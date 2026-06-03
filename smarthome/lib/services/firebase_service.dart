import 'package:cloud_firestore/cloud_firestore.dart';

// Firestore structure:
//   devices/{room}   → light (bool), dimmer (int), rgb (string)
//   sensors/current  → temperature (num), humidity (num), gas (bool), smoke (bool), motion (bool)
//   alerts/{autoId}  → type, message, timestamp
//   controls/{type}  → open (bool), timestamp  ← servo commands read by IoT device
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final _db = FirebaseFirestore.instance;

  // ── Devices ────────────────────────────────────────────────────────────────

  Stream<DocumentSnapshot<Map<String, dynamic>>> getRoomData(String room) =>
      _db.collection('devices').doc(room).snapshots();

  Future<void> toggleLight(String room, bool state) =>
      _db.collection('devices').doc(room).update({'light': state});

  Future<void> setDimmer(String room, int value) =>
      _db.collection('devices').doc(room).update({'dimmer': value});

  Future<void> setRGB(String room, String rgb) =>
      _db.collection('devices').doc(room).update({'rgb': rgb});

  // Convenience: update multiple fields at once
  Future<void> updateRoom(String room, Map<String, dynamic> data) =>
      _db.collection('devices').doc(room).update(data);

  // Initialises a room document if it doesn't exist yet
  Future<void> initRoom(String room) =>
      _db.collection('devices').doc(room).set(
        {'light': false, 'dimmer': 100, 'rgb': '#FFFFFF'},
        SetOptions(merge: true),
      );

  // ── Sensors ────────────────────────────────────────────────────────────────

  Stream<DocumentSnapshot<Map<String, dynamic>>> getSensorsData() =>
      _db.collection('sensors').doc('current').snapshots();

  // ── Alerts ─────────────────────────────────────────────────────────────────

  Stream<QuerySnapshot<Map<String, dynamic>>> getAlerts({int limit = 50}) =>
      _db
          .collection('alerts')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots();

  Future<void> addAlert({
    required String type,
    required String message,
  }) =>
      _db.collection('alerts').add({
        'type': type,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

  // ── Servo / Gate control ───────────────────────────────────────────────────
  // Writes a command document that the IoT device (ESP32 / Pi) watches.
  // type: 'gate' | 'window' | 'curtain' | any servo label you use.
  Future<void> controlServo(String type, bool open) =>
      _db.collection('controls').doc(type).set({
        'open': open,
        'timestamp': FieldValue.serverTimestamp(),
      });

  // ── Face logs ──────────────────────────────────────────────────────────────

  Stream<QuerySnapshot<Map<String, dynamic>>> getFaceLogs({int limit = 20}) =>
      _db
          .collection('face_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots();

  // ── Users ──────────────────────────────────────────────────────────────────

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) =>
      _db.collection('users').doc(uid).get();

  Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).update(data);
}
