import 'package:flutter/material.dart';

class AppConfig {
  // API Configuration - Using your server URL
  // static const String baseUrl = 'https://leap.gmu.ac.in/alumni';
  static const String baseUrl =
      'http://172.21.3.247/alumni'; // Local Testing IP
  static const String apiUrl = '$baseUrl/api';
  // Colors matching website theme
  static const Color primaryColor = Color(0xFF5B1F1F);
  static const Color secondaryColor = Color(0xFFECC35C);
  static const Color bgLight = Color(0xFFF5F7FB);
  static const Color textColor = Color(0xFF333333);
  static const Color textLight = Color(0xFF666666);

  // API Endpoints
  static const String loginEndpoint = '$apiUrl/auth/login.php';
  static const String registerEndpoint = '$apiUrl/auth/register.php';
  static const String logoutEndpoint = '$apiUrl/auth/logout.php';
  static const String noticeboardEndpoint = '$apiUrl/noticeboard/list.php';
  static const String newsEndpoint = '$apiUrl/news/list.php';
  static const String eventsEndpoint = '$apiUrl/events/list.php';
  static const String jobsEndpoint = '$apiUrl/jobs/list.php';
  static const String galleriesEndpoint = '$apiUrl/galleries/list.php';
  static const String coreTeamEndpoint = '$apiUrl/core-team/list.php';
  static const String proudAlumniEndpoint = '$apiUrl/proud-alumni/list.php';
  static const String directoryEndpoint = '$apiUrl/alumni/directory.php';
  static const String profileEndpoint = '$apiUrl/profile/me.php';
  static const String announcementsEndpoint = '$apiUrl/announcements/list.php';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userDataKey = 'user_data';
  static const String isLoggedInKey = 'is_logged_in';

  // Helper to get full URL for profile images
  static String getProfileImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    // Normalize slashes
    String normalizedPath = path.replaceAll('\\', '/');
    if (normalizedPath.startsWith('/')) {
      normalizedPath = normalizedPath.substring(1);
    }

    // Most profile images are filename-only and stored in api/uploads/profile_images
    // This includes 'default.jpg' and 'profile_id_timestamp.jpg'

    if (normalizedPath.contains('profiles/')) {
      // Support legacy paths if they come from the DB
      return '$apiUrl/uploads/${normalizedPath.replaceFirst('profiles/', 'profile_images/')}';
    }

    if (normalizedPath.contains('profile_images/')) {
      return '$apiUrl/$normalizedPath';
    }

    return '$apiUrl/uploads/profile_images/$normalizedPath';
  }

  // Helper to get full URL for post media
  static String getPostImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    // Normalize slashes
    String normalizedPath = path.replaceAll('\\', '/');
    if (normalizedPath.startsWith('/')) {
      normalizedPath = normalizedPath.substring(1);
    }

    // If it already looks like a path from base, just prepend baseUrl
    if (normalizedPath.contains('/') || normalizedPath.startsWith('uploads/')) {
      return '$baseUrl/$normalizedPath';
    }

    return '$baseUrl/uploads/posts/$normalizedPath';
  }

  // Helper to get full URL for event images
  static String getEventImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    // Normalize slashes
    String normalizedPath = path.replaceAll('\\', '/');
    if (normalizedPath.startsWith('/')) {
      normalizedPath = normalizedPath.substring(1);
    }

    // If it already looks like a path from base, just prepend baseUrl
    if (normalizedPath.contains('/') || normalizedPath.startsWith('uploads/')) {
      return '$baseUrl/$normalizedPath';
    }

    return '$baseUrl/uploads/events/$normalizedPath';
  }
}
