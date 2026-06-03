import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smarthome/config.dart';
import 'package:smarthome/services/sms_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = const FlutterSecureStorage();
  final _sms = SmsService();
  final Map<String, String> _pending2fa = {};

  Future<Map<String, dynamic>> login(String username, String password) async {
    final saved = await _storage.read(key: AppConfig.keyPassword);
    if (password == (saved ?? AppConfig.mockDefaultPassword)) {
      return {'success': true, 'requires2FA': false};
    }
    return {'success': false, 'message': 'Invalid credentials'};
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConfig.keyToken);
  }

  Future<Map<String, dynamic>> requestPasswordReset(String username) async {
    final phone = await _storage.read(key: AppConfig.keyPhone);
    if (phone == null || phone.isEmpty) {
      return {'success': false, 'message': 'No registered phone number found.'};
    }
    final result = await _sms.sendCode(phone);
    if (result['success'] == true) {
      _pending2fa[username] = result['code'] as String;
    }
    return result;
  }

  Future<Map<String, dynamic>> verifyResetCode(
    String username,
    String code,
    String newPassword,
  ) async {
    if (_pending2fa[username] == code) {
      _pending2fa.remove(username);
      await _storage.write(key: AppConfig.keyPassword, value: newPassword);
      return {'success': true, 'message': 'Password updated successfully.'};
    }
    return {'success': false, 'message': 'Invalid verification code.'};
  }

  Future<Map<String, dynamic>> changePassword(
    String current,
    String next,
  ) async {
    final saved = await _storage.read(key: AppConfig.keyPassword);
    if (current != (saved ?? AppConfig.mockDefaultPassword)) {
      return {'success': false, 'message': 'Incorrect current password.'};
    }
    if (next.length < 8) {
      return {'success': false, 'message': 'Password must be at least 8 characters.'};
    }
    await _storage.write(key: AppConfig.keyPassword, value: next);
    return {'success': true, 'message': 'Password updated successfully.'};
  }
}
