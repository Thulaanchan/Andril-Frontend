import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:andril_mobile/shared_core/language_selection/data/repositories/shared_prefs_language_preference_repository.dart';
import 'package:andril_mobile/shared_core/language_selection/domain/models/app_language.dart';
import 'package:andril_mobile/shared_core/language_selection/domain/repositories/language_preference_repository.dart';
import 'package:andril_mobile/shared_core/language_selection/screens/choose_language_screen.dart';
import 'package:andril_mobile/shared_core/language_selection/viewmodels/language_selection_viewmodel.dart';
import 'package:andril_mobile/shared_core/onboarding/presentation/widgets/language_card.dart';

class FakeLanguagePreferenceRepository implements LanguagePreferenceRepository {
  String? _saved;

  @override
  Future<String?> getSavedLanguage() async => _saved;

  @override
  Future<void> saveLanguage(String languageCode) async {
    _saved = languageCode;
  }
}

void main() {
  group('SharedPrefsLanguagePreferenceRepository', () {
    test('saves and retrieves language code using SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = SharedPrefsLanguagePreferenceRepository();

      expect(await repository.getSavedLanguage(), isNull);
      await repository.saveLanguage('ta');
      expect(await repository.getSavedLanguage(), equals('ta'));
    });
  });

  group('LanguageSelectionViewModel', () {
    late FakeLanguagePreferenceRepository repository;
    late LanguageSelectionViewModel viewModel;

    setUp(() {
      repository = FakeLanguagePreferenceRepository();
      viewModel = LanguageSelectionViewModel(repository: repository);
    });

    test('defaults to English and allows selection', () {
      expect(viewModel.selectedLanguage, equals(AppLanguage.english));

      viewModel.selectLanguage(AppLanguage.tamil);
      expect(viewModel.selectedLanguage, equals(AppLanguage.tamil));

      viewModel.selectLanguage(AppLanguage.sinhala);
      expect(viewModel.selectedLanguage, equals(AppLanguage.sinhala));
    });

    test('persists selected language on saveAndContinue', () async {
      var successCalled = false;
      viewModel.selectLanguage(AppLanguage.sinhala);

      await viewModel.saveAndContinue(onSuccess: () {
        successCalled = true;
      });

      expect(successCalled, isTrue);
      expect(await repository.getSavedLanguage(), equals('si'));
    });
  });

  group('ChooseLanguageScreen Widget Tests', () {
    testWidgets('renders all three languages, info callout and Continue button',
        (tester) async {
      final repository = FakeLanguagePreferenceRepository();
      final viewModel = LanguageSelectionViewModel(repository: repository);

      await tester.pumpWidget(
        MaterialApp(
          home: ChooseLanguageScreen(
            viewModel: viewModel,
          ),
        ),
      );

      // Verify headings
      expect(find.text('Choose Your Language'), findsNWidgets(2));
      expect(find.text('Select your preferred language for Andril.'), findsOneWidget);

      // Verify language options
      expect(find.byType(LanguageCard), findsNWidgets(3));
      expect(find.text('English'), findsOneWidget);
      expect(find.text('தமிழ் — Tamil'), findsOneWidget);
      expect(find.text('සිංහල — Sinhala'), findsOneWidget);

      // Verify information callout
      expect(find.text('You can change your language later in Settings.'), findsOneWidget);

      // Verify Continue button
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('allows user to change selection and tap Continue',
        (tester) async {
      final repository = FakeLanguagePreferenceRepository();
      final viewModel = LanguageSelectionViewModel(repository: repository);
      var continueFired = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ChooseLanguageScreen(
            viewModel: viewModel,
            onContinue: () {
              continueFired = true;
            },
          ),
        ),
      );

      // Tap Tamil language card
      await tester.tap(find.text('தமிழ் — Tamil'));
      await tester.pumpAndSettle();

      expect(viewModel.selectedLanguage, equals(AppLanguage.tamil));

      // Tap Continue button
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(continueFired, isTrue);
      expect(await repository.getSavedLanguage(), equals('ta'));
    });
  });
}
