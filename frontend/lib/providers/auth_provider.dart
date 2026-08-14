import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_ai_nexus/models/user.dart';
import 'package:quran_ai_nexus/services/api_service.dart';
import 'package:quran_ai_nexus/config/constants.dart';

class AuthProvider extends ChangeNotifier {
  final SharedPreferences prefs;
  User? _user;
  bool _isLoading = false;
  bool _isLoggedIn = false;

  AuthProvider(this.prefs) {
    _loadUser();
  }

  void _loadUser() {
    final token = prefs.getString(AppConstants.prefToken);
    final username = prefs.getString(AppConstants.prefUsername);
    final isAdmin = prefs.getBool(AppConstants.prefIsAdmin) ?? false;
    
    if (token != null && username != null && token.isNotEmpty) {
      _user = User(
        username: username,
        email: '',
        token: token,
        isAdmin: isAdmin,
      );
      ApiService.setToken(token);
      _isLoggedIn = true;
      print('✅ User loaded: $username, isAdmin: $isAdmin');
    } else {
      _isLoggedIn = false;
      print('❌ No user session found');
    }
    notifyListeners();
  }

  // ==========================================
  // 📦 GETTERS
  // ==========================================

  User? get user => _user;
  bool get isAuthenticated => _user != null && _user?.token != null && _user!.token!.isNotEmpty;
  bool get isLoading => _isLoading;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isLoggedIn => _isLoggedIn;
  String? get token => _user?.token;
  String? get username => _user?.username;
  String? get email => _user?.email;

  // ==========================================
  // 🔐 LOGIN
  // ==========================================

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🔐 Attempting login: $username');
      final response = await ApiService.login(username, password);
      print('📥 Login response: $response');
      
      if (response['success'] == true || response['access_token'] != null) {
        final token = response['access_token'] ?? response['token'];
        final isAdmin = response['is_admin'] ?? (username.toLowerCase() == 'admin');
        
        _user = User(
          username: response['username'] ?? username,
          email: response['email'] ?? '',
          token: token,
          isAdmin: isAdmin,
        );
        
        await prefs.setString(AppConstants.prefToken, token);
        await prefs.setString(AppConstants.prefUsername, _user!.username);
        await prefs.setBool(AppConstants.prefIsAdmin, isAdmin);
        await prefs.setBool(AppConstants.prefIsLoggedIn, true);
        
        ApiService.setToken(token);
        _isLoggedIn = true;
        
        _isLoading = false;
        notifyListeners();
        print('✅ Login successful! isAdmin: $isAdmin');
        return true;
      } else {
        final errorMsg = response['detail'] ?? response['message'] ?? 'Login failed';
        print('❌ Login failed: $errorMsg');
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
    } catch (e) {
      print('❌ Login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // 📝 REGISTER
  // ==========================================

  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('📝 Registering: $username');
      final response = await ApiService.register(username, email, password);
      print('📥 Register response: $response');
      
      if (response['success'] == true || response['access_token'] != null) {
        final token = response['access_token'] ?? response['token'];
        final isAdmin = response['is_admin'] ?? (username.toLowerCase() == 'admin');
        
        _user = User(
          username: response['username'] ?? username,
          email: response['email'] ?? email,
          token: token,
          isAdmin: isAdmin,
        );
        
        await prefs.setString(AppConstants.prefToken, token);
        await prefs.setString(AppConstants.prefUsername, _user!.username);
        await prefs.setBool(AppConstants.prefIsAdmin, isAdmin);
        await prefs.setBool(AppConstants.prefIsLoggedIn, true);
        
        ApiService.setToken(token);
        _isLoggedIn = true;
        
        _isLoading = false;
        notifyListeners();
        print('✅ Registration successful! isAdmin: $isAdmin');
        return true;
      } else {
        final errorMsg = response['detail'] ?? response['message'] ?? 'Registration failed';
        print('❌ Registration failed: $errorMsg');
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
    } catch (e) {
      print('❌ Registration error: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ==========================================
  // 🚪 LOGOUT
  // ==========================================

  Future<void> logout() async {
    _user = null;
    _isLoggedIn = false;
    ApiService.clearToken();
    await prefs.remove(AppConstants.prefToken);
    await prefs.remove(AppConstants.prefUsername);
    await prefs.remove(AppConstants.prefIsAdmin);
    await prefs.setBool(AppConstants.prefIsLoggedIn, false);
    notifyListeners();
    print('🔓 Logged out');
  }

  // ==========================================
  // 🔄 REFRESH SESSION
  // ==========================================

  Future<void> refreshSession() async {
    _loadUser();
    notifyListeners();
  }

  // ==========================================
  // 🛠️ UPDATE USER
  // ==========================================

  Future<void> updateUser({String? username, String? email, bool? isAdmin}) async {
    if (_user != null) {
      _user = User(
        username: username ?? _user!.username,
        email: email ?? _user!.email,
        token: _user!.token,
        isAdmin: isAdmin ?? _user!.isAdmin,
      );
      
      if (username != null) {
        await prefs.setString(AppConstants.prefUsername, username);
      }
      if (isAdmin != null) {
        await prefs.setBool(AppConstants.prefIsAdmin, isAdmin);
      }
      
      notifyListeners();
      print('✅ User updated: ${_user!.username}, isAdmin: ${_user!.isAdmin}');
    }
  }

  // ==========================================
  // 🧹 CLEAR USER (Emergency)
  // ==========================================

  Future<void> clearUserData() async {
    _user = null;
    _isLoggedIn = false;
    ApiService.clearToken();
    await prefs.remove(AppConstants.prefToken);
    await prefs.remove(AppConstants.prefUsername);
    await prefs.remove(AppConstants.prefIsAdmin);
    await prefs.setBool(AppConstants.prefIsLoggedIn, false);
    notifyListeners();
    print('🧹 User data cleared');
  }
}