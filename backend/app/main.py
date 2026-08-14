from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger(__name__)

app = FastAPI(
    title="Quran AI Nexus API",
    description="AI-powered Quranic assistant with Tafsir, Fiqh, Spiritual, and Hadith agents",
    version="1.0.0"
)

# CORS middleware - Allow all origins for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Import routers
try:
    from app.routers import quran
    app.include_router(quran.router)
    logger.info("✅ Quran router loaded")
except Exception as e:
    logger.error(f"❌ Failed to load Quran router: {e}")

# ✅ ADD AUTH ROUTER
try:
    from app.routers import auth
    app.include_router(auth.router)
    logger.info("✅ Auth router loaded")
except Exception as e:
    logger.error(f"❌ Failed to load Auth router: {e}")


@app.get("/")
async def root():
    return {
        "message": "Quran AI Nexus API is running",
        "status": "healthy",
        "version": "1.0.0",
        "endpoints": {
            "/auth/login": "POST - Login",
            "/auth/register": "POST - Register",
            "/auth/me": "GET - Get current user",
            "/quran/ask": "POST - Ask Quran",
            "/quran/chat": "POST - Chat with Quran",
            "/quran/search": "GET - Search Quran",
            "/quran/verse/{surah}:{verse}": "GET - Get specific verse",
            "/quran/surah/{surah_number}": "GET - Get Surah",
            "/quran/tafsir": "POST - Get Tafsir",
            "/quran/fiqh": "POST - Get Fiqh ruling",
            "/quran/spiritual": "POST - Get Spiritual guidance",
            "/quran/hadith": "POST - Get Hadith",
            "/quran/intent/{query}": "GET - Detect intent"
        }
    }


@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "Quran AI Nexus"
    }


@app.on_event("startup")
async def startup_event():
    logger.info("🚀 Quran AI Nexus API started successfully")
    logger.info("📚 Loading agents and datasets...")
    logger.info("🔐 Auth endpoints available at /auth/login and /auth/register")


@app.on_event("shutdown")
async def shutdown_event():
    logger.info("🛑 Quran AI Nexus API shutting down...")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)