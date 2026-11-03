/// Alignment options for GitHub-Flavored Markdown table columns.
enum TableColumnAlign {
  left,
  center,
  right;

  String toSeparatorCell() {
    switch (this) {
      case TableColumnAlign.left:
        return ':---';
      case TableColumnAlign.center:
        return ':---:';
      case TableColumnAlign.right:
        return '---:';
    }
  }

  TableColumnAlign next() {
    switch (this) {
      case TableColumnAlign.left:
        return TableColumnAlign.center;
      case TableColumnAlign.center:
        return TableColumnAlign.right;
      case TableColumnAlign.right:
        return TableColumnAlign.left;
    }
  }
}

/// Immutable representation of an editable GFM Markdown table.
class EditableMarkdownTable {
  final List<String> headers;
  final List<TableColumnAlign> alignments;
  final List<List<String>> rows;

  const EditableMarkdownTable({
    required this.headers,
    required this.alignments,
    required this.rows,
  });

  int get columnCount => headers.length;
  int get rowCount => rows.length;
}

/// Pure parsing, manipulation, and GFM serialization service for Markdown tables.
class MarkdownTableService {
  MarkdownTableService._();

  /// Strips formatting markers (bold, italic, code, orphan asterisks) so table editors
  /// work with clean, human-readable cell strings without raw markdown leaking into inputs.
  static String stripInlineMarkdown(String text) {
    var result = text.trim();
    result = result.replaceAllMapped(RegExp(r'\*\*\*(.*?)\*\*\*'), (m) => m[1] ?? '');
    result = result.replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (m) => m[1] ?? '');
    result = result.replaceAllMapped(RegExp(r'\*(.*?)\*'), (m) => m[1] ?? '');
    result = result.replaceAllMapped(RegExp(r'___(.*?)___'), (m) => m[1] ?? '');
    result = result.replaceAllMapped(RegExp(r'__(.*?)__'), (m) => m[1] ?? '');
    result = result.replaceAllMapped(RegExp(r'_(.*?)_'), (m) => m[1] ?? '');
    result = result.replaceAllMapped(RegExp(r'`(.*?)`'), (m) => m[1] ?? '');
    result = result.replaceAllMapped(RegExp(r'~~(.*?)~~'), (m) => m[1] ?? '');
    result = result.replaceAll(RegExp(r'^[\*_]+|[\*_]+$'), '');
    return result.trim();
  }

  static List<String> _splitPipeCells(String line) {
    var raw = line.trim();
    if (raw.startsWith('|')) raw = raw.substring(1);
    if (raw.endsWith('|') && !raw.endsWith(r'\|')) {
      raw = raw.substring(0, raw.length - 1);
    }
    final cells = <String>[];
    final current = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      if (raw[i] == '\\' && i + 1 < raw.length && raw[i + 1] == '|') {
        current.write('|');
        i++;
      } else if (raw[i] == '|') {
        cells.add(current.toString().trim());
        current.clear();
      } else {
        current.write(raw[i]);
      }
    }
    cells.add(current.toString().trim());
    return cells;
  }

  static EditableMarkdownTable? parseTableLines(List<String> lines, {bool stripFormatting = true}) {
    if (lines.length < 2) return null;
    final rawHeaders = _splitPipeCells(lines[0]);
    if (rawHeaders.isEmpty) return null;
    final headers = stripFormatting
        ? rawHeaders.map(stripInlineMarkdown).toList()
        : rawHeaders;

    final sepCells = _splitPipeCells(lines[1]);
    final alignments = List<TableColumnAlign>.generate(headers.length, (idx) {
      if (idx >= sepCells.length) return TableColumnAlign.left;
      final t = sepCells[idx].trim();
      if (t.startsWith(':') && t.endsWith(':')) return TableColumnAlign.center;
      if (t.endsWith(':')) return TableColumnAlign.right;
      return TableColumnAlign.left;
    });

    final rows = <List<String>>[];
    for (int r = 2; r < lines.length; r++) {
      final parsedRow = _splitPipeCells(lines[r]);
      final normalizedRow = List<String>.generate(
        headers.length,
        (c) {
          final cell = c < parsedRow.length ? parsedRow[c] : '';
          return stripFormatting ? stripInlineMarkdown(cell) : cell;
        },
      );
      rows.add(normalizedRow);
    }

    return EditableMarkdownTable(
      headers: headers,
      alignments: alignments,
      rows: rows,
    );
  }

  static String _escapeCell(String value) {
    return value.replaceAll('\n', ' ').replaceAll('|', r'\|').trim();
  }

  static String toMarkdown(EditableMarkdownTable table) {
    if (table.headers.isEmpty) return '';
    final colCount = table.headers.length;
    final buf = StringBuffer();

    final headerCells = table.headers.map((h) {
      final escaped = _escapeCell(h);
      return escaped.isEmpty ? 'Column' : escaped;
    }).join(' | ');
    buf.writeln('| $headerCells |');

    final sepCells = List<String>.generate(
      colCount,
      (i) => (i < table.alignments.length ? table.alignments[i] : TableColumnAlign.left)
          .toSeparatorCell(),
    ).join(' | ');
    buf.write('| $sepCells |');

    for (final row in table.rows) {
      buf.writeln();
      final rowCells = List<String>.generate(
        colCount,
        (i) => i < row.length ? _escapeCell(row[i]) : '',
      ).join(' | ');
      buf.write('| $rowCells |');
    }

    return buf.toString();
  }

  static String replaceTableInDocument({
    required String rawDocument,
    required int startLine,
    required int endLineExclusive,
    required EditableMarkdownTable updatedTable,
  }) {
    final lines = rawDocument.split('\n');
    final safeStart = startLine.clamp(0, lines.length);
    final safeEnd = endLineExclusive.clamp(safeStart, lines.length);
    final replacementLines = toMarkdown(updatedTable).split('\n');
    lines.replaceRange(safeStart, safeEnd, replacementLines);
    return lines.join('\n');
  }
}

