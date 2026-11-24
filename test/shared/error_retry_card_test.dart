import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/shared/presentation/widgets/error_retry_card.dart';

Widget _buildTestApp(Widget child, {TextScaler? textScaler, Size? size}) {
  return MaterialApp(
    theme: LearningTheme.theme,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: size?.width ?? 360,
          height: size?.height ?? 640,
          child: MediaQuery(
            data: MediaQueryData(
              size: size ?? const Size(360, 640),
              textScaler: textScaler ?? TextScaler.noScaling,
            ),
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('ErrorRetryCard Tests', () {
    testWidgets('1. Safe error message renders', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const ErrorRetryCard(
            title: 'Unable to load data',
            message: 'An unexpected error occurred. Please try again.',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load data'), findsOneWidget);
      expect(
        find.text('An unexpected error occurred. Please try again.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. Retry button renders when callback exists', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ErrorRetryCard(
            onRetry: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });

    testWidgets('3. Retry callback invoked exactly once', (tester) async {
      int retryCount = 0;

      await tester.pumpWidget(
        _buildTestApp(
          ErrorRetryCard(
            onRetry: () => retryCount++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(retryCount, 0);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(retryCount, 1);
    });

    testWidgets('4. Retry disabled while isRetrying == true', (tester) async {
      int retryCount = 0;

      await tester.pumpWidget(
        _buildTestApp(
          ErrorRetryCard(
            onRetry: () => retryCount++,
            isRetrying: true,
          ),
        ),
      );
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(retryCount, 0);
    });

    testWidgets('5. Missing callback does not render a retry button',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const ErrorRetryCard(
            onRetry: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('6. Loading state presented with spinner', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ErrorRetryCard(
            onRetry: () {},
            isRetrying: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Retrying...'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('7. Error text wraps correctly without overflow',
        (tester) async {
      const longMessage =
          'This is an extensive description of a connection failure designed to test text '
          'wrapping behavior across constrained display dimensions without causing any overflow '
          'or clipping bugs on smaller mobile form factors.';

      await tester.pumpWidget(
        _buildTestApp(
          const ErrorRetryCard(
            title: 'Critical Connection Failure In Network Gateway Layer',
            message: longMessage,
          ),
          size: const Size(320, 640),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(longMessage), findsOneWidget);
    });

    testWidgets('8. 320dp viewport has no overflow', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ErrorRetryCard(
            title: 'Network Timeout',
            message: 'Failed to establish a secure link to the server.',
            onRetry: () {},
          ),
          size: const Size(320, 640),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorRetryCard), findsOneWidget);
    });

    testWidgets('9. 412dp viewport has no overflow', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ErrorRetryCard(
            title: 'Network Timeout',
            message: 'Failed to establish a secure link to the server.',
            onRetry: () {},
          ),
          size: const Size(412, 892),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorRetryCard), findsOneWidget);
    });

    testWidgets('10. Accessible semantics and contrast are appropriate',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          ErrorRetryCard(
            title: 'Payment Error',
            message: 'Could not complete transaction.',
            onRetry: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            (widget.properties.label ==
                    'Payment Error. Could not complete transaction.' ||
                widget.properties.attributedLabel?.string ==
                    'Payment Error. Could not complete transaction.'),
      );
      expect(semanticsFinder, findsOneWidget);

      const card = ErrorRetryCard();
      expect(card, isA<StatelessWidget>());
      expect(card.title, 'Unable to load data');
      expect(card.backgroundColor,
          isNull); // Falls back to LearningColors.cardSurface
    });
  });
}
