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
    
    # Base Data Directory - Store in user's home directory so data persists across app updates
    DATA_DIR: str = os.path.expanduser("~/Library/Application Support/OpenTranscribe")
    
    # Database
    @property
    def DATABASE_URL(self) -> str:
        return f"sqlite:///{os.path.join(self.DATA_DIR, 'whisper.db')}"
    
    # Whisper
    WHISPER_MODEL_DIR: str = os.path.expanduser("~/Library/Application Support/OpenTranscribe/models")
    DEFAULT_MODEL: str = "base"
    DEFAULT_LANGUAGE: str = "auto"
    
    # File Upload
    @property
    def UPLOAD_DIR(self) -> str:
        return os.path.join(self.DATA_DIR, "uploads")
        
    MAX_UPLOAD_SIZE: int = 524288000  # 500MB
    ALLOWED_EXTENSIONS: str = "mp3,wav,m4a,flac,ogg,mp4,mkv,avi,mov,webm"
    
    # Storage
    @property
    def TRANSCRIPTION_DIR(self) -> str:
        return os.path.join(self.DATA_DIR, "transcriptions")
    
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
        os.makedirs(self.DATA_DIR, exist_ok=True)
        os.makedirs(self.UPLOAD_DIR, exist_ok=True)
        os.makedirs(self.TRANSCRIPTION_DIR, exist_ok=True)
        os.makedirs(self.WHISPER_MODEL_DIR, exist_ok=True)
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()