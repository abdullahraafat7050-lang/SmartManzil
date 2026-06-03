import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smarthome/config.dart';
import 'package:smarthome/services/auth_service.dart';
import 'package:smarthome/services/device_service.dart';

// Thin facade — keeps existing screen imports working while
// delegating all logic to AuthService and DeviceService.
class HomeService {
  static final HomeService _instance = HomeService._internal();
  factory HomeService() => _instance;
  HomeService._internal();

  final _auth = AuthService();
  final _devices = DeviceService();
  final _storage = const FlutterSecureStorage();

  // ── Auth ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String username, String password) =>
      _auth.login(username, password);

  Future<Map<String, dynamic>> changePassword(String current, String next) =>
      _auth.changePassword(current, next);

  Future<Map<String, dynamic>> requestPasswordReset(String username) =>
      _auth.requestPasswordReset(username);

  Future<Map<String, dynamic>> verifyResetCode(
    String username,
    String code,
    String newPassword,
  ) =>
      _auth.verifyResetCode(username, code, newPassword);

  // ── Devices ─────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> getRooms() =>
      _devices.getRooms().map((r) => r.toJson()).toList();

  Map<String, dynamic>? getRoomById(String id) =>
      _devices.getRoomById(id)?.toJson();

  Future<Map<String, dynamic>> getHomeStatus() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _devices.getHomeSnapshot();
  }

  Future<Map<String, dynamic>> toggleDeviceState(
    String roomId,
    String deviceId,
  ) async {
    final ok = await _devices.toggleDevice(roomId, deviceId);
    return {'success': ok};
  }

  Future<Map<String, dynamic>> setDeviceState(
    String areaName,
    String deviceKey,
    dynamic value,
  ) async {
    bool ok = false;
    if (areaName == 'global' && deviceKey == 'gateOpen') {
      ok = await _devices.setGate(value as bool);
    } else if (areaName == 'global' && deviceKey == 'allLightsOff') {
      await _devices.setAllLights(false);
      ok = true;
    } else if (deviceKey == 'lightOn') {
      ok = await _devices.setLight(areaName, on: value as bool);
    } else if (deviceKey == 'lightValue') {
      ok = await _devices.setLight(areaName, brightness: (value as num).toDouble());
    } else if (deviceKey == 'curtainOpen') {
      ok = await _devices.setCurtain(areaName, value as bool);
    }
    return {'success': ok};
  }

  // ── User ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getMockUserData() async {
    final phone = await _storage.read(key: AppConfig.keyPhone);
    final username = await _storage.read(key: AppConfig.keyUsername);
    return {
      'username': username ?? 'user_smart',
      'phone': phone ?? '123-456-7890',
    };
  }

  Future<Map<String, dynamic>> updateMockPhoneNumber(String phone) async {
    await _storage.write(key: AppConfig.keyPhone, value: phone);
    return {'success': true};
  }

  Future<Map<String, dynamic>> changeUsername(String name) async {
    await _storage.write(key: AppConfig.keyUsername, value: name);
    return {'success': true};
  }
}
