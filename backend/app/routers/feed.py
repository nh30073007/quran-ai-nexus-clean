from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime
import base64
from ..database import SessionLocal, Post, NewsCard, StatusUpdate  # ✅ NewsCard এখানে আছে

router = APIRouter(prefix="/feed", tags=["feed"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/posts")
async def get_posts(limit: int = 10, offset: int = 0, db: Session = Depends(get_db)):
    posts = db.query(Post).order_by(Post.added_at.desc()).offset(offset).limit(limit).all()
    
    result = []
    for p in posts:
        post_data = {
            "id": p.id,
            "text": p.text,
            "is_official": p.is_official,
            "added_by": p.added_by,
            "added_at": p.added_at.isoformat() if p.added_at else None,
            "image": None,
            "video": None
        }
        
        if p.image:
            try:
                image_base64 = base64.b64encode(p.image).decode('utf-8')
                post_data["image"] = f"data:image/jpeg;base64,{image_base64}"
            except Exception as e:
                print(f"Image conversion error: {e}")
        
        if p.video:
            try:
                video_base64 = base64.b64encode(p.video).decode('utf-8')
                post_data["video"] = f"data:video/mp4;base64,{video_base64}"
            except Exception as e:
                print(f"Video conversion error: {e}")
            
        result.append(post_data)
    
    return result

@router.get("/news")
async def get_news(db: Session = Depends(get_db)):
    news = db.query(NewsCard).order_by(NewsCard.added_at.desc()).all()
    return [
        {
            "id": n.id,
            "title": n.title,
            "description": n.description,
            "image": base64.b64encode(n.image).decode('utf-8') if n.image else None,
            "url": n.url,
            "source": n.source,
            "added_at": n.added_at.isoformat() if n.added_at else None
        }
        for n in news
    ]

@router.get("/status")
async def get_status(db: Session = Depends(get_db)):
    updates = db.query(StatusUpdate).order_by(StatusUpdate.added_at.desc()).all()
    return [
        {
            "id": u.id,
            "text": u.text,
            "added_by": u.added_by,
            "added_at": u.added_at.isoformat() if u.added_at else None
        }
        for u in updates
    ]