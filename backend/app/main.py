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

@app.get("/api/v1/health")
async def health():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "version": settings.APP_VERSION,
        "environment": settings.ENVIRONMENT
    }

# Serve static files (frontend) in production
# We check both standard relative path and PyInstaller _MEIPASS path
import sys

def get_frontend_dist():
    """Get the path to the frontend dist folder, handling PyInstaller environment."""
    if hasattr(sys, '_MEIPASS'):
        # PyInstaller creates a temp folder and stores path in _MEIPASS
        return os.path.join(sys._MEIPASS, 'frontend_dist')
    
    # Standard development path
    return os.path.abspath(os.path.join(os.path.dirname(__file__), "../../frontend/dist"))

frontend_dist = get_frontend_dist()
if os.path.exists(frontend_dist):
    logger.info(f"Serving frontend from {frontend_dist}")
    app.mount("/", StaticFiles(directory=frontend_dist, html=True), name="frontend")
else:
    logger.warning(f"Frontend dist not found at {frontend_dist}")

# Ensure any unmatched routes fall back to index.html for client-side routing
@app.exception_handler(404)
async def custom_404_handler(request, exc):
    if os.path.exists(frontend_dist) and not request.url.path.startswith("/api/"):
        from fastapi.responses import FileResponse
        return FileResponse(os.path.join(frontend_dist, "index.html"))
    from fastapi.responses import JSONResponse
    return JSONResponse({"detail": "Not Found"}, status_code=404)
if __name__ == "__main__":
    import webbrowser
    import threading
    import time
    
    def open_browser():
        time.sleep(1.5)
        webbrowser.open(f"http://{settings.HOST}:{settings.PORT}")
        
    # Only auto-open browser in production/bundled mode
    if hasattr(sys, '_MEIPASS'):
        threading.Thread(target=open_browser, daemon=True).start()

    # When bundled, reload should always be False.
    is_bundled = hasattr(sys, '_MEIPASS')
    
    import uvicorn
    if is_bundled:
        # In pyinstaller, we must pass the app object directly, not a string
        uvicorn.run(
            app,
            host=settings.HOST,
            port=settings.PORT,
            reload=False
        )
    else:
        uvicorn.run(
            "app.main:app",
            host=settings.HOST,
            port=settings.PORT,
            reload=settings.DEBUG
        )
