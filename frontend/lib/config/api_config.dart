// lib/config/api_config.dart
class ApiConfig {
  // Base URL for your backend API
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5001', // Android emulator localhost
    // For iOS simulator, use: 'http://localhost:5001'
    // For physical device, use your computer's IP: 'http://192.168.x.x:5001'
    // For production, use: 'https://your-production-api.com'
  );

  static const String apiPath = '/api';
  
  // Full API base URL
  static String get apiBaseUrl => '$baseUrl$apiPath';
  
  // Endpoints
  static String get authEndpoint => '$apiBaseUrl/auth';
  static String get usersEndpoint => '$apiBaseUrl/users';
  static String get projectsEndpoint => '$apiBaseUrl/projects';
  
  // Profile endpoints
  static String get profilePictureEndpoint => '$usersEndpoint/profile/picture';
  static String get profileEndpoint => '$usersEndpoint/profile';
  
  // Timeout durations
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // File upload limits
  static const int maxImageSizeMB = 5;
  static const int maxImageSizeBytes = maxImageSizeMB * 1024 * 1024;
  
  // Supported image formats
  static const List<String> supportedImageFormats = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  ];
  
  // Helper method to check if running on emulator
  static bool get isEmulator {
    // You can enhance this with platform checking
    return baseUrl.contains('10.0.2.2');
  }
}