import os
import uuid
import time
import subprocess
from pathlib import Path
from typing import Optional, Dict, Any
from faster_whisper import WhisperModel
from loguru import logger
from app.config import settings
from app.models.database import Transcription, TranscriptionStatus, SessionLocal

class TranscriptionService:
    def __init__(self):
        self.model = None
        self.current_model_name = None
    
    def load_model(self, model_name: str) -> WhisperModel:
        """Load or get cached Whisper model."""
        if self.current_model_name == model_name and self.model is not None:
            return self.model
        
        logger.info(f"Loading Whisper model: {model_name}")
        
        # Determine device
        try:
            import torch
            if torch.cuda.is_available() and settings.USE_GPU:
                device = "cuda"
                compute_type = "float16"
                logger.info(f"Using CUDA GPU: {torch.cuda.get_device_name(0)}")
            else:
                device = "cpu"
                compute_type = "int8"
                logger.info("Using CPU for transcription")
        except ImportError:
            device = "cpu"
            compute_type = "int8"
            logger.info("PyTorch not available, using CPU")
        
        # Find the model directory - check both naming conventions
        cache_dir = Path(settings.WHISPER_MODEL_DIR).expanduser()
        model_dir = cache_dir / f"models--Systran--faster-whisper-{model_name}"
        
        if not model_dir.exists():
            model_dir = cache_dir / f"models--guillaumek--faster-whisper-{model_name}"
        
        if model_dir.exists():
            # Use the local directory directly
            self.model = WhisperModel(
                str(model_dir),
                device=device,
                compute_type=compute_type
            )
        else:
            # Fall back to downloading
            self.model = WhisperModel(
                model_name,
                device=device,
                compute_type=compute_type,
                download_root=settings.WHISPER_MODEL_DIR
            )
        
        self.current_model_name = model_name
        return self.model
    
    def get_audio_duration(self, file_path: str) -> float:
        """Get audio duration using ffprobe."""
        try:
            cmd = [
                'ffprobe', '-v', 'error',
                '-show_entries', 'format=duration',
                '-of', 'default=noprint_wrappers=1:nokey=1',
                file_path
            ]
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0:
                return float(result.stdout.strip())
        except Exception as e:
            logger.warning(f"Could not get duration: {e}")
        return 0.0
    
    def extract_audio(self, input_path: str, output_path: str) -> str:
        """Extract audio from video or convert audio format."""
        cmd = [
            'ffmpeg', '-y', '-i', input_path,
            '-vn',  # No video
            '-acodec', 'pcm_s16le',  # 16-bit PCM
            '-ar', '16000',  # 16kHz sample rate
            '-ac', '1',  # Mono
            output_path
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            raise Exception(f"FFmpeg error: {result.stderr}")
        
        return output_path
    
    def transcribe_file(
        self,
        transcription_id: str,
        file_path: str,
        model_name: str,
        language: Optional[str] = None,
        task: str = "transcribe"
    ) -> Dict[str, Any]:
        """Transcribe an audio/video file."""
        start_time = time.time()
        db = SessionLocal()
        
        try:
            # Update status to processing
            transcription = db.query(Transcription).filter(Transcription.id == transcription_id).first()
            if not transcription:
                raise ValueError(f"Transcription {transcription_id} not found")
            
            transcription.status = TranscriptionStatus.PROCESSING
            db.commit()
            
            # Load model
            model = self.load_model(model_name)
            
            # Prepare audio file
            audio_path = file_path
            temp_audio = None
            
            # Check if we need to extract audio
            file_ext = Path(file_path).suffix.lower()
            video_extensions = ['.mp4', '.mkv', '.avi', '.mov', '.webm']
            
            if file_ext in video_extensions:
                temp_audio = file_path + ".wav"
                audio_path = self.extract_audio(file_path, temp_audio)
                logger.info(f"Extracted audio from video: {audio_path}")
            
            # Transcribe
            logger.info(f"Starting transcription of {file_path}")
            
            # Determine language
            lang = None if language == "auto" else language
            
            segments_gen, info = model.transcribe(
                audio_path,
                language=lang,
                task=task,
                beam_size=5,
                word_timestamps=True
            )
            
            # Process segments
            segments = []
            full_text = []
            
            # Get total duration for progress calculation
            total_duration = self.get_audio_duration(audio_path)
            if total_duration <= 0:
                # Fallback: use info.duration from whisper if available
                total_duration = getattr(info, 'duration', 0) or 0
            
            logger.info(f"Audio duration for progress: {total_duration:.2f}s")
            
            for segment in segments_gen:
                seg_data = {
                    "id": len(segments),
                    "start": round(segment.start, 2),
                    "end": round(segment.end, 2),
                    "text": segment.text.strip(),
                    "avg_logprob": round(segment.avg_logprob, 4),
                    "no_speech_prob": round(segment.no_speech_prob, 4)
                }
                segments.append(seg_data)
                full_text.append(segment.text.strip())
                
                # Update progress in database
                if total_duration > 0:
                    progress = min(95, (segment.end / total_duration) * 100)
                else:
                    # If duration unknown, show incrementing progress per segment
                    progress = min(90, len(segments) * 2)
                
                transcription.progress = round(progress, 1)
                db.commit()
                
                logger.debug(f"Segment {len(segments)}: {segment.start:.2f}s - {segment.end:.2f}s (progress: {progress:.1f}%)")
            
            # Calculate processing time
            processing_time = time.time() - start_time
            
            # Update transcription record
            from datetime import datetime
            transcription.status = TranscriptionStatus.COMPLETED
            transcription.text = "\n".join(full_text)
            transcription.segments = segments
            transcription.language = info.language
            transcription.processing_time = processing_time
            transcription.completed_at = datetime.utcnow()
            
            db.commit()
            
            logger.info(f"Transcription completed in {processing_time:.2f}s")
            
            # Clean up temp audio
            if temp_audio and os.path.exists(temp_audio):
                os.remove(temp_audio)
            
            return {
                "id": transcription_id,
                "status": "completed",
                "text": transcription.text,
                "segments": segments,
                "language": info.language,
                "processing_time": processing_time
            }
            
        except Exception as e:
            logger.error(f"Transcription failed: {e}")
            
            # Update transcription with error
            if transcription:
                transcription.status = TranscriptionStatus.FAILED
                transcription.error_message = str(e)
                db.commit()
            
            raise
            
        finally:
            db.close()
    
    def get_available_models(self):
        """Get list of available Whisper models."""
        models = [
            {"name": "tiny", "size_mb": 39, "params": "39M", "vram_gb": 1, "accuracy_score": 6.5},
            {"name": "base", "size_mb": 74, "params": "74M", "vram_gb": 1, "accuracy_score": 7.5},
            {"name": "small", "size_mb": 244, "params": "244M", "vram_gb": 2, "accuracy_score": 8.0},
            {"name": "medium", "size_mb": 769, "params": "769M", "vram_gb": 5, "accuracy_score": 8.5},
            {"name": "large-v3", "size_mb": 2900, "params": "1550M", "vram_gb": 10, "accuracy_score": 9.0},
            {"name": "large-v3-turbo", "size_mb": 1600, "params": "809M", "vram_gb": 6, "accuracy_score": 8.8},
        ]
        
        # Check which models are downloaded
        cache_dir = Path(settings.WHISPER_MODEL_DIR).expanduser()
        for model in models:
            # Check for both possible naming conventions
            model_path_systran = cache_dir / f"models--Systran--faster-whisper-{model['name']}"
            model_path_guillaumek = cache_dir / f"models--guillaumek--faster-whisper-{model['name']}"
            model["downloaded"] = model_path_systran.exists() or model_path_guillaumek.exists()
        
        return models

transcription_service = TranscriptionService()