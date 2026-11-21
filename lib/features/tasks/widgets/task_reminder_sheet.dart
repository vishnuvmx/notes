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
          rationale: 'Allow notifications so Tack can alert you when your scheduled tasks are due.',
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
    final hasAnySelection =
        _dueAt != null ||
        _recurrence != null ||
        widget.initialDueAt != null ||
        widget.initialRecurrence != null;
    final isPastSelection =
        _dueAt != null &&
        (_hasExplicitTime
            ? _dueAt!.isBefore(now)
            : DateTime(
                _dueAt!.year,
                _dueAt!.month,
                _dueAt!.day,
                9,
                0,
              ).isBefore(now));

    final schedulePresets =
        <({String label, bool isSelected, VoidCallback onTap})>[
          (
            label: now.hour < 9 ? 'Today · 9 AM' : 'Today · Date only',
            isSelected:
                _isSameDay(_dueAt, now) &&
                (!_hasExplicitTime || _dueAt?.hour == 9),
            onTap: () => _selectPreset(
              now.hour < 9 ? todayNine : DateTime(now.year, now.month, now.day),
              withTime: now.hour < 9,
            ),
          ),
          if (now.hour < 18)
            (
              label: 'Tonight · 6 PM',
              isSelected:
                  _isSameDay(_dueAt, now) &&
                  _hasExplicitTime &&
                  _dueAt?.hour == 18 &&
                  _dueAt?.minute == 0,
              onTap: () => _selectPreset(tonightSix, withTime: true),
            ),
          (
            label: 'Tomorrow · 9 AM',
            isSelected:
                _isSameDay(_dueAt, tomorrowNine) &&
                _hasExplicitTime &&
                _dueAt?.hour == 9,
            onTap: () => _selectPreset(tomorrowNine, withTime: true),
          ),
          (
            label: 'Next Week',
            isSelected: _isSameDay(_dueAt, nextWeekNine),
            onTap: () => _selectPreset(nextWeekNine, withTime: true),
          ),
        ];

    final customTimeLabel = _hasExplicitTime && _dueAt != null
        ? 'Time · ${DerivedTaskItem(noteId: "", noteTitle: "", paletteId: "amber", lineIndex: 0, text: "", isDone: false, noteUpdatedAt: now, dueAt: _dueAt, hasExplicitTime: true).formatDueLabel(now)!.split(" · ").last}'
        : 'Set Time…';

    return SingleChildScrollView(
      padding: AppSpacing.modalSheetPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Clean editorial header (no decorative bell box)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.taskTitle.trim().isEmpty
                            ? 'Task Reminder'
                            : widget.taskTitle.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSm(
                          color: tokens.textPrimary,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _previewLabel(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
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

          const SizedBox(height: AppSpacing.s4),

          // Clean hairline-divided Schedule list (Things / Linear / Apple Reminders style)
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(
              color: tokens.canvasSunken.withValues(alpha: 0.45),
              shape: SmoothRectangleBorder(
                borderRadius: AppSpacing.roundedMd,
                smoothness: AppSpacing.defaultSmoothing,
                side: BorderSide(color: tokens.borderSubtle, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < schedulePresets.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: AppSpacing.s4,
                      endIndent: AppSpacing.s4,
                      color: tokens.borderSubtle,
                    ),
                  _ScheduleListRow(
                    label: schedulePresets[i].label,
                    isSelected: schedulePresets[i].isSelected,
                    onTap: schedulePresets[i].onTap,
                  ),
                ],
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: AppSpacing.s4,
                  endIndent: AppSpacing.s4,
                  color: tokens.borderSubtle,
                ),
                _ScheduleListRow(
                  label: 'Pick Date…',
                  icon: TackIcons.calendar,
                  isSelected: false,
                  showChevron: true,
                  onTap: _pickCustomDate,
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: AppSpacing.s4,
                  endIndent: AppSpacing.s4,
                  color: tokens.borderSubtle,
                ),
                _ScheduleListRow(
                  label: customTimeLabel,
                  icon: TackIcons.clock,
                  isSelected: _hasExplicitTime,
                  showChevron: !_hasExplicitTime,
                  onTap: _pickCustomTime,
                ),
              ],
            ),
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
                      weight: FontWeight.w500,
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

          const SizedBox(height: AppSpacing.s4),
          Text(
            'Repeat',
            style: AppTypography.caption(
              color: tokens.textTertiary,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),

          // Clean single-line horizontal Repeat strip
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Row(
              children: [
                for (int i = 0; i < _repeatChoices.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  TactileFilterPill(
                    label: _repeatChoices[i].label,
                    isSelected: _recurrence == _repeatChoices[i].value,
                    unselectedColor: tokens.canvasSunken,
                    unselectedFg: tokens.textPrimary,
                    selectedBorderColor: tokens.actionPrimary,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _recurrence = _repeatChoices[i].value;
                        if (_recurrence != null && _dueAt == null) {
                          final todayNineStart = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            9,
                            0,
                          );
                          _dueAt = now.isBefore(todayNineStart)
                              ? todayNineStart
                              : tomorrowNine;
                          _hasExplicitTime = true;
                        }
                      });
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.s5),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(
                      AppSpacing.minTouchTarget,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s3,
                    ),
                    side: BorderSide(color: tokens.borderSubtle),
                    shape: AppSpacing.smoothMd(
                      side: BorderSide(color: tokens.borderSubtle, width: 1),
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
                    shape: AppSpacing.smoothMd(),
                  ),
                  onPressed: _isSaving ? null : _handleSave,
                  child: Text(
                    'Save Reminder',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label(
                      color: tokens.actionPrimaryFg,
                      weight: FontWeight.w600,
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

class _ScheduleListRow extends StatelessWidget {
  final String label;
  final dynamic icon;
  final bool isSelected;
  final bool showChevron;
  final VoidCallback onTap;

  const _ScheduleListRow({
    required this.label,
    this.icon,
    required this.isSelected,
    this.showChevron = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Material(
      color: isSelected
          ? tokens.actionPrimary.withValues(alpha: tokens.isDark ? 0.14 : 0.06)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: 12,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                TackIcon(
                  icon,
                  size: 16,
                  color: isSelected ? tokens.textPrimary : tokens.textSecondary,
                ),
                const SizedBox(width: AppSpacing.s3),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm(
                    color: tokens.textPrimary,
                    weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected)
                TackIcon(TackIcons.check, size: 16, color: tokens.textPrimary)
              else if (showChevron)
                TackIcon(
                  TackIcons.chevronRight,
                  size: 15,
                  color: tokens.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
