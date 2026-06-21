import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const _key = 'isDarkMode';
  bool _isDark = true;

  bool get isDark => _isDark;

  ThemeService() {
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    _isDark = sp.getBool(_key) ?? true;
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_key, _isDark);
    notifyListeners();
  }
}
