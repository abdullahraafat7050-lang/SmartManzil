import 'dart:async';

// Receives real-time device state pushes from the backend.
// Wire up once a real backend WebSocket server is available.
class WsClient {
  static final WsClient _instance = WsClient._internal();
  factory WsClient() => _instance;
  WsClient._internal();

  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  bool _connected = false;
  bool get isConnected => _connected;

  Future<void> connect(String token) async {
    // TODO: replace with real WebSocket connection
    // final ws = await WebSocket.connect('${AppConfig.wsUrl}?token=$token');
    // ws.listen((data) => _controller.add(json.decode(data as String)));
    // _connected = true;
    // connect to: AppConfig.wsUrl
  }

  void send(Map<String, dynamic> payload) {
    // TODO: ws.add(json.encode(payload));
  }

  Future<void> disconnect() async {
    _connected = false;
    // TODO: await ws.close();
  }

  void dispose() {
    _controller.close();
  }
}
