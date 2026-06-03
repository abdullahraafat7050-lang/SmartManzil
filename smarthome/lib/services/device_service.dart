import 'package:collection/collection.dart';
import 'package:smarthome/models/device.dart';
import 'package:smarthome/models/room.dart';

class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  final List<Room> _rooms = [
    Room(id: 'room-001', name: 'Living Room', devices: [
      Device(id: 'dev-001', name: 'Main TV', type: DeviceType.tv),
      Device(id: 'dev-002', name: 'Ceiling Light', type: DeviceType.light, state: true, value: 75.0),
    ]),
    Room(id: 'room-002', name: 'Kitchen', devices: [
      Device(id: 'dev-003', name: 'Cabinet Lights', type: DeviceType.light, value: 50.0),
      Device(id: 'dev-004', name: 'Coffee Maker', type: DeviceType.appliance),
    ]),
    Room(id: 'room-003', name: 'Bedroom', devices: [
      Device(id: 'dev-005', name: 'Blackout Curtain', type: DeviceType.curtain),
      Device(id: 'dev-008', name: 'Bedside Lamp', type: DeviceType.light, value: 40.0),
    ]),
    Room(id: 'room-004', name: 'Bathroom', devices: [
      Device(id: 'dev-006', name: 'Ventilation Fan', type: DeviceType.fan),
      Device(id: 'dev-009', name: 'Mirror Light', type: DeviceType.light, value: 60.0),
    ]),
    Room(id: 'room-005', name: 'Garden', devices: [
      Device(id: 'sensor-001', name: 'Rain Detector', type: DeviceType.rain, isRaining: false),
      Device(id: 'dev-007', name: 'Front Gate', type: DeviceType.gate),
      Device(id: 'dev-010', name: 'Garden Lamp', type: DeviceType.light, value: 30.0),
    ]),
    Room(id: 'room-006', name: 'Hall', devices: [
      Device(id: 'dev-011', name: 'Hall Ceiling', type: DeviceType.light, value: 50.0),
      Device(id: 'dev-012', name: 'Blackout Curtain', type: DeviceType.curtain),
    ]),
  ];

  List<Room> getRooms() => List.unmodifiable(_rooms);

  Room? getRoomById(String id) =>
      _rooms.firstWhereOrNull((r) => r.id == id);

  Future<bool> toggleDevice(String roomId, String deviceId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final device = getRoomById(roomId)
        ?.devices
        .firstWhereOrNull((d) => d.id == deviceId);
    if (device == null || !device.isToggleable) return false;
    device.state = !device.state;
    return true;
  }

  Future<bool> setLight(String roomName, {bool? on, double? brightness}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final light = _rooms.firstWhereOrNull((r) => r.name == roomName)?.firstLight;
    if (light == null) return false;
    if (on != null) light.state = on;
    if (brightness != null) light.value = brightness;
    return true;
  }

  Future<bool> setCurtain(String roomName, bool open) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final curtain =
        _rooms.firstWhereOrNull((r) => r.name == roomName)?.firstCurtain;
    if (curtain == null) return false;
    curtain.state = open;
    return true;
  }

  Future<bool> setGate(bool open) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final gate =
        _rooms.firstWhereOrNull((r) => r.name == 'Garden')?.gate;
    if (gate == null) return false;
    gate.state = open;
    return true;
  }

  Future<void> setAllLights(bool on) async {
    await Future.delayed(const Duration(milliseconds: 150));
    for (final room in _rooms) {
      room.firstLight?.state = on;
    }
  }

  Future<void> setAllCurtains(bool open) async {
    await Future.delayed(const Duration(milliseconds: 150));
    for (final room in _rooms) {
      room.firstCurtain?.state = open;
    }
  }

  Map<String, dynamic> getHomeSnapshot() {
    final snapshot = <String, dynamic>{};
    for (final room in _rooms) {
      snapshot[room.name] = {
        'lightOn': room.firstLight?.state ?? false,
        'lightValue': room.firstLight?.value ?? 50.0,
        'curtainOpen': room.firstCurtain?.state ?? false,
      };
    }
    snapshot['gateOpen'] =
        _rooms.firstWhereOrNull((r) => r.name == 'Garden')?.gate?.state ?? false;
    return snapshot;
  }
}
