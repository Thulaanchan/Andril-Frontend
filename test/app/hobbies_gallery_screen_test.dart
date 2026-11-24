import 'package:andril_mobile/app/themes/hobbies/hobbies_colors.dart';
import 'package:andril_mobile/app/themes/hobbies/hobbies_theme.dart';
import 'package:andril_mobile/app/themes/hobbies/hobbies_typography.dart';
import 'package:andril_mobile/features/hobbies/presentation/screens/hobbies_gallery_screen.dart';
import 'package:andril_mobile/features/hobbies/presentation/widgets/andril_hobbies_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HobbiesGalleryScreen — Required Checkpoint Tests (M3-CP-02A)', () {
    // 1. Gallery screen renders successfully
    testWidgets('1. Gallery screen renders successfully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HobbiesGalleryScreen(),
        ),
      );

      expect(find.byType(HobbiesGalleryScreen), findsOneWidget);
      expect(find.text('Hobbies Media Gallery'), findsOneWidget);
      expect(find.text(HobbiesGalleryScreen.defaultSubtitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 2. Existing Hobbies scaffold is reused
    testWidgets('2. Existing Hobbies scaffold is reused',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HobbiesGalleryScreen(),
        ),
      );

      expect(find.byType(AndrilHobbiesScaffold), findsOneWidget);
      final AndrilHobbiesScaffold scaffold =
          tester.widget<AndrilHobbiesScaffold>(
        find.byType(AndrilHobbiesScaffold),
      );
      expect(scaffold.title, 'Hobbies Media Gallery');
      expect(scaffold.showWave, isTrue);
    });

    // 3. Correct background and typography
    testWidgets('3. Correct background and typography',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HobbiesGalleryScreen(),
        ),
      );

      final Scaffold innerScaffold =
          tester.widget<Scaffold>(find.byType(Scaffold));
      expect(innerScaffold.backgroundColor, HobbiesColors.background);
      expect(innerScaffold.backgroundColor, const Color(0xFFECFDF5));

      final Text titleText =
          tester.widget<Text>(find.text('Hobbies Media Gallery'));
      expect(titleText.style?.color, HobbiesTheme.textDark);
      expect(titleText.style?.fontSize, HobbiesTypography.screenTitle.fontSize);
    });

    // 4. Loading state
    testWidgets('4. Loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HobbiesGalleryScreen(
            status: HobbiesGalleryStatus.loading,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading media gallery...'), findsOneWidget);
      expect(find.byType(SliverGrid), findsNothing);
      expect(find.text('No Hobby Moments Yet'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    // 5. Empty state
    testWidgets('5. Empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HobbiesGalleryScreen(
            status: HobbiesGalleryStatus.empty,
            items: <HobbiesGalleryItem>[],
          ),
        ),
      );

      expect(find.text('No Hobby Moments Yet'), findsOneWidget);
      expect(
        find.text(
          'Capture and showcase your hobby milestones, projects, and creative activities in your personal gallery.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
      expect(find.byKey(const Key('gallery_empty_add_button')), findsOneWidget);
      expect(find.byType(SliverGrid), findsNothing);
    });

    // 6. Populated grid state
    testWidgets('6. Populated grid state', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final List<HobbiesGalleryItem> mockItems =
          HobbiesGalleryMockFixtures.sampleItems;

      HobbiesGalleryItem? tappedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: HobbiesGalleryScreen(
            status: HobbiesGalleryStatus.populated,
            items: mockItems,
            onItemTapped: (HobbiesGalleryItem item) => tappedItem = item,
          ),
        ),
      );

      expect(find.byType(SliverGrid), findsOneWidget);
      expect(find.text('Ceramic Glazing Workshop'), findsOneWidget);
      expect(find.text('Macro Orchid Bloom'), findsOneWidget);
      expect(find.text('Handmade Leather Journal'), findsOneWidget);
      expect(find.text('Sourdough Country Loaf'), findsOneWidget);

      // Verify category tags render
      expect(find.text('Pottery'), findsOneWidget);
      expect(find.text('Gardening'), findsOneWidget);

      // Verify item interactivity
      await tester.tap(find.byKey(const Key('gallery_item_mock-hob-01')));
      await tester.pump();
      expect(tappedItem?.id, 'mock-hob-01');
      expect(tappedItem?.title, 'Ceramic Glazing Workshop');
    });

    // 7. Denied-access state
    testWidgets('7. Denied-access state', (WidgetTester tester) async {
      const String customDeniedMessage =
          'You lack authorization to access this private hobby gallery.';

      await tester.pumpWidget(
        const MaterialApp(
          home: HobbiesGalleryScreen(
            status: HobbiesGalleryStatus.denied,
            deniedMessage: customDeniedMessage,
          ),
        ),
      );

      expect(find.text('Access Denied'), findsOneWidget);
      expect(find.text(customDeniedMessage), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.byType(SliverGrid), findsNothing);
      expect(tester.takeException(), isNull);
    });

    // 8. Error state
    testWidgets('8. Error state', (WidgetTester tester) async {
      const String customErrorMessage =
          'Network connection interrupted during gallery synchronization.';

      await tester.pumpWidget(
        const MaterialApp(
          home: HobbiesGalleryScreen(
            status: HobbiesGalleryStatus.error,
            errorMessage: customErrorMessage,
          ),
        ),
      );

      expect(find.text('Unable to Load Media'), findsOneWidget);
      expect(find.text(customErrorMessage), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
      expect(find.byKey(const Key('gallery_retry_button')), findsOneWidget);
      expect(find.byType(SliverGrid), findsNothing);
    });

    // 9. Retry callback
    testWidgets('9. Retry callback', (WidgetTester tester) async {
      bool retryInvoked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: HobbiesGalleryScreen(
            status: HobbiesGalleryStatus.error,
            onRetry: () => retryInvoked = true,
          ),
        ),
      );

      expect(find.byKey(const Key('gallery_retry_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('gallery_retry_button')));
      await tester.pump();
      expect(retryInvoked, isTrue);
    });

    // 10. Long media titles
    testWidgets('10. Long media titles', (WidgetTester tester) async {
      const String veryLongTitle =
          'Extremely Long Hobby Project Title Describing Masterpiece Pottery Exhibition Piece With Extensive Detail';
      const String veryLongCaption =
          'Very detailed description that spans multiple sentences to verify that layout clipping and ellipsis handling operate without any box overflow exceptions.';

      final List<HobbiesGalleryItem> itemsWithLongText = <HobbiesGalleryItem>[
        const HobbiesGalleryItem(
          id: 'long-item-01',
          title: veryLongTitle,
          caption: veryLongCaption,
          hobbyTag: 'Ceramics & Sculpting',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: HobbiesGalleryScreen(
            status: HobbiesGalleryStatus.populated,
            items: itemsWithLongText,
          ),
        ),
      );

      expect(find.text(veryLongTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 11. Compact mobile viewport (320 x 568)
    testWidgets(
        '11. Compact mobile viewport renders without overflow (320 x 568)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: HobbiesGalleryScreen(
            status: HobbiesGalleryStatus.populated,
            items: HobbiesGalleryMockFixtures.sampleItems,
          ),
        ),
      );

      expect(find.byType(HobbiesGalleryScreen), findsOneWidget);
      expect(find.text('Hobbies Media Gallery'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 12. Standard mobile viewport (390 x 844)
    testWidgets('12. Standard mobile viewport (390 x 844)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: HobbiesGalleryScreen(
            status: HobbiesGalleryStatus.populated,
            items: HobbiesGalleryMockFixtures.sampleItems,
          ),
        ),
      );

      expect(find.byType(HobbiesGalleryScreen), findsOneWidget);
      expect(find.text('Hobbies Media Gallery'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 13. Text scaling (2.0x)
    testWidgets('13. Text scaling (2.0x)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.only(top: 44.0),
              textScaler: TextScaler.linear(2.0),
            ),
            child: HobbiesGalleryScreen(
              status: HobbiesGalleryStatus.populated,
              items: HobbiesGalleryMockFixtures.sampleItems,
            ),
          ),
        ),
      );

      expect(find.byType(HobbiesGalleryScreen), findsOneWidget);
      expect(find.text('Hobbies Media Gallery'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 14. Disabled or safely controlled upload action
    testWidgets('14. Disabled or safely controlled upload action',
        (WidgetTester tester) async {
      bool uploadTapped = false;

      // Part A: Disabled by default
      await tester.pumpWidget(
        MaterialApp(
          home: HobbiesGalleryScreen(
            isUploadEnabled: false,
            onUploadPressed: () => uploadTapped = true,
          ),
        ),
      );

      final ElevatedButton disabledButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('gallery_upload_button')),
      );
      expect(disabledButton.onPressed, isNull);

      // Verify notice is present in tooltip
      final Tooltip tooltip = tester.widget<Tooltip>(
        find.byWidgetPredicate(
          (Widget w) =>
              w is Tooltip &&
              w.message == HobbiesGalleryScreen.uploadUnavailableNotice,
        ),
      );
      expect(
        tooltip.message,
        'Upload integration is not yet available.',
      );

      // Part B: Safely controlled when enabled
      await tester.pumpWidget(
        MaterialApp(
          home: HobbiesGalleryScreen(
            isUploadEnabled: true,
            onUploadPressed: () => uploadTapped = true,
          ),
        ),
      );

      final ElevatedButton enabledButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('gallery_upload_button')),
      );
      expect(enabledButton.onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('gallery_upload_button')));
      await tester.pump();
      expect(uploadTapped, isTrue);
    });

    // 15. No Gallery/Map contribution confusion
    testWidgets('15. No Gallery/Map contribution confusion',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HobbiesGalleryScreen(
            status: HobbiesGalleryStatus.populated,
            items: HobbiesGalleryMockFixtures.sampleItems,
          ),
        ),
      );

      // Verify official Screen ID
      expect(HobbiesGalleryScreen.screenId, 'M3-HOB-01-GALLERY-01');

      // Verify disclaimer specifically excludes photo portfolios
      expect(
        find.text(HobbiesGalleryScreen.disclaimerText),
        findsOneWidget,
      );
      expect(
        HobbiesGalleryScreen.disclaimerText.contains('Photo Portfolios'),
        isTrue,
      );

      // Verify no Map contribution or moderation elements are present
      expect(find.textContaining('Andril Map'), findsNothing);
      expect(find.textContaining('Mapbox'), findsNothing);
      expect(find.textContaining('Contribution moderation'), findsNothing);
      expect(find.textContaining('Camera evidence'), findsNothing);
    });

    // 16. No cross-module imports or private identity exposure
    testWidgets('16. No cross-module imports or private identity exposure',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HobbiesGalleryScreen(
            status: HobbiesGalleryStatus.populated,
            items: HobbiesGalleryMockFixtures.sampleItems,
          ),
        ),
      );

      // Verify theme colors remain strictly Hobbies brand
      final ThemeData capturedTheme = HobbiesTheme.lightTheme;
      const Color learningPrimary = Color(0xFF2563EB);
      const Color socialAccent = Color(0xFFE11D48);

      expect(capturedTheme.colorScheme.primary, HobbiesColors.primary);
      expect(capturedTheme.colorScheme.primary, isNot(learningPrimary));
      expect(capturedTheme.colorScheme.primary, isNot(socialAccent));

      // Verify no Dating or Learning identities or profile tokens are exposed
      expect(find.textContaining('Learning Profile'), findsNothing);
      expect(find.textContaining('Dating Profile'), findsNothing);
      expect(find.textContaining('Social Profile'), findsNothing);
      expect(find.textContaining('MoodTone'), findsNothing);
      expect(find.textContaining('bearer_token'), findsNothing);
    });
  });

  group('HobbiesGalleryScreen — Privacy State Hardening (M3-CP-02A-R01)', () {
    // 1. Denied status with a nonempty items list does not display private counts or media information
    testWidgets(
        '1. Denied status with a nonempty items list does not display private counts or media information',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HobbiesGalleryScreen(
            status: HobbiesGalleryStatus.denied,
            items: HobbiesGalleryMockFixtures.sampleItems,
          ),
        ),
      );

      // Verify no metrics card is displayed
      expect(find.text('Total Media'), findsNothing);
      expect(find.text('Visible Media'), findsNothing);
      expect(find.text('4'), findsNothing);

      // Verify no private item titles, captions, or tags are exposed
      expect(find.text('Ceramic Glazing Workshop'), findsNothing);
      expect(find.text('Macro Orchid Bloom'), findsNothing);
      expect(find.text('Handmade Leather Journal'), findsNothing);
      expect(find.text('Sourdough Country Loaf'), findsNothing);
      expect(find.text('Pottery'), findsNothing);
      expect(find.text('Gardening'), findsNothing);

      // Verify denied UI renders cleanly
      expect(find.text('Access Denied'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 2. Loading status with retained items does not expose their metadata
    testWidgets(
        '2. Loading status with retained items does not expose their metadata',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HobbiesGalleryScreen(
            status: HobbiesGalleryStatus.loading,
            items: HobbiesGalleryMockFixtures.sampleItems,
          ),
        ),
      );

      // Verify no metrics card is displayed
      expect(find.text('Total Media'), findsNothing);
      expect(find.text('Visible Media'), findsNothing);
      expect(find.text('4'), findsNothing);

      // Verify no private item metadata is exposed
      expect(find.text('Ceramic Glazing Workshop'), findsNothing);
      expect(find.text('Pottery'), findsNothing);
      expect(find.text('Loading media gallery...'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 3. Error status with retained items does not expose their metadata
    testWidgets(
        '3. Error status with retained items does not expose their metadata',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HobbiesGalleryScreen(
            status: HobbiesGalleryStatus.error,
            items: HobbiesGalleryMockFixtures.sampleItems,
          ),
        ),
      );

      // Verify no metrics card is displayed
      expect(find.text('Total Media'), findsNothing);
      expect(find.text('Visible Media'), findsNothing);
      expect(find.text('4'), findsNothing);

      // Verify no private item metadata is exposed
      expect(find.text('Ceramic Glazing Workshop'), findsNothing);
      expect(find.text('Pottery'), findsNothing);
      expect(find.text('Unable to Load Media'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 4. Empty status with stale items displays zero metrics
    testWidgets('4. Empty status with stale items displays zero metrics',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HobbiesGalleryScreen(
            status: HobbiesGalleryStatus.empty,
            items: HobbiesGalleryMockFixtures.sampleItems,
          ),
        ),
      );

      // Verify metrics card is displayed but strictly shows 0
      expect(find.text('Total Media'), findsOneWidget);
      expect(find.text('Visible Media'), findsOneWidget);
      expect(find.text('0'), findsNWidgets(2));
      expect(find.text('4'), findsNothing);

      // Verify no private item content is rendered in grid
      expect(find.text('Ceramic Glazing Workshop'), findsNothing);
      expect(find.text('No Hobby Moments Yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 5. Populated status still displays correct metrics and media
    testWidgets('5. Populated status still displays correct metrics and media',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: HobbiesGalleryScreen(
            status: HobbiesGalleryStatus.populated,
            items: HobbiesGalleryMockFixtures.sampleItems,
          ),
        ),
      );

      // Verify metrics card displays item count (4 total, 4 visible)
      expect(find.text('Total Media'), findsOneWidget);
      expect(find.text('Visible Media'), findsOneWidget);
      expect(find.text('4'), findsNWidgets(2));

      // Verify media items render
      expect(find.text('Ceramic Glazing Workshop'), findsOneWidget);
      expect(find.text('Macro Orchid Bloom'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 6. Upload callback cannot execute while denied
    testWidgets('6. Upload callback cannot execute while denied',
        (WidgetTester tester) async {
      bool uploadInvoked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: HobbiesGalleryScreen(
            status: HobbiesGalleryStatus.denied,
            isUploadEnabled: true,
            onUploadPressed: () => uploadInvoked = true,
          ),
        ),
      );

      final ElevatedButton button = tester.widget<ElevatedButton>(
        find.byKey(const Key('gallery_upload_button')),
      );
      expect(button.onPressed, isNull);

      await tester.tap(find.byKey(const Key('gallery_upload_button')));
      await tester.pump();
      expect(uploadInvoked, isFalse);
    });

    // 7. Upload callback cannot execute while loading
    testWidgets('7. Upload callback cannot execute while loading',
        (WidgetTester tester) async {
      bool uploadInvoked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: HobbiesGalleryScreen(
            status: HobbiesGalleryStatus.loading,
            isUploadEnabled: true,
            onUploadPressed: () => uploadInvoked = true,
          ),
        ),
      );

      final ElevatedButton button = tester.widget<ElevatedButton>(
        find.byKey(const Key('gallery_upload_button')),
      );
      expect(button.onPressed, isNull);

      await tester.tap(find.byKey(const Key('gallery_upload_button')));
      await tester.pump();
      expect(uploadInvoked, isFalse);
    });

    // 8. Upload callback cannot execute while error
    testWidgets('8. Upload callback cannot execute while error',
        (WidgetTester tester) async {
      bool uploadInvoked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: HobbiesGalleryScreen(
            status: HobbiesGalleryStatus.error,
            isUploadEnabled: true,
            onUploadPressed: () => uploadInvoked = true,
          ),
        ),
      );

      final ElevatedButton button = tester.widget<ElevatedButton>(
        find.byKey(const Key('gallery_upload_button')),
      );
      expect(button.onPressed, isNull);

      await tester.tap(find.byKey(const Key('gallery_upload_button')));
      await tester.pump();
      expect(uploadInvoked, isFalse);
    });

    // 9. Authorized presentation states preserve the previous callback contract
    testWidgets(
        '9. Authorized presentation states preserve the previous callback contract',
        (WidgetTester tester) async {
      bool uploadInvoked = false;

      // Part A: Populated state with upload enabled invokes callback
      await tester.pumpWidget(
        MaterialApp(
          home: HobbiesGalleryScreen(
            status: HobbiesGalleryStatus.populated,
            items: HobbiesGalleryMockFixtures.sampleItems,
            isUploadEnabled: true,
            onUploadPressed: () => uploadInvoked = true,
          ),
        ),
      );

      final ElevatedButton populatedButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('gallery_upload_button')),
      );
      expect(populatedButton.onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('gallery_upload_button')));
      await tester.pump();
      expect(uploadInvoked, isTrue);

      // Part B: Empty state with upload enabled invokes callback
      uploadInvoked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: HobbiesGalleryScreen(
            status: HobbiesGalleryStatus.empty,
            isUploadEnabled: true,
            onUploadPressed: () => uploadInvoked = true,
          ),
        ),
      );

      final ElevatedButton emptyButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('gallery_upload_button')),
      );
      expect(emptyButton.onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('gallery_upload_button')));
      await tester.pump();
      expect(uploadInvoked, isTrue);

      // Empty state action button also connects to onUploadPressed
      uploadInvoked = false;
      final ElevatedButton emptyAddButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('gallery_empty_add_button')),
      );
      expect(emptyAddButton.onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('gallery_empty_add_button')));
      await tester.pump();
      expect(uploadInvoked, isTrue);
    });

    // 10. Compact viewport does not overflow after the correction
    testWidgets('10. Compact viewport does not overflow after the correction',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Test denied with retained items
      await tester.pumpWidget(
        MaterialApp(
          home: HobbiesGalleryScreen(
            status: HobbiesGalleryStatus.denied,
            items: HobbiesGalleryMockFixtures.sampleItems,
            isUploadEnabled: true,
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      // Test loading with retained items
      await tester.pumpWidget(
        MaterialApp(
          home: HobbiesGalleryScreen(
            status: HobbiesGalleryStatus.loading,
            items: HobbiesGalleryMockFixtures.sampleItems,
            isUploadEnabled: true,
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      // Test error with retained items
      await tester.pumpWidget(
        MaterialApp(
          home: HobbiesGalleryScreen(
            status: HobbiesGalleryStatus.error,
            items: HobbiesGalleryMockFixtures.sampleItems,
            isUploadEnabled: true,
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      // Test empty with retained items
      await tester.pumpWidget(
        MaterialApp(
          home: HobbiesGalleryScreen(
            status: HobbiesGalleryStatus.empty,
            items: HobbiesGalleryMockFixtures.sampleItems,
            isUploadEnabled: true,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
