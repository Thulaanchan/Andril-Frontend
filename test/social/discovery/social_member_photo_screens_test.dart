import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/social/discovery/domain/social_candidate.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_member_photo_gallery_screen.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_member_profile_screen.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_photo_viewer_screen.dart';

void main() {
  const testPhotos = [
    'https://example.com/photos/1.jpg',
    'https://example.com/photos/2.jpg',
    'https://example.com/photos/3.jpg',
  ];

  group('SocialMemberPhotoGalleryScreen (Task 125 / S51)', () {
    testWidgets('renders member gallery with correct photo count and thumbnails', (tester) async {
      int? selectedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: SocialMemberPhotoGalleryScreen(
            memberName: 'Priya',
            memberId: 'usr-42',
            photoUrls: testPhotos,
            onPhotoSelected: (idx) => selectedIndex = idx,
          ),
        ),
      );

      expect(find.text("Priya's Photos"), findsOneWidget);
      expect(find.text('3 photos'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);

      // Verify thumbnails rendered and can be tapped
      final firstThumb = find.byType(InkWell).first;
      expect(firstThumb, findsOneWidget);

      await tester.tap(firstThumb);
      await tester.pump();
      expect(selectedIndex, 0);
    });

    testWidgets('back button triggers onBack callback', (tester) async {
      var backCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SocialMemberPhotoGalleryScreen(
            memberName: 'Priya',
            memberId: 'usr-42',
            photoUrls: testPhotos,
            onBack: () => backCalled = true,
          ),
        ),
      );

      await tester.tap(find.byTooltip('Back'));
      await tester.pump();
      expect(backCalled, isTrue);
    });

    testWidgets('renders friendly empty state when photo list is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SocialMemberPhotoGalleryScreen(
            memberName: 'Alex',
            memberId: 'usr-99',
            photoUrls: [],
          ),
        ),
      );

      expect(find.text('No Photos Available'), findsOneWidget);
      expect(find.text("Alex hasn't uploaded additional gallery photos."), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
    });

    testWidgets('renders access denied state when isAuthorized is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SocialMemberPhotoGalleryScreen(
            memberName: 'Priya',
            memberId: 'usr-42',
            photoUrls: testPhotos,
            isAuthorized: false,
          ),
        ),
      );

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.textContaining('requires an active authorized Social session'), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
    });

    testWidgets('renders responsively across viewports without overflow', (tester) async {
      for (final width in [320.0, 400.0, 800.0]) {
        tester.view.physicalSize = Size(width * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: SocialMemberPhotoGalleryScreen(
              memberName: 'Priya',
              memberId: 'usr-42',
              photoUrls: testPhotos,
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

  group('SocialPhotoViewerScreen (Task 126 / S52)', () {
    testWidgets('renders full-screen viewer starting at initialIndex with page indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SocialPhotoViewerScreen(
            memberName: 'Priya',
            photoUrls: testPhotos,
            initialIndex: 1,
          ),
        ),
      );

      expect(find.text('2 / 3'), findsOneWidget);
      expect(find.text('Priya'), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('defensively handles out-of-bounds initialIndex', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SocialPhotoViewerScreen(
            memberName: 'Priya',
            photoUrls: testPhotos,
            initialIndex: 99, // invalid index
          ),
        ),
      );

      // Defaults to first photo without throwing
      expect(find.text('1 / 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('close button triggers onClose callback', (tester) async {
      var closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SocialPhotoViewerScreen(
            memberName: 'Priya',
            photoUrls: testPhotos,
            onClose: () => closed = true,
          ),
        ),
      );

      await tester.tap(find.byTooltip('Close'));
      await tester.pump();
      expect(closed, isTrue);
    });

    testWidgets('displays empty state when photoUrls is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SocialPhotoViewerScreen(
            memberName: 'Priya',
            photoUrls: [],
          ),
        ),
      );

      expect(find.text('No Photos to Display'), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('displays access denied when isAuthorized is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SocialPhotoViewerScreen(
            memberName: 'Priya',
            photoUrls: testPhotos,
            isAuthorized: false,
          ),
        ),
      );

      expect(find.text('Access Denied'), findsOneWidget);
      expect(find.textContaining('do not have permission to inspect'), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('renders responsively across viewports without overflow', (tester) async {
      for (final width in [320.0, 400.0, 800.0]) {
        tester.view.physicalSize = Size(width * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: SocialPhotoViewerScreen(
              memberName: 'Priya',
              photoUrls: testPhotos,
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

  group('SocialMemberProfileScreen Photo Integration (Task 126)', () {
    final candidate = SocialCandidate(
      id: 'c-test-1',
      displayName: 'Maya',
      age: 26,
      biography: 'Photographer and hiker.',
      locationName: 'Jaffna',
      approximateDistanceKm: 4,
      isVerified: true,
      photoUrls: testPhotos,
      interests: const ['Photography', 'Travel'],
      sharedConnectionGoals: const ['Friendship'],
    );

    testWidgets('tapping photo thumbnail triggers onPhotoTap callback', (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: SocialMemberProfileScreen(
            candidate: candidate,
            onPhotoTap: (idx) => tappedIndex = idx,
          ),
        ),
      );

      final photoFinder = find.byType(Image).first;
      expect(photoFinder, findsOneWidget);

      await tester.tap(photoFinder);
      await tester.pump();
      expect(tappedIndex, 0);
    });

    testWidgets('tapping gallery badge triggers onOpenGallery callback', (tester) async {
      var galleryOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SocialMemberProfileScreen(
            candidate: candidate,
            onOpenGallery: () => galleryOpened = true,
          ),
        ),
      );

      final badgeFinder = find.text('3');
      expect(badgeFinder, findsOneWidget);

      await tester.tap(badgeFinder);
      await tester.pump();
      expect(galleryOpened, isTrue);
    });
  });
}
