// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'SmartManzil';

  @override
  String get appVersion => 'SmartManzil v1.0';

  @override
  String get appTagline => 'Evinizi her yerden kontrol edin';

  @override
  String get welcomeBack => 'Tekrar hoş geldiniz';

  @override
  String get signInToContinue => 'Devam etmek için giriş yapın';

  @override
  String get username => 'Kullanıcı Adı';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get usernameRequired => 'Kullanıcı adı gerekli';

  @override
  String get emailRequired => 'E-posta gerekli';

  @override
  String get passwordRequired => 'Şifre gerekli';

  @override
  String get forgotPassword => 'Şifremi unuttum?';

  @override
  String get signIn => 'Giriş Yap';

  @override
  String get signInWithGoogle => 'Google ile devam et';

  @override
  String get orDivider => 'veya';

  @override
  String get resetEmailSent => 'Şifre sıfırlama e-postası gönderildi.';

  @override
  String goodEvening(String name) {
    return 'İyi akşamlar, $name';
  }

  @override
  String get masterControl => 'Ana kontrol';

  @override
  String get mainLight => 'Ana Işık';

  @override
  String get curtain => 'Perde';

  @override
  String get curtainOpen => 'Açık';

  @override
  String get curtainClosed => 'Kapalı';

  @override
  String get masterOff => 'Tümünü Kapat';

  @override
  String get goodMorning => 'Günaydın';

  @override
  String get goodNight => 'İyi Geceler';

  @override
  String get gate => 'Kapı';

  @override
  String get logout => 'Çıkış Yap';

  @override
  String get areaBedroom => 'Yatak Odası';

  @override
  String get areaBathroom => 'Banyo';

  @override
  String get areaLivingRoom => 'Oturma Odası';

  @override
  String get areaKitchen => 'Mutfak';

  @override
  String get areaGarden => 'Bahçe';

  @override
  String get areaHall => 'Koridor';

  @override
  String get sensorsTitle => 'Sensörler';

  @override
  String get temperatureLabel => 'Sıcaklık';

  @override
  String get humidityLabel => 'Nem';

  @override
  String get gasAlert => 'Gaz!';

  @override
  String get smokeAlert => 'Duman!';

  @override
  String get motionLabel => 'Hareket';

  @override
  String get allClear => 'Temiz';

  @override
  String get lightLabel => 'Işık';

  @override
  String get dimmerLabel => 'Parlaklık';

  @override
  String get colorLabel => 'Renk';

  @override
  String get alertsTitle => 'Uyarılar';

  @override
  String get noAlerts => 'Yeni uyarı yok';

  @override
  String get clearAlerts => 'Tümünü temizle';

  @override
  String get securitySettings => 'Güvenlik & Ayarlar';

  @override
  String get sectionIdentity => 'KİMLİK';

  @override
  String get sectionSecurity => 'GÜVENLİK ERİŞİMİ';

  @override
  String get sectionSystem => 'SİSTEM';

  @override
  String get registeredSmsNumber => 'Kayıtlı SMS Numarası';

  @override
  String get updateAccessKey => 'Erişim Anahtarını Güncelle';

  @override
  String get currentPassword => 'Mevcut Şifre';

  @override
  String get newPassword => 'Yeni Şifre';

  @override
  String get confirmNew => 'Yeni Şifreyi Onayla';

  @override
  String get confirmChange => 'Değişikliği Onayla';

  @override
  String get alertPreferences => 'Uyarı Tercihleri';

  @override
  String get aboutApp => 'Lumina v1.0 Hakkında';

  @override
  String get updateSmsTarget => 'SMS Hedefini Güncelle';

  @override
  String get cancel => 'İptal';

  @override
  String get save => 'Kaydet';

  @override
  String get minCharsError => 'En az 8 karakter gerekli.';

  @override
  String get enterNumberError => 'Geçerli bir numara girin.';

  @override
  String get numberSaved => 'Numara güvenle kaydedildi.';

  @override
  String get errorSavingNumber => 'Numara kaydedilirken hata oluştu.';

  @override
  String get connectionError => 'Bağlantı hatası.';

  @override
  String get language => 'Dil';

  @override
  String get identifyAccount => 'Hesabı\nDoğrula';

  @override
  String get secureVerification => 'Güvenli\nDoğrulama';

  @override
  String get newCredentials => 'Yeni\nKimlik Bilgileri';

  @override
  String get sixDigitCode => '6 Haneli Kod';

  @override
  String get confirmPassword => 'Şifreyi Onayla';

  @override
  String get requestSmsCode => 'SMS Kodu İste';

  @override
  String get verifyAndContinue => 'Doğrula ve Devam Et';

  @override
  String get resetPassword => 'Şifreyi Sıfırla';

  @override
  String get cancelRequest => 'İsteği İptal Et';

  @override
  String get pleaseEnterUsername => 'Lütfen kullanıcı adınızı girin.';

  @override
  String get invalidCode => 'Geçersiz kod. Lütfen tekrar deneyin.';

  @override
  String get codeAccepted => 'Kod kabul edildi. Yeni şifrenizi oluşturun.';

  @override
  String get passwordsDoNotMatch => 'Şifreler eşleşmiyor.';

  @override
  String get networkError => 'Ağ hatası. Lütfen tekrar deneyin.';

  @override
  String get twoFactorTitle => 'İki Faktörlü Doğrulama';

  @override
  String twoFactorBody(String username) {
    return '$username için kayıtlı numaraya 6 haneli doğrulama kodu gönderildi.';
  }

  @override
  String get enterSixDigitCode => '6 haneli kodu girin.';

  @override
  String get verify => 'Doğrula';

  @override
  String get resendCode => 'Kodu yeniden gönder';

  @override
  String resendCodeCooldown(int seconds) {
    return 'Yeniden gönder ($seconds sn)';
  }

  @override
  String get backToLogin => 'Girişe Dön';

  @override
  String get roomNotFound => 'Oda bulunamadı';

  @override
  String get deviceOn => 'AÇIK';

  @override
  String get deviceOff => 'KAPALI';

  @override
  String get raining => 'Yağmur var';

  @override
  String get clear => 'Açık hava';

  @override
  String get cameras => 'Cameras';

  @override
  String get noCamerasFound => 'No cameras available';

  @override
  String get errorLoadingCameras => 'Error loading cameras';
}
