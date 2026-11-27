import 'package:flutter/widgets.dart';
import '../../../language_selection/domain/models/app_language.dart';

/// Comprehensive localization dictionary for all Member-02 Onboarding screens (Screens 01 through 10).
///
/// Supports English (`en`), Tamil (`ta`), and Sinhala (`si`).
/// Provides natural, culturally appropriate, and phonetically verified translations
/// with graceful fallback to English.
class OnboardingLocalizations {
  const OnboardingLocalizations(this.language);

  final AppLanguage language;

  static OnboardingLocalizations of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final appLang = AppLanguage.tryFromCode(locale.languageCode) ?? AppLanguage.english;
    return OnboardingLocalizations(appLang);
  }

  static OnboardingLocalizations forLanguage(AppLanguage language) {
    return OnboardingLocalizations(language);
  }

  static OnboardingLocalizations forCode(String? code) {
    return OnboardingLocalizations(AppLanguage.fromCode(code));
  }

  // --- Common Actions & Buttons ---
  String get continueButton => switch (language) {
        AppLanguage.tamil => 'தொடரவும்',
        AppLanguage.sinhala => 'ඉදිරියට යන්න',
        AppLanguage.english => 'Continue',
      };

  String get backButton => switch (language) {
        AppLanguage.tamil => 'பின்னே',
        AppLanguage.sinhala => 'ආපසු',
        AppLanguage.english => 'Back',
      };

  String get okButton => switch (language) {
        AppLanguage.tamil => 'சரி',
        AppLanguage.sinhala => 'හරි',
        AppLanguage.english => 'OK',
      };

  String get cancelButton => switch (language) {
        AppLanguage.tamil => 'ரத்துசெய்',
        AppLanguage.sinhala => 'අවලංගු කරන්න',
        AppLanguage.english => 'Cancel',
      };

  String get retryButton => switch (language) {
        AppLanguage.tamil => 'மீண்டும் முயற்சிக்கவும்',
        AppLanguage.sinhala => 'නැවත උත්සාහ කරන්න',
        AppLanguage.english => 'Retry',
      };

  String get closeButton => switch (language) {
        AppLanguage.tamil => 'மூடு',
        AppLanguage.sinhala => 'වසන්න',
        AppLanguage.english => 'Close',
      };

  // --- Screen 01: Splash Screen ---
  String get splashTagline => switch (language) {
        AppLanguage.tamil => 'ஒவ்வொரு பாதையும் இங்கே தொடங்குகிறது',
        AppLanguage.sinhala => 'සෑම ගමනක්ම මෙතැනින් ඇරඹේ',
        AppLanguage.english => 'Every Path Begins Here',
      };

  // --- Screen 02: Language Selection Screen ---
  String get languageTitle => switch (language) {
        AppLanguage.tamil => 'மொழியைத் தேர்ந்தெடுக்கவும்',
        AppLanguage.sinhala => 'ඔබගේ භාෂාව තෝරන්න',
        AppLanguage.english => 'Choose Your Language',
      };

  String get languageSubtitle => switch (language) {
        AppLanguage.tamil => 'Andril பயன்பாட்டிற்கான உங்கள் விருப்ப மொழியைத் தேர்ந்தெடுக்கவும்.',
        AppLanguage.sinhala => 'Andril සඳහා ඔබ කැමති භාෂාව තෝරන්න.',
        AppLanguage.english => 'Select your preferred language for Andril.',
      };

  String get languageCallout => switch (language) {
        AppLanguage.tamil => 'நீங்கள் பின்னர் அமைப்புகளில் உங்கள் மொழியை மாற்றலாம்.',
        AppLanguage.sinhala => 'ඔබට පසුව සැකසීම් තුළින් භාෂාව වෙනස් කළ හැක.',
        AppLanguage.english => 'You can change your language later in Settings.',
      };

  // --- Screen 03: Welcome Screen ---
  String get welcomeHeading => switch (language) {
        AppLanguage.tamil => 'அன்றிலுக்கு நல்வரவு',
        AppLanguage.sinhala => 'ඇන්ඩ්‍රිල් වෙත සාදරයෙන් පිළිගනිමු',
        AppLanguage.english => 'Welcome to Andril',
      };

  String get welcomeDescription => switch (language) {
        AppLanguage.tamil =>
          'ஒரே கணக்கு, உங்கள் கற்றல், விருப்பங்கள் மற்றும் சமூகத் தொடர்புகளுக்கு மூன்று தனித்தனி இடங்கள்.',
        AppLanguage.sinhala =>
          'එක් ගිණුමක්, ඔබගේ ඉගෙනීම, විනෝදාංශ සහ සමාජ සම්බන්ධතා සඳහා ස්වාධීන අවකාශ තුනක්.',
        AppLanguage.english =>
          'One account, three independent spaces for your\nlearning, hobbies and social connections.',
      };

  String get createAccountButton => switch (language) {
        AppLanguage.tamil => 'கணக்கை உருவாக்கவும்',
        AppLanguage.sinhala => 'ගිණුමක් සාදන්න',
        AppLanguage.english => 'Create Account',
      };

  String get logInButton => switch (language) {
        AppLanguage.tamil => 'உள்நுழைக',
        AppLanguage.sinhala => 'ඇතුල් වන්න',
        AppLanguage.english => 'Log In',
      };

  // --- Screen 04: Registration Screen ---
  String get registerTitle => switch (language) {
        AppLanguage.tamil => 'கணக்கை உருவாக்கவும்',
        AppLanguage.sinhala => 'ගිණුමක් සාදන්න',
        AppLanguage.english => 'Create Account',
      };

  String get registerSubtitle => switch (language) {
        AppLanguage.tamil => 'ஒரு பாதுகாப்பான கணக்குடன் உங்கள் பயணத்தைத் தொடங்குங்கள்.',
        AppLanguage.sinhala => 'එක් ආරක්ෂිත ගිණුමකින් ඔබගේ ගමන අරඹන්න.',
        AppLanguage.english => 'Start your journey with one secure account.',
      };

  String get emailLabel => switch (language) {
        AppLanguage.tamil => 'மின்னஞ்சல் முகவரி',
        AppLanguage.sinhala => 'විද්‍යුත් තැපෑල',
        AppLanguage.english => 'Email Address',
      };

  String get passwordLabel => switch (language) {
        AppLanguage.tamil => 'கடவுச்சொல்',
        AppLanguage.sinhala => 'මුරපදය',
        AppLanguage.english => 'Password',
      };

  String get confirmPasswordLabel => switch (language) {
        AppLanguage.tamil => 'கடவுச்சொல்லை உறுதிப்படுத்தவும்',
        AppLanguage.sinhala => 'මුරපදය තහවුරු කරන්න',
        AppLanguage.english => 'Confirm Password',
      };

  // --- Screen 05: Account Verification Screen ---
  String get verificationTitle => switch (language) {
        AppLanguage.tamil => 'மின்னஞ்சலைச் சரிபார்க்கவும்',
        AppLanguage.sinhala => 'විද්‍යුත් තැපෑල තහවුරු කරන්න',
        AppLanguage.english => 'Verify Your Email',
      };

  String get verificationSubtitle => switch (language) {
        AppLanguage.tamil => 'உங்கள் மின்னஞ்சலுக்கு அனுப்பப்பட்ட 6-இலக்கக் குறியீட்டை உள்ளிடவும்.',
        AppLanguage.sinhala => 'ඔබගේ විද්‍යුත් තැපෑලට එවන ලද ඉලක්කම් 6 කේතය ඇතුළත් කරන්න.',
        AppLanguage.english => 'Enter the 6-digit code sent to your email.',
      };

  String get resendCode => switch (language) {
        AppLanguage.tamil => 'குறியீட்டை மீண்டும் அனுப்பவும்',
        AppLanguage.sinhala => 'කේතය නැවත එවන්න',
        AppLanguage.english => 'Resend Code',
      };

  // --- Screen 06: Login Screen ---
  String get loginTitle => switch (language) {
        AppLanguage.tamil => 'மீண்டும் நல்வரவு',
        AppLanguage.sinhala => 'නැවත සාදරයෙන් පිළිගනිමු',
        AppLanguage.english => 'Welcome Back',
      };

  String get loginSubtitle => switch (language) {
        AppLanguage.tamil => 'தொடர உங்கள் அன்றில் கணக்கில் உள்நுழைக.',
        AppLanguage.sinhala => 'ඉදිරියට යාමට ඔබගේ ඇන්ඩ්‍රිල් ගිණුමට ඇතුල් වන්න.',
        AppLanguage.english => 'Sign in to your Andril account to continue.',
      };

  String get forgotPasswordLink => switch (language) {
        AppLanguage.tamil => 'கடவுச்சொல் மறந்துவிட்டதா?',
        AppLanguage.sinhala => 'මුරපදය අමතකද?',
        AppLanguage.english => 'Forgot Password?',
      };

  String get continueWithGoogle => switch (language) {
        AppLanguage.tamil => 'Google உடன் தொடரவும்',
        AppLanguage.sinhala => 'Google සමඟ ඉදිරියට යන්න',
        AppLanguage.english => 'Continue with Google',
      };

  // --- Screen 07: Forgot Password Screen ---
  String get forgotPasswordTitle => switch (language) {
        AppLanguage.tamil => 'கடவுச்சொல் மீட்பு',
        AppLanguage.sinhala => 'මුරපදය නැවත ලබාගැනීම',
        AppLanguage.english => 'Password Recovery',
      };

  String get forgotPasswordSubtitle => switch (language) {
        AppLanguage.tamil => 'மீட்டமைப்பு இணைப்பைப் பெற உங்கள் மின்னஞ்சலை உள்ளிடவும்.',
        AppLanguage.sinhala => 'මුරපදය යළි පිහිටුවීමේ සබැඳිය ලබා ගැනීමට ඔබගේ විද්‍යුත් තැපෑල ඇතුළත් කරන්න.',
        AppLanguage.english => 'Enter your email to receive a password reset link.',
      };

  String get sendResetLinkButton => switch (language) {
        AppLanguage.tamil => 'மீட்டமைப்பு இணைப்பை அனுப்புக',
        AppLanguage.sinhala => 'යළි පිහිටුවීමේ සබැඳිය එවන්න',
        AppLanguage.english => 'Send Reset Link',
      };

  // --- Screen 08: Reset Password Screen ---
  String get resetPasswordTitle => switch (language) {
        AppLanguage.tamil => 'புதிய கடவுச்சொல்லை உருவாக்கவும்',
        AppLanguage.sinhala => 'නව මුරපදයක් සාදන්න',
        AppLanguage.english => 'Create New Password',
      };

  String get resetPasswordSubtitle => switch (language) {
        AppLanguage.tamil => 'உங்கள் கணக்கிற்குப் புதிய வலுவான கடவுச்சொல்லை உள்ளிடவும்.',
        AppLanguage.sinhala => 'ඔබගේ ගිණුම සඳහා ශක්තිමත් නව මුරපදයක් ඇතුළත් කරන්න.',
        AppLanguage.english => 'Enter a strong new password for your account.',
      };

  // --- Screen 09: Eligibility & Policies Screen ---
  String get eligibilityTitle => switch (language) {
        AppLanguage.tamil => 'தகுதி மற்றும் கொள்கைகள்',
        AppLanguage.sinhala => 'සුදුසුකම් සහ ප්‍රතිපත්ති',
        AppLanguage.english => 'Eligibility & Policies',
      };

  String get beforeYouContinue => switch (language) {
        AppLanguage.tamil => 'தொடர்வதற்கு முன்',
        AppLanguage.sinhala => 'ඉදිරියට යාමට පෙර',
        AppLanguage.english => 'Before You Continue',
      };

  String get eligibilitySubtitle => switch (language) {
        AppLanguage.tamil => 'உங்கள் பாதுகாப்பை உறுதிப்படுத்த சில முக்கியமான விவரங்கள்.',
        AppLanguage.sinhala => 'ඔබගේ ආරක්ෂාව තහවුරු කිරීමට වැදගත් තොරතුරු කිහිපයක්.',
        AppLanguage.english => 'A few important details to keep you safe and welcoming.',
      };

  String get social18CalloutTitle => switch (language) {
        AppLanguage.tamil => 'சமூகம் 18+ வயதுக்கு மட்டுமே',
        AppLanguage.sinhala => 'සමාජීය අංශය 18+ සඳහා පමණි',
        AppLanguage.english => 'Social is 18+ only',
      };

  String get social18CalloutSubtitle => switch (language) {
        AppLanguage.tamil => '18 வயதுக்கு உட்பட்டவரா? நீங்கள் கற்றல் மற்றும் விருப்பங்களை ஆராயலாம்.',
        AppLanguage.sinhala => '18 ට අඩුද? ඔබට තවමත් ඉගෙනීම සහ විනෝදාංශ ගවේෂණය කළ හැක.',
        AppLanguage.english => 'Under 18? You can still explore Learning and Hobbies.',
      };

  String get communityGuidelinesCard => switch (language) {
        AppLanguage.tamil => 'எங்கள் சமூகம் மரியாதை மற்றும் பாதுகாப்பை மதிக்கிறது. ',
        AppLanguage.sinhala => 'අපගේ ප්‍රජාව ගෞරවය සහ ආරක්ෂාව අගය කරයි. ',
        AppLanguage.english => 'Our community values respect and safety. ',
      };

  String get communityGuidelinesLink => switch (language) {
        AppLanguage.tamil => 'சமூக வழிகாட்டுதல்கள்',
        AppLanguage.sinhala => 'ප්‍රජා මාර්ගෝපදේශ',
        AppLanguage.english => 'Community Guidelines',
      };

  String get dateOfBirthLabel => switch (language) {
        AppLanguage.tamil => 'பிறந்த தேதி',
        AppLanguage.sinhala => 'උපන් දිනය',
        AppLanguage.english => 'Date of Birth',
      };

  String get selectDateOfBirthHint => switch (language) {
        AppLanguage.tamil => 'உங்கள் பிறந்த தேதியைத் தேர்ந்தெடுக்கவும்',
        AppLanguage.sinhala => 'ඔබගේ උපන් දිනය තෝරන්න',
        AppLanguage.english => 'Select your date of birth',
      };

  String get genderLabel => switch (language) {
        AppLanguage.tamil => 'பாலினம்',
        AppLanguage.sinhala => 'ස්ත්‍රී / පුරුෂ භාවය',
        AppLanguage.english => 'Gender',
      };

  String get selectGenderHint => switch (language) {
        AppLanguage.tamil => 'உங்கள் பாலினத்தைத் தேர்ந்தெடுக்கவும்',
        AppLanguage.sinhala => 'ඔබගේ ස්ත්‍රී/පුරුෂ භාවය තෝරන්න',
        AppLanguage.english => 'Select your gender',
      };

  String get termsAgreementPrefix => switch (language) {
        AppLanguage.tamil => 'நான் ஒப்புக்கொள்கிறேன்: ',
        AppLanguage.sinhala => 'මම එකඟ වෙමි: ',
        AppLanguage.english => 'I agree to the ',
      };

  String get termsOfServiceLink => switch (language) {
        AppLanguage.tamil => 'சேவை விதிமுறைகள்',
        AppLanguage.sinhala => 'සේවා කොන්දේසි',
        AppLanguage.english => 'Terms of Service',
      };

  String get privacyAgreementPrefix => switch (language) {
        AppLanguage.tamil => 'நான் மதிப்பாய்வு செய்துள்ளேன்: ',
        AppLanguage.sinhala => 'මම සමාලෝචනය කළෙමි: ',
        AppLanguage.english => 'I have reviewed the ',
      };

  String get privacyPolicyLink => switch (language) {
        AppLanguage.tamil => 'தனியுரிமைக் கொள்கை',
        AppLanguage.sinhala => 'පෞද්ගලිකත්ව ප්‍රතිපත්තිය',
        AppLanguage.english => 'Privacy Policy',
      };

  // --- Screen 10: Starter Module Selection Screen ---
  String get starterModuleTitle => switch (language) {
        AppLanguage.tamil => 'உங்கள் பாதையைத் தேர்ந்தெடுக்கவும்',
        AppLanguage.sinhala => 'ඔබේ මාවත තෝරන්න',
        AppLanguage.english => 'Choose Your Path',
      };

  String get starterModuleSubtitle => switch (language) {
        AppLanguage.tamil => 'உங்கள் தொடக்கப் பகுதியைத் தேர்ந்தெடுக்கவும். மற்றவைகளை பின்னர் அணுகலாம்.',
        AppLanguage.sinhala => 'ආරම්භක අංශය තෝරන්න. අනෙක් ඒවා පසුව සක්‍රිය කළ හැක.',
        AppLanguage.english => 'Select your starting space. You can unlock others anytime.',
      };

  String get moduleLearning => switch (language) {
        AppLanguage.tamil => 'கற்றல்',
        AppLanguage.sinhala => 'ඉගෙනීම',
        AppLanguage.english => 'Learning',
      };

  String get moduleHobbies => switch (language) {
        AppLanguage.tamil => 'விருப்பங்கள்',
        AppLanguage.sinhala => 'විනෝදාංශ',
        AppLanguage.english => 'Hobbies',
      };

  String get moduleSocial => switch (language) {
        AppLanguage.tamil => 'சமூகம்',
        AppLanguage.sinhala => 'සමාජීය',
        AppLanguage.english => 'Social',
      };

  String get socialModalTitle => switch (language) {
        AppLanguage.tamil => '18+ சமூக அனுமதி',
        AppLanguage.sinhala => '18+ සමාජීය අවසරය',
        AppLanguage.english => '18+ Social Agreement',
      };

  String get socialModalBody => switch (language) {
        AppLanguage.tamil =>
          'சமூகப் பகுதி 18 வயது அல்லது அதற்கு மேற்பட்ட வயதுடைய உறுப்பினர்களுக்கு மட்டுமே. உங்கள் சமூக சுயவிவரம் மற்ற தொகுதிகளிலிருந்து தனித்தனியாக இருக்கும்.',
        AppLanguage.sinhala =>
          'සමාජීය අංශය වයස අවුරුදු 18 හෝ ඊට වැඩි සාමාජිකයින් සඳහා පමණි. ඔබගේ සමාජීය පැතිකඩ අනෙකුත් අංශවලින් ස්වාධීනව තබා ගනු ඇත.',
        AppLanguage.english =>
          'The Social module is exclusive to members aged 18 and older. Your social profile will be kept completely private and distinct from other modules.',
      };

  String get socialConsentCheckbox => switch (language) {
        AppLanguage.tamil => 'எனக்கு 18 அல்லது அதற்கு மேற்பட்ட வயது என்பதை உறுதிப்படுத்துகிறேன்.',
        AppLanguage.sinhala => 'මම වයස අවුරුදු 18 ක් හෝ ඊට වැඩි බව තහවුරු කරමි.',
        AppLanguage.english => 'I confirm that I am 18 years of age or older.',
      };
}
