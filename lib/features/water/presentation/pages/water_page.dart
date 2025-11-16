import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/wave_progress_bar.dart';
import '../../core/constants/water_constants.dart';
import '../providers/water_provider.dart';
import '../../domain/entities/water_intake.dart';
import '../../data/services/custom_amount_service.dart';

class WaterPage extends StatefulWidget {
  const WaterPage({super.key});

  @override
  State<WaterPage> createState() => _WaterPageState();
}

class _WaterPageState extends State<WaterPage> with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  List<int> _customAmounts = [];
  final GlobalKey _statCardKey = GlobalKey();
  double? _statCardWidth;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WaterProvider>().loadTodayWaterIntake();
      _loadCustomAmounts();
    });
  }

  Future<void> _loadCustomAmounts() async {
    final amounts = await CustomAmountService.getCustomAmounts();
    if (mounted) {
      setState(() {
        _customAmounts = amounts;
      });
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.secondaryCream),
      child: SafeArea(
        child: Consumer<WaterProvider>(
          builder: (context, provider, child) {
            // Check if goal was just reached and trigger celebration
            if (provider.justReachedGoal) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _celebrationController.forward().then((_) {
                  _celebrationController.reverse();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(
                          LucideIcons.partyPopper,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '🎉 Daily goal reached!',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              });
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Header
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  // Today's Progress Section
                  _buildTodaysProgressCard(context, provider),
                  const SizedBox(height: 24),
                  // Today's Log Section
                  _buildTodaysLogSection(context, provider),
                  const SizedBox(height: 24),
                  // Add Custom Amount Button
                  _buildAddCustomAmountButton(context),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Water Tracker',
              style: theme.textTheme.displaySmall?.copyWith(
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Stay hydrated & healthy',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.darkGrey.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primaryOrange, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            LucideIcons.droplet,
            color: AppColors.primaryOrange,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildTodaysProgressCard(
    BuildContext context,
    WaterProvider provider,
  ) {
    final theme = Theme.of(context);
    final percentage = (provider.todayProgress * 100).toInt();
    final glassCount = provider.todayIntake?.logs.length ?? 0;
    final remaining = WaterConstants.dailyGoalMl - provider.todayAmount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryOrange, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              const Icon(
                LucideIcons.trendingUp,
                color: AppColors.primaryOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'TODAY\'S PROGRESS',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryOrange,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Current Amount
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${provider.todayAmount}',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 36,
                    color: AppColors.primaryOrange,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'ml',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 24,
                    color: AppColors.darkGrey.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Goal
          Text(
            'of ${WaterConstants.dailyGoalMl}ml daily goal',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.darkGrey.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          // Horizontal Progress Bar with Wave Effect
          WaveProgressBar(
            progress: provider.todayProgress,
            centerText: '$percentage%',
            bottomText:
                '${provider.todayAmount} / ${WaterConstants.dailyGoalMl} ml',
          ),
          const SizedBox(height: 20),
          // Three Stat Cards
          Builder(
            builder: (context) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        key: _statCardKey,
                        child: _buildStatCard(context, '$glassCount', 'Cups'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          '${remaining > 0 ? remaining : 0}',
                          'Remaining',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCardWithIcon(context, 'Status'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Quick Add Section with same card width
                  Builder(
                    builder: (context) {
                      // Measure stat card width after first frame
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final RenderBox? renderBox =
                            _statCardKey.currentContext?.findRenderObject()
                                as RenderBox?;
                        if (renderBox != null && _statCardWidth == null) {
                          setState(() {
                            _statCardWidth = renderBox.size.width;
                          });
                        }
                      });

                      if (_statCardWidth != null) {
                        return _buildQuickAddSection(
                          context,
                          provider,
                          _statCardWidth!,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundCream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.darkGrey.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardWithIcon(BuildContext context, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundCream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.flame,
            color: AppColors.primaryOrange,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.darkGrey.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddSection(
    BuildContext context,
    WaterProvider provider,
    double cardWidth,
  ) {
    final theme = Theme.of(context);

    // Default amounts
    final defaultAmounts = [
      {'amount': 250, 'label': '1 Glass'},
      {'amount': 500, 'label': '1 Bottle'},
      {'amount': 1000, 'label': '1 Liter'},
    ];

    // Combine all amounts (default + custom)
    final allAmounts = <Map<String, dynamic>>[];
    allAmounts.addAll(defaultAmounts);
    for (var amount in _customAmounts) {
      allAmounts.add({'amount': amount, 'label': 'Custom'});
    }

    // Sort all amounts from smallest to largest
    allAmounts.sort(
      (a, b) => (a['amount'] as int).compareTo(b['amount'] as int),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            const Icon(
              LucideIcons.droplet,
              color: AppColors.primaryOrange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'QUICK ADD',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.primaryOrange,
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
            itemCount: allAmounts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = allAmounts[index];
              final amount = item['amount'] as int;
              final label = item['label'] as String;

              return SizedBox(
                width: cardWidth,
                child: _buildAmountButton(context, amount, label, provider),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAmountButton(
    BuildContext context,
    int amount,
    String label,
    WaterProvider provider,
  ) {
    final theme = Theme.of(context);
    final isCustom = label == 'Custom';

    return GestureDetector(
      onTap: () => context.read<WaterProvider>().addWaterAmount(amount),
      onLongPress: isCustom
          ? () => _showDeleteCustomAmountDialog(context, amount)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryOrange,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.droplet, color: Colors.white, size: 28),
            const SizedBox(height: 12),
            Text(
              '${amount}ml',
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysLogSection(BuildContext context, WaterProvider provider) {
    final theme = Theme.of(context);
    final logs = provider.todayIntake?.logs ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryOrange, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.clock,
                    color: AppColors.primaryOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TODAY\'S LOG',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryOrange,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (logs.isNotEmpty)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${logs.length}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Log Items
          if (logs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No entries yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkGrey.withValues(alpha: 0.5),
                  ),
                ),
              ),
            )
          else
            ...logs
                .map((log) => _buildLogItem(context, log, provider))
                .toList()
                .reversed, // Show newest first
        ],
      ),
    );
  }

  Widget _buildLogItem(
    BuildContext context,
    WaterLog log,
    WaterProvider provider,
  ) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm');
    final timeString = timeFormat.format(log.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.secondaryCream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.droplet,
              color: AppColors.primaryOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Amount and time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.amountMl}ml',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.darkGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeString,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.darkGrey.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          // Delete button
          GestureDetector(
            onTap: () => provider.deleteLog(log.id),
            child: SizedBox(
              width: 32,
              height: 32,
              child: const Icon(
                LucideIcons.trash2,
                color: Colors.red,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCustomAmountButton(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showAddCustomAmountDialog(context),
            icon: const Icon(LucideIcons.plus, color: AppColors.primaryOrange),
            label: Text(
              'Add Custom Amount',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppColors.primaryOrange),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.primaryOrange, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddCustomAmountDialog(BuildContext context) async {
    final amountController = TextEditingController();
    final theme = Theme.of(context);

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Add Custom Amount',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.primaryOrange,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Amount (ml)',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.darkGrey,
              ),
            ),
            const SizedBox(height: 8),

            /// AMOUNT TEXTFIELD
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter amount in ml',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkGrey.withValues(alpha: 0.4),
                ),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primaryOrange.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primaryOrange.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryOrange,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          /// Cancel Button
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.darkGrey.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.darkGrey.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: ElevatedButton(
              onPressed: () {
                final amountText = amountController.text.trim();
                if (amountText.isNotEmpty) {
                  final amount = int.tryParse(amountText);
                  if (amount != null && amount > 0) {
                    Navigator.pop(context, amount);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid amount'),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,

                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Add',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      await CustomAmountService.addCustomAmount(result);
      await _loadCustomAmounts();
    }

    amountController.dispose();
  }

  Future<void> _showDeleteCustomAmountDialog(
    BuildContext context,
    int amount,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Custom Amount',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        content: Text(
          'Are you sure you want to remove ${amount}ml from quick add?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await CustomAmountService.removeCustomAmount(amount);
      await _loadCustomAmounts();
    }
  }
}
