import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'global_keys.dart'; // Import the global key

class MQTTManager extends ChangeNotifier {
  MqttServerClient? _client;
  String broker = '192.168.1.100'; // Default IP
  int port = 1883;

  // App State
  Map<String, bool> lights = {'Living Room': false, 'Bedroom': false, 'Kitchen': false};
  Map<String, double> curtains = {'Master Bedroom': 0.0, 'Living Room': 0.0};
  Map<String, bool> doors = {'Living Room': true, 'Bedroom': true, 'Kitchen': true};
  
  String gasStatus = 'OK';
  String rainStatus = 'Dry';
  bool fanActive = false;
  
  bool cameraAuthorized = true;
  bool keypadEntry = false;
  bool appOverride = false;

  StreamSubscription? _updatesSubscription;

  Future<void> connect() async {
    _updatesSubscription?.cancel();
    _client?.disconnect();

    final String clientId = 'flutter_client_${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient(broker, clientId);
    _client!.port = port;
    _client!.logging(on: false);
    _client!.keepAlivePeriod = 20;
    _client!.onDisconnected = () => print('Disconnected');

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    _client!.connectionMessage = connMessage;

    try {
      final status = await _client!.connect();
      if (status?.state == MqttConnectionState.connected) {
        print('Connected to MQTT Broker');
        _setupSubscriptions();
      } else {
        print('Connection failed: ${status?.state}');
      }
    } catch (e) {
      print('MQTT Connection Exception: $e');
      _client?.disconnect();
    }
  }

  void _setupSubscriptions() {
    _client!.subscribe('home/sensors/#', MqttQos.atMostOnce);
    _client!.subscribe('home/alerts/gas', MqttQos.atLeastOnce);

    _updatesSubscription = _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      if (c.isEmpty) return;
      
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final String topic = c[0].topic;
      final String payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      _handlePayload(topic, payload);
    });
  }

  void _handlePayload(String topic, String payload) {
    // Parse sensor updates
    if (topic == 'home/sensors/gas') {
      gasStatus = payload == '1' ? 'LEAK DETECTED' : 'OK';
    } else if (topic == 'home/sensors/rain') {
      rainStatus = payload == '1' ? 'Raining' : 'Dry';
    } else if (topic == 'home/sensors/fan') {
      fanActive = payload == '1';
    } else if (topic == 'home/alerts/gas' && payload == 'DANGER') {
      _triggerAlert("DANGER: Gas Leak Detected!");
    }
    
    notifyListeners();
  }

  void _triggerAlert(String message) {
    // Implementation for snackbar handled via a global key or context
    scaffoldMessengerKey.currentState?.showSnackBar( // Use the global key
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

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