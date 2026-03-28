from pydantic_settings import BaseSettings
from typing import List
import os

class Settings(BaseSettings):
    # Application
    APP_NAME: str = "Whisper WebApp"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True
    ENVIRONMENT: str = "development"
    
    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    
    # Database
    DATABASE_URL: str = "sqlite:///./data/whisper.db"
    
    # Whisper
    WHISPER_MODEL_DIR: str = "~/.cache/whisper"
    DEFAULT_MODEL: str = "base"
    DEFAULT_LANGUAGE: str = "auto"
    
    # File Upload
    UPLOAD_DIR: str = "./data/uploads"
    MAX_UPLOAD_SIZE: int = 524288000  # 500MB
    ALLOWED_EXTENSIONS: str = "mp3,wav,m4a,flac,ogg,mp4,mkv,avi,mov,webm"
    
    # Storage
    TRANSCRIPTION_DIR: str = "./data/transcriptions"
    
    # GPU
    USE_GPU: bool = True
    
    # Logging
    LOG_LEVEL: str = "INFO"
    
    # CORS
    CORS_ORIGINS: str = "http://localhost:5173,http://localhost:3000"
    
    @property
    def allowed_extensions_list(self) -> List[str]:
        return [ext.strip() for ext in self.ALLOWED_EXTENSIONS.split(",")]
    
    @property
    def cors_origins_list(self) -> List[str]:
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",")]
    
    def ensure_directories(self):
        """Create necessary directories if they don't exist."""
        os.makedirs(self.UPLOAD_DIR, exist_ok=True)
        os.makedirs(self.TRANSCRIPTION_DIR, exist_ok=True)
        os.makedirs("./data", exist_ok=True)
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()