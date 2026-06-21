import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smarthome/l10n/app_localizations.dart';
import 'package:smarthome/screens/camera_feed_screen.dart';
import 'package:smarthome/services/firebase_auth_service.dart';
import 'package:smarthome/services/firebase_service.dart';
import 'package:smarthome/widgets/room_card.dart';
import 'package:smarthome/widgets/sensor_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Firebase rooms — keys match Firestore document IDs
  final List<String> _roomKeys = ['bedroom', 'living', 'kitchen', 'garden'];
  int _selectedRoom = 0;

  static const _gold = Color(0xFFBFA86D);
  static const _bg = Color(0xFF0D0D0D);
  static const _card = Color(0xFF131418);

  String _roomLabel(String key, AppLocalizations l) {
    switch (key) {
      case 'bedroom':
        return l.areaBedroom;
      case 'living':
        return l.areaLivingRoom;
      case 'kitchen':
        return l.areaKitchen;
      case 'garden':
        return l.areaGarden;
      default:
        return key;
    }
  }

  IconData _roomIcon(String key) {
    switch (key) {
      case 'bedroom':
        return Icons.bedroom_child;
      case 'living':
        return Icons.weekend;
      case 'kitchen':
        return Icons.kitchen;
      case 'garden':
        return Icons.park;
      default:
        return Icons.home;
    }
  }

  String get _userName {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
  }

  Future<void> _logout() async {
    await FirebaseAuthService().signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _masterOff() async {
    for (final room in _roomKeys) {
      await FirebaseService().toggleLight(room, false);
    }
  }

  Future<void> _activateScene(bool morning) async {
    for (final room in _roomKeys) {
      await FirebaseService().toggleLight(room, morning);
      if (morning) await FirebaseService().setDimmer(room, 80);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(l),
            SensorPanel(),
            _buildRoomTabs(l),
            const SizedBox(height: 14),
            Expanded(
              child: RoomCard(roomKey: _roomKeys[_selectedRoom]),
            ),
            _buildSceneBar(l),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.goodEvening(_userName),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
                Text(
                  'akilli-manzil',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 12),
                ),
              ],
            ),
          ),
          // Alerts bell
          StreamBuilder<int>(
            stream: _alertCountStream(),
            builder: (_, snap) {
              final count = snap.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.white70, size: 24),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/alerts'),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 9),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Camera
          IconButton(
            icon: const Icon(Icons.videocam_outlined,
                color: Colors.white70, size: 22),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CameraFeedScreen(),
              ),
            ),
          ),
          // Settings
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: Colors.white70, size: 22),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          // Logout
          IconButton(
            tooltip: l.logout,
            icon: const Icon(Icons.logout,
                color: Colors.white54, size: 20),
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  Stream<int> _alertCountStream() {
    return FirebaseService()
        .getAlerts(limit: 50)
        .map((snap) => snap.docs.length);
  }

  // ── Room tabs ─────────────────────────────────────────────────────────────

  Widget _buildRoomTabs(AppLocalizations l) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _roomKeys.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final selected = i == _selectedRoom;
          return GestureDetector(
            onTap: () => setState(() => _selectedRoom = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 110,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected
                    ? _gold.withValues(alpha: 0.12)
                    : _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: selected ? _gold : Colors.transparent),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_roomIcon(_roomKeys[i]),
                      color: selected ? _gold : Colors.white54,
                      size: 22),
                  const SizedBox(height: 6),
                  Text(
                    _roomLabel(_roomKeys[i], l),
                    style: TextStyle(
                        color:
                            selected ? Colors.white : Colors.white54,
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Scene bar ─────────────────────────────────────────────────────────────

  Widget _buildSceneBar(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _card,
        border: Border(
            top: BorderSide(
                color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SceneButton(
            icon: Icons.wb_sunny,
            label: l.goodMorning,
            onTap: () => _activateScene(true),
          ),
          _SceneButton(
            icon: Icons.nightlight_round,
            label: l.goodNight,
            onTap: () => _activateScene(false),
          ),
          _SceneButton(
            icon: Icons.power_settings_new,
            label: l.masterOff,
            onTap: _masterOff,
            color: Colors.redAccent.withValues(alpha: 0.8),
          ),
          _SceneButton(
            icon: Icons.meeting_room_outlined,
            label: l.gate,
            onTap: () => FirebaseService().controlServo('gate', true),
          ),
        ],
      ),
    );
  }
}

// ── Scene button ──────────────────────────────────────────────────────────────

class _SceneButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SceneButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  static const _gold = Color(0xFFBFA86D);

  @override
  Widget build(BuildContext context) {
    final c = color ?? _gold;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c, size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: c.withValues(alpha: 0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
