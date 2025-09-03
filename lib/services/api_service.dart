import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.67:8000/api';
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  Future<String?> getPushToken() async {
    return await FirebaseMessaging.instance.getToken();
  }

  Future<bool> login(String email, String password) async {
    final pushToken = await getPushToken();
    final body = {
      'email': email,
      'password': password,
      if (pushToken != null) 'token_push_notification': pushToken,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['token'] != null) {
      // Salva token e usuário de forma segura
      await storage.write(key: 'token', value: data['token']);
      await storage.write(key: 'user', value: jsonEncode(data['user']));
      return true;
    } else {
      return false;
    }
  }

  /// REGISTRAR
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String username,
    String password,
  ) async {
    final pushToken = await getPushToken();
    final body = {
      'name': name,
      'email': email,
      'username': username,
      'password': password,
      if (pushToken != null) 'token_push_notification': pushToken,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data['token'] != null) {
      await storage.write(key: 'token', value: data['token']);
      await storage.write(key: 'user', value: jsonEncode(data['user']));
    }

    return {
      'statusCode': response.statusCode,
      'token': data['token'],
      'user': data['user'],
      'message': data['message'] ?? 'Erro desconhecido',
    };
  }

  Future<void> saveToken(String token, Map<String, dynamic>? user) async {
    await storage.write(key: 'token', value: token);
    if (user != null) {
      await storage.write(key: 'user', value: jsonEncode(user));
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(response.body);
  }

  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

  Future<Map<String, dynamic>?> getUser() async {
    final userString = await storage.read(key: 'user');
    if (userString != null) {
      return jsonDecode(userString);
    }
    return null;
  }

  Future<void> logout() async {
    await storage.delete(key: 'token');
    await storage.delete(key: 'user');
  }

  Future<void> clearToken() async {
    await storage.delete(key: 'token');
    await storage.delete(key: 'user');
  }
}
