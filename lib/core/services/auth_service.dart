import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  static const _tokenKey = 'jwt';
  static const _roleKey = 'userRole';

  /// Inloggen met e-mail + wachtwoord
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiService.client.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    final data = response.data;
    final token = data['access_token'];
    final user = data['user'];

    if (token != null) {
      await _storage.write(key: _tokenKey, value: token);
      _apiService.client.options.headers['Authorization'] = 'Bearer $token';
    }

    if (user != null && user['role'] != null) {
      await _storage.write(key: _roleKey, value: user['role']);
    }

    return data;
  }

  /// Registreren
  Future<Map<String, dynamic>> register(String email, String password) async {
    final response = await _apiService.client.post(
      '/auth/register',
      data: {'email': email, 'password': password},
    );
    return response.data;
  }

  /// Token laden bij app start
  Future<String?> loadToken() async {
    final token = await _storage.read(key: _tokenKey);
    if (token != null) {
      _apiService.client.options.headers['Authorization'] = 'Bearer $token';
    }
    return token;
  }

  /// Rol laden bij app start
  Future<String?> loadRole() async {
    return await _storage.read(key: _roleKey);
  }

  /// Uitloggen → token & rol verwijderen
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _roleKey);
    _apiService.client.options.headers.remove('Authorization');
  }

  /// Check of gebruiker ingelogd is
  Future<bool> isLoggedIn() async {
    final token = await loadToken();
    return token != null;
  }
}
