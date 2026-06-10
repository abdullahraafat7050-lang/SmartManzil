import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'global_keys.dart';
import 'services/firebase_service.dart';

class MQTTManager extends ChangeNotifier {
  MqttBrowserClient? _client;

  // ── Local broker (editable from settings) ────────────────────────────────
  String broker = '192.168.1.112';
  int port = 9001; // WebSocket port

  // ── HiveMQ Cloud credentials ──────────────────────────────────────────────
  static const _remoteBroker =
      '09d4a42e19724bf7b2a3204bb9ee1bd2.s1.eu.hivemq.cloud';
  static const _remotePort = 8884; // HiveMQ WebSocket SSL
  static const _remoteUser = 'akilli_menzil';
  static const _remotePass = 'a5eUB@njzud6s4C';

  // ── Connection state ──────────────────────────────────────────────────────
  bool isRemote = false;
  Timer? _reconnectTimer;

  // ── Sensor state (updated from MQTT) ──────────────────────────────────────
  String gasStatus = 'OK';
  String rainStatus = 'Dry';
  bool fanActive = false;
  double? temperature;
  double? humidity;
  bool motionDetected = false;
  bool smokeDetected = false;
  bool windowOpen = false;

  // ── Legacy state (kept for compatibility) ─────────────────────────────────
  Map<String, bool> lights = {
    'Living Room': false,
    'Bedroom': false,
    'Kitchen': false
  };
  Map<String, double> curtains = {
    'Master Bedroom': 0.0,
    'Living Room': 0.0
  };
  Map<String, bool> doors = {
    'Living Room': true,
    'Bedroom': true,
    'Kitchen': true
  };
  bool cameraAuthorized = true;
  bool keypadEntry = false;
  bool appOverride = false;

  StreamSubscription? _updatesSubscription;

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  // ── Public connect (tries local → remote) ────────────────────────────────
  Future<void> connect() async {
    _updatesSubscription?.cancel();
    _reconnectTimer?.cancel();
    _client?.disconnect();

    // 1. Try local broker (5-second timeout)
    final localOk = await _tryConnect(
      host: broker,
      port: port,
      secure: false,
      username: 'smart_ev',
      password: '12345678',
    );
    if (localOk) {
      isRemote = false;
      notifyListeners();
      return;
    }

    // 2. Fall back to HiveMQ Cloud
    final remoteOk = await _tryConnect(
      host: _remoteBroker,
      port: _remotePort,
      secure: true,
      username: _remoteUser,
      password: _remotePass,
    );
    isRemote = remoteOk;

    // If both fail, schedule a retry
    if (!remoteOk) {
      _reconnectTimer = Timer(const Duration(seconds: 15), connect);
    }

    notifyListeners();
  }

  // ── Internal: attempt a single broker connection ──────────────────────────
  Future<bool> _tryConnect({
    required String host,
    required int port,
    required bool secure,
    String? username,
    String? password,
  }) async {
    final clientId = 'flutter_${DateTime.now().millisecondsSinceEpoch}';
    final wsScheme = secure ? 'wss' : 'ws';
    final url = '$wsScheme://$host';
    debugPrint('[MQTT] Trying $url:$port  user=$username');

    _client = MqttBrowserClient(url, clientId);
    _client!.port = port;
    _client!.logging(on: true);
    _client!.keepAlivePeriod = 20;

    var connMsg = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    if (username != null && password != null) {
      connMsg = connMsg.authenticateAs(username, password);
    }
    _client!.connectionMessage = connMsg;

    try {
      final status = await _client!
          .connect()
          .timeout(const Duration(seconds: 5));
      debugPrint('[MQTT] Status: ${status?.state}');
      if (status?.state == MqttConnectionState.connected) {
        debugPrint('[MQTT] ✓ Connected to $url:$port');
        _client!.onDisconnected = _onDisconnected;
        _setupSubscriptions();
        return true;
      }
      debugPrint('[MQTT] ✗ Not connected — state=${status?.state}');
    } catch (e) {
      debugPrint('[MQTT] ✗ Exception: $e');
      _client?.disconnect();
    }
    return false;
  }

  // ── Auto-reconnect on drop ────────────────────────────────────────────────
  void _onDisconnected() {
    notifyListeners();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 10), connect);
  }

  // ── Subscriptions (unchanged) ─────────────────────────────────────────────
  void _setupSubscriptions() {
    // Sensor topics
    _client!.subscribe('home/sensors/#', MqttQos.atMostOnce);
    // Alert topics
    _client!.subscribe('home/alerts/#', MqttQos.atLeastOnce);
    // Room device feedback
    _client!.subscribe('home/+/light', MqttQos.atMostOnce);
    _client!.subscribe('home/+/dimmer', MqttQos.atMostOnce);
    _client!.subscribe('home/+/motion', MqttQos.atMostOnce);
    // Global window
    _client!.subscribe('home/window', MqttQos.atMostOnce);

    _updatesSubscription = _client!.updates!
        .listen((List<MqttReceivedMessage<MqttMessage>> msgs) {
      if (msgs.isEmpty) return;
      final recMsg = msgs[0].payload as MqttPublishMessage;
      final topic = msgs[0].topic;
      final payload =
          MqttPublishPayload.bytesToStringAsString(recMsg.payload.message);
      _handlePayload(topic, payload);
    });
  }

  void _handlePayload(String topic, String payload) {
    // Python bridge wraps values in JSON: {"value":1,"source":"arduino_mega",...}
    // Extract the raw value string regardless of format
    String val = payload;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map && decoded.containsKey('value')) {
        val = decoded['value'].toString();
      }
    } catch (_) {
      // plain payload — use as-is
    }

    debugPrint('[MQTT] topic=$topic  val=$val');

    // Sensors
    if (topic == 'home/sensors/temperature') {
      temperature = double.tryParse(val);
      FirebaseService().updateSensorRTDB('temperature', temperature);
    } else if (topic == 'home/sensors/humidity') {
      humidity = double.tryParse(val);
      FirebaseService().updateSensorRTDB('humidity', humidity);
    } else if (topic == 'home/sensors/motion') {
      motionDetected = val == '1' || val == 'true';
      FirebaseService().updateSensorRTDB('motion', motionDetected);
    } else if (topic == 'home/sensors/gas' || topic == 'home/kitchen/gas') {
      gasStatus = val == '1' ? 'LEAK DETECTED' : 'OK';
      FirebaseService().updateSensorRTDB('gas', val == '1');
    } else if (topic == 'home/kitchen/smoke' || topic == 'home/sensors/flame') {
      smokeDetected = val == '1' || val == 'true';
      FirebaseService().updateSensorRTDB('flame', smokeDetected);
    } else if (topic == 'home/sensors/rain') {
      rainStatus = val == '1' ? 'Raining' : 'Dry';
      FirebaseService().updateSensorRTDB('rain', val == '1');
    } else if (topic == 'home/sensors/fan') {
      fanActive = val == '1' || val == 'true';
    } else if (topic == 'home/window') {
      windowOpen = val == '1' || val == 'true';
    }
    // Motion in rooms
    else if (topic.contains('/motion')) {
      motionDetected = val == '1' || val == 'true';
      FirebaseService().updateSensorRTDB('motion', motionDetected);
    }
    // Alerts
    else if (topic.startsWith('home/alerts/')) {
      if (payload.isNotEmpty) _triggerAlert(topic, payload);
    }

    notifyListeners();
  }

  void _triggerAlert(String topic, String payload) {
    final type = topic.split('/').last.toUpperCase();
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('⚠️  $type alert: $payload'),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // ── Public publish method (used by RoomCard for dual-sync) ────────────────
  void publishDirect(String topic, String message) {
    _publish(topic, message);
  }

  // ── Legacy methods (kept for compatibility) ───────────────────────────────
  void toggleLight(String room) {
    lights[room] = !lights[room]!;
    _publish('home/lights/$room', lights[room]! ? '1' : '0');
    notifyListeners();
  }

  void toggleDoor(String room) {
    doors[room] = !doors[room]!;
    _publish('home/servos/$room', doors[room]! ? '1' : '0');
    notifyListeners();
  }

  void updateCurtain(String room, double value) {
    curtains[room] = value;
    _publish('home/curtains/$room', value.toInt().toString());
    notifyListeners();
  }

  void toggleGate() {
    appOverride = !appOverride;
    _publish('home/servos/master_gate', '1');
    notifyListeners();
  }

  void _publish(String topic, String message) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      _client!.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    }
  }
}
