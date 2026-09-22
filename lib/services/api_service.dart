import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  static void _configureCertificates() {
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        // For development/testing - accept all certificates
        // In production, you should validate the certificate properly
        return true;
      };
      return client;
    };
  }

  static void initialize() {
    _configureCertificates();
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Response> get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    try {
      print('🌐 API Service: Making GET request');
      print('🌐 Base URL: ${AppConfig.apiUrl}');
      print('🌐 Endpoint: $endpoint');
      print('🌐 Full URL: ${AppConfig.apiUrl}$endpoint');
      
      final token = await _getToken();
      final headers = <String, dynamic>{};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        headers['X-Authorization'] = 'Bearer $token';
      }
      
      final response = await _dio.get(
        endpoint, 
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      
      print('✅ API Service: Response received');
      print('✅ Status Code: ${response.statusCode}');
      print('✅ Response Data: ${response.data}');
      
      return response;
    } catch (e) {
      print('❌ API Service ERROR: $e');
      if (e is DioException) {
        print('❌ DioException Type: ${e.type}');
        print('❌ DioException Message: ${e.message}');
        print('❌ Response: ${e.response?.data}');
      }
      rethrow;
    }
  }

  static Future<Response> post(String endpoint, {dynamic data, bool includeAuth = true}) async {
    try {
      print('📤 API Service: Making POST request');
      print('📤 Endpoint: $endpoint');
      print('📤 Data: $data');
      
      final token = await _getToken();
      print('🔑 Token: ${token != null ? "Present (${token.substring(0, 10)}...)" : "Missing"}');
      
      final headers = <String, dynamic>{};
      if (includeAuth && token != null) {
        headers['Authorization'] = 'Bearer $token';
        headers['X-Authorization'] = 'Bearer $token';
      }
      
      final response = await _dio.post(
        endpoint, 
        data: data,
        options: Options(headers: headers),
      );
      
      print('✅ API Service: Response received');
      print('✅ Status Code: ${response.statusCode}');
      print('✅ Response Data: ${response.data}');
      
      return response;
    } catch (e) {
      print('❌ POST Error: $e');
      if (e is DioException) {
        print('❌ DioException Type: ${e.type}');
        print('❌ DioException Message: ${e.message}');
        print('❌ Response: ${e.response?.data}');
        print('❌ Status Code: ${e.response?.statusCode}');
      }
      rethrow;
    }
  }

  static Future<Response> put(String endpoint, {dynamic data}) async {
    try {
      return await _dio.put(endpoint, data: data);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> delete(String endpoint) async {
    try {
      return await _dio.delete(endpoint);
    } catch (e) {
      rethrow;
    }
  }
}
