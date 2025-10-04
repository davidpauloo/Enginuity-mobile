// lib/services/profile_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:chat_app/config/api_config.dart';
import 'package:chat_app/services/auth_service.dart';

class ProfileService {
  final AuthService _authService = AuthService();

  /// Upload profile picture to backend
  /// Returns the new profile picture URL on success
  Future<String> uploadProfilePicture(File imageFile) async {
    try {
      // Get authentication token
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Validate file size
      final fileSizeInBytes = await imageFile.length();
      if (fileSizeInBytes > ApiConfig.maxImageSizeBytes) {
        throw Exception(
          'Image size must be less than ${ApiConfig.maxImageSizeMB}MB',
        );
      }

      // Determine MIME type
      final String mimeType = _getMimeType(imageFile.path);
      if (!ApiConfig.supportedImageFormats.contains(mimeType)) {
        throw Exception('Unsupported image format');
      }

      // Create multipart request
      final uri = Uri.parse(ApiConfig.profilePictureEndpoint);
      var request = http.MultipartRequest('PUT', uri);

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add the file with the correct field name 'profilePic'
      request.files.add(
        await http.MultipartFile.fromPath(
          'profilePic', // Must match backend field name
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      // Send request
      final streamedResponse = await request.send().timeout(
        ApiConfig.connectionTimeout,
        onTimeout: () {
          throw Exception('Upload timeout - please check your connection');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      // Handle response
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final newProfilePicUrl = responseData['profilePic'] as String?;

        if (newProfilePicUrl == null || newProfilePicUrl.isEmpty) {
          throw Exception('Invalid response from server');
        }

        return newProfilePicUrl;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - please login again');
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Invalid request');
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on http.ClientException {
      throw Exception('Network error - please try again');
    } catch (e) {
      // Re-throw with original message if it's already an Exception
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Upload failed: ${e.toString()}');
    }
  }

  /// Determine MIME type from file extension
  String _getMimeType(String path) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Get current user profile
  Future<Map<String, dynamic>> getCurrentProfile() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final uri = Uri.parse(ApiConfig.profileEndpoint);
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - please login again');
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      throw Exception('Failed to get profile: ${e.toString()}');
    }
  }

  /// Update user profile information (name, email, etc.)
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? email,
    String? mobileNumber,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final uri = Uri.parse(ApiConfig.profileEndpoint);
      final body = <String, dynamic>{};
      
      if (fullName != null) body['name'] = fullName;
      if (email != null) body['email'] = email;
      if (mobileNumber != null) body['phone'] = mobileNumber;

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      ).timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - please login again');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Update failed');
      }
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }
}