import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  String? _token;

  ApiClient(this.baseUrl);

  Future<bool> login(String username, String password) async {
    try {
      final url = Uri.parse('$baseUrl/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body.containsKey('token')) {
          _token = body['token']?.toString();
        } else if (body.containsKey('access_token')) {
          _token = body['access_token']?.toString();
        } else if (body.containsKey('jwt')) {
          _token = body['jwt']?.toString();
        }
        return true;
      }
    } catch (e) {
      print('Login Exception: $e');
    }
    return false;
  }

  Future<List<dynamic>> getNotes() async {
    if (_token == null) return [];
    try {
      final url = Uri.parse('$baseUrl/notes');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map) {
          if (decoded.containsKey('notes') && decoded['notes'] is List) {
            return decoded['notes'] as List<dynamic>;
          }
          if (decoded.containsKey('data') && decoded['data'] is List) {
            return decoded['data'] as List<dynamic>;
          }
        }
      }
    } catch (e) {
      print('Fetch Notes Exception: $e');
    }
    return [];
  }

  Future<bool> updateNote(dynamic id, String title, String content) async {
    if (_token == null) return false;
    try {
      final url = Uri.parse('$baseUrl/notes/$id');
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'title': title, 'content': content}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Update Note Exception: $e');
      return false;
    }
  }

  // HTTP PATCH: Isolates and flips the completion status field alone
  Future<bool> toggleNoteCompletion(dynamic id, bool isCompleted) async {
    if (_token == null) return false;
    try {
      final url = Uri.parse('$baseUrl/notes/$id');
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'is_completed': isCompleted}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Toggle Completion Exception: $e');
      return false;
    }
  }

  // HTTP DELETE: Destroys the target row via URL parameter ID mapping
  Future<bool> deleteNote(dynamic id) async {
    if (_token == null) return false;
    try {
      final url = Uri.parse('$baseUrl/notes/$id');
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Delete Note Exception: $e');
      return false;
    }
  }

  Future<bool> createNote(String title, String content) async {
    if (_token == null) return false;
    try {
      final url = Uri.parse('$baseUrl/notes');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'title': title, 'content': content}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Create Note Exception: $e');
      return false;
    }
  }
}
