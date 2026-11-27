import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/shared_core/language_selection/domain/models/app_language.dart';
import 'package:andril_mobile/shared_core/onboarding/presentation/localization/onboarding_localizations.dart';

void main() {
  group('Task 02.02: Onboarding Localization Tests (Screens 01 through 10)', () {
    test('English dictionary contains non-empty strings for all 10 screens', () {
      const l10n = OnboardingLocalizations(AppLanguage.english);

      // Screen 01 - Splash
      expect(l10n.splashTagline, equals('Every Path Begins Here'));

      // Screen 02 - Choose Language
      expect(l10n.languageTitle, equals('Choose Your Language'));
      expect(l10n.languageSubtitle, isNotEmpty);
      expect(l10n.continueButton, equals('Continue'));

      // Screen 03 - Welcome
      expect(l10n.welcomeHeading, equals('Welcome to Andril'));
      expect(l10n.createAccountButton, equals('Create Account'));
      expect(l10n.logInButton, equals('Log In'));

      // Screen 04 - Registration
      expect(l10n.registerTitle, equals('Create Account'));
      expect(l10n.emailLabel, equals('Email Address'));
      expect(l10n.passwordLabel, equals('Password'));

      // Screen 05 - Verification
      expect(l10n.verificationTitle, equals('Verify Your Email'));
      expect(l10n.resendCode, equals('Resend Code'));

      // Screen 06 - Login
      expect(l10n.loginTitle, equals('Welcome Back'));
      expect(l10n.forgotPasswordLink, equals('Forgot Password?'));
      expect(l10n.continueWithGoogle, equals('Continue with Google'));

      // Screen 07 - Password Recovery
      expect(l10n.forgotPasswordTitle, equals('Password Recovery'));
      expect(l10n.sendResetLinkButton, equals('Send Reset Link'));

      // Screen 08 - Password Reset
      expect(l10n.resetPasswordTitle, equals('Create New Password'));
      expect(l10n.confirmPasswordLabel, equals('Confirm Password'));

      // Screen 09 - Eligibility & Policies
      expect(l10n.eligibilityTitle, equals('Eligibility & Policies'));
      expect(l10n.termsOfServiceLink, equals('Terms of Service'));
      expect(l10n.privacyPolicyLink, equals('Privacy Policy'));
      expect(l10n.communityGuidelinesLink, equals('Community Guidelines'));
      expect(l10n.social18CalloutTitle, contains('18+'));

      // Screen 10 - Starter Module Selection
      expect(l10n.starterModuleTitle, equals('Choose Your Path'));
      expect(l10n.moduleLearning, equals('Learning'));
      expect(l10n.moduleHobbies, equals('Hobbies'));
      expect(l10n.moduleSocial, equals('Social'));
    });

    test('Tamil dictionary contains valid translated strings for all 10 screens', () {
      const l10n = OnboardingLocalizations(AppLanguage.tamil);

      expect(l10n.splashTagline, equals('ஒவ்வொரு பாதையும் இங்கே தொடங்குகிறது'));
      expect(l10n.languageTitle, equals('மொழியைத் தேர்ந்தெடுக்கவும்'));
      expect(l10n.continueButton, equals('தொடரவும்'));
      expect(l10n.welcomeHeading, equals('அன்றிலுக்கு நல்வரவு'));
      expect(l10n.createAccountButton, equals('கணக்கை உருவாக்கவும்'));
      expect(l10n.logInButton, equals('உள்நுழைக'));
      expect(l10n.registerTitle, equals('கணக்கை உருவாக்கவும்'));
      expect(l10n.verificationTitle, equals('மின்னஞ்சலைச் சரிபார்க்கவும்'));
      expect(l10n.loginTitle, equals('மீண்டும் நல்வரவு'));
      expect(l10n.forgotPasswordTitle, equals('கடவுச்சொல் மீட்பு'));
      expect(l10n.resetPasswordTitle, equals('புதிய கடவுச்சொல்லை உருவாக்கவும்'));
      expect(l10n.eligibilityTitle, equals('தகுதி மற்றும் கொள்கைகள்'));
      expect(l10n.termsOfServiceLink, equals('சேவை விதிமுறைகள்'));
      expect(l10n.privacyPolicyLink, equals('தனியுரிமைக் கொள்கை'));
      expect(l10n.communityGuidelinesLink, equals('சமூக வழிகாட்டுதல்கள்'));
      expect(l10n.starterModuleTitle, equals('உங்கள் பாதையைத் தேர்ந்தெடுக்கவும்'));
      expect(l10n.moduleLearning, equals('கற்றல்'));
      expect(l10n.moduleHobbies, equals('விருப்பங்கள்'));
      expect(l10n.moduleSocial, equals('சமூகம்'));
    });

    test('Sinhala dictionary contains valid translated strings for all 10 screens', () {
      const l10n = OnboardingLocalizations(AppLanguage.sinhala);

      expect(l10n.splashTagline, equals('සෑම ගමනක්ම මෙතැනින් ඇරඹේ'));
      expect(l10n.languageTitle, equals('ඔබගේ භාෂාව තෝරන්න'));
      expect(l10n.continueButton, equals('ඉදිරියට යන්න'));
      expect(l10n.welcomeHeading, equals('ඇන්ඩ්‍රිල් වෙත සාදරයෙන් පිළිගනිමු'));
      expect(l10n.createAccountButton, equals('ගිණුමක් සාදන්න'));
      expect(l10n.logInButton, equals('ඇතුල් වන්න'));
      expect(l10n.registerTitle, equals('ගිණුමක් සාදන්න'));
      expect(l10n.verificationTitle, equals('විද්‍යුත් තැපෑල තහවුරු කරන්න'));
      expect(l10n.loginTitle, equals('නැවත සාදරයෙන් පිළිගනිමු'));
      expect(l10n.forgotPasswordTitle, equals('මුරපදය නැවත ලබාගැනීම'));
      expect(l10n.resetPasswordTitle, equals('නව මුරපදයක් සාදන්න'));
      expect(l10n.eligibilityTitle, equals('සුදුසුකම් සහ ප්‍රතිපත්ති'));
      expect(l10n.termsOfServiceLink, equals('සේවා කොන්දේසි'));
      expect(l10n.privacyPolicyLink, equals('පෞද්ගලිකත්ව ප්‍රතිපත්තිය'));
      expect(l10n.communityGuidelinesLink, equals('ප්‍රජා මාර්ගෝපදේශ'));
      expect(l10n.starterModuleTitle, equals('ඔබේ මාවත තෝරන්න'));
      expect(l10n.moduleLearning, equals('ඉගෙනීම'));
      expect(l10n.moduleHobbies, equals('විනෝදාංශ'));
      expect(l10n.moduleSocial, equals('සමාජීය'));
    });
  });
}
