import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:me_hub/core/widgets/animated_metric_text.dart';

void main() {
  Widget buildSubject({
    required num value,
    int fractionDigits = 0,
    bool disableAnimations = false,
    String? suffix,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Material(
          child: AnimatedMetricText(
            value: value,
            fractionDigits: fractionDigits,
            suffix: suffix,
            semanticLabel: '$value liters',
            style: const TextStyle(fontSize: 32),
          ),
        ),
      ),
    );
  }

  testWidgets('configures the rolling value and decimal precision', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(value: 1.25, fractionDigits: 2));

    final widget = tester.widget<AnimatedDigitWidget>(
      find.byType(AnimatedDigitWidget),
    );
    expect(widget.value, 1.25);
    expect(widget.fractionDigits, 2);
    expect(widget.firstScrollAnimate, isTrue);
    expect(widget.duration, const Duration(milliseconds: 500));
  });

  testWidgets('handles water metric precision changes without errors', (
    tester,
  ) async {
    const values = <(num, int)>[(0, 0), (0.25, 2), (1, 0), (1.25, 2)];

    for (final (value, fractionDigits) in values) {
      await tester.pumpWidget(
        buildSubject(value: value, fractionDigits: fractionDigits),
      );
      await tester.pump(const Duration(milliseconds: 550));

      final widget = tester.widget<AnimatedDigitWidget>(
        find.byType(AnimatedDigitWidget),
      );
      expect(widget.value, value);
      expect(widget.fractionDigits, fractionDigits);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('exposes one accessible label', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(buildSubject(value: 0.25, fractionDigits: 2));

    expect(find.bySemanticsLabel('0.25 liters'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('renders suffixes in animated and reduced-motion modes', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(value: 1.3, fractionDigits: 1, suffix: 'L'),
    );

    final animated = tester.widget<AnimatedDigitWidget>(
      find.byType(AnimatedDigitWidget),
    );
    expect(animated.suffix, 'L');

    await tester.pumpWidget(
      buildSubject(
        value: 1.3,
        fractionDigits: 1,
        suffix: 'L',
        disableAnimations: true,
      ),
    );
    expect(find.text('1.3L'), findsOneWidget);
  });

  testWidgets('updates six low-frequency metrics together', (tester) async {
    Widget buildMetrics(List<int> values) {
      return MaterialApp(
        home: Material(
          child: Row(
            children: values
                .map(
                  (value) => AnimatedMetricText(
                    value: value,
                    style: const TextStyle(fontSize: 18),
                  ),
                )
                .toList(),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildMetrics([1, 2, 3, 4, 5, 6]));
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pumpWidget(buildMetrics([2, 3, 4, 5, 6, 7]));
    await tester.pump(const Duration(milliseconds: 550));

    expect(find.byType(AnimatedDigitWidget), findsNWidgets(6));
    expect(tester.takeException(), isNull);
  });

  testWidgets('disables rolling motion when reduced motion is requested', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(value: 1.25, fractionDigits: 2, disableAnimations: true),
    );

    expect(find.byType(AnimatedDigitWidget), findsNothing);
    expect(find.text('1.25'), findsOneWidget);

    await tester.pumpWidget(
      buildSubject(value: 1.5, fractionDigits: 2, disableAnimations: true),
    );
    await tester.pump();
    expect(find.text('1.50'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
