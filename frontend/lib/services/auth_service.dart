// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chat_app/key.dart'; // Assuming BACKEND_URL is defined here

// CurrentUser model (as it was likely structured if present, or we'll define it here for completeness)
// If you already had a separate current_user.dart, please let me know and remove this from auth_service.dart
class CurrentUser {
  final String id;
  final String fullName;
  final String email;
  final String? profilePic; // Was likely not present or defaulted to empty
  final String? mobileNumber; // Was likely not present or defaulted to empty
  final bool isAdmin; // Was likely not present or defaulted to false

  CurrentUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.profilePic,
    this.mobileNumber,
    this.isAdmin = false,
  });

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      // Assuming 'id' from backend login response might be '_id' or 'id'
      id: json['_id'] as String? ?? json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      // Defaulting profilePic and mobileNumber if they weren't yet in your backend's login response
      profilePic: json['profilePic'] as String? ?? '',
      mobileNumber: json['mobileNumber'] as String? ?? '',
      isAdmin: json['isAdmin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'profilePic': profilePic,
      'mobileNumber': mobileNumber,
      'isAdmin': isAdmin,
    };
  }
}

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String _baseUrl = BACKEND_URL;

  static const String _tokenKey =
      'token'; // The key you were using for the token
  static const String _currentUserKey = 'currentUser';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['token'];
      final userJson =
          data['user']; // Assuming backend returns user data on login

      if (token != null && userJson != null) {
        final currentUser = CurrentUser.fromJson(userJson);
        final currentUserString = json.encode(currentUser.toJson());

        await _storage.write(key: _tokenKey, value: token);
        await _storage.write(key: _currentUserKey, value: currentUserString);

        return {'success': true, 'message': 'Login successful'};
      } else {
        throw Exception('Login successful but token or user data missing.');
      }
    } else {
      final error = json.decode(response.body)['error'] ?? 'Login failed';
      throw Exception(error);
    }
  }

  // Register Function - mobileNumber was not originally an explicit parameter
  Future<Map<String, dynamic>> register(
      String email, String password, String fullName) async {
    // Positional args
    final Map<String, dynamic> body = {
      'email': email,
      'password': password,
      'fullName': fullName,
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/api/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return {'success': true, 'message': 'User registered successfully'};
    } else {
      final error =
          json.decode(response.body)['error'] ?? 'Registration failed';
      throw Exception(error);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _currentUserKey);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<CurrentUser?> getCurrentUser() async {
    // This original version only read from storage, didn't try to fetch from backend
    final userString = await _storage.read(key: _currentUserKey);
    if (userString != null) {
      return CurrentUser.fromJson(json.decode(userString));
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    return await _storage.read(key: _tokenKey) != null;
  }

  // --- Methods for editing profile (updateCurrentUserProfile, _uploadImageToBackend) were NOT present here ---
  // If you are reverting, ensure these are removed.
}
