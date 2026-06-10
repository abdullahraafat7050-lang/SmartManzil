import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../locale_service.dart';
import '../services/firebase_service.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  static const _gold = Color(0xFFBFA86D);
  static const _bg = Color(0xFF121212);
  static const _card = Color(0xFF1E1E1E);

  Color _colorFor(String? type) {
    switch (type?.toLowerCase()) {
      case 'gas':
      case 'fire':
        return Colors.redAccent;
      case 'motion':
      case 'intrusion':
        return Colors.orangeAccent;
      default:
        return _gold;
    }
  }

  IconData _iconFor(String? type) {
    switch (type?.toLowerCase()) {
      case 'gas':
        return Icons.gas_meter_outlined;
      case 'fire':
        return Icons.local_fire_department_outlined;
      case 'motion':
      case 'intrusion':
        return Icons.directions_run;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatTime(DateTime t) {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '${months[t.month - 1]} ${t.day}, $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(s.alertsTitle,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              color: Colors.white.withValues(alpha: 0.07), height: 1),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseService().getAlerts(limit: 100),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _gold));
          }

          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.white.withValues(alpha: 0.2),
                      size: 56),
                  const SizedBox(height: 16),
                  Text(s.noAlerts,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final data = docs[i].data();
              final type = data['type'] as String?;
              final message = data['message'] as String? ?? '';
              final ts = data['timestamp'] as Timestamp?;
              final time = ts?.toDate();
              final color = _colorFor(type);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child:
                          Icon(_iconFor(type), color: color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (type != null)
                            Text(type.toUpperCase(),
                                style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1)),
                          const SizedBox(height: 2),
                          Text(message,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14)),
                          if (time != null) ...[
                            const SizedBox(height: 6),
                            Text(_formatTime(time),
                                style: TextStyle(
                                    color: Colors.white
                                        .withValues(alpha: 0.35),
                                    fontSize: 11)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
