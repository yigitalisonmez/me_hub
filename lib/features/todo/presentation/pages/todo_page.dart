import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/layout_constants.dart';
import '../providers/todo_provider.dart';

import '../widgets/todo_card_widget.dart';
import '../../../../core/providers/theme_provider.dart';

import '../../../../core/services/quote_cache_service.dart';
import '../../../../core/services/quote_service.dart';
import '../../../../core/widgets/glass_container.dart';

/// Ana todo sayfası - main.dart'taki todo gösterim kodlarından taşındı
class TodoPage extends StatefulWidget {
  final bool showFullPage;

  const TodoPage({super.key, this.showFullPage = true});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  Quote? _quote;
  bool _isLoadingQuote = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodoProvider>().loadTodayTodos();
    });
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    try {
      final quote = await QuoteCacheService.getDailyQuote();
      if (mounted) {
        setState(() {
          _quote = quote;
          _isLoadingQuote = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingQuote = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    // Main content with Hero Card and Todo List
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroCard(themeProvider),
        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [const TodoCardWidget()],
          ),
        ),
        SizedBox(height: LayoutConstants.getNavbarClearance(context)),
      ],
    );

    if (widget.showFullPage) {
      return Scaffold(
        backgroundColor: themeProvider.backgroundColor,
        body: SingleChildScrollView(child: Column(children: [content])),
      );
    } else {
      return SafeArea(child: SingleChildScrollView(child: content));
    }
  }

  Widget _buildHeroCard(ThemeProvider themeProvider) {
    return Container(
      height: 320,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.primaryColor, // Using primary color as requested
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Pattern or Gradient (Optional)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    themeProvider.primaryColor.withValues(alpha: 0.8),
                    themeProvider.primaryColor,
                  ],
                ),
              ),
            ),
          ),

          // 3D Clay Asset
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            bottom: 60, // Adjusted to give space for the glass card
            child: Center(
              child: Image.asset(
                'assets/images/home_page_character.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Glassmorphism Overlay
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoadingQuote)
                    const Text(
                      'Loading inspiration...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else if (_quote != null) ...[
                    Text(
                      '"${_quote!.text}"',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '— ${_quote!.author}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else
                    const Text(
                      'Improve creativity.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Top Bar (Menu & Profile) - Visual only for now as per screenshot
        ],
      ),
    );
  }
}
