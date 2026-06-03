import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../mqtt_manager.dart';
import '../services/firebase_service.dart';

// Shows sensor data merged from MQTT (real-time) + Firestore (cloud backup).
// MQTT has priority for gas/smoke alerts; Firestore supplies temp/humidity.
class SensorPanel extends StatelessWidget {
  const SensorPanel({super.key});

  static const _gold = Color(0xFFBFA86D);
  static const _card = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    return Consumer<MQTTManager>(
      builder: (context, mqtt, _) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseService().getSensorsData(),
          builder: (context, snap) {
            final fs = snap.data?.data() ?? {};

            // Temperature & humidity from Firestore (hardware writes here)
            final temp = (fs['temperature'] as num?)?.toDouble()
                ?? mqtt.temperature;
            final humidity = (fs['humidity'] as num?)?.toDouble()
                ?? mqtt.humidity;

            // Gas/smoke: MQTT = real-time priority, Firestore = backup
            final gasAlert = mqtt.gasStatus != 'OK'
                || (fs['gas'] as bool? ?? false);
            final smokeAlert = mqtt.smokeDetected
                || (fs['smoke'] as bool? ?? false);
            final motion = mqtt.motionDetected
                || (fs['motion'] as bool? ?? false);

            final hasAlert = gasAlert || smokeAlert;

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasAlert
                      ? Colors.redAccent.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  Icon(Icons.sensors, color: _gold, size: 16),
                  const SizedBox(width: 8),
                  if (temp != null)
                    _Chip(
                      icon: Icons.thermostat,
                      value: '${temp.toStringAsFixed(1)}°C',
                      label: 'Temp',
                    ),
                  if (humidity != null)
                    _Chip(
                      icon: Icons.water_drop_outlined,
                      value: '${humidity.toStringAsFixed(0)}%',
                      label: 'Humidity',
                    ),
                  _Chip(
                    icon: gasAlert
                        ? Icons.warning_rounded
                        : Icons.gas_meter_outlined,
                    value: gasAlert ? 'GAS!' : 'OK',
                    label: 'Gas',
                    color: gasAlert ? Colors.redAccent : Colors.greenAccent,
                    alert: gasAlert,
                  ),
                  if (smokeAlert)
                    _Chip(
                      icon: Icons.cloud_outlined,
                      value: 'SMOKE!',
                      label: 'Smoke',
                      color: Colors.redAccent,
                      alert: true,
                    ),
                  if (motion)
                    _Chip(
                      icon: Icons.directions_run,
                      value: 'Active',
                      label: 'Motion',
                      color: Colors.orangeAccent,
                    ),
                  if (!gasAlert && !smokeAlert && !motion)
                    _Chip(
                      icon: Icons.check_circle_outline,
                      value: 'All Clear',
                      label: '',
                      color: Colors.greenAccent,
                    ),
                ]),
              ),
            );
          },
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;
  final bool alert;

  const _Chip({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
    this.alert = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFFBFA86D);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withValues(alpha: alert ? 0.6 : 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: c, size: 14),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: TextStyle(
                    color: c, fontSize: 12, fontWeight: FontWeight.w700)),
            if (label.isNotEmpty)
              Text(label,
                  style: TextStyle(
                      color: c.withValues(alpha: 0.7), fontSize: 9)),
          ],
        ),
      ]),
    );
  }
}
