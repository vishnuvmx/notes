import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/permission_rationale_dialog.dart';
import '../../../shared/widgets/tactile_ink_target.dart';
import '../services/open_tasks_service.dart';

/// Result returned from [TaskReminderSheet].
class TaskReminderSelection {
  final DateTime? dueAt;
  final bool hasExplicitTime;
  final TaskRecurrence? recurrence;

  const TaskReminderSelection({
    this.dueAt,
    this.hasExplicitTime = false,
    this.recurrence,
  });
}

/// Floating modal bottom sheet for configuring a task's `@due(...)` date/time
/// and `@repeat(...)` recurrence rule cleanly.
class TaskReminderSheet extends StatefulWidget {
  final String taskTitle;
  final DateTime? initialDueAt;
  final bool initialHasExplicitTime;
  final TaskRecurrence? initialRecurrence;

  const TaskReminderSheet({
    super.key,
    required this.taskTitle,
    this.initialDueAt,
    this.initialHasExplicitTime = false,
    this.initialRecurrence,
  });

  static Future<TaskReminderSelection?> show({
    required BuildContext context,
    required String taskTitle,
    DateTime? initialDueAt,
    bool initialHasExplicitTime = false,
    TaskRecurrence? initialRecurrence,
  }) {
    HapticFeedback.selectionClick();
    return AppBottomSheet.show<TaskReminderSelection>(
      context: context,
      builder: (_) => TaskReminderSheet(
        taskTitle: taskTitle,
        initialDueAt: initialDueAt,
        initialHasExplicitTime: initialHasExplicitTime,
        initialRecurrence: initialRecurrence,
      ),
    );
  }

  @override
  State<TaskReminderSheet> createState() => _TaskReminderSheetState();
}

class _TaskReminderSheetState extends State<TaskReminderSheet> {
  DateTime? _dueAt;
  bool _hasExplicitTime = false;
  TaskRecurrence? _recurrence;
  bool _isSaving = false;

  static final List<({String label, TaskRecurrence? value})> _repeatChoices = [
    (label: 'None', value: null),
    (label: 'Daily', value: TaskRecurrence.daily),
    (label: 'Weekdays', value: TaskRecurrence.weekdays),
    (label: 'Weekly', value: TaskRecurrence.weekly),
    (label: 'Monthly', value: TaskRecurrence.monthly),
    (label: 'Yearly', value: TaskRecurrence.yearly),
  ];

  @override
  void initState() {
    super.initState();
    _dueAt = widget.initialDueAt;
    _hasExplicitTime = widget.initialHasExplicitTime;
    _recurrence = widget.initialRecurrence;
  }

  void _selectPreset(DateTime target, {required bool withTime}) {
    HapticFeedback.selectionClick();
    setState(() {
      _dueAt = target;
      _hasExplicitTime = withTime;
    });
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1);
    final lastDate = DateTime(now.year + 10);
    final rawInitial = _dueAt ?? now;
    final initial = rawInitial.isBefore(firstDate)
        ? firstDate
        : (rawInitial.isAfter(lastDate) ? lastDate : rawInitial);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (_hasExplicitTime && _dueAt != null) {
        _dueAt = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _dueAt!.hour,
          _dueAt!.minute,
        );
      } else {
        _dueAt = DateTime(picked.year, picked.month, picked.day);
      }
    });
  }

  Future<void> _pickCustomTime() async {
    final now = DateTime.now();
    final baseDate = _dueAt ?? DateTime(now.year, now.month, now.day);
    final initialTime = _hasExplicitTime && _dueAt != null
        ? TimeOfDay(hour: _dueAt!.hour, minute: _dueAt!.minute)
        : const TimeOfDay(hour: 9, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dueAt = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        picked.hour,
        picked.minute,
      );
      _hasExplicitTime = true;
    });
  }

  String _previewLabel() {
    if (_dueAt == null && _recurrence == null) {
      return 'No reminder scheduled';
    }
    final probe = DerivedTaskItem(
      noteId: '',
      noteTitle: '',
      paletteId: 'amber',
      lineIndex: 0,
      text: widget.taskTitle,
      isDone: false,
      noteUpdatedAt: DateTime.now(),
      dueAt: _dueAt,
      hasExplicitTime: _hasExplicitTime,
      recurrence: _recurrence,
    );
    final dueText = probe.formatDueLabel() ?? 'On each check-off';
    if (_recurrence == null) return dueText;
    return '$dueText · Repeats ${_recurrence!.label.toLowerCase()}';
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    HapticFeedback.mediumImpact();
    if (!kIsWeb &&
        Platform.isAndroid &&
        (_dueAt != null || _recurrence != null)) {
      setState(() => _isSaving = true);
      try {
        await ensureNotificationPermissionWithRationale(
          context,
          title: 'Enable Task Reminders',
          rationale:
              'Allow notifications so Tack can alert you when your scheduled tasks are due.',
        );
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
    if (!mounted) return;
    Navigator.of(context).pop(
      TaskReminderSelection(
        dueAt: _dueAt,
        hasExplicitTime: _hasExplicitTime,
        recurrence: _recurrence,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final now = DateTime.now();
    final todayNine = DateTime(now.year, now.month, now.day, 9, 0);
    final tonightSix = DateTime(now.year, now.month, now.day, 18, 0);
    final tomorrowNine = DateTime(now.year, now.month, now.day + 1, 9, 0);
    final nextWeekNine = DateTime(now.year, now.month, now.day + 7, 9, 0);
    final hasAnySelection = _dueAt != null ||
        _recurrence != null ||
        widget.initialDueAt != null ||
        widget.initialRecurrence != null;
    final isPastSelection = _dueAt != null &&
        (_hasExplicitTime
            ? _dueAt!.isBefore(now)
            : DateTime(_dueAt!.year, _dueAt!.month, _dueAt!.day, 9, 0)
                .isBefore(now));

    return SingleChildScrollView(
      padding: AppSpacing.modalSheetPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tokens.canvasSunken,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Center(
                  child: TackIcon(
                    TackIcons.notification,
                    size: 18,
                    color: tokens.accentPin,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.taskTitle.trim().isEmpty
                          ? 'Task Reminder'
                          : widget.taskTitle.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSm(color: tokens.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _previewLabel(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption(color: tokens.textSecondary),
                    ),
                  ],
                ),
              ),
              if (hasAnySelection)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: tokens.danger,
                    minimumSize: const Size(
                      AppSpacing.minTouchTarget,
                      AppSpacing.minTouchTarget,
                    ),
                  ),
                  onPressed: _isSaving
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop(
                            const TaskReminderSelection(
                              dueAt: null,
                              hasExplicitTime: false,
                              recurrence: null,
                            ),
                          );
                        },
                  child: const Text('Clear'),
                ),
              IconButton(
                tooltip: 'Close',
                constraints: const BoxConstraints(
                  minWidth: AppSpacing.minTouchTarget,
                  minHeight: AppSpacing.minTouchTarget,
                ),
                onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                icon: TackIcon(
                  TackIcons.close,
                  size: 18,
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.s5),
          Text(
            'Schedule',
            style: AppTypography.label(
              color: tokens.textSecondary,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Wrap(
            spacing: AppSpacing.s2,
            runSpacing: AppSpacing.s2,
            children: [
              _ReminderChoiceChip(
                label: now.hour < 9 ? 'Today · 9 AM' : 'Today · Date only',
                isSelected: _isSameDay(_dueAt, now) &&
                    (!_hasExplicitTime || _dueAt?.hour == 9),
                onTap: () => _selectPreset(
                  now.hour < 9
                      ? todayNine
                      : DateTime(now.year, now.month, now.day),
                  withTime: now.hour < 9,
                ),
              ),
              if (now.hour < 18)
                _ReminderChoiceChip(
                  label: 'Tonight · 6 PM',
                  isSelected: _isSameDay(_dueAt, now) &&
                      _hasExplicitTime &&
                      _dueAt?.hour == 18 &&
                      _dueAt?.minute == 0,
                  onTap: () => _selectPreset(tonightSix, withTime: true),
                ),
              _ReminderChoiceChip(
                label: 'Tomorrow · 9 AM',
                isSelected: _isSameDay(_dueAt, tomorrowNine) &&
                    _hasExplicitTime &&
                    _dueAt?.hour == 9,
                onTap: () => _selectPreset(tomorrowNine, withTime: true),
              ),
              _ReminderChoiceChip(
                label: 'Next Week',
                isSelected: _isSameDay(_dueAt, nextWeekNine),
                onTap: () => _selectPreset(nextWeekNine, withTime: true),
              ),
              _ReminderChoiceChip(
                label: 'Pick Date…',
                isSelected: false,
                onTap: _pickCustomDate,
              ),
              _ReminderChoiceChip(
                label: _hasExplicitTime && _dueAt != null
                    ? 'Time · ${DerivedTaskItem(noteId: "", noteTitle: "", paletteId: "amber", lineIndex: 0, text: "", isDone: false, noteUpdatedAt: now, dueAt: _dueAt, hasExplicitTime: true).formatDueLabel(now)!.split(" · ").last}'
                    : 'Set Time…',
                isSelected: _hasExplicitTime,
                onTap: _pickCustomTime,
              ),
            ],
          ),
          if (isPastSelection) ...[
            const SizedBox(height: AppSpacing.s2),
            Row(
              children: [
                TackIcon(TackIcons.warning, size: 14, color: tokens.warning),
                const SizedBox(width: AppSpacing.s1),
                Expanded(
                  child: Text(
                    'Selected time is in the past — set a time later today or pick tomorrow.',
                    style: AppTypography.caption(
                      color: tokens.warning,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (_dueAt != null && !_hasExplicitTime) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Date-only tasks notify at 9:00 AM on the due date.',
              style: AppTypography.caption(color: tokens.textTertiary),
            ),
          ],

          const SizedBox(height: AppSpacing.s5),
          Text(
            'Repeat',
            style: AppTypography.label(
              color: tokens.textSecondary,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Wrap(
            spacing: AppSpacing.s2,
            runSpacing: AppSpacing.s2,
            children: [
              for (final choice in _repeatChoices)
                _ReminderChoiceChip(
                  label: choice.label,
                  isSelected: _recurrence == choice.value,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _recurrence = choice.value;
                      // Seed recurring tasks with the next upcoming 9 AM slot.
                      if (_recurrence != null && _dueAt == null) {
                        final todayNineStart =
                            DateTime(now.year, now.month, now.day, 9, 0);
                        _dueAt = now.isBefore(todayNineStart)
                            ? todayNineStart
                            : tomorrowNine;
                        _hasExplicitTime = true;
                      }
                    });
                  },
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.s6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(
                      AppSpacing.minTouchTarget,
                    ),
                    side: BorderSide(color: tokens.borderSubtle),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppSpacing.roundedPill,
                    ),
                  ),
                  onPressed: _isSaving
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop(null);
                        },
                  child: Text(
                    'Cancel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label(
                      color: tokens.textPrimary,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(
                      AppSpacing.minTouchTarget,
                    ),
                    backgroundColor: tokens.actionPrimary,
                    foregroundColor: tokens.actionPrimaryFg,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppSpacing.roundedPill,
                    ),
                  ),
                  onPressed: _isSaving ? null : _handleSave,
                  child: Text(
                    'Save Reminder',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label(
                      color: tokens.actionPrimaryFg,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _ReminderChoiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReminderChoiceChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final fg = isSelected ? tokens.actionPrimaryFg : tokens.textPrimary;
    return TactileFilterPill(
      label: label,
      isSelected: isSelected,
      onTap: onTap,
      triggerHaptics: false,
      unselectedColor: tokens.canvasSunken,
      unselectedFg: tokens.textPrimary,
      selectedBorderColor: tokens.actionPrimary,
      borderWidth: 0.9,
      textStyle: AppTypography.caption(
        color: fg,
        weight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}
