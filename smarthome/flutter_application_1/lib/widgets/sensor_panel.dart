import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../locale_service.dart';
import '../mqtt_manager.dart';
import '../services/firebase_service.dart';

class SensorPanel extends StatelessWidget {
  const SensorPanel({super.key});

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

            return Column(children: [
              _MergedCard(
                leftIcon: Icons.thermostat,
                leftValue: temp != null ? '${temp.toStringAsFixed(1)}°C' : '--',
                leftLabel: s.temp,
                rightIcon: Icons.water_drop_outlined,
                rightValue: humidity != null
                    ? '${humidity.toStringAsFixed(0)}%'
                    : '--',
                rightLabel: s.humidity,
              ),
              _MergedCard(
                leftIcon: gasAlert
                    ? Icons.warning_rounded
                    : Icons.gas_meter_outlined,
                leftValue: gasAlert ? 'GAS!' : 'OK',
                leftLabel: 'Gas',
                leftColor: gasAlert ? Colors.redAccent : Colors.greenAccent,
                leftAlert: gasAlert,
                rightIcon: smokeAlert ? Icons.cloud : Icons.smoke_free,
                rightValue: smokeAlert ? 'SMOKE!' : 'OK',
                rightLabel: s.smoke,
                rightColor: smokeAlert ? Colors.redAccent : Colors.greenAccent,
                rightAlert: smokeAlert,
              ),
              _MergedCard(
                leftIcon: motion
                    ? Icons.directions_run
                    : Icons.accessibility_new,
                leftValue: motion ? 'Motion!' : 'Clear',
                leftLabel: s.motion,
                leftColor: motion ? Colors.orangeAccent : Colors.greenAccent,
                leftAlert: motion,
                rightIcon:
                    rainAlert ? Icons.umbrella : Icons.wb_sunny_outlined,
                rightValue: rainAlert ? 'Rain!' : 'Dry',
                rightLabel: s.rain,
                rightColor:
                    rainAlert ? Colors.blueAccent : Colors.greenAccent,
                rightAlert: rainAlert,
              ),
            ]);
          },
        );
      },
    );
  }
}

// ── helpers ───────────────────────────────────────────────────────────────────

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

// ── Merged card (2 sensors side by side) ─────────────────────────────────────

class _MergedCard extends StatelessWidget {
  final IconData leftIcon;
  final String leftValue;
  final String leftLabel;
  final Color leftColor;
  final bool leftAlert;

  final IconData rightIcon;
  final String rightValue;
  final String rightLabel;
  final Color rightColor;
  final bool rightAlert;

  static const _gold = Color(0xFFBFA86D);
  static const _card = Color(0xFF1E1E1E);

  const _MergedCard({
    required this.leftIcon,
    required this.leftValue,
    required this.leftLabel,
    this.leftColor = _gold,
    this.leftAlert = false,
    required this.rightIcon,
    required this.rightValue,
    required this.rightLabel,
    this.rightColor = _gold,
    this.rightAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasAlert = leftAlert || rightAlert;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasAlert
              ? Colors.redAccent.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.08),
          width: hasAlert ? 1.5 : 1.0,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(children: [
          Expanded(
            child: _SensorHalf(
              icon: leftIcon,
              value: leftValue,
              label: leftLabel,
              color: leftColor,
              alert: leftAlert,
            ),
          ),
          VerticalDivider(
            color: Colors.white.withValues(alpha: 0.08),
            width: 24,
            thickness: 1,
          ),
          Expanded(
            child: _SensorHalf(
              icon: rightIcon,
              value: rightValue,
              label: rightLabel,
              color: rightColor,
              alert: rightAlert,
            ),
          ),
        ]),
      ),
    );
  }
}

class _SensorHalf extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool alert;

  const _SensorHalf({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.alert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: alert ? 0.18 : 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 26),
      ),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    ]);
  }
}
