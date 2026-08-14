from sqlalchemy import create_engine, Column, Integer, String, Text, DateTime, Boolean, BLOB, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from datetime import datetime
from .config import settings

# Database setup
engine = create_engine(
    settings.DATABASE_URL,
    connect_args={"check_same_thread": False} if "sqlite" in settings.DATABASE_URL else {}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# ==================== USER MODELS ====================

class Admin(Base):
    __tablename__ = "admins"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    password = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)

# ==================== FEED MODELS ====================

class Post(Base):
    __tablename__ = "posts"
    id = Column(Integer, primary_key=True, index=True)
    text = Column(Text)
    image = Column(BLOB, nullable=True)
    video = Column(BLOB, nullable=True)
    is_official = Column(Boolean, default=False)
    added_by = Column(String)
    added_at = Column(DateTime, default=datetime.utcnow)

class NewsCard(Base):
    __tablename__ = "news_cards"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    description = Column(Text)
    image = Column(BLOB, nullable=True)
    url = Column(String, nullable=True)
    source = Column(String)
    added_by = Column(String)
    added_at = Column(DateTime, default=datetime.utcnow)

class StatusUpdate(Base):
    __tablename__ = "status_updates"
    id = Column(Integer, primary_key=True, index=True)
    text = Column(Text)
    added_by = Column(String)
    added_at = Column(DateTime, default=datetime.utcnow)

# ==================== CHAT MODELS ====================

class ChatHistory(Base):
    __tablename__ = "chat_history"
    id = Column(Integer, primary_key=True, index=True)
    user_query = Column(Text)
    ai_response = Column(Text)
    verse_reference = Column(String)
    timestamp = Column(DateTime, default=datetime.utcnow)
    user_id = Column(String, nullable=True)

class AskQuranHistory(Base):
    __tablename__ = "ask_quran_history"
    id = Column(Integer, primary_key=True, index=True)
    user_query = Column(Text)
    ai_response = Column(Text)
    verse_reference = Column(String)
    timestamp = Column(DateTime, default=datetime.utcnow)
    user_id = Column(String, nullable=True)

# ==================== MEDIA MODELS ====================

class MediaContent(Base):
    __tablename__ = "media_content"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    description = Column(Text)
    image = Column(BLOB, nullable=True)
    video = Column(BLOB, nullable=True)
    content_type = Column(String)
    added_by = Column(String)
    added_at = Column(DateTime, default=datetime.utcnow)

# ==================== CITATION MODELS (NEW) ====================

class Citation(Base):
    __tablename__ = "citations"
    id = Column(Integer, primary_key=True, index=True)
    response_id = Column(String, index=True)
    citation_type = Column(String)  # 'quran', 'hadith', 'tafsir'
    source_ref = Column(String)  # e.g., "2:255" or "Bukhari"
    text = Column(Text)
    confidence = Column(Integer, default=95)  # 0-100
    created_at = Column(DateTime, default=datetime.utcnow)

# ==================== DEPENDENCY ====================

def get_db():
    """Dependency for getting database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Create all tables
Base.metadata.create_all(bind=engine)

print("✅ Database tables created successfully!")