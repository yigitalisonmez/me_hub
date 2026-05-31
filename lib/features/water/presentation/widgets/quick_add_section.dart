part of '../pages/water_page.dart';

class QuickAddSection extends StatelessWidget {
  final WaterProvider provider;
  final List<QuickAddAmount> quickAddAmounts;

  const QuickAddSection({
    super.key,
    required this.provider,
    required this.quickAddAmounts,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final visibleAmounts = quickAddAmounts.take(4).toList();

    if (visibleAmounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      itemCount: visibleAmounts.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: visibleAmounts.length < 4 ? visibleAmounts.length : 4,
        crossAxisSpacing: 9,
        mainAxisSpacing: 9,
        mainAxisExtent: 82,
      ),
      itemBuilder: (context, index) {
        final quickAddAmount = visibleAmounts[index];
        final selected = index == 0;

        return WaterAmountButton(
          amount: quickAddAmount.amountMl,
          label: quickAddAmount.label,
          theme: Theme.of(context),
          themeProvider: themeProvider,
          isSelected: selected,
          onTap: () async {
            HapticFeedback.mediumImpact();
            await provider.addWaterAmount(quickAddAmount.amountMl);
          },
        );
      },
    );
  }
}
