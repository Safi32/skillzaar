import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, String> _localizedStrings;

  AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  Future<bool> load() async {
    String jsonString = await rootBundle.loadString(
      'lib/l10n/${locale.languageCode}.json',
    );
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    return true;
  }

  String get selectLanguage => _localizedStrings['selectLanguage'] ?? '';
  String get english => _localizedStrings['english'] ?? '';
  String get urdu => _localizedStrings['urdu'] ?? '';
  String get monthlyAccess => _localizedStrings['monthlyAccess'] ?? '';
  String get payMsg => _localizedStrings['payMsg'] ?? '';
  String get accept => _localizedStrings['accept'] ?? '';
  String get skillzaar => _localizedStrings['skillzaar'] ?? '';
  String get welcome => _localizedStrings['welcome'] ?? '';
  String get chooseRole => _localizedStrings['chooseRole'] ?? '';
  String get skilledWorker => _localizedStrings['skilledWorker'] ?? '';
  String get postAJob => _localizedStrings['postAJob'] ?? '';
  String get jobTitle => _localizedStrings['jobTitle'] ?? '';
  String get jobTitleHint => _localizedStrings['jobTitleHint'] ?? '';
  String get jobDescription => _localizedStrings['jobDescription'] ?? '';
  String get jobDescriptionHint =>
      _localizedStrings['jobDescriptionHint'] ?? '';
  String get address => _localizedStrings['address'] ?? '';
  String get useCurrentLocation =>
      _localizedStrings['useCurrentLocation'] ?? '';
  String get enterManually => _localizedStrings['enterManually'] ?? '';
  String get staticAddress => _localizedStrings['staticAddress'] ?? '';
  String get enterAddress => _localizedStrings['enterAddress'] ?? '';
  String get currentLocationHint =>
      _localizedStrings['currentLocationHint'] ?? '';
  String get optionalImages => _localizedStrings['optionalImages'] ?? '';
  String get quickRegistration => _localizedStrings['quickRegistration'] ?? '';
  String get enterMobile => _localizedStrings['enterMobile'] ?? '';
  String get phoneHint => _localizedStrings['phoneHint'] ?? '';
  String get skilledWorkerSignUp =>
      _localizedStrings['skilledWorkerSignUp'] ?? '';
  String get skilledWorkerLogin =>
      _localizedStrings['skilledWorkerLogin'] ?? '';
  String get phoneNumber => _localizedStrings['phoneNumber'] ?? '';
  String get phoneNumberHint => _localizedStrings['phoneNumberHint'] ?? '';
  String get sendOtp => _localizedStrings['sendOtp'] ?? '';
  String get verifyOtp => _localizedStrings['verifyOtp'] ?? '';
  String get enterOtp => _localizedStrings['enterOtp'] ?? '';
  String get otpSentMsg => _localizedStrings['otpSentMsg'] ?? '';
  String get uploadCnic => _localizedStrings['uploadCnic'] ?? '';
  String get uploadCnicDesc => _localizedStrings['uploadCnicDesc'] ?? '';
  String get skillProfileSetup => _localizedStrings['skillProfileSetup'] ?? '';
  String get selectCategories => _localizedStrings['selectCategories'] ?? '';
  String get yearsOfExperience => _localizedStrings['yearsOfExperience'] ?? '';
  String get yearsOfExperienceHint =>
      _localizedStrings['yearsOfExperienceHint'] ?? '';
  String get shortBio => _localizedStrings['shortBio'] ?? '';
  String get shortBioHint => _localizedStrings['shortBioHint'] ?? '';
  String get portfolioPictures => _localizedStrings['portfolioPictures'] ?? '';
  String get fullName => _localizedStrings['fullName'] ?? '';
  String get age => _localizedStrings['age'] ?? '';
  String get city => _localizedStrings['city'] ?? '';
  String get workingRadius => _localizedStrings['workingRadius'] ?? '';
  String get aVerificationCodeSent =>
      _localizedStrings['aVerificationCodeSent'] ?? '';
  String get invalidOtp => _localizedStrings['invalidOtp'] ?? '';
  String get phoneNotRegistered =>
      _localizedStrings['phoneNotRegistered'] ?? '';
  String get profileSetup => _localizedStrings['profileSetup'] ?? '';
  String get finish => _localizedStrings['finish'] ?? '';
  String get postJob => _localizedStrings['postJob'] ?? '';
  String get jobPoster => _localizedStrings['jobPoster'] ?? '';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ur'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
