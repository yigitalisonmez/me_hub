part of '../pages/water_page.dart';

class QuickAddSection extends StatelessWidget {
  final WaterProvider provider;
  final double cardWidth;
  final List<QuickAddAmount> quickAddAmounts;

  const QuickAddSection({
    super.key,
    required this.provider,
    required this.cardWidth,
    required this.quickAddAmounts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(
              LucideIcons.droplet,
              color: themeProvider.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'QUICK ADD',
              style: theme.textTheme.titleMedium?.copyWith(
                color: themeProvider.primaryColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Horizontal Scrollable Buttons
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: quickAddAmounts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final quickAddAmount = quickAddAmounts[index];

              return SizedBox(
                width: cardWidth,
                child: WaterAmountButton(
                  amount: quickAddAmount.amountMl,
                  label: quickAddAmount.label,
                  theme: theme,
                  themeProvider: themeProvider,
                  onTap: () async {
                    // Haptic feedback
                    HapticFeedback.mediumImpact();
                    
                    // Add water
                    await context.read<WaterProvider>().addWaterAmount(quickAddAmount.amountMl);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
