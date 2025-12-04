import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../data/services/analysis_service.dart';

class AnalysisCard extends StatefulWidget {
  const AnalysisCard({super.key});

  @override
  State<AnalysisCard> createState() => _AnalysisCardState();
}

class _AnalysisCardState extends State<AnalysisCard> {
  List<String> _insights = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadAnalysis() async {
    final service = AnalysisService();
    final results = await Future.wait([
      service.analyzeWaterMoodCorrelation(),
      service.analyzeMoodTrendByDay(),
      service.analyzeMoodTrendByTime(),
    ]);

    if (mounted) {
      setState(() {
        _insights = results.whereType<String>().toList();
        _isLoading = false;
      });

      if (_insights.length > 1) {
        _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
          if (mounted) {
            setState(() {
              _currentIndex = (_currentIndex + 1) % _insights.length;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();
    if (_insights.isEmpty) return const SizedBox.shrink();

    final themeProvider = context.watch<ThemeProvider>();
    final insight = _insights[_currentIndex];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Container(
        key: ValueKey<String>(insight),
        margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeProvider.primaryColor.withValues(alpha: 0.1),
            themeProvider.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themeProvider.primaryColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: themeProvider.surfaceColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.sparkles,
              color: themeProvider.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Insight',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.primaryColor,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  insight,
                  style: TextStyle(
                    fontSize: 15,
                    color: themeProvider.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
