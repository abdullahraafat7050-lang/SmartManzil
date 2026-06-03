import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'global_keys.dart';

class MQTTManager extends ChangeNotifier {
  MqttServerClient? _client;
  String broker = '192.168.1.100';
  int port = 1883;

  // ── Sensor state (updated from MQTT) ──────────────────────────────────────
  String gasStatus = 'OK';
  String rainStatus = 'Dry';
  bool fanActive = false;
  double? temperature;
  double? humidity;
  bool motionDetected = false;
  bool smokeDetected = false;

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

  Future<void> connect() async {
    _updatesSubscription?.cancel();
    _client?.disconnect();

    final clientId = 'flutter_${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient(broker, clientId);
    _client!.port = port;
    _client!.logging(on: false);
    _client!.keepAlivePeriod = 20;
    _client!.onDisconnected = () => notifyListeners();

    final connMsg = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    _client!.connectionMessage = connMsg;

    try {
      final status = await _client!.connect();
      if (status?.state == MqttConnectionState.connected) {
        _setupSubscriptions();
        notifyListeners();
      }
    } catch (e) {
      _client?.disconnect();
    }
  }

  void _setupSubscriptions() {
    // Sensor topics
    _client!.subscribe('home/sensors/#', MqttQos.atMostOnce);
    // Alert topics
    _client!.subscribe('home/alerts/#', MqttQos.atLeastOnce);
    // Room device feedback
    _client!.subscribe('home/+/light', MqttQos.atMostOnce);
    _client!.subscribe('home/+/dimmer', MqttQos.atMostOnce);
    _client!.subscribe('home/+/motion', MqttQos.atMostOnce);

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
    // Sensors
    if (topic == 'home/sensors/temperature') {
      temperature = double.tryParse(payload);
    } else if (topic == 'home/sensors/humidity') {
      humidity = double.tryParse(payload);
    } else if (topic == 'home/sensors/motion') {
      motionDetected = payload == '1';
    } else if (topic == 'home/sensors/gas' || topic == 'home/kitchen/gas') {
      gasStatus = payload == '1' ? 'LEAK DETECTED' : 'OK';
    } else if (topic == 'home/kitchen/smoke') {
      smokeDetected = payload == '1';
    } else if (topic == 'home/sensors/rain') {
      rainStatus = payload == '1' ? 'Raining' : 'Dry';
    } else if (topic == 'home/sensors/fan') {
      fanActive = payload == '1';
    }
    // Motion in rooms
    else if (topic.contains('/motion')) {
      motionDetected = payload == '1';
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
