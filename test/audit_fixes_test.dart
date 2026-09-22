import 'package:flutter_test/flutter_test.dart';
import 'package:notes/domain/models/text_note.dart';
import 'package:notes/domain/services/note_export_service.dart';
import 'package:notes/data/repositories/workspace_repo_impl.dart';
import 'package:notes/state/workspace_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDF Export Service Tests', () {
    test('generatePdfBytes produces valid PDF document header', () async {
      final pdfBytes = await NoteExportService.generatePdfBytes(
        title: 'Project Architecture',
        content: '# Heading 1\n- [ ] Task A\n- [x] Task B\n- Bullet item\n> A quote\nSome text.',
        tags: ['architecture', 'tack'],
        paletteId: 'amber',
      );

      expect(pdfBytes, isNotEmpty);
      // PDF documents always start with '%PDF-'
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, '%PDF-');
    });
  });

  group('Workspace Sort Order Tests', () {
    test('setSortOrder correctly reorders items by titleAZ, dateCreated, and recentlyModified', () async {
      final now = DateTime.now();
      final itemA = TextNote(
        id: 'note_1',
        title: 'Alpha Note',
        content: 'Content A',
        paletteId: 'amber',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      );
      final itemB = TextNote(
        id: 'note_2',
        title: 'Zeta Note',
        content: 'Content B',
        paletteId: 'amber',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 5)),
      );
      final itemC = TextNote(
        id: 'note_3',
        title: 'Beta Note',
        content: 'Content C',
        paletteId: 'amber',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
      );

      final repo = LocalStorageWorkspaceRepository(initialItems: [itemA, itemB, itemC]);
      final provider = WorkspaceProvider(repo);

      // Default: recentlyModified (itemC newest, then itemA, then itemB)
      expect(provider.sortOrder, NoteSortOrder.recentlyModified);
      expect(provider.items.map((e) => e.title).toList(), ['Beta Note', 'Alpha Note', 'Zeta Note']);

      // Sort Title A-Z: Alpha, Beta, Zeta
      provider.setSortOrder(NoteSortOrder.titleAZ);
      expect(provider.sortOrder, NoteSortOrder.titleAZ);
      expect(provider.items.map((e) => e.title).toList(), ['Alpha Note', 'Beta Note', 'Zeta Note']);

      // Sort Date Created (newest first): Zeta (1 day ago), Beta (2 days ago), Alpha (3 days ago)
      provider.setSortOrder(NoteSortOrder.dateCreated);
      expect(provider.sortOrder, NoteSortOrder.dateCreated);
      expect(provider.items.map((e) => e.title).toList(), ['Zeta Note', 'Beta Note', 'Alpha Note']);
    });
  });
}
