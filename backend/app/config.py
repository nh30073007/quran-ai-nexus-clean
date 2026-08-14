import os
from dotenv import load_dotenv
from cryptography.fernet import Fernet

load_dotenv()

class Settings:
    # App
    APP_NAME = os.getenv("APP_NAME", "Quran AI Nexus")
    DEBUG = os.getenv("DEBUG", "True").lower() == "true"
    
    # Database
    DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./quran_ai.db")
    
    # Security
    ENCRYPTION_KEY = os.getenv("ENCRYPTION_KEY", Fernet.generate_key().decode())
    SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-here")
    ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "admin123")
    ALGORITHM = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # 24 hours
    
    # AI
    HF_TOKEN = os.getenv("HF_TOKEN", "")
    
    def __init__(self):
        print("✅ Loaded config:")
        print(f"   APP_NAME: {self.APP_NAME}")
        print(f"   DEBUG: {self.DEBUG}")
        print(f"   DATABASE_URL: {self.DATABASE_URL}")
        print(f"   SECRET_KEY: {'********** (set)' if self.SECRET_KEY else '❌ NOT SET!'}")

settings = Settings()