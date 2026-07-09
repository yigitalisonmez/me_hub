import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_route.dart';
import '../../../../main.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final LinkedHashSet<String> _selectedFocuses = LinkedHashSet.of({
    'tasks',
    'routines',
    'water',
    'breathing',
  });

  late final AnimationController _floatController;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _goToPage(int page) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _continueFromName() {
    if (_nameController.text.trim().isEmpty) {
      _showMessage('Please enter your name to continue');
      return;
    }
    _goToPage(3);
  }

  Future<void> _completeOnboarding() async {
    if (_isCompleting) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Please enter your name to continue');
      await _goToPage(2);
      return;
    }
    if (_selectedFocuses.isEmpty) {
      _showMessage('Pick at least one focus to continue');
      return;
    }

    setState(() => _isCompleting = true);
    final preferences = await SharedPreferences.getInstance();
    final focuses = _selectedFocuses.toList(growable: false);
    await Future.wait([
      preferences.setBool('onboarding_completed', true),
      preferences.setStringList('user_focus_areas', focuses),
      preferences.setString('user_primary_focus', focuses.first),
      const FlutterSecureStorage().write(key: 'user_name', value: name),
    ]);

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(AppFadeRoute(page: const MainScreen()));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primaryDeep,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeProvider.isDarkMode
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: themeProvider.backgroundColor,
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _WelcomeStep(
              themeProvider: themeProvider,
              floatController: _floatController,
              onContinue: () => _goToPage(1),
            ),
            _IntroStep(
              themeProvider: themeProvider,
              onContinue: () => _goToPage(2),
              onSkip: () => _goToPage(2),
            ),
            _NameStep(
              themeProvider: themeProvider,
              controller: _nameController,
              onBack: () => _goToPage(1),
              onContinue: _continueFromName,
              onChanged: (_) => setState(() {}),
            ),
            _FocusStep(
              themeProvider: themeProvider,
              selectedFocuses: _selectedFocuses,
              isCompleting: _isCompleting,
              onBack: () => _goToPage(2),
              onToggle: (value) {
                setState(() {
                  if (_selectedFocuses.contains(value)) {
                    _selectedFocuses.remove(value);
                  } else {
                    _selectedFocuses.add(value);
                  }
                });
              },
              onComplete: _completeOnboarding,
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({
    required this.themeProvider,
    required this.floatController,
    required this.onContinue,
  });

  final ThemeProvider themeProvider;
  final AnimationController floatController;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final heroHeight = (constraints.maxHeight * 0.44).clamp(300.0, 350.0);
        return SafeArea(
          top: false,
          child: Column(
            children: [
              SizedBox(
                height: heroHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: themeProvider.isDarkMode
                                ? const [
                                    AppColors.darkSurface,
                                    AppColors.darkBackground,
                                  ]
                                : const [
                                    AppColors.surfaceAlt,
                                    AppColors.background,
                                  ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: heroHeight * 0.34,
                      child: Container(
                        width: 230,
                        height: 230,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.30),
                              AppColors.primary.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 5,
                      child: Image.asset(
                        'assets/images/home_page_character.png',
                        width: 290,
                        height: heroHeight - 42,
                        fit: BoxFit.contain,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: floatController,
                      builder: (context, child) {
                        return Positioned(
                          left: 4,
                          top: 92 - (floatController.value * 12),
                          child: child!,
                        );
                      },
                      child: _FloatingArt(
                        asset: 'assets/images/water_glass_check.png',
                        size: 78,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: floatController,
                      builder: (context, child) {
                        return Positioned(
                          right: 4,
                          top: 72 + (floatController.value * 10),
                          child: child!,
                        );
                      },
                      child: _FloatingArt(
                        asset: 'assets/images/mood_circle.png',
                        size: 66,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
                  child: Column(
                    children: [
                      const _KoraWordmark(size: 40),
                      const SizedBox(height: 16),
                      Text(
                        'Your calm, organized day - all in one place.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: themeProvider.textPrimary,
                              fontSize: 25,
                              height: 1.18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tasks, routines, mood and mindfulness, gently woven '
                        'into a daily rhythm.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: themeProvider.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      _PrimaryButton(
                        label: 'Get started',
                        onPressed: onContinue,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IntroStep extends StatelessWidget {
  const _IntroStep({
    required this.themeProvider,
    required this.onContinue,
    required this.onSkip,
  });

  final ThemeProvider themeProvider;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OnboardingTopBar(
              leading: const _KoraWordmark(size: 24),
              trailing: TextButton(
                onPressed: onSkip,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: themeProvider.textTertiary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Text(
              'A gentle space for everything you care about.',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: themeProvider.textPrimary,
                fontSize: 23,
                height: 1.2,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.45,
              ),
            ),
            const SizedBox(height: 22),
            _ValueCard(
              themeProvider: themeProvider,
              asset: 'assets/images/todo_tracker.png',
              title: 'Plan with intention',
              subtitle: 'Tasks & routines that adapt to your day.',
              tint: AppColors.terraTint,
            ),
            const SizedBox(height: 14),
            _ValueCard(
              themeProvider: themeProvider,
              asset: 'assets/images/water_tracker.png',
              title: 'Care for your body',
              subtitle: 'Hydration, mood and energy at a glance.',
              tint: AppColors.waterTint,
            ),
            const SizedBox(height: 14),
            _ValueCard(
              themeProvider: themeProvider,
              asset: 'assets/images/breathing.png',
              title: 'Find a moment of calm',
              subtitle: 'Breathing, gratitude and affirmations.',
              tint: AppColors.mindfulTint,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _ProgressDots(activeIndex: 0),
                _RoundButton(onPressed: onContinue),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({
    required this.themeProvider,
    required this.controller,
    required this.onBack,
    required this.onContinue,
    required this.onChanged,
  });

  final ThemeProvider themeProvider;
  final TextEditingController controller;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        child: Column(
          children: [
            _OnboardingTopBar(
              leading: _BackButton(onPressed: onBack),
              center: const _ProgressDots(activeIndex: 1, compact: true),
              trailing: const SizedBox(width: 44),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 22),
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: themeProvider.isDarkMode
                            ? AppColors.mood.withValues(alpha: 0.16)
                            : AppColors.moodTint,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/images/mood_circle.png',
                        width: 94,
                        height: 94,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'First, what should we call you?',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: themeProvider.textPrimary,
                            fontSize: 23,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.45,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This is how Kora will greet you each day.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: themeProvider.textSecondary,
                        fontSize: 13.5,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'YOUR NAME',
                          style: TextStyle(
                            color: themeProvider.textSecondary,
                            fontSize: 12,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    TextField(
                      key: const Key('onboarding_name_field'),
                      controller: controller,
                      autofocus: false,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      maxLength: 50,
                      onChanged: onChanged,
                      onSubmitted: (_) => onContinue(),
                      style: TextStyle(
                        color: themeProvider.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Your name',
                        hintStyle: TextStyle(
                          color: themeProvider.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: themeProvider.cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _PrimaryButton(label: 'Continue', onPressed: onContinue),
          ],
        ),
      ),
    );
  }
}

class _FocusStep extends StatelessWidget {
  const _FocusStep({
    required this.themeProvider,
    required this.selectedFocuses,
    required this.isCompleting,
    required this.onBack,
    required this.onToggle,
    required this.onComplete,
  });

  static const _items = [
    _FocusItem(
      value: 'tasks',
      title: 'Tasks',
      asset: 'assets/images/todo_tracker.png',
      color: AppColors.primary,
      tint: AppColors.terraTint,
    ),
    _FocusItem(
      value: 'routines',
      title: 'Routines',
      asset: 'assets/images/routine_tracker.png',
      color: AppColors.routine,
      tint: AppColors.routineTint,
    ),
    _FocusItem(
      value: 'water',
      title: 'Water',
      asset: 'assets/images/water_tracker.png',
      color: AppColors.water,
      tint: AppColors.waterTint,
    ),
    _FocusItem(
      value: 'mood',
      title: 'Mood',
      asset: 'assets/images/mood_tracker.png',
      color: AppColors.mood,
      tint: AppColors.moodTint,
    ),
    _FocusItem(
      value: 'breathing',
      title: 'Breathing',
      asset: 'assets/images/breathing.png',
      color: AppColors.mindful,
      tint: AppColors.mindfulTint,
    ),
    _FocusItem(
      value: 'gratitude',
      title: 'Gratitude',
      asset: 'assets/images/gratitude_2.png',
      color: AppColors.mindful,
      tint: AppColors.mindfulTint,
    ),
  ];

  final ThemeProvider themeProvider;
  final Set<String> selectedFocuses;
  final bool isCompleting;
  final VoidCallback onBack;
  final ValueChanged<String> onToggle;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OnboardingTopBar(
              leading: _BackButton(onPressed: onBack),
              center: const _ProgressDots(activeIndex: 2, compact: true),
              trailing: const SizedBox(width: 44),
            ),
            Text(
              'What would you like to focus on?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: themeProvider.textPrimary,
                fontSize: 23,
                height: 1.2,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.45,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pick a few - you can change these anytime.',
              style: TextStyle(
                color: themeProvider.textSecondary,
                fontSize: 13.5,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.28,
                ),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _FocusCard(
                    themeProvider: themeProvider,
                    item: item,
                    selected: selectedFocuses.contains(item.value),
                    onTap: () => onToggle(item.value),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _PrimaryButton(
              label: isCompleting
                  ? 'Getting things ready...'
                  : 'Start my journey',
              onPressed: isCompleting ? null : onComplete,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingTopBar extends StatelessWidget {
  const _OnboardingTopBar({
    required this.leading,
    required this.trailing,
    this.center,
  });

  final Widget leading;
  final Widget trailing;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(alignment: Alignment.centerLeft, child: leading),
          if (center != null) center!,
          Align(alignment: Alignment.centerRight, child: trailing),
        ],
      ),
    );
  }
}

class _KoraWordmark extends StatelessWidget {
  const _KoraWordmark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
      color: AppColors.primary,
      fontSize: size,
      height: 1,
      fontWeight: FontWeight.w800,
      letterSpacing: -size * 0.04,
    );
    final markSize = size * 0.78;

    return Semantics(
      label: 'Kora',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('k', style: textStyle),
            Container(
              width: markSize,
              height: markSize,
              margin: EdgeInsets.symmetric(horizontal: size * 0.02),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.14),
                border: Border.all(
                  color: AppColors.primary,
                  width: size >= 30 ? 2.5 : 2,
                ),
              ),
              child: Icon(
                LucideIcons.check,
                color: AppColors.primary,
                size: markSize * 0.58,
                weight: 3,
              ),
            ),
            Text('ra', style: textStyle),
          ],
        ),
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({
    required this.themeProvider,
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.tint,
  });

  final ThemeProvider themeProvider;
  final String asset;
  final String title;
  final String subtitle;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: themeProvider.textPrimary.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: themeProvider.isDarkMode ? 0.20 : 0.05,
            ),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode
                  ? tint.withValues(alpha: 0.12)
                  : tint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.asset(asset, fit: BoxFit.contain),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: themeProvider.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: themeProvider.textSecondary,
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
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

class _FocusCard extends StatelessWidget {
  const _FocusCard({
    required this.themeProvider,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ThemeProvider themeProvider;
  final _FocusItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
            decoration: BoxDecoration(
              color: selected
                  ? themeProvider.isDarkMode
                        ? item.color.withValues(alpha: 0.14)
                        : item.tint
                  : themeProvider.cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected
                    ? item.color
                    : themeProvider.textPrimary.withValues(alpha: 0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: themeProvider.isDarkMode ? 0.18 : 0.05,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? item.color : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? item.color
                            : themeProvider.textPrimary.withValues(alpha: 0.16),
                        width: 1.5,
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            LucideIcons.check,
                            color: Colors.white,
                            size: 13,
                            weight: 3,
                          )
                        : null,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        item.asset,
                        width: 60,
                        height: 60,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: themeProvider.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
          shape: const StadiumBorder(),
          shadowColor: AppColors.primaryDeep.withValues(alpha: 0.55),
        ).copyWith(elevation: WidgetStateProperty.resolveWith((states) => 0)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            const Icon(LucideIcons.arrowRight, size: 20),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          elevation: 0,
          shape: const CircleBorder(),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        child: const Icon(LucideIcons.arrowRight, size: 22),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: 'Back',
      icon: const Icon(LucideIcons.chevronLeft, size: 22),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.activeIndex, this.compact = false});

  final int activeIndex;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Semantics(
      label: 'Step ${activeIndex + 1} of 3',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final active = index == activeIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: active ? (compact ? 18 : 22) : (compact ? 6 : 7),
              height: compact ? 6 : 7,
              margin: EdgeInsets.only(right: index == 2 ? 0 : 7),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary
                    : themeProvider.textPrimary.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _FloatingArt extends StatelessWidget {
  const _FloatingArt({required this.asset, required this.size});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(asset, width: size, height: size, fit: BoxFit.contain);
  }
}

class _FocusItem {
  const _FocusItem({
    required this.value,
    required this.title,
    required this.asset,
    required this.color,
    required this.tint,
  });

  final String value;
  final String title;
  final String asset;
  final Color color;
  final Color tint;
}
