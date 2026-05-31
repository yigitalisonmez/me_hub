import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../../../../core/widgets/page_header.dart';
import '../providers/affirmation_provider.dart';
import '../widgets/record_step.dart';
import '../widgets/session_complete_page.dart';
import '../widgets/session_step.dart';
import '../widgets/step_indicator.dart';
import '../widgets/welcome_step.dart';

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
      context.read<AffirmationProvider>().init();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    final provider = context.read<AffirmationProvider>();
    provider.goToStep(step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _onSessionComplete() {
    setState(() => _showCompletionPage = true);
  }

  void _closeCompletionPage() {
    setState(() => _showCompletionPage = false);
    final provider = context.read<AffirmationProvider>();
    provider.resetFlow();
    _goToStep(0);
  }

  Future<void> _handleBackPress() async {
    final provider = context.read<AffirmationProvider>();
    final themeProvider = context.read<ThemeProvider>();

    if (provider.playbackState != PlaybackState.idle) {
      final shouldLeave = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: themeProvider.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              const Icon(
                LucideIcons.triangleAlert,
                color: AppColors.moodDeep,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'End session?',
                style: TextStyle(
                  color: themeProvider.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          content: Text(
            'Your current session will be stopped before leaving.',
            style: TextStyle(color: themeProvider.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Stay',
                style: TextStyle(color: themeProvider.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mindfulDeep,
              ),
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

    if (provider.sessionJustCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.clearSessionCompleted();
        _onSessionComplete();
      });
    }

    final title = switch (provider.currentStep) {
      0 => 'Affirmations',
      1 => 'Record',
      _ => 'Session',
    };
    final subtitle = switch (provider.currentStep) {
      0 => 'Daily card and sleep flow',
      1 => 'Your own kind words',
      _ => 'Soft loop with calming sound',
    };

    return PopScope(
      canPop: provider.playbackState == PlaybackState.idle,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackPress();
        }
      },
      child: Scaffold(
        backgroundColor: themeProvider.backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: PageHeader(
                  title: title,
                  subtitle: subtitle,
                  showBackButton: true,
                  actionIcon: provider.currentStep == 0
                      ? LucideIcons.bookmark
                      : LucideIcons.ellipsis,
                  onActionTap: provider.currentStep == 0 ? () {} : null,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: provider.currentStep == 0
                    ? Padding(
                        key: const ValueKey('daily_affirmation'),
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: _DailyAffirmationCard(
                          onStartVoiceFlow: () => _goToStep(1),
                        ),
                      )
                    : const SizedBox(height: 18, key: ValueKey('step_spacer')),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: StepIndicator(currentStep: provider.currentStep),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: provider.goToStep,
                  children: [
                    WelcomeStep(onBegin: () => _goToStep(1)),
                    RecordStep(
                      onContinue: () => _goToStep(2),
                      onBack: () => _goToStep(0),
                    ),
                    SessionStep(
                      onComplete: _onSessionComplete,
                      onBack: () => _goToStep(1),
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyAffirmationCard extends StatelessWidget {
  final VoidCallback onStartVoiceFlow;

  const _DailyAffirmationCard({required this.onStartVoiceFlow});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TODAY'S AFFIRMATION",
          style: TextStyle(
            color: AppColors.mindfulDeep,
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        ElevatedCard(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          borderRadius: 28,
          backgroundColor: AppColors.mindfulTint,
          borderColor: AppColors.mindful.withValues(alpha: 0.16),
          child: Column(
            children: [
              Image.asset(
                'assets/images/affirmation.png',
                width: 104,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 2),
              Text(
                'I am calm, capable, and exactly where I need to be.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  height: 1.28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'SELF-COMPASSION',
                style: TextStyle(
                  color: AppColors.mindfulDeep,
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _AffirmAction(icon: LucideIcons.heart, active: true),
                  SizedBox(width: 12),
                  _AffirmAction(icon: LucideIcons.share2),
                  SizedBox(width: 12),
                  _AffirmAction(icon: LucideIcons.shuffle),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onStartVoiceFlow,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.mindfulDeep,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.mindfulDeep.withValues(alpha: 0.26),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    LucideIcons.mic,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sleep Affirmations',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Record your own voice, drift off calm',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xD9FFFFFF),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  LucideIcons.chevronRight,
                  color: Color(0xD9FFFFFF),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.flame, color: AppColors.moodDeep, size: 14),
            const SizedBox(width: 6),
            Text(
              '7 mindful days in a row',
              style: TextStyle(
                color: themeProvider.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AffirmAction extends StatelessWidget {
  final IconData icon;
  final bool active;

  const _AffirmAction({required this.icon, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: active ? AppColors.mindful : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: active ? Colors.white : AppColors.mindfulDeep,
        size: 18,
      ),
    );
  }
}
