from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime
from pydantic import BaseModel
import base64
from ..database import get_db, Post, NewsCard, StatusUpdate
from ..auth.jwt_handler import verify_token
from fastapi.security import OAuth2PasswordBearer

router = APIRouter(prefix="/admin", tags=["admin"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

def verify_admin(token: str = Depends(oauth2_scheme)):
    try:
        payload = verify_token(token)
        username = payload.get("sub")
        if not username:
            raise HTTPException(status_code=401, detail="Invalid token")
        if username != "admin":
            raise HTTPException(status_code=403, detail="Admin only")
        return username
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))

class PostCreate(BaseModel):
    text: str
    is_official: bool = False
    image_data: Optional[str] = None
    video_data: Optional[str] = None

@router.post("/upload/post")
async def upload_post(
    post_data: PostCreate,
    db: Session = Depends(get_db),
    username: str = Depends(verify_admin)
):
    try:
        image_bytes = None
        video_bytes = None
        
        if post_data.image_data:
            try:
                img_data = post_data.image_data
                if ',' in img_data:
                    img_data = img_data.split(',')[1]
                image_bytes = base64.b64decode(img_data)
            except Exception as e:
                print(f"Image decode error: {e}")
        
        if post_data.video_data:
            try:
                vid_data = post_data.video_data
                if ',' in vid_data:
                    vid_data = vid_data.split(',')[1]
                video_bytes = base64.b64decode(vid_data)
            except Exception as e:
                print(f"Video decode error: {e}")
        
        post = Post(
            text=post_data.text,
            is_official=True,
            added_by=username,
            added_at=datetime.utcnow()
        )
        
        if image_bytes:
            post.image = image_bytes
        if video_bytes:
            post.video = video_bytes
        
        db.add(post)
        db.commit()
        db.refresh(post)
        
        return {
            "message": "Post uploaded successfully",
            "id": post.id,
            "has_image": post.image is not None,
            "has_video": post.video is not None
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")

@router.post("/upload/news")
async def upload_news(
    title: str = Form(...),
    description: str = Form(...),
    url: Optional[str] = Form(None),
    source: str = Form(...),
    image: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
    username: str = Depends(verify_admin)
):
    try:
        image_bytes = None
        if image:
            image_bytes = await image.read()
        
        news = NewsCard(
            title=title,
            description=description,
            url=url,
            source=source,
            image=image_bytes,
            added_by=username,
            added_at=datetime.utcnow()
        )
        
        db.add(news)
        db.commit()
        db.refresh(news)
        
        return {"message": "News uploaded successfully", "id": news.id}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")

@router.post("/upload/status")
async def upload_status(
    text: str = Form(...),
    db: Session = Depends(get_db),
    username: str = Depends(verify_admin)
):
    try:
        status = StatusUpdate(
            text=text,
            added_by=username,
            added_at=datetime.utcnow()
        )
        db.add(status)
        db.commit()
        db.refresh(status)
        
        return {"message": "Status updated successfully", "id": status.id}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")

@router.delete("/post/{post_id}")
async def delete_post(
    post_id: int,
    db: Session = Depends(get_db),
    username: str = Depends(verify_admin)
):
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    db.delete(post)
    db.commit()
    return {"message": "Post deleted successfully"}

@router.delete("/news/{news_id}")
async def delete_news(
    news_id: int,
    db: Session = Depends(get_db),
    username: str = Depends(verify_admin)
):
    news = db.query(NewsCard).filter(NewsCard.id == news_id).first()
    if not news:
        raise HTTPException(status_code=404, detail="News not found")
    
    db.delete(news)
    db.commit()
    return {"message": "News deleted successfully"}

@router.delete("/status/{status_id}")
async def delete_status(
    status_id: int,
    db: Session = Depends(get_db),
    username: str = Depends(verify_admin)
):
    status = db.query(StatusUpdate).filter(StatusUpdate.id == status_id).first()
    if not status:
        raise HTTPException(status_code=404, detail="Status not found")
    
    db.delete(status)
    db.commit()
    return {"message": "Status deleted successfully"}