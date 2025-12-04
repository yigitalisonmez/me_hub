import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/elevated_card.dart';

import '../../../../core/services/quote_cache_service.dart';
import '../../../../core/services/quote_service.dart';

class DailyQuoteWidget extends StatefulWidget {
  const DailyQuoteWidget({super.key});

  @override
  State<DailyQuoteWidget> createState() => _DailyQuoteWidgetState();
}

class _DailyQuoteWidgetState extends State<DailyQuoteWidget> {
  Quote? _quote;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final quote = await QuoteCacheService.getDailyQuote();
      if (mounted) {
        setState(() {
          _quote = quote;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    

    
    return ElevatedCard(
      margin: const EdgeInsets.only(bottom: 20),
      child: _isLoading
          ? _buildLoadingWidget()
          : _quote != null
          ? _buildQuoteContent()
          : _buildErrorWidget(),
    );
  }

  Widget _buildLoadingWidget() {
    final themeProvider = context.watch<ThemeProvider>();
    
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: themeProvider.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  themeProvider.primaryColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Loading daily inspiration...',
            style: TextStyle(
              color: themeProvider.textSecondary,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteContent() {
    final themeProvider = context.watch<ThemeProvider>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: themeProvider.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: themeProvider.isDarkMode 
                        ? Colors.black.withValues(alpha: 0.2) 
                        : Colors.grey.withValues(alpha: 0.1),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                    spreadRadius: 0,
                    blurStyle: BlurStyle.inner,
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.quote,
                color: themeProvider.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Daily Inspiration',
              style: TextStyle(
                color: themeProvider.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '"${_quote!.text}"',
          style: TextStyle(
            color: themeProvider.textPrimary,
            fontSize: 16,
            height: 1.4,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '— ${_quote!.author}',
            style: TextStyle(
              color: themeProvider.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    final themeProvider = context.watch<ThemeProvider>();
    
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.circleAlert,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Daily Inspiration',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Unable to load today\'s inspiration. Please check your internet connection.',
          style: TextStyle(color: themeProvider.textSecondary, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 12),
        Text(
          'Check your internet connection and restart the app.',
          style: TextStyle(
            color: themeProvider.textSecondary,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
