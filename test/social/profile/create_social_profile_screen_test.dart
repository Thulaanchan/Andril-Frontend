import 'dart:async';
import 'package:andril_mobile/features/social/profile/screens/create_social_profile_screen.dart';
import 'package:andril_mobile/features/social/profile/viewmodels/social_profile_draft.dart';
import 'package:andril_mobile/features/social/profile/viewmodels/social_profile_repository.dart';
import 'package:andril_mobile/features/social/profile/viewmodels/social_profile_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test-local repository double for widget interaction tests.
class FakeSocialProfileRepository implements SocialProfileRepository {
  SocialProfileResult? nextResult;
  Completer<SocialProfileResult>? pendingCompleter;
  int saveCallCount = 0;

  @override
  Future<SocialProfileResult> getProfileDraft() async {
    return const SocialProfileResult.success(SocialProfileDraft());
  }

  @override
  Future<SocialProfileResult> createProfileDraft() async {
    return const SocialProfileResult.success(SocialProfileDraft());
  }

  @override
  Future<SocialProfileResult> saveProfileDraft(SocialProfileDraft draft) async {
    saveCallCount++;
    if (pendingCompleter != null) {
      return pendingCompleter!.future;
    }
    return nextResult ?? SocialProfileResult.success(draft);
  }
}

Widget createTestWidget({
  required SocialProfileViewModel viewModel,
  VoidCallback? onBack,
  VoidCallback? onContinue,
}) {
  return MaterialApp(
    home: CreateSocialProfileScreen(
      viewModel: viewModel,
      onBack: onBack,
      onContinue: onContinue,
    ),
  );
}

void main() {
  late FakeSocialProfileRepository repository;
  late SocialProfileViewModel viewModel;

  setUp(() {
    repository = FakeSocialProfileRepository();
    viewModel = SocialProfileViewModel(repository: repository);
  });

  tearDown(() {
    viewModel.dispose();
  });

  void setViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('CreateSocialProfileScreen Widget Tests (M5-FE-S02-UI-02)', () {
    testWidgets('renders all initial S02 components without overflow',
        (tester) async {
      setViewport(tester);
      await tester.pumpWidget(createTestWidget(viewModel: viewModel));

      // Header components
      expect(find.text('Create Profile'), findsOneWidget);
      expect(find.text('Step 1 of 2 • Basic Information'), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);

      // Photo and text fields
      expect(find.text('Profile Photo (Private)'), findsOneWidget);
      expect(
          find.text('Kept private to authorized connections'), findsOneWidget);
      expect(find.byKey(const Key('displayNameField')), findsOneWidget);
      expect(find.byKey(const Key('bioField')), findsOneWidget);

      // Eligibility notice
      expect(
        find.textContaining(
            'Social profile drafts are restricted to confirmed adult participants'),
        findsOneWidget,
      );

      // Continue button disabled initially
      final continueButtonFinder = find.byKey(const Key('continueButton'));
      expect(continueButtonFinder, findsOneWidget);
      final elevatedButton =
          tester.widget<ElevatedButton>(continueButtonFinder);
      expect(elevatedButton.onPressed, isNull);

      // Absence of Personality Test controls
      expect(find.textContaining('Personality'), findsNothing);
      expect(find.textContaining('Quiz'), findsNothing);
      expect(find.textContaining('Questionnaire'), findsNothing);
    });

    testWidgets('entering valid display name enables Continue button',
        (tester) async {
      setViewport(tester);
      await tester.pumpWidget(createTestWidget(viewModel: viewModel));

      final nameField = find.byKey(const Key('displayNameField'));
      await tester.enterText(nameField, 'Thulaan');
      await tester.pump();

      expect(viewModel.draft.displayName, 'Thulaan');
      expect(viewModel.canSubmit, isTrue);

      final elevatedButton = tester
          .widget<ElevatedButton>(find.byKey(const Key('continueButton')));
      expect(elevatedButton.onPressed, isNotNull);
    });

    testWidgets('tapping Back triggers onBack callback', (tester) async {
      setViewport(tester);
      bool backPressed = false;
      await tester.pumpWidget(createTestWidget(
        viewModel: viewModel,
        onBack: () => backPressed = true,
      ));

      await tester.tap(find.byTooltip('Back'));
      await tester.pump();

      expect(backPressed, isTrue);
    });

    testWidgets('successful submission invokes onContinue', (tester) async {
      setViewport(tester);
      bool continuePressed = false;
      await tester.pumpWidget(createTestWidget(
        viewModel: viewModel,
        onContinue: () => continuePressed = true,
      ));

      await tester.enterText(
          find.byKey(const Key('displayNameField')), 'AliceValid');
      await tester.enterText(
          find.byKey(const Key('bioField')), 'Hello from tests!');
      await tester.pump();

      final continueButton = find.byKey(const Key('continueButton'));
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pump(); // Start save
      await tester.pumpAndSettle(); // Settle async

      expect(repository.saveCallCount, 1);
      expect(continuePressed, isTrue);
      expect(viewModel.isSuccess, isTrue);
    });

    testWidgets('shows loading indicator during active submission',
        (tester) async {
      setViewport(tester);
      final completer = Completer<SocialProfileResult>();
      repository.pendingCompleter = completer;

      await tester.pumpWidget(createTestWidget(viewModel: viewModel));
      await tester.enterText(
          find.byKey(const Key('displayNameField')), 'LoadingTest');
      await tester.pump();

      final continueButton = find.byKey(const Key('continueButton'));
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pump(); // Enter loading state

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete async
      completer.complete(SocialProfileResult.success(viewModel.draft));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders conflict banner when display name is taken',
        (tester) async {
      setViewport(tester);
      repository.nextResult = const SocialProfileResult.failure(
        SocialProfileFailure(
          type: SocialProfileFailureType.displayNameUnavailable,
          message: 'The display name "TakenName" is already in use.',
        ),
      );

      await tester.pumpWidget(createTestWidget(viewModel: viewModel));
      await tester.enterText(
          find.byKey(const Key('displayNameField')), 'TakenName');
      await tester.pump();

      final continueButton = find.byKey(const Key('continueButton'));
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(
        find.text('The display name "TakenName" is already in use.'),
        findsOneWidget,
      );
      expect(viewModel.isConflict, isTrue);
    });

    testWidgets('renders denied banner when adult authorization is denied',
        (tester) async {
      setViewport(tester);
      repository.nextResult = const SocialProfileResult.failure(
        SocialProfileFailure(
          type: SocialProfileFailureType.authorizationDenied,
          message: 'Adult eligibility is required to access Social features.',
        ),
      );

      await tester.pumpWidget(createTestWidget(viewModel: viewModel));
      await tester.enterText(
          find.byKey(const Key('displayNameField')), 'UnderageName');
      await tester.pump();

      final continueButton = find.byKey(const Key('continueButton'));
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Adult eligibility is required to access Social features.'),
        findsOneWidget,
      );
      expect(viewModel.isDenied, isTrue);
    });

    testWidgets('renders error banner on unexpected dependency failure',
        (tester) async {
      setViewport(tester);
      repository.nextResult = const SocialProfileResult.failure(
        SocialProfileFailure(
          type: SocialProfileFailureType.dependencyFailure,
          message: 'Backend service temporarily unavailable.',
        ),
      );

      await tester.pumpWidget(createTestWidget(viewModel: viewModel));
      await tester.enterText(
          find.byKey(const Key('displayNameField')), 'NetworkFail');
      await tester.pump();

      final continueButton = find.byKey(const Key('continueButton'));
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Backend service temporarily unavailable.'),
        findsOneWidget,
      );
      expect(viewModel.isError, isTrue);
    });

    testWidgets('tapping photo placeholder updates photo state',
        (tester) async {
      setViewport(tester);
      await tester.pumpWidget(createTestWidget(viewModel: viewModel));

      expect(viewModel.draft.profilePhotoPath, isNull);

      final photoFinder = find.bySemanticsLabel('Profile photo, private');
      expect(photoFinder, findsOneWidget);

      await tester.tap(photoFinder);
      await tester.pump();

      expect(viewModel.draft.profilePhotoPath, isNotNull);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });
  });
}
