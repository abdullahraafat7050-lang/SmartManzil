import 'package:flutter/material.dart';

class LocaleService {
  static final LocaleService _instance = LocaleService._internal();
  factory LocaleService() => _instance;
  LocaleService._internal();

  final ValueNotifier<Locale> locale = ValueNotifier(const Locale('en'));

  bool get isTurkish => locale.value.languageCode == 'tr';

  void toggle() => locale.value =
      isTurkish ? const Locale('en') : const Locale('tr');
}

// Context-based translation helper.
// Usage: final s = S.of(context); then s.email, s.signIn, etc.
class S {
  final bool _tr;
  const S._(this._tr);

  factory S.of(BuildContext context) =>
      S._(Localizations.localeOf(context).languageCode == 'tr');

  // ── Login ──────────────────────────────────────────────────────────────────
  String get email => _tr ? 'E-posta' : 'Email';
  String get password => _tr ? 'Şifre' : 'Password';
  String get signIn => _tr ? 'Giriş Yap' : 'Log In';
  String get forgotPassword => _tr ? 'Şifremi unuttum?' : 'Forgot password?';
  String get welcomeBack => _tr ? 'Tekrar hoş geldiniz' : 'Welcome back';
  String get signInToContinue =>
      _tr ? 'Devam etmek için giriş yapın' : 'Sign in to continue';
  String get emailRequired => _tr ? 'E-posta gerekli' : 'Email is required';
  String get passwordRequired =>
      _tr ? 'Şifre gerekli' : 'Password is required';
  String get tagline =>
      _tr ? 'Evinizi her yerden kontrol edin' : 'Control your home, anywhere';
  String get continueWithGoogle =>
      _tr ? 'Google ile kayıt ol' : 'Sign Up with Google';
  String get emailDomainError =>
      _tr ? 'Sadece @admin.com veya @gmail.com e-postaları kabul edilir'
          : 'Only @admin.com or @gmail.com emails are allowed';
  String get or => _tr ? 'veya' : 'or';
  String get resetEmailSent =>
      _tr ? 'Şifre sıfırlama e-postası gönderildi.' : 'Password reset email sent.';
  String get enterEmailFirst =>
      _tr ? 'Önce e-postanızı girin.' : 'Enter your email first.';
  String get connectionError =>
      _tr ? 'Bağlantı hatası. Tekrar deneyin.' : 'Connection error. Please try again.';
  String get googleFailed =>
      _tr ? 'Google girişi başarısız.' : 'Google sign-in failed.';

  // ── Home ───────────────────────────────────────────────────────────────────
  String goodEvening(String name) =>
      _tr ? 'İyi akşamlar, $name' : 'Good Evening, $name';
  String get goodMorning => _tr ? 'Günaydın' : 'Good Morning';
  String get goodNight => _tr ? 'İyi Geceler' : 'Good Night';
  String get masterOff => _tr ? 'Tümünü Kapat' : 'Master Off';
  String get gate => _tr ? 'Kapı' : 'Gate';
  String get mqttOnline => _tr ? 'MQTT bağlı' : 'MQTT online';
  String get mqttOffline => _tr ? 'MQTT bağlı değil' : 'MQTT offline';
  String get logout => _tr ? 'Çıkış Yap' : 'Log out';

  // ── Rooms ──────────────────────────────────────────────────────────────────
  String roomLabel(String key) {
    switch (key) {
      case 'bedroom':
        return _tr ? 'Yatak Odası' : 'Bedroom';
      case 'living':
        return _tr ? 'Salon' : 'Living';
      case 'kitchen':
        return _tr ? 'Mutfak' : 'Kitchen';
      case 'garden':
        return _tr ? 'Bahçe' : 'Garden';
      default:
        return key;
    }
  }

  // ── Room card ──────────────────────────────────────────────────────────────
  String get light => _tr ? 'Işık' : 'Light';
  String get dimmer => _tr ? 'Parlaklık' : 'Dimmer';
  String get color => _tr ? 'Renk' : 'Color';

  // ── Sensor panel ───────────────────────────────────────────────────────────
  String get temp => _tr ? 'Sıcaklık' : 'Temp';
  String get humidity => _tr ? 'Nem' : 'Humidity';
  String get allClear => _tr ? 'Temiz' : 'All Clear';
  String get motion => _tr ? 'Hareket' : 'Motion';
  String get smoke => _tr ? 'Duman' : 'Smoke';
  String get rain => _tr ? 'Yağmur' : 'Rain';
  String get window => _tr ? 'Pencere' : 'Window';
  String get fan    => _tr ? 'Fan'     : 'Fan';

  // ── Alerts ─────────────────────────────────────────────────────────────────
  String get alertsTitle => _tr ? 'Uyarılar' : 'Alerts';
  String get noAlerts => _tr ? 'Yeni uyarı yok' : 'No alerts';

  // ── Settings ───────────────────────────────────────────────────────────────
  String get settingsTitle => _tr ? 'Ayarlar' : 'Settings';
  String get profileSection => _tr ? 'PROFİL' : 'PROFILE';
  String get nameLabel => _tr ? 'Ad' : 'Name';
  String get accountSection => _tr ? 'HESAP' : 'ACCOUNT';
  String get logOut => _tr ? 'Çıkış Yap' : 'Log Out';
  String get brokerIp =>
      _tr ? 'Broker IP Adresi' : 'Broker IP Address';
  String get reconnect => _tr ? 'Yeniden Bağlan' : 'Reconnect';
  String get reconnecting =>
      _tr ? 'Yeniden bağlanılıyor...' : 'Reconnecting to MQTT broker...';
  String get languageSection => _tr ? 'DİL' : 'LANGUAGE';
  String get language => _tr ? 'Dil' : 'Language';
  String get disconnected => _tr ? 'Bağlı değil' : 'Disconnected';
  String connectedTo(String broker) =>
      _tr ? '$broker\'e bağlı' : 'Connected to $broker';
}
