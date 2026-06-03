import 'package:flutter/material.dart';
import 'package:smarthome/models/device.dart';
import 'package:smarthome/models/room.dart';
import 'package:smarthome/services/device_service.dart';
import 'package:smarthome/widgets/device_tile.dart';

class RoomDetailScreen extends StatefulWidget {
  final String roomId;
  final String roomName;

  const RoomDetailScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final _deviceService = DeviceService();

  Room? _room;
  bool _isLoading = true;

  static const _gold = Color(0xFFBFA86D);
  static const _bg = Color(0xFF0D0D0D);

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _room = _deviceService.getRoomById(widget.roomId);
        _isLoading = false;
      });
    });
  }

  void _toggle(Device device) async {
    setState(() => device.state = !device.state);
    await _deviceService.toggleDevice(widget.roomId, device.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.roomName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: Colors.white.withOpacity(0.07), height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : _room == null
              ? const Center(
                  child: Text(
                    'Room not found',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : _buildGrid(),
    );
  }

  Widget _buildGrid() {
    final devices = _room!.devices;
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.1,
      ),
      itemCount: devices.length,
      itemBuilder: (_, i) => DeviceTile(
        device: devices[i],
        onTap: () => _toggle(devices[i]),
      ),
    );
  }
}
