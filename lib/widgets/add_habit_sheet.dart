import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/habit.dart';
import '../providers/habits_provider.dart';
import '../theme/app_theme.dart';

class AddHabitSheet extends ConsumerStatefulWidget {
  const AddHabitSheet({super.key});

  @override
  ConsumerState<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends ConsumerState<AddHabitSheet> {
  final _titleCtrl = TextEditingController();
  HabitFrequency _frequency = HabitFrequency.daily;
  bool _saving = false;

  final _weekdayLabels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  // 1=Mon .. 7=Sun
  final List<int> _selectedWeekdays = [1, 2, 3, 4, 5, 6, 7];

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    await ref.read(habitsProvider.notifier).addHabit(
          title: title,
          frequency: _frequency,
          activeWeekdays: _frequency == HabitFrequency.custom
              ? List.from(_selectedWeekdays)
              : [1, 2, 3, 4, 5, 6, 7],
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('New Habit', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'e.g. Drink water, Read 10 pages ✦',
              hintStyle:
                  const TextStyle(color: AppColors.textMuted, fontSize: 15),
              filled: true,
              fillColor: AppColors.bgDeep,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.surfaceBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.surfaceBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.mint, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Repeat',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Row(
            children: HabitFrequency.values.map((f) {
              final labels = {
                HabitFrequency.daily: 'Daily',
                HabitFrequency.weekly: 'Weekly',
                HabitFrequency.custom: 'Custom',
              };
              return GestureDetector(
                onTap: () => setState(() => _frequency = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _frequency == f
                        ? AppColors.mint.withOpacity(0.2)
                        : AppColors.bgDeep,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _frequency == f
                          ? AppColors.mint
                          : AppColors.surfaceBorder,
                      width: _frequency == f ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    labels[f]!,
                    style: TextStyle(
                      color: _frequency == f
                          ? AppColors.mint
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_frequency == HabitFrequency.custom) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final day = i + 1;
                final selected = _selectedWeekdays.contains(day);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      if (_selectedWeekdays.length > 1) {
                        _selectedWeekdays.remove(day);
                      }
                    } else {
                      _selectedWeekdays.add(day);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? AppColors.mint.withOpacity(0.25)
                          : AppColors.bgDeep,
                      border: Border.all(
                        color: selected
                            ? AppColors.mint
                            : AppColors.surfaceBorder,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _weekdayLabels[i],
                        style: TextStyle(
                          color: selected
                              ? AppColors.mint
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mint,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Add Habit  ✦',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
