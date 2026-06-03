import 'package:flutter/material.dart';

enum DeviceType { light, curtain, tv, appliance, fan, gate, heat, rain }

class Device {
  final String id;
  final String name;
  final DeviceType type;
  bool state;
  double? value;
  bool? isRaining;
  double? temperature;
  String? unit;

  Device({
    required this.id,
    required this.name,
    required this.type,
    this.state = false,
    this.value,
    this.isRaining,
    this.temperature,
    this.unit,
  });

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        id: json['id'] as String,
        name: json['name'] as String,
        type: DeviceType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => DeviceType.appliance,
        ),
        state: json['state'] as bool? ?? false,
        value: (json['value'] as num?)?.toDouble(),
        isRaining: json['isRaining'] as bool?,
        temperature: (json['temperature'] as num?)?.toDouble(),
        unit: json['unit'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'state': state,
        if (value != null) 'value': value,
        if (isRaining != null) 'isRaining': isRaining,
        if (temperature != null) 'temperature': temperature,
        if (unit != null) 'unit': unit,
      };

  bool get isToggleable => type != DeviceType.heat;
  bool get hasSlider => type == DeviceType.light;

  bool get isActive {
    if (type == DeviceType.heat) return true;
    if (type == DeviceType.rain) return isRaining == true;
    return state;
  }

  String get statusText {
    if (type == DeviceType.heat) {
      return '${(temperature ?? 0.0).toStringAsFixed(1)} ${unit ?? '°C'}';
    }
    if (type == DeviceType.rain) return isRaining == true ? 'Raining' : 'Clear';
    return state ? 'ON' : 'OFF';
  }

  IconData get icon {
    switch (type) {
      case DeviceType.light:
        return Icons.lightbulb_outline;
      case DeviceType.curtain:
        return Icons.vertical_split;
      case DeviceType.tv:
        return Icons.tv;
      case DeviceType.appliance:
        return Icons.local_dining;
      case DeviceType.fan:
        return Icons.mode_fan_off_outlined;
      case DeviceType.gate:
        return Icons.sensor_door;
      case DeviceType.heat:
        return Icons.thermostat_outlined;
      case DeviceType.rain:
        return Icons.cloudy_snowing;
    }
  }

  Device copyWith({bool? state, double? value, bool? isRaining}) => Device(
        id: id,
        name: name,
        type: type,
        state: state ?? this.state,
        value: value ?? this.value,
        isRaining: isRaining ?? this.isRaining,
        temperature: temperature,
        unit: unit,
      );
}
