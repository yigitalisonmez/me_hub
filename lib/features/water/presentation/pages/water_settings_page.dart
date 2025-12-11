import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../data/services/daily_goal_service.dart';
import '../../data/services/quick_add_amounts_service.dart';
import '../../data/models/quick_add_amount.dart';

class WaterSettingsPage extends StatefulWidget {
  const WaterSettingsPage({super.key});

  @override
  State<WaterSettingsPage> createState() => _WaterSettingsPageState();
}

class _WaterSettingsPageState extends State<WaterSettingsPage> {
  int _dailyGoal = 2000;
  List<QuickAddAmount> _quickAddAmounts = [];
  int? _selectedPreset;
  final List<int> _presets = [2000, 2500, 3000, 3500];

  // Form controllers for adding new amount
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();

  // Slider track measurement for gradient alignment
  final GlobalKey _sliderKey = GlobalKey();
  double? _trackLeft;
  double? _trackWidth;

  // Slider constants
  static const double _thumbRadius = 10.0;
  static const double _trackHeight = 6.0;

  @override
  void initState() {
    super.initState();
    // Load settings after first frame to avoid blocking UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
      _measureSliderTrack();
    });
    // Add listeners to text fields to update button state
    _amountController.addListener(_onTextChanged);
    _labelController.addListener(_onTextChanged);
  }

  /// Measures the slider's track position and width for gradient alignment
  void _measureSliderTrack() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final RenderBox? renderBox =
          _sliderKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final size = renderBox.size;
        // Slider track starts at thumbRadius and ends at width - thumbRadius
        setState(() {
          _trackLeft = _thumbRadius;
          _trackWidth = size.width - (_thumbRadius * 2);
        });
      }
    });
  }

  void _onTextChanged() {
    // Debounce setState to avoid excessive rebuilds
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadSettings() async {
    final goal = await DailyGoalService.getDailyGoal();
    final amounts = await QuickAddAmountsService.getQuickAddAmounts();

    if (mounted) {
      setState(() {
        _dailyGoal = goal;
        _quickAddAmounts = amounts;
        // Check if current goal matches a preset
        _selectedPreset = _presets.contains(goal) ? goal : null;
      });
    }
  }

  Future<void> _saveSettings() async {
    await DailyGoalService.setDailyGoal(_dailyGoal);
    await QuickAddAmountsService.saveQuickAddAmounts(_quickAddAmounts);

    if (mounted) {
      Navigator.of(
        context,
      ).pop(true); // Return true to indicate settings were saved
    }
  }

  void _onSliderChanged(double value) {
    final newGoal = (value / 250).round() * 250; // Round to nearest 250
    setState(() {
      _dailyGoal = newGoal.clamp(500, 5000);
      // Check if matches a preset
      _selectedPreset = _presets.contains(_dailyGoal) ? _dailyGoal : null;
    });
  }

  void _onPresetTapped(int preset) {
    setState(() {
      _dailyGoal = preset;
      _selectedPreset = preset;
    });
  }

  void _addQuickAddAmount() {
    final amountText = _amountController.text.trim();
    final labelText = _labelController.text.trim();

    if (amountText.isEmpty || labelText.isEmpty) return;

    final amount = int.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    setState(() {
      _quickAddAmounts.add(QuickAddAmount(amountMl: amount, label: labelText));
      _quickAddAmounts.sort((a, b) => a.amountMl.compareTo(b.amountMl));
      _amountController.clear();
      _labelController.clear();
    });
  }

  void _removeQuickAddAmount(int amountMl) {
    if (_quickAddAmounts.length <= 1) return; // Must have at least one

    setState(() {
      _quickAddAmounts.removeWhere((a) => a.amountMl == amountMl);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildDailyGoalCard(),
              const SizedBox(height: 20),
              _buildQuickAddButtonsCard(),
              const SizedBox(height: 100), // Space for save button
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildSaveButton(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: theme.textTheme.displaySmall?.copyWith(
                color: themeProvider.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Customize your tracker',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: themeProvider.textSecondary,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: themeProvider.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              LucideIcons.chevronLeft,
              color: themeProvider.primaryColor,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyGoalCard() {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                LucideIcons.target,
                color: themeProvider.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'DAILY GOAL',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: themeProvider.primaryColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Goal Display
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: themeProvider.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$_dailyGoal',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 48,
                        color: themeProvider.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ml',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: themeProvider.textSecondary,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Daily water intake goal',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: themeProvider.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Slider with gradient on active track
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate slider dimensions
              final sliderHeight = _thumbRadius * 2 + _trackHeight + 4;
              final trackTop = (sliderHeight - _trackHeight) / 2;

              // Use measured track position if available, otherwise calculate fallback
              final trackLeft = _trackLeft ?? _thumbRadius;
              final trackWidth =
                  _trackWidth ?? (constraints.maxWidth - (_thumbRadius * 2));

              // Calculate progress and track widths
              final progress = (_dailyGoal - 500) / (5000 - 500);
              final activeWidth = trackWidth * progress;
              final inactiveWidth = trackWidth * (1 - progress);

              return SizedBox(
                height: sliderHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Active track with gradient (left side)
                    Positioned(
                      left: trackLeft,
                      top: trackTop,
                      child: Container(
                        height: _trackHeight,
                        width: activeWidth,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    // Inactive track with solid color (right side)
                    Positioned(
                      left: trackLeft + activeWidth,
                      top: trackTop,
                      child: Container(
                        height: _trackHeight,
                        width: inactiveWidth,
                        decoration: BoxDecoration(
                          color: themeProvider.surfaceColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    // Slider widget on top with transparent tracks
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                        thumbColor: themeProvider.primaryColor,
                        overlayColor: themeProvider.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        trackHeight: _trackHeight,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: _thumbRadius,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: _thumbRadius * 2,
                        ),
                      ),
                      child: Slider(
                        key: _sliderKey,
                        value: _dailyGoal.toDouble(),
                        min: 500,
                        max: 5000,
                        onChanged: _onSliderChanged,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '500ml',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: themeProvider.textSecondary,
                  fontSize: 14,
                ),
              ),
              Text(
                '5000ml',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: themeProvider.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Quick Presets
          Text(
            'Quick Presets',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: themeProvider.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _presets.map((preset) {
              final isSelected = _selectedPreset == preset;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: preset == _presets.last ? 0 : 8,
                  ),
                  child: GestureDetector(
                    onTap: () => _onPresetTapped(preset),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? themeProvider.primaryColor
                            : themeProvider.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: themeProvider.primaryColor.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        '${preset}ml',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? themeProvider.textPrimary
                              : themeProvider.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddButtonsCard() {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                LucideIcons.droplet,
                color: themeProvider.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'QUICK ADD BUTTONS',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: themeProvider.primaryColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Customize your quick add water amounts',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: themeProvider.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          // Current Amounts List
          ..._quickAddAmounts.map((amount) => _buildQuickAddItem(amount)),
          const SizedBox(height: 24),
          // Add New Amount Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: themeProvider.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Amount',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: themeProvider.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: themeProvider.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Amount (ml)',
                    labelStyle: TextStyle(color: themeProvider.textSecondary),
                    hintText: 'e.g. 350',
                    hintStyle: TextStyle(
                      color: themeProvider.textSecondary.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: themeProvider.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: themeProvider.primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _labelController,
                  style: TextStyle(color: themeProvider.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Label',
                    labelStyle: TextStyle(color: themeProvider.textSecondary),
                    hintText: 'e.g. Small Glass',
                    hintStyle: TextStyle(
                      color: themeProvider.textSecondary.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: themeProvider.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: themeProvider.primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _amountController.text.isNotEmpty &&
                            _labelController.text.isNotEmpty &&
                            (int.tryParse(_amountController.text) ?? 0) > 0
                        ? _addQuickAddAmount
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeProvider.primaryColor,
                      foregroundColor: themeProvider.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: themeProvider.primaryColor
                          .withValues(alpha: 0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.plus, size: 20),
                        const SizedBox(width: 8),
                        const Text('Add Amount'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddItem(QuickAddAmount amount) {
    final themeProvider = context.watch<ThemeProvider>();
    final canDelete = _quickAddAmounts.length > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.droplet,
              color: themeProvider.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${amount.amountMl}ml',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: themeProvider.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amount.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: themeProvider.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (canDelete)
            GestureDetector(
              onTap: () => _removeQuickAddAmount(amount.amountMl),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.trash2,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.primaryColor,
              foregroundColor: themeProvider.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.save,
                  size: 20,
                  color: themeProvider.textPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Save Changes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: themeProvider.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
