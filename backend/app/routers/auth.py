from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from typing import Optional
import logging
import jwt
from datetime import datetime, timedelta
import bcrypt
import os
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["auth"])

# JWT Configuration
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-this-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 30))

# Request Models
class LoginRequest(BaseModel):
    username: str
    password: str

class RegisterRequest(BaseModel):
    username: str
    email: str
    password: str
    full_name: Optional[str] = None

class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    username: str

# Temporary in-memory user storage (replace with database in production)
# This is for testing only - use a proper database in production
users_db = {
    "admin": {
        "username": "admin",
        "email": "admin@quranai.com",
        "full_name": "Admin",
        "password_hash": bcrypt.hashpw("admin123".encode('utf-8'), bcrypt.gensalt()).decode('utf-8'),
        "created_at": datetime.now().isoformat()
    }
}


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """Create JWT access token"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify plain password against hashed password"""
    return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))


def get_password_hash(password: str) -> str:
    """Hash a password"""
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')


@router.post("/login")
async def login(request: LoginRequest):
    """
    Login endpoint - returns JWT token
    """
    try:
        logger.info(f"🔐 Login attempt: {request.username}")
        
        # Find user in database
        user = users_db.get(request.username)
        
        if not user:
            logger.warning(f"❌ User not found: {request.username}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid username or password",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # Verify password
        if not verify_password(request.password, user["password_hash"]):
            logger.warning(f"❌ Invalid password for: {request.username}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid username or password",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # Create access token
        access_token = create_access_token(
            data={"sub": user["username"], "email": user["email"]}
        )
        
        logger.info(f"✅ Login successful: {request.username}")
        
        return {
            "success": True,
            "access_token": access_token,
            "token_type": "bearer",
            "username": user["username"],
            "email": user["email"],
            "full_name": user.get("full_name", user["username"])
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Login error: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Login failed: {str(e)}"
        )


@router.post("/register")
async def register(request: RegisterRequest):
    """
    Register new user
    """
    try:
        logger.info(f"📝 Register attempt: {request.username}")
        
        # Check if user already exists
        if request.username in users_db:
            logger.warning(f"❌ Username already exists: {request.username}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username already exists"
            )
        
        # Check if email already exists
        for user in users_db.values():
            if user["email"].lower() == request.email.lower():
                logger.warning(f"❌ Email already exists: {request.email}")
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Email already registered"
                )
        
        # Create new user
        new_user = {
            "username": request.username,
            "email": request.email,
            "full_name": request.full_name or request.username,
            "password_hash": get_password_hash(request.password),
            "created_at": datetime.now().isoformat()
        }
        
        users_db[request.username] = new_user
        logger.info(f"✅ Registration successful: {request.username}")
        
        # Create access token
        access_token = create_access_token(
            data={"sub": new_user["username"], "email": new_user["email"]}
        )
        
        return {
            "success": True,
            "message": "User registered successfully",
            "access_token": access_token,
            "token_type": "bearer",
            "username": new_user["username"],
            "email": new_user["email"],
            "full_name": new_user["full_name"]
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Registration error: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Registration failed: {str(e)}"
        )


@router.get("/me")
async def get_current_user(token: str):
    """
    Get current user info from token
    """
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username = payload.get("sub")
        if username not in users_db:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found"
            )
        
        user = users_db[username]
        return {
            "success": True,
            "username": user["username"],
            "email": user["email"],
            "full_name": user.get("full_name", user["username"])
        }
        
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired"
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )
    except Exception as e:
        logger.error(f"❌ Get user error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get user: {str(e)}"
        )