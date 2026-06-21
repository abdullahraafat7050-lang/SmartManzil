import 'package:flutter/material.dart';

class ThemeService extends ChangeNotifier {
  bool _isDark = true;

  bool get isDark => _isDark;

  ThemeService();

  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
  }
}
