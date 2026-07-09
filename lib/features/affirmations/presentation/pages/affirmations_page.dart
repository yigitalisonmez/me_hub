import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/utils/app_route.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/affirmation_provider.dart';
import '../widgets/record_step.dart';
import '../widgets/session_complete_page.dart';
import '../widgets/session_step.dart';
import '../widgets/welcome_step.dart';

// ─────────────────────────────────────────────
// Daily Card — main affirmations screen
// ─────────────────────────────────────────────
class AffirmationsPage extends StatefulWidget {
  const AffirmationsPage({super.key});

  @override
  State<AffirmationsPage> createState() => _AffirmationsPageState();
}

class _AffirmationsPageState extends State<AffirmationsPage> {
  static const _affirmations = [
    ('I am calm, capable, and exactly where I need to be.', 'Self-Compassion'),
    ('My presence is enough.', 'Mindfulness'),
    ('I trust the process of my growth.', 'Growth'),
    ('Rest is part of the work.', 'Balance'),
    ('I choose peace in every moment.', 'Inner Peace'),
    ('I am worthy of good things.', 'Self-Worth'),
  ];

  late final int _todayIndex;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _todayIndex =
        (now.year * 365 + now.month * 31 + now.day) % _affirmations.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AffirmationProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final provider = context.watch<AffirmationProvider>();
    final (quote, category) = _affirmations[_todayIndex];
    final streak = provider.totalCompletedSessions;

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.mindfulTint, themeProvider.backgroundColor],
            stops: const [0.0, 0.45],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(context, themeProvider),
                const SizedBox(height: 18),
                Text(
                  "TODAY'S AFFIRMATION",
                  style: TextStyle(
                    color: AppColors.mindfulDeep,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 10),
                _buildAffirmationCard(context, themeProvider, quote, category),
                const SizedBox(height: 14),
                _buildStreak(themeProvider, streak),
                const SizedBox(height: 18),
                _buildSleepCta(context, themeProvider),
                const SizedBox(height: 22),
                Text(
                  'SAVED',
                  style: TextStyle(
                    color: themeProvider.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 10),
                _buildSavedList(themeProvider, provider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, ThemeProvider tp) {
    return Row(
      children: [
        _TopBarButton(
          icon: LucideIcons.chevronLeft,
          onTap: () => Navigator.of(context).maybePop(),
          themeProvider: tp,
        ),
        const Spacer(),
        Text(
          'Affirmations',
          style: TextStyle(
            color: tp.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        _TopBarButton(
          icon: LucideIcons.bookmark,
          onTap: () {},
          themeProvider: tp,
        ),
      ],
    );
  }

  Widget _buildAffirmationCard(
    BuildContext context,
    ThemeProvider tp,
    String quote,
    String category,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.mindfulTint, Color(0xFFFDFBF7)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.mindful.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/affirmation.png',
            width: 116,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(height: 10),
          Text(
            quote,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.toUpperCase(),
            style: const TextStyle(
              color: AppColors.mindfulDeep,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(
                icon: LucideIcons.heart,
                filled: true,
                color: AppColors.mindful,
                onTap: () {},
              ),
              const SizedBox(width: 12),
              _ActionButton(
                icon: LucideIcons.share,
                onTap: () {},
                themeProvider: tp,
              ),
              const SizedBox(width: 12),
              _ActionButton(
                icon: LucideIcons.shuffle,
                onTap: () {},
                themeProvider: tp,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreak(ThemeProvider tp, int sessions) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.flame, size: 14, color: AppColors.moodDeep),
          const SizedBox(width: 6),
          Text(
            sessions > 0
                ? '$sessions mindful session${sessions == 1 ? '' : 's'} completed'
                : '7 mindful days in a row',
            style: TextStyle(
              color: tp.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepCta(BuildContext context, ThemeProvider tp) {
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(AppRoute(page: const _SleepAffirmationsFlowPage())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.mindfulDeep,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.mindful.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
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
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(LucideIcons.mic, size: 22, color: Colors.white),
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Record your own voice · drift off calm',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedList(ThemeProvider tp, AffirmationProvider provider) {
    final saved = provider.savedRecordings;
    if (saved.isEmpty) {
      return _SavedRow(text: 'I trust my own pace.', tp: tp);
    }
    return Column(
      children: saved
          .take(3)
          .map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SavedRow(text: r.name, tp: tp),
            ),
          )
          .toList(),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final ThemeProvider themeProvider;

  const _TopBarButton({
    required this.icon,
    required this.onTap,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: themeProvider.textSecondary.withValues(alpha: 0.12),
          ),
        ),
        child: Icon(icon, size: 19, color: themeProvider.textPrimary),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final Color? color;
  final VoidCallback onTap;
  final ThemeProvider? themeProvider;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.color,
    this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: filled
              ? (color ?? AppColors.mindful)
              : (themeProvider?.cardColor ?? Colors.white),
          shape: BoxShape.circle,
          border: filled
              ? null
              : Border.all(
                  color:
                      themeProvider?.textSecondary.withValues(alpha: 0.16) ??
                      AppColors.textSecondary.withValues(alpha: 0.16),
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 18,
          color: filled ? Colors.white : (color ?? AppColors.mindfulDeep),
        ),
      ),
    );
  }
}

class _SavedRow extends StatelessWidget {
  final String text;
  final ThemeProvider tp;

  const _SavedRow({required this.text, required this.tp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tp.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tp.textSecondary.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.heart, size: 14, color: AppColors.mindful),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: tp.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sleep affirmations 3-step flow
// ─────────────────────────────────────────────
class _SleepAffirmationsFlowPage extends StatefulWidget {
  const _SleepAffirmationsFlowPage();

  @override
  State<_SleepAffirmationsFlowPage> createState() =>
      _SleepAffirmationsFlowPageState();
}

class _SleepAffirmationsFlowPageState
    extends State<_SleepAffirmationsFlowPage> {
  late PageController _pageController;
  bool _showCompletionPage = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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

  void _onSessionComplete() => setState(() => _showCompletionPage = true);

  void _closeCompletionPage() {
    setState(() => _showCompletionPage = false);
    context.read<AffirmationProvider>().resetFlow();
    _goToStep(0);
  }

  Future<bool> _confirmLeave() async {
    final provider = context.read<AffirmationProvider>();
    final themeProvider = context.read<ThemeProvider>();

    if (provider.playbackState == PlaybackState.idle) {
      if (provider.currentStep > 0) {
        _goToStep(provider.currentStep - 1);
        return false;
      }
      return true;
    }

    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeProvider.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
    if (leave == true) await provider.stopPlayback();
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_showCompletionPage) {
      return SessionCompletePage(onClose: _closeCompletionPage);
    }

    final provider = context.watch<AffirmationProvider>();

    if (provider.sessionJustCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.clearSessionCompleted();
        _onSessionComplete();
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        final shouldPop = await _confirmLeave();
        if (!mounted) return;
        if (shouldPop) nav.pop();
      },
      child: Scaffold(
        backgroundColor: context.watch<ThemeProvider>().backgroundColor,
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: provider.goToStep,
          children: [
            WelcomeStep(
              onBegin: () => _goToStep(1),
              onBack: () => Navigator.of(context).pop(),
            ),
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
    );
  }
}
