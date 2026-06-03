import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smarthome/config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _token;
  void setToken(String token) => _token = token;
  void clearToken() => _token = null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(
      Uri.parse('${AppConfig.backendUrl}$path'),
      headers: _headers,
    );
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('${AppConfig.backendUrl}$path'),
      headers: _headers,
      body: json.encode(body),
    );
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> patch(
      String path, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('${AppConfig.backendUrl}$path'),
      headers: _headers,
      body: json.encode(body),
    );
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final res = await http.delete(
      Uri.parse('${AppConfig.backendUrl}$path'),
      headers: _headers,
    );
    return json.decode(res.body) as Map<String, dynamic>;
  }
}
