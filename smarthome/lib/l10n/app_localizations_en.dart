// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'SmartManzil';

  @override
  String get appVersion => 'SmartManzil v1.0';

  @override
  String get appTagline => 'Control your home, anywhere';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get username => 'Username';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get usernameRequired => 'Username is required';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get signIn => 'Sign In';

  @override
  String get signInWithGoogle => 'Continue with Google';

  @override
  String get orDivider => 'or';

  @override
  String get resetEmailSent => 'Password reset email sent.';

  @override
  String goodEvening(String name) {
    return 'Good Evening, $name';
  }

  @override
  String get masterControl => 'Master control';

  @override
  String get mainLight => 'Main Light';

  @override
  String get curtain => 'Curtain';

  @override
  String get curtainOpen => 'Open';

  @override
  String get curtainClosed => 'Closed';

  @override
  String get masterOff => 'Master Off';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodNight => 'Good Night';

  @override
  String get gate => 'Gate';

  @override
  String get logout => 'Log out';

  @override
  String get areaBedroom => 'Bedroom';

  @override
  String get areaBathroom => 'Bathroom';

  @override
  String get areaLivingRoom => 'Living Room';

  @override
  String get areaKitchen => 'Kitchen';

  @override
  String get areaGarden => 'Garden';

  @override
  String get areaHall => 'Hall';

  @override
  String get sensorsTitle => 'Sensors';

  @override
  String get temperatureLabel => 'Temp';

  @override
  String get humidityLabel => 'Humidity';

  @override
  String get gasAlert => 'Gas!';

  @override
  String get smokeAlert => 'Smoke!';

  @override
  String get motionLabel => 'Motion';

  @override
  String get allClear => 'All Clear';

  @override
  String get lightLabel => 'Light';

  @override
  String get dimmerLabel => 'Dimmer';

  @override
  String get colorLabel => 'Color';

  @override
  String get alertsTitle => 'Alerts';

  @override
  String get noAlerts => 'No new alerts';

  @override
  String get clearAlerts => 'Clear all';

  @override
  String get securitySettings => 'Security & Settings';

  @override
  String get sectionIdentity => 'IDENTITY';

  @override
  String get sectionSecurity => 'SECURITY ACCESS';

  @override
  String get sectionSystem => 'SYSTEM';

  @override
  String get registeredSmsNumber => 'Registered SMS Number';

  @override
  String get updateAccessKey => 'Update Access Key';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNew => 'Confirm New';

  @override
  String get confirmChange => 'Confirm Change';

  @override
  String get alertPreferences => 'Alert Preferences';

  @override
  String get aboutApp => 'About Lumina v1.0';

  @override
  String get updateSmsTarget => 'Update SMS Target';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get minCharsError => 'Minimum 8 characters required.';

  @override
  String get enterNumberError => 'Enter a valid number.';

  @override
  String get numberSaved => 'Number stored securely.';

  @override
  String get errorSavingNumber => 'Error saving number.';

  @override
  String get connectionError => 'Connection error.';

  @override
  String get language => 'Language';

  @override
  String get identifyAccount => 'Identify\nAccount';

  @override
  String get secureVerification => 'Secure\nVerification';

  @override
  String get newCredentials => 'New\nCredentials';

  @override
  String get sixDigitCode => '6-Digit Code';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get requestSmsCode => 'Request SMS Code';

  @override
  String get verifyAndContinue => 'Verify & Continue';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get cancelRequest => 'Cancel Request';

  @override
  String get pleaseEnterUsername => 'Please enter your username.';

  @override
  String get invalidCode => 'Invalid code. Please try again.';

  @override
  String get codeAccepted => 'Code accepted. Create your new password.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get networkError => 'Network error. Please try again.';

  @override
  String get twoFactorTitle => 'Two-Factor Verification';

  @override
  String twoFactorBody(String username) {
    return 'A 6-digit verification code was sent to the contact on file for $username.';
  }

  @override
  String get enterSixDigitCode => 'Enter the 6-digit code.';

  @override
  String get verify => 'Verify';

  @override
  String get resendCode => 'Resend code';

  @override
  String resendCodeCooldown(int seconds) {
    return 'Resend code ($seconds s)';
  }

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get roomNotFound => 'Room not found';

  @override
  String get deviceOn => 'ON';

  @override
  String get deviceOff => 'OFF';

  @override
  String get raining => 'Raining';

  @override
  String get clear => 'Clear';
}
