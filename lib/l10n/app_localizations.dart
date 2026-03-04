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
  String get myAds => _localizedStrings['myAds'] ?? '';
  String get contactUs => _localizedStrings['contactUs'] ?? '';
  String get logout => _localizedStrings['logout'] ?? '';
  String get home => _localizedStrings['home'] ?? '';
  String get rateJobPoster => _localizedStrings['rateJobPoster'] ?? '';
  String get allAds => _localizedStrings['allAds'] ?? '';
  String get profile => _localizedStrings['profile'] ?? '';
  String get requests => _localizedStrings['requests'] ?? '';
  String get findJobsHireTalent =>
      _localizedStrings['findJobsHireTalent'] ?? '';
  String get iAmJobPoster => _localizedStrings['iAmJobPoster'] ?? '';
  String get iAmSkilledWorker => _localizedStrings['iAmSkilledWorker'] ?? '';
  String get postJobsHire => _localizedStrings['postJobsHire'] ?? '';
  String get findApplyJobs => _localizedStrings['findApplyJobs'] ?? '';
  String get continueGuest => _localizedStrings['continueGuest'] ?? '';
  String get or => _localizedStrings['or'] ?? '';
  String get jobLocation => _localizedStrings['jobLocation'] ?? '';
  String get max3Images => _localizedStrings['max3Images'] ?? '';
  String get fillRequiredFields =>
      _localizedStrings['fillRequiredFields'] ?? '';
  String get errorPickingImage => _localizedStrings['errorPickingImage'] ?? '';
  String get errorPostingJob => _localizedStrings['errorPostingJob'] ?? '';
  String get jobPostedSuccess => _localizedStrings['jobPostedSuccess'] ?? '';
  String get jobImagesOptional => _localizedStrings['jobImagesOptional'] ?? '';
  String get addImage => _localizedStrings['addImage'] ?? '';
  String get numImages => _localizedStrings['numImages'] ?? '';
  String get postingJob => _localizedStrings['postingJob'] ?? '';
  String get serviceType => _localizedStrings['serviceType'] ?? '';
  String get selectServiceType => _localizedStrings['selectServiceType'] ?? '';
  String get search => _localizedStrings['search'] ?? '';
  String get pleaseLogin => _localizedStrings['pleaseLogin'] ?? '';
  String get locationAccessGranted =>
      _localizedStrings['locationAccessGranted'] ?? '';
  String get locationAccessDenied =>
      _localizedStrings['locationAccessDenied'] ?? '';
  String get hireHighlyQualified =>
      _localizedStrings['hireHighlyQualified'] ?? '';
  String get qualified => _localizedStrings['qualified'] ?? '';
  String get professionals => _localizedStrings['professionals'] ?? '';
  String get ads => _localizedStrings['ads'] ?? '';
  String get cleaningServices => _localizedStrings['cleaningServices'] ?? '';
  String get plumbingServices => _localizedStrings['plumbingServices'] ?? '';
  String get carpentryFurniture =>
      _localizedStrings['carpentryFurniture'] ?? '';
  String get paintingFinishing => _localizedStrings['paintingFinishing'] ?? '';
  String get masonryMetalwork => _localizedStrings['masonryMetalwork'] ?? '';
  String get roofingServices => _localizedStrings['roofingServices'] ?? '';
  String get glassInstallation => _localizedStrings['glassInstallation'] ?? '';
  String get outdoorGardening => _localizedStrings['outdoorGardening'] ?? '';
  String get electricalServices =>
      _localizedStrings['electricalServices'] ?? '';
  String get labourMoving => _localizedStrings['labourMoving'] ?? '';
  String get carCareServices => _localizedStrings['carCareServices'] ?? '';
  String get cateringEvents => _localizedStrings['cateringEvents'] ?? '';
  String get outdoorConstruction =>
      _localizedStrings['outdoorConstruction'] ?? '';
  String get leakRepair => _localizedStrings['leakRepair'] ?? '';
  String get drainCleaning => _localizedStrings['drainCleaning'] ?? '';
  String get fixtureInstall => _localizedStrings['fixtureInstall'] ?? '';
  String get pipeReplacement => _localizedStrings['pipeReplacement'] ?? '';
  String get tapPipeLeaks => _localizedStrings['tapPipeLeaks'] ?? '';
  String get clogsSlowDrains => _localizedStrings['clogsSlowDrains'] ?? '';
  String get faucetsToilets => _localizedStrings['faucetsToilets'] ?? '';
  String get pvcMetalFitting => _localizedStrings['pvcMetalFitting'] ?? '';
  String get plumbing => _localizedStrings['plumbing'] ?? '';
  String get painting => _localizedStrings['painting'] ?? '';
  String get cleaning => _localizedStrings['cleaning'] ?? '';
  String get gardening => _localizedStrings['gardening'] ?? '';
  String get masonry => _localizedStrings['masonry'] ?? '';
  String get electricWork => _localizedStrings['electricWork'] ?? '';
  String get all => _localizedStrings['all'] ?? '';
  String get noJobsAvailable => _localizedStrings['noJobsAvailable'] ?? '';
  String get checkBackLater => _localizedStrings['checkBackLater'] ?? '';
  String get noCategoryJobs => _localizedStrings['noCategoryJobs'] ?? '';
  String get logoutConfirmMsg => _localizedStrings['logoutConfirmMsg'] ?? '';
  String get cancel => _localizedStrings['cancel'] ?? '';
  String get locationAccess => _localizedStrings['locationAccess'] ?? '';
  String get locationAccessDesc =>
      _localizedStrings['locationAccessDesc'] ?? '';
  String get thisWillHelp => _localizedStrings['thisWillHelp'] ?? '';
  String get preciseLocations => _localizedStrings['preciseLocations'] ?? '';
  String get nearbyWorkers => _localizedStrings['nearbyWorkers'] ?? '';
  String get matchingAccuracy => _localizedStrings['matchingAccuracy'] ?? '';
  String get turnOnLocation => _localizedStrings['turnOnLocation'] ?? '';
  String get locationDisabled => _localizedStrings['locationDisabled'] ?? '';
  String get locationPermanentlyDenied =>
      _localizedStrings['locationPermanentlyDenied'] ?? '';
  String get goToSettings => _localizedStrings['goToSettings'] ?? '';
  String get tapPrivacy => _localizedStrings['tapPrivacy'] ?? '';
  String get tapLocationServices =>
      _localizedStrings['tapLocationServices'] ?? '';
  String get enableForApp => _localizedStrings['enableForApp'] ?? '';
  String get openSettings => _localizedStrings['openSettings'] ?? '';
  String get viewDetails => _localizedStrings['viewDetails'] ?? '';
  String get edit => _localizedStrings['edit'] ?? '';
  String get postedToday => _localizedStrings['postedToday'] ?? '';
  String get postedYesterday => _localizedStrings['postedYesterday'] ?? '';
  String get pleaseLoginToViewAds =>
      _localizedStrings['pleaseLoginToViewAds'] ?? '';
  String get personalInformation =>
      _localizedStrings['personalInformation'] ?? '';
  String get statistics => _localizedStrings['statistics'] ?? '';
  String get totalJobsPosted => _localizedStrings['totalJobsPosted'] ?? '';
  String get activeRequests => _localizedStrings['activeRequests'] ?? '';
  String get completedJobs => _localizedStrings['completedJobs'] ?? '';
  String get guestUser => _localizedStrings['guestUser'] ?? '';
  String get deactivateAccount => _localizedStrings['deactivateAccount'] ?? '';
  String get deactivateConfirmMsg =>
      _localizedStrings['deactivateConfirmMsg'] ?? '';
  String get delete => _localizedStrings['delete'] ?? '';
  String get loginToViewDetails =>
      _localizedStrings['loginToViewDetails'] ?? '';
  String get email => _localizedStrings['email'] ?? '';
  String get location => _localizedStrings['location'] ?? '';
  String get actions => _localizedStrings['actions'] ?? '';
  String get adDetailsMissing => _localizedStrings['adDetailsMissing'] ?? '';
  String get editComingSoon => _localizedStrings['editComingSoon'] ?? '';
  String get noApprovedJobs => _localizedStrings['noApprovedJobs'] ?? '';
  String get jobsAdminReview => _localizedStrings['jobsAdminReview'] ?? '';
  String get calculatingDistance =>
      _localizedStrings['calculatingDistance'] ?? '';
  String get tapForMoreDetails => _localizedStrings['tapForMoreDetails'] ?? '';
  String get jobNotAssignedMsg => _localizedStrings['jobNotAssignedMsg'] ?? '';
  String get callJobPoster => _localizedStrings['callJobPoster'] ?? '';
  String kmAway(String distance) =>
      (_localizedStrings['kmAway'] ?? '').replaceAll('{distance}', distance);
  String get noAdsYet => _localizedStrings['noAdsYet'] ?? '';
  String get startPostingJobsMsg =>
      _localizedStrings['startPostingJobsMsg'] ?? '';
  String get postYourFirstJob => _localizedStrings['postYourFirstJob'] ?? '';
  String get noJobsFound => _localizedStrings['noJobsFound'] ?? '';
  String get jobsAppearHereMsg => _localizedStrings['jobsAppearHereMsg'] ?? '';
  String get selectSkills => _localizedStrings['selectSkills'] ?? '';
  String get custom => _localizedStrings['custom'] ?? '';
  String get chooseSkillsDesc => _localizedStrings['chooseSkillsDesc'] ?? '';
  String selectedCategoriesCount(String count) =>
      (_localizedStrings['selectedCategoriesCount'] ?? '').replaceAll(
        '{count}',
        count,
      );
  String get primaryServiceType =>
      _localizedStrings['primaryServiceType'] ?? '';
  String get serviceTypeDesc => _localizedStrings['serviceTypeDesc'] ?? '';
  String get selectPrimaryServiceHint =>
      _localizedStrings['selectPrimaryServiceHint'] ?? '';
  String selectedService(String service) =>
      (_localizedStrings['selectedService'] ?? '').replaceAll(
        '{service}',
        service,
      );
  String get yearsOfExperienceLabel =>
      _localizedStrings['yearsOfExperienceLabel'] ?? '';
  String get experienceDesc => _localizedStrings['experienceDesc'] ?? '';
  String get hourlyRateLabel => _localizedStrings['hourlyRateLabel'] ?? '';
  String get hourlyRateDesc => _localizedStrings['hourlyRateDesc'] ?? '';
  String get availabilityLabel => _localizedStrings['availabilityLabel'] ?? '';
  String get availabilityDesc => _localizedStrings['availabilityDesc'] ?? '';
  String get shortBioLabel => _localizedStrings['shortBioLabel'] ?? '';
  String get bioDesc => _localizedStrings['bioDesc'] ?? '';
  String get portfolioLabel => _localizedStrings['portfolioLabel'] ?? '';
  String get portfolioDesc => _localizedStrings['portfolioDesc'] ?? '';
  String get saveProfile => _localizedStrings['saveProfile'] ?? '';
  String get updatingProfile => _localizedStrings['updatingProfile'] ?? '';
  String get profileUpdatedMsg => _localizedStrings['profileUpdatedMsg'] ?? '';
  String get errorUpdatingProfile =>
      _localizedStrings['errorUpdatingProfile'] ?? '';
  String get years => _localizedStrings['years'] ?? '';
  String get egYears => _localizedStrings['egYears'] ?? '';
  String get pkrPerHour => _localizedStrings['pkrPerHour'] ?? '';
  String get egHourlyRate => _localizedStrings['egHourlyRate'] ?? '';
  String get egAvailability => _localizedStrings['egAvailability'] ?? '';
  String get professionalBio => _localizedStrings['professionalBio'] ?? '';
  String get bioHint => _localizedStrings['bioHint'] ?? '';
  String minCharsRequired(String min) =>
      (_localizedStrings['minCharsRequired'] ?? '').replaceAll('{min}', min);
  String moreCharsNeeded(String count) =>
      (_localizedStrings['moreCharsNeeded'] ?? '').replaceAll('{count}', count);
  String get addPhoto => _localizedStrings['addPhoto'] ?? '';
  String get completeRequiredFields =>
      _localizedStrings['completeRequiredFields'] ?? '';
  String get portfolioComplete => _localizedStrings['portfolioComplete'] ?? '';
  String get portfolioSetupRequired =>
      _localizedStrings['portfolioSetupRequired'] ?? '';
  String percentComplete(String percent) =>
      (_localizedStrings['percentComplete'] ?? '').replaceAll(
        '{percent}',
        percent,
      );
  String get saveFailed => _localizedStrings['saveFailed'] ?? '';
  String get saveFailedDesc => _localizedStrings['saveFailedDesc'] ?? '';
  String get checkConnectionMsg =>
      _localizedStrings['checkConnectionMsg'] ?? '';
  String get retry => _localizedStrings['retry'] ?? '';
  String get portfolioSetupHelp =>
      _localizedStrings['portfolioSetupHelp'] ?? '';
  String get completePortfolioSteps =>
      _localizedStrings['completePortfolioSteps'] ?? '';
  String get stepSkills => _localizedStrings['stepSkills'] ?? '';
  String get stepExperience => _localizedStrings['stepExperience'] ?? '';
  String get stepRate => _localizedStrings['stepRate'] ?? '';
  String get stepAvailability => _localizedStrings['stepAvailability'] ?? '';
  String get stepBio => _localizedStrings['stepBio'] ?? '';
  String get stepPictures => _localizedStrings['stepPictures'] ?? '';
  String get portfolioVisibleToClients =>
      _localizedStrings['portfolioVisibleToClients'] ?? '';
  String get gotIt => _localizedStrings['gotIt'] ?? '';
  String get deleteFailed => _localizedStrings['deleteFailed'] ?? '';
  String get deleteFailedMsg => _localizedStrings['deleteFailedMsg'] ?? '';
  String get userRegistration => _localizedStrings['userRegistration'] ?? '';
  String get enterPhoneToRegister =>
      _localizedStrings['enterPhoneToRegister'] ?? '';
  String otpSentTo(String phone) =>
      (_localizedStrings['otpSentTo'] ?? '').replaceAll('{phone}', phone);
  String get tagline => _localizedStrings['tagline'] ?? '';
  String get statusPending => _localizedStrings['statusPending'] ?? '';
  String get statusCompleted => _localizedStrings['statusCompleted'] ?? '';
  String get statusActive => _localizedStrings['statusActive'] ?? '';
  String get statusInactive => _localizedStrings['statusInactive'] ?? '';
  String get statusAssigned => _localizedStrings['statusAssigned'] ?? '';
  String get statusApproved => _localizedStrings['statusApproved'] ?? '';
  String get autoLocation => _localizedStrings['autoLocation'] ?? '';
  String get manualAddress => _localizedStrings['manualAddress'] ?? '';
  String get manualAddressEntry =>
      _localizedStrings['manualAddressEntry'] ?? '';
  String get searchAddressHint => _localizedStrings['searchAddressHint'] ?? '';
  String get searchLocationHint =>
      _localizedStrings['searchLocationHint'] ?? '';
  String get selectedLocation => _localizedStrings['selectedLocation'] ?? '';
  String get gettingLocation => _localizedStrings['gettingLocation'] ?? '';
  String get preciseCoordinatesNote =>
      _localizedStrings['preciseCoordinatesNote'] ?? '';
  String get manualAddressInstruction =>
      _localizedStrings['manualAddressInstruction'] ?? '';
  String get locationSelectedLabel =>
      _localizedStrings['locationSelectedLabel'] ?? '';
  String get locationAccessGrantedGPS =>
      _localizedStrings['locationAccessGrantedGPS'] ?? '';
  String get locationPermRequiredMsg =>
      _localizedStrings['locationPermRequiredMsg'] ?? '';
  String get locationServiceDisabledMsg =>
      _localizedStrings['locationServiceDisabledMsg'] ?? '';

  // New Services
  String get applianceDeepCleaning =>
      _localizedStrings['applianceDeepCleaning'] ?? '';
  String get waterUtility => _localizedStrings['waterUtility'] ?? '';
  String get resCommConstruction =>
      _localizedStrings['resCommConstruction'] ?? '';
  String get designPlanning => _localizedStrings['designPlanning'] ?? '';
  String get renovationFinishing =>
      _localizedStrings['renovationFinishing'] ?? '';
  String get specializedWorks => _localizedStrings['specializedWorks'] ?? '';

  // Contact Us
  String get wereHereToHelp => _localizedStrings['wereHereToHelp'] ?? '';
  String get getInTouchWithSupport =>
      _localizedStrings['getInTouchWithSupport'] ?? '';
  String get getInTouch => _localizedStrings['getInTouch'] ?? '';
  String get callUs => _localizedStrings['callUs'] ?? '';
  String get emailUs => _localizedStrings['emailUs'] ?? '';
  String get whatsApp => _localizedStrings['whatsApp'] ?? '';
  String get messageUsOnWhatsApp =>
      _localizedStrings['messageUsOnWhatsApp'] ?? '';
  String get officeHours => _localizedStrings['officeHours'] ?? '';
  String get mondayFriday => _localizedStrings['mondayFriday'] ?? '';
  String get saturday => _localizedStrings['saturday'] ?? '';
  String get sunday => _localizedStrings['sunday'] ?? '';
  String get closed => _localizedStrings['closed'] ?? '';
  String get faq => _localizedStrings['faq'] ?? '';
  String get howToPostJob => _localizedStrings['howToPostJob'] ?? '';
  String get howToPostJobAns => _localizedStrings['howToPostJobAns'] ?? '';
  String get howToViewRequests => _localizedStrings['howToViewRequests'] ?? '';
  String get howToViewRequestsAns =>
      _localizedStrings['howToViewRequestsAns'] ?? '';
  String get canIEditJobs => _localizedStrings['canIEditJobs'] ?? '';
  String get canIEditJobsAns => _localizedStrings['canIEditJobsAns'] ?? '';
  String get howToContactWorkers =>
      _localizedStrings['howToContactWorkers'] ?? '';
  String get howToContactWorkersAns =>
      _localizedStrings['howToContactWorkersAns'] ?? '';
  String get reportAnIssue => _localizedStrings['reportAnIssue'] ?? '';
  String get welcomeToSkillzaar =>
      _localizedStrings['welcomeToSkillzaar'] ?? '';
  String get loginAsSkilledWorkerDesc =>
      _localizedStrings['loginAsSkilledWorkerDesc'] ?? '';
  String get loginAsJobPosterDesc =>
      _localizedStrings['loginAsJobPosterDesc'] ?? '';
  String get mobileNumber => _localizedStrings['mobileNumber'] ?? '';
  String get enterPhoneHint => _localizedStrings['enterPhoneHint'] ?? '';
  String get password => _localizedStrings['password'] ?? '';
  String get enterPasswordHint => _localizedStrings['enterPasswordHint'] ?? '';
  String get dontHaveAccount => _localizedStrings['dontHaveAccount'] ?? '';
  String get signUp => _localizedStrings['signUp'] ?? '';
  String get termsPolicyAccept => _localizedStrings['termsPolicyAccept'] ?? '';
  String get phoneValidError => _localizedStrings['phoneValidError'] ?? '';
  String get pleaseEnterPhone => _localizedStrings['pleaseEnterPhone'] ?? '';
  String get pleaseEnterPassword =>
      _localizedStrings['pleaseEnterPassword'] ?? '';
  String get createAccount => _localizedStrings['createAccount'] ?? '';
  String get joinAsJobPoster => _localizedStrings['joinAsJobPoster'] ?? '';
  String get username => _localizedStrings['username'] ?? '';
  String get enterNameHint => _localizedStrings['enterNameHint'] ?? '';
  String get enterEmailHint => _localizedStrings['enterEmailHint'] ?? '';
  String get userExistsError => _localizedStrings['userExistsError'] ?? '';
  String get registrationFailed =>
      _localizedStrings['registrationFailed'] ?? '';
  String get termsOfServicePrivacy =>
      _localizedStrings['termsOfServicePrivacy'] ?? '';
  String get pleaseEnterUserEmailPass =>
      _localizedStrings['pleaseEnterUserEmailPass'] ?? '';
  String get invalidPhone => _localizedStrings['invalidPhone'] ?? '';
  String get enterPhoneLoginWorkerDesc =>
      _localizedStrings['enterPhoneLoginWorkerDesc'] ?? '';
  String get alreadyHaveAccount =>
      _localizedStrings['alreadyHaveAccount'] ?? '';
  String get noAccountFoundWorker =>
      _localizedStrings['noAccountFoundWorker'] ?? '';
  String errorCheckingAccount(String error) =>
      (_localizedStrings['errorCheckingAccount'] ?? '').replaceAll(
        '{error}',
        error,
      );
  String get addCustomCategory => _localizedStrings['addCustomCategory'] ?? '';
  String get enterCustomCategoryName =>
      _localizedStrings['enterCustomCategoryName'] ?? '';
  String get add => _localizedStrings['add'] ?? '';
  String get portfolioCompleteMessage =>
      _localizedStrings['portfolioCompleteMessage'] ?? '';
  String get completePortfolioRequestJobs =>
      _localizedStrings['completePortfolioRequestJobs'] ?? '';
  String get skillsText => _localizedStrings['skillsText'] ?? '';
  String get experienceText => _localizedStrings['experienceText'] ?? '';
  String get bioText => _localizedStrings['bioText'] ?? '';
  String get catElectrical => _localizedStrings['catElectrical'] ?? '';
  String get catPlumbing => _localizedStrings['catPlumbing'] ?? '';
  String get catCarpentry => _localizedStrings['catCarpentry'] ?? '';
  String get catCleaning => _localizedStrings['catCleaning'] ?? '';
  String get catOther => _localizedStrings['catOther'] ?? '';
  String get getInTouchWithUs => _localizedStrings['getInTouchWithUs'] ?? '';
  String get close => _localizedStrings['close'] ?? '';
  String get filterJobs => _localizedStrings['filterJobs'] ?? '';
  String get jobType => _localizedStrings['jobType'] ?? '';
  String get radiusKm => _localizedStrings['radiusKm'] ?? '';
  String get apply => _localizedStrings['apply'] ?? '';
  String get reset => _localizedStrings['reset'] ?? '';

  String get assignedJobDetails =>
      _localizedStrings['assignedJobDetails'] ?? '';
  String get jobDetailsText => _localizedStrings['jobDetailsText'] ?? '';
  String get jobTitleText => _localizedStrings['jobTitleText'] ?? '';
  String get locationText => _localizedStrings['locationText'] ?? '';
  String get budgetText => _localizedStrings['budgetText'] ?? '';
  String get descriptionText => _localizedStrings['descriptionText'] ?? '';
  String get createdText => _localizedStrings['createdText'] ?? '';
  String get urgencyText => _localizedStrings['urgencyText'] ?? '';
  String get durationText => _localizedStrings['durationText'] ?? '';
  String get statusText => _localizedStrings['statusText'] ?? '';

  String get skilledWorkerDetailsText =>
      _localizedStrings['skilledWorkerDetailsText'] ?? '';
  String get nameText => _localizedStrings['nameText'] ?? '';
  String get phoneText => _localizedStrings['phoneText'] ?? '';
  String get cityText => _localizedStrings['cityText'] ?? '';
  String get ratingText => _localizedStrings['ratingText'] ?? '';
  String get experienceLabel => _localizedStrings['experienceLabel'] ?? '';
  String get rateText => _localizedStrings['rateText'] ?? '';

  String get jobPosterDetailsText =>
      _localizedStrings['jobPosterDetailsText'] ?? '';
  String get emailText => _localizedStrings['emailText'] ?? '';
  String get addressText => _localizedStrings['addressText'] ?? '';

  String get callText => _localizedStrings['callText'] ?? '';
  String get navigateText => _localizedStrings['navigateText'] ?? '';
  String get trackWorker => _localizedStrings['trackWorker'] ?? '';
  String get completeJob => _localizedStrings['completeJob'] ?? '';
  String get cancelJobText => _localizedStrings['cancelJobText'] ?? '';
  String get jobApproval => _localizedStrings['jobApproval'] ?? '';
  String get approvalPendingText =>
      _localizedStrings['approvalPendingText'] ?? '';
  String get paymentApprovedText =>
      _localizedStrings['paymentApprovedText'] ?? '';

  String get notSpecified => _localizedStrings['notSpecified'] ?? '';
  String get normalUrgency => _localizedStrings['normalUrgency'] ?? '';
  String get noTitle => _localizedStrings['noTitle'] ?? '';
  String get noLocation => _localizedStrings['noLocation'] ?? '';
  String get noDescription => _localizedStrings['noDescription'] ?? '';
  String get unknown => _localizedStrings['unknown'] ?? '';
  String get notAvailable => _localizedStrings['notAvailable'] ?? '';
  String get noRating => _localizedStrings['noRating'] ?? '';
  String get jobAndApplicantDetails =>
      _localizedStrings['jobAndApplicantDetails'] ?? '';
  String get titleText => _localizedStrings['titleText'] ?? '';
  String get serviceTypeText => _localizedStrings['serviceTypeText'] ?? '';
  String get posterPhoneText => _localizedStrings['posterPhoneText'] ?? '';
  String get skilledWorkerText => _localizedStrings['skilledWorkerText'] ?? '';
  String get skillsLabel => _localizedStrings['skillsLabel'] ?? '';
  String get trackWorkerLocation =>
      _localizedStrings['trackWorkerLocation'] ?? '';
  String get statusCancelled => _localizedStrings['statusCancelled'] ?? '';
  String get workerTrackingUnavailable =>
      _localizedStrings['workerTrackingUnavailable'] ?? '';
  String get unableToTrackWorkerLocation =>
      _localizedStrings['unableToTrackWorkerLocation'] ?? '';
  String get distanceToJob => _localizedStrings['distanceToJob'] ?? '';
  String get lastUpdate => _localizedStrings['lastUpdate'] ?? '';
  String get navigateTo => _localizedStrings['navigateTo'] ?? '';
  String get workerLocationNotAvailable =>
      _localizedStrings['workerLocationNotAvailable'] ?? '';
  String get enableLocationServicesToGetDirections =>
      _localizedStrings['enableLocationServicesToGetDirections'] ?? '';
  String get goBack => _localizedStrings['goBack'] ?? '';
  String get routeInformation => _localizedStrings['routeInformation'] ?? '';
  String get yourCurrentLocation =>
      _localizedStrings['yourCurrentLocation'] ?? '';
  String get getDirections => _localizedStrings['getDirections'] ?? '';
  String get distanceLabel => _localizedStrings['distanceLabel'] ?? '';
  String get jobNotFound => _localizedStrings['jobNotFound'] ?? '';
  String get noAddress => _localizedStrings['noAddress'] ?? '';
  String get noPhoneInfo => _localizedStrings['noPhoneInfo'] ?? '';
  String get statusOnline => _localizedStrings['statusOnline'] ?? '';
  String get statusOffline => _localizedStrings['statusOffline'] ?? '';
  String get lastSeenLabel => _localizedStrings['lastSeenLabel'] ?? '';
  String get neverLabel => _localizedStrings['neverLabel'] ?? '';
  String get justNowLabel => _localizedStrings['justNowLabel'] ?? '';
  String get minutesAgo => _localizedStrings['minutesAgo'] ?? '';
  String get hoursAgo => _localizedStrings['hoursAgo'] ?? '';
  String get daysAgo => _localizedStrings['daysAgo'] ?? '';
  String get refreshLocation => _localizedStrings['refreshLocation'] ?? '';
  String get workLocation => _localizedStrings['workLocation'] ?? '';
  String get currentPosition => _localizedStrings['currentPosition'] ?? '';
  String get updatedLabel => _localizedStrings['updatedLabel'] ?? '';
  String get rateSkilledWorker => _localizedStrings['rateSkilledWorker'] ?? '';
  String get rateClient => _localizedStrings['rateClient'] ?? '';
  String get jobCompleted => _localizedStrings['jobCompleted'] ?? '';
  String get currentRating => _localizedStrings['currentRating'] ?? '';
  String get ratingLabel => _localizedStrings['ratingLabel'] ?? '';
  String get ratingsLabel => _localizedStrings['ratingsLabel'] ?? '';
  String get howWasExperienceWorker =>
      _localizedStrings['howWasExperienceWorker'] ?? '';
  String get howWasExperienceClient =>
      _localizedStrings['howWasExperienceClient'] ?? '';
  String get quickFeedback => _localizedStrings['quickFeedback'] ?? '';
  String get customFeedback => _localizedStrings['customFeedback'] ?? '';
  String get feedbackHintWorker =>
      _localizedStrings['feedbackHintWorker'] ?? '';
  String get feedbackHintClient =>
      _localizedStrings['feedbackHintClient'] ?? '';
  String get submitRatingCompleteJob =>
      _localizedStrings['submitRatingCompleteJob'] ?? '';
  String get submitRating => _localizedStrings['submitRating'] ?? '';
  String get ratingSubmittedSuccess =>
      _localizedStrings['ratingSubmittedSuccess'] ?? '';
  String get failedToSubmitRating =>
      _localizedStrings['failedToSubmitRating'] ?? '';
  String get workerNotIdentified =>
      _localizedStrings['workerNotIdentified'] ?? '';
  String get workerNotFound => _localizedStrings['workerNotFound'] ?? '';
  String get workerIdMissing => _localizedStrings['workerIdMissing'] ?? '';
  String get jobDataNotAvailable =>
      _localizedStrings['jobDataNotAvailable'] ?? '';
  String get feedbackExcellent => _localizedStrings['feedbackExcellent'] ?? '';
  String get feedbackVeryGood => _localizedStrings['feedbackVeryGood'] ?? '';
  String get feedbackGood => _localizedStrings['feedbackGood'] ?? '';
  String get feedbackAverage => _localizedStrings['feedbackAverage'] ?? '';
  String get feedbackPoor => _localizedStrings['feedbackPoor'] ?? '';
  String get feedbackExcellentClient =>
      _localizedStrings['feedbackExcellentClient'] ?? '';
  String get clientLabel => _localizedStrings['clientLabel'] ?? '';
  String get workerLabel => _localizedStrings['workerLabel'] ?? '';
  String get jobLabel => _localizedStrings['jobLabel'] ?? '';
  String get phoneLabel => _localizedStrings['phoneLabel'] ?? '';
  String get cityLabel => _localizedStrings['cityLabel'] ?? '';
  String get jobPosterDetails => _localizedStrings['jobPosterDetails'] ?? '';
  String get rateExperienceJobPoster =>
      _localizedStrings['rateExperienceJobPoster'] ?? '';
  String get howWasExperience => _localizedStrings['howWasExperience'] ?? '';
  String get selectFeedback => _localizedStrings['selectFeedback'] ?? '';
  String get writeOwnFeedback => _localizedStrings['writeOwnFeedback'] ?? '';
  String get enterDetailedFeedback =>
      _localizedStrings['enterDetailedFeedback'] ?? '';
  String get submittingText => _localizedStrings['submittingText'] ?? '';
  String get nameLabel => _localizedStrings['nameLabel'] ?? '';
  String get emailLabel => _localizedStrings['emailLabel'] ?? '';
  String get addressLabel => _localizedStrings['addressLabel'] ?? '';
  String get excellent => _localizedStrings['excellent'] ?? '';
  String get veryGoodExcl => _localizedStrings['veryGoodExcl'] ?? '';
  String get goodExcl => _localizedStrings['goodExcl'] ?? '';
  String get enterOtpCode => _localizedStrings['enterOtpCode'] ?? '';
  String get resendOtp => _localizedStrings['resendOtp'] ?? '';
  String get verifyButton => _localizedStrings['verifyButton'] ?? '';
  String get pleaseEnterOtp => _localizedStrings['pleaseEnterOtp'] ?? '';
  String get signupSuccess => _localizedStrings['signupSuccess'] ?? '';
  String get loginSuccess => _localizedStrings['loginSuccess'] ?? '';
  String get signupFailed => _localizedStrings['signupFailed'] ?? '';
  String get loginFailed => _localizedStrings['loginFailed'] ?? '';
  String get ratingSubmittedStars =>
      _localizedStrings['ratingSubmittedStars'] ?? '';
  String get errorSubmittingRating =>
      _localizedStrings['errorSubmittingRating'] ?? '';
  String get assignedJobNotFound =>
      _localizedStrings['assignedJobNotFound'] ?? '';
  String get alreadySubmittedRating =>
      _localizedStrings['alreadySubmittedRating'] ?? '';
  String get missingRequiredIds =>
      _localizedStrings['missingRequiredIds'] ?? '';
  String get errorLoadingJobData =>
      _localizedStrings['errorLoadingJobData'] ?? '';
  String get starsText => _localizedStrings['starsText'] ?? '';
  String get recaptchaFailed => _localizedStrings['recaptchaFailed'] ?? '';
  String get recaptchaExpired => _localizedStrings['recaptchaExpired'] ?? '';
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
