// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chat_app/key.dart';

class CurrentUser {
  final String id;
  final String fullName;
  final String email;
  final String? profilePic;
  final String? mobileNumber;
  final String role;

  CurrentUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.profilePic,
    this.mobileNumber,
    required this.role,
  });

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      id: json['_id'] as String? ?? json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      profilePic: json['profilePic'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
      role: json['role'] as String? ?? 'client',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'profilePic': profilePic,
      'mobileNumber': mobileNumber,
      'role': role,
    };
  }
}

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String _baseUrl = BACKEND_URL;

  static const String _tokenKey = 'token';
  static const String _currentUserKey = 'currentUser';

  Future<Map<String, dynamic>> login(String email, String password) async {
    print('LOGIN DEBUG:');
    print('URL: $_baseUrl/api/auth/login');
    print('Username: $email');
    print('Password: $password');
    
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'platform': 'mobile',
      }),
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['token'];

      if (token != null) {
        await _storage.write(key: _tokenKey, value: token);

        final currentUser = CurrentUser(
          id: data['_id'],
          fullName: data['fullName'],
          email: data['email'],
          profilePic: data['profilePic'],
          role: data['role'],
        );
        
        await _storage.write(
          key: _currentUserKey,
          value: json.encode(currentUser.toJson()),
        );

        return {'success': true, 'message': 'Login successful'};
      } else {
        throw Exception('Login successful but token missing.');
      }
    } else if (response.statusCode == 403) {
      final error = json.decode(response.body)['message'] ?? 'Access denied';
      throw Exception(error);
    } else {
      final error = json.decode(response.body)['message'] ?? 'Login failed';
      throw Exception(error);
    }
  }

  Future<Map<String, dynamic>> register(
      String email, String password, String fullName) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'fullName': fullName,
        'role': 'client',
        'platform': 'mobile',
      }),
    );

    if (response.statusCode == 201) {
      return {'success': true, 'message': 'User registered successfully'};
    } else {
      final error = json.decode(response.body)['message'] ?? 'Registration failed';
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
    final userString = await _storage.read(key: _currentUserKey);
    if (userString != null) {
      return CurrentUser.fromJson(json.decode(userString));
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    return await _storage.read(key: _tokenKey) != null;
  }
}