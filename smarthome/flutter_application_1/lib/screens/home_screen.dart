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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mqtt = Provider.of<MQTTManager>(context, listen: false);
      mqtt.connect();
    });
  }

  static const _relayMap = {
    'bedroom': 'light1',  // pin 22
    'garden':  'light2',  // pin 23
    'living':  'light3',  // pin 24
  };

  static const _roomIcons = [
    Icons.bedroom_child,
    Icons.weekend,
    Icons.kitchen,
    Icons.park,
  ];

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
      final relay = _relayMap[r];
      if (relay != null) {
        final val = morning ? 1 : 0; // 1=ON, 0=OFF
        mqtt.publishDirect(
          'home/home_001/actuators/lights',
          '{"path":"actuators/$relay","value":$val}',
        );
        await Future.delayed(const Duration(milliseconds: 150));
      }
    }
  }

  Future<void> _masterOff() async {
    final mqtt = Provider.of<MQTTManager>(context, listen: false);

    // إطفاء كل الأنوار بدون delays (منع infinite loop)
    mqtt.publishDirect('home/home_001/actuators/lights', '{"path":"actuators/light1","value":0}');
    mqtt.publishDirect('home/home_001/actuators/lights', '{"path":"actuators/light2","value":0}');
    mqtt.publishDirect('home/home_001/actuators/lights', '{"path":"actuators/light3","value":0}');

    // إطفاء المروحة
    mqtt.publishDirect('home/home_001/actuators/fan', '{"path":"actuators/fan","value":0}');
    mqtt.recordAction('fan', 'Fan turned off requested');

    // إغلاق الشباك
    mqtt.publishDirect('home/home_001/actuators/windows', '{"path":"actuators/windows","value":"close"}');
    mqtt.recordAction('window', 'Window close requested');

    // إغلاق البوابة (Gate)
    await Future.delayed(const Duration(milliseconds: 100));
    mqtt.publishDirect(
      'home/home_001/actuators/gate',
      '{"path":"actuators/gate","value":"close"}',
    );
    mqtt.recordAction('gate', 'Gate close requested');

    // تحديث Firebase بدون انتظار
    for (final r in _rooms) {
      FirebaseService().toggleLight(r, false);
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
                      mqtt.publishDirect(
                        'home/home_001/actuators/gate',
                        '{"path":"actuators/gate","value":"open"}',
                      );
                      mqtt.recordAction('gate', 'Gate open requested');
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
                      mqtt.publishDirect(
                        'home/home_001/actuators/gate',
                        '{"path":"actuators/gate","value":"close"}',
                      );
                      mqtt.recordAction('gate', 'Gate close requested');
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
      bottomNavigationBar: _buildSceneBar(s),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(s),
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [
                const SizedBox(height: 4),
                const SensorPanel(),
                const SizedBox(height: 12),
                _buildRoomGrid(s),
                const SizedBox(height: 12),
                RoomCard(roomKey: _rooms[_selectedRoom]),
                const SizedBox(height: 16),
              ]),
            ),
          ),
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
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                        color: Colors.redAccent, shape: BoxShape.circle),
                  ),
                ),
            ]);
          },
        ),
        IconButton(
          icon: const Icon(Icons.videocam_outlined,
              color: Colors.white70, size: 22),
          onPressed: () => Navigator.pushNamed(context, '/camera'),
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

  Widget _buildRoomGrid(S s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.9,
        children: List.generate(_rooms.length, (i) {
          final sel = i == _selectedRoom;
          return GestureDetector(
            onTap: () => setState(() => _selectedRoom = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: sel ? _gold.withValues(alpha: 0.12) : _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: sel ? _gold : Colors.white.withValues(alpha: 0.07),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _roomIcons[i],
                    color: sel ? _gold : Colors.white54,
                    size: 32,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.roomLabel(_rooms[i]),
                    style: TextStyle(
                      color: sel ? Colors.white : Colors.white54,
                      fontSize: 13,
                      fontWeight:
                          sel ? FontWeight.w600 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSceneBar(S s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: _card,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SceneBtn(
            icon: Icons.wb_sunny,
            label: s.goodMorning,
            onTap: () => _scene(true),
          ),
          _SceneBtn(
            icon: Icons.nightlight_round,
            label: s.goodNight,
            onTap: () => _scene(false),
          ),
          _SceneBtn(
            icon: Icons.power_settings_new,
            label: s.masterOff,
            onTap: _masterOff,
            color: Colors.redAccent.withValues(alpha: 0.8),
          ),
          _SceneBtn(
            icon: Icons.door_sliding_outlined,
            label: s.gate,
            onTap: () => _showGateBottomSheet(context),
          ),
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
  final bool showLabel;

  const _SceneBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFFBFA86D);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: c, size: 24),
          if (showLabel) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: c.withValues(alpha: 0.9),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
