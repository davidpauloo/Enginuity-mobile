// lib/services/project_service.dart
import 'dart:convert';
import 'package:chat_app/key.dart';
import 'package:http/http.dart' as http;
import 'package:chat_app/models/project.dart'; // Make sure this path is correct
import 'package:chat_app/services/auth_service.dart'; // To get the token

class ProjectService {
  static const String _baseUrl =
      BACKEND_URL; // Assuming BACKEND_URL is defined in key.dart

  final AuthService _authService = AuthService(); // To get the auth token

  Future<List<Project>> fetchProjects(
      {String? clientName, String? token}) async {
    // Get token if not provided (e.g., when called from ProjectsScreen directly)
    token ??= await _authService
        .getToken(); // Retrieve token if not explicitly passed
    if (token == null) {
      throw Exception('Authentication token not found. Please log in.');
    }

    // Build query parameters
    final Map<String, String> queryParams = {};
    if (clientName != null && clientName.isNotEmpty) {
      queryParams['clientName'] = clientName;
    }

    final uri = Uri.parse('$_baseUrl/api/projects')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Pass the token in the header
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> projectJson = json.decode(response.body);
        return projectJson.map((json) => Project.fromJson(json)).toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Handle unauthorized/forbidden access, e.g., redirect to login
        throw Exception('Unauthorized access. Please log in again.');
      } else {
        throw Exception('Failed to load projects: ${response.body}');
      }
    } catch (e) {
      print('Error fetching projects: $e');
      rethrow; // Re-throw to be caught by the UI
    }
  }
}
