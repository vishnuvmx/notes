import '../models/base_item.dart';
import '../models/clipboard_item.dart';
import '../models/sticky_note.dart';
import '../models/text_note.dart';
import '../models/whiteboard_item.dart';
import 'frontmatter_service.dart';

/// Parsed representation of a `[[Target#Anchor|Alias]]` or `![[Target#Anchor|Alias]]` link.
class ParsedWikiLink {
  final String rawMatch;
  final bool isEmbed;
  final String target;
  final String? anchor;
  final String? alias;

  const ParsedWikiLink({
    required this.rawMatch,
    required this.isEmbed,
    required this.target,
    this.anchor,
    this.alias,
  });

  String get displayLabel {
    if (alias != null && alias!.trim().isNotEmpty) {
      return alias!.trim();
    }
    if (anchor != null && anchor!.trim().isNotEmpty) {
      return '$target › ${anchor!.trim()}';
    }
    return target;
  }
}

/// Active `[[` or `![[` autocomplete state at the editor cursor.
class ActiveWikiTrigger {
  final int triggerStart; // Index of `[` (or `!` for embeds)
  final int cursorOffset;
  final bool isEmbed;
  final String targetQuery;
  final String? anchorQuery;

  const ActiveWikiTrigger({
    required this.triggerStart,
    required this.cursorOffset,
    required this.isEmbed,
    required this.targetQuery,
    this.anchorQuery,
  });
}

/// Active `/` slash command state at the start of a line.
class ActiveSlashTrigger {
  final int slashOffset;
  final int cursorOffset;
  final String query;

  const ActiveSlashTrigger({
    required this.slashOffset,
    required this.cursorOffset,
    required this.query,
  });
}

/// Backlink or unlinked mention entry pointing back to a workspace item.
class BacklinkEntry {
  final BaseWorkspaceItem sourceItem;
  final String contextSnippet;
  final bool isCanvasNodeLink;
  final String? canvasNodeId;
  final int? unlinkedMatchOffset;
  final int? unlinkedMatchLength;

  const BacklinkEntry({
    required this.sourceItem,
    required this.contextSnippet,
    this.isCanvasNodeLink = false,
    this.canvasNodeId,
    this.unlinkedMatchOffset,
    this.unlinkedMatchLength,
  });
}

/// Pure OOP service for local-first bi-directional `[[Wiki-Links]]`, `![[Embeds]]`,
/// heading anchors, active editor triggers, and backlinks discovery.
class WikiLinkService {
  WikiLinkService._();

  static final RegExp inlineWikiPattern = RegExp(r'(!?\[\[[^\[\]\n]+\]\])');

  /// Parses a single `[[...]]` or `![[...]]` token.
  static ParsedWikiLink? parseToken(String token) {
    final trimmed = token.trim();
    final isEmbed = trimmed.startsWith('![[');
    if (!isEmbed && !trimmed.startsWith('[[')) return null;
    if (!trimmed.endsWith(']]')) return null;

    final inner = trimmed.substring(isEmbed ? 3 : 2, trimmed.length - 2).trim();
    if (inner.isEmpty) return null;

    String targetAndAnchor = inner;
    String? alias;

    final pipeIdx = inner.indexOf('|');
    if (pipeIdx != -1) {
      targetAndAnchor = inner.substring(0, pipeIdx).trim();
      alias = inner.substring(pipeIdx + 1).trim();
    }

    String target = targetAndAnchor;
    String? anchor;
    final hashIdx = targetAndAnchor.indexOf('#');
    if (hashIdx != -1) {
      target = targetAndAnchor.substring(0, hashIdx).trim();
      anchor = targetAndAnchor.substring(hashIdx + 1).trim();
    }

    if (target.isEmpty) return null;

    return ParsedWikiLink(
      rawMatch: trimmed,
      isEmbed: isEmbed,
      target: target,
      anchor: (anchor != null && anchor.isEmpty) ? null : anchor,
      alias: (alias != null && alias.isEmpty) ? null : alias,
    );
  }

  /// Extracts the Markdown/text body of any workspace item.
  static String contentOfItem(BaseWorkspaceItem item) {
    if (item is TextNote) return item.content;
    if (item is StickyNote) return item.content;
    if (item is ClipboardItem) return item.clipText;
    return '';
  }

  /// Extracts all `[[...]]` and `![[...]]` links outside fenced code blocks.
  static List<ParsedWikiLink> extractAllLinks(String content) {
    if (content.isEmpty) return const [];
    final links = <ParsedWikiLink>[];
    final lines = content.split('\n');
    bool inFence = false;

    for (final line in lines) {
      if (line.trim().startsWith('```')) {
        inFence = !inFence;
        continue;
      }
      if (inFence) continue;

      for (final match in inlineWikiPattern.allMatches(line)) {
        final parsed = parseToken(match.group(0)!);
        if (parsed != null) {
          links.add(parsed);
        }
      }
    }
    return links;
  }

  /// Resolves a target name or ID against active workspace items.
  static BaseWorkspaceItem? resolveTarget(
    String target,
    Iterable<BaseWorkspaceItem> items,
  ) {
    final clean = target.trim();
    if (clean.isEmpty) return null;
    final lower = clean.toLowerCase();

    // 1. Exact ID match
    for (final item in items) {
      if (!item.isTrash && item.id == clean) return item;
    }

    // 2. Exact case-insensitive title match
    for (final item in items) {
      if (!item.isTrash && item.title.trim().toLowerCase() == lower) {
        return item;
      }
    }

    // 3. YAML frontmatter alias match
    for (final item in items) {
      if (item.isTrash) continue;
      String? content;
      if (item is TextNote) content = item.content;
      if (item is StickyNote) content = item.content;
      if (content != null && content.startsWith('---')) {
        final fm = FrontmatterService.parse(content);
        if (fm.aliases.any((a) => a.toLowerCase() == lower)) {
          return item;
        }
      }
    }

    return null;
  }

  /// Extracts all Markdown headings (`#` to `######`) outside fenced code blocks.
  static List<({int level, String title, int lineIndex})> extractHeadings(String content) {
    final results = <({int level, String title, int lineIndex})>[];
    final lines = content.split('\n');
    bool inFence = false;

    for (int i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      if (trimmed.startsWith('```')) {
        inFence = !inFence;
        continue;
      }
      if (inFence) continue;

      final match = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(trimmed);
      if (match != null) {
        results.add((
          level: match.group(1)!.length,
          title: match.group(2)!.trim(),
          lineIndex: i,
        ));
      }
    }
    return results;
  }

  /// Finds the line index of a matching heading anchor (`# Section`).
  static int? findHeadingLineIndex(String content, String? anchor) {
    if (anchor == null || anchor.trim().isEmpty) return null;
    final needle = anchor.trim().toLowerCase();
    final headings = extractHeadings(content);
    for (final h in headings) {
      if (h.title.toLowerCase() == needle) return h.lineIndex;
    }
    for (final h in headings) {
      if (h.title.toLowerCase().contains(needle)) return h.lineIndex;
    }
    return null;
  }

  /// Extracts a clean preview snippet of either a whole note or a specific `#Heading` section.
  static String extractSectionMarkdown(String content, {String? anchor, int maxLines = 6}) {
    if (content.trim().isEmpty) return '';
    final lines = content.split('\n');

    int startLine = 0;
    int? targetLevel;

    if (anchor != null && anchor.trim().isNotEmpty) {
      final idx = findHeadingLineIndex(content, anchor);
      if (idx != null) {
        startLine = idx + 1;
        final m = RegExp(r'^(#{1,6})\s+').firstMatch(lines[idx].trim());
        targetLevel = m?.group(1)?.length;
      }
    }

    final collected = <String>[];
    bool inFence = false;
    for (int i = startLine; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      if (trimmed.startsWith('```')) {
        inFence = !inFence;
        continue;
      }
      if (inFence) continue;

      if (targetLevel != null) {
        final headingMatch = RegExp(r'^(#{1,6})\s+').firstMatch(trimmed);
        if (headingMatch != null && headingMatch.group(1)!.length <= targetLevel) {
          break;
        }
      }

      if (trimmed.isNotEmpty) {
        collected.add(lines[i]);
        if (collected.length >= maxLines) break;
      }
    }

    return collected.join('\n').trim();
  }

  /// Checks whether the given character offset sits inside a fenced code block.
  static bool isInsideCodeFence(String text, int cursorOffset) {
    final safeCursor = cursorOffset.clamp(0, text.length);
    final linesBefore = text.substring(0, safeCursor).split('\n');
    int fenceCount = 0;
    for (int i = 0; i < linesBefore.length - 1; i++) {
      if (linesBefore[i].trim().startsWith('```')) {
        fenceCount++;
      }
    }
    return fenceCount.isOdd;
  }

  /// Detects an active unclosed `[[query` or `![[query` immediately before the cursor.
  static ActiveWikiTrigger? detectActiveWikiTrigger(String text, int cursorOffset) {
    if (cursorOffset < 2 || cursorOffset > text.length) return null;
    if (isInsideCodeFence(text, cursorOffset)) return null;

    final before = text.substring(0, cursorOffset);
    final lineStart = before.lastIndexOf('\n') + 1;
    final lineBeforeCursor = before.substring(lineStart);

    final openIdxInLine = lineBeforeCursor.lastIndexOf('[[');
    if (openIdxInLine == -1) return null;

    final afterOpen = lineBeforeCursor.substring(openIdxInLine + 2);
    // Already closed or contains invalid brackets
    if (afterOpen.contains(']]') || afterOpen.contains('[') || afterOpen.contains(']')) {
      return null;
    }

    final bool isEmbed = openIdxInLine > 0 && lineBeforeCursor[openIdxInLine - 1] == '!';
    final int triggerStart = lineStart + (isEmbed ? openIdxInLine - 1 : openIdxInLine);

    // Strip alias part if user already typed `|`
    final pipeIdx = afterOpen.indexOf('|');
    if (pipeIdx != -1) return null;

    String targetQuery = afterOpen;
    String? anchorQuery;
    final hashIdx = afterOpen.indexOf('#');
    if (hashIdx != -1) {
      targetQuery = afterOpen.substring(0, hashIdx);
      anchorQuery = afterOpen.substring(hashIdx + 1);
    }

    return ActiveWikiTrigger(
      triggerStart: triggerStart,
      cursorOffset: cursorOffset,
      isEmbed: isEmbed,
      targetQuery: targetQuery,
      anchorQuery: anchorQuery,
    );
  }

  /// Detects an active `/command` typed at the start of a line (outside code blocks).
  static ActiveSlashTrigger? detectActiveSlashTrigger(String text, int cursorOffset) {
    if (cursorOffset < 1 || cursorOffset > text.length) return null;
    if (isInsideCodeFence(text, cursorOffset)) return null;

    final before = text.substring(0, cursorOffset);
    final lineStart = before.lastIndexOf('\n') + 1;
    final lineBeforeCursor = before.substring(lineStart);

    final match = RegExp(r'^(\s*)\/([a-zA-Z0-9_-]*)$').firstMatch(lineBeforeCursor);
    if (match == null) return null;

    final leadingSpaces = match.group(1)!.length;
    final query = match.group(2)!;

    return ActiveSlashTrigger(
      slashOffset: lineStart + leadingSpaces,
      cursorOffset: cursorOffset,
      query: query,
    );
  }

  /// Computes both explicit Backlinks (`[[Title]]`, `![[Title]]`, Canvas Spec Cards)
  /// and Unlinked Mentions across the workspace.
  static ({List<BacklinkEntry> linked, List<BacklinkEntry> unlinked}) computeBacklinks({
    required BaseWorkspaceItem currentItem,
    required Iterable<BaseWorkspaceItem> allItems,
  }) {
    final linked = <BacklinkEntry>[];
    final unlinked = <BacklinkEntry>[];

    final currentTitle = currentItem.title.trim();
    final lowerTitle = currentTitle.toLowerCase();
    final lowerAliases = FrontmatterService.parse(contentOfItem(currentItem))
        .aliases
        .map((a) => a.toLowerCase())
        .toSet();
    bool matchesTarget(String rawTarget) {
      if (rawTarget == currentItem.id) return true;
      final lower = rawTarget.toLowerCase();
      return lower == lowerTitle || lowerAliases.contains(lower);
    }

    final canMatchUnlinked = currentTitle.length >= 3 &&
        lowerTitle != 'untitled note' &&
        lowerTitle != 'new sticky' &&
        lowerTitle != 'new whiteboard';

    for (final candidate in allItems) {
      if (candidate.isTrash || candidate.id == currentItem.id) continue;

      if (candidate is WhiteboardCanvasItem) {
        // Check if any CanvasNode pins this note or mentions [[currentTitle]] / [[alias]]
        for (final node in candidate.nodes) {
          final isDirectPin = node.linkedNoteId == currentItem.id;
          final nodeLinks = extractAllLinks(node.text);
          final mentionsViaLink = nodeLinks.any((l) => matchesTarget(l.target));
          if (isDirectPin || mentionsViaLink) {
            linked.add(
              BacklinkEntry(
                sourceItem: candidate,
                contextSnippet: isDirectPin
                    ? 'Pinned as Spec Card on "${candidate.title}"'
                    : 'Referenced in canvas node: "${node.text}"',
                isCanvasNodeLink: true,
                canvasNodeId: node.id,
              ),
            );
            break;
          }
        }
        continue;
      }

      final body = contentOfItem(candidate);
      if (body.trim().isEmpty) continue;

      final linksInCandidate = extractAllLinks(body);
      ParsedWikiLink? matchedLink;
      for (final l in linksInCandidate) {
        if (matchesTarget(l.target)) {
          matchedLink = l;
          break;
        }
      }

      if (matchedLink != null) {
        linked.add(
          BacklinkEntry(
            sourceItem: candidate,
            contextSnippet: _extractContextAround(body, matchedLink.target),
          ),
        );
      } else if (canMatchUnlinked) {
        // Look for whole-word case-insensitive plain-text mention outside [[...]]
        final escaped = RegExp.escape(currentTitle);
        final wordRegex = RegExp('(?<![\\[\\w])$escaped(?![\\]\\w])', caseSensitive: false);
        final match = wordRegex.firstMatch(body);
        if (match != null) {
          unlinked.add(
            BacklinkEntry(
              sourceItem: candidate,
              contextSnippet: _extractSnippetAtOffset(body, match.start, match.end),
              unlinkedMatchOffset: match.start,
              unlinkedMatchLength: match.end - match.start,
            ),
          );
        }
      }
    }

    return (linked: linked, unlinked: unlinked);
  }

  static String _extractContextAround(String body, String needle) {
    final lines = body.split('\n');
    final lowerNeedle = needle.toLowerCase();
    for (final line in lines) {
      if (line.toLowerCase().contains(lowerNeedle)) {
        final cleaned = line.trim();
        return cleaned.length > 96 ? '${cleaned.substring(0, 96)}...' : cleaned;
      }
    }
    final firstNonEmpty = lines.firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    return firstNonEmpty.length > 96 ? '${firstNonEmpty.substring(0, 96)}...' : firstNonEmpty;
  }

  static String _extractSnippetAtOffset(String body, int start, int end) {
    final from = (start - 32).clamp(0, body.length);
    final to = (end + 48).clamp(0, body.length);
    final raw = body.substring(from, to).replaceAll('\n', ' ').trim();
    final prefix = from > 0 ? '...' : '';
    final suffix = to < body.length ? '...' : '';
    return '$prefix$raw$suffix';
  }
}

