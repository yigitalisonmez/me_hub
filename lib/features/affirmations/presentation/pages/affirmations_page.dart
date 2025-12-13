import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/theme_provider.dart';
import '../providers/affirmation_provider.dart';
import '../widgets/step_indicator.dart';
import '../widgets/welcome_step.dart';
import '../widgets/record_step.dart';
import '../widgets/session_step.dart';
import '../widgets/session_complete_page.dart';

/// Main page for the Affirmations feature - 3-step guided flow
class AffirmationsPage extends StatefulWidget {
  const AffirmationsPage({super.key});

  @override
  State<AffirmationsPage> createState() => _AffirmationsPageState();
}

class _AffirmationsPageState extends State<AffirmationsPage> {
  late PageController _pageController;
  bool _showCompletionPage = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initProvider();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initProvider() async {
    final provider = context.read<AffirmationProvider>();
    await provider.init();
  }

  void _goToStep(int step) {
    final provider = context.read<AffirmationProvider>();
    provider.goToStep(step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _onSessionComplete() {
    setState(() {
      _showCompletionPage = true;
    });
  }

  void _closeCompletionPage() {
    setState(() {
      _showCompletionPage = false;
    });
    final provider = context.read<AffirmationProvider>();
    provider.resetFlow();
    _goToStep(0);
  }

  Future<void> _handleBackPress() async {
    final provider = context.read<AffirmationProvider>();
    final themeProvider = context.read<ThemeProvider>();

    // If session is playing, show confirmation
    if (provider.playbackState != PlaybackState.idle) {
      final shouldLeave = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: themeProvider.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(LucideIcons.triangleAlert, color: Colors.amber, size: 24),
              const SizedBox(width: 12),
              Text(
                'End Session?',
                style: TextStyle(color: themeProvider.textPrimary),
              ),
            ],
          ),
          content: Text(
            'Your current session will be stopped. Are you sure you want to leave?',
            style: TextStyle(color: themeProvider.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Stay',
                style: TextStyle(color: themeProvider.primaryColor),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Leave', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (shouldLeave == true) {
        await provider.stopPlayback();
        if (mounted) Navigator.of(context).pop();
      }
      return;
    }

    // Normal back navigation
    if (provider.currentStep > 0) {
      _goToStep(provider.currentStep - 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showCompletionPage) {
      return SessionCompletePage(onClose: _closeCompletionPage);
    }

    final themeProvider = context.watch<ThemeProvider>();
    final provider = context.watch<AffirmationProvider>();

    // Check if session completed
    if (provider.playbackState != PlaybackState.idle &&
        provider.remainingDuration.inSeconds == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onSessionComplete();
      });
    }

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Colorful gradient header
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: themeProvider.backgroundColor,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
              onPressed: _handleBackPress,
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Affirmations',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      themeProvider.primaryColor,
                      themeProvider.primaryColor.withValues(alpha: 0.7),
                      themeProvider.backgroundColor,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 60,
                      right: 40,
                      child: Icon(
                        LucideIcons.moon,
                        size: 32,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 100,
                      child: Icon(
                        LucideIcons.sparkles,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Step indicator + Pages
          SliverFillRemaining(
            child: Column(
              children: [
                // Step indicator
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: StepIndicator(currentStep: provider.currentStep),
                ),

                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      provider.goToStep(index);
                    },
                    children: [
                      // Step 1: Welcome
                      WelcomeStep(onBegin: () => _goToStep(1)),

                      // Step 2: Record/Select
                      RecordStep(
                        onContinue: () => _goToStep(2),
                        onBack: () => _goToStep(0),
                      ),

                      // Step 3: Session
                      SessionStep(
                        onComplete: _onSessionComplete,
                        onBack: () => _goToStep(1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
