import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/common/diary/domain/diary_models.dart';
import 'package:andril_mobile/features/common/diary/presentation/screens/private_diary_screen.dart';

void _setupTestViewport(
  WidgetTester tester, {
  Size size = const Size(360, 800),
  double devicePixelRatio = 1.0,
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _buildTestHarness({
  required Widget child,
  Size size = const Size(360, 800),
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    theme: LearningTheme.theme,
    home: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: textScaler,
          ),
          child: child,
        ),
      ),
    ),
  );
}

Future<void> _safeTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('Private Diary (CF-13 / DIA-R01..R10) Domain & Presentation Tests', () {
    // =========================================================================
    // SECTION 1: DOMAIN MODEL TESTS
    // =========================================================================

    group('Domain Models: DiaryReflection, DiaryPlan, ModuleDiaryEntry', () {
      test('TEST-DIA-01: DiaryReflection validated construction and boundaries',
          () {
        final ref = DiaryReflection.validated(
          title: 'Architectural Decisions',
          body: 'Studied module isolation and fail-closed security.',
        );
        expect(ref.title, 'Architectural Decisions');
        expect(ref.body, 'Studied module isolation and fail-closed security.');
        expect(ref.toString(),
            'Private Diary reflection [title and body omitted]');

        // Title exceeding 100 characters throws ArgumentError
        expect(
          () => DiaryReflection.validated(
            title: 'A' * 101,
            body: 'Valid body',
          ),
          throwsArgumentError,
        );

        // Empty body throws ArgumentError
        expect(
          () => DiaryReflection.validated(body: '   '),
          throwsArgumentError,
        );

        // Body exceeding 10,000 characters throws ArgumentError
        expect(
          () => DiaryReflection.validated(body: 'B' * 10001),
          throwsArgumentError,
        );
      });

      test('TEST-DIA-02: DiaryPlan validated construction and boundaries', () {
        final plan = DiaryPlan.validated(
          id: 'p1',
          title: 'Review Clean Architecture',
          description: 'Focus on dependency inversion.',
        );
        expect(plan.id, 'p1');
        expect(plan.title, 'Review Clean Architecture');
        expect(plan.description, 'Focus on dependency inversion.');
        expect(plan.isCompleted, isFalse);
        expect(plan.toString(),
            'Private Diary plan [identity, title and description omitted]');

        // Toggle completed
        final toggled = plan.toggleCompleted();
        expect(toggled.isCompleted, isTrue);

        // Empty title throws ArgumentError
        expect(
          () => DiaryPlan.validated(title: '  '),
          throwsArgumentError,
        );

        // Title exceeding 120 chars throws ArgumentError
        expect(
          () => DiaryPlan.validated(title: 'T' * 121),
          throwsArgumentError,
        );

        // Description exceeding 1,000 chars throws ArgumentError
        expect(
          () => DiaryPlan.validated(title: 'Valid', description: 'D' * 1001),
          throwsArgumentError,
        );
      });

      test('TEST-DIA-03: DiaryCalendarResolver timezone and date contract', () {
        const resolver = DiaryCalendarResolver();

        // 1. Explicit date is preserved literally without timezone or clock conversion
        final explicit = DateTime.utc(2026, 11, 21);
        final resolvedExplicit = resolver.resolveDate(
          ianaTimeZone: 'America/New_York',
          explicitDate: explicit,
        );
        expect(resolvedExplicit, DateTime.utc(2026, 11, 21));

        // 2. Implicit date with valid IANA timezone
        final fixedUtc = DateTime.utc(
            2026, 11, 24, 19, 0, 0); // 7 PM UTC = 12:30 AM next day Colombo
        final resolvedColombo = resolver.resolveDate(
          ianaTimeZone: 'Asia/Colombo',
          utcNow: fixedUtc,
        );
        expect(resolvedColombo, DateTime.utc(2026, 11, 25));

        // 3. Implicit date with missing or invalid timezone returns null (no fallback to local time)
        expect(
            resolver.resolveDate(ianaTimeZone: null, utcNow: fixedUtc), isNull);
        expect(resolver.resolveDate(ianaTimeZone: '   ', utcNow: fixedUtc),
            isNull);
        expect(
            resolver.resolveDate(
                ianaTimeZone: 'Invalid/Private', utcNow: fixedUtc),
            isNull);
      });

      test('TEST-DIA-04: ModuleDiaryEntry boundaries and 20-plan limit', () {
        final entry = ModuleDiaryEntry.create(
          ownerModuleProfileId: 'owner_01',
          module: 'learning',
          date: DateTime.utc(2026, 11, 25),
        );
        expect(entry.ownerModuleProfileId, 'owner_01');
        expect(entry.module, 'learning');
        expect(entry.isPrivate, isTrue);
        expect(entry.plans, isEmpty);
        expect(entry.reflection, isNull);
        expect(entry.toString(),
            'Private module Diary entry [owner, module, date and content omitted]');

        // Set reflection
        final withRef =
            entry.setReflection('Daily Goal', 'Execute all widget tests.');
        expect(withRef.reflection?.title, 'Daily Goal');

        // Add 20 plans
        var current = withRef;
        for (int i = 0; i < 20; i++) {
          current = current
              .addPlan(DiaryPlan.validated(id: 'plan_$i', title: 'Task $i'));
        }
        expect(current.plans.length, 20);

        // 21st plan throws StateError
        expect(
          () => current
              .addPlan(DiaryPlan.validated(id: 'plan_21', title: 'Overflow')),
          throwsStateError,
        );

        // Duplicate plan ID throws ArgumentError
        expect(
          () => withRef
              .addPlan(DiaryPlan.validated(id: 'dup', title: 'First'))
              .addPlan(DiaryPlan.validated(id: 'dup', title: 'Second')),
          throwsArgumentError,
        );
      });
    });

    // =========================================================================
    // SECTION 2: WIDGET TESTS: INITIAL RENDERING & NAVIGATION
    // =========================================================================

    testWidgets(
        'TEST-DIA-05: Initial render displays module badge, private badge, date, and actions',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: PrivateDiaryScreen(
            currentUserId: 'test_owner_01',
            ownerModuleProfileId: 'test_owner_01',
            module: 'learning',
            initialDate: DateTime.utc(2026, 11, 25),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Private Diary'), findsOneWidget);
      expect(find.byKey(const Key('module_badge')), findsOneWidget);
      expect(find.text('LEARNING DIARY'), findsOneWidget);
      expect(find.byKey(const Key('privacy_badge_private')), findsOneWidget);
      expect(find.byKey(const Key('selected_date_display')), findsOneWidget);
      expect(find.text('Wednesday, November 25, 2026'), findsOneWidget);
      expect(find.byKey(const Key('save_diary_draft_button')), findsOneWidget);
    });

    testWidgets(
        'TEST-DIA-06: Date navigation updates date and triggers onDateChanged',
        (tester) async {
      _setupTestViewport(tester);

      DateTime? changedDate;

      await tester.pumpWidget(
        _buildTestHarness(
          child: PrivateDiaryScreen(
            currentUserId: 'test_owner_01',
            ownerModuleProfileId: 'test_owner_01',
            module: 'learning',
            initialDate: DateTime.utc(2026, 11, 25),
            onDateChanged: (d) => changedDate = d,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Previous Day
      await _safeTap(tester, find.byKey(const Key('prev_day_button')));
      expect(find.text('Tuesday, November 24, 2026'), findsOneWidget);
      expect(changedDate, DateTime.utc(2026, 11, 24));

      // Tap Next Day twice
      await _safeTap(tester, find.byKey(const Key('next_day_button')));
      await _safeTap(tester, find.byKey(const Key('next_day_button')));
      expect(find.text('Thursday, November 26, 2026'), findsOneWidget);
      expect(changedDate, DateTime.utc(2026, 11, 26));
    });

    // =========================================================================
    // SECTION 3: WIDGET TESTS: REFLECTION CREATION, EDITING & REMOVAL
    // =========================================================================

    testWidgets(
        'TEST-DIA-07: Add reflection opens editor and saves reflection to draft',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: PrivateDiaryScreen(
            currentUserId: 'test_owner_01',
            ownerModuleProfileId: 'test_owner_01',
            module: 'learning',
            initialDate: DateTime.utc(2026, 11, 25),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('no_reflection_placeholder')), findsOneWidget);

      // Open reflection editor
      await _safeTap(tester, find.byKey(const Key('add_reflection_button')));
      expect(find.byKey(const Key('reflection_card')), findsOneWidget);

      // Save with empty body triggers error banner
      await _safeTap(tester, find.byKey(const Key('save_reflection_button')));
      expect(find.byKey(const Key('error_banner')), findsOneWidget);
      expect(find.text('A non-blank reflection body is required.'),
          findsOneWidget);

      // Enter valid title and body
      await tester.enterText(
          find.byKey(const Key('diary_reflection_title_input')),
          'Daily System Design');
      await tester.enterText(
          find.byKey(const Key('diary_reflection_body_input')),
          'Practiced cache invalidation techniques.');
      await tester.pumpAndSettle();

      await _safeTap(tester, find.byKey(const Key('save_reflection_button')));
      expect(find.byKey(const Key('status_banner')), findsOneWidget);
      expect(
          find.text('Daily reflection saved to local draft.'), findsOneWidget);
      expect(find.byKey(const Key('remove_reflection_button')), findsOneWidget);
    });

    testWidgets(
        'TEST-DIA-08: Remove reflection clears reflection content and shows placeholder',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: PrivateDiaryScreen(
            currentUserId: 'test_owner_01',
            ownerModuleProfileId: 'test_owner_01',
            module: 'learning',
            initialDate: DateTime.utc(2026, 11, 25),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _safeTap(tester, find.byKey(const Key('add_reflection_button')));
      await tester.enterText(
          find.byKey(const Key('diary_reflection_body_input')),
          'Temporary thought.');
      await _safeTap(tester, find.byKey(const Key('save_reflection_button')));

      // Remove reflection
      await _safeTap(tester, find.byKey(const Key('remove_reflection_button')));
      expect(
          find.byKey(const Key('no_reflection_placeholder')), findsOneWidget);
      expect(find.text('Daily reflection removed from draft.'), findsOneWidget);
    });

    // =========================================================================
    // SECTION 4: WIDGET TESTS: PLANS CRUD & 20-PLAN LIMIT
    // =========================================================================

    testWidgets('TEST-DIA-09: Add plan validates title and displays plan card',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: PrivateDiaryScreen(
            currentUserId: 'test_owner_01',
            ownerModuleProfileId: 'test_owner_01',
            module: 'learning',
            initialDate: DateTime.utc(2026, 11, 25),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('empty_plans_card')), findsOneWidget);

      // Open add plan form
      await _safeTap(tester, find.byKey(const Key('add_plan_button')));
      expect(find.byKey(const Key('plan_form_card')), findsOneWidget);

      // Empty title triggers error banner
      await _safeTap(tester, find.byKey(const Key('save_plan_button')));
      expect(find.byKey(const Key('error_banner')), findsOneWidget);
      expect(find.text('A non-blank Diary plan title is required.'),
          findsOneWidget);

      // Enter valid plan title and description
      await tester.enterText(
          find.byKey(const Key('plan_title_input')), 'Complete Task 04-06');
      await tester.enterText(find.byKey(const Key('plan_desc_input')),
          'Implement Private Diary interface and unit tests.');
      await tester.pumpAndSettle();

      await _safeTap(tester, find.byKey(const Key('save_plan_button')));
      expect(find.byKey(const Key('empty_plans_card')), findsNothing);
      expect(find.text('Complete Task 04-06'), findsOneWidget);
      expect(find.text('Implement Private Diary interface and unit tests.'),
          findsOneWidget);
      expect(find.text('Daily Plans (1/20)'), findsOneWidget);
    });

    testWidgets('TEST-DIA-10: Toggle plan completion and delete plan entry',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: PrivateDiaryScreen(
            currentUserId: 'test_owner_01',
            ownerModuleProfileId: 'test_owner_01',
            module: 'learning',
            initialDate: DateTime.utc(2026, 11, 25),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Add a plan
      await _safeTap(tester, find.byKey(const Key('add_plan_button')));
      await tester.enterText(
          find.byKey(const Key('plan_title_input')), 'Task to complete');
      await _safeTap(tester, find.byKey(const Key('save_plan_button')));

      // Toggle plan checkbox
      final checkboxFinder = find.byType(Checkbox);
      expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);

      await _safeTap(tester, checkboxFinder);
      expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);

      // Delete plan
      final deleteFinder = find.byIcon(Icons.delete_outline);
      await _safeTap(tester, deleteFinder);

      expect(find.byKey(const Key('empty_plans_card')), findsOneWidget);
      expect(find.text('Daily Plans (0/20)'), findsOneWidget);
    });

    // =========================================================================
    // SECTION 5: ACCESS SECURITY & MODULE ISOLATION
    // =========================================================================

    testWidgets(
        'TEST-DIA-11: Access denied when currentUserId != ownerModuleProfileId',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const PrivateDiaryScreen(
            currentUserId: 'unauthorized_user_99',
            ownerModuleProfileId: 'test_owner_01',
            module: 'learning',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('access_denied_card')), findsOneWidget);
      expect(find.text('Access Denied'), findsOneWidget);
      expect(find.byKey(const Key('calendar_navigation_bar')), findsNothing);
    });

    testWidgets('TEST-DIA-12: Access denied when module is not learning',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const PrivateDiaryScreen(
            currentUserId: 'test_owner_01',
            ownerModuleProfileId: 'test_owner_01',
            module: 'social', // Module mismatch
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('access_denied_card')), findsOneWidget);
    });

    testWidgets('TEST-DIA-13: Loading state renders loading indicator',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const PrivateDiaryScreen(
            currentUserId: 'test_owner_01',
            ownerModuleProfileId: 'test_owner_01',
            isLoading: true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('loading_indicator')), findsOneWidget);
      expect(find.byKey(const Key('calendar_navigation_bar')), findsNothing);
    });

    // =========================================================================
    // SECTION 6: DRAFT PRESERVATION & PERSISTENCE NOTICE
    // =========================================================================

    testWidgets(
        'TEST-DIA-14: Save Diary Draft displays verified pending notice and invokes callback',
        (tester) async {
      _setupTestViewport(tester);

      ModuleDiaryEntry? savedEntry;

      await tester.pumpWidget(
        _buildTestHarness(
          child: PrivateDiaryScreen(
            currentUserId: 'test_owner_01',
            ownerModuleProfileId: 'test_owner_01',
            module: 'learning',
            initialDate: DateTime.utc(2026, 11, 25),
            onSaveDraft: (ModuleDiaryEntry entry) => savedEntry = entry,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _safeTap(tester, find.byKey(const Key('save_diary_draft_button')));

      expect(savedEntry, isNotNull);
      expect(savedEntry!.ownerModuleProfileId, 'test_owner_01');
      expect(savedEntry!.module, 'learning');
      expect(savedEntry!.date, DateTime.utc(2026, 11, 25));
      expect(savedEntry!.isPrivate, isTrue);

      expect(find.byKey(const Key('status_banner')), findsOneWidget);
      expect(
        find.text(
            'Diary entry saved locally. Remote repository persistence contract pending.'),
        findsOneWidget,
      );
    });

    // =========================================================================
    // SECTION 7: RESPONSIVENESS (320dp, 360dp, 412dp) & 1.5x TEXT SCALE
    // =========================================================================

    testWidgets(
        'TEST-DIA-15: Responsive layout renders across 320dp, 360dp, 412dp without overflow',
        (tester) async {
      for (final size in [
        const Size(320, 640),
        const Size(360, 800),
        const Size(412, 915),
      ]) {
        _setupTestViewport(tester, size: size);

        await tester.pumpWidget(
          _buildTestHarness(
            size: size,
            child: PrivateDiaryScreen(
              currentUserId: 'test_owner_01',
              ownerModuleProfileId: 'test_owner_01',
              module: 'learning',
              initialDate: DateTime.utc(2026, 11, 25),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
            find.byKey(const Key('calendar_navigation_bar')), findsOneWidget);
      }
    });

    testWidgets('TEST-DIA-16: 1.5x dynamic text scale renders without overflow',
        (tester) async {
      _setupTestViewport(tester, size: const Size(360, 800));

      await tester.pumpWidget(
        _buildTestHarness(
          size: const Size(360, 800),
          textScaler: const TextScaler.linear(1.5),
          child: PrivateDiaryScreen(
            currentUserId: 'test_owner_01',
            ownerModuleProfileId: 'test_owner_01',
            module: 'learning',
            initialDate: DateTime.utc(2026, 11, 25),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('calendar_navigation_bar')), findsOneWidget);
    });
  });
}
