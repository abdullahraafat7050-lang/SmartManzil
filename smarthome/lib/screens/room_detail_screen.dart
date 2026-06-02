// lib/screens/room_detail_screen.dart

import 'package:flutter/material.dart';
// Ensure this import is correct based on your file structure
import 'package:smarthome/services/home_service.dart'; 

class RoomDetailScreen extends StatefulWidget {
  final String roomId;
  final String roomName;

  const RoomDetailScreen({super.key, required this.roomId, required this.roomName});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  // 💡 FIX: Accessing the HomeService Singleton correctly
  final HomeService _homeService = HomeService(); 
  
  Map<String, dynamic>? _roomData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoomData();
  }

  // Reloads room data from the service
  void _loadRoomData() {
    setState(() {
      _isLoading = true;
    });
    // Simulate API call delay for realism
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return; // Safety check
      setState(() {
        _roomData = _homeService.getRoomById(widget.roomId);
        _isLoading = false;
      });
    });
  }

  // Toggles the state of simple devices/sensors (like light, gate, rain)
  void _toggleDeviceState(String deviceId) async {
    // Optimistic UI update (optional, but faster user experience)
    setState(() {
      final deviceIndex = (_roomData!['devices'] as List).indexWhere((d) => d['id'] == deviceId);
      if (deviceIndex != -1) {
        final device = _roomData!['devices'][deviceIndex];
        
        // Toggle the relevant boolean property
        if (device.containsKey('state')) {
          device['state'] = !device['state'];
        } else if (device.containsKey('isRaining')) {
          device['isRaining'] = !device['isRaining'];
        }
      }
    });

    // Send update to mock backend
    await Future.delayed(const Duration(milliseconds: 100));
    _homeService.toggleDeviceState(widget.roomId, deviceId);

    // Reload data (to ensure UI syncs if the optimistic update failed or 
    // to handle asynchronous state changes later)
    // _loadRoomData(); 
  }

  // ==========================================================
  // HELPER METHODS
  // ==========================================================

  /// Helper method to determine the icon for a device/sensor
  IconData _getDeviceIcon(String type) {
    switch (type) {
      case 'light':
        return Icons.lightbulb_outline;
      case 'curtain':
        return Icons.vertical_split;
      case 'tv':
        return Icons.tv;
      case 'appliance':
        return Icons.local_dining;
      case 'fan':
        return Icons.mode_fan_off_outlined;
      case 'gate':
        return Icons.sensor_door;
      case 'heat': // 🔥 Temperature Sensor Icon
        return Icons.thermostat_outlined;
      case 'rain': // 🌧️ Rain Sensor Icon
        return Icons.cloudy_snowing;
      default:
        return Icons.device_unknown;
    }
  }

  /// Helper method to display sensor status or device state
  String _getStatusText(Map<String, dynamic> device) {
    if (device['type'] == 'heat') {
      // Safely access value and unit
      final value = device['value'] ?? 0.0;
      final unit = device['unit'] ?? '°C';
      return "${value.toStringAsFixed(1)} $unit";
    }
    if (device['type'] == 'rain') {
      return device['isRaining'] == true ? 'Raining' : 'Clear';
    }
    // For standard devices
    return device['state'] == true ? 'ON' : 'OFF';
  }

  /// Determines if the device card should appear active
  bool _isDeviceActive(Map<String, dynamic> device) {
    if (device['type'] == 'heat') {
      // Temperature is always "active" as it's always reading data
      return true; 
    }
    if (device['type'] == 'rain') {
      return device['isRaining'] == true;
    }
    return device['state'] == true;
  }
  
  // ==========================================================
  // BUILD METHOD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.roomName} Details'),
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF7F9FC), // Light background for contrast
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _roomData == null
              ? const Center(child: Text('Room data not found. Check Room ID.'))
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    Text(
                      'Devices & Sensors',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Display the list of devices and sensors
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, 
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        childAspectRatio: 1.3, // Slightly taller cards for better look
                      ),
                      itemCount: (_roomData!['devices'] as List).length,
                      itemBuilder: (context, index) {
                        final device = _roomData!['devices']![index] as Map<String, dynamic>;
                        final isActive = _isDeviceActive(device);
                        
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          color: isActive ? Colors.indigo.shade50 : Colors.white,
                          child: InkWell(
                            // Only allow tap interaction if the device has a state property to toggle
                            onTap: device.containsKey('state') || device.containsKey('isRaining') 
                                ? () => _toggleDeviceState(device['id']) 
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // ICON
                                  Icon(
                                    _getDeviceIcon(device['type']),
                                    size: 36,
                                    color: isActive ? Colors.indigo.shade600 : Colors.grey.shade500,
                                  ),
                                  
                                  const SizedBox(height: 8),

                                  // NAME
                                  Text(
                                    device['name'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  
                                  // STATUS / VALUE
                                  Text(
                                    _getStatusText(device),
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isActive ? Colors.green.shade700 : Colors.grey.shade500,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
    );
  }
}