import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notes/data/repositories/workspace_repo_impl.dart';
import 'package:notes/state/workspace_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Clipboard Rules Tests', () {
    test('isIndividualNumber correctly identifies standalone numbers and ignores text paragraphs', () {
      // Individual numbers should be true
      expect(WorkspaceProvider.isIndividualNumber('4'), true);
      expect(WorkspaceProvider.isIndividualNumber('  42  '), true);
      expect(WorkspaceProvider.isIndividualNumber('3.14'), true);
      expect(WorkspaceProvider.isIndividualNumber('-100'), true);
      expect(WorkspaceProvider.isIndividualNumber('+919876543210'), true);
      expect(WorkspaceProvider.isIndividualNumber('123-456-7890'), true);
      expect(WorkspaceProvider.isIndividualNumber(r'$50'), true);
      expect(WorkspaceProvider.isIndividualNumber('₹500'), true);
      expect(WorkspaceProvider.isIndividualNumber('45%'), true);
      expect(WorkspaceProvider.isIndividualNumber('(123)'), true);
      expect(WorkspaceProvider.isIndividualNumber('1,000,000'), true);

      // Paragraphs and text containing words/letters should be false
      expect(WorkspaceProvider.isIndividualNumber('This paragraph contains 4 numbers: 2, 10, and 5.'), false);
      expect(WorkspaceProvider.isIndividualNumber('Meeting at 4 with 2 colleagues to review 10 pages and 5 tasks'), false);
      expect(WorkspaceProvider.isIndividualNumber('Tack Design Tokens'), false);
      expect(WorkspaceProvider.isIndividualNumber('Room 101'), false);
      expect(WorkspaceProvider.isIndividualNumber('Chapter 4'), false);
      expect(WorkspaceProvider.isIndividualNumber('#FF8F6B'), false);
      expect(WorkspaceProvider.isIndividualNumber('4 apples'), false);
      expect(WorkspaceProvider.isIndividualNumber(''), false);
    });

    test('saveClipboardSnippet prevents duplicates and does not add twice', () async {
      final repository = LocalStorageWorkspaceRepository(initialItems: []);
      final provider = WorkspaceProvider(repository);
      await provider.loadItems();

      // First add should succeed
      final snippet = 'A useful note snippet to remember.';
      final firstItem = await provider.saveClipboardSnippet(snippet);
      expect(firstItem, isNotNull);
      expect(firstItem?.clipText, snippet);
      expect(provider.totalClipsCount, 1);

      // Second add of the same snippet should be rejected as duplicate
      final secondItem = await provider.saveClipboardSnippet(snippet);
      expect(secondItem, isNull);
      expect(provider.totalClipsCount, 1); // Count remains 1, no duplicate added

      // Second add with extra whitespace should also be rejected
      final thirdItem = await provider.saveClipboardSnippet('   $snippet   ');
      expect(thirdItem, isNull);
      expect(provider.totalClipsCount, 1);
    });

    test('saveClipboardSnippet ignores individual numbers but saves paragraphs with numbers', () async {
      final repository = LocalStorageWorkspaceRepository(initialItems: []);
      final provider = WorkspaceProvider(repository);
      await provider.loadItems();

      // Attempting to add individual numbers should return null and not be saved
      expect(await provider.saveClipboardSnippet('4'), isNull);
      expect(await provider.saveClipboardSnippet('2'), isNull);
      expect(await provider.saveClipboardSnippet('10'), isNull);
      expect(await provider.saveClipboardSnippet('5'), isNull);
      expect(provider.totalClipsCount, 0);

      // Adding the full paragraph with numbers should succeed
      final paragraph = 'We have 4 tasks, 2 reviews, 10 comments, and 5 approvals.';
      final paragraphItem = await provider.saveClipboardSnippet(paragraph);
      expect(paragraphItem, isNotNull);
      expect(paragraphItem?.clipText, paragraph);
      expect(provider.totalClipsCount, 1); // Only the paragraph was saved!
    });
  });
}
