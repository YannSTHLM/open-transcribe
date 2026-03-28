from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager
from loguru import logger
import os

from app.config import settings
from app.models.database import init_db
from app.api.v1.endpoints import transcription, models

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler."""
    # Startup
    logger.info("Starting Open Transcribe...")
    settings.ensure_directories()
    init_db()
    logger.info("Database initialized")
    yield
    # Shutdown
    logger.info("Shutting down Open Transcribe...")

# Create FastAPI app
app = FastAPI(
    title="Open Transcribe",
    version=settings.APP_VERSION,
    description="A powerful, privacy-focused web application for audio/video transcription using OpenAI's Whisper model",
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routes
app.include_router(transcription.router, prefix="/api/v1", tags=["transcription"])
app.include_router(models.router, prefix="/api/v1", tags=["models"])

# Serve static files (frontend) in production
frontend_dist = os.path.join(os.path.dirname(__file__), "../../frontend/dist")
if os.path.exists(frontend_dist):
    app.mount("/", StaticFiles(directory=frontend_dist, html=True), name="frontend")

@app.get("/api/v1/health")
async def health():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "version": settings.APP_VERSION,
        "environment": settings.ENVIRONMENT
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG
    )