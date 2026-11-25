import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/features/learning/classrooms/domain/entities/learning_classroom.dart';
import 'package:andril_mobile/features/learning/classrooms/presentation/screens/learning_classrooms_hub_screen.dart';
import 'package:andril_mobile/features/learning/classrooms/presentation/widgets/classroom_card.dart';
import 'package:andril_mobile/features/learning/classrooms/presentation/widgets/request_to_join_dialog.dart';

void main() {
  Widget buildTestWidget({
    String currentUserId = 'test_user_id',
    String currentAccountId = 'test_account_id',
    String currentDisplayName = 'Thusa Test',
    bool isLearningActivated = true,
    bool isLoading = false,
    String? errorMessage,
    bool isUnavailable = false,
    List<LearningClassroom>? initialClassrooms,
    VoidCallback? onBack,
    VoidCallback? onRetry,
    double textScaleFactor = 1.0,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScaleFactor),
        ),
        child: LearningClassroomsHubScreen(
          currentUserId: currentUserId,
          currentAccountId: currentAccountId,
          currentDisplayName: currentDisplayName,
          isLearningActivated: isLearningActivated,
          isLoading: isLoading,
          errorMessage: errorMessage,
          isUnavailable: isUnavailable,
          initialClassrooms: initialClassrooms,
          onBack: onBack,
          onRetry: onRetry,
        ),
      ),
    );
  }

  group('LearningClassroomsHubScreen - Access Control & State Flags', () {
    testWidgets('renders Access Denied view when currentUserId is empty',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(currentUserId: ''));
      await tester.pumpAndSettle();

      expect(find.text('Learning Profile Required'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('Classrooms Hub'), findsOneWidget);
    });

    testWidgets('renders Access Denied view when isLearningActivated is false',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(isLearningActivated: false));
      await tester.pumpAndSettle();

      expect(find.text('Learning Profile Required'), findsOneWidget);
      expect(find.byType(ClassroomCard), findsNothing);
    });

    testWidgets('renders Loading state when isLoading is true', (tester) async {
      await tester.pumpWidget(buildTestWidget(isLoading: true));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ClassroomCard), findsNothing);
    });

    testWidgets('renders Error state and triggers onRetry', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        buildTestWidget(
          errorMessage: 'Failed to connect to classrooms service.',
          onRetry: () => retried = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Error Loading Classrooms'), findsOneWidget);
      expect(find.text('Failed to connect to classrooms service.'),
          findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(retried, isTrue);
    });

    testWidgets('renders Unavailable state and triggers retry', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        buildTestWidget(
          isUnavailable: true,
          onRetry: () => retried = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Classrooms Service Unavailable'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);

      await tester.tap(find.text('Retry Connection'));
      await tester.pumpAndSettle();
      expect(retried, isTrue);
    });

    testWidgets('triggers onBack callback when back button is tapped',
        (tester) async {
      var backed = false;
      await tester.pumpWidget(buildTestWidget(onBack: () => backed = true));
      await tester.pumpAndSettle();

      final backButton = find.byTooltip('Back');
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(backed, isTrue);
    });
  });

  group('LearningClassroomsHubScreen - UI Elements & Interaction', () {
    testWidgets('renders Disconnected notice banner and classrooms list',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text(LearningClassroom.disconnectedNotice), findsOneWidget);
      expect(find.text('All Classrooms'), findsOneWidget);
      expect(find.text('My Classrooms'), findsOneWidget);
      expect(find.byType(ClassroomCard), findsWidgets);
    });

    testWidgets('filters classrooms by category chip', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Flutter & Dart Mastery'), findsOneWidget);
      expect(find.text('UI/UX Design Systems Workshop'), findsOneWidget);

      // Tap Design category
      await tester.tap(find.widgetWithText(ChoiceChip, 'Design'));
      await tester.pumpAndSettle();

      expect(find.text('UI/UX Design Systems Workshop'), findsOneWidget);
      expect(find.text('Flutter & Dart Mastery'), findsNothing);

      // Tap All category to restore
      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.pumpAndSettle();

      expect(find.text('Flutter & Dart Mastery'), findsOneWidget);
    });

    testWidgets('searches classrooms by keyword and clears search',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Spanish');
      await tester.pumpAndSettle();

      expect(find.text('Conversational Spanish for Tech'), findsOneWidget);
      expect(find.text('Flutter & Dart Mastery'), findsNothing);

      // Tap clear button
      final clearButton = find.byTooltip('Clear search');
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(find.text('Flutter & Dart Mastery'), findsOneWidget);
    });

    testWidgets('shows empty state when no classrooms match search',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'NonExistentTopicXYZ');
      await tester.pumpAndSettle();

      expect(find.text('No Classrooms Found'), findsOneWidget);
      expect(find.byType(ClassroomCard), findsNothing);
    });

    testWidgets('joins public classroom and shows confirmation banner',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Find 'Join Classroom' button on Flutter & Dart Mastery
      final joinButton =
          find.widgetWithText(ElevatedButton, 'Join Classroom').first;
      await tester.tap(joinButton);
      await tester.pumpAndSettle();

      expect(find.text('Enrolled in Classroom'), findsWidgets);
      expect(
          find.textContaining('Joined "Flutter & Dart Mastery" successfully.'),
          findsOneWidget);
    });

    testWidgets(
        'requests to join approval-required classroom and shows pending state',
        (tester) async {
      final requestClassroom = LearningClassroom.create(
        id: 'cls_request_test',
        name: 'UI/UX Design Workshop',
        description: 'Design systems hands-on.',
        category: 'Design',
        privacy: ClassroomPrivacy.requestToJoin,
        hostProfileId: 'h1',
        hostDisplayName: 'Designer Host',
        membershipStatus: ClassroomMembershipStatus.none,
      );

      await tester
          .pumpWidget(buildTestWidget(initialClassrooms: [requestClassroom]));
      await tester.pumpAndSettle();

      // Tap Request to Join on the first item
      final requestButton =
          find.widgetWithText(OutlinedButton, 'Request to Join');
      expect(requestButton, findsOneWidget);
      await tester.tap(requestButton);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.byType(RequestToJoinDialog), findsOneWidget);
      expect(find.text('Request Admission'), findsOneWidget);

      // Enter optional note and submit
      final noteField = find.descendant(
        of: find.byType(RequestToJoinDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(noteField, 'I have 2 years of design experience.');
      await tester.tap(find.text('Submit Request'));
      await tester.pumpAndSettle();

      // Dialog dismissed, pending status visible
      expect(find.byType(RequestToJoinDialog), findsNothing);
      expect(find.text('Admission Pending'), findsOneWidget);
      expect(find.textContaining('Admission request submitted for'),
          findsOneWidget);
    });

    testWidgets('cancels pending admission request', (tester) async {
      final pendingClassroom = LearningClassroom.create(
        id: 'cls_pending_test',
        name: 'Product Strategy & Lean MVPs',
        description: 'Frameworks for rapid MVP validation.',
        category: 'Business',
        privacy: ClassroomPrivacy.requestToJoin,
        hostProfileId: 'h_biz',
        hostDisplayName: 'Marcus Vance',
        membershipStatus: ClassroomMembershipStatus.pending,
      );

      await tester
          .pumpWidget(buildTestWidget(initialClassrooms: [pendingClassroom]));
      await tester.pumpAndSettle();

      final cancelButton =
          find.widgetWithText(OutlinedButton, 'Cancel Request');
      expect(cancelButton, findsOneWidget);
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      expect(find.text('Admission request cancelled.'), findsOneWidget);
    });

    testWidgets('switches to My Classrooms tab and shows enrolled classrooms',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap 'My Classrooms'
      await tester.tap(find.text('My Classrooms'));
      await tester.pumpAndSettle();

      // Sample has Conversational Spanish (member) and Mobile App Architecture (host)
      expect(find.text('Conversational Spanish for Tech'), findsOneWidget);
      expect(find.text('Mobile App Architecture Labs'), findsOneWidget);
      expect(find.text('Flutter & Dart Mastery'), findsNothing);
    });

    testWidgets(
        'shows empty state in My Classrooms when none enrolled and allows switching to discovery',
        (tester) async {
      final unjoinedClassrooms = [
        LearningClassroom.create(
          id: 'cls_test_unjoined',
          name: 'Public Test Classroom',
          description: 'A test classroom.',
          category: 'Programming',
          hostProfileId: 'h1',
          hostDisplayName: 'Host One',
          membershipStatus: ClassroomMembershipStatus.none,
        ),
      ];

      await tester
          .pumpWidget(buildTestWidget(initialClassrooms: unjoinedClassrooms));
      await tester.pumpAndSettle();

      await tester.tap(find.text('My Classrooms'));
      await tester.pumpAndSettle();

      expect(find.text('No Enrolled Classrooms'), findsOneWidget);
      expect(find.text('Discover Classrooms'), findsOneWidget);

      // Tap 'Discover Classrooms' button
      await tester.tap(find.text('Discover Classrooms'));
      await tester.pumpAndSettle();

      expect(find.text('Public Test Classroom'), findsOneWidget);
    });

    testWidgets('session revocation: changing currentUserId purges state',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(currentUserId: 'user_A'));
      await tester.pumpAndSettle();

      // Type in search
      await tester.enterText(find.byType(TextField), 'Flutter');
      await tester.pumpAndSettle();
      expect(find.text('Flutter & Dart Mastery'), findsOneWidget);

      // Switch tab
      await tester.tap(find.text('My Classrooms'));
      await tester.pumpAndSettle();

      // Re-pump with user_B
      await tester.pumpWidget(buildTestWidget(currentUserId: 'user_B'));
      await tester.pumpAndSettle();

      // Tab should be reset to All Classrooms and search cleared
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
      expect(find.text('Flutter & Dart Mastery'), findsOneWidget);
      expect(find.text('UI/UX Design Systems Workshop'), findsOneWidget);
    });
  });

  group('LearningClassroomsHubScreen - Responsive Layout & Text Scaling Tests',
      () {
    testWidgets('renders on 320x568 (iPhone SE size) without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Classrooms Hub'), findsOneWidget);
    });

    testWidgets('renders on 360x640 (Android baseline) without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Classrooms Hub'), findsOneWidget);
    });

    testWidgets('renders on 412x915 (Modern Android flagship) without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Classrooms Hub'), findsOneWidget);
    });

    testWidgets('renders at 1.5x font scale without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(textScaleFactor: 1.5));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Classrooms Hub'), findsOneWidget);
    });
  });
}
