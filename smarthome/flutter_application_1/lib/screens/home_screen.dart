import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../locale_service.dart';
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

  String get _userName {
    final u = FirebaseAuth.instance.currentUser;
    return u?.displayName ?? u?.email?.split('@')[0] ?? 'User';
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

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

  void _showGateBottomSheet(BuildContext ctx) {
    final mqtt = Provider.of<MQTTManager>(ctx, listen: false);
    showModalBottomSheet(
      context: ctx,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.door_sliding_outlined,
                    color: Colors.white70, size: 22),
                SizedBox(width: 8),
                Text(
                  'Gate Control',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      mqtt.publishDirect('home/garden/gate', 'open');
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.lock_open_outlined),
                    label: const Text('Open'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      mqtt.publishDirect('home/garden/gate', 'close');
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.lock_outlined),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(s),
          const SensorPanel(),
          _buildRoomTabs(s),
          const SizedBox(height: 12),
          Expanded(child: RoomCard(roomKey: _rooms[_selectedRoom])),
          _buildSceneBar(s),
        ]),
      ),
    );
  }

  Widget _buildHeader(S s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.goodEvening(_userName),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
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
                    mqtt.isConnected ? s.mqttOnline : s.mqttOffline,
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
          icon: const Icon(Icons.logout, color: Colors.white38, size: 20),
          tooltip: s.logout,
          onPressed: _logout,
        ),
      ]),
    );
  }

  Widget _buildRoomTabs(S s) {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _rooms.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final sel = i == _selectedRoom;
          final icons = [
            Icons.bedroom_child,
            Icons.weekend,
            Icons.kitchen,
            Icons.park
          ];
          return GestureDetector(
            onTap: () => setState(() => _selectedRoom = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 96,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: sel ? _gold.withValues(alpha: 0.12) : _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: sel ? _gold : Colors.transparent),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icons[i],
                      color: sel ? _gold : Colors.white54, size: 20),
                  const SizedBox(height: 4),
                  Text(s.roomLabel(_rooms[i]),
                      style: TextStyle(
                          color: sel ? Colors.white : Colors.white54,
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

  Widget _buildSceneBar(S s) {
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
              label: s.goodMorning,
              onTap: () => _scene(true)),
          _SceneBtn(
              icon: Icons.nightlight_round,
              label: s.goodNight,
              onTap: () => _scene(false)),
          _SceneBtn(
              icon: Icons.power_settings_new,
              label: s.masterOff,
              onTap: _masterOff,
              color: Colors.redAccent.withValues(alpha: 0.8)),
          _SceneBtn(
              icon: Icons.door_sliding_outlined,
              label: s.gate,
              onTap: () => _showGateBottomSheet(context)),
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
