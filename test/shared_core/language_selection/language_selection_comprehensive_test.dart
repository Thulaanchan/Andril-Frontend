import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:andril_mobile/shared_core/language_selection/data/repositories/shared_prefs_language_preference_repository.dart';
import 'package:andril_mobile/shared_core/language_selection/domain/models/app_language.dart';

void main() {
  group('Task 02.01: Language Selection and Persistence Comprehensive Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial repository returns null when no language has been saved', () async {
      final repo = SharedPrefsLanguagePreferenceRepository();
      final saved = await repo.getSavedLanguage();
      expect(saved, isNull);
    });

    test('Persists and retrieves English (en) using key andril_m2_selected_language', () async {
      final repo = SharedPrefsLanguagePreferenceRepository();
      await repo.saveLanguage('en');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('andril_m2_selected_language'), equals('en'));

      final retrieved = await repo.getSavedLanguage();
      expect(retrieved, equals('en'));
      expect(AppLanguage.isValidCode(retrieved), isTrue);
    });

    test('Persists and retrieves Tamil (ta)', () async {
      final repo = SharedPrefsLanguagePreferenceRepository();
      await repo.saveLanguage('ta');

      final retrieved = await repo.getSavedLanguage();
      expect(retrieved, equals('ta'));
      expect(AppLanguage.isValidCode(retrieved), isTrue);
    });

    test('Persists and retrieves Sinhala (si)', () async {
      final repo = SharedPrefsLanguagePreferenceRepository();
      await repo.saveLanguage('si');

      final retrieved = await repo.getSavedLanguage();
      expect(retrieved, equals('si'));
      expect(AppLanguage.isValidCode(retrieved), isTrue);
    });

    test('Overwriting previous language selection persists the latest value', () async {
      final repo = SharedPrefsLanguagePreferenceRepository();
      await repo.saveLanguage('en');
      expect(await repo.getSavedLanguage(), equals('en'));

      await repo.saveLanguage('ta');
      expect(await repo.getSavedLanguage(), equals('ta'));

      await repo.saveLanguage('si');
      expect(await repo.getSavedLanguage(), equals('si'));
    });

    test('Invalid language code is rejected by AppLanguage validation', () {
      expect(AppLanguage.isValidCode('fr'), isFalse);
      expect(AppLanguage.isValidCode('de'), isFalse);
      expect(AppLanguage.isValidCode(''), isFalse);
      expect(AppLanguage.isValidCode(null), isFalse);
      expect(AppLanguage.isValidCode('tam'), isFalse);
    });

    test('AppLanguage enum values map to correct codes and titles', () {
      expect(AppLanguage.english.code, equals('en'));
      expect(AppLanguage.english.title, equals('English'));

      expect(AppLanguage.tamil.code, equals('ta'));
      expect(AppLanguage.tamil.title, contains('Tamil'));

      expect(AppLanguage.sinhala.code, equals('si'));
      expect(AppLanguage.sinhala.title, contains('Sinhala'));
    });

    test('AppLanguage fromCode resolves supported codes and falls back safely', () {
      expect(AppLanguage.fromCode('en'), equals(AppLanguage.english));
      expect(AppLanguage.fromCode('ta'), equals(AppLanguage.tamil));
      expect(AppLanguage.fromCode('si'), equals(AppLanguage.sinhala));
      expect(AppLanguage.fromCode('xyz'), equals(AppLanguage.english));
      expect(AppLanguage.fromCode(null), equals(AppLanguage.english));
    });
  });
}
