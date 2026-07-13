part of '../pages/water_page.dart';

class QuickAddSection extends StatelessWidget {
  final List<QuickAddAmount> quickAddAmounts;
  final Future<void> Function(int amountMl) onAddWater;

  const QuickAddSection({
    super.key,
    required this.quickAddAmounts,
    required this.onAddWater,
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

        // Design spec: all quick-add tiles share the same light style; no
        // tile is pre-highlighted.
        return WaterAmountButton(
          amount: quickAddAmount.amountMl,
          label: quickAddAmount.label,
          theme: Theme.of(context),
          themeProvider: themeProvider,
          onTap: () async {
            await onAddWater(quickAddAmount.amountMl);
          },
        );
      },
    );
  }
}
