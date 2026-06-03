import 'package:flutter/material.dart';
import 'package:smarthome/models/device.dart';

class DeviceTile extends StatelessWidget {
  final Device device;
  final VoidCallback? onTap;

  const DeviceTile({super.key, required this.device, this.onTap});

  static const _gold = Color(0xFFBFA86D);
  static const _cardBg = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final active = device.isActive;

    return GestureDetector(
      onTap: device.isToggleable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: active ? _gold.withOpacity(0.10) : _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? _gold.withOpacity(0.45) : Colors.white.withOpacity(0.07),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(device.icon, color: active ? _gold : Colors.white38, size: 26),
                if (device.isToggleable)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? _gold : Colors.white24,
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  device.statusText,
                  style: TextStyle(
                    color: active ? _gold : Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
