import os
import asyncio
from pathlib import Path
from fastapi import APIRouter, HTTPException
from loguru import logger

from app.config import settings
from app.services.transcription_service import transcription_service

router = APIRouter()

@router.get("/models")
async def list_models():
    """List available Whisper models."""
    models = transcription_service.get_available_models()
    return {"models": models}

@router.post("/models/{model_name}/download")
async def download_model(model_name: str):
    """Download a Whisper model."""
    valid_models = ["tiny", "base", "small", "medium", "large-v3", "large-v3-turbo"]
    
    if model_name not in valid_models:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid model name. Valid options: {valid_models}"
        )
    
    # Check if already downloaded
    cache_dir = Path(settings.WHISPER_MODEL_DIR).expanduser()
    model_path = cache_dir / f"models--guillaumek--faster-whisper-{model_name}"
    
    if model_path.exists():
        return {
            "model_name": model_name,
            "status": "already_downloaded",
            "message": f"Model {model_name} is already downloaded"
        }
    
    # Start download in background
    asyncio.create_task(download_model_async(model_name))
    
    return {
        "model_name": model_name,
        "status": "downloading",
        "message": f"Started downloading model {model_name}"
    }

async def download_model_async(model_name: str):
    """Download model asynchronously."""
    try:
        logger.info(f"Starting download of model: {model_name}")
        
        from huggingface_hub import snapshot_download
        import os
        
        # Map model names to HuggingFace repo IDs
        model_mapping = {
            "tiny": "Systran/faster-whisper-tiny",
            "base": "Systran/faster-whisper-base",
            "small": "Systran/faster-whisper-small",
            "medium": "Systran/faster-whisper-medium",
            "large-v3": "Systran/faster-whisper-large-v3",
            "large-v3-turbo": "Systran/faster-whisper-large-v3-turbo"
        }
        
        repo_id = model_mapping.get(model_name, f"Systran/faster-whisper-{model_name}")
        
        # Download the model using huggingface_hub
        cache_dir = os.path.expanduser(settings.WHISPER_MODEL_DIR)
        
        snapshot_download(
            repo_id=repo_id,
            cache_dir=cache_dir,
            local_dir=os.path.join(cache_dir, f"models--Systran--faster-whisper-{model_name}"),
            local_dir_use_symlinks=False  # Avoid symlink issues
        )
        
        logger.info(f"Model {model_name} downloaded successfully")
        
    except Exception as e:
        logger.error(f"Failed to download model {model_name}: {e}")

@router.delete("/models/{model_name}")
async def delete_model(model_name: str):
    """Delete a downloaded model."""
    cache_dir = Path(settings.WHISPER_MODEL_DIR).expanduser()
    
    # Check both possible naming conventions
    model_path_systran = cache_dir / f"models--Systran--faster-whisper-{model_name}"
    model_path_guillaumek = cache_dir / f"models--guillaumek--faster-whisper-{model_name}"
    
    paths_to_delete = []
    if model_path_systran.exists():
        paths_to_delete.append(model_path_systran)
    if model_path_guillaumek.exists():
        paths_to_delete.append(model_path_guillaumek)
        
    if not paths_to_delete:
        raise HTTPException(
            status_code=404,
            detail=f"Model {model_name} not found"
        )

    try:
        import shutil
        for path in paths_to_delete:
            shutil.rmtree(path)

        return {
            "model_name": model_name,
            "status": "deleted",
            "message": f"Model {model_name} deleted successfully"
        }
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to delete model: {str(e)}"
        )

@router.get("/system/info")
async def get_system_info():
    """Get system information."""
    import platform
    import psutil
    
    # Check GPU availability
    gpu_info = {"available": False, "devices": []}
    try:
        import torch
        if torch.cuda.is_available():
            gpu_info["available"] = True
            for i in range(torch.cuda.device_count()):
                gpu_info["devices"].append({
                    "id": i,
                    "name": torch.cuda.get_device_name(i),
                    "memory_total": torch.cuda.get_device_properties(i).total_memory // (1024**2)
                })
    except ImportError:
        pass
    
    # Get memory info
    memory = psutil.virtual_memory()
    
    # Get disk info
    disk = psutil.disk_usage("/")
    
    return {
        "version": settings.APP_VERSION,
        "platform": platform.system(),
        "processor": platform.processor() or platform.machine(),
        "python_version": platform.python_version(),
        "memory": {
            "total": memory.total // (1024**2),
            "available": memory.available // (1024**2),
            "used_percent": memory.percent
        },
        "gpu": gpu_info,
        "storage": {
            "total": disk.total // (1024**3),
            "used": disk.used // (1024**3),
            "free": disk.free // (1024**3)
        }
    }

@router.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "version": settings.APP_VERSION,
        "environment": settings.ENVIRONMENT
    }