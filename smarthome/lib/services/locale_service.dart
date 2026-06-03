import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocaleService {
  static final LocaleService _instance = LocaleService._internal();
  factory LocaleService() => _instance;
  LocaleService._internal();

  final _storage = const FlutterSecureStorage();
  final ValueNotifier<Locale> locale = ValueNotifier(const Locale('en'));

  Future<void> load() async {
    final saved = await _storage.read(key: 'app_locale');
    if (saved != null) locale.value = Locale(saved);
  }

  Future<void> setLocale(Locale newLocale) async {
    locale.value = newLocale;
    await _storage.write(key: 'app_locale', value: newLocale.languageCode);
  }

  bool get isTurkish => locale.value.languageCode == 'tr';
}
