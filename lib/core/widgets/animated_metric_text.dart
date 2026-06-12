import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';

/// Displays a numeric metric with a rolling digit transition.
class AnimatedMetricText extends StatelessWidget {
  final num value;
  final TextStyle style;
  final int fractionDigits;
  final String? prefix;
  final String? suffix;
  final String? semanticLabel;
  final Duration duration;
  final Curve curve;
  final bool animateOnFirstBuild;

  const AnimatedMetricText({
    super.key,
    required this.value,
    required this.style,
    this.fractionDigits = 0,
    this.prefix,
    this.suffix,
    this.semanticLabel,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutCubic,
    this.animateOnFirstBuild = true,
  });

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final metric = disableAnimations
        ? Text(_formattedDisplayValue, style: style)
        : AnimatedDigitWidget(
            value: value,
            textStyle: style,
            fractionDigits: fractionDigits,
            prefix: prefix,
            suffix: suffix,
            duration: duration,
            curve: curve,
            loop: false,
            autoSize: true,
            animateAutoSize: true,
            animateUnchangedDigits: false,
            firstScrollAnimate: animateOnFirstBuild,
          );

    return Semantics(
      label: semanticLabel ?? _formattedDisplayValue,
      child: ExcludeSemantics(child: metric),
    );
  }

  String get _formattedValue => value.toStringAsFixed(fractionDigits);

  String get _formattedDisplayValue =>
      '${prefix ?? ''}$_formattedValue${suffix ?? ''}';
}
