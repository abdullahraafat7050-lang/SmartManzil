import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smarthome/firebase_options.dart';
import 'package:smarthome/l10n/app_localizations.dart';
import 'package:smarthome/services/locale_service.dart';
import 'screens/alerts_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'package:smarthome/screens/password_reset_screen.dart';
import 'package:smarthome/screens/room_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocaleService().load();
  runApp(const SmartHomeApp());
}

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService().locale,
      builder: (_, locale, __) => MaterialApp(
        title: 'SmartManzil',
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F1115),
          primaryColor: const Color(0xFFBFA86D),
          fontFamily: 'Georgia',
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/alerts': (context) => const AlertsScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/password-reset': (context) => const PasswordResetScreen(),
          '/room-detail': (context) {
            final args = ModalRoute.of(context)!.settings.arguments
                as Map<String, String>;
            return RoomDetailScreen(
              roomId: args['id']!,
              roomName: args['name']!,
            );
          },
        },
      ),
    );
  }
}
