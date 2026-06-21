import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import '../locale_service.dart';

class CameraStreamScreen extends StatelessWidget {
  const CameraStreamScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    // Set the Raspberry Pi Tailscale IP address here.
    //const String tailscaleIp = '192.168.1.114';
    const String tailscaleIp = '100.79.6.90';
    const String streamUrl = 'http://$tailscaleIp:8081';

    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        title: Text(s.cameraLiveTitle),
        backgroundColor: Colors.blueGrey[900],
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Mjpeg(
                      fit: BoxFit.fitWidth,
                      isLive: true,
                      stream: streamUrl,
                      timeout: const Duration(seconds: 10),
                      loading: (context) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              s.cameraConnecting,
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      error: (context, error, stackTrace) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.signal_wifi_connected_no_internet_4,
                                    color: Colors.orangeAccent, size: 42),
                                const SizedBox(height: 8),
                                Text(
                                  s.cameraConnectionFailed,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  s.tailscaleConnectionHint,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ),
              ),
            ),
              
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.tailscaleSecureLabel,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}