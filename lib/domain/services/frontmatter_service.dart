/// Service for parsing and updating Obsidian / Figma-Specs compatible
/// YAML frontmatter (`--- ... ---`) at the top of Markdown notes.
///
/// Keeps Tack 100% local-first and `.md`-portable without needing any database.
class ParsedNoteFrontmatter {
  final Map<String, String> properties;
  final String bodyWithoutFrontmatter;

  /// Number of lines occupied by the frontmatter block at the top of [rawContent]
  /// (including trailing newline line offset), or `0` when no frontmatter exists.
  final int contentStartLineIndex;

  const ParsedNoteFrontmatter({
    required this.properties,
    required this.bodyWithoutFrontmatter,
    required this.contentStartLineIndex,
  });

  bool get hasProperties => properties.isNotEmpty;

  String? get status => properties['status'];
  String? get priority => properties['priority'];
  String? get targetDate => properties['target_date'] ?? properties['due'];

  List<String> get aliases {
    final raw = properties['aliases'] ?? properties['alias'];
    if (raw == null || raw.trim().isEmpty) return const [];
    var cleaned = raw.trim();
    if (cleaned.startsWith('[') && cleaned.endsWith(']')) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    return cleaned
        .split(',')
        .map((s) => s.trim().replaceAll(RegExp('^["\']|["\']\$'), ''))
        .where((s) => s.isNotEmpty)
        .toList();
  }
}

class FrontmatterService {
  FrontmatterService._();

  static const List<String> statusPresets = [
    'Draft',
    'In Review',
    'Approved',
    'Blocked',
  ];

  static const List<String> priorityPresets = [
    'Low',
    'Medium',
    'High',
    'Urgent',
  ];

  /// Parses optional `---` YAML frontmatter at line 0 of [rawContent].
  static ParsedNoteFrontmatter parse(String rawContent) {
    if (rawContent.isEmpty) {
      return const ParsedNoteFrontmatter(
        properties: {},
        bodyWithoutFrontmatter: '',
        contentStartLineIndex: 0,
      );
    }

    final lines = rawContent.split('\n');
    if (lines.isEmpty || lines.first.trim() != '---') {
      return ParsedNoteFrontmatter(
        properties: const {},
        bodyWithoutFrontmatter: rawContent,
        contentStartLineIndex: 0,
      );
    }

    int closingIdx = -1;
    for (int i = 1; i < lines.length; i++) {
      final t = lines[i].trim();
      if (t == '---' || t == '...') {
        closingIdx = i;
        break;
      }
    }

    if (closingIdx == -1) {
      return ParsedNoteFrontmatter(
        properties: const {},
        bodyWithoutFrontmatter: rawContent,
        contentStartLineIndex: 0,
      );
    }

    final props = <String, String>{};
    bool validYaml = true;
    for (int i = 1; i < closingIdx; i++) {
      final line = lines[i];
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final colonIdx = trimmed.indexOf(':');
      if (colonIdx <= 0) {
        validYaml = false;
        break;
      }
      final key = trimmed.substring(0, colonIdx).trim().toLowerCase();
      var val = trimmed.substring(colonIdx + 1).trim();
      if ((val.startsWith('"') && val.endsWith('"') && val.length >= 2) ||
          (val.startsWith("'") && val.endsWith("'") && val.length >= 2)) {
        val = val.substring(1, val.length - 1);
      }
      if (key.isNotEmpty) {
        props[key] = val;
      }
    }

    if (!validYaml) {
      return ParsedNoteFrontmatter(
        properties: const {},
        bodyWithoutFrontmatter: rawContent,
        contentStartLineIndex: 0,
      );
    }

    int bodyStartIdx = closingIdx + 1;
    // Skip a single blank separator line right after closing `---` for clean rendering,
    // while tracking exact line index in the original document.
    if (bodyStartIdx < lines.length && lines[bodyStartIdx].trim().isEmpty) {
      bodyStartIdx++;
    }

    final body = bodyStartIdx < lines.length
        ? lines.sublist(bodyStartIdx).join('\n')
        : '';

    return ParsedNoteFrontmatter(
      properties: props,
      bodyWithoutFrontmatter: body,
      contentStartLineIndex: bodyStartIdx,
    );
  }

  /// Serializes [properties] and [bodyWithoutFrontmatter] back into standard Markdown.
  /// If [properties] is empty, returns [bodyWithoutFrontmatter] cleanly without empty `---`.
  static String serialize(
    Map<String, String> properties,
    String bodyWithoutFrontmatter,
  ) {
    final nonEmpty = <String, String>{};
    for (final entry in properties.entries) {
      final k = entry.key.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
      final v = entry.value.trim();
      if (k.isNotEmpty && v.isNotEmpty) {
        nonEmpty[k] = v;
      }
    }

    if (nonEmpty.isEmpty) {
      return bodyWithoutFrontmatter;
    }

    final buffer = StringBuffer('---\n');
    for (final entry in nonEmpty.entries) {
      final v = entry.value;
      final needsQuotes = v.contains(':') || v.contains('#');
      buffer.writeln(
        needsQuotes ? '${entry.key}: "${v.replaceAll('"', '\\"')}"' : '${entry.key}: $v',
      );
    }
    buffer.writeln('---');
    if (bodyWithoutFrontmatter.isNotEmpty) {
      buffer.write('\n$bodyWithoutFrontmatter');
    }
    return buffer.toString();
  }

  /// Updates or removes (`value == null` or empty) a single frontmatter property in [rawContent].
  static String upsertProperty(String rawContent, String key, String? value) {
    final parsed = parse(rawContent);
    final updated = Map<String, String>.from(parsed.properties);
    final normalizedKey = key.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    if (value == null || value.trim().isEmpty) {
      updated.remove(normalizedKey);
    } else {
      updated[normalizedKey] = value.trim();
    }
    return serialize(updated, parsed.bodyWithoutFrontmatter);
  }
}

