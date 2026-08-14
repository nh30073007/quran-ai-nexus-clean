class AppConstants {
  static const String baseUrl = 'http://127.0.0.1:8000';
  
  // API Endpoints
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String quranSearch = '/quran/search';
  static const String quranAsk = '/quran/ask';
  static const String quranChat = '/quran/chat';
  static const String quranTafsir = '/quran/tafsir';
  static const String feedPosts = '/feed/posts';
  static const String feedNews = '/feed/news';
  static const String feedStatus = '/feed/status';
  static const String adminPost = '/admin/upload/post';
  static const String adminNews = '/admin/upload/news';
  static const String adminStatus = '/admin/upload/status';
  static const String adminDeletePost = '/admin/post';
  static const String adminDeleteNews = '/admin/news';
  static const String adminDeleteStatus = '/admin/status';
  static const String guidanceLife = '/guidance/life';
  static const String guidanceDaily = '/guidance/daily';
  static const String guidanceTopics = '/guidance/topics';
  static const String guidanceCustom = '/guidance/custom';
  static const String mediaList = '/media/list';
  static const String mediaUpload = '/media/upload';
  
  // SharedPreferences Keys
  static const String prefToken = 'auth_token';
  static const String prefUsername = 'username';
  static const String prefTheme = 'theme';
  static const String prefLanguage = 'language';
  static const String prefIsLoggedIn = 'is_logged_in';
  static const String prefIsAdmin = 'is_admin';  // ✅ This is correct
  
  // Colors
  static const int primaryColor = 0xFF1E90FF;
  static const int secondaryColor = 0xFF87CEEB;
  static const int accentColor = 0xFFFFD700;
  
  // Animation Durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 2);
}