import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

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
  StreamSubscription<List<int>>? _sub;

  @override
  void initState() {
    super.initState();
    _startStream();
  }

  @override
  void dispose() {
    _running = false;
    _sub?.cancel();
    _httpClient?.close(force: true);
    super.dispose();
  }

  Future<void> _startStream() async {
    _httpClient = HttpClient();
    _running = true;
    final buffer = <int>[];
    try {
      final request = await _httpClient!.getUrl(Uri.parse(widget.url));
      // optionally set Accept header for mjpeg:
      request.headers.set('Accept', 'multipart/x-mixed-replace');
      final response = await request.close();

      _sub = response.listen((chunk) {
        if (!_running) return;
        buffer.addAll(chunk);

        // find JPEG start (0xFF 0xD8) and end (0xFF 0xD9)
        final start = _indexOf(buffer, [0xFF, 0xD8]);
        final end = _indexOf(buffer, [0xFF, 0xD9]);
        if (start != -1 && end != -1 && end > start) {
          final frame = buffer.sublist(start, end + 2);
          // drop consumed bytes
          buffer.removeRange(0, end + 2);
          if (mounted) {
            setState(() {
              _frame = Uint8List.fromList(frame);
            });
          }
        } else {
          // keep buffering until we can find a full frame
          // If buffer grows too large, drop head bytes to avoid memory issues
          const maxBuffer = 5 * 1024 * 1024; // 5 MB
          if (buffer.length > maxBuffer) {
            buffer.removeRange(0, buffer.length - 512 * 1024);
          }
        }
      }, onError: (e) {
        // ignore or surface error
        // print('MJPEG stream error: $e');
      }, onDone: () {
        // stream ended
        _running = false;
      }, cancelOnError: true);
    } catch (e) {
      // print('Failed to start MJPEG stream: $e');
      _running = false;
    }
  }

  static int _indexOf(List<int> data, List<int> pattern) {
    final n = data.length;
    final m = pattern.length;
    if (m == 0 || n < m) return -1;
    for (var i = 0; i <= n - m; i++) {
      var ok = true;
      for (var j = 0; j < m; j++) {
        if (data[i + j] != pattern[j]) {
          ok = false;
          break;
        }
      }
      if (ok) return i;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    return _frame == null
        ? const Center(child: CircularProgressIndicator())
        : Image.memory(_frame!, gaplessPlayback: true, fit: BoxFit.contain);
  }
}