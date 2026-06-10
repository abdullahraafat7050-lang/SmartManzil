import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../locale_service.dart';
import '../mqtt_manager.dart';
import '../services/firebase_service.dart';

class SensorPanel extends StatelessWidget {
  const SensorPanel({super.key});

  static const _gold = Color(0xFFBFA86D);
  static const _card = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Consumer<MQTTManager>(
      builder: (context, mqtt, _) {
        return StreamBuilder<DatabaseEvent>(
          stream: FirebaseService().getSensorsRTDB(),
          builder: (context, snap) {
            final raw = snap.data?.snapshot.value;
            final fs = (raw is Map)
                ? Map<String, dynamic>.from(raw as Map)
                : <String, dynamic>{};

            // Each node can be a direct value or a map {value: ...}
            dynamic _node(String key) {
              final n = fs[key];
              if (n is Map) return n['value'];
              return n;
            }

            final temp = _numVal(_node('temperature'))?.toDouble()
                ?? mqtt.temperature;
            final humidity = _numVal(_node('humidity'))?.toDouble()
                ?? mqtt.humidity;
            final gasAlert = mqtt.gasStatus != 'OK'
                || _boolVal(_node('gas'));
            final smokeAlert = mqtt.smokeDetected
                || _boolVal(_node('flame'));
            final motion = mqtt.motionDetected
                || _boolVal(_node('motion'));
            final rainAlert = mqtt.rainStatus == 'Raining'
                || _boolVal(_node('rain'));
            final hasAlert = gasAlert || smokeAlert;

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
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
                      label: s.temp,
                    ),
                  if (humidity != null)
                    _Chip(
                      icon: Icons.water_drop_outlined,
                      value: '${humidity.toStringAsFixed(0)}%',
                      label: s.humidity,
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
                  _Chip(
                    icon: smokeAlert
                        ? Icons.cloud
                        : Icons.smoke_free,
                    value: smokeAlert ? 'SMOKE!' : 'OK',
                    label: s.smoke,
                    color: smokeAlert ? Colors.redAccent : Colors.greenAccent,
                    alert: smokeAlert,
                  ),
                  _Chip(
                    icon: motion
                        ? Icons.directions_run
                        : Icons.accessibility_new,
                    value: motion ? 'Motion!' : 'Clear',
                    label: s.motion,
                    color: motion ? Colors.orangeAccent : Colors.greenAccent,
                    alert: motion,
                  ),
                  _Chip(
                    icon: rainAlert
                        ? Icons.umbrella
                        : Icons.wb_sunny_outlined,
                    value: rainAlert ? 'Rain!' : 'Dry',
                    label: s.rain,
                    color: rainAlert ? Colors.blueAccent : Colors.greenAccent,
                    alert: rainAlert,
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

// ── RTDB value helpers ────────────────────────────────────────────────────────

num? _numVal(dynamic v) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}

bool _boolVal(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
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
                    color: c,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
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
