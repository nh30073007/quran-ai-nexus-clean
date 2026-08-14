import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';
  
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 120),
    receiveTimeout: const Duration(seconds: 120),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  static String? _token;

  static void setToken(String token) {
    _token = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
    print('🔑 Token set: ${token.substring(0, 20)}...');
  }

  static void clearToken() {
    _token = null;
    _dio.options.headers.remove('Authorization');
    print('🔑 Token cleared');
  }

  static String? getToken() => _token;

  // Check internet connection
  static Future<bool> _hasInternet() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // ==================== AUTH ENDPOINTS ====================

  // ✅ FIXED: Auth - Login (Now sends JSON)
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      if (!await _hasInternet()) {
        throw Exception('No internet connection');
      }
      
      print('🔐 Attempting login: $username');
      
      final response = await _dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
        // ✅ REMOVED the wrong Content-Type header
        // Uses default JSON from BaseOptions
      );
      
      print('✅ Login successful');
      print('📥 Response: ${response.data}');
      return response.data;
      
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Connection error: Please check if the backend server is running on $baseUrl');
      }
      
      // Print detailed error
      print('❌ Login error: ${e.message}');
      if (e.response != null) {
        print('❌ Status: ${e.response?.statusCode}');
        print('❌ Response: ${e.response?.data}');
      }
      
      // Try to extract meaningful error message
      if (e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data.containsKey('detail')) {
          throw Exception('Login failed: ${data['detail']}');
        }
      }
      
      throw Exception('Login failed: ${e.message}');
    } catch (e) {
      print('❌ Login error: $e');
      throw Exception('Login failed: $e');
    }
  }

  // ✅ FIXED: Auth - Register (Now sends JSON)
  static Future<Map<String, dynamic>> register(
    String username, 
    String email, 
    String password,
    {String? fullName}
  ) async {
    try {
      if (!await _hasInternet()) {
        throw Exception('No internet connection');
      }
      
      print('📝 Registering: $username');
      print('📧 Email: $email');
      
      final response = await _dio.post(
        '/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'full_name': fullName ?? username,
        },
        // ✅ Uses default JSON
      );
      
      print('✅ Registration successful');
      print('📥 Response: ${response.data}');
      return response.data;
      
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Connection error: Please check if the backend server is running on $baseUrl');
      }
      
      print('❌ Registration error: ${e.message}');
      if (e.response != null) {
        print('❌ Status: ${e.response?.statusCode}');
        print('❌ Response: ${e.response?.data}');
      }
      
      if (e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data.containsKey('detail')) {
          final detail = data['detail'];
          if (detail is List) {
            final errors = detail.map((e) => e['msg']).join(', ');
            throw Exception('Registration failed: $errors');
          } else {
            throw Exception('Registration failed: $detail');
          }
        }
      }
      
      throw Exception('Registration failed: ${e.message}');
    } catch (e) {
      print('❌ Registration error: $e');
      throw Exception('Registration failed: $e');
    }
  }

  // ==================== QURAN INTELLIGENT AGENT ENDPOINTS ====================

  // Ask Quran - Uses intelligent agent routing
  static Future<Map<String, dynamic>> askQuran(String query, {String language = 'en'}) async {
    try {
      if (!await _hasInternet()) {
        throw Exception('No internet connection');
      }
      
      print('📖 Ask Quran: $query');
      final response = await _dio.post(
        '/quran/ask',
        data: {
          'query': query,
          'language': language,
        },
      );
      print('✅ Ask Quran response received');
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to server. Please ensure backend is running on port 8000');
      }
      print('❌ Ask Quran error: ${e.message}');
      throw Exception('Ask failed: ${e.message}');
    } catch (e) {
      print('❌ Ask Quran error: $e');
      throw Exception('Ask failed: $e');
    }
  }

  // Chat with Quran - With conversation history
  static Future<Map<String, dynamic>> chatQuran(
    String query, {
    List<Map<String, String>> history = const [],
    String language = 'en',
  }) async {
    try {
      if (!await _hasInternet()) {
        throw Exception('No internet connection');
      }
      
      print('💬 Chat Quran: $query');
      print('📜 History length: ${history.length}');
      
      final response = await _dio.post(
        '/quran/chat',
        data: {
          'query': query,
          'history': history,
          'language': language,
        },
      );
      print('✅ Chat response received');
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to server. Please ensure backend is running on port 8000');
      }
      print('❌ Chat error: ${e.message}');
      throw Exception('Chat failed: ${e.message}');
    } catch (e) {
      print('❌ Chat error: $e');
      throw Exception('Chat failed: $e');
    }
  }

  // Search Quran verses
  static Future<Map<String, dynamic>> searchQuran(
    String query, {
    int limit = 5,
    String language = 'en',
  }) async {
    try {
      if (!await _hasInternet()) {
        throw Exception('No internet connection');
      }
      
      print('🔍 Search Quran: $query');
      final response = await _dio.get(
        '/quran/search',
        queryParameters: {
          'query': query,
          'limit': limit,
          'language': language,
        },
      );
      print('✅ Search response received');
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to server. Please ensure backend is running on port 8000');
      }
      print('❌ Search error: ${e.message}');
      throw Exception('Search failed: ${e.message}');
    } catch (e) {
      print('❌ Search error: $e');
      throw Exception('Search failed: $e');
    }
  }

  // Get specific verse by Surah:Verse
  static Future<Map<String, dynamic>> getVerse(int surah, int verse) async {
    try {
      if (!await _hasInternet()) {
        throw Exception('No internet connection');
      }
      
      print('📖 Get Verse: $surah:$verse');
      final response = await _dio.get(
        '/quran/verse/$surah:$verse',
      );
      print('✅ Verse response received');
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to server');
      }
      print('❌ Get verse error: ${e.message}');
      throw Exception('Get verse failed: ${e.message}');
    } catch (e) {
      print('❌ Get verse error: $e');
      throw Exception('Get verse failed: $e');
    }
  }

  // Get entire Surah
  static Future<Map<String, dynamic>> getSurah(int surahNumber) async {
    try {
      if (!await _hasInternet()) {
        throw Exception('No internet connection');
      }
      
      print('📖 Get Surah: $surahNumber');
      final response = await _dio.get(
        '/quran/surah/$surahNumber',
      );
      print('✅ Surah response received');
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to server');
      }
      print('❌ Get surah error: ${e.message}');
      throw Exception('Get surah failed: ${e.message}');
    } catch (e) {
      print('❌ Get surah error: $e');
      throw Exception('Get surah failed: $e');
    }
  }

  // Get Tafsir for a verse
  static Future<Map<String, dynamic>> getTafsir(String query, {String language = 'en'}) async {
    try {
      if (!await _hasInternet()) {
        throw Exception('No internet connection');
      }
      
      print('📚 Get Tafsir: $query');
      final response = await _dio.post(
        '/quran/tafsir',
        data: {
          'query': query,
          'language': language,
        },
      );
      print('✅ Tafsir response received');
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to server');
      }
      print('❌ Tafsir error: ${e.message}');
      throw Exception('Tafsir failed: ${e.message}');
    } catch (e) {
      print('❌ Tafsir error: $e');
      throw Exception('Tafsir failed: $e');
    }
  }

  // Get Fiqh Ruling
  static Future<Map<String, dynamic>> getFiqhRuling(String query, {String language = 'en'}) async {
    try {
      if (!await _hasInternet()) {
        throw Exception('No internet connection');
      }
      
      print('⚖️ Get Fiqh: $query');
      final response = await _dio.post(
        '/quran/fiqh',
        data: {
          'query': query,
          'language': language,
        },
      );
      print('✅ Fiqh response received');
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to server');
      }
      print('❌ Fiqh error: ${e.message}');
      throw Exception('Fiqh failed: ${e.message}');
    } catch (e) {
      print('❌ Fiqh error: $e');
      throw Exception('Fiqh failed: $e');
    }
  }

  // Get Spiritual Guidance
  static Future<Map<String, dynamic>> getSpiritualGuidance(String query, {String language = 'en'}) async {
    try {
      if (!await _hasInternet()) {
        throw Exception('No internet connection');
      }
      
      print('✨ Get Spiritual: $query');
      final response = await _dio.post(
        '/quran/spiritual',
        data: {
          'query': query,
          'language': language,
        },
      );
      print('✅ Spiritual response received');
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to server');
      }
      print('❌ Spiritual error: ${e.message}');
      throw Exception('Spiritual failed: ${e.message}');
    } catch (e) {
      print('❌ Spiritual error: $e');
      throw Exception('Spiritual failed: $e');
    }
  }

  // Get Hadith
  static Future<Map<String, dynamic>> getHadith(String query, {String language = 'en'}) async {
    try {
      if (!await _hasInternet()) {
        throw Exception('No internet connection');
      }
      
      print('📜 Get Hadith: $query');
      final response = await _dio.post(
        '/quran/hadith',
        data: {
          'query': query,
          'language': language,
        },
      );
      print('✅ Hadith response received');
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to server');
      }
      print('❌ Hadith error: ${e.message}');
      throw Exception('Hadith failed: ${e.message}');
    } catch (e) {
      print('❌ Hadith error: $e');
      throw Exception('Hadith failed: $e');
    }
  }

  // Detect Intent (for testing)
  static Future<Map<String, dynamic>> detectIntent(String query) async {
    try {
      if (!await _hasInternet()) {
        throw Exception('No internet connection');
      }
      
      print('🎯 Detect Intent: $query');
      final response = await _dio.get(
        '/quran/intent/${Uri.encodeComponent(query)}',
      );
      print('✅ Intent detection response received');
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to server');
      }
      print('❌ Intent detection error: ${e.message}');
      throw Exception('Intent detection failed: ${e.message}');
    } catch (e) {
      print('❌ Intent detection error: $e');
      throw Exception('Intent detection failed: $e');
    }
  }

  // ==================== FEED ENDPOINTS ====================

  // Feed Posts
  static Future<List<dynamic>> getPosts({int limit = 10, int offset = 0}) async {
    try {
      print('📊 Fetching posts...');
      final response = await _dio.get(
        '/feed/posts',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );
      print('📊 Posts fetched: ${response.data?.length}');
      return response.data;
    } on DioException catch (e) {
      print('❌ Get posts error: ${e.message}');
      return [];
    } catch (e) {
      print('❌ Get posts error: $e');
      return [];
    }
  }

  // Feed News
  static Future<List<dynamic>> getNews() async {
    try {
      final response = await _dio.get('/feed/news');
      return response.data;
    } on DioException catch (e) {
      print('Get news error: ${e.message}');
      return [];
    } catch (e) {
      return [];
    }
  }

  // Feed Status
  static Future<List<dynamic>> getStatus() async {
    try {
      final response = await _dio.get('/feed/status');
      return response.data;
    } on DioException catch (e) {
      print('Get status error: ${e.message}');
      return [];
    } catch (e) {
      return [];
    }
  }

  // ==================== GUIDANCE ENDPOINTS ====================

  // Life Guidance
  static Future<Map<String, dynamic>> getLifeGuidance({
    required String topic,
    required String feeling,
    String language = 'en',
  }) async {
    try {
      if (!await _hasInternet()) {
        throw Exception('No internet connection');
      }
      
      print('🌙 Life Guidance: $topic, $feeling');
      final response = await _dio.post(
        '/guidance/life',
        data: {
          'topic': topic,
          'feeling': feeling,
          'language': language,
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to server');
      }
      throw Exception('Guidance failed: ${e.message}');
    } catch (e) {
      throw Exception('Guidance failed: $e');
    }
  }

  // Daily Guidance
  static Future<Map<String, dynamic>> getDailyGuidance({String language = 'en'}) async {
    try {
      if (!await _hasInternet()) {
        throw Exception('No internet connection');
      }
      
      print('🌅 Daily Guidance');
      final response = await _dio.get(
        '/guidance/daily',
        queryParameters: {'language': language},
      );
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to server');
      }
      throw Exception('Daily guidance failed: ${e.message}');
    } catch (e) {
      throw Exception('Daily guidance failed: $e');
    }
  }

  // ==================== ADMIN ENDPOINTS ====================

  // Admin - Create Post (without media)
  static Future<Map<String, dynamic>> createPost({
    required String text,
    bool isOfficial = false,
  }) async {
    try {
      if (_token == null) {
        throw Exception('Not authenticated. Please login first.');
      }
      
      print('📝 Creating post...');
      final response = await _dio.post(
        '/admin/upload/post',
        data: {
          'text': text,
          'is_official': isOfficial,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_token',
          },
        ),
      );
      print('✅ Post created!');
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      }
      if (e.response?.statusCode == 422) {
        throw Exception('Invalid data. Please check your input.');
      }
      print('❌ Create post error: ${e.message}');
      throw Exception('Create post failed: ${e.message}');
    } catch (e) {
      print('❌ Create post error: $e');
      throw Exception('Create post failed: $e');
    }
  }

  // Admin - Create Post with Media
  static Future<Map<String, dynamic>> createPostWithMedia({
    required String text,
    bool isOfficial = false,
    String? imageData,
    String? videoData,
    String? imageRatio,
  }) async {
    try {
      if (_token == null) {
        throw Exception('Not authenticated. Please login first.');
      }
      
      print('📝 Creating post with media...');
      print('📝 Text: $text');
      print('📝 Has image: ${imageData != null}');
      print('📝 Has video: ${videoData != null}');
      print('📝 Image ratio: $imageRatio');
      
      final Map<String, dynamic> data = {
        'text': text,
        'is_official': isOfficial,
        'image_ratio': imageRatio ?? 'portrait',
      };
      
      if (imageData != null && imageData.isNotEmpty) {
        data['image_data'] = imageData;
        print('📝 Image data size: ${imageData.length}');
      }
      
      if (videoData != null && videoData.isNotEmpty) {
        data['video_data'] = videoData;
        print('📝 Video data size: ${videoData.length}');
      }
      
      final response = await _dio.post(
        '/admin/upload/post',
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_token',
          },
        ),
      );
      print('✅ Post with media created!');
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      }
      if (e.response?.statusCode == 422) {
        throw Exception('Invalid data. Please check your input.');
      }
      print('❌ Create post with media error: ${e.message}');
      throw Exception('Create post failed: ${e.message}');
    } catch (e) {
      print('❌ Create post with media error: $e');
      throw Exception('Create post failed: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  // Parse agent response for display
  static String parseAgentResponse(Map<String, dynamic> response) {
    try {
      if (response['success'] == true) {
        final data = response['data'];
        if (data != null) {
          // If there's a 'text' field in data
          if (data['text'] != null) {
            return data['text'];
          }
          // If data itself is a string
          if (data is String) {
            return data;
          }
          // Try to get text from response directly
          if (response['text'] != null) {
            return response['text'];
          }
        }
        return 'Response received but no text found.';
      }
      return 'Error: ${response['message'] ?? 'Unknown error'}';
    } catch (e) {
      return 'Failed to parse response: $e';
    }
  }

  // Get citations from response
  static List<Map<String, dynamic>> getCitations(Map<String, dynamic> response) {
    try {
      final data = response['data'];
      if (data != null && data['citations'] != null) {
        return List<Map<String, dynamic>>.from(data['citations']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get intent from response
  static String getIntent(Map<String, dynamic> response) {
    try {
      final data = response['data'];
      if (data != null && data['intent'] != null) {
        return data['intent'];
      }
      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  // Get confidence score from response
  static double getConfidence(Map<String, dynamic> response) {
    try {
      final data = response['data'];
      if (data != null && data['confidence'] != null) {
        return data['confidence'].toDouble();
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Get sources from response
  static List<String> getSources(Map<String, dynamic> response) {
    try {
      final data = response['data'];
      if (data != null && data['sources'] != null) {
        return List<String>.from(data['sources']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}