import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/routine_icons.dart';
import '../../../../core/providers/theme_provider.dart';

class RoutineIconPicker extends StatelessWidget {
  final int? selectedIconCodePoint;
  final Function(int iconCodePoint) onIconSelected;

  const RoutineIconPicker({
    super.key,
    this.selectedIconCodePoint,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const crossAxisCount = 4;
          const crossAxisSpacing = 12.0;

          final totalSpacing = (crossAxisCount - 1) * crossAxisSpacing;
          final cardWidth =
              (constraints.maxWidth - totalSpacing) / crossAxisCount;

          return GridView.builder(
            padding: const EdgeInsets.only(top: 20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: 12,
              childAspectRatio: cardWidth / (cardWidth * 1.2),
            ),
            itemCount: RoutineIcons.allIcons.length,
            itemBuilder: (context, index) {
              final iconData = RoutineIcons.allIcons[index];
              final icon = iconData['icon'] as IconData;
              final iconName = iconData['name'] as String;
              final isSelected = selectedIconCodePoint == icon.codePoint;

              return GestureDetector(
                onTap: () => onIconSelected(icon.codePoint),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: cardWidth,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? themeProvider.primaryColor
                            : themeProvider.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: themeProvider.isDarkMode
                              ? themeProvider.textSecondary.withValues(
                                  alpha: 0.3,
                                )
                              : themeProvider.primaryColor,
                          width: isSelected ? 2 : 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              icon,
                              color: isSelected
                                  ? Colors.white
                                  : themeProvider.primaryColor,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              iconName.isNotEmpty
                                  ? '${iconName[0].toUpperCase()}${iconName.substring(1)}'
                                  : iconName,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : themeProvider.textSecondary,
                                    fontSize: 11,
                                  ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: -cardWidth * 0.03,
                        right: -cardWidth * 0.03,
                        child: Container(
                          width: cardWidth * 0.25,
                          height: cardWidth * 0.25,
                          decoration: BoxDecoration(
                            color: themeProvider.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              LucideIcons.check,
                              color: Colors.white,
                              size: cardWidth * 0.15,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
