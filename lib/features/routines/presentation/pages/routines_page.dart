import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/routine.dart';
import '../providers/routines_provider.dart';

class RoutinesPage extends StatefulWidget {
  const RoutinesPage({super.key});

  @override
  State<RoutinesPage> createState() => _RoutinesPageState();
}

class _RoutinesPageState extends State<RoutinesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutinesProvider>().loadRoutines();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: SafeArea(
        child: Consumer<RoutinesProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  ...provider.routines.map((r) => _buildRoutineCard(r, provider)),
                  const SizedBox(height: 16),
                  _buildAddRoutineButton(context),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.repeat, color: AppColors.primaryOrange, size: 24),
        SizedBox(width: 8),
        Text(
          'ROUTINES',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryOrange,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(width: 8),
        Icon(Icons.repeat, color: AppColors.primaryOrange, size: 24),
      ],
    );
  }

  Widget _buildRoutineCard(Routine routine, RoutinesProvider provider) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryOrange, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  routine.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkGrey,
                  ),
                ),
              ),
              _buildStreakBadge(routine.streakCount),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'add_item') {
                    final controller = TextEditingController();
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Add Routine Item'),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(hintText: 'Item title'),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
                        ],
                      ),
                    );
                    if (ok == true && controller.text.trim().isNotEmpty) {
                      final item = RoutineItem(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        title: controller.text.trim(),
                      );
                      await provider.addItem(routine.id, item);
                    }
                  } else if (v == 'delete') {
                    await provider.deleteRoutine(routine.id);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'add_item', child: Text('Add Item')),
                  PopupMenuItem(value: 'delete', child: Text('Delete Routine')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...routine.items.map((i) => _buildRoutineItem(routine, i, provider)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final controller = TextEditingController();
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Add Routine Item'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: 'Item title'),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
                  ],
                ),
              );
              if (ok == true && controller.text.trim().isNotEmpty) {
                final item = RoutineItem(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  title: controller.text.trim(),
                );
                await provider.addItem(routine.id, item);
              }
            },
            icon: const Icon(Icons.add, color: AppColors.primaryOrange),
            label: const Text('Add Item', style: TextStyle(color: AppColors.primaryOrange)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primaryOrange.withValues(alpha: 0.4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: AppColors.primaryOrange, size: 16),
          const SizedBox(width: 6),
          Text('$count', style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildRoutineItem(Routine routine, RoutineItem item, RoutinesProvider provider) {
    final today = DateTime.now();
    final isToday = item.isCheckedToday(DateTime(today.year, today.month, today.day));
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => provider.toggleItemCheckedToday(routine.id, item.id),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isToday ? AppColors.primaryOrange : Colors.transparent,
                border: Border.all(
                  color: isToday
                      ? AppColors.primaryOrange
                      : AppColors.primaryOrange.withValues(alpha: 0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isToday
                  ? const Icon(Icons.check, color: AppColors.white, size: 14)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isToday ? AppColors.darkGrey : AppColors.darkGrey,
                decoration: isToday ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddRoutineButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final controller = TextEditingController();
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('New Routine'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Routine name'),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
              ],
            ),
          );
          if (ok == true && controller.text.trim().isNotEmpty) {
            await context.read<RoutinesProvider>().addNewRoutine(
                  DateTime.now().microsecondsSinceEpoch.toString(),
                  controller.text.trim(),
                );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Routine'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}


