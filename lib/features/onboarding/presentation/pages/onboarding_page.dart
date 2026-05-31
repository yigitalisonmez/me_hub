import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_route.dart';
import '../../../../main.dart'; // For MainScreen navigation

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _introKey = GlobalKey<IntroductionScreenState>();
  final TextEditingController _nameController = TextEditingController();
  String? _selectedFocus;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your name to continue'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      // Name page is index 2
      _introKey.currentState?.animateScroll(2);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    // Persist the user's focus selection for personalization
    if (_selectedFocus != null) {
      await prefs.setString('user_primary_focus', _selectedFocus!);
    }

    // Securely store user name
    const secureStorage = FlutterSecureStorage();
    await secureStorage.write(key: 'user_name', value: name);

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(AppFadeRoute(page: const MainScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: SafeArea(
        child: IntroductionScreen(
          key: _introKey,
          globalBackgroundColor: themeProvider.backgroundColor,
          allowImplicitScrolling: true,
          autoScrollDuration: null,
          pages: [
            _buildWelcomePage(themeProvider),
            _buildIntroPage(themeProvider),
            _buildNamePage(themeProvider),
            _buildFocusPage(themeProvider),
          ],
          onDone: _completeOnboarding,
          onSkip: _completeOnboarding, // Optional: Allow skipping
          showSkipButton: false,
          showBackButton: true,
          back: const Icon(Icons.arrow_back),
          next: const Icon(Icons.arrow_forward),
          done: const Text(
            'Get Started',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          curve: Curves.fastLinearToSlowEaseIn,
          controlsMargin: const EdgeInsets.all(16),
          controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
          dotsDecorator: DotsDecorator(
            size: const Size(10.0, 10.0),
            color: themeProvider.borderColor,
            activeSize: const Size(22.0, 10.0),
            activeShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0),
            ),
            activeColor: themeProvider.primaryColor,
          ),
          baseBtnStyle: TextButton.styleFrom(
            foregroundColor: themeProvider.primaryColor,
          ),
          doneStyle: TextButton.styleFrom(
            foregroundColor: themeProvider.primaryColor,
          ),
        ),
      ),
    );
  }

  PageViewModel _buildWelcomePage(ThemeProvider themeProvider) {
    return PageViewModel(
      title: "Welcome to Kora",
      body:
          "A calmer place to plan your day, track your wellbeing, and keep small promises to yourself.",
      image: _buildWelcomeHero(themeProvider),
      decoration: _pageDecoration(themeProvider),
    );
  }

  PageViewModel _buildIntroPage(ThemeProvider themeProvider) {
    return PageViewModel(
      title: "Everything has its place",
      bodyWidget: Column(
        children: [
          Text(
            "Kora brings your daily rhythm into one soft, scannable dashboard.",
            style: TextStyle(
              color: themeProvider.textSecondary,
              fontSize: 16,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildIntroRow(
            themeProvider,
            'Plan',
            'Tasks, routines, calendar and focus sessions.',
            'assets/images/tasks_card_1.png',
            AppColors.primary,
          ),
          const SizedBox(height: 14),
          _buildIntroRow(
            themeProvider,
            'Care',
            'Water, mood and mindful pauses without noise.',
            'assets/images/mood_card_1.png',
            AppColors.mood,
          ),
          const SizedBox(height: 14),
          _buildIntroRow(
            themeProvider,
            'Reflect',
            'Gratitude, affirmations and gentle progress.',
            'assets/images/gratitude_2.png',
            AppColors.routine,
          ),
        ],
      ),
      decoration: _pageDecoration(themeProvider),
    );
  }

  PageViewModel _buildNamePage(ThemeProvider themeProvider) {
    return PageViewModel(
      title: "Let's get to know you",
      image: Center(
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.terraTint,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: themeProvider.primaryColor.withValues(alpha: 0.16),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Image.asset('assets/images/app_logo.png'),
          ),
        ),
      ),
      bodyWidget: Column(
        children: [
          Text(
            "What should we call you?",
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.w700,
              color: themeProvider.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          TextField(
            controller: _nameController,
            textAlign: TextAlign.center,
            maxLength: 50, // Security: Limit input length
            style: TextStyle(
              fontSize: 24,
              color: themeProvider.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: 'Your Name',
              hintStyle: TextStyle(
                color: themeProvider.textSecondary.withValues(alpha: 0.3),
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: themeProvider.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide(
                  color: themeProvider.primaryColor.withValues(alpha: 0.24),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide(
                  color: themeProvider.primaryColor.withValues(alpha: 0.18),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide(
                  color: themeProvider.primaryColor.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 24,
                horizontal: 32,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      decoration: PageDecoration(
        titleTextStyle: TextStyle(
          fontSize: 28.0,
          fontWeight: FontWeight.w800,
          color: themeProvider.textPrimary,
        ),
        pageColor: themeProvider.backgroundColor,
        bodyAlignment: Alignment.center,
      ),
    );
  }

  PageViewModel _buildFocusPage(ThemeProvider themeProvider) {
    return PageViewModel(
      title: "What's your main focus?",
      bodyWidget: Column(
        children: [
          Text(
            "We'll help you customize your experience.",
            style: TextStyle(
              fontSize: 16.0,
              color: themeProvider.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.96,
            children: [
              _buildFocusOption(
                themeProvider,
                'Build Habits',
                'assets/images/routine_tracker.png',
                AppColors.routine,
                'routines',
              ),
              _buildFocusOption(
                themeProvider,
                'Track Mood',
                'assets/images/mood_circle.png',
                AppColors.mood,
                'mood',
              ),
              _buildFocusOption(
                themeProvider,
                'Stay Hydrated',
                'assets/images/water_tracker.png',
                AppColors.water,
                'water',
              ),
              _buildFocusOption(
                themeProvider,
                'Plan Better',
                'assets/images/checklist_2.png',
                AppColors.primary,
                'tasks',
              ),
            ],
          ),
        ],
      ),
      decoration: _pageDecoration(
        themeProvider,
      ).copyWith(bodyAlignment: Alignment.center),
    );
  }

  Widget _buildFocusOption(
    ThemeProvider themeProvider,
    String title,
    String imagePath,
    Color color,
    String value,
  ) {
    final isSelected = _selectedFocus == value;

    return InkWell(
      onTap: () => setState(() => _selectedFocus = value),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: themeProvider.isDarkMode ? 0.16 : 0.12)
              : themeProvider.cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? color : themeProvider.borderColor,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(child: Image.asset(imagePath, fit: BoxFit.contain)),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isSelected ? color : themeProvider.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 20)
            else
              Icon(
                LucideIcons.circle,
                color: themeProvider.textTertiary.withValues(alpha: 0.42),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHero(ThemeProvider themeProvider) {
    return SizedBox(
      height: 330,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              color: AppColors.terraTint,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: themeProvider.primaryColor.withValues(alpha: 0.16),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            child: Image.asset(
              'assets/images/home_page_character.png',
              height: 250,
            ),
          ),
          Positioned(
            top: 26,
            left: 18,
            child: _floatingAsset('assets/images/tasks_card_1.png', 80),
          ),
          Positioned(
            top: 42,
            right: 20,
            child: _floatingAsset('assets/images/mood_card_1.png', 70),
          ),
        ],
      ),
    );
  }

  Widget _floatingAsset(String path, double size) {
    return Image.asset(path, width: size, height: size, fit: BoxFit.contain);
  }

  Widget _buildIntroRow(
    ThemeProvider themeProvider,
    String title,
    String subtitle,
    String asset,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: themeProvider.isDarkMode
              ? Colors.white.withValues(alpha: 0.07)
              : AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
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
                  style: TextStyle(
                    color: themeProvider.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: themeProvider.textSecondary,
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PageDecoration _pageDecoration(ThemeProvider themeProvider) {
    return PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 29.0,
        fontWeight: FontWeight.w800,
        color: themeProvider.textPrimary,
        height: 1.12,
      ),
      bodyTextStyle: TextStyle(
        fontSize: 16.0,
        color: themeProvider.textSecondary,
        height: 1.45,
        fontWeight: FontWeight.w600,
      ),
      pageColor: themeProvider.backgroundColor,
      imagePadding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
      bodyAlignment: Alignment.center,
      titlePadding: const EdgeInsets.symmetric(horizontal: 18),
      bodyPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}
