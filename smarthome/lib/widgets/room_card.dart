import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smarthome/l10n/app_localizations.dart';
import 'package:smarthome/services/firebase_service.dart';

class RoomCard extends StatelessWidget {
  final String roomKey; // 'bedroom' | 'living' | 'kitchen' | 'garden'

  const RoomCard({super.key, required this.roomKey});

  static const _gold = Color(0xFFBFA86D);
  static const _card = Color(0xFF131418);

  static const _colorPresets = [
    Color(0xFFFFFFFF), // White
    Color(0xFFFFE0A3), // Warm white
    Color(0xFFFFB347), // Amber
    Color(0xFF87CEEB), // Sky blue
    Color(0xFF98FB98), // Pale green
    Color(0xFFFF6B6B), // Coral
    Color(0xFFDDA0DD), // Plum
    Color(0xFFFF69B4), // Pink
  ];

  Color _parseHex(String hex) {
    final h = hex.replaceAll('#', '');
    if (h.length != 6) return Colors.white;
    return Color(int.parse('FF$h', radix: 16));
  }

  String _toHex(Color c) =>
      '#${c.r.round().toRadixString(16).padLeft(2, '0')}${c.g.round().toRadixString(16).padLeft(2, '0')}${c.b.round().toRadixString(16).padLeft(2, '0')}'.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final fb = FirebaseService();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: fb.getRoomData(roomKey),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _gold));
        }

        // Auto-init document if it doesn't exist
        if (!snap.hasData || snap.data?.exists == false) {
          fb.initRoom(roomKey);
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
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: lightOn
                  ? _gold.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.06),
            ),
            boxShadow: lightOn
                ? [
                    BoxShadow(
                        color: _gold.withValues(alpha: 0.08),
                        blurRadius: 20,
                        spreadRadius: 2)
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Light toggle ─────────────────────────────────────────
              _SectionRow(
                label: l.lightLabel,
                icon: Icons.lightbulb_outline,
                iconColor: lightOn ? _gold : Colors.white38,
                trailing: Switch(
                  value: lightOn,
                  activeColor: _gold,
                  onChanged: (val) => fb.toggleLight(roomKey, val),
                ),
              ),

              if (lightOn) ...[
                const SizedBox(height: 20),

                // ── Dimmer ───────────────────────────────────────────
                Row(children: [
                  Icon(Icons.brightness_6_outlined,
                      color: _gold.withValues(alpha: 0.8), size: 18),
                  const SizedBox(width: 8),
                  Text(l.dimmerLabel,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14)),
                  const Spacer(),
                  Text('$dimmer%',
                      style: const TextStyle(
                          color: _gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ]),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbColor: _gold,
                    activeTrackColor: _gold,
                    inactiveTrackColor:
                        Colors.white.withValues(alpha: 0.12),
                    overlayColor: _gold.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: dimmer.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    onChanged: (_) {}, // visual only during drag
                    onChangeEnd: (v) =>
                        fb.setDimmer(roomKey, v.round()),
                  ),
                ),

                const SizedBox(height: 20),

                // ── RGB presets ─────────────────────────────────────
                Row(children: [
                  Icon(Icons.palette_outlined,
                      color: _gold.withValues(alpha: 0.8), size: 18),
                  const SizedBox(width: 8),
                  Text(l.colorLabel,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14)),
                  const SizedBox(width: 10),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: rgbColor,
                      border: Border.all(
                          color: Colors.white24, width: 1.5),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _colorPresets.map((c) {
                    final selected =
                        _toHex(c).toUpperCase() == rgbHex.toUpperCase();
                    return GestureDetector(
                      onTap: () => fb.setRGB(roomKey, _toHex(c)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c,
                          border: Border.all(
                            color: selected
                                ? _gold
                                : Colors.white.withValues(alpha: 0.25),
                            width: selected ? 2.5 : 1.5,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                      color: _gold
                                          .withValues(alpha: 0.5),
                                      blurRadius: 8)
                                ]
                              : [],
                        ),
                        child: selected
                            ? Icon(Icons.check,
                                size: 14,
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

class _SectionRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Widget trailing;

  const _SectionRow({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: iconColor, size: 22),
      const SizedBox(width: 10),
      Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500)),
      const Spacer(),
      trailing,
    ]);
  }
}
