import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../mqtt_manager.dart';
import '../services/firebase_service.dart';

// Dual-sync room control card.
// StreamBuilder reads live Firestore state.
// On user interaction → updates BOTH Firestore AND publishes to MQTT.
class RoomCard extends StatelessWidget {
  final String roomKey; // 'bedroom' | 'living' | 'kitchen' | 'garden'

  const RoomCard({super.key, required this.roomKey});

  static const _gold = Color(0xFFBFA86D);
  static const _card = Color(0xFF1E1E1E);

  static const _colorPresets = [
    Color(0xFFFFFFFF), // White
    Color(0xFFFFE0A3), // Warm white
    Color(0xFFFFB347), // Amber
    Color(0xFF87CEEB), // Sky blue
    Color(0xFF98FB98), // Pale green
    Color(0xFFFF6B6B), // Coral red
    Color(0xFFDDA0DD), // Plum
    Color(0xFFFF69B4), // Pink
  ];

  String _toHex(Color c) =>
      '#${c.r.round().toRadixString(16).padLeft(2, '0')}'
      '${c.g.round().toRadixString(16).padLeft(2, '0')}'
      '${c.b.round().toRadixString(16).padLeft(2, '0')}'
          .toUpperCase();

  Color _parseHex(String hex) {
    try {
      return Color(
          int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return Colors.white;
    }
  }

  // Dual-sync: Firestore + MQTT
  void _toggleLight(BuildContext ctx, bool current) {
    final mqtt = Provider.of<MQTTManager>(ctx, listen: false);
    FirebaseService().toggleLight(roomKey, !current);
    mqtt.publishDirect('home/$roomKey/light', !current ? '1' : '0');
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
              // ── Light toggle ────────────────────────────────────────────
              Row(children: [
                Icon(Icons.lightbulb_outline,
                    color: lightOn ? _gold : Colors.white38, size: 22),
                const SizedBox(width: 10),
                const Text('Light',
                    style: TextStyle(color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.w500)),
                const Spacer(),
                Switch(
                  value: lightOn,
                  activeColor: _gold,
                  onChanged: (_) => _toggleLight(context, lightOn),
                ),
              ]),

              if (lightOn) ...[
                const SizedBox(height: 18),

                // ── Dimmer ────────────────────────────────────────────────
                Row(children: [
                  Icon(Icons.brightness_6_outlined,
                      color: _gold.withValues(alpha: 0.8), size: 18),
                  const SizedBox(width: 8),
                  const Text('Dimmer',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
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

                // ── RGB color presets ─────────────────────────────────────
                Row(children: [
                  Icon(Icons.palette_outlined,
                      color: _gold.withValues(alpha: 0.8), size: 18),
                  const SizedBox(width: 8),
                  const Text('Color',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 13)),
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
                    final selected =
                        _toHex(c) == rgbHex.toUpperCase();
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
      },
    );
  }
}
