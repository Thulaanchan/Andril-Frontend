import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/social/home/widgets/social_prototype_navigation.dart';

void main() {
  testWidgets(
      'all five destinations have accessible taps and retain selected state',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = 0;
    final taps = <int>[];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: StatefulBuilder(
                builder: (context, setState) => SocialPrototypeNavigation(
                    currentIndex: selected,
                    onTap: (index) {
                      taps.add(index);
                      setState(() => selected = index);
                    })))));
    final semantics = tester.ensureSemantics();
    for (final (index, label)
        in ['Home', 'Zones', 'Explore', 'Chat', 'Profile'].indexed) {
      final finder = find.bySemanticsLabel(RegExp('^$label tab'));
      expect(finder, findsOneWidget);
      expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(finder).width, greaterThanOrEqualTo(48));
      await tester.tap(finder);
      await tester.pumpAndSettle();
      expect(selected, index);
      expect(find.bySemanticsLabel('$label tab, selected'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    expect(taps, [0, 1, 2, 3, 4]);
    semantics.dispose();
  });

  testWidgets(
      'keyboard hides dock; reduced motion disables tab movement animations',
      (tester) async {
    var selected = 0;
    var keyboard = false;
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: StatefulBuilder(builder: (context, setState) {
      update = setState;
      return MediaQuery(
          data: MediaQuery.of(context).copyWith(
              disableAnimations: true,
              viewInsets: EdgeInsets.only(bottom: keyboard ? 300 : 0)),
          child: SocialPrototypeNavigation(
              currentIndex: selected,
              onTap: (index) => setState(() => selected = index)));
    }))));
    await tester.tap(find.text('Zones'));
    await tester.pump();
    await tester.pump();
    expect(selected, 1);
    expect(
        tester
            .widgetList<AnimatedScale>(find.byType(AnimatedScale))
            .every((widget) => widget.duration == Duration.zero),
        isTrue);
    expect(
        tester
            .widgetList<AnimatedDefaultTextStyle>(find.descendant(
                of: find.byType(SocialPrototypeNavigation),
                matching: find.byType(AnimatedDefaultTextStyle)))
            .every((widget) => widget.duration == Duration.zero),
        isTrue);
    update(() => keyboard = true);
    await tester.pump();
    expect(find.text('Zones'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
