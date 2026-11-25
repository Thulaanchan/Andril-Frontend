import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/learning/skill_exchange/domain/entities/skill_exchange.dart';
import 'package:andril_mobile/features/learning/skill_exchange/domain/entities/skill_exchange_participant.dart';
import 'package:andril_mobile/features/learning/skill_exchange/presentation/screens/skill_exchange_hub_screen.dart';

void _setupTestViewport(
  WidgetTester tester, {
  Size size = const Size(360, 950),
  double devicePixelRatio = 1.0,
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _buildTestApp(
  Widget child, {
  Size size = const Size(360, 950),
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
  try {
    await tester.ensureVisible(finder);
  } catch (_) {}
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('SkillExchangeHubScreen Widget Tests', () {
    testWidgets('Renders access-denied view when currentUserId is empty',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestApp(
          const SkillExchangeHubScreen(
            currentUserId: '',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('card_hub_access_denied')), findsOneWidget);
      expect(find.text('Access Denied'), findsOneWidget);
    });

    testWidgets('Renders access-denied view when isLearningActivated is false',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestApp(
          const SkillExchangeHubScreen(
            currentUserId: 'usr_thusa_01',
            isLearningActivated: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('card_hub_access_denied')), findsOneWidget);
    });

    testWidgets('Renders loading indicator when isLoading is true',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestApp(
          const SkillExchangeHubScreen(
            currentUserId: 'usr_thusa_01',
            isLoading: true,
          ),
        ),
      );
      await tester.pump();

      expect(
          find.byKey(const ValueKey('indicator_hub_loading')), findsOneWidget);
    });

    testWidgets(
        'Renders error card with retry callback when errorMessage is set',
        (tester) async {
      _setupTestViewport(tester);
      var retryCalled = false;

      await tester.pumpWidget(
        _buildTestApp(
          SkillExchangeHubScreen(
            currentUserId: 'usr_thusa_01',
            errorMessage: 'Network timeout occurred.',
            onRetry: () => retryCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('card_hub_error')), findsOneWidget);
      expect(find.text('Network timeout occurred.'), findsOneWidget);

      await _safeTap(tester, find.text('Retry'));
      expect(retryCalled, isTrue);
    });

    testWidgets('Renders unavailable card when isUnavailable is true',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestApp(
          const SkillExchangeHubScreen(
            currentUserId: 'usr_thusa_01',
            isUnavailable: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('card_hub_unavailable')), findsOneWidget);
      expect(
          find.text('Skill Exchange Temporarily Unavailable'), findsOneWidget);
    });

    testWidgets(
        'Renders disconnected contract notice and default discover partners',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestApp(
          const SkillExchangeHubScreen(
            currentUserId: 'usr_thusa_01',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('banner_disconnected_notice')),
          findsOneWidget);
      expect(find.text(SkillExchange.disconnectedNotice), findsOneWidget);

      // Verify search bar and category chips
      expect(find.byKey(const ValueKey('input_skill_search')), findsOneWidget);
      expect(find.byKey(const ValueKey('chip_category_All')), findsOneWidget);
      expect(find.byKey(const ValueKey('chip_category_Technology')),
          findsOneWidget);

      // Verify sample partners rendered
      expect(find.text('Ananya Sharma'), findsOneWidget);
      expect(find.text('Marcus Chen'), findsOneWidget);
    });

    testWidgets('Filters partners by search query and clears search',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestApp(
          const SkillExchangeHubScreen(
            currentUserId: 'usr_thusa_01',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(
          find.byKey(const ValueKey('input_skill_search')), 'Marcus');
      await tester.pumpAndSettle();

      expect(find.text('Marcus Chen'), findsOneWidget);
      expect(find.text('Ananya Sharma'), findsNothing);

      // Clear search
      await _safeTap(tester, find.byKey(const ValueKey('btn_clear_search')));
      expect(find.text('Ananya Sharma'), findsOneWidget);
      expect(find.text('Marcus Chen'), findsOneWidget);
    });

    testWidgets('Filters partners by category chips', (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestApp(
          const SkillExchangeHubScreen(
            currentUserId: 'usr_thusa_01',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Design category
      await _safeTap(
          tester, find.byKey(const ValueKey('chip_category_Design')));
      expect(find.text('Marcus Chen'), findsOneWidget);
      expect(find.text('Ananya Sharma'), findsNothing);

      // Tap All category
      await _safeTap(tester, find.byKey(const ValueKey('chip_category_All')));
      expect(find.text('Ananya Sharma'), findsOneWidget);
      expect(find.text('Marcus Chen'), findsOneWidget);
    });

    testWidgets('Toggles Offer a Skill and Learn a Skill quick filters',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestApp(
          const SkillExchangeHubScreen(
            currentUserId: 'usr_thusa_01',
            userSkillsToShare: ['Flutter'],
            userSkillsToLearn: ['Figma'],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Offer filter (partner wants Flutter)
      await _safeTap(tester, find.byKey(const ValueKey('btn_filter_offer')));
      expect(find.text('Marcus Chen'), findsOneWidget); // Marcus wants Flutter

      // Tap again to toggle off
      await _safeTap(tester, find.byKey(const ValueKey('btn_filter_offer')));
      expect(find.text('Ananya Sharma'), findsOneWidget);

      // Tap Learn filter (partner offers Figma)
      await _safeTap(tester, find.byKey(const ValueKey('btn_filter_learn')));
      expect(find.text('Marcus Chen'), findsOneWidget); // Marcus offers Figma
    });

    testWidgets(
        'Renders empty partners view when search has no matches, resets filters',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestApp(
          const SkillExchangeHubScreen(
            currentUserId: 'usr_thusa_01',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('input_skill_search')),
        'NonexistentQuery123',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('view_empty_partners')), findsOneWidget);
      expect(find.text('No Matching Partners Found'), findsOneWidget);

      await _safeTap(
          tester, find.byKey(const ValueKey('btn_reset_partner_filters')));
      expect(find.text('Ananya Sharma'), findsOneWidget);
    });

    testWidgets('Opens Propose Exchange dialog and creates a new proposal',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestApp(
          const SkillExchangeHubScreen(
            currentUserId: 'usr_thusa_01',
            userSkillsToShare: ['Flutter', 'Dart'],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Request Exchange on Ananya
      await _safeTap(tester,
          find.byKey(const ValueKey('btn_request_exchange_partner_ananya_01')));
      expect(find.byKey(const ValueKey('dialog_propose_exchange')),
          findsOneWidget);
      expect(find.text('Propose Skill Exchange'), findsOneWidget);

      // Enter optional note
      await tester.enterText(
        find.byKey(const ValueKey('input_proposal_note')),
        'Looking forward to trading Flutter for Figma!',
      );

      // Submit proposal
      await _safeTap(
          tester, find.byKey(const ValueKey('btn_submit_exchange_proposal')));

      // Dialog dismissed and confirmation banner rendered
      expect(
          find.byKey(const ValueKey('dialog_propose_exchange')), findsNothing);
      expect(find.byKey(const ValueKey('banner_confirmation')), findsOneWidget);
      expect(
          find.textContaining('Skill exchange proposal sent'), findsOneWidget);

      // Partner card now displays pending proposal status
      expect(find.text('Pending Proposal Active'), findsOneWidget);
    });

    testWidgets(
        'Propose dialog validates against identical offered and wanted skills',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestApp(
          const SkillExchangeHubScreen(
            currentUserId: 'usr_thusa_01',
            userSkillsToShare: ['Flutter'],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _safeTap(tester,
          find.byKey(const ValueKey('btn_request_exchange_partner_ananya_01')));

      // Tap + Other for wanted skill and enter 'Flutter'
      await _safeTap(tester, find.text('+ Other').last);
      await tester.enterText(
          find.byKey(const ValueKey('input_wanted_skill')), 'Flutter');
      await tester.pumpAndSettle();

      await _safeTap(
          tester, find.byKey(const ValueKey('btn_submit_exchange_proposal')));

      expect(
        find.text(
            'An identical offered and wanted skill requires an approved overlap policy.'),
        findsOneWidget,
      );

      // Dismiss dialog
      await _safeTap(
          tester, find.byKey(const ValueKey('btn_dismiss_proposal_dialog')));
      expect(
          find.byKey(const ValueKey('dialog_propose_exchange')), findsNothing);
    });

    testWidgets('Switches to My Exchanges tab and handles sender cancellation',
        (tester) async {
      _setupTestViewport(tester);

      final initialExchange = SkillExchange.propose(
        id: 'ex_test_01',
        sender: SkillExchangeParticipant(
          accountId: 'acc_current_user',
          learningProfileId: 'usr_thusa_01',
        ),
        recipient: SkillExchangeParticipant(
          accountId: 'acc_partner_01',
          learningProfileId: 'partner_ananya_01',
        ),
        offeredSkill: 'Flutter',
        wantedSkill: 'Figma',
      );

      await tester.pumpWidget(
        _buildTestApp(
          SkillExchangeHubScreen(
            currentUserId: 'usr_thusa_01',
            initialExchanges: [initialExchange],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to My Exchanges tab
      await _safeTap(tester, find.byKey(const ValueKey('tab_my_exchanges')));

      expect(find.byKey(const ValueKey('card_exchange_ex_test_01')),
          findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.text('Cancel Request'), findsOneWidget);

      // Tap Cancel Request
      await _safeTap(
          tester, find.byKey(const ValueKey('btn_cancel_exchange_ex_test_01')));

      expect(find.text('CANCELLED'), findsOneWidget);
      expect(find.text('Proposal cancelled successfully.'), findsOneWidget);
    });

    testWidgets('Recipient can accept incoming exchange request',
        (tester) async {
      _setupTestViewport(tester);

      // In this scenario, user is recipient
      final incomingExchange = SkillExchange.propose(
        id: 'ex_incoming_01',
        sender: SkillExchangeParticipant(
          accountId: 'acc_partner_01',
          learningProfileId: 'partner_ananya_01',
        ),
        recipient: SkillExchangeParticipant(
          accountId: 'acc_current_user',
          learningProfileId: 'usr_thusa_01',
        ),
        offeredSkill: 'Figma',
        wantedSkill: 'Flutter',
      );

      await tester.pumpWidget(
        _buildTestApp(
          SkillExchangeHubScreen(
            currentUserId: 'usr_thusa_01',
            initialExchanges: [incomingExchange],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _safeTap(tester, find.byKey(const ValueKey('tab_my_exchanges')));

      expect(find.text('Proposed to you'), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_accept_exchange_ex_incoming_01')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('btn_decline_exchange_ex_incoming_01')),
          findsOneWidget);

      // Tap Accept
      await _safeTap(tester,
          find.byKey(const ValueKey('btn_accept_exchange_ex_incoming_01')));

      expect(find.text('ACCEPTED'), findsOneWidget);
      expect(find.textContaining('Mutual Agreement Active'), findsOneWidget);
    });

    testWidgets('Recipient can decline incoming exchange request',
        (tester) async {
      _setupTestViewport(tester);

      final incomingExchange = SkillExchange.propose(
        id: 'ex_incoming_02',
        sender: SkillExchangeParticipant(
          accountId: 'acc_partner_01',
          learningProfileId: 'partner_ananya_01',
        ),
        recipient: SkillExchangeParticipant(
          accountId: 'acc_current_user',
          learningProfileId: 'usr_thusa_01',
        ),
        offeredSkill: 'Figma',
        wantedSkill: 'Flutter',
      );

      await tester.pumpWidget(
        _buildTestApp(
          SkillExchangeHubScreen(
            currentUserId: 'usr_thusa_01',
            initialExchanges: [incomingExchange],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _safeTap(tester, find.byKey(const ValueKey('tab_my_exchanges')));

      // Tap Decline
      await _safeTap(tester,
          find.byKey(const ValueKey('btn_decline_exchange_ex_incoming_02')));

      expect(find.text('DECLINED'), findsOneWidget);
      expect(find.text('Proposal declined.'), findsOneWidget);
    });

    testWidgets(
        'Renders empty exchanges view when my exchanges is empty, redirects to discover',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestApp(
          const SkillExchangeHubScreen(
            currentUserId: 'usr_thusa_01',
            initialExchanges: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _safeTap(tester, find.byKey(const ValueKey('tab_my_exchanges')));

      expect(
          find.byKey(const ValueKey('view_empty_exchanges')), findsOneWidget);
      expect(find.text('No Skill Exchanges Yet'), findsOneWidget);

      // Tap Discover Partners from empty view
      await _safeTap(
          tester, find.byKey(const ValueKey('btn_go_discover_partners')));
      expect(find.byKey(const ValueKey('input_skill_search')), findsOneWidget);
    });

    testWidgets(
        'Session revocation: changing currentUserId resets dirty search and tab',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestApp(
          const SkillExchangeHubScreen(
            currentUserId: 'usr_thusa_01',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Dirty the search input
      await tester.enterText(
          find.byKey(const ValueKey('input_skill_search')), 'Marcus');
      await tester.pumpAndSettle();

      // Switch user
      await tester.pumpWidget(
        _buildTestApp(
          const SkillExchangeHubScreen(
            currentUserId: 'usr_new_user_99',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search field must be purged
      final searchField = tester
          .widget<TextField>(find.byKey(const ValueKey('input_skill_search')));
      expect(searchField.controller?.text, isEmpty);
    });

    testWidgets(
        'Responsive layouts across 320dp, 360dp, and 412dp viewports without overflow',
        (tester) async {
      final viewports = [
        const Size(320, 600),
        const Size(360, 800),
        const Size(412, 915),
      ];

      for (final size in viewports) {
        _setupTestViewport(tester, size: size);

        await tester.pumpWidget(
          _buildTestApp(
            const SkillExchangeHubScreen(
              currentUserId: 'usr_thusa_01',
            ),
            size: size,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('banner_disconnected_notice')),
            findsOneWidget);
        expect(find.text('Skill Exchange Hub'), findsOneWidget);
      }
    });

    testWidgets(
        'Accessibility: supports 1.5x dynamic text scaling without layout crash',
        (tester) async {
      _setupTestViewport(tester, size: const Size(360, 800));

      await tester.pumpWidget(
        _buildTestApp(
          const SkillExchangeHubScreen(
            currentUserId: 'usr_thusa_01',
          ),
          textScaler: const TextScaler.linear(1.5),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Skill Exchange Hub'), findsOneWidget);
      expect(find.byKey(const ValueKey('banner_disconnected_notice')),
          findsOneWidget);
    });
  });
}
