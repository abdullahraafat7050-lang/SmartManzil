import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'SmartManzil'**
  String get appName;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'SmartManzil v1.0'**
  String get appVersion;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Control your home, anywhere'**
  String get appTagline;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get usernameRequired;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get signInWithGoogle;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent.'**
  String get resetEmailSent;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening, {name}'**
  String goodEvening(String name);

  /// No description provided for @masterControl.
  ///
  /// In en, this message translates to:
  /// **'Master control'**
  String get masterControl;

  /// No description provided for @mainLight.
  ///
  /// In en, this message translates to:
  /// **'Main Light'**
  String get mainLight;

  /// No description provided for @curtain.
  ///
  /// In en, this message translates to:
  /// **'Curtain'**
  String get curtain;

  /// No description provided for @curtainOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get curtainOpen;

  /// No description provided for @curtainClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get curtainClosed;

  /// No description provided for @masterOff.
  ///
  /// In en, this message translates to:
  /// **'Master Off'**
  String get masterOff;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodNight.
  ///
  /// In en, this message translates to:
  /// **'Good Night'**
  String get goodNight;

  /// No description provided for @gate.
  ///
  /// In en, this message translates to:
  /// **'Gate'**
  String get gate;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @areaBedroom.
  ///
  /// In en, this message translates to:
  /// **'Bedroom'**
  String get areaBedroom;

  /// No description provided for @areaBathroom.
  ///
  /// In en, this message translates to:
  /// **'Bathroom'**
  String get areaBathroom;

  /// No description provided for @areaLivingRoom.
  ///
  /// In en, this message translates to:
  /// **'Living Room'**
  String get areaLivingRoom;

  /// No description provided for @areaKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get areaKitchen;

  /// No description provided for @areaGarden.
  ///
  /// In en, this message translates to:
  /// **'Garden'**
  String get areaGarden;

  /// No description provided for @areaHall.
  ///
  /// In en, this message translates to:
  /// **'Hall'**
  String get areaHall;

  /// No description provided for @sensorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sensors'**
  String get sensorsTitle;

  /// No description provided for @temperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Temp'**
  String get temperatureLabel;

  /// No description provided for @humidityLabel.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidityLabel;

  /// No description provided for @gasAlert.
  ///
  /// In en, this message translates to:
  /// **'Gas!'**
  String get gasAlert;

  /// No description provided for @smokeAlert.
  ///
  /// In en, this message translates to:
  /// **'Smoke!'**
  String get smokeAlert;

  /// No description provided for @motionLabel.
  ///
  /// In en, this message translates to:
  /// **'Motion'**
  String get motionLabel;

  /// No description provided for @allClear.
  ///
  /// In en, this message translates to:
  /// **'All Clear'**
  String get allClear;

  /// No description provided for @lightLabel.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightLabel;

  /// No description provided for @dimmerLabel.
  ///
  /// In en, this message translates to:
  /// **'Dimmer'**
  String get dimmerLabel;

  /// No description provided for @colorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get colorLabel;

  /// No description provided for @alertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsTitle;

  /// No description provided for @noAlerts.
  ///
  /// In en, this message translates to:
  /// **'No new alerts'**
  String get noAlerts;

  /// No description provided for @clearAlerts.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAlerts;

  /// No description provided for @securitySettings.
  ///
  /// In en, this message translates to:
  /// **'Security & Settings'**
  String get securitySettings;

  /// No description provided for @sectionIdentity.
  ///
  /// In en, this message translates to:
  /// **'IDENTITY'**
  String get sectionIdentity;

  /// No description provided for @sectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'SECURITY ACCESS'**
  String get sectionSecurity;

  /// No description provided for @sectionSystem.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM'**
  String get sectionSystem;

  /// No description provided for @registeredSmsNumber.
  ///
  /// In en, this message translates to:
  /// **'Registered SMS Number'**
  String get registeredSmsNumber;

  /// No description provided for @updateAccessKey.
  ///
  /// In en, this message translates to:
  /// **'Update Access Key'**
  String get updateAccessKey;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNew.
  ///
  /// In en, this message translates to:
  /// **'Confirm New'**
  String get confirmNew;

  /// No description provided for @confirmChange.
  ///
  /// In en, this message translates to:
  /// **'Confirm Change'**
  String get confirmChange;

  /// No description provided for @alertPreferences.
  ///
  /// In en, this message translates to:
  /// **'Alert Preferences'**
  String get alertPreferences;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About Lumina v1.0'**
  String get aboutApp;

  /// No description provided for @updateSmsTarget.
  ///
  /// In en, this message translates to:
  /// **'Update SMS Target'**
  String get updateSmsTarget;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @minCharsError.
  ///
  /// In en, this message translates to:
  /// **'Minimum 8 characters required.'**
  String get minCharsError;

  /// No description provided for @enterNumberError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number.'**
  String get enterNumberError;

  /// No description provided for @numberSaved.
  ///
  /// In en, this message translates to:
  /// **'Number stored securely.'**
  String get numberSaved;

  /// No description provided for @errorSavingNumber.
  ///
  /// In en, this message translates to:
  /// **'Error saving number.'**
  String get errorSavingNumber;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error.'**
  String get connectionError;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @identifyAccount.
  ///
  /// In en, this message translates to:
  /// **'Identify\nAccount'**
  String get identifyAccount;

  /// No description provided for @secureVerification.
  ///
  /// In en, this message translates to:
  /// **'Secure\nVerification'**
  String get secureVerification;

  /// No description provided for @newCredentials.
  ///
  /// In en, this message translates to:
  /// **'New\nCredentials'**
  String get newCredentials;

  /// No description provided for @sixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'6-Digit Code'**
  String get sixDigitCode;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @requestSmsCode.
  ///
  /// In en, this message translates to:
  /// **'Request SMS Code'**
  String get requestSmsCode;

  /// No description provided for @verifyAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify & Continue'**
  String get verifyAndContinue;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get cancelRequest;

  /// No description provided for @pleaseEnterUsername.
  ///
  /// In en, this message translates to:
  /// **'Please enter your username.'**
  String get pleaseEnterUsername;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code. Please try again.'**
  String get invalidCode;

  /// No description provided for @codeAccepted.
  ///
  /// In en, this message translates to:
  /// **'Code accepted. Create your new password.'**
  String get codeAccepted;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please try again.'**
  String get networkError;

  /// No description provided for @twoFactorTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Verification'**
  String get twoFactorTitle;

  /// No description provided for @twoFactorBody.
  ///
  /// In en, this message translates to:
  /// **'A 6-digit verification code was sent to the contact on file for {username}.'**
  String twoFactorBody(String username);

  /// No description provided for @enterSixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code.'**
  String get enterSixDigitCode;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @resendCodeCooldown.
  ///
  /// In en, this message translates to:
  /// **'Resend code ({seconds} s)'**
  String resendCodeCooldown(int seconds);

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @roomNotFound.
  ///
  /// In en, this message translates to:
  /// **'Room not found'**
  String get roomNotFound;

  /// No description provided for @deviceOn.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get deviceOn;

  /// No description provided for @deviceOff.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get deviceOff;

  /// No description provided for @raining.
  ///
  /// In en, this message translates to:
  /// **'Raining'**
  String get raining;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @cameras.
  ///
  /// In en, this message translates to:
  /// **'Cameras'**
  String get cameras;

  /// No description provided for @noCamerasFound.
  ///
  /// In en, this message translates to:
  /// **'No cameras available'**
  String get noCamerasFound;

  /// No description provided for @errorLoadingCameras.
  ///
  /// In en, this message translates to:
  /// **'Error loading cameras'**
  String get errorLoadingCameras;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
