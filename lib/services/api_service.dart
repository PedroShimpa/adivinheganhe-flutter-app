import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ApiService {
  static const String baseUrl = 'https://adivinheganhe.com.br/api';
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  /// PEGAR TOKEN FCM DO DISPOSITIVO
  Future<String?> getPushToken() async {
    return await FirebaseMessaging.instance.getToken();
  }

  /// LOGIN
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
    String fingerprint,
  ) async {
    final pushToken = await getPushToken();
    final body = {
      'name': name,
      'email': email,
      'username': username,
      'password': password,
      'fingerprint': fingerprint,
      if (pushToken != null) 'token_push_notification': pushToken,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    // Salva token e usuário no storage seguro
    if (response.statusCode == 200 && data['token'] != null) {
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

  /// SALVAR TOKEN E USUÁRIO
  Future<void> saveToken(String token, Map<String, dynamic>? user) async {
    await storage.write(key: 'token', value: token);
    if (user != null) {
      await storage.write(key: 'user', value: jsonEncode(user));
    }
  }

  /// FORGOT PASSWORD
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(response.body);
  }

  /// RETORNAR TOKEN SALVO
  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

  /// RETORNAR USUÁRIO SALVO
  Future<Map<String, dynamic>?> getUser() async {
    final userString = await storage.read(key: 'user');
    if (userString != null) {
      return jsonDecode(userString);
    }
    return null;
  }

  /// LOGOUT
  Future<void> logout() async {
    await storage.delete(key: 'token');
    await storage.delete(key: 'user');
  }

  /// LIMPAR TOKENS
  Future<void> clearToken() async {
    await storage.delete(key: 'token');
    await storage.delete(key: 'user');
  }

  /// ATUALIZAR TOKEN PUSH NO BACKEND
  Future<void> updatePushToken() async {
    final token = await getToken();
    final pushToken = await getPushToken();
    if (token != null && pushToken != null) {
      await http.post(
        Uri.parse('$baseUrl/update-push-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'token_push_notification': pushToken}),
      );
    }
  }
}
