/// Official policy document representations for ANDRIL Member-02.
///
/// Supports Terms of Service (02.05), Privacy Policy (02.06), and Community Guidelines (02.07).
class PolicyDocument {
  const PolicyDocument({
    required this.id,
    required this.title,
    required this.version,
    required this.languageCode,
    required this.url,
    required this.summary,
    required this.content,
    this.effectiveDate = 'November 2026',
  });

  final String id;
  final String title;
  final String version;
  final String languageCode;
  final String url;
  final String summary;
  final String content;
  final String effectiveDate;

  static const String currentVersion = '2.1';
  static const String termsUrl = 'https://andril.app/policies/terms';
  static const String privacyUrl = 'https://andril.app/policies/privacy';
  static const String guidelinesUrl = 'https://andril.app/policies/community-guidelines';

  /// Terms of Service factory.
  factory PolicyDocument.termsOfService({String languageCode = 'en'}) {
    switch (languageCode) {
      case 'ta':
        return const PolicyDocument(
          id: 'terms_of_service',
          title: 'சேவை விதிமுறைகள்',
          version: currentVersion,
          languageCode: 'ta',
          url: termsUrl,
          summary: 'ANDRIL தளத்தைப் பயன்படுத்துவதற்கான விதிமுறைகள் மற்றும் நிபந்தனைகள்.',
          content: '1. கணக்கு பொறுப்புணர்வு\nபயனர்கள் தங்கள் கணக்கின் பாதுகாப்பு மற்றும் அங்கீகார விவரங்களுக்கு முழுப் பொறுப்பாவார்கள்.\n\n2. ஏற்றுக்கொள்ளக்கூடிய பயன்பாடு\nதவறான தகவல்களைப் பகிர்வதோ பிறரை அச்சுறுத்துவதோ கண்டிப்பாக தடை செய்யப்பட்டுள்ளது.\n\n3. சேவை மாற்றங்கள்\nபாதுகாப்பு மற்றும் தொழில்நுட்ப மேம்பாடுகளுக்காக சேவையில் திருத்தங்கள் செய்யப்படலாம்.',
        );
      case 'si':
        return const PolicyDocument(
          id: 'terms_of_service',
          title: 'සේවා නියමයන්',
          version: currentVersion,
          languageCode: 'si',
          url: termsUrl,
          summary: 'ANDRIL වේදිකාව භාවිතා කිරීමේ නීතිමය කොන්දේසි.',
          content: '1. ගිණුම් වගකීම\nපරිශීලකයන් තම ගිණුමේ රහස්‍යභාවය හා ක්‍රියාකාරකම් පිළිබඳ සම්පූර්ණ වගකීම දැරිය යුතුය.\n\n2. පිළිගත හැකි භාවිතය\nඅසත්‍ය තොරතුරු බෙදාහැරීම හෝ අන් අයට බාධා කිරීම තහනම් වේ.\n\n3. සේවා යාවත්කාලීන කිරීම්\nආරක්ෂාව සහ කාර්යක්ෂමතාව වෙනුවෙන් සේවාවන් සංශෝධනය විය හැක.',
        );
      case 'en':
      default:
        return const PolicyDocument(
          id: 'terms_of_service',
          title: 'Terms of Service',
          version: currentVersion,
          languageCode: 'en',
          url: termsUrl,
          summary: 'Standard terms governing your participation and usage across ANDRIL modules.',
          content: '1. Acceptance of Terms\nBy accessing or creating an account on ANDRIL, you agree to comply with and be bound by these Terms of Service.\n\n2. Account Eligibility\nYou must be at least 16 years of age to register and access learning or hobby modules, and at least 18 years of age to access social features.\n\n3. User Conduct and Responsibilities\nYou are responsible for maintaining the confidentiality of your credentials and for all activities that occur under your account.\n\n4. Termination\nANDRIL reserves the right to suspend or terminate accounts that violate community safety or policy agreements.',
        );
    }
  }

  /// Privacy Policy factory.
  factory PolicyDocument.privacyPolicy({String languageCode = 'en'}) {
    switch (languageCode) {
      case 'ta':
        return const PolicyDocument(
          id: 'privacy_policy',
          title: 'தனியுரிமைக் கொள்கை',
          version: currentVersion,
          languageCode: 'ta',
          url: privacyUrl,
          summary: 'உங்கள் தனிப்பட்ட தரவு எவ்வாறு பாதுகாப்பாக சேமிக்கப்பட்டு கையாளப்படுகிறது என்பதற்கான வழிகாட்டுதல்.',
          content: '1. தரவு சேகரிப்பு\nகணக்கு சரிபார்ப்பு மற்றும் தொகுதி தனிப்பயனாக்கலுக்காக தேவையான தகவல்கள் மட்டுமே சேகரிக்கப்படுகின்றன.\n\n2. தரவு பாதுகாப்பு\nஅனைத்து தனிப்பட்ட தகவல்களும் குறியாக்கம் செய்யப்பட்டு தனிப்பட்ட தரவுத்தளத்தில் பாதுகாக்கப்படுகின்றன.\n\n3. உங்கள் உரிமைகள்\nஉங்கள் சுயவிவரத் தகவல்களை எப்போது வேண்டுமானாலும் அணுகவும் புதுப்பிக்கவும் உரிமை உண்டு.',
        );
      case 'si':
        return const PolicyDocument(
          id: 'privacy_policy',
          title: 'පෞද්ගලිකත්ව ප්‍රතිපත්තිය',
          version: currentVersion,
          languageCode: 'si',
          url: privacyUrl,
          summary: 'ඔබේ පෞද්ගලික දත්ත ආරක්ෂා කිරීම සහ භාවිතය පිළිබඳ විස්තර.',
          content: '1. දත්ත රැස් කිරීම\nගිණුම සත්‍යාපනය සහ මොඩියුල පුද්ගලීකරණය සඳහා අත්‍යවශ්‍ය තොරතුරු පමණක් ලබා ගනු ලැබේ.\n\n2. දත්ත ආරක්ෂාව\nසියලුම පෞද්ගලික දත්ත කේතනය කර ආරක්ෂිතව තබා ගනු ලැබේ.\n\n3. ඔබේ අයිතිවාසිකම්\nඔබේ ගිණුම් තොරතුරු ඕනෑම වේලාවක වෙනස් කිරීමට හෝ සමාලෝචනය කිරීමට ඔබට හැකියාව ඇත.',
        );
      case 'en':
      default:
        return const PolicyDocument(
          id: 'privacy_policy',
          title: 'Privacy Policy',
          version: currentVersion,
          languageCode: 'en',
          url: privacyUrl,
          summary: 'How ANDRIL collects, protects, encrypts, and handles your personal demographics and data.',
          content: '1. Information We Collect\nWe collect identity information, date of birth for age verification, gender for demographic customization, and module preference selections.\n\n2. Data Security & Storage\nYour personal demographic data is isolated in private schema storage with Row Level Security (RLS) enforcement and end-to-end encryption in transit.\n\n3. Consent & Control\nYou retain full control over your privacy settings and may update your module preferences at any time.\n\n4. Third-Party Sharing\nWe do not sell, rent, or trade your personal data to any external commercial third parties.',
        );
    }
  }

  /// Community Guidelines factory.
  factory PolicyDocument.communityGuidelines({String languageCode = 'en'}) {
    switch (languageCode) {
      case 'ta':
        return const PolicyDocument(
          id: 'community_guidelines',
          title: 'சமூக வழிகாட்டுதல்கள்',
          version: currentVersion,
          languageCode: 'ta',
          url: guidelinesUrl,
          summary: 'அனைவருக்கும் பாதுகாப்பான, மரியாதைக்குரிய மற்றும் ஊக்கமளிக்கும் சூழலை உருவாக்குதல்.',
          content: '1. பரஸ்பர மரியாதை\nஅனைத்து பயனர்களுடனும் நாகரிகமாகவும் மரியாதையுடனும் தொடர்புகொள்ளுங்கள்.\n\n2. பாதுகாப்பு மற்றும் நம்பிக்கை\nதுன்புறுத்தல், தவறான நடத்தை மற்றும் தீங்கு விளைவிக்கும் செயல்கள் கடுமையாக தடை செய்யப்பட்டுள்ளன.\n\n3. உள்ளடக்கம் பகிர்தல்\nஆக்கபூர்வமான மற்றும் பயனுள்ள கற்றல் தகவல்களை மட்டுமே பகிருங்கள்.',
        );
      case 'si':
        return const PolicyDocument(
          id: 'community_guidelines',
          title: 'ප්‍රජා මාර්ගෝපදේශ',
          version: currentVersion,
          languageCode: 'si',
          url: guidelinesUrl,
          summary: 'ආරක්ෂිත, ගෞරවනීය සහ මිත්‍රශීලී පරිසරයක් පවත්වා ගැනීම සඳහා උපදෙස්.',
          content: '1. අන්‍යෝන්‍ය ගෞරවය\nසියලු සාමාජිකයන් සමඟ සුහදශීලීව හා ගෞරවයෙන් කටයුතු කරන්න.\n\n2. ආරක්ෂාව සහ විශ්වාසය\nකිසිදු ආකාරයක හිංසනයක් හෝ අනිසි හැසිරීමක් නොඉවසනු ඇත.\n\n3. නිර්මාණශීලී සහභාගීත්වය\nඅධ්‍යාපනික සහ ඵලදායී අදහස් පමණක් බෙදාහරින්න.',
        );
      case 'en':
      default:
        return const PolicyDocument(
          id: 'community_guidelines',
          title: 'Community Guidelines',
          version: currentVersion,
          languageCode: 'en',
          url: guidelinesUrl,
          summary: 'Principles of mutual respect, safety, constructive interaction, and inclusive collaboration.',
          content: '1. Mutual Respect\nTreat all community members with empathy, dignity, and courtesy across all discussion spaces and modules.\n\n2. Zero Tolerance for Harassment\nHarassment, hate speech, bullying, impersonation, or offensive conduct will result in immediate suspension.\n\n3. Constructive Collaboration\nEncourage peers, share meaningful knowledge, and maintain authentic participation in your chosen modules.\n\n4. Reporting Violations\nIf you observe behavior inconsistent with these guidelines, use the reporting mechanism to notify moderation.',
        );
    }
  }
}
