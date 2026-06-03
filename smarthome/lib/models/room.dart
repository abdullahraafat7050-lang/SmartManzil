import 'package:collection/collection.dart';
import 'package:smarthome/models/device.dart';

class Room {
  final String id;
  final String name;
  final List<Device> devices;

  const Room({required this.id, required this.name, required this.devices});

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        id: json['id'] as String,
        name: json['name'] as String,
        devices: (json['devices'] as List<dynamic>? ?? [])
            .map((d) => Device.fromJson(d as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'devices': devices.map((d) => d.toJson()).toList(),
      };

  Device? get firstLight =>
      devices.firstWhereOrNull((d) => d.type == DeviceType.light);

  Device? get firstCurtain =>
      devices.firstWhereOrNull((d) => d.type == DeviceType.curtain);

  Device? get gate =>
      devices.firstWhereOrNull((d) => d.type == DeviceType.gate);
}
