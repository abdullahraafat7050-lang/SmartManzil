import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class HomeService {
  final _storage = const FlutterSecureStorage();
  static const String _apiBase = 'https://api.example.com';
  bool useRemote = false;

  static final HomeService _instance = HomeService._internal();
  factory HomeService() => _instance;
  HomeService._internal();

  static final List<Map<String, dynamic>> _mockRooms = [
    {
      'id': 'room-001',
      'name': 'Living Room',
      'devices': [
        {'id': 'dev-001', 'name': 'Main TV', 'type': 'tv', 'state': false},
        {'id': 'dev-002', 'name': 'Ceiling Light', 'type': 'light', 'state': true, 'value': 75.0},
      ],
    },
    {
      'id': 'room-002',
      'name': 'Kitchen',
      'devices': [
        {'id': 'dev-003', 'name': 'Cabinet Lights', 'type': 'light', 'state': false, 'value': 50.0},
        {'id': 'dev-004', 'name': 'Coffee Maker', 'type': 'appliance', 'state': false},
      ],
    },
    {
      'id': 'room-003',
      'name': 'Bedroom',
      'devices': [
        {'id': 'dev-005', 'name': 'Blackout Curtain', 'type': 'curtain', 'state': false},
        {'id': 'dev-008', 'name': 'Bedside Lamp', 'type': 'light', 'state': false, 'value': 40.0},
      ],
    },
    {
      'id': 'room-004',
      'name': 'Bathroom',
      'devices': [
        {'id': 'dev-006', 'name': 'Ventilation Fan', 'type': 'fan', 'state': false},
        {'id': 'dev-009', 'name': 'Mirror Light', 'type': 'light', 'state': false, 'value': 60.0},
      ],
    },
    {
      'id': 'room-005',
      'name': 'Garden',
      'devices': [
        {'id': 'sensor-002', 'name': 'Rain Detector', 'type': 'rain', 'isRaining': false},
        {'id': 'dev-007', 'name': 'Front Gate', 'type': 'gate', 'state': false},
        {'id': 'dev-010', 'name': 'Garden Lamp', 'type': 'light', 'state': false, 'value': 30.0},
      ],
    },
    {
      'id': 'room-006',
      'name': 'Hall',
      'devices': [
        {'id': 'dev-011', 'name': 'Hall Ceiling', 'type': 'light', 'state': false, 'value': 50.0},
        {'id': 'dev-012', 'name': 'Blackout Curtain', 'type': 'curtain', 'state': false},
      ],
    },
  ];

  static Map<String, dynamic> _mockUser = {
    'username': 'user_smart',
    'email': 'user@smarthome.com',
    'phone': '123-456-7890',
  };

  final Map<String, String> _pending2fa = {};

  // --- ROOM & DEVICE METHODS ---
  List<Map<String, dynamic>> getRooms() => _mockRooms;

  Future<Map<String, dynamic>> getHomeStatus() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final Map<String, dynamic> status = {};
    for (var room in _mockRooms) {
      final String roomName = room['name'];
      final light = (room['devices'] as List).firstWhereOrNull((d) => d['type'] == 'light');
      final curtain = (room['devices'] as List).firstWhereOrNull((d) => d['type'] == 'curtain');
      
      if (roomName == 'Garden') {
        final gate = (room['devices'] as List).firstWhereOrNull((d) => d['type'] == 'gate');
        status['gateOpen'] = gate?['state'] ?? false;
      }
      
      status[roomName] = {
        'lightOn': light?['state'] ?? false,
        'lightValue': light?['value'] ?? 50.0,
        'curtainOpen': curtain?['state'] ?? false,
      };
    }
    return status;
  }
  // --- ADDED: Password Reset Logic ---
  Future<Map<String, dynamic>> requestPasswordReset(String username) async {
    // 1. Try to get the user's phone number from secure storage
    String? phone = await _storage.read(key: 'user_phone');
    
    if (phone == null || phone.isEmpty || phone == 'N/A') {
      return {'success': false, 'message': 'No registered phone number found for this user.'};
    }

    // 2. Trigger the real Twilio SMS
    return await sendRealSMS(phone);
  }

  // --- ADDED: Verification Logic ---
  Future<Map<String, dynamic>> verifyResetCode(String username, String code, String newPassword) async {
    // 1. Check if the code matches the one stored in _pending2fa
    if (_pending2fa['user_smart'] == code) {
      // 2. Clear the pending code
      _pending2fa.remove('user_smart');
      
      // 3. Save the new password permanently
      await _storage.write(key: 'user_password', value: newPassword);
      
      return {'success': true, 'message': 'Password has been successfully updated.'};
    } else {
      return {'success': false, 'message': 'Invalid verification code. Please check your SMS.'};
    }
  }
  // --- ADDED: Change Password Logic ---
  Future<Map<String, dynamic>> changePassword(String current, String next) async {
    // 1. Check if the current password matches what we have in storage
    String? saved = await _storage.read(key: 'user_password');
    String actualCurrent = saved ?? '123'; // Default is 123 if never changed

    if (current != actualCurrent) {
      return {'success': false, 'message': 'Incorrect current password.'};
    }

    if (next.length < 8) {
      return {'success': false, 'message': 'New password must be at least 8 characters.'};
    }

    // 2. Persist the new password to physical memory
    await _storage.write(key: 'user_password', value: next);
    
    return {
      'success': true, 
      'message': 'Password updated successfully. Please log in again.'
    };
  }
  // --- ADDED: Room Detail Logic ---

  // 1. Finds a specific room's data using its unique ID
  Map<String, dynamic>? getRoomById(String id) {
    return _mockRooms.firstWhereOrNull((room) => room['id'] == id);
  }

  // 2. Toggles the state (On/Off) of a specific device within a room
  Future<Map<String, dynamic>> toggleDeviceState(String roomId, String deviceId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Find the room
    final room = _mockRooms.firstWhereOrNull((r) => r['id'] == roomId);
    if (room == null) return {'success': false, 'message': 'Room not found'};

    // Find the device inside that room
    final device = (room['devices'] as List).firstWhereOrNull((d) => d['id'] == deviceId);
    
    if (device != null && device.containsKey('state')) {
      // Flip the boolean state
      device['state'] = !device['state'];
      return {'success': true, 'device': device};
    }
    
    return {'success': false, 'message': 'Device not found or not toggleable'};
  }

  Future<Map<String, dynamic>> setDeviceState(String areaName, String deviceKey, dynamic value) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // FIXED: Gate logic for Global command
    if (areaName == 'global' && deviceKey == 'gateOpen') {
      final garden = _mockRooms.firstWhereOrNull((r) => r['name'] == 'Garden');
      final gate = (garden?['devices'] as List?)?.firstWhereOrNull((d) => d['type'] == 'gate');
      if (gate != null) {
        gate['state'] = value;
        return {'success': true};
      }
    }

    if (areaName == 'global' && deviceKey == 'allLightsOff') {
      for (var room in _mockRooms) {
        final light = (room['devices'] as List).firstWhereOrNull((d) => d['type'] == 'light');
        if (light != null) light['state'] = false;
      }
      return {'success': true};
    }

    final room = _mockRooms.firstWhereOrNull((r) => r['name'] == areaName);
    if (room == null) return {'success': false};

    final deviceList = room['devices'] as List<Map<String, dynamic>>;
    if (deviceKey == 'lightOn') {
      final light = deviceList.firstWhereOrNull((d) => d['type'] == 'light');
      if (light != null) { light['state'] = value; return {'success': true}; }
    } else if (deviceKey == 'lightValue') {
      final light = deviceList.firstWhereOrNull((d) => d['type'] == 'light');
      if (light != null) { light['value'] = value; return {'success': true}; }
    } else if (deviceKey == 'curtainOpen') {
      final curtain = deviceList.firstWhereOrNull((d) => d['type'] == 'curtain');
      if (curtain != null) { curtain['state'] = value; return {'success': true}; }
    }
    return {'success': false};
  }

  // --- PERSISTENCE & AUTH ---
  Future<Map<String, dynamic>> login(String username, String password) async {
    String? saved = await _storage.read(key: 'user_password');
    if (password == (saved ?? '123')) return {'success': true, 'requires2FA': false};
    return {'success': false, 'message': 'Invalid credentials'};
  }

  Future<Map<String, dynamic>> updateMockPhoneNumber(String phone) async {
    await _storage.write(key: 'user_phone', value: phone);
    _mockUser['phone'] = phone;
    return {'success': true};
  }

  Future<Map<String, dynamic>> getMockUserData() async {
    String? phone = await _storage.read(key: 'user_phone');
    return {'username': _mockUser['username'], 'phone': phone ?? _mockUser['phone']};
  }

  // --- TWILIO REAL SMS ---
  Future<Map<String, dynamic>> sendRealSMS(String toNumber) async {
    const accountSid = 'USbf37b5b456cadc0125df78b3e5336698'; 
    const authToken = '5WUYL1SHPE1VACV9PCVJMJJV';
    const twilioNumber = '+90552714283'; 

    final code = (100000 + (999999 - 100000)).toString();
    final uri = Uri.parse('https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$accountSid:$authToken'))}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'From': twilioNumber, 'To': toNumber, 'Body': 'Lumina Security Code: $code'},
      );
      if (response.statusCode == 201) {
        _pending2fa['user_smart'] = code;
        return {'success': true, 'message': 'Code sent to $toNumber'};
      }
      return {'success': false, 'message': 'Twilio Error'};
    } catch (e) {
      return {'success': false, 'message': 'Network Error'};
    }
  }

  Future<Map<String, dynamic>> changeUsername(String name) async {
    await _storage.write(key: 'user_name', value: name);
    _mockUser['username'] = name;
    return {'success': true};
  }
}