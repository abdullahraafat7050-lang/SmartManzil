import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:smarthome/services/home_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 1. SERVICE INITIALIZATION
  final HomeService _homeService = HomeService();
  bool _isLoading = true;

  String get userName =>
      ModalRoute.of(context)?.settings.arguments as String? ?? 'Guest';

  final List<String> areas = [
    "Bedroom",
    "Bathroom",
    "Living Room",
    "Kitchen",
    "Garden",
    "Hall"
  ];
  final List<IconData> areaIcons = [
    Icons.bedroom_child,
    Icons.bathtub,
    Icons.weekend,
    Icons.kitchen,
    Icons.park,
    Icons.home,
  ];

  int selectedArea = 0;

  // 2. STATE VARIABLES
  bool _isListening = false;
  List<bool> lcdOn = List.filled(6, false);
  List<double> lcdValue = List.filled(6, 50.0);
  List<bool> curtainOpen = List.filled(6, false);
  bool gateOpen = false;

  final Map<String, bool> _deviceLoading = {};

  late stt.SpeechToText speech;
  String voiceCommand = "";

  // Theme/colors
  final Color _bgColor = const Color.fromARGB(255, 0, 0, 0);
  final Color _cardColor = const Color(0xFF131418);
  final Color _muted = Colors.grey;
  final Color _gold = const Color(0xFFBFA86D);
  final double _cornerRadius = 14.0;

  // 3. ASYNCHRONOUS DATA FETCHING
  void _fetchInitialStatus() async {
    try {
      final Map<String, dynamic> status = await _homeService.getHomeStatus();
      setState(() {
        for (int i = 0; i < areas.length; i++) {
          String area = areas[i];
          if (status.containsKey(area)) {
            lcdOn[i] = status[area]['lightOn'] ?? false;
            lcdValue[i] = (status[area]['lightValue'] as num?)?.toDouble() ?? 50.0;
            curtainOpen[i] = status[area]['curtainOpen'] ?? false;
          }
        }
        gateOpen = status['gateOpen'] ?? false;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching initial home status: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchInitialStatus();
    speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    if (speech.isListening) speech.stop();
    super.dispose();
  }

  String _deviceKey(String area, String device) => '$area:$device';

  void _sendDeviceCommand(String area, String device, dynamic value) async {
    if (_isLoading) return;
    final String key = _deviceKey(area, device);
    if (_deviceLoading[key] == true) return;

    setState(() => _deviceLoading[key] = true);
    final int index = areas.indexOf(area);

    try {
      final Map<String, dynamic> result = await _homeService.setDeviceState(area, device, value);
      if (result['success'] == true) {
        setState(() {
          if (device == 'lightOn' && index >= 0) {
            lcdOn[index] = value as bool;
          } else if (device == 'lightValue' && index >= 0) {
            lcdValue[index] = (value as num).toDouble();
          } else if (device == 'curtainOpen' && index >= 0) {
            curtainOpen[index] = value as bool;
          } else if (device == 'gateOpen') {
            gateOpen = value as bool;
          }
        });
      }
    } catch (e) {
      debugPrint("Network/API error: $e");
    } finally {
      setState(() => _deviceLoading[key] = false);
    }
  }

  void _toggleAllLightsForRoom(String area, bool value) {
    HapticFeedback.lightImpact();
    _sendDeviceCommand(area, 'lightOn', value);
  }

  void _masterOffAllLights() {
    HapticFeedback.mediumImpact();
    for (final area in areas) {
      _sendDeviceCommand(area, 'lightOn', false);
    }
  }

  void _closeAllCurtains() {
    HapticFeedback.mediumImpact();
    for (final area in areas) {
      _sendDeviceCommand(area, 'curtainOpen', false);
    }
  }

  void listenVoiceCommand() async {
    try {
      if (speech.isListening) {
        await speech.stop();
        setState(() => _isListening = false);
        return;
      }
      bool available = await speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        speech.listen(onResult: (result) {
          setState(() => voiceCommand = result.recognizedWords);
          final String cmd = voiceCommand.toLowerCase();
          if (cmd.contains('turn on all lights')) {
            for (var a in areas) _sendDeviceCommand(a, 'lightOn', true);
          } else if (cmd.contains('turn off all lights')) {
            for (var a in areas) _sendDeviceCommand(a, 'lightOn', false);
          }
        });
      }
    } catch (e) {
      setState(() => _isListening = false);
    }
  }

  void activateScene(String scene) {
    bool isMorning = scene == "Good Morning";
    setState(() {
      for (int i = 0; i < areas.length; i++) {
        lcdOn[i] = isMorning;
        curtainOpen[i] = isMorning;
      }
    });

    for (int i = 0; i < areas.length; i++) {
      _sendDeviceCommand(areas[i], 'lightOn', isMorning);
      _sendDeviceCommand(areas[i], 'curtainOpen', isMorning);
    }
  }

  Widget _brightnessGradientBar() {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [_gold.withOpacity(0.95), Colors.white12, Colors.grey.shade800],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildRoomControls(int idx) {
    final area = areas[idx];
    final bool isHall = area.toLowerCase() == 'hall';
    final bool isBedroom = area.toLowerCase() == 'bedroom';

    return Card(
      color: _cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cornerRadius)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(areaIcons[idx], color: _gold, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(area, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                    Text("Master control", style: TextStyle(color: _muted.withOpacity(0.8), fontSize: 12)),
                  ],
                ),
                const Spacer(),
                Switch(
                  activeColor: _gold,
                  value: lcdOn[idx],
                  onChanged: (val) => _toggleAllLightsForRoom(area, val),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(Icons.lightbulb, color: lcdOn[idx] ? _gold : Colors.grey.shade600),
                const SizedBox(width: 8),
                const Text("Main Light", style: TextStyle(color: Colors.white, fontSize: 16)),
                const Spacer(),
                SizedBox(
                  width: 150,
                  child: Slider(
                    value: lcdValue[idx],
                    min: 0, max: 100,
                    onChanged: (val) => setState(() => lcdValue[idx] = val),
                    onChangeEnd: (val) => _sendDeviceCommand(area, 'lightValue', val),
                    activeColor: _gold,
                  ),
                )
              ],
            ),
            if (isBedroom || isHall) ...[
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("Curtain", style: TextStyle(color: Colors.white)),
                  const Spacer(),
                  Switch(
                    value: curtainOpen[idx],
                    activeColor: _gold,
                    onChanged: (val) => _sendDeviceCommand(area, 'curtainOpen', val),
                  ),
                  Text(curtainOpen[idx] ? "Open" : "Closed", style: TextStyle(color: _muted, fontSize: 12)),
                ],
              ),
            ],
            if (isHall) ...[
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.black),
                  onPressed: _masterOffAllLights,
                  child: const Text("Master Off"),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: Center(child: CircularProgressIndicator(color: _gold)),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Good Evening, $userName", 
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: areas.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final bool selected = i == selectedArea;
                    return GestureDetector(
                      onTap: () => setState(() => selectedArea = i),
                      child: Container(
                        width: 140,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected ? _gold.withOpacity(0.12) : _cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selected ? _gold : Colors.transparent),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(areaIcons[i], color: selected ? _gold : Colors.white70),
                            const SizedBox(height: 4),
                            Text(areas[i], style: TextStyle(color: selected ? Colors.white : Colors.white70)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildRoomControls(selectedArea),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => activateScene('Good Morning'),
                          icon: Icon(Icons.wb_sunny, color: _gold),
                          label: const Text('Good Morning', style: TextStyle(color: Colors.white70)),
                        ),
                        const SizedBox(width: 12),
                        TextButton.icon(
                          onPressed: () => activateScene('Good Night'),
                          icon: Icon(Icons.nightlight_round, color: _gold),
                          label: const Text('Good Night', style: TextStyle(color: Colors.white70)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Card(
                      color: _cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cornerRadius)),
                      child: ListTile(
                        leading: const Icon(Icons.meeting_room, color: Colors.amber),
                        title: const Text("Gate", style: TextStyle(color: Colors.white)),
                        trailing: Switch(
                          value: gateOpen,
                          activeColor: _gold,
                          onChanged: (val) => _sendDeviceCommand('global', 'gateOpen', val),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}