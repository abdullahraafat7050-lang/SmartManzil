import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

// Firestore operations for SmartHome Pro.
// Used alongside MQTTManager for dual-sync (Firebase = cloud, MQTT = local).
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final _db = FirebaseFirestore.instance;

  // ── devices/{room} ──────────────────────────────────────────────────────────

  Stream<DocumentSnapshot<Map<String, dynamic>>> getRoomData(String room) =>
      _db.collection('devices').doc(room).snapshots();

  Future<void> toggleLight(String room, bool state) =>
      _db.collection('devices').doc(room).update({'light': state});

  Future<void> setDimmer(String room, int value) =>
      _db.collection('devices').doc(room).update({'dimmer': value});

  Future<void> setRGB(String room, String rgb) =>
      _db.collection('devices').doc(room).update({'rgb': rgb});

  Future<void> initRoom(String room) => _db.collection('devices').doc(room).set(
        {'light': false, 'dimmer': 100, 'rgb': '#FFFFFF'},
        SetOptions(merge: true),
      );

  // ── sensors/current (Firestore) ──────────────────────────────────────────────

  Stream<DocumentSnapshot<Map<String, dynamic>>> getSensorsData() =>
      _db.collection('sensors').doc('current').snapshots();

  Future<void> updateSensor(Map<String, dynamic> data) =>
      _db.collection('sensors').doc('current').set(
            data,
            SetOptions(merge: true),
          );

  // ── sensors (Realtime Database) ───────────────────────────────────────────

  Stream<DatabaseEvent> getSensorsRTDB() =>
      FirebaseDatabase.instance.ref('sensors').onValue;

  Future<void> updateSensorRTDB(String key, dynamic value) =>
      FirebaseDatabase.instance.ref('sensors/$key').set(value);

  // ── alerts/{autoId} ─────────────────────────────────────────────────────────

  Stream<QuerySnapshot<Map<String, dynamic>>> getAlerts({int limit = 50}) =>
      _db
          .collection('alerts')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots();

  Future<void> addAlert({required String type, required String message}) =>
      _db.collection('alerts').add({
        'type': type,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

  // ── controls/{type} — servo commands read by IoT device ────────────────────

  Future<void> controlServo(String type, bool open) =>
      _db.collection('controls').doc(type).set({
        'open': open,
        'timestamp': FieldValue.serverTimestamp(),
      });

  // ── users/{userId} ──────────────────────────────────────────────────────────

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) =>
      _db.collection('users').doc(uid).get();

  Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).update(data);

  // ── face_logs/{autoId} ──────────────────────────────────────────────────────

  Stream<QuerySnapshot<Map<String, dynamic>>> getFaceLogs({int limit = 20}) =>
      _db
          .collection('face_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots();
}
