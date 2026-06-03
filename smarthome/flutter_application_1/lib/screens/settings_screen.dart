import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../mqtt_manager.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _brokerCtrl = TextEditingController();

  static const _gold = Color(0xFFBFA86D);
  static const _bg = Color(0xFF121212);
  static const _card = Color(0xFF1E1E1E);

  @override
  void initState() {
    super.initState();
    _brokerCtrl.text =
        Provider.of<MQTTManager>(context, listen: false).broker;
  }

  @override
  void dispose() {
    _brokerCtrl.dispose();
    super.dispose();
  }

  void _reconnect() {
    final mqtt = Provider.of<MQTTManager>(context, listen: false);
    mqtt.broker = _brokerCtrl.text.trim();
    mqtt.connect();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reconnecting to MQTT broker...')),
    );
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              color: Colors.white.withValues(alpha: 0.07), height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── User profile ─────────────────────────────────────────────────
          if (uid != null) ...[
            _label('PROFILE'),
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseService().getUser(uid),
              builder: (ctx, snap) {
                final data = snap.data?.data() ?? {};
                final name = (data['name'] as String?)
                    ?? AuthService().currentUser?.displayName
                    ?? 'N/A';
                final email = (data['email'] as String?)
                    ?? AuthService().currentUser?.email
                    ?? 'N/A';

                return _cardWidget(
                  child: Column(children: [
                    _infoTile(Icons.person_outline, 'Name', name),
                    Divider(
                        color: Colors.white.withValues(alpha: 0.07),
                        height: 1),
                    _infoTile(Icons.email_outlined, 'Email', email),
                  ]),
                );
              },
            ),
            const SizedBox(height: 24),
          ],

          // ── MQTT broker ───────────────────────────────────────────────────
          _label('MQTT BROKER'),
          _cardWidget(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _brokerCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Broker IP Address',
                      labelStyle:
                          const TextStyle(color: Colors.white54),
                      hintText: '192.168.1.100',
                      hintStyle:
                          const TextStyle(color: Colors.white24),
                      prefixIcon: const Icon(Icons.router_outlined,
                          color: _gold),
                      enabledBorder: const UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white12)),
                      focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: _gold)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Consumer<MQTTManager>(
                    builder: (_, mqtt, __) => Row(children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: mqtt.isConnected
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        mqtt.isConnected
                            ? 'Connected to ${mqtt.broker}'
                            : 'Disconnected',
                        style: TextStyle(
                          color: mqtt.isConnected
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _reconnect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Reconnect',
                          style: TextStyle(
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Account ───────────────────────────────────────────────────────
          _label('ACCOUNT'),
          _cardWidget(
            child: ListTile(
              leading: const Icon(Icons.logout,
                  color: Colors.redAccent),
              title: const Text('Log Out',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w500)),
              onTap: _logout,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: _gold,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3)),
      );

  Widget _cardWidget({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: child,
      );

  Widget _infoTile(IconData icon, String label, String value) =>
      ListTile(
        leading: Icon(icon, color: _gold, size: 20),
        title: Text(label,
            style: const TextStyle(
                color: Colors.white54, fontSize: 12)),
        subtitle: Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 14)),
      );
}
