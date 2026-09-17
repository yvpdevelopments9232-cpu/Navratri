import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppStrings {
  static const String _prefKey = 'user_selected_language';

  // ValueNotifier for reactive updates across the entire app
  static final ValueNotifier<bool> languageNotifier = ValueNotifier<bool>(true);

  static bool get isMarathi => languageNotifier.value;
  static set isMarathi(bool val) {
    if (languageNotifier.value != val) {
      languageNotifier.value = val;
      _savePreference(val);
    }
  }

  static String tr(String mr, String en) => isMarathi ? mr : en;

  /// Loads saved language preference on application startup
  static Future<void> loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString(_prefKey);
      if (savedLang != null) {
        languageNotifier.value = (savedLang == 'mr');
        debugPrint('Loaded language preference: ${savedLang == "mr" ? "Marathi" : "English"}');
      } else {
        languageNotifier.value = true; // Default is Marathi
      }
    } catch (e) {
      debugPrint('Language preference load error: $e');
    }
  }

  /// Sets and persists language preference
  static Future<void> setLanguage({required bool marathi}) async {
    languageNotifier.value = marathi;
    await _savePreference(marathi);
  }

  /// Toggles and persists language preference
  static Future<void> toggleLanguage() async {
    await setLanguage(marathi: !isMarathi);
  }

  static Future<void> _savePreference(bool marathi) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, marathi ? 'mr' : 'en');
      debugPrint('Saved language preference: ${marathi ? "Marathi" : "English"}');
    } catch (e) {
      debugPrint('Language preference save error: $e');
    }
  }

  // Header & App Identity
  static String get appName => tr('श्री नवदुर्गा उत्सव मंडळ', 'Shree Navdurga Utsav Mandal');
  static String get appSubtitle => tr('नवरात्र उत्सव व हिशोब व्यवस्थापन प्रणाली', 'Navratri Festival & Accounts Management ERP');
  static String get tagline => tr('धर्मो रक्षति रक्षितः • उत्सव एकात्मतेचा', 'Dharmo Rakshati Rakshitah • Festival of Unity');

  // Auth & Roles
  static String get loginTitle => tr('1. Login & Authentication', '1. Login & Authentication');
  static String get emailLabel => tr('Email ID (वापरकर्ता ईमेल)', 'Email ID (Username)');
  static String get passwordLabel => tr('Password (पासवर्ड)', 'Password');
  static String get forgotPassword => tr('पासवर्ड विसरलात? (Forgot Password?)', 'Forgot Password?');
  static String get loginButton => tr('Login', 'Login');
  static String get loggingIn => tr('लॉगिन होत आहे...', 'Signing in...');
  static String get newAccountPrompt => tr('नवीन खाते तयार करायचे आहे? ', 'Want to register a new account? ');
  static String get signUpLink => tr('Sign Up करा', 'Sign Up');
  static String get alreadyHaveAccount => tr('आधीच खाते आहे? ', 'Already have an account? ');
  static String get loginLink => tr('Login करा', 'Log In');
  static String get subUserSwitch => tr('Sub-User Switch (कार्यकर्ता / पदाधिकारी)', 'Sub-User Switch (Staff / Officers)');
  static String get forgotPasswordTitle => tr('पासवर्ड रीसेट (Forgot Password)', 'Reset Password');
  static String get forgotPasswordSubtitle => tr('आपला नोंदणीकृत ईमेल आयडी टाका. आम्ही पासवर्ड रीसेट OTP कोड पाठवू.', 'Enter your registered email address. We will send an OTP code to reset your password.');
  static String get otpSentSuccess => tr('OTP कोड आपल्या ईमेलवर पाठवला आहे! (Password reset OTP sent to your email)', 'Password reset OTP sent to your email!');
  static String get sendOtpButton => tr('OTP कोड पाठवा (SEND OTP)', 'Send OTP Code');
  static String get backToLogin => tr('मागे जा (Back to Login)', 'Back to Login');
  static String get otpVerificationTitle => tr('OTP पडताळणी (Verify OTP)', 'Verify OTP');
  static String get otpVerificationSubtitle => tr('आम्ही OTP कोड खालील ईमेलवर पाठवला आहे:', 'We have sent an OTP code to:');
  static String get otpLabel => tr('OTP कोड (६ किंवा ८ अंकी / 6 or 8-Digit OTP)', 'OTP Code (6 or 8 Digits)');
  static String get newPasswordLabel => tr('नवीन पासवर्ड (New Password)', 'New Password');
  static String get setPasswordButton => tr('पासवर्ड निश्चित करा (SET PASSWORD)', 'Set Password');
  static String get passwordResetSuccess => tr('पासवर्ड यशस्वीरित्या बदलला आहे! आता आपण नवीन पासवर्डने लॉगिन करू शकता.', 'Password changed successfully! You can now log in with your new password.');

  // Sign Up
  static String get signUpTitle => tr('नवीन मंडळ नोंदणी (Sign Up)', 'New Mandal Registration (Sign Up)');
  static String get signUpSubtitle => tr('नवीन खाते तयार करा व मंडळाची नोंदणी करा', 'Create New Account & Register Mandal');
  static String get mandalNameLabel => tr('Mandal Name (मंडळाचे नाव) *', 'Mandal Name *');
  static String get addressLabel => tr('Address / City (पत्ता / शहर / प्रभाग) *', 'Address / City / Ward *');
  static String get adminNameLabel => tr('President / Admin Full Name (अध्यक्ष / व्यवस्थापक नाव) *', 'President / Admin Full Name *');
  static String get mobileLabel => tr('Mobile Number (मोबाईल नंबर)', 'Mobile Number');
  static String get signUpButton => tr('Sign Up & Start App', 'Sign Up & Start App');
  static String get signingUp => tr('नोंदणी होत आहे...', 'Registering...');

  // Sub-Login
  static String get subLoginTitle => tr('Navratri Mandal Management System', 'Navratri Mandal Management System');
  static String get secureAccess => tr('Secure Application Access', 'Secure Application Access');
  static String get dataUpToDate => tr('Data Up To Date (हिशोब अखेर तारीख)', 'Data Up To Date');
  static String get loginAndContinue => tr('Login & Continue', 'Login & Continue');
  static String get viewOnlyButton => tr('सभासद म्हणून उघडा (View Only Mode)', 'Open as Member (View Only Mode)');
  static String get switchMainLogin => tr('दुसऱ्या खात्यातून लॉगिन करायचे आहे? ', 'Want to sign in with a different account? ');
  static String get mainLoginLink => tr('Main Login', 'Main Login');

  // Role Selection Dialog
  static String get selectRole => tr('SELECT ROLE', 'SELECT ROLE');
  static String get selectRoleSubtitle => tr('तुमची भूमिका निवडा (Select your role)', 'Select your role');
  static String get roleAdmin => tr('Admin (ॲडमिन)', 'Admin');
  static String get roleAdminDesc => tr('सर्व अधिकार, देणगी पावती, खर्च, बँक व हिशोब व्यवस्थापन (Sub-Login Flow)', 'Full access to donations, expenses, cash, and settings');
  static String get roleMember => tr('Member / Volunteer (सभासद / कार्यकर्ता)', 'Member / Volunteer');
  static String get roleMemberDesc => tr('फक्त माहिती, कार्यक्रम, आरती व अहवाल पाहणे (थेट ॲप सुरू होईल)', 'View-only access to events, aarti, and public reports');
  static String get continueBtn => tr('CONTINUE / पुढे जा', 'CONTINUE');

  // Sidebar & Module Titles
  static String get navDashboard => tr('डॅशबोर्ड', 'Dashboard');
  static String get navMembers => tr('मंडळ सभासद', 'Members');
  static String get navDonations => tr('देणगी / वर्गणी', 'Donations');
  static String get navExpenses => tr('खर्च व्यवस्थापन', 'Expenses');
  static String get navBankCash => tr('बँक व रोख', 'Bank & Cash');
  static String get navEvents => tr('उत्सव कार्यक्रम', 'Events');
  static String get navGarba => tr('गरबा / दांडिया', 'Garba / Dandiya');
  static String get navVolunteers => tr('स्वयंसेवक / कार्यकर्ते', 'Volunteers');
  static String get navVendors => tr('विक्रेते / व्यापारी', 'Vendors');
  static String get navInventory => tr('साहित्य व्यवस्थापन', 'Inventory');
  static String get navPermissions => tr('सरकारी परवानग्या', 'Permissions');
  static String get navSponsors => tr('प्रायोजक', 'Sponsors');
  static String get navFoodPrasad => tr('महाप्रसाद भोजन', 'Food / Prasad');
  static String get navSecurity => tr('सुरक्षा व संपर्क', 'Security');
  static String get navGallery => tr('छायाचित्रे गॅलरी', 'Gallery');
  static String get navAarti => tr('आरती वेळापत्रक', 'Aarti');
  static String get navMatajiIdol => tr('माताजी मूर्ती तपशील', 'Mataji / Idol');
  static String get navVisarjan => tr('विसर्जन नियोजन', 'Visarjan');
  static String get navReports => tr('अहवाल व जमाखर्च', 'Reports');
  static String get navUsersRoles => tr('वापरकर्ते व्यवस्थापन', 'Users & Roles');
  static String get navBackupRestore => tr('बॅकअप व रिस्टोअर (.db)', 'Backup & Restore (.db)');
  static String get navSettings => tr('सेटिंग्ज', 'Settings');

  // Dashboard Metrics
  static String get totalDonations => tr('एकूण देणगी जमा', 'Total Donations');
  static String get totalExpenses => tr('एकूण खर्च', 'Total Expenses');
  static String get currentBalance => tr('शिल्लक रक्कम', 'Current Balance');
  static String get activeMembers => tr('एकूण सभासद', 'Active Members');
  static String get totalVolunteers => tr('एकूण कार्यकर्ते', 'Volunteers');
  static String get upcomingEvents => tr('आगामी कार्यक्रम', 'Upcoming Events');

  // Common UI Actions
  static String get addDonation => tr('+ देणगी जोडा', '+ Add Donation');
  static String get addExpense => tr('+ खर्च जोडा', '+ Add Expense');
  static String get addMember => tr('+ सभासद जोडा', '+ Add Member');
  static String get addEvent => tr('+ कार्यक्रम जोडा', '+ Add Event');
  static String get saveSettings => tr('सेटिंग्ज जतन करा', 'Save Settings');
  static String get changeLogo => tr('लोगो बदला', 'Change Logo');
  static String get search => tr('शोधा...', 'Search...');
  static String get noDataFound => tr('नोंद उपलब्ध नाही', 'No records found');
}
