import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'global_keys.dart';
import 'locale_service.dart';
import 'mqtt_manager.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (_) => MQTTManager()..connect(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService().locale,
      builder: (_, locale, __) => MaterialApp(
        title: 'SmartHome Pro',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: scaffoldMessengerKey,
        locale: locale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('tr')],
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF121212),
          cardColor: const Color(0xFF1E1E1E),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFBFA86D),
            surface: Color(0xFF1E1E1E),
          ),
          useMaterial3: true,
        ),
        initialRoute: '/login',
        routes: {
          '/login':    (context) => const LoginScreen(),
          '/home':     (context) => const HomeScreen(),
          '/alerts':   (context) => const AlertsScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}
