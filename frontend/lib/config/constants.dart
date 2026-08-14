class AppConstants {
  // ==========================================
  // 🔗 API BASE URL
  // ==========================================
  
  // 🚀 Production URL (Render - Live Backend)
  static const String baseUrl = 'https://quran-ai-nexus.onrender.com';
  
  // 🏠 Development URL (Local - untuk testing)
  // static const String baseUrl = 'http://127.0.0.1:8000';
  
  // ==========================================
  // 📡 API ENDPOINTS
  // ==========================================
  
  // Auth
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authMe = '/auth/me';
  static const String authChangePassword = '/auth/change-password';
  
  // Quran
  static const String quranAsk = '/quran/ask';
  static const String quranChat = '/quran/chat';
  static const String quranSearch = '/quran/search';
  static const String quranVerse = '/quran/verse';
  static const String quranSurah = '/quran/surah';
  static const String quranTafsir = '/quran/tafsir';
  static const String quranFiqh = '/quran/fiqh';
  static const String quranSpiritual = '/quran/spiritual';
  static const String quranHadith = '/quran/hadith';
  static const String quranIntent = '/quran/intent';
  
  // Feed
  static const String feedPosts = '/feed/posts';
  static const String feedNews = '/feed/news';
  static const String feedStatus = '/feed/status';
  
  // Admin
  static const String adminPost = '/admin/upload/post';
  static const String adminNews = '/admin/upload/news';
  static const String adminStatus = '/admin/upload/status';
  static const String adminDeletePost = '/admin/post';
  static const String adminDeleteNews = '/admin/news';
  static const String adminDeleteStatus = '/admin/status';
  
  // Guidance
  static const String guidanceLife = '/guidance/life';
  static const String guidanceDaily = '/guidance/daily';
  static const String guidanceTopics = '/guidance/topics';
  static const String guidanceCustom = '/guidance/custom';
  
  // Media
  static const String mediaList = '/media/list';
  static const String mediaUpload = '/media/upload';
  
  // ==========================================
  // 💾 SHAREDPREFERENCES KEYS
  // ==========================================
  
  static const String prefToken = 'auth_token';
  static const String prefUsername = 'username';
  static const String prefEmail = 'email';
  static const String prefFullName = 'full_name';
  static const String prefTheme = 'theme';
  static const String prefLanguage = 'language';
  static const String prefIsLoggedIn = 'is_logged_in';
  static const String prefIsAdmin = 'is_admin';
  static const String prefUserId = 'user_id';
  
  // ==========================================
  // 🎨 COLORS
  // ==========================================
  
  static const int primaryColor = 0xFF1E90FF;
  static const int secondaryColor = 0xFF87CEEB;
  static const int accentColor = 0xFFFFD700;
  static const int successColor = 0xFF4CAF50;
  static const int errorColor = 0xFFE53935;
  static const int warningColor = 0xFFFF9800;
  
  // ==========================================
  // ⏱️ ANIMATION DURATIONS
  // ==========================================
  
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration loadingDelay = Duration(milliseconds: 500);
  
  // ==========================================
  // 📱 APP INFO
  // ==========================================
  
  static const String appName = 'Quran AI Nexus';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'AI-powered Quranic assistant with Tafsir, Fiqh, Spiritual, and Hadith agents';
  
  // ==========================================
  // 🌐 SUPPORTED LANGUAGES
  // ==========================================
  
  static const List<String> supportedLanguages = ['en', 'bn'];
  static const Map<String, String> languageNames = {
    'en': 'English',
    'bn': 'বাংলা',
  };
  
  // ==========================================
  // 🧠 AGENT NAMES (for display)
  // ==========================================
  
  static const Map<String, String> agentNames = {
    'tafsir_agent': 'Tafsir',
    'fiqh_agent': 'Fiqh',
    'spiritual_agent': 'Spiritual',
    'hadith_agent': 'Hadith',
    'general_agent': 'General',
  };
  
  static const Map<String, int> agentColors = {
    'tafsir_agent': 0xFF9C27B0,
    'fiqh_agent': 0xFF3F51B5,
    'spiritual_agent': 0xFF00897B,
    'hadith_agent': 0xFF795548,
    'general_agent': 0xFF1E90FF,
  };
}

// ==========================================
// 📦 ENVIRONMENT CONFIGURATION
// ==========================================

/// Use this to check if app is running in production
bool get isProduction => AppConstants.baseUrl.contains('onrender.com') || 
                         AppConstants.baseUrl.contains('render.com');

/// Use this to check if app is running in development
bool get isDevelopment => AppConstants.baseUrl.contains('127.0.0.1') || 
                          AppConstants.baseUrl.contains('localhost');