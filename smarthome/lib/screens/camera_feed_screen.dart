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
        ? const Center(child: CircularProgressIndicator())
        : Image.memory(_frame!, gaplessPlayback: true, fit: BoxFit.contain);
  }
}