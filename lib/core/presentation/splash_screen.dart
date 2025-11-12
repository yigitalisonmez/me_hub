import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../services/quote_cache_service.dart';
import '../services/quote_service.dart';

class SplashScreen extends StatefulWidget {
  final Widget child;

  const SplashScreen({super.key, required this.child});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;

  Quote? _quote;
  bool _isLoading = true;
  String _loadingText = 'Loading...';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadQuote();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _textController.forward();
    });
  }

  Future<void> _loadQuote() async {
    setState(() {
      _loadingText = 'Loading...';
    });

    try {
      // API'den quote'u çek
      final quote = await QuoteCacheService.getDailyQuote();

      if (mounted) {
        setState(() {
          _quote = quote;
          _loadingText = 'Ready!';
        });

        // API yanıtı geldikten sonra hemen geçiş yap
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  widget.child,
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingText = 'Ready!';
        });

        // Hata durumunda da hemen geçiş yap
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  widget.child,
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Logo Animation
                AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryOrange.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.sparkles,
                          color: AppColors.white,
                          size: 60,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // App Name Animation
                AnimatedBuilder(
                  animation: _textAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textAnimation.value,
                      child: Column(
                        children: [
                          const Text(
                            'Me Hub',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryOrange,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your Personal Productivity Hub',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.grey,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 60),

                // Simple Loading Indicator
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryOrange,
                    ),
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
