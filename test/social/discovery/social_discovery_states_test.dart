import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_discovery_empty_state.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_discovery_status_view.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_saved_profiles_screen.dart';

void main() {
  group('SocialDiscoveryEmptyState (Task 135 / S26, S83)', () {
    testWidgets('renders S26 No People Found state with filter action', (tester) async {
      var filterTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialDiscoveryEmptyState(
              type: SocialDiscoveryEmptyType.noCandidates,
              onOpenFilters: () => filterTapped = true,
              onRefresh: () {},
            ),
          ),
        ),
      );

      expect(find.text('No Profiles Found'), findsOneWidget);
      expect(find.textContaining('Adjust your radius or preferences to see more people.'), findsOneWidget);
      expect(find.text('Adjust Filters'), findsOneWidget);

      await tester.tap(find.text('Adjust Filters'));
      await tester.pump();
      expect(filterTapped, isTrue);
    });

    testWidgets('renders S83 End of Discovery state with refresh feed action', (tester) async {
      var refreshTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialDiscoveryEmptyState(
              type: SocialDiscoveryEmptyType.endOfDeck,
              onRefresh: () => refreshTapped = true,
            ),
          ),
        ),
      );

      expect(find.text("You're All Caught Up"), findsOneWidget);
      expect(find.textContaining('reviewed all available discovery profiles for today'), findsOneWidget);
      expect(find.text('Refresh Feed'), findsOneWidget);

      await tester.tap(find.text('Refresh Feed'));
      await tester.pump();
      expect(refreshTapped, isTrue);
    });

    testWidgets('renders cleanly across viewports without overflow', (tester) async {
      for (final width in [320.0, 400.0, 800.0]) {
        tester.view.physicalSize = Size(width * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SocialDiscoveryEmptyState(
                type: SocialDiscoveryEmptyType.noCandidates,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      }
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });

  group('SocialSavedProfilesScreen Empty State (Task 136 / S27)', () {
    testWidgets('renders S27 empty saved profiles view and Explore button', (tester) async {
      var exploreCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SocialSavedProfilesScreen(
            savedProfiles: const [],
            onExploreMore: () => exploreCalled = true,
          ),
        ),
      );

      expect(find.text('No Saved Profiles Yet'), findsOneWidget);
      expect(find.textContaining('bookmark candidates while discovering people'), findsOneWidget);
      expect(find.text('Explore People'), findsOneWidget);

      await tester.tap(find.text('Explore People'));
      await tester.pump();
      expect(exploreCalled, isTrue);
    });

    testWidgets('renders cleanly across viewports without overflow', (tester) async {
      for (final width in [320.0, 400.0, 800.0]) {
        tester.view.physicalSize = Size(width * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: SocialSavedProfilesScreen(
              savedProfiles: [],
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      }
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });

  group('SocialDiscoveryStatusView (Task 137 / S84, S85)', () {
    testWidgets('renders S84 Discovery Error state with retry callback', (tester) async {
      var retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialDiscoveryStatusView(
              type: SocialDiscoveryStatusType.networkError,
              onRetry: () => retryCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Unable to Load Discovery'), findsOneWidget);
      expect(find.textContaining('encountered an issue communicating with the discovery service'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retryCalled, isTrue);
    });

    testWidgets('renders S85 Profile Unavailable state with return callback', (tester) async {
      var returnCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialDiscoveryStatusView(
              type: SocialDiscoveryStatusType.profileUnavailable,
              onReturn: () => returnCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Profile Unavailable'), findsOneWidget);
      expect(find.textContaining('This profile is no longer available'), findsOneWidget);
      expect(find.text('Back to Discovery'), findsOneWidget);

      await tester.tap(find.text('Back to Discovery'));
      await tester.pump();
      expect(returnCalled, isTrue);
    });

    testWidgets('renders cleanly across viewports without overflow', (tester) async {
      for (final width in [320.0, 400.0, 800.0]) {
        tester.view.physicalSize = Size(width * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SocialDiscoveryStatusView(
                type: SocialDiscoveryStatusType.networkError,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      }
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
