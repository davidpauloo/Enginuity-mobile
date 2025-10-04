import 'dart:convert';
import 'package:chat_app/key.dart';
import 'package:http/http.dart' as http;
import 'package:chat_app/models/project_model.dart';
import 'package:chat_app/services/auth_service.dart';

class ProjectService {
  static const String _baseUrl = BACKEND_URL;
  final AuthService _authService = AuthService();

  // Fetch all projects for the authenticated user (existing).
  Future<List<Project>> fetchProjects({String? token}) async {
    token ??= await _authService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found. Please log in.');
    }

    final uri = Uri.parse('$_baseUrl/api/projects');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Unauthorized access. Please log in again.');
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to load projects: ${response.body}');
    }

    final dynamic raw = json.decode(response.body);

    List<dynamic> items;
    if (raw is List) {
      items = raw;
    } else if (raw is Map<String, dynamic>) {
      final dynamic docs = raw['documents'] ?? raw['data'] ?? raw['projects'];
      if (docs is List) {
        items = docs;
      } else if (docs is Map) {
        items = [docs];
      } else {
        items = const <dynamic>[];
      }
    } else {
      items = const <dynamic>[];
    }

    final List<Project> projects = items
        .where((e) => e is Map)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map(Project.fromJson)
        .toList();

    return projects;
  }

  // NEW: Fetch a single project by id (uses GET /api/projects/:projectId).
  Future<Project> fetchProjectById(String id, {String? token}) async {
    token ??= await _authService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found. Please log in.');
    }

    final uri = Uri.parse('$_baseUrl/api/projects/$id?ts=${DateTime.now().millisecondsSinceEpoch}');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Unauthorized access. Please log in again.');
    }
    if (response.statusCode == 404) {
      throw Exception('Project not found.');
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to load project: ${response.body}');
    }

    final dynamic raw = json.decode(response.body);
    if (raw is! Map<String, dynamic>) {
      throw Exception('Unexpected payload for project: ${response.body}');
    }

    return Project.fromJson(raw);
  }
}
