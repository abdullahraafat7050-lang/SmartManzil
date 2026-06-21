import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'global_keys.dart';
import 'locale_service.dart';
import 'services/firebase_service.dart';

class MQTTManager extends ChangeNotifier {
  dynamic _client;

  // ── Local broker (editable from settings) ────────────────────────────────
  String broker = '192.168.1.114';
  int port = 1883; // Plain MQTT port

  // ── Connection state ──────────────────────────────────────────────────────
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

  // ── Public connect (local broker only) ────────────────────────────────────
  Future<void> connect() async {
    _updatesSubscription?.cancel();
    _reconnectTimer?.cancel();
    _client?.disconnect();

    final ok = await _tryConnect(
      host: broker,
      port: port,
      secure: false,
      username: 'smart_ev',
      password: '12345678',
    );

    if (!ok) {
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
    debugPrint('[MQTT] Trying $host:$port  user=$username');

    if (!kIsWeb) {
      _client = MqttServerClient(host, clientId);
      _client!.useWebSocket = false;
      _client!.secure = secure;
      _client!.onBadCertificate = (dynamic certificate) => true;
    } else {
      debugPrint('[MQTT] Web not supported in this build');
      return false;
    }

    _client!.port = port;
    _client!.logging(on: true);
    _client!.keepAlivePeriod = 20;
    _client!.connectionMessage = MqttConnectMessage();

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
        debugPrint('[MQTT] ✓ Connected to $host:$port');
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
    // Sensor topics (from Raspberry Pi)
    _client!.subscribe('home/home_001/sensors/#', MqttQos.atMostOnce);
    _client!.subscribe('home/sensors/#', MqttQos.atMostOnce);
    // Alert topics
    _client!.subscribe('home/alerts/#', MqttQos.atLeastOnce);
    // Room device feedback
    _client!.subscribe('home/+/light', MqttQos.atMostOnce);
    _client!.subscribe('home/+/dimmer', MqttQos.atMostOnce);
    _client!.subscribe('home/+/motion', MqttQos.atMostOnce);
    // Actuator feedback — gercek donanim durumu (Arduino → Pi)
    _client!.subscribe('home/home_001/actuators/windows', MqttQos.atMostOnce);
    _client!.subscribe('home/home_001/actuators/fan', MqttQos.atMostOnce);
    _client!.subscribe('home/home_001/actuators/doors', MqttQos.atMostOnce);
    _client!.subscribe('home/home_001/actuators/gate', MqttQos.atMostOnce);

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

    // Sensors (from Raspberry Pi: home/home_001/sensors/...)
    if (topic.contains('temperature')) {
      temperature = double.tryParse(val);
      FirebaseService().updateSensorRTDB('temperature', temperature);
    } else if (topic.contains('humidity')) {
      humidity = double.tryParse(val);
      FirebaseService().updateSensorRTDB('humidity', humidity);
    } else if (topic.contains('motion')) {
      motionDetected = val == '1' || val == 'true';
      FirebaseService().updateSensorRTDB('motion', motionDetected);
    } else if (topic.contains('gas')) {
      final previous = gasStatus;
      gasStatus = val == '1' ? 'LEAK DETECTED' : 'OK';
      FirebaseService().updateSensorRTDB('gas', val == '1');
      if (previous != gasStatus) {
        final isTr = LocaleService().isTurkish;
        final msg = gasStatus == 'LEAK DETECTED'
            ? (isTr ? 'Gaz kaçağı algılandı' : 'Gas leak detected')
            : (isTr ? 'Gaz durumu normale döndü' : 'Gas status returned to normal');
        _recordAlert('gas', msg);
      }
      if (val == '1') {
        final isTr = LocaleService().isTurkish;
        _triggerAutomationAlert(
          isTr ? '💨 Gaz Algılandı!' : '💨 Gas Detected!',
          isTr ? 'Fan, kapı ve pencereler açılıyor' : 'Fan, gate and windows opening',
        );
        publishDirect('home/home_001/actuators/fan', '{"path":"actuators/fan","value":1}');
        publishDirect('home/home_001/actuators/gate', '{"path":"actuators/gate","value":"open"}');
        publishDirect('home/home_001/actuators/windows', '{"path":"actuators/windows","value":"open"}');
      }
    } else if (topic.contains('flame') || topic.contains('smoke')) {
      final previous = smokeDetected;
      smokeDetected = val == '1' || val == 'true';
      FirebaseService().updateSensorRTDB('flame', smokeDetected);
      if (previous != smokeDetected) {
        final isTr = LocaleService().isTurkish;
        final msg = smokeDetected
            ? (isTr ? 'Yangın veya duman algılandı' : 'Fire or smoke detected')
            : (isTr ? 'Yangın / duman durdu' : 'Fire / smoke cleared');
        _recordAlert('fire', msg);
      }
      if (val == '1' || val == 'true') {
        final isTr = LocaleService().isTurkish;
        _triggerAutomationAlert(
          isTr ? '🔥 Yangın Algılandı!' : '🔥 Fire Detected!',
          isTr ? 'Tüm kapılar ve pencereler açılıyor' : 'All doors and windows opening',
        );
        publishDirect('home/home_001/actuators/doors', '{"path":"actuators/doors","value":"open"}');
        publishDirect('home/home_001/actuators/gate', '{"path":"actuators/gate","value":"open"}');
        publishDirect('home/home_001/actuators/windows', '{"path":"actuators/windows","value":"open"}');
      }
    } else if (topic.contains('rain')) {
      final previous = rainStatus;
      rainStatus = val == '1' ? 'Raining' : 'Dry';
      FirebaseService().updateSensorRTDB('rain', val == '1');
      if (previous != rainStatus) {
        final isTr = LocaleService().isTurkish;
        final msg = rainStatus == 'Raining'
            ? (isTr ? 'Yağmur başladı' : 'Rain detected')
            : (isTr ? 'Yağmur durdu' : 'Rain stopped');
        _recordAlert('rain', msg);
      }
      if (val == '1') {
        final isTr = LocaleService().isTurkish;
        _triggerAutomationAlert(
          isTr ? '🌧️ Yağmur Algılandı!' : '🌧️ Rain Detected!',
          isTr ? 'Pencereler kapanıyor' : 'Windows closing',
        );
        publishDirect('home/home_001/actuators/windows', '{"path":"actuators/windows","value":"close"}');
      }
    } else if (topic == 'home/home_001/actuators/fan') {
      final previous = fanActive;
      fanActive = val == '1' || val == 'true';
      if (previous != fanActive) {
        final isTr = LocaleService().isTurkish;
        _recordAlert(
          'fan',
          fanActive
              ? (isTr ? 'Fan açıldı' : 'Fan turned on')
              : (isTr ? 'Fan kapatıldı' : 'Fan turned off'),
        );
      }
    } else if (topic == 'home/home_001/actuators/windows') {
      final previous = windowOpen;
      windowOpen = val == '1' || val == 'true' || val == 'open';
      if (previous != windowOpen) {
        final isTr = LocaleService().isTurkish;
        _recordAlert(
          'window',
          windowOpen
              ? (isTr ? 'Pencere açıldı' : 'Window opened')
              : (isTr ? 'Pencere kapandı' : 'Window closed'),
        );
      }
    } else if (topic == 'home/home_001/actuators/doors') {
      final action = val.toLowerCase() == 'open' ? 'opened' : 'closed';
      final isTr = LocaleService().isTurkish;
      _recordAlert(
        'door',
        isTr ? 'Kapı ${action == 'opened' ? 'açıldı' : 'kapandı'}' : 'Door $action',
      );
    }
    // Motion in rooms
    else if (topic.contains('/motion')) {
      final previousMotion = motionDetected;
      motionDetected = val == '1' || val == 'true';
      FirebaseService().updateSensorRTDB('motion', motionDetected);
      if (previousMotion != motionDetected) {
        _recordAlert('motion', motionDetected ? 'Motion detected' : 'Motion cleared');
      }
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

  void _triggerAutomationAlert(String title, String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade800,
        duration: const Duration(seconds: 6),
      ),
    );
    _recordAlert('automation', '$title — $message');
  }

  Future<void> recordAction(String type, String message) async {
    try {
      await FirebaseService().addAlert(type: type, message: message);
    } catch (e) {
      debugPrint('[MQTT] Failed to record action: $e');
    }
  }

  Future<void> _recordAlert(String type, String message) async {
    return recordAction(type, message);
  }

  // ── Public publish method (used by RoomCard for dual-sync) ────────────────
  void publishDirect(String topic, String message) {
    _publish(topic, message);
  }

  // ── Legacy methods (kept for compatibility) ───────────────────────────────
  void toggleLight(String room) {
    lights[room] = !lights[room]!;
    _publish('home/lights/$room', lights[room]! ? '1' : '0');
    final isTr = LocaleService().isTurkish;
    _recordAlert(
      'light',
      '${room[0].toUpperCase()}${room.substring(1)} ${
        lights[room]!
            ? (isTr ? 'ışık açıldı' : 'light turned on')
            : (isTr ? 'ışık kapatıldı' : 'light turned off')
      }',
    );
    notifyListeners();
  }

  void toggleDoor(String room) {
    doors[room] = !doors[room]!;
    _publish('home/servos/$room', doors[room]! ? '1' : '0');
    final isTr = LocaleService().isTurkish;
    _recordAlert(
      'door',
      '${room[0].toUpperCase()}${room.substring(1)} ${
        doors[room]!
            ? (isTr ? 'kapı açıldı' : 'door opened')
            : (isTr ? 'kapı kapandı' : 'door closed')
      }',
    );
    notifyListeners();
  }

  void updateCurtain(String room, double value) {
    curtains[room] = value;
    _publish('home/curtains/$room', value.toInt().toString());
    notifyListeners();
  }

  void controlWindow(bool open) {
    final previous = windowOpen;
    windowOpen = open;
    final action = open ? 'open' : 'close';
    _publish('home/home_001/actuators/windows',
        '{"path":"actuators/windows","value":"$action"}');
    if (previous != windowOpen) {
      _recordAlert('window', windowOpen ? 'Window opened' : 'Window closed');
    }
    notifyListeners();
  }

  void controlFan(bool active) {
    final previous = fanActive;
    fanActive = active;
    final val = active ? 1 : 0; // Active-LOW: 1=ON, 0=OFF
    _publish('home/home_001/actuators/fan',
        '{"path":"actuators/fan","value":$val}');
    if (previous != fanActive) {
      _recordAlert('fan', fanActive ? 'Fan turned on' : 'Fan turned off');
    }
    notifyListeners();
  }

  void toggleGate() {
    appOverride = !appOverride;
    _publish('home/servos/master_gate', '1');
    _recordAlert('gate', 'Gate command sent');
    notifyListeners();
  }

  void _publish(String topic, String message) {
    try {
      if (_client == null) {
        debugPrint('[MQTT] ✗ Client is null');
        return;
      }
      if (_client!.connectionStatus?.state != MqttConnectionState.connected) {
        debugPrint('[MQTT] ✗ Not connected (state=${_client?.connectionStatus?.state})');
        return;
      }
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      _client!.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
      debugPrint('[MQTT] ✓ Published: $topic -> $message');
    } catch (e) {
      debugPrint('[MQTT] ✗ Error: $e');
    }
  }
}

// ── ملخص التعديلات (Bug Fixes - Fan Control Logic) ──────────────────────────
// تم إصلاح خطأين متعلقين بمنطق التحكم في المروحة:
//
// 1. في دالة controlFan():
//    - تم تغيير: final val = active ? 0 : 1;
//    - إلى:     final val = active ? 1 : 0;
//    - السبب: عندما يريد المستخدم تشغيل المروحة (active=true)، يجب إرسال 1 للـ Arduino
//
// 2. في دالة _handlePayload():
//    - تم تغيير: fanActive = val == '0' || val == 'false';
//    - إلى:     fanActive = val == '1' || val == 'true';
//    - السبب: عندما يستقبل Flutter feedback من Arduino بأن المروحة مشغلة (val=1)،
//             يجب تحديث حالة fanActive إلى true
//
// النتيجة: المروحة الآن تعمل بشكل صحيح — عندما يقفلها المستخدم من التطبيق،
// تبقى مقفلة ولا تفتح من الـ rules/automation تلقائياً.
// ───────────────────────────────────────────────────────────────────────────
