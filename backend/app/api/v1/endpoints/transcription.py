import os
import uuid
from datetime import datetime
from typing import List, Optional
from pathlib import Path
from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Depends, Query
from sqlalchemy.orm import Session
from loguru import logger

from app.config import settings
from app.models.database import get_db, Transcription, TranscriptionStatus, TaskType
from app.services.transcription_service import transcription_service

router = APIRouter()

@router.post("/transcriptions")
async def create_transcription(
    file: UploadFile = File(...),
    model: str = Form(default="base"),
    language: str = Form(default="auto"),
    task: str = Form(default="transcribe"),
    db: Session = Depends(get_db)
):
    """Upload and transcribe a file."""
    # Validate file extension
    file_ext = Path(file.filename).suffix.lower().lstrip('.')
    if file_ext not in settings.allowed_extensions_list:
        raise HTTPException(
            status_code=400,
            detail=f"File type .{file_ext} not allowed. Allowed: {settings.allowed_extensions_list}"
        )
    
    # Generate unique ID
    transcription_id = str(uuid.uuid4())
    
    # Save uploaded file
    upload_dir = Path(settings.UPLOAD_DIR)
    upload_dir.mkdir(parents=True, exist_ok=True)
    
    file_path = upload_dir / f"{transcription_id}_{file.filename}"
    
    try:
        # Save file
        content = await file.read()
        if len(content) > settings.MAX_UPLOAD_SIZE:
            raise HTTPException(status_code=400, detail="File too large")
        
        with open(file_path, "wb") as f:
            f.write(content)
        
        # Get file duration
        duration = transcription_service.get_audio_duration(str(file_path))
        
        # Create transcription record
        transcription = Transcription(
            id=transcription_id,
            file_name=file.filename,
            file_path=str(file_path),
            file_size=len(content),
            duration=duration,
            format=file_ext,
            model=model,
            language=language,
            task=TaskType(task),
            status=TranscriptionStatus.PENDING
        )
        
        db.add(transcription)
        db.commit()
        
        # Start transcription in background (simplified - in production use Celery)
        import asyncio
        asyncio.create_task(
            run_transcription_async(transcription_id, str(file_path), model, language, task)
        )
        
        return {
            "id": transcription_id,
            "status": "pending",
            "file_name": file.filename,
            "file_size": len(content),
            "duration": duration,
            "model": model,
            "language": language,
            "created_at": transcription.created_at.isoformat()
        }
        
    except Exception as e:
        # Clean up file on error
        if file_path.exists():
            os.remove(file_path)
        raise HTTPException(status_code=500, detail=str(e))

async def run_transcription_async(transcription_id: str, file_path: str, model: str, language: str, task: str):
    """Run transcription in a background thread so the event loop stays responsive for polling."""
    import asyncio
    loop = asyncio.get_event_loop()
    try:
        await loop.run_in_executor(
            None,
            lambda: transcription_service.transcribe_file(
                transcription_id=transcription_id,
                file_path=file_path,
                model_name=model,
                language=language,
                task=task
            )
        )
    except Exception as e:
        logger.error(f"Background transcription failed: {e}")

@router.get("/transcriptions")
async def list_transcriptions(
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
    status: Optional[str] = Query(default=None),
    search: Optional[str] = Query(default=None),
    db: Session = Depends(get_db)
):
    """List all transcriptions."""
    query = db.query(Transcription)
    
    # Filter by status
    if status:
        query = query.filter(Transcription.status == TranscriptionStatus(status))
    
    # Search in text
    if search:
        query = query.filter(Transcription.text.ilike(f"%{search}%"))
    
    # Order by created_at descending
    query = query.order_by(Transcription.created_at.desc())
    
    # Get total count
    total = query.count()
    
    # Apply pagination
    transcriptions = query.offset(skip).limit(limit).all()
    
    return {
        "total": total,
        "skip": skip,
        "limit": limit,
        "items": [
            {
                "id": t.id,
                "file_name": t.file_name,
                "file_size": t.file_size,
                "duration": t.duration,
                "model": t.model,
                "language": t.language,
                "status": t.status.value,
                "progress": t.progress,
                "created_at": t.created_at.isoformat(),
                "completed_at": t.completed_at.isoformat() if t.completed_at else None,
                "processing_time": t.processing_time
            }
            for t in transcriptions
        ]
    }

@router.get("/transcriptions/{transcription_id}")
async def get_transcription(
    transcription_id: str,
    db: Session = Depends(get_db)
):
    """Get transcription details."""
    transcription = db.query(Transcription).filter(Transcription.id == transcription_id).first()
    
    if not transcription:
        raise HTTPException(status_code=404, detail="Transcription not found")
    
    return {
        "id": transcription.id,
        "file_name": transcription.file_name,
        "file_size": transcription.file_size,
        "duration": transcription.duration,
        "format": transcription.format,
        "model": transcription.model,
        "language": transcription.language,
        "task": transcription.task.value,
        "status": transcription.status.value,
        "progress": transcription.progress,
        "text": transcription.text,
        "segments": transcription.segments,
        "processing_time": transcription.processing_time,
        "created_at": transcription.created_at.isoformat(),
        "completed_at": transcription.completed_at.isoformat() if transcription.completed_at else None,
        "error_message": transcription.error_message
    }

@router.delete("/transcriptions/{transcription_id}")
async def delete_transcription(
    transcription_id: str,
    db: Session = Depends(get_db)
):
    """Delete a transcription."""
    transcription = db.query(Transcription).filter(Transcription.id == transcription_id).first()
    
    if not transcription:
        raise HTTPException(status_code=404, detail="Transcription not found")
    
    # Delete file
    if os.path.exists(transcription.file_path):
        os.remove(transcription.file_path)
    
    # Delete record
    db.delete(transcription)
    db.commit()
    
    return {"message": "Transcription deleted successfully", "id": transcription_id}

@router.post("/transcriptions/batch")
async def create_batch_transcription(
    files: List[UploadFile] = File(...),
    model: str = Form(default="base"),
    language: str = Form(default="auto"),
    task: str = Form(default="transcribe"),
    db: Session = Depends(get_db)
):
    """Upload and transcribe multiple files."""
    if len(files) > 20:
        raise HTTPException(
            status_code=400,
            detail="Maximum 20 files allowed per batch"
        )
    
    results = []
    errors = []
    
    for file in files:
        try:
            # Validate file extension
            file_ext = Path(file.filename).suffix.lower().lstrip('.')
            if file_ext not in settings.allowed_extensions_list:
                errors.append({
                    "file": file.filename,
                    "error": f"File type .{file_ext} not allowed"
                })
                continue
            
            # Generate unique ID
            transcription_id = str(uuid.uuid4())
            
            # Save uploaded file
            upload_dir = Path(settings.UPLOAD_DIR)
            upload_dir.mkdir(parents=True, exist_ok=True)
            
            file_path = upload_dir / f"{transcription_id}_{file.filename}"
            
            # Save file
            content = await file.read()
            if len(content) > settings.MAX_UPLOAD_SIZE:
                errors.append({
                    "file": file.filename,
                    "error": "File too large"
                })
                continue
            
            with open(file_path, "wb") as f:
                f.write(content)
            
            # Get file duration
            duration = transcription_service.get_audio_duration(str(file_path))
            
            # Create transcription record
            transcription = Transcription(
                id=transcription_id,
                file_name=file.filename,
                file_path=str(file_path),
                file_size=len(content),
                duration=duration,
                format=file_ext,
                model=model,
                language=language,
                task=TaskType(task),
                status=TranscriptionStatus.PENDING
            )
            
            db.add(transcription)
            db.commit()
            
            # Start transcription in background
            import asyncio
            asyncio.create_task(
                run_transcription_async(transcription_id, str(file_path), model, language, task)
            )
            
            results.append({
                "id": transcription_id,
                "status": "pending",
                "file_name": file.filename,
                "file_size": len(content),
                "duration": duration
            })
            
        except Exception as e:
            errors.append({
                "file": file.filename,
                "error": str(e)
            })
    
    return {
        "batch_id": str(uuid.uuid4()),
        "total_files": len(files),
        "successful": len(results),
        "failed": len(errors),
        "results": results,
        "errors": errors,
        "model": model,
        "language": language
    }

@router.get("/transcriptions/{transcription_id}/export")
async def export_transcription(
    transcription_id: str,
    format: str = Query(default="txt", regex="^(txt|json|srt|vtt)$"),
    db: Session = Depends(get_db)
):
    """Export transcription in various formats."""
    transcription = db.query(Transcription).filter(Transcription.id == transcription_id).first()
    
    if not transcription:
        raise HTTPException(status_code=404, detail="Transcription not found")
    
    if transcription.status != TranscriptionStatus.COMPLETED:
        raise HTTPException(status_code=400, detail="Transcription not completed")
    
    # Extract original filename (remove UUID prefix if present)
    original_filename = transcription.file_name
    if "_" in original_filename:
        # Remove UUID prefix (format: uuid_originalname.ext)
        parts = original_filename.split("_", 1)
        if len(parts) > 1:
            original_filename = parts[1]
    
    # Remove file extension from original filename for export
    name_without_ext = Path(original_filename).stem
    
    if format == "txt":
        content = transcription.text
        media_type = "text/plain"
        filename = f"{name_without_ext}.txt"
    elif format == "json":
        import json
        content = json.dumps({
            "file_name": original_filename,
            "language": transcription.language,
            "model": transcription.model,
            "text": transcription.text,
            "segments": transcription.segments
        }, indent=2)
        media_type = "application/json"
        filename = f"{name_without_ext}.json"
    elif format == "srt":
        content = generate_srt(transcription.segments)
        media_type = "text/plain"
        filename = f"{name_without_ext}.srt"
    elif format == "vtt":
        content = generate_vtt(transcription.segments)
        media_type = "text/vtt"
        filename = f"{name_without_ext}.vtt"
    
    from fastapi.responses import Response
    return Response(
        content=content,
        media_type=media_type,
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )

def generate_srt(segments: list) -> str:
    """Generate SRT subtitle format."""
    srt = []
    for i, seg in enumerate(segments, 1):
        start = format_timestamp_srt(seg["start"])
        end = format_timestamp_srt(seg["end"])
        srt.append(f"{i}\n{start} --> {end}\n{seg['text']}\n")
    return "\n".join(srt)

def generate_vtt(segments: list) -> str:
    """Generate VTT subtitle format."""
    vtt = ["WEBVTT\n"]
    for seg in segments:
        start = format_timestamp_vtt(seg["start"])
        end = format_timestamp_vtt(seg["end"])
        vtt.append(f"{start} --> {end}\n{seg['text']}\n")
    return "\n".join(vtt)

def format_timestamp_srt(seconds: float) -> str:
    """Format timestamp for SRT."""
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    millis = int((seconds % 1) * 1000)
    return f"{hours:02d}:{minutes:02d}:{secs:02d},{millis:03d}"

def format_timestamp_vtt(seconds: float) -> str:
    """Format timestamp for VTT."""
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    millis = int((seconds % 1) * 1000)
    return f"{hours:02d}:{minutes:02d}:{secs:02d}.{millis:03d}"