import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'mqtt_manager.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mqtt = Provider.of<MQTTManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Home Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Alerts Bar
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildSensorTile('Gas', mqtt.gasStatus, mqtt.gasStatus == 'OK' ? Icons.gas_meter : Icons.warning, mqtt.gasStatus != 'OK'),
                  _buildSensorTile('Rain', mqtt.rainStatus, Icons.umbrella, mqtt.rainStatus == 'Raining'),
                  _buildSensorTile('Fan', mqtt.fanActive ? 'ON' : 'OFF', Icons.cyclone, mqtt.fanActive),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Lighting Control
            const Text('Lighting Control', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: mqtt.lights.keys.map((room) => FilterChip(
                label: Text(room),
                selected: mqtt.lights[room]!,
                onSelected: (_) => mqtt.toggleLight(room),
              )).toList(),
            ),
            const SizedBox(height: 24),

            // 3. Curtain Control
            const Text('Curtains', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...mqtt.curtains.keys.map((room) => Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text(room)),
                    Slider(
                      value: mqtt.curtains[room]!,
                      onChanged: (val) => mqtt.updateCurtain(room, val),
                    ),
                  ],
                ),
              ],
            )),
            const SizedBox(height: 24),

            // 4. Door Security (Vertical List)
            const Text('Security (Doors)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mqtt.doors.length,
              itemBuilder: (context, index) {
                String room = mqtt.doors.keys.elementAt(index);
                bool isLocked = mqtt.doors[room]!;
                return ListTile(
                  title: Text(room),
                  trailing: ElevatedButton(
                    onPressed: () => mqtt.toggleDoor(room),
                    child: Text(isLocked ? 'Unlock' : 'Lock'),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // 5. Main Gate
            Center(
              child: Column(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    icon: const Icon(Icons.sensor_door_outlined),
                    label: const Text('MASTER GATE', style: TextStyle(color: Colors.white)),
                    onPressed: () => _confirmGateAction(context, mqtt),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _statusDot('Camera', mqtt.cameraAuthorized),
                      _statusDot('Keypad', mqtt.keypadEntry),
                      _statusDot('Override', mqtt.appOverride),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorTile(String label, String value, IconData icon, bool alert) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: alert ? Colors.red.withOpacity(0.2) : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: alert ? Colors.red : Colors.blueAccent),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: alert ? Colors.red : Colors.blue),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _statusDot(String label, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: active ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  void _confirmGateAction(BuildContext context, MQTTManager mqtt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Gate Operation'),
        content: const Text('Are you sure you want to trigger the master gate?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              mqtt.toggleGate();
              Navigator.pop(context);
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}