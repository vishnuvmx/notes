import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notes/core/services/task_reminder_service.dart';
import 'package:notes/core/theme/app_theme.dart';
import 'package:notes/core/theme/theme_provider.dart';
import 'package:notes/features/notes/models/text_note.dart';
import 'package:notes/features/notes/widgets/rich_note_content_view.dart';
import 'package:notes/features/tasks/screens/today_screen.dart';
import 'package:notes/features/tasks/services/open_tasks_service.dart';
import 'package:notes/features/tasks/widgets/task_reminder_sheet.dart';
import 'package:notes/shared/data/i_workspace_repo.dart';
import 'package:notes/shared/models/base_item.dart';
import 'package:notes/shared/providers/workspace_provider.dart';

class _InMemoryWorkspaceRepo extends IWorkspaceRepository {
  final List<BaseWorkspaceItem> store;

  _InMemoryWorkspaceRepo([List<BaseWorkspaceItem>? initial])
      : store = List<BaseWorkspaceItem>.from(initial ?? const []);

  @override
  List<BaseWorkspaceItem> get cachedActiveItems =>
      store.where((i) => !i.isTrash && !i.isArchived).toList();

  @override
  Future<List<BaseWorkspaceItem>> getAllActiveItems() async => cachedActiveItems;

  @override
  Future<List<BaseWorkspaceItem>> getItemsByType(ItemType? type) async {
    if (type == null) return cachedActiveItems;
    return cachedActiveItems.where((i) => i.type == type).toList();
  }

  @override
  Future<List<BaseWorkspaceItem>> getFavoriteItems() async =>
      cachedActiveItems.where((i) => i.isFavorite).toList();

  @override
  Future<List<BaseWorkspaceItem>> getArchivedItems() async =>
      store.where((i) => i.isArchived && !i.isTrash).toList();

  @override
  Future<List<BaseWorkspaceItem>> getTrashItems() async =>
      store.where((i) => i.isTrash).toList();

  @override
  Future<List<BaseWorkspaceItem>> searchItems(String query, {ItemType? type}) async =>
      cachedActiveItems
          .where((i) => (type == null || i.type == type) && i.matchesQuery(query))
          .toList();

  @override
  Future<BaseWorkspaceItem?> getItemById(String id) async =>
      store.where((i) => i.id == id).firstOrNull;

  @override
  Future<void> saveItem(BaseWorkspaceItem item) async {
    final idx = store.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      store[idx] = item;
    } else {
      store.add(item);
    }
  }

  @override
  Future<void> moveToTrash(String id) async {}

  @override
  Future<void> restoreItem(String id) async {}

  @override
  Future<void> toggleArchive(String id) async {}

  @override
  Future<void> toggleFavorite(String id) async {}

  @override
  Future<void> deletePermanently(String id) async {
    store.removeWhere((i) => i.id == id);
  }

  @override
  Future<void> emptyTrash() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OpenTasksService metadata & recurrence', () {
    final refNow = DateTime(2026, 11, 14, 10, 30);

    test('parses @due date, @due date+time, relative keywords, and @repeat/@every tokens', () {
      final timed = OpenTasksService.parseTaskMetadata(
        'Submit sprint demo @due(2026-11-16 14:30) @repeat(weekly)',
        referenceNow: refNow,
      );
      expect(timed.cleanText, 'Submit sprint demo');
      expect(timed.dueAt, DateTime(2026, 11, 16, 14, 30));
      expect(timed.hasExplicitTime, isTrue);
      expect(timed.recurrence, TaskRecurrence.weekly);

      final dateOnly = OpenTasksService.parseTaskMetadata(
        'Renew passport @due(today) @every(every 3 days)',
        referenceNow: refNow,
      );
      expect(dateOnly.cleanText, 'Renew passport');
      expect(dateOnly.dueAt, DateTime(2026, 11, 14));
      expect(dateOnly.hasExplicitTime, isFalse);
      expect(dateOnly.recurrence, const TaskRecurrence(unit: RecurrenceUnit.day, interval: 3));

      final custom = OpenTasksService.parseTaskMetadata(
        'Clean filter @due(tomorrow 08:15) @repeat(2w)',
        referenceNow: refNow,
      );
      expect(custom.cleanText, 'Clean filter');
      expect(custom.dueAt, DateTime(2026, 11, 15, 8, 15));
      expect(custom.hasExplicitTime, isTrue);
      expect(custom.recurrence, const TaskRecurrence(unit: RecurrenceUnit.week, interval: 2));
    });

    test('extractTasks strips metadata cleanly and sorts by urgency', () {
      final note = TextNote(
        id: 'n1',
        title: 'Sprint Plan',
        paletteId: 'slate',
        content: [
          '- [ ] Undated task',
          '- [ ] Next month milestone @due(2026-12-01)',
          '- [ ] Today afternoon call @due(2026-11-14 16:00)',
          '- [ ] Yesterday overdue item @due(2026-11-13)',
        ].join('\n'),
        createdAt: refNow,
        updatedAt: refNow,
      );

      final extracted = OpenTasksService.extractTasks([note], now: refNow);
      expect(extracted.length, 4);
      expect(extracted.map((t) => t.text).toList(), [
        'Yesterday overdue item',
        'Today afternoon call',
        'Next month milestone',
        'Undated task',
      ]);
      expect(extracted[0].isOverdue(refNow), isTrue);
      expect(extracted[1].isDueToday(refNow), isTrue);
      expect(extracted[3].hasReminder, isFalse);
    });

    test('completeOrToggleTaskAtLine advances recurring tasks strictly past now', () {
      // Friday 2026-11-13 09:00 checked on Saturday 2026-11-14 10:30 with weekdays rule -> Monday 2026-11-16 09:00
      const weekdayContent = '- [ ] Standup @due(2026-11-13 09:00) @repeat(weekdays)';
      final weekdayResult = OpenTasksService.completeOrToggleTaskAtLine(
        weekdayContent,
        0,
        now: DateTime(2026, 11, 14, 10, 30),
      );
      expect(weekdayResult, isNotNull);
      expect(weekdayResult!.advancedRecurrence, isTrue);
      expect(weekdayResult.isNowDone, isFalse);
      expect(weekdayResult.nextDueAt, DateTime(2026, 11, 16, 9, 0));
      expect(
        weekdayResult.updatedContent,
        '- [ ] Standup @due(2026-11-16 09:00) @repeat(weekdays)',
      );

      // Monthly anchor clamping: Jan 31 -> Feb 28 (2026 non-leap year)
      const monthlyContent = '- [ ] Pay invoice @due(2026-01-31) @repeat(monthly)';
      final monthlyResult = OpenTasksService.completeOrToggleTaskAtLine(
        monthlyContent,
        0,
        now: DateTime(2026, 1, 31, 12, 0),
      );
      expect(monthlyResult, isNotNull);
      expect(monthlyResult!.advancedRecurrence, isTrue);
      expect(monthlyResult.nextDueAt, DateTime(2026, 2, 28));
      expect(
        monthlyResult.updatedContent,
        '- [ ] Pay invoice @due(2026-02-28) @repeat(monthly)',
      );

      // Skipping multiple missed daily occurrences without drift
      const missedDaily = '- [ ] Vitamins @due(2026-11-10 08:00) @repeat(daily)';
      final dailyResult = OpenTasksService.completeOrToggleTaskAtLine(
        missedDaily,
        0,
        now: DateTime(2026, 11, 14, 10, 0),
      );
      expect(dailyResult!.nextDueAt, DateTime(2026, 11, 15, 8, 0));

      // Non-recurring task toggles [ ] -> [x] -> [ ] and preserves tokens
      const oneOff = '- [ ] Buy milk @due(2026-11-15)';
      final checked = OpenTasksService.completeOrToggleTaskAtLine(oneOff, 0);
      expect(checked!.advancedRecurrence, isFalse);
      expect(checked.isNowDone, isTrue);
      expect(checked.updatedContent, '- [x] Buy milk @due(2026-11-15)');

      final unchecked = OpenTasksService.completeOrToggleTaskAtLine(
        checked.updatedContent,
        0,
      );
      expect(unchecked!.isNowDone, isFalse);
      expect(unchecked.updatedContent, oneOff);
    });

    test('setTaskReminderAtLine adds, replaces, and clears reminder tokens cleanly', () {
      const base = '- [ ] Prepare slides';
      final withReminder = OpenTasksService.setTaskReminderAtLine(
        base,
        0,
        dueAt: DateTime(2026, 11, 18, 17, 45),
        hasExplicitTime: true,
        recurrence: TaskRecurrence.weekly,
      );
      expect(
        withReminder,
        '- [ ] Prepare slides @due(2026-11-18 17:45) @repeat(weekly)',
      );

      final cleared = OpenTasksService.setTaskReminderAtLine(
        withReminder!,
        0,
        dueAt: null,
        recurrence: null,
      );
      expect(cleared, base);
    });
  });

  group('TaskReminderService scheduling payload builder', () {
    test('filters completed, past, inbox, and trashed tasks; sorts chronologically', () {
      final now = DateTime(2026, 11, 14, 8, 30);
      final activeNote = TextNote(
        id: 'note-a',
        title: 'Work',
        paletteId: 'slate',
        content: [
          '- [ ] Already passed @due(2026-11-14 07:00)',
          '- [ ] Later today date-only @due(2026-11-14)',
          '- [ ] Soon timed @due(2026-11-14 08:45) @repeat(daily)',
          '- [x] Completed future @due(2026-11-15 10:00)',
        ].join('\n'),
        createdAt: now,
        updatedAt: now,
      );
      final inboxNote = TextNote(
        id: 'daily-inbox-2026-11-14',
        title: 'Inbox',
        paletteId: 'slate',
        content: '- [ ] Inbox capture @due(2026-11-14 09:30)',
        createdAt: now,
        updatedAt: now,
        isInbox: true,
      );
      final trashedNote = TextNote(
        id: 'note-trash',
        title: 'Old',
        paletteId: 'slate',
        content: '- [ ] Trashed task @due(2026-11-14 09:15)',
        createdAt: now,
        updatedAt: now,
        isTrash: true,
      );

      final reminders = TaskReminderService.buildUpcomingReminders(
        [activeNote, inboxNote, trashedNote],
        now: now,
      );

      expect(reminders.length, 2);
      expect(reminders[0].title, 'Soon timed');
      expect(reminders[0].triggerAt, DateTime(2026, 11, 14, 8, 45));
      expect(reminders[0].repeatLabel, 'Daily');

      // Date-only task defaults to 09:00 local, which is > 08:30 now.
      expect(reminders[1].title, 'Later today date-only');
      expect(reminders[1].triggerAt, DateTime(2026, 11, 14, 9, 0));
      expect(reminders[0].stableNotificationId, isPositive);
      expect(
        reminders[0].stableNotificationId,
        isNot(reminders[1].stableNotificationId),
      );
    });
  });

  group('Task Reminder UI integration', () {
    testWidgets('RichNoteContentView hides raw tokens, renders chips, and advances recurring checkbox', (tester) async {
      String latestContent = '- [ ] Water plants @due(2026-11-14 09:00) @repeat(daily)';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: RichNoteContentView(
                content: latestContent,
                isInteractive: true,
                onContentChanged: (updated) => latestContent = updated,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Water plants', findRichText: true), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.textContaining('@due(', findRichText: true), findsNothing);
      expect(find.textContaining('@repeat(', findRichText: true), findsNothing);

      await tester.tap(find.text('Water plants', findRichText: true));
      await tester.pump();

      expect(latestContent, contains('@repeat(daily)'));
      expect(latestContent, startsWith('- [ ] Water plants @due('));
      expect(latestContent, isNot(equals('- [ ] Water plants @due(2026-11-14 09:00) @repeat(daily)')));
    });

    testWidgets('TodayScreen displays due/repeat chips cleanly and advances recurring task on tap', (tester) async {
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final repo = _InMemoryWorkspaceRepo([
        TextNote(
          id: 'task-note',
          title: 'Daily Routines',
          paletteId: 'slate',
          content: '- [ ] Take vitamins @due($todayStr 08:00) @repeat(daily)',
          createdAt: now,
          updatedAt: now,
        ),
      ]);
      final workspace = WorkspaceProvider(repo);
      await workspace.loadItems();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider.value(value: workspace),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: TodayScreen(onOpenItem: (_, {bool startInEditMode = false}) {}),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Take vitamins'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.textContaining('@due('), findsNothing);
      expect(find.textContaining('@repeat('), findsNothing);

      // Tap checkbox in the task row (left 22x22 InkWell box via text or checkbox).
      await tester.tap(find.text('Daily'));
      await tester.pump();
    });

    testWidgets('TodayScreen checkbox advances recurring task & saves updated due date', (tester) async {
      final pastDate = DateTime(2025, 1, 10, 9, 0);
      final repo = _InMemoryWorkspaceRepo([
        TextNote(
          id: 'recur-note',
          title: 'Errands',
          paletteId: 'slate',
          content: '- [ ] Weekly review @due(2025-01-10 09:00) @repeat(weekly)',
          createdAt: pastDate,
          updatedAt: pastDate,
        ),
      ]);
      final workspace = WorkspaceProvider(repo);
      await workspace.loadItems();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider.value(value: workspace),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: TodayScreen(onOpenItem: (_, {bool startInEditMode = false}) {}),
            ),
          ),
        ),
      );
      await tester.pump();

      final taskFinder = find.text('Weekly review');
      await tester.ensureVisible(taskFinder);
      await tester.pumpAndSettle();
      await tester.tap(taskFinder);
      await tester.pumpAndSettle();

      final saved = repo.store.first as TextNote;
      expect(saved.content, startsWith('- [ ] Weekly review @due('));
      expect(saved.content, contains('@repeat(weekly)'));
      expect(saved.content, isNot(contains('2025-01-10')));
    });

    testWidgets('TaskReminderSheet returns selected schedule preset and recurrence rule', (tester) async {
      TaskReminderSelection? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await TaskReminderSheet.show(
                    context: context,
                    taskTitle: 'Pay rent',
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Pay rent'), findsOneWidget);
      await tester.tap(find.text('Tomorrow · 9 AM'));
      await tester.pump();

      await tester.tap(find.text('Monthly'));
      await tester.pump();

      await tester.tap(find.text('Save Reminder'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.dueAt, isNotNull);
      expect(result!.hasExplicitTime, isTrue);
      expect(result!.dueAt!.hour, 9);
      expect(result!.recurrence, TaskRecurrence.monthly);
    });
  });
}
