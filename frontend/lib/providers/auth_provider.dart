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

  User? get user => _user;
  bool get isAuthenticated => _user != null && _user?.token != null && _user!.token!.isNotEmpty;
  bool get isLoading => _isLoading;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isLoggedIn => _isLoggedIn;
  String? get token => _user?.token;

  // ✅ FIXED: Login with proper response handling
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🔐 Attempting login: $username');
      final response = await ApiService.login(username, password);
      print('📥 Login response: $response');
      
      // ✅ Check for success or access_token
      if (response['success'] == true || response['access_token'] != null) {
        final token = response['access_token'] ?? response['token'];
        // Check if user is admin (either from response or username)
        final isAdmin = response['is_admin'] ?? (username.toLowerCase() == 'admin');
        
        _user = User(
          username: response['username'] ?? username,
          email: response['email'] ?? '',
          token: token,
          isAdmin: isAdmin,
        );
        
        // Save to SharedPreferences
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
        // Backend returned success=false
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

  // ✅ FIXED: Register with proper response handling (returns bool)
  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('📝 Registering: $username');
      final response = await ApiService.register(username, email, password);
      print('📥 Register response: $response');
      
      // ✅ Check for success or access_token
      if (response['success'] == true || response['access_token'] != null) {
        final token = response['access_token'] ?? response['token'];
        final isAdmin = response['is_admin'] ?? (username.toLowerCase() == 'admin');
        
        _user = User(
          username: response['username'] ?? username,
          email: response['email'] ?? email,
          token: token,
          isAdmin: isAdmin,
        );
        
        // Save to SharedPreferences
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
        // Backend returned success=false
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
      // Re-throw so the UI can handle the error
      rethrow;
    }
  }

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

  // Force refresh user session
  Future<void> refreshSession() async {
    _loadUser();
    notifyListeners();
  }
}