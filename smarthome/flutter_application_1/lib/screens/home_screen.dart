import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../mqtt_manager.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../widgets/room_card.dart';
import '../widgets/sensor_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _rooms = ['bedroom', 'living', 'kitchen', 'garden'];
  int _selectedRoom = 0;

  static const _gold = Color(0xFFBFA86D);
  static const _bg = Color(0xFF121212);
  static const _card = Color(0xFF1E1E1E);

  String _roomLabel(String key) {
    switch (key) {
      case 'bedroom': return 'Bedroom';
      case 'living':  return 'Living';
      case 'kitchen': return 'Kitchen';
      case 'garden':  return 'Garden';
      default:        return key;
    }
  }

  IconData _roomIcon(String key) {
    switch (key) {
      case 'bedroom': return Icons.bedroom_child;
      case 'living':  return Icons.weekend;
      case 'kitchen': return Icons.kitchen;
      case 'garden':  return Icons.park;
      default:        return Icons.home;
    }
  }

  String get _userName {
    final u = FirebaseAuth.instance.currentUser;
    return u?.displayName ?? u?.email?.split('@')[0] ?? 'User';
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  // ── Scene actions — dual-sync ─────────────────────────────────────────────

  Future<void> _scene(bool morning) async {
    final mqtt = Provider.of<MQTTManager>(context, listen: false);
    for (final r in _rooms) {
      await FirebaseService().toggleLight(r, morning);
      if (morning) await FirebaseService().setDimmer(r, 80);
      mqtt.publishDirect('home/$r/light', morning ? '1' : '0');
    }
  }

  Future<void> _masterOff() async {
    final mqtt = Provider.of<MQTTManager>(context, listen: false);
    for (final r in _rooms) {
      await FirebaseService().toggleLight(r, false);
      mqtt.publishDirect('home/$r/light', '0');
    }
  }

  Future<void> _openGate() async {
    final mqtt = Provider.of<MQTTManager>(context, listen: false);
    await FirebaseService().controlServo('gate', true);
    mqtt.publishDirect('home/garden/gate', 'open');
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          const SensorPanel(),
          _buildRoomTabs(),
          const SizedBox(height: 12),
          Expanded(child: RoomCard(roomKey: _rooms[_selectedRoom])),
          _buildSceneBar(),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good Evening, $_userName',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              // MQTT connection indicator
              Consumer<MQTTManager>(
                builder: (_, mqtt, __) => Row(children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: mqtt.isConnected
                          ? Colors.greenAccent
                          : Colors.white24,
                    ),
                  ),
                  Text(
                    mqtt.isConnected ? 'MQTT online' : 'MQTT offline',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 11),
                  ),
                ]),
              ),
            ],
          ),
        ),
        // Alerts badge
        StreamBuilder(
          stream: FirebaseService().getAlerts(limit: 50),
          builder: (ctx, snap) {
            final count = snap.data?.docs.length ?? 0;
            return Stack(children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white70),
                onPressed: () => Navigator.pushNamed(context, '/alerts'),
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
            ]);
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined,
              color: Colors.white70, size: 22),
          onPressed: () => Navigator.pushNamed(context, '/settings'),
        ),
        IconButton(
          icon: const Icon(Icons.logout,
              color: Colors.white38, size: 20),
          tooltip: 'Log out',
          onPressed: _logout,
        ),
      ]),
    );
  }

  Widget _buildRoomTabs() {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _rooms.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final sel = i == _selectedRoom;
          return GestureDetector(
            onTap: () => setState(() => _selectedRoom = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 96,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    sel ? _gold.withValues(alpha: 0.12) : _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: sel ? _gold : Colors.transparent),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_roomIcon(_rooms[i]),
                      color: sel ? _gold : Colors.white54,
                      size: 20),
                  const SizedBox(height: 4),
                  Text(_roomLabel(_rooms[i]),
                      style: TextStyle(
                          color:
                              sel ? Colors.white : Colors.white54,
                          fontSize: 11,
                          fontWeight: sel
                              ? FontWeight.w600
                              : FontWeight.normal),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSceneBar() {
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
          _SceneBtn(
              icon: Icons.wb_sunny,
              label: 'Good Morning',
              onTap: () => _scene(true)),
          _SceneBtn(
              icon: Icons.nightlight_round,
              label: 'Good Night',
              onTap: () => _scene(false)),
          _SceneBtn(
              icon: Icons.power_settings_new,
              label: 'Master Off',
              onTap: _masterOff,
              color: Colors.redAccent.withValues(alpha: 0.8)),
          _SceneBtn(
              icon: Icons.door_sliding_outlined,
              label: 'Gate',
              onTap: _openGate),
        ],
      ),
    );
  }
}

class _SceneBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SceneBtn(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFFBFA86D);
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: c, size: 22),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: c.withValues(alpha: 0.9),
                fontSize: 10,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
