import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'mqtt_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _brokerController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final mqttManager = Provider.of<MQTTManager>(context, listen: false);
    _brokerController.text = mqttManager.broker;
    _portController.text = mqttManager.port.toString();
  }

  void _saveSettings() {
    final mqttManager = Provider.of<MQTTManager>(context, listen: false);
    mqttManager.broker = _brokerController.text;
    mqttManager.port = int.tryParse(_portController.text) ?? 1883;
    // Reconnect to MQTT with new settings
    mqttManager.connect();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _brokerController, decoration: const InputDecoration(labelText: 'MQTT Broker IP')),
            TextField(controller: _portController, decoration: const InputDecoration(labelText: 'MQTT Port')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveSettings, child: const Text('Save Settings')),
          ],
        ),
      ),
    );
  }
}