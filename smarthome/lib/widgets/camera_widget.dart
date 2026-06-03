import 'package:flutter/material.dart';
import 'package:smarthome/models/camera.dart';
import 'package:smarthome/widgets/mjpeg_viewer.dart';

class CameraWidget extends StatelessWidget {
  final Camera camera;

  const CameraWidget({super.key, required this.camera});

  static const _cardBg = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: camera.isOnline
                ? MjpegViewer(url: camera.streamUrl)
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam_off, color: Colors.white24, size: 36),
                        SizedBox(height: 8),
                        Text(
                          'Camera offline',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: camera.isOnline ? Colors.greenAccent : Colors.white24,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  camera.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
