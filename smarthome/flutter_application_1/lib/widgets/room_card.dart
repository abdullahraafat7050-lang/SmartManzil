import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../locale_service.dart';
import '../mqtt_manager.dart';
import '../services/firebase_service.dart';

class RoomCard extends StatelessWidget {
  final String roomKey;
  const RoomCard({super.key, required this.roomKey});

  static const _gold = Color(0xFFBFA86D);
  static const _card = Color(0xFF1E1E1E);

  static const _relayMap = {
    'bedroom': 'light1',  // pin 22
    'garden':  'light2',  // pin 23
    'living':  'light3',  // pin 24
  };

  static const _colorPresets = [
    Color(0xFFFFFFFF),
    Color(0xFFFFE0A3),
    Color(0xFFFFB347),
    Color(0xFF87CEEB),
    Color(0xFF98FB98),
    Color(0xFFFF6B6B),
    Color(0xFFDDA0DD),
    Color(0xFFFF69B4),
  ];

  String _toHex(Color c) =>
      '#${c.r.round().toRadixString(16).padLeft(2, '0')}'
      '${c.g.round().toRadixString(16).padLeft(2, '0')}'
      '${c.b.round().toRadixString(16).padLeft(2, '0')}'
          .toUpperCase();

  Color _parseHex(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return Colors.white;
    }
  }

  void _toggleLight(BuildContext ctx, bool current) {
    final mqtt = Provider.of<MQTTManager>(ctx, listen: false);
    FirebaseService().toggleLight(roomKey, !current);
    final relay = _relayMap[roomKey];
    if (relay != null) {
      final val = !current ? 1 : 0; // Active-LOW relay: 1=ON, 0=OFF
      mqtt.publishDirect(
        'home/home_001/actuators/lights',
        '{"path":"actuators/$relay","value":$val}',
      );
    }
  }

  void _setDimmer(BuildContext ctx, int value) {
    final mqtt = Provider.of<MQTTManager>(ctx, listen: false);
    FirebaseService().setDimmer(roomKey, value);
    mqtt.publishDirect('home/$roomKey/dimmer', value.toString());
  }

  void _setRGB(BuildContext ctx, Color color) {
    final mqtt = Provider.of<MQTTManager>(ctx, listen: false);
    final hex = _toHex(color);
    FirebaseService().setRGB(roomKey, hex);
    mqtt.publishDirect('home/$roomKey/rgb', hex);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseService().getRoomData(roomKey),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _gold));
        }
        if (!snap.hasData || snap.data?.exists == false) {
          FirebaseService().initRoom(roomKey);
          return const Center(
              child: CircularProgressIndicator(color: _gold));
        }

        final data = snap.data!.data() ?? {};
        final lightOn = data['light'] as bool? ?? false;
        final dimmer = (data['dimmer'] as num?)?.toInt() ?? 100;
        final rgbHex = data['rgb'] as String? ?? '#FFFFFF';
        final rgbColor = _parseHex(rgbHex);

        return Consumer<MQTTManager>(
          builder: (ctx, mqtt, _) => _buildCard(
            context: ctx,
            s: s,
            mqtt: mqtt,
            lightOn: lightOn,
            dimmer: dimmer,
            rgbHex: rgbHex,
            rgbColor: rgbColor,
          ),
        );
      },
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required S s,
    required MQTTManager mqtt,
    required bool lightOn,
    required int dimmer,
    required String rgbHex,
    required Color rgbColor,
  }) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: lightOn
                  ? _gold.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.07),
            ),
            boxShadow: lightOn
                ? [
                    BoxShadow(
                        color: _gold.withValues(alpha: 0.06),
                        blurRadius: 20,
                        spreadRadius: 2)
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Light toggle
              _ToggleRow(
                icon: Icons.lightbulb_outline,
                label: s.light,
                value: lightOn,
                activeColor: _gold,
                onChanged: (_) => _toggleLight(context, lightOn),
              ),

              // Window toggle (global — one window in the house)
              const Divider(color: Colors.white12, height: 24),
              _ToggleRow(
                icon: Icons.window,
                label: s.window,
                value: mqtt.windowOpen,
                activeColor: Colors.lightBlueAccent,
                onChanged: (_) {
                  final next = !mqtt.windowOpen;
                  mqtt.controlWindow(next);
                  FirebaseService().controlServo('window', next);
                },
              ),

              // Fan toggle
              const Divider(color: Colors.white12, height: 24),
              _ToggleRow(
                icon: Icons.air,
                label: s.fan,
                value: mqtt.fanActive,
                activeColor: Colors.cyanAccent,
                onChanged: (_) => mqtt.controlFan(!mqtt.fanActive),
              ),

              if (lightOn) ...[
                const SizedBox(height: 18),

                // Dimmer
                Row(children: [
                  Icon(Icons.brightness_6_outlined,
                      color: _gold.withValues(alpha: 0.8), size: 18),
                  const SizedBox(width: 8),
                  Text(s.dimmer,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  const Spacer(),
                  Text('$dimmer%',
                      style: const TextStyle(
                          color: _gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbColor: _gold,
                    activeTrackColor: _gold,
                    inactiveTrackColor: Colors.white12,
                    overlayColor: _gold.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: dimmer.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    onChanged: (_) {},
                    onChangeEnd: (v) => _setDimmer(context, v.round()),
                  ),
                ),

                const SizedBox(height: 14),

                // RGB
                Row(children: [
                  Icon(Icons.palette_outlined,
                      color: _gold.withValues(alpha: 0.8), size: 18),
                  const SizedBox(width: 8),
                  Text(s.color,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  const SizedBox(width: 8),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: rgbColor,
                      border: Border.all(color: Colors.white24),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colorPresets.map((c) {
                    final selected = _toHex(c) == rgbHex.toUpperCase();
                    return GestureDetector(
                      onTap: () => _setRGB(context, c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c,
                          border: Border.all(
                            color: selected
                                ? _gold
                                : Colors.white.withValues(alpha: 0.3),
                            width: selected ? 2.5 : 1.5,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                      color: _gold.withValues(alpha: 0.5),
                                      blurRadius: 6)
                                ]
                              : [],
                        ),
                        child: selected
                            ? Icon(Icons.check,
                                size: 12,
                                color: c.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
  }
}

// ── Reusable toggle row ───────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = value ? activeColor : Colors.white38;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: value ? 0.15 : 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: value ? Colors.white : Colors.white60,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Switch(
          value: value,
          activeColor: activeColor,
          inactiveThumbColor: Colors.white38,
          inactiveTrackColor: Colors.white12,
          onChanged: onChanged,
        ),
      ]),
    );
  }
}
