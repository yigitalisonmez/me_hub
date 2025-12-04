import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../main.dart'; // For HomePage navigation

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (_nameController.text.isNotEmpty) {
      await prefs.setString('user_name', _nameController.text.trim());
    }
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
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
            _buildNamePage(themeProvider),
            _buildFocusPage(themeProvider),
          ],
          onDone: _completeOnboarding,
          onSkip: _completeOnboarding, // Optional: Allow skipping
          showSkipButton: false,
          showBackButton: true,
          back: const Icon(Icons.arrow_back),
          next: const Icon(Icons.arrow_forward),
          done: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.w600)),
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
      title: "Welcome to MeHub",
      body: "Your all-in-one personal companion for habits, mood, and hydration.",
      image: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: themeProvider.primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          LucideIcons.sparkles,
          size: 80,
          color: themeProvider.primaryColor,
        ),
      ),
      decoration: PageDecoration(
        titleTextStyle: TextStyle(
          fontSize: 28.0, 
          fontWeight: FontWeight.w700,
          color: themeProvider.textPrimary,
        ),
        bodyTextStyle: TextStyle(
          fontSize: 18.0,
          color: themeProvider.textSecondary,
        ),
        pageColor: themeProvider.backgroundColor,
        imagePadding: const EdgeInsets.all(24),
      ),
    );
  }

  PageViewModel _buildNamePage(ThemeProvider themeProvider) {
    return PageViewModel(
      title: "Let's get to know you",
      bodyWidget: Column(
        children: [
          Text(
            "What should we call you?",
            style: TextStyle(
              fontSize: 18.0,
              color: themeProvider.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            autofocus: true,
            style: TextStyle(
              fontSize: 24,
              color: themeProvider.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Your Name',
              hintStyle: TextStyle(
                color: themeProvider.textSecondary.withValues(alpha: 0.5),
              ),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: themeProvider.primaryColor),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: themeProvider.borderColor),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: themeProvider.primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      decoration: PageDecoration(
        titleTextStyle: TextStyle(
          fontSize: 28.0, 
          fontWeight: FontWeight.w700,
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
          _buildFocusOption(
            themeProvider,
            'Build Habits',
            LucideIcons.repeat,
            'routines',
          ),
          const SizedBox(height: 16),
          _buildFocusOption(
            themeProvider,
            'Track Mood',
            LucideIcons.heart,
            'mood',
          ),
          const SizedBox(height: 16),
          _buildFocusOption(
            themeProvider,
            'Stay Hydrated',
            LucideIcons.droplet,
            'water',
          ),
        ],
      ),
      decoration: PageDecoration(
        titleTextStyle: TextStyle(
          fontSize: 28.0, 
          fontWeight: FontWeight.w700,
          color: themeProvider.textPrimary,
        ),
        pageColor: themeProvider.backgroundColor,
        bodyAlignment: Alignment.center,
      ),
    );
  }

  Widget _buildFocusOption(
    ThemeProvider themeProvider,
    String title,
    IconData icon,
    String value,
  ) {
    final isSelected = _selectedFocus == value;
    
    return InkWell(
      onTap: () => setState(() => _selectedFocus = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected 
              ? themeProvider.primaryColor.withValues(alpha: 0.1)
              : themeProvider.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? themeProvider.primaryColor : themeProvider.borderColor,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? themeProvider.primaryColor : themeProvider.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isSelected ? themeProvider.primaryColor : themeProvider.textPrimary,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: themeProvider.primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
