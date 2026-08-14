from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta
from pydantic import BaseModel

from ..database import get_db, Admin
from .jwt_handler import create_access_token
from .password import hash_password, verify_password

router = APIRouter(prefix="/auth", tags=["auth"])

class UserRegister(BaseModel):
    username: str
    email: str
    password: str

@router.post("/register")
async def register(user: UserRegister, db: Session = Depends(get_db)):
    existing_user = db.query(Admin).filter(
        (Admin.username == user.username) | (Admin.email == user.email)
    ).first()
    
    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="Username or email already registered"
        )
    
    hashed_password = hash_password(user.password)
    new_admin = Admin(
        username=user.username,
        email=user.email,
        password=hashed_password
    )
    
    db.add(new_admin)
    db.commit()
    db.refresh(new_admin)
    
    return {"message": "User registered successfully"}

@router.post("/login")
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(Admin).filter(Admin.username == form_data.username).first()
    
    if not user or not verify_password(form_data.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=30)
    access_token = create_access_token(
        data={"sub": user.username}, 
        expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "username": user.username
    }