import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class CelebrationMetric {
  final String before;
  final String after;
  final String label;

  const CelebrationMetric({
    required this.before,
    required this.after,
    required this.label,
  });
}

Future<void> showCelebrationDialog({
  required BuildContext context,
  required IconData icon,
  required Color color,
  required String title,
  required String message,
  String eyebrow = 'SMALL WIN',
  String actionLabel = 'Done',
  CelebrationMetric? metric,
}) {
  final disableAnimations = MediaQuery.disableAnimationsOf(context);

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.46),
    transitionDuration: disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 380),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _CelebrationCard(
        icon: icon,
        color: color,
        title: title,
        message: message,
        eyebrow: eyebrow,
        actionLabel: actionLabel,
        metric: metric,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      if (disableAnimations) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.86, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _CelebrationCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String eyebrow;
  final String actionLabel;
  final CelebrationMetric? metric;

  const _CelebrationCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.eyebrow,
    required this.actionLabel,
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return SafeArea(
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 326,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: color.withValues(alpha: 0.20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 42,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.72, end: 1),
                  duration: disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 620),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: color.withValues(
                        alpha: theme.isDarkMode ? 0.18 : 0.13,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 42),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  eyebrow,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.25,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 24,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 13.5,
                    height: 1.42,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (metric != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(
                        alpha: theme.isDarkMode ? 0.14 : 0.09,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          metric!.before,
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: color,
                            size: 20,
                          ),
                        ),
                        Text(
                          metric!.after,
                          style: TextStyle(
                            color: color,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          metric!.label,
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: Text(
                      actionLabel,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
