import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smarthome/l10n/app_localizations.dart';
import 'package:smarthome/services/firebase_service.dart';

class SensorPanel extends StatelessWidget {
  const SensorPanel({super.key});

  static const _gold = Color(0xFFBFA86D);
  static const _card = Color(0xFF131418);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseService().getSensorsData(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? {};

        final temp = (data['temperature'] as num?)?.toDouble();
        final humidity = (data['humidity'] as num?)?.toDouble();
        final gas = data['gas'] as bool? ?? false;
        final smoke = data['smoke'] as bool? ?? false;
        final motion = data['motion'] as bool? ?? false;

        final hasAlert = gas || smoke;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasAlert
                  ? Colors.red.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: snap.connectionState == ConnectionState.waiting
              ? const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: _gold, strokeWidth: 2),
                  ),
                )
              : Row(
                  children: [
                    Icon(Icons.sensors, color: _gold, size: 18),
                    const SizedBox(width: 8),
                    Text(l.sensorsTitle,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (temp != null)
                              _Chip(
                                icon: Icons.thermostat,
                                label:
                                    '${temp.toStringAsFixed(1)}°C',
                                subtitle: l.temperatureLabel,
                              ),
                            if (humidity != null)
                              _Chip(
                                icon: Icons.water_drop_outlined,
                                label:
                                    '${humidity.toStringAsFixed(0)}%',
                                subtitle: l.humidityLabel,
                              ),
                            if (motion)
                              _AlertChip(
                                  icon: Icons.directions_run,
                                  label: l.motionLabel,
                                  color: Colors.orange),
                            if (gas)
                              _AlertChip(
                                  icon: Icons.warning_amber_rounded,
                                  label: l.gasAlert,
                                  color: Colors.red),
                            if (smoke)
                              _AlertChip(
                                  icon: Icons.cloud_outlined,
                                  label: l.smokeAlert,
                                  color: Colors.red),
                            if (!gas && !smoke && !motion)
                              _Chip(
                                icon: Icons.check_circle_outline,
                                label: l.allClear,
                                color: Colors.greenAccent,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? color;

  const _Chip({
    required this.icon,
    required this.label,
    this.subtitle,
    this.color,
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
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: c, size: 14),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    color: c,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
            if (subtitle != null)
              Text(subtitle!,
                  style: TextStyle(
                      color: c.withValues(alpha: 0.7),
                      fontSize: 9)),
          ],
        ),
      ]),
    );
  }
}

class _AlertChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _AlertChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
