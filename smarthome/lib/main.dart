import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'package:smarthome/screens/password_reset_screen.dart';
import 'package:smarthome/screens/room_detail_screen.dart';

void main() {
  runApp(const SmartHomeApp());
}

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});
  

  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      title: 'Smart Home App',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1115),
        primaryColor: const Color(0xFFBFA86D), // Gold
         fontFamily: 'Georgia', // Gives it that "Classy" serif feel
    ),
      initialRoute: '/login', // Start at login
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(), 
        '/settings': (context) => const SettingsScreen(),
        '/password-reset': (context) => const PasswordResetScreen(),
        
        // --- NEW ROUTE FOR ROOM DETAILS ---
        '/room-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
          return RoomDetailScreen(
            roomId: args['id']!,
            roomName: args['name']!,
          );
        },
      },
    );
  }
}