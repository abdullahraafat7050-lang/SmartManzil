import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:smarthome/l10n/app_localizations.dart';
import 'package:smarthome/models/camera.dart';
import 'package:smarthome/services/firebase_service.dart';
import 'package:smarthome/widgets/camera_widget.dart';

class CameraFeedScreen extends StatefulWidget {
  const CameraFeedScreen({super.key});

  @override
  State<CameraFeedScreen> createState() => _CameraFeedScreenState();
}

class _CameraFeedScreenState extends State<CameraFeedScreen> {
  static const _gold = Color(0xFFBFA86D);
  static const _bg = Color(0xFF0D0D0D);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF131418),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l.cameras,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<List<Camera>>(
        stream: FirebaseService().getCameras(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _gold),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                l.errorLoadingCameras,
                style: const TextStyle(color: Colors.white54),
              ),
            );
          }

          final cameras = snapshot.data ?? [];

          if (cameras.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam_off,
                    size: 48,
                    color: Colors.white24,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.noCamerasFound,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: cameras.length,
            itemBuilder: (context, index) {
              final camera = cameras[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraDetailScreen(camera: camera),
                    ),
                  );
                },
                child: CameraWidget(camera: camera),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Camera Detail Screen ──────────────────────────────────────────────────────

class CameraDetailScreen extends StatefulWidget {
  final Camera camera;

  const CameraDetailScreen({super.key, required this.camera});

  @override
  State<CameraDetailScreen> createState() => _CameraDetailScreenState();
}

class _CameraDetailScreenState extends State<CameraDetailScreen> {
  static const _bg = Color(0xFF0D0D0D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF131418),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.camera.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.camera.isOnline
                ? MjpegViewer(url: widget.camera.streamUrl)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.videocam_off,
                          size: 48,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Camera offline',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          Container(
            color: const Color(0xFF131418),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.camera.isOnline
                        ? Colors.greenAccent
                        : Colors.white24,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.camera.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: widget.camera.isOnline
                        ? Colors.greenAccent
                        : Colors.white54,
                    fontSize: 12,
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

// ── MJPEG Viewer ──────────────────────────────────────────────────────────────

class MjpegViewer extends StatefulWidget {
  final String url;
  const MjpegViewer({Key? key, required this.url}) : super(key: key);

  @override
  State<MjpegViewer> createState() => _MjpegViewerState();
}

class _MjpegViewerState extends State<MjpegViewer> {
  Uint8List? _frame;
  HttpClient? _httpClient;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _startStream();
  }

  @override
  void dispose() {
    _running = false;
    _httpClient?.close(force: true);
    super.dispose();
  }

  Future<void> _startStream() async {
    _httpClient = HttpClient();
    _running = true;
    try {
      final request = await _httpClient!.getUrl(Uri.parse(widget.url));
      final response = await request.close();

      // Read stream bytes and parse JPEG frames by boundary
      final bytesStream = response.asBroadcastStream();
      final completer = Completer<void>();

      final buffer = <int>[];
      await for (final chunk in bytesStream) {
        if (!_running) break;
        buffer.addAll(chunk);

        // Look for JPEG SOI/EOI markers
        final start = _indexOf(buffer, [0xFF, 0xD8]); // SOI
        final end = _indexOf(buffer, [0xFF, 0xD9]);   // EOI
        if (start != -1 && end != -1 && end > start) {
          final frame = buffer.sublist(start, end + 2);
          // remove used bytes
          buffer.removeRange(0, end + 2);

          setState(() {
            _frame = Uint8List.fromList(frame);
          });
        }
      }
      completer.complete();
      await completer.future;
    } catch (e) {
      // ignore or handle error
    }
  }

  static int _indexOf(List<int> data, List<int> pattern) {
    for (var i = 0; i <= data.length - pattern.length; i++) {
      var match = true;
      for (var j = 0; j < pattern.length; j++) {
        if (data[i + j] != pattern[j]) {
          match = false;
          break;
        }
      }
      if (match) return i;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    return _frame == null
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFFBFA86D)),
          )
        : Image.memory(_frame!, gaplessPlayback: true, fit: BoxFit.contain);
  }
}