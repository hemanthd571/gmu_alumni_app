import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../config/app_config.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _isLoggedIn = false;
  bool _hasSubmittedFeedback = false;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _isLoggedIn;
  bool get hasSubmittedFeedback => _hasSubmittedFeedback;

  void markFeedbackSubmitted() async {
    _hasSubmittedFeedback = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (_user != null) {
      await prefs.setBool('has_feedback_${_user!.id}', true);
    }
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(AppConfig.isLoggedInKey) ?? false;
    _token = prefs.getString(AppConfig.tokenKey);
    
    if (_isLoggedIn && _token != null) {
      final userData = prefs.getString(AppConfig.userDataKey);
      if (userData != null) {
        _user = UserModel.fromJson(json.decode(userData));
        _hasSubmittedFeedback = prefs.getBool('has_feedback_${_user!.id}') ?? false;
      }
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      print('🔐 Attempting login for: $email');
      
      // Import dio for API call
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));
      
      final response = await dio.post(
        '/auth/login.php',
        data: {
          'email': email,
          'password': password,
        },
      );
      
      print('📥 FULL LOGIN RESPONSE: ${json.encode(response.data)}');
      print("sonal");
      if (response.data['success']) {
        final userData = Map<String, dynamic>.from(response.data['user']);
        final token = response.data['token'];
        
        // DEBUG: Scan for any key containing "director"
        response.data.forEach((key, value) {
          if (key.toLowerCase().contains('director')) {
            print('🎯 FOUND DIRECTOR KEY AT TOP LEVEL: $key = $value');
            userData['is_director'] = value;
          }
        });
        
        userData.forEach((key, value) {
          if (key.toLowerCase().contains('director')) {
            print('🎯 FOUND DIRECTOR KEY IN USER DATA: $key = $value');
          }
        });
        
        print('✅ Login successful! Token: ${token.substring(0, 10)}...');
        print('👤 Final User data for model: $userData');
        
        _user = UserModel.fromJson(userData);
        _token = token;
        _isLoggedIn = true;
        
        final prefs = await SharedPreferences.getInstance();
        _hasSubmittedFeedback = prefs.getBool('has_feedback_${_user!.id}') ?? false;
        await prefs.setBool(AppConfig.isLoggedInKey, true);
        await prefs.setString(AppConfig.tokenKey, _token!);
        await prefs.setString(AppConfig.userDataKey, json.encode(_user!.toJson()));
        
        print('💾 Token saved to SharedPreferences');
        
        notifyListeners();
        return true;
      }
      else {
        print("sonal");
        print('❌ Login failed: ${response.data['message']}');
        return false;
      }
    } catch (e) {
      print('💥 Login error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String department,
    required String batch,
    required String usn,
    required String phoneNumber,
  }) async {
    try {
      print('📝 Attempting registration for: $email');
      
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        validateStatus: (status) => true, // Accept all status codes to handle 400/500 manually
      ));
      
      final response = await dio.post(
        '/auth/register.php',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'department': department,
          'batch': batch, // Passout Year
          'usn': usn,
          'phone_number': phoneNumber,
        },
      );
      
      print('📥 REGISTRATION RESPONSE [${response.statusCode}]: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Handle success (sometimes API returns 200 even for logic errors if not using standard codes, but our script uses 201 for success)
        if (response.data is Map && response.data['success'] == true) {
             return {'success': true, 'message': response.data['message']};
        }
      }
      
      // Handle known error responses
      if (response.data is Map && response.data['message'] != null) {
          return {'success': false, 'message': response.data['message']};
      }
      
      return {'success': false, 'message': 'Registration failed with status ${response.statusCode}'};

    } catch (e) {
      print('💥 Registration error: $e');
      return {'success': false, 'message': 'Connection error. Please check your internet.'};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    _user = null;
    _token = null;
    _isLoggedIn = false;
    
    notifyListeners();
  }

  Future<void> updateUser(Map<String, dynamic> userData) async {
    _user = UserModel.fromJson(userData);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.userDataKey, json.encode(_user!.toJson()));
    notifyListeners();
  }
}
