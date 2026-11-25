import 'dart:async';
import 'package:andril_mobile/features/social/interests_preferences/domain/social_preferences_model.dart';
import 'package:andril_mobile/features/social/interests_preferences/presentation/social_preferences_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget createTestWidget({
  SocialPreferencesModel? initialPreferences,
  List<SocialInterestItem>? interestCatalog,
  VoidCallback? onBack,
  ValueChanged<SocialPreferencesModel>? onContinue,
  Future<bool> Function(SocialPreferencesModel preferences)? onSave,
}) {
  return MaterialApp(
    home: SocialPreferencesScreen(
      initialPreferences: initialPreferences,
      interestCatalog: interestCatalog,
      onBack: onBack,
      onContinue: onContinue,
      onSave: onSave,
    ),
  );
}

void main() {
  void setViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('SocialPreferencesModel Unit Tests (M5-FE-S03-QA-01)', () {
    test('default preferences model enforces valid defaults', () {
      const model = SocialPreferencesModel();
      expect(model.minAge, 18);
      expect(model.maxAge, 99);
      expect(model.maxDistanceKm, 50);
      expect(model.selectedInterests, isEmpty);
      expect(model.relationshipGoals, contains('Friendship'));
      expect(model.languages, contains('English'));
      expect(model.showMe, 'Everyone');
      expect(model.isValid, isFalse); // False because selectedInterests is empty
    });

    test('toggleInterest adds and removes interest IDs without duplicates', () {
      var model = const SocialPreferencesModel();
      model = model.toggleInterest('music');
      expect(model.selectedInterests, contains('music'));
      expect(model.selectedInterests.length, 1);
      expect(model.isValid, isTrue);

      // Duplicate addition via withInterest
      model = model.withInterest('music');
      expect(model.selectedInterests.length, 1);

      // Toggle off
      model = model.toggleInterest('music');
      expect(model.selectedInterests, isNot(contains('music')));
      expect(model.selectedInterests.length, 0);

      // withoutInterest
      model = model.withInterest('coffee');
      model = model.withoutInterest('coffee');
      expect(model.selectedInterests, isEmpty);
    });

    test('toggleRelationshipGoal and toggleLanguage operate immutably', () {
      var model = const SocialPreferencesModel(
        relationshipGoals: ['Friendship'],
        languages: ['English'],
      );

      model = model.toggleRelationshipGoal('Networking');
      expect(model.relationshipGoals, containsAll(['Friendship', 'Networking']));

      model = model.toggleRelationshipGoal('Friendship');
      expect(model.relationshipGoals, ['Networking']);

      model = model.toggleLanguage('Tamil');
      expect(model.languages, containsAll(['English', 'Tamil']));
    });

    test('enforces defensive collection immutability for goals, languages, and interests', () {
      const model = SocialPreferencesModel();
      expect(
        () => model.relationshipGoals.add('InvalidGoal'),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => model.relationshipGoals.clear(),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => model.languages.add('InvalidLang'),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => model.languages.clear(),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => model.selectedInterests.add('invalidInterest'),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => model.selectedInterests.clear(),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('equality and hashcode operate on set and list content', () {
      final model1 = const SocialPreferencesModel()
          .withInterest('music')
          .copyWith(minAge: 21);
      final model2 = const SocialPreferencesModel()
          .withInterest('music')
          .copyWith(minAge: 21);
      final model3 = const SocialPreferencesModel()
          .withInterest('books')
          .copyWith(minAge: 21);

      expect(model1, equals(model2));
      expect(model1.hashCode, equals(model2.hashCode));
      expect(model1, isNot(equals(model3)));
    });

    test('toString excludes sensitive diagnostic disclosure', () {
      final model = const SocialPreferencesModel().withInterest('music');
      final desc = model.toString();
      expect(desc, contains('selectedCount: 1'));
      expect(desc, contains('minAge: 18'));
      expect(desc, contains('distance: 50km'));
    });
  });

  group('SocialPreferencesScreen Widget Tests (M5-FE-S03-QA-01)', () {
    testWidgets('renders all discovery sections and initial controls without overflow',
        (tester) async {
      setViewport(tester);
      await tester.pumpWidget(createTestWidget());

      // Header
      expect(find.text('Interests & Preferences'), findsOneWidget);
      expect(find.text('Step 2 of 2 • Discovery Criteria'), findsOneWidget);
      expect(find.byKey(const Key('backButton')), findsOneWidget);

      // Sections
      expect(find.text('Social Interests *'), findsOneWidget);
      expect(find.text('0 selected'), findsOneWidget);
      expect(find.text('Preferred Age Range'), findsOneWidget);
      expect(find.text('18 – 99 years'), findsOneWidget);
      expect(find.text('Maximum Distance'), findsOneWidget);
      expect(find.text('Relationship Goals'), findsOneWidget);
      expect(find.text('Preferred Languages'), findsOneWidget);
      expect(find.text('Show Me'), findsOneWidget);

      // Continue button disabled initially because 0 interests selected
      final continueFinder = find.byKey(const Key('continueButton'));
      expect(continueFinder, findsOneWidget);
      final elevatedButton = tester.widget<ElevatedButton>(continueFinder);
      expect(elevatedButton.onPressed, isNull);

      // Invariants: No personality test elements
      expect(find.textContaining('Personality'), findsNothing);
      expect(find.textContaining('Quiz'), findsNothing);
    });

    testWidgets('selecting interests enables Continue button and updates counter',
        (tester) async {
      setViewport(tester);
      await tester.pumpWidget(createTestWidget());

      final musicChip = find.byKey(const Key('interestChip_music'));
      expect(musicChip, findsOneWidget);

      await tester.tap(musicChip);
      await tester.pump();

      expect(find.text('1 selected'), findsOneWidget);

      final continueFinder = find.byKey(const Key('continueButton'));
      final elevatedButton = tester.widget<ElevatedButton>(continueFinder);
      expect(elevatedButton.onPressed, isNotNull);

      // Deselect interest
      await tester.tap(musicChip);
      await tester.pump();

      expect(find.text('0 selected'), findsOneWidget);
      final elevatedButtonAfter =
          tester.widget<ElevatedButton>(continueFinder);
      expect(elevatedButtonAfter.onPressed, isNull);
    });

    testWidgets('tapping Back triggers onBack callback', (tester) async {
      setViewport(tester);
      bool backTapped = false;
      await tester.pumpWidget(createTestWidget(onBack: () => backTapped = true));

      await tester.tap(find.byKey(const Key('backButton')));
      await tester.pump();

      expect(backTapped, isTrue);
    });

    testWidgets('tapping Continue returns selected preferences model via onContinue',
        (tester) async {
      setViewport(tester);
      SocialPreferencesModel? resultModel;

      await tester.pumpWidget(createTestWidget(
        onContinue: (prefs) => resultModel = prefs,
      ));

      // Select an interest
      await tester.tap(find.byKey(const Key('interestChip_coffee')));
      await tester.pump();

      final continueButton = find.byKey(const Key('continueButton'));
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pump();

      expect(resultModel, isNotNull);
      expect(resultModel!.isInterestSelected('coffee'), isTrue);
      expect(resultModel!.selectedInterests.length, 1);
    });

    testWidgets('shows loading spinner when onSave is executing',
        (tester) async {
      setViewport(tester);
      final completer = Completer<bool>();

      await tester.pumpWidget(createTestWidget(
        initialPreferences:
            const SocialPreferencesModel().withInterest('tech'),
        onSave: (_) => completer.future,
      ));

      final continueButton = find.byKey(const Key('continueButton'));
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pump(); // Enter loading

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('renders error banner when onSave fails', (tester) async {
      setViewport(tester);
      await tester.pumpWidget(createTestWidget(
        initialPreferences:
            const SocialPreferencesModel().withInterest('art'),
        onSave: (_) async => false,
      ));

      final continueButton = find.byKey(const Key('continueButton'));
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Failed to save preferences. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('renders empty catalog fallback when interestCatalog is empty',
        (tester) async {
      setViewport(tester);
      await tester.pumpWidget(createTestWidget(
        interestCatalog: const [],
      ));

      expect(
        find.text('No interests available currently.'),
        findsOneWidget,
      );
    });

    testWidgets('choice chips toggle discovery scope correctly',
        (tester) async {
      setViewport(tester);
      SocialPreferencesModel? resultModel;

      await tester.pumpWidget(createTestWidget(
        initialPreferences:
            const SocialPreferencesModel().withInterest('fitness'),
        onContinue: (prefs) => resultModel = prefs,
      ));

      // Select Women
      final womenChip = find.byKey(const Key('showMeChip_Women'));
      await tester.ensureVisible(womenChip);
      await tester.tap(womenChip);
      await tester.pump();

      final continueButton = find.byKey(const Key('continueButton'));
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pump();

      expect(resultModel?.showMe, 'Women');
    });
  });
}

