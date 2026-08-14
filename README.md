# 📖 Quran AI Nexus

An intelligent AI-powered Quranic assistant with Tafsir, Fiqh, Spiritual, and Hadith agents.

## 🚀 Features
- 🤖 5 Specialized AI Agents (Tafsir, Fiqh, Spiritual, Hadith, General)
- 🔍 Semantic Search with FAISS + Embeddings
- 💬 Chat with Quran
- 📚 Tafsir (Ibn Kathir, Jalalayn)
- ✨ Sufi Insights (Rumi, Ibn Arabi)
- ⚖️ Fiqh Rulings
- 🌐 Bengali & English Support
- 🔐 JWT Authentication

## 📁 Project Structure
quran_ai_nexus/
├── backend/ # FastAPI Backend
├── frontend/ # Flutter Frontend
└── ...

text

## 🛠️ Tech Stack
- **Backend**: FastAPI, Python, Sentence-Transformers, FAISS
- **Frontend**: Flutter, Dart
- **Database**: SQLite (for auth)
- **Deployment**: Render.com

## 🚀 Quick Start

### Backend
```bash
cd backend
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your settings
uvicorn app.main:app --reload --port 8000
Frontend
bash
cd frontend
flutter pub get
flutter run -d chrome
🔐 Environment Variables
env
SECRET_KEY=your-secret-key
ADMIN_USERNAME=admin
ADMIN_PASSWORD=strong-password
ENVIRONMENT=development
📡 API Endpoints
POST /auth/login - Login

POST /auth/register - Register

POST /quran/ask - Ask Quran

POST /quran/chat - Chat with Quran

📄 License
MIT License

👤 Author
A.H.M.nazmul hasan

🙏 Acknowledgments
Quran Dataset: quran_en1.json

Tafsir: Ibn Kathir, Jalalayn

Sufi: Rumi, Ibn Arabi

text

---

### 3. **`.env.example`** )

```env
# ==========================================
# QURAN AI NEXUS - ENVIRONMENT VARIABLES
# Copy this file to .env and fill in your values
# ==========================================

# Security
SECRET_KEY=your-very-long-secret-key-min-32-characters
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Admin - Change these!
ADMIN_USERNAME=admin
ADMIN_PASSWORD=your-strong-password-here

# Environment
ENVIRONMENT=development
DEBUG=true
LOG_LEVEL=INFO

# Server
PORT=8000
HOST=0.0.0.0

# CORS (add your frontend URLs)
CORS_ORIGINS=http://localhost:3000,http://localhost:8000,https://yourdomain.com

# API Keys (if needed)
HF_TOKEN=your_huggingface_token
OPENAI_API_KEY=your_openai_key

# Rate Limiting
RATE_LIMIT=100
RATE_LIMIT_PERIOD=60