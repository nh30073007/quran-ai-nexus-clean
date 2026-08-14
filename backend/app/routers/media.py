from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime
import os
import shutil
import uuid
import io
from PIL import Image
from ..database import SessionLocal, MediaContent
from ..auth.jwt_handler import verify_token
from fastapi.security import OAuth2PasswordBearer

router = APIRouter(prefix="/media", tags=["media"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

# Create uploads directory if it doesn't exist
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(os.path.join(UPLOAD_DIR, "images"), exist_ok=True)
os.makedirs(os.path.join(UPLOAD_DIR, "videos"), exist_ok=True)
os.makedirs(os.path.join(UPLOAD_DIR, "audio"), exist_ok=True)

# Instagram-style image standards
INSTAGRAM_SQUARE = (1080, 1080)      # 1:1
INSTAGRAM_PORTRAIT = (1080, 1350)      # 4:5
JPEG_QUALITY = 85

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def verify_admin(token: str = Depends(oauth2_scheme)):
    try:
        payload = verify_token(token)
        username = payload.get("sub")
        if not username:
            raise HTTPException(status_code=401, detail="Invalid token")
        return username
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))

# বাকি কোড একই রাখো (process_instagram_image, upload_image, etc.)