import 'dart:math' as math;

/// Supported Mermaid diagram types.
enum MermaidDiagramType {
  flowchart,
  pie,
  sequence,
  timeline,
  erDiagram,
  gantt,
  mindmap,
  unsupported,
}

/// Shape types for flowchart and mindmap nodes.
enum MermaidNodeShape {
  process,       // [text]
  rounded,       // (text)
  pill,          // ([text])
  decision,      // {text}
  database,      // [(text)]
  circle,        // ((text))
  subroutine,    // [[text]]
  hexagon,       // {{text}}
  parallelogram, // [/text/]
  flag,          // >text]
  classBox,      // UML class box (label: header lines, '---', member lines)
}

/// Parsed node in a flowchart graph.
class MermaidNode {
  final String id;
  final String label;
  final MermaidNodeShape shape;
  final String? subgraphId;

  const MermaidNode({
    required this.id,
    required this.label,
    this.shape = MermaidNodeShape.process,
    this.subgraphId,
  });

  MermaidNode copyWith({
    String? id,
    String? label,
    MermaidNodeShape? shape,
    String? subgraphId,
  }) {
    return MermaidNode(
      id: id ?? this.id,
      label: label ?? this.label,
      shape: shape ?? this.shape,
      subgraphId: subgraphId ?? this.subgraphId,
    );
  }
}

/// Parsed subgraph container in a flowchart diagram.
class MermaidSubgraph {
  final String id;
  final String title;
  final String? parentId;
  final List<String> nodeIds;

  const MermaidSubgraph({
    required this.id,
    required this.title,
    this.parentId,
    this.nodeIds = const [],
  });
}

/// Parsed edge/connector in a flowchart graph.
class MermaidEdge {
  final String fromId;
  final String toId;
  final String? label;
  final bool isDotted;
  final bool isThick;

  const MermaidEdge({
    required this.fromId,
    required this.toId,
    this.label,
    this.isDotted = false,
    this.isThick = false,
  });
}

/// Parsed slice for pie charts.
class MermaidPieSlice {
  final String label;
  final double value;

  const MermaidPieSlice({
    required this.label,
    required this.value,
  });
}

/// Parsed message in sequence diagrams.
class MermaidSequenceMessage {
  final String from;
  final String to;
  final String text;
  final bool isDashed;

  const MermaidSequenceMessage({
    required this.from,
    required this.to,
    required this.text,
    this.isDashed = false,
  });
}

/// Parsed item/period in a timeline diagram.
class MermaidTimelineItem {
  final String period;
  final List<String> events;
  final String? section;

  const MermaidTimelineItem({
    required this.period,
    required this.events,
    this.section,
  });
}

/// Attribute row inside a Mermaid ER diagram entity.
class MermaidErAttribute {
  final String type;
  final String name;
  final String? keyType; // PK, FK, UK
  final String? comment;

  const MermaidErAttribute({
    required this.type,
    required this.name,
    this.keyType,
    this.comment,
  });
}

/// Entity table inside a Mermaid ER diagram.
class MermaidErEntity {
  final String name;
  final String? alias;
  final List<MermaidErAttribute> attributes;

  const MermaidErEntity({
    required this.name,
    this.alias,
    this.attributes = const [],
  });

  String get displayName => (alias != null && alias!.isNotEmpty) ? alias! : name;
}

/// Relationship connector between two ER entities.
class MermaidErRelation {
  final String fromEntity;
  final String toEntity;
  final String leftCardinality;  // ||, |o, o|, |{, }|, o{, }o
  final String rightCardinality; // ||, o|, |o, |{, }|, o{, }o
  final bool isNonIdentifying;   // true for '..' dashed line
  final String label;

  const MermaidErRelation({
    required this.fromEntity,
    required this.toEntity,
    required this.leftCardinality,
    required this.rightCardinality,
    this.isNonIdentifying = false,
    required this.label,
  });
}

/// Task bar entry in a Mermaid Gantt chart.
class MermaidGanttTask {
  final String? id;
  final String name;
  final String section;
  final DateTime startDate;
  final DateTime endDate;
  final bool isDone;
  final bool isActive;
  final bool isCrit;
  final bool isMilestone;

  const MermaidGanttTask({
    this.id,
    required this.name,
    required this.section,
    required this.startDate,
    required this.endDate,
    this.isDone = false,
    this.isActive = false,
    this.isCrit = false,
    this.isMilestone = false,
  });
}

/// Tree node inside a Mermaid Mindmap diagram.
class MermaidMindmapNode {
  final String id;
  final String label;
  final MermaidNodeShape shape;
  final int depth;
  final List<MermaidMindmapNode> children;

  const MermaidMindmapNode({
    required this.id,
    required this.label,
    this.shape = MermaidNodeShape.rounded,
    this.depth = 0,
    this.children = const [],
  });
}

/// Result of parsing a Mermaid code block.
class ParsedMermaidDiagram {
  final MermaidDiagramType type;
  final String rawCode;
  final String? title;
  final String direction; // 'TD', 'TB', 'LR', 'RL', 'BT'
  final List<MermaidNode> nodes;
  final List<MermaidSubgraph> subgraphs;
  final List<MermaidEdge> edges;
  final List<MermaidPieSlice> pieSlices;
  final List<String> participants;
  final List<MermaidSequenceMessage> sequenceMessages;
  final List<MermaidTimelineItem> timelineItems;
  final List<MermaidErEntity> erEntities;
  final List<MermaidErRelation> erRelations;
  final List<MermaidGanttTask> ganttTasks;
  final MermaidMindmapNode? mindmapRoot;
  final String? parseError;
  final bool isClassDiagram;

  const ParsedMermaidDiagram({
    required this.type,
    required this.rawCode,
    this.title,
    this.direction = 'TD',
    this.nodes = const [],
    this.subgraphs = const [],
    this.edges = const [],
    this.pieSlices = const [],
    this.participants = const [],
    this.sequenceMessages = const [],
    this.timelineItems = const [],
    this.erEntities = const [],
    this.erRelations = const [],
    this.ganttTasks = const [],
    this.mindmapRoot,
    this.parseError,
    this.isClassDiagram = false,
  });

  bool get isValid => parseError == null && type != MermaidDiagramType.unsupported;
}

class _MutableSubgraph {
  final String id;
  final String title;
  final String? parentId;
  final List<String> nodeIds = [];

  _MutableSubgraph({
    required this.id,
    required this.title,
    this.parentId,
  });

  void addNode(String nodeId) {
    if (!nodeIds.contains(nodeId)) {
      nodeIds.add(nodeId);
    }
  }
}

class _MutableMindmapEntry {
  final String id;
  final String label;
  final MermaidNodeShape shape;
  final int indent;
  final int depth;
  final List<_MutableMindmapEntry> children = [];

  _MutableMindmapEntry({
    required this.id,
    required this.label,
    required this.shape,
    required this.indent,
    required this.depth,
  });

  MermaidMindmapNode freeze(int resolvedDepth) {
    return MermaidMindmapNode(
      id: id,
      label: label,
      shape: shape,
      depth: resolvedDepth,
      children: [for (final c in children) c.freeze(resolvedDepth + 1)],
    );
  }
}

/// Lightweight, pure Dart parser for Mermaid diagram syntaxes
/// (flowcharts + subgraphs, pie charts, sequence, class, state, timeline, ER, Gantt, mindmap).
class MermaidDiagramParser {
  MermaidDiagramParser._();

  static ParsedMermaidDiagram parse(String rawCode) {
    final cleanCode = rawCode.trim();
    if (cleanCode.isEmpty) {
      return ParsedMermaidDiagram(
        type: MermaidDiagramType.unsupported,
        rawCode: rawCode,
        parseError: 'Empty diagram content',
      );
    }

    final rawLines = cleanCode
        .split('\n')
        .where((l) => l.trim().isNotEmpty && !l.trim().startsWith('%%'))
        .toList();

    if (rawLines.isEmpty) {
      return ParsedMermaidDiagram(
        type: MermaidDiagramType.unsupported,
        rawCode: rawCode,
        parseError: 'No active diagram statements',
      );
    }

    final lines = rawLines.map((l) => l.trim()).toList();
    final firstLine = lines.first.toLowerCase();

    // 1. Mindmap (must preserve leading indentation!)
    if (firstLine == 'mindmap' || firstLine.startsWith('mindmap ')) {
      return _parseMindmap(rawCode, rawLines);
    }

    // 2. ER Diagram: erDiagram
    if (firstLine == 'erdiagram' || firstLine.startsWith('erdiagram ')) {
      return _parseErDiagram(rawCode, lines);
    }

    // 3. Gantt Chart: gantt
    if (firstLine == 'gantt' || firstLine.startsWith('gantt ')) {
      return _parseGantt(rawCode, lines);
    }

    // 4. Pie Chart: pie [title ...]
    if (firstLine.startsWith('pie')) {
      return _parsePieChart(rawCode, lines);
    }

    // 5. Sequence Diagram: sequenceDiagram
    if (firstLine.startsWith('sequencediagram')) {
      return _parseSequenceDiagram(rawCode, lines);
    }

    // 6. UML Class Diagram: classDiagram
    if (firstLine.startsWith('classdiagram')) {
      return _parseClassDiagram(rawCode, lines);
    }

    // 7. Flowchart / Graph: graph TD / flowchart LR ...
    if (firstLine.startsWith('graph') || firstLine.startsWith('flowchart')) {
      return _parseFlowchart(rawCode, lines);
    }

    // 8. Timeline Diagram: timeline ...
    if (lines.any((l) =>
        l.toLowerCase() == 'timeline' ||
        l.toLowerCase().startsWith('timeline ') ||
        l.toLowerCase().startsWith('timeline\n'))) {
      return _parseTimeline(rawCode, lines);
    }

    // 9. State Diagram: stateDiagram / stateDiagram-v2
    if (lines.any((l) => l.toLowerCase().startsWith('statediagram'))) {
      return _parseStateDiagram(rawCode, lines);
    }

    // Fallback: If lines contain '-->' or '---', attempt flowchart parsing
    if (lines.any((l) => l.contains('-->') || l.contains('---') || l.contains('==>'))) {
      return _parseFlowchart(rawCode, lines);
    }

    return ParsedMermaidDiagram(
      type: MermaidDiagramType.unsupported,
      rawCode: rawCode,
      parseError: 'Unsupported or unrecognized Mermaid diagram type',
    );
  }

  static ParsedMermaidDiagram _parseTimeline(String rawCode, List<String> lines) {
    String? title;
    String? currentSection;
    final items = <MermaidTimelineItem>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      if (lower == 'timeline') continue;

      if (lower.startsWith('title ')) {
        title = line.substring(6).trim();
        continue;
      }

      if (lower.startsWith('section ')) {
        currentSection = line.substring(8).trim();
        continue;
      }

      if (line.contains(':')) {
        final colonIdx = line.indexOf(':');
        final prefix = line.substring(0, colonIdx).trim();
        final rest = line.substring(colonIdx + 1);
        final events = rest
            .split(':')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        if (prefix.isNotEmpty) {
          items.add(MermaidTimelineItem(
            period: prefix,
            events: events.isEmpty ? [prefix] : events,
            section: currentSection,
          ));
        } else if (items.isNotEmpty) {
          final last = items.removeLast();
          items.add(MermaidTimelineItem(
            period: last.period,
            events: [...last.events, ...events],
            section: last.section,
          ));
        }
      } else if (line.isNotEmpty && !line.startsWith('%%')) {
        items.add(MermaidTimelineItem(
          period: line.trim(),
          events: [line.trim()],
          section: currentSection,
        ));
      }
    }

    if (items.isEmpty && title == null) {
      return ParsedMermaidDiagram(
        type: MermaidDiagramType.unsupported,
        rawCode: rawCode,
        parseError: 'No timeline events found',
      );
    }

    return ParsedMermaidDiagram(
      type: MermaidDiagramType.timeline,
      rawCode: rawCode,
      title: title,
      timelineItems: items,
    );
  }

  static ParsedMermaidDiagram _parsePieChart(String rawCode, List<String> lines) {
    String? title;
    final slices = <MermaidPieSlice>[];

    final quoteStripRegex = RegExp(r'^["\x27]|["\x27]$');
    final sliceRegex = RegExp(r'^["\x27]?(.*?)["\x27]?\s*:\s*([\d.]+)');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.toLowerCase().startsWith('pie')) {
        final titleMatch = RegExp(r'title\s+([^\n\r]+)', caseSensitive: false).firstMatch(line);
        if (titleMatch != null) {
          title = titleMatch.group(1)?.replaceAll(quoteStripRegex, '').trim();
        }
        continue;
      }

      if (line.toLowerCase().startsWith('title ')) {
        title = line.substring(6).replaceAll(quoteStripRegex, '').trim();
        continue;
      }

      final sliceMatch = sliceRegex.firstMatch(line);
      if (sliceMatch != null) {
        final label = sliceMatch.group(1)?.trim() ?? 'Item';
        final val = double.tryParse(sliceMatch.group(2) ?? '0') ?? 0.0;
        if (val > 0) {
          slices.add(MermaidPieSlice(label: label, value: val));
        }
      }
    }

    if (slices.isEmpty) {
      return ParsedMermaidDiagram(
        type: MermaidDiagramType.pie,
        rawCode: rawCode,
        parseError: 'No data slices found in pie chart',
      );
    }

    return ParsedMermaidDiagram(
      type: MermaidDiagramType.pie,
      rawCode: rawCode,
      title: title,
      pieSlices: slices,
    );
  }

  static ParsedMermaidDiagram _parseSequenceDiagram(String rawCode, List<String> lines) {
    final participants = <String>{};
    final messages = <MermaidSequenceMessage>[];
    String? title;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.toLowerCase().startsWith('sequencediagram')) continue;
      if (line.toLowerCase().startsWith('autonumber')) continue;

      if (line.toLowerCase().startsWith('title ')) {
        title = line.substring(6).trim();
        continue;
      }

      final partMatch = RegExp(r'^(?:participant|actor)\s+([A-Za-z0-9_]+)(?:\s+as\s+(.+))?', caseSensitive: false).firstMatch(line);
      if (partMatch != null) {
        final name = partMatch.group(2) ?? partMatch.group(1)!;
        participants.add(name.trim());
        continue;
      }

      final msgMatch = RegExp(r'^([A-Za-z0-9_]+)\s*(-{1,2}>>?|-->>?|-x|--x)\s*([A-Za-z0-9_]+)\s*:\s*(.*)$').firstMatch(line);
      if (msgMatch != null) {
        final from = msgMatch.group(1)!.trim();
        final arrow = msgMatch.group(2)!;
        final to = msgMatch.group(3)!.trim();
        final text = msgMatch.group(4)!.trim();

        participants.add(from);
        participants.add(to);
        messages.add(MermaidSequenceMessage(
          from: from,
          to: to,
          text: text,
          isDashed: arrow.startsWith('--'),
        ));
      }
    }

    if (participants.isEmpty && messages.isEmpty) {
      return ParsedMermaidDiagram(
        type: MermaidDiagramType.sequence,
        rawCode: rawCode,
        parseError: 'No participants or interactions found',
      );
    }

    return ParsedMermaidDiagram(
      type: MermaidDiagramType.sequence,
      rawCode: rawCode,
      title: title,
      participants: participants.toList(),
      sequenceMessages: messages,
    );
  }

  static ParsedMermaidDiagram _parseFlowchart(String rawCode, List<String> lines) {
    String direction = 'TD';
    final nodeMap = <String, MermaidNode>{};
    final edges = <MermaidEdge>[];
    final subgraphStack = <_MutableSubgraph>[];
    final allSubgraphs = <_MutableSubgraph>[];
    final subgraphMap = <String, _MutableSubgraph>{};
    int sgCounter = 0;

    final header = lines.first;
    final dirMatch = RegExp(r'(?:graph|flowchart)\s+([A-Za-z]{2})', caseSensitive: false).firstMatch(header);
    if (dirMatch != null) {
      direction = dirMatch.group(1)!.toUpperCase();
      if (direction == 'TB') direction = 'TD';
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      if (i == 0 && (lower.startsWith('graph') || lower.startsWith('flowchart'))) {
        continue;
      }

      // Subgraph opening: `subgraph id [Title]`, `subgraph "Title"`, or `subgraph id`
      final sgMatch = RegExp(r'^subgraph\b(.*)$', caseSensitive: false).firstMatch(line);
      if (sgMatch != null) {
        final rest = (sgMatch.group(1) ?? '').trim();
        String sgId;
        String sgTitle;

        final bracketMatch = RegExp(r'^([A-Za-z0-9_.-]+)\s*\[(.+)\]$').firstMatch(rest);
        if (bracketMatch != null) {
          sgId = bracketMatch.group(1)!;
          sgTitle = _cleanLabel(bracketMatch.group(2)!);
        } else if (rest.isEmpty) {
          sgId = 'subgraph_${++sgCounter}';
          sgTitle = 'Group $sgCounter';
        } else {
          final cleaned = _cleanLabel(rest);
          final singleIdMatch = RegExp(r'^([A-Za-z0-9_.-]+)$').firstMatch(rest);
          if (singleIdMatch != null) {
            sgId = singleIdMatch.group(1)!;
            sgTitle = cleaned;
          } else {
            sgId = 'subgraph_${++sgCounter}';
            sgTitle = cleaned;
          }
        }

        final sg = _MutableSubgraph(
          id: sgId,
          title: sgTitle,
          parentId: subgraphStack.isEmpty ? null : subgraphStack.last.id,
        );
        subgraphStack.add(sg);
        allSubgraphs.add(sg);
        subgraphMap[sg.id] = sg;
        continue;
      }

      if (lower == 'end') {
        if (subgraphStack.isNotEmpty) {
          subgraphStack.removeLast();
        }
        continue;
      }

      if (RegExp(r'^direction\s+[A-Za-z]{2}$', caseSensitive: false).hasMatch(line)) {
        continue;
      }

      if (lower.startsWith('style ') ||
          lower.startsWith('classdef ') ||
          lower.startsWith('class ') ||
          lower.startsWith('linkstyle ') ||
          lower.startsWith('click ')) {
        continue;
      }

      final activeSg = subgraphStack.isEmpty ? null : subgraphStack.last;
      final statements = line.split(';').map((s) => s.trim()).where((s) => s.isNotEmpty);

      for (final stmt in statements) {
        _parseFlowchartStatement(
          stmt,
          nodeMap,
          edges,
          activeSubgraph: activeSg,
          subgraphMap: subgraphMap,
        );
      }
    }

    if (nodeMap.isEmpty && edges.isEmpty) {
      return ParsedMermaidDiagram(
        type: MermaidDiagramType.flowchart,
        rawCode: rawCode,
        parseError: 'Could not extract nodes or edges from flowchart',
      );
    }

    final frozenSubgraphs = allSubgraphs
        .where((sg) => sg.nodeIds.isNotEmpty || allSubgraphs.any((child) => child.parentId == sg.id))
        .map((sg) => MermaidSubgraph(
              id: sg.id,
              title: sg.title,
              parentId: sg.parentId,
              nodeIds: List.unmodifiable(sg.nodeIds),
            ))
        .toList();

    return ParsedMermaidDiagram(
      type: MermaidDiagramType.flowchart,
      rawCode: rawCode,
      direction: direction,
      nodes: nodeMap.values.toList(),
      subgraphs: frozenSubgraphs,
      edges: edges,
    );
  }

  static ParsedMermaidDiagram _parseErDiagram(String rawCode, List<String> lines) {
    final entitiesMap = <String, _MutableErEntity>{};
    final relations = <MermaidErRelation>[];
    String? title;
    _MutableErEntity? currentEntity;

    _MutableErEntity ensureEntity(String name, {String? alias}) {
      return entitiesMap.putIfAbsent(name, () => _MutableErEntity(name: name, alias: alias));
    }

    final relRegex = RegExp(
      r'^([A-Za-z0-9_-]+)\s*([|o}{]{1,2}|1|0\+|1\+)\s*(--|\.\.)\s*([|o}{]{1,2}|1|0\+|1\+)\s*([A-Za-z0-9_-]+)\s*(?::\s*(.*))?$',
    );
    final entityOpenRegex = RegExp(
      r'^([A-Za-z0-9_-]+)(?:\s*\[\s*["\x27]?([^"\x27\]]+)["\x27]?\s*\])?\s*\{$',
    );
    final attrRegex = RegExp(
      r'^([^\s]+)\s+([^\s]+)(?:\s+([A-Za-z,]+))?(?:\s+["\x27]([^"\x27]*)["\x27])?$',
    );

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      if (lower.startsWith('title ')) {
        title = _cleanLabel(line.substring(6));
        continue;
      }
      if (lower.startsWith('direction ')) continue;

      if (currentEntity != null) {
        if (line == '}') {
          currentEntity = null;
          continue;
        }
        final attrMatch = attrRegex.firstMatch(line);
        if (attrMatch != null) {
          final rawKey = attrMatch.group(3)?.toUpperCase();
          final isKeyToken = rawKey != null &&
              rawKey.split(',').every((k) => k == 'PK' || k == 'FK' || k == 'UK');
          currentEntity.attributes.add(MermaidErAttribute(
            type: attrMatch.group(1)!,
            name: attrMatch.group(2)!,
            keyType: isKeyToken ? rawKey : null,
            comment: attrMatch.group(4)?.trim(),
          ));
        }
        continue;
      }

      // Single-line empty entity: CUSTOMER {}
      final emptyEntityMatch = RegExp(r'^([A-Za-z0-9_-]+)\s*\{\s*\}$').firstMatch(line);
      if (emptyEntityMatch != null) {
        ensureEntity(emptyEntityMatch.group(1)!);
        continue;
      }

      final openMatch = entityOpenRegex.firstMatch(line);
      if (openMatch != null) {
        final name = openMatch.group(1)!;
        final alias = openMatch.group(2)?.trim();
        currentEntity = ensureEntity(name, alias: alias);
        continue;
      }

      final relMatch = relRegex.firstMatch(line);
      if (relMatch != null) {
        final from = relMatch.group(1)!;
        final leftCard = relMatch.group(2)!;
        final connector = relMatch.group(3)!;
        final rightCard = relMatch.group(4)!;
        final to = relMatch.group(5)!;
        final label = _cleanLabel(relMatch.group(6) ?? '');

        ensureEntity(from);
        ensureEntity(to);

        relations.add(MermaidErRelation(
          fromEntity: from,
          toEntity: to,
          leftCardinality: leftCard,
          rightCardinality: rightCard,
          isNonIdentifying: connector == '..',
          label: label,
        ));
      }
    }

    if (entitiesMap.isEmpty) {
      return ParsedMermaidDiagram(
        type: MermaidDiagramType.erDiagram,
        rawCode: rawCode,
        parseError: 'No entities or relationships found in ER diagram',
      );
    }

    final frozenEntities = entitiesMap.values
        .map((e) => MermaidErEntity(
              name: e.name,
              alias: e.alias,
              attributes: List.unmodifiable(e.attributes),
            ))
        .toList();

    return ParsedMermaidDiagram(
      type: MermaidDiagramType.erDiagram,
      rawCode: rawCode,
      title: title,
      erEntities: frozenEntities,
      erRelations: relations,
    );
  }

  static ParsedMermaidDiagram _parseGantt(String rawCode, List<String> lines) {
    String? title;
    String dateFormat = 'YYYY-MM-DD';
    String currentSection = 'Tasks';
    final tasks = <MermaidGanttTask>[];
    final taskById = <String, MermaidGanttTask>{};
    final now = DateTime.now();
    DateTime fallbackCursor = DateTime(now.year, now.month, now.day);

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      if (lower.startsWith('title ')) {
        title = _cleanLabel(line.substring(6));
        continue;
      }
      if (lower.startsWith('dateformat ')) {
        dateFormat = line.substring(11).trim();
        continue;
      }
      if (lower.startsWith('axisformat ') ||
          lower.startsWith('excludes ') ||
          lower.startsWith('todaymarker ') ||
          lower.startsWith('tickinterval ') ||
          lower.startsWith('weekday ') ||
          lower == 'inclusiveenddates') {
        continue;
      }
      if (lower.startsWith('section ')) {
        currentSection = _cleanLabel(line.substring(8));
        continue;
      }

      final colonIdx = line.indexOf(':');
      if (colonIdx <= 0) continue;

      final taskName = line.substring(0, colonIdx).trim();
      final metaRaw = line.substring(colonIdx + 1).trim();
      if (taskName.isEmpty || metaRaw.isEmpty) continue;

      final tokens = metaRaw.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

      bool isDone = false;
      bool isActive = false;
      bool isCrit = false;
      bool isMilestone = false;
      String? taskId;
      DateTime? startDate;
      DateTime? endDate;
      Duration? duration;

      for (final tok in tokens) {
        final tLower = tok.toLowerCase();
        if (tLower == 'done') {
          isDone = true;
        } else if (tLower == 'active') {
          isActive = true;
        } else if (tLower == 'crit') {
          isCrit = true;
        } else if (tLower == 'milestone') {
          isMilestone = true;
        } else if (tLower.startsWith('after ')) {
          final deps = tok.substring(6).trim().split(RegExp(r'\s+'));
          DateTime? maxEnd;
          for (final depId in deps) {
            final depTask = taskById[depId];
            if (depTask != null) {
              if (maxEnd == null || depTask.endDate.isAfter(maxEnd)) {
                maxEnd = depTask.endDate;
              }
            }
          }
          if (maxEnd != null) {
            startDate = maxEnd;
          }
        } else {
          final parsedDuration = _parseGanttDuration(tok);
          if (parsedDuration != null) {
            duration = parsedDuration;
          } else {
            final parsedDate = _parseGanttDate(tok, dateFormat);
            if (parsedDate != null) {
              if (startDate == null) {
                startDate = parsedDate;
              } else {
                endDate = parsedDate;
              }
            } else if (taskId == null && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(tok)) {
              taskId = tok;
            }
          }
        }
      }

      final resolvedStart = startDate ?? fallbackCursor;
      final Duration defaultSpan = isMilestone ? Duration.zero : const Duration(days: 3);
      DateTime resolvedEnd = endDate ?? resolvedStart.add(duration ?? defaultSpan);
      if (resolvedEnd.isBefore(resolvedStart)) {
        resolvedEnd = resolvedStart;
      }
      if (!isMilestone && resolvedEnd.isAtSameMomentAs(resolvedStart)) {
        resolvedEnd = resolvedStart.add(const Duration(days: 1));
      }

      final task = MermaidGanttTask(
        id: taskId,
        name: taskName,
        section: currentSection,
        startDate: resolvedStart,
        endDate: resolvedEnd,
        isDone: isDone,
        isActive: isActive,
        isCrit: isCrit,
        isMilestone: isMilestone,
      );

      tasks.add(task);
      if (taskId != null) {
        taskById[taskId] = task;
      }
      fallbackCursor = resolvedEnd;
    }

    if (tasks.isEmpty) {
      return ParsedMermaidDiagram(
        type: MermaidDiagramType.gantt,
        rawCode: rawCode,
        parseError: 'No tasks found in Gantt chart',
      );
    }

    return ParsedMermaidDiagram(
      type: MermaidDiagramType.gantt,
      rawCode: rawCode,
      title: title,
      ganttTasks: tasks,
    );
  }

  static Duration? _parseGanttDuration(String token) {
    final m = RegExp(r'^(\d+)\s*(ms|d|w|h|m|y)$', caseSensitive: false).firstMatch(token.trim());
    if (m == null) return null;
    final val = int.tryParse(m.group(1)!) ?? 0;
    final unit = m.group(2)!;
    switch (unit) {
      case 'd':
      case 'D':
        return Duration(days: val);
      case 'w':
      case 'W':
        return Duration(days: val * 7);
      case 'h':
      case 'H':
        return Duration(hours: math.max(val, 24));
      case 'M':
        return Duration(days: val * 30);
      case 'y':
      case 'Y':
        return Duration(days: val * 365);
      case 'm':
      case 'ms':
      default:
        return Duration(days: val == 0 ? 0 : 1);
    }
  }

  static DateTime? _parseGanttDate(String token, String formatHint) {
    final trimmed = token.trim();
    final direct = DateTime.tryParse(trimmed);
    if (direct != null) {
      return DateTime(direct.year, direct.month, direct.day);
    }

    final sepMatch = RegExp(r'^(\d{1,4})[/-](\d{1,2})[/-](\d{1,4})$').firstMatch(trimmed);
    if (sepMatch == null) return null;

    final a = int.tryParse(sepMatch.group(1)!) ?? 0;
    final b = int.tryParse(sepMatch.group(2)!) ?? 0;
    final c = int.tryParse(sepMatch.group(3)!) ?? 0;

    if (sepMatch.group(1)!.length == 4) {
      // YYYY-MM-DD or YYYY/MM/DD
      return DateTime(a, b.clamp(1, 12), c.clamp(1, 31));
    }
    if (sepMatch.group(3)!.length == 4) {
      // DD-MM-YYYY or MM-DD-YYYY based on hint
      final isMonthFirst = formatHint.toUpperCase().startsWith('MM');
      final month = isMonthFirst ? a : b;
      final day = isMonthFirst ? b : a;
      return DateTime(c, month.clamp(1, 12), day.clamp(1, 31));
    }
    return null;
  }

  static ParsedMermaidDiagram _parseMindmap(String rawCode, List<String> rawLines) {
    final stack = <_MutableMindmapEntry>[];
    final topLevelNodes = <_MutableMindmapEntry>[];
    int nodeCounter = 0;

    for (int i = 1; i < rawLines.length; i++) {
      final raw = rawLines[i];
      final trimmed = raw.trim();
      if (trimmed.isEmpty ||
          trimmed.startsWith('%%') ||
          trimmed.startsWith('::icon(') ||
          trimmed.startsWith(':::')) {
        continue;
      }

      // Expand tabs to 2 spaces so indentation depth compares consistently.
      final expanded = raw.replaceAll('\t', '  ');
      final indent = expanded.length - expanded.trimLeft().length;

      // Strip optional inline Mermaid class annotation :::myClass
      final cleanContent = trimmed.replaceAll(RegExp(r'\s*:::[A-Za-z0-9_-]+$'), '').trim();
      final parsedShapeAndLabel = _parseMindmapNodeToken(cleanContent);

      while (stack.isNotEmpty && stack.last.indent >= indent) {
        stack.removeLast();
      }

      final entry = _MutableMindmapEntry(
        id: 'mm_${++nodeCounter}',
        label: parsedShapeAndLabel.$1,
        shape: parsedShapeAndLabel.$2,
        indent: indent,
        depth: stack.length,
      );

      if (stack.isEmpty) {
        topLevelNodes.add(entry);
      } else {
        stack.last.children.add(entry);
      }
      stack.add(entry);
    }

    if (topLevelNodes.isEmpty) {
      return ParsedMermaidDiagram(
        type: MermaidDiagramType.mindmap,
        rawCode: rawCode,
        parseError: 'No nodes found in mindmap',
      );
    }

    final MermaidMindmapNode root;
    if (topLevelNodes.length == 1) {
      root = topLevelNodes.first.freeze(0);
    } else {
      root = MermaidMindmapNode(
        id: 'mm_root',
        label: 'Mindmap',
        shape: MermaidNodeShape.circle,
        depth: 0,
        children: [for (final n in topLevelNodes) n.freeze(1)],
      );
    }

    return ParsedMermaidDiagram(
      type: MermaidDiagramType.mindmap,
      rawCode: rawCode,
      title: root.label,
      mindmapRoot: root,
    );
  }

  static (String, MermaidNodeShape) _parseMindmapNodeToken(String token) {
    var s = token.trim();
    if (s.startsWith('root') && s.length > 4 && !RegExp(r'^[A-Za-z]').hasMatch(s[4])) {
      s = s.substring(4).trim();
    }

    final circleM = RegExp(r'^\(\((.+)\)\)$').firstMatch(s);
    if (circleM != null) return (_cleanLabel(circleM.group(1)!), MermaidNodeShape.circle);

    final pillM = RegExp(r'^\(\[(.+)\]\)$').firstMatch(s);
    if (pillM != null) return (_cleanLabel(pillM.group(1)!), MermaidNodeShape.pill);

    final hexM = RegExp(r'^\{\{(.+)\}\}$').firstMatch(s);
    if (hexM != null) return (_cleanLabel(hexM.group(1)!), MermaidNodeShape.hexagon);

    final bangM = RegExp(r'^\)\)(.+)\(\($').firstMatch(s);
    if (bangM != null) return (_cleanLabel(bangM.group(1)!), MermaidNodeShape.hexagon);

    final cloudM = RegExp(r'^\)(.+)\($').firstMatch(s);
    if (cloudM != null) return (_cleanLabel(cloudM.group(1)!), MermaidNodeShape.pill);

    final roundM = RegExp(r'^\((.+)\)$').firstMatch(s);
    if (roundM != null) return (_cleanLabel(roundM.group(1)!), MermaidNodeShape.rounded);

    final rectM = RegExp(r'^\[(.+)\]$').firstMatch(s);
    if (rectM != null) return (_cleanLabel(rectM.group(1)!), MermaidNodeShape.process);

    return (_cleanLabel(s), MermaidNodeShape.rounded);
  }

  static String _cleanLabel(String raw) {
    var s = raw.trim();
    if ((s.startsWith('"') && s.endsWith('"')) ||
        (s.startsWith("'") && s.endsWith("'"))) {
      if (s.length >= 2) {
        s = s.substring(1, s.length - 1).trim();
      }
    }
    s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    return s;
  }

  /// Parses a Mermaid classDiagram into box nodes + relationship edges.
  static ParsedMermaidDiagram _parseClassDiagram(String rawCode, List<String> lines) {
    final headers = <String, List<String>>{};
    final members = <String, List<String>>{};
    final order = <String>[];
    final edges = <MermaidEdge>[];
    String? current;

    void ensure(String name) {
      if (!headers.containsKey(name)) {
        headers[name] = [];
        members[name] = [];
        order.add(name);
      }
    }

    String clean(String s) =>
        s.replaceAllMapped(RegExp(r'~([^~]*)~'), (m) => '<${m.group(1)}>').trim();

    final relRegex = RegExp(
      r'^(\w+)\s*(?:"[^"]*"\s*)?(<\|--|--\|>|<\|\.\.|\.\.\|>|\*--|--\*|o--|--o|<--|-->|<\.\.|\.\.>|\.\.|--)\s*(?:"[^"]*"\s*)?(\w+)\s*(?::\s*(.*))?$',
    );

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      if (lower.startsWith('direction ') || lower.startsWith('title ') || lower.startsWith('note ')) continue;

      if (current != null) {
        if (line == '}') {
          current = null;
          continue;
        }
        final stereo = RegExp(r'^<<\s*(.*?)\s*>>$').firstMatch(line);
        if (stereo != null) {
          headers[current]!.add('\u00AB${stereo.group(1)}\u00BB');
        } else {
          members[current]!.add(clean(line));
        }
        continue;
      }

      final classOpen = RegExp(r'^class\s+(\w+)\s*(\{)?\s*(\})?$').firstMatch(line);
      if (classOpen != null) {
        final name = classOpen.group(1)!;
        ensure(name);
        if (classOpen.group(2) != null && classOpen.group(3) == null) current = name;
        continue;
      }

      final stereoLine = RegExp(r'^<<\s*(.*?)\s*>>\s*(\w+)$').firstMatch(line);
      if (stereoLine != null) {
        final name = stereoLine.group(2)!;
        ensure(name);
        headers[name]!.add('\u00AB${stereoLine.group(1)}\u00BB');
        continue;
      }

      final memberLine = RegExp(r'^(\w+)\s*:\s*(.+)$').firstMatch(line);
      if (memberLine != null && !line.contains('--') && !line.contains('..')) {
        final name = memberLine.group(1)!;
        ensure(name);
        members[name]!.add(clean(memberLine.group(2)!));
        continue;
      }

      final rel = relRegex.firstMatch(line);
      if (rel != null) {
        final a = rel.group(1)!;
        final op = rel.group(2)!;
        final b = rel.group(3)!;
        ensure(a);
        ensure(b);
        edges.add(MermaidEdge(
          fromId: a,
          toId: b,
          label: rel.group(4) == null ? null : _cleanLabel(rel.group(4)!),
          isDotted: op.contains('..'),
        ));
      }
    }

    if (order.isEmpty) {
      return ParsedMermaidDiagram(
        type: MermaidDiagramType.flowchart,
        rawCode: rawCode,
        parseError: 'No classes found in classDiagram',
      );
    }

    final nodes = <MermaidNode>[];
    for (final name in order) {
      final buf = <String>[...headers[name]!, name];
      if (members[name]!.isNotEmpty) {
        buf.add('---');
        buf.addAll(members[name]!);
      }
      nodes.add(MermaidNode(id: name, label: buf.join('\n'), shape: MermaidNodeShape.classBox));
    }

    return ParsedMermaidDiagram(
      type: MermaidDiagramType.flowchart,
      rawCode: rawCode,
      direction: 'TD',
      nodes: nodes,
      edges: edges,
      isClassDiagram: true,
    );
  }

  static ParsedMermaidDiagram _parseStateDiagram(String rawCode, List<String> lines) {
    String direction = 'TD';
    final nodeMap = <String, MermaidNode>{};
    final edges = <MermaidEdge>[];
    String? title;
    int stateCounter = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lower = line.toLowerCase();
      if (lower.startsWith('statediagram')) continue;
      if (lower.startsWith('direction ')) {
        final d = line.substring(10).trim().toUpperCase();
        if (d == 'LR' || d == 'RL' || d == 'TD' || d == 'BT') direction = d;
        continue;
      }
      if (lower.startsWith('title ')) {
        title = line.substring(6).trim();
        continue;
      }

      if (line.contains('-->')) {
        final parts = line.split('-->');
        if (parts.length >= 2) {
          final fromRaw = parts[0].trim();
          final rightPart = parts.sublist(1).join('-->').trim();
          String toRaw = rightPart;
          String? label;

          if (rightPart.contains(':')) {
            final colonIdx = rightPart.indexOf(':');
            toRaw = rightPart.substring(0, colonIdx).trim();
            label = _cleanLabel(rightPart.substring(colonIdx + 1));
          }

          final fromId = fromRaw == '[*]' ? 'start_${stateCounter++}' : fromRaw;
          final toId = toRaw == '[*]' ? 'end_${stateCounter++}' : toRaw;

          if (!nodeMap.containsKey(fromId)) {
            nodeMap[fromId] = MermaidNode(
              id: fromId,
              label: fromRaw == '[*]' ? 'Start' : fromRaw,
              shape: fromRaw == '[*]' ? MermaidNodeShape.circle : MermaidNodeShape.rounded,
            );
          }
          if (!nodeMap.containsKey(toId)) {
            nodeMap[toId] = MermaidNode(
              id: toId,
              label: toRaw == '[*]' ? 'End' : toRaw,
              shape: toRaw == '[*]' ? MermaidNodeShape.circle : MermaidNodeShape.rounded,
            );
          }

          edges.add(MermaidEdge(
            fromId: fromId,
            toId: toId,
            label: label,
          ));
        }
      } else if (line.isNotEmpty && !line.startsWith('%%') && !line.startsWith('note ')) {
        final id = line.split(';').first.trim();
        if (id.isNotEmpty && !nodeMap.containsKey(id)) {
          nodeMap[id] = MermaidNode(
            id: id,
            label: id,
            shape: MermaidNodeShape.rounded,
          );
        }
      }
    }

    return ParsedMermaidDiagram(
      type: MermaidDiagramType.flowchart,
      rawCode: rawCode,
      title: title,
      direction: direction,
      nodes: nodeMap.values.toList(),
      edges: edges,
    );
  }

  static void _parseFlowchartStatement(
    String stmt,
    Map<String, MermaidNode> nodeMap,
    List<MermaidEdge> edges, {
    _MutableSubgraph? activeSubgraph,
    Map<String, _MutableSubgraph> subgraphMap = const {},
  }) {
    final edgeRegex = RegExp(
      r'(-\.->\|.*?\||-->\|.*?\||--\s*.*?\s*-->|==>\|.*?\||==>|-->|-\.->|---|---.*?---)',
    );

    final edgeMatch = edgeRegex.firstMatch(stmt);
    if (edgeMatch != null) {
      final leftPart = stmt.substring(0, edgeMatch.start).trim();
      final edgeOp = edgeMatch.group(0)!;
      final rightPart = stmt.substring(edgeMatch.end).trim();

      String? edgeLabel;
      final bool isDotted = edgeOp.contains('-.');
      final bool isThick = edgeOp.contains('==');

      if (edgeOp.startsWith('-.->|') && edgeOp.endsWith('|') && edgeOp.length > 6) {
        edgeLabel = _cleanLabel(edgeOp.substring(5, edgeOp.length - 1));
      } else if (edgeOp.startsWith('-->|') && edgeOp.endsWith('|') && edgeOp.length > 5) {
        edgeLabel = _cleanLabel(edgeOp.substring(4, edgeOp.length - 1));
      } else if (edgeOp.startsWith('==>|') && edgeOp.endsWith('|') && edgeOp.length > 5) {
        edgeLabel = _cleanLabel(edgeOp.substring(4, edgeOp.length - 1));
      } else if (edgeOp.startsWith('--') && edgeOp.endsWith('-->') && edgeOp.length > 5) {
        edgeLabel = _cleanLabel(edgeOp.substring(2, edgeOp.length - 3));
      }

      final leftTokens = leftPart.split('&').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final fromIds = leftTokens
          .expand((t) => _resolveEndpointIds(t, nodeMap, activeSubgraph, subgraphMap))
          .toList();

      if (edgeRegex.hasMatch(rightPart)) {
        final firstRightNodeMatch = RegExp(r'^([^-\s=>]+(?:\[.*?\]|\(.*?\)|<.*?>|\{.*?\}|\([\[(].*?[\])]\))?)').firstMatch(rightPart);
        if (firstRightNodeMatch != null) {
          final toNodeToken = firstRightNodeMatch.group(1)!.trim();
          final toIds = _resolveEndpointIds(toNodeToken, nodeMap, activeSubgraph, subgraphMap);
          for (final fId in fromIds) {
            for (final tId in toIds) {
              edges.add(MermaidEdge(
                fromId: fId,
                toId: tId,
                label: edgeLabel,
                isDotted: isDotted,
                isThick: isThick,
              ));
            }
          }
          _parseFlowchartStatement(
            rightPart,
            nodeMap,
            edges,
            activeSubgraph: activeSubgraph,
            subgraphMap: subgraphMap,
          );
          return;
        }
      }

      final rightTokens = rightPart.split('&').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final toIds = rightTokens
          .expand((t) => _resolveEndpointIds(t, nodeMap, activeSubgraph, subgraphMap))
          .toList();

      for (final fId in fromIds) {
        for (final tId in toIds) {
          edges.add(MermaidEdge(
            fromId: fId,
            toId: tId,
            label: edgeLabel,
            isDotted: isDotted,
            isThick: isThick,
          ));
        }
      }
    } else {
      _extractNode(stmt, nodeMap, activeSubgraph: activeSubgraph);
    }
  }

  static List<String> _resolveEndpointIds(
    String token,
    Map<String, MermaidNode> nodeMap,
    _MutableSubgraph? activeSubgraph,
    Map<String, _MutableSubgraph> subgraphMap,
  ) {
    final trimmed = token.trim();
    final sg = subgraphMap[trimmed];
    if (sg != null && sg.nodeIds.isNotEmpty) {
      return [sg.nodeIds.first];
    }
    final node = _extractNode(trimmed, nodeMap, activeSubgraph: activeSubgraph);
    return node == null ? const [] : [node.id];
  }

  static MermaidNode? _extractNode(
    String token,
    Map<String, MermaidNode> nodeMap, {
    _MutableSubgraph? activeSubgraph,
  }) {
    var raw = token.trim();
    if (raw.isEmpty) return null;

    if (raw.endsWith(';')) raw = raw.substring(0, raw.length - 1).trim();

    MermaidNode upsert(String id, String label, MermaidNodeShape shape) {
      final existing = nodeMap[id];
      final sgId = existing?.subgraphId ?? activeSubgraph?.id;
      if (sgId != null && sgId == activeSubgraph?.id) {
        activeSubgraph!.addNode(id);
      }
      final node = MermaidNode(id: id, label: label, shape: shape, subgraphId: sgId);
      nodeMap[id] = node;
      return node;
    }

    // 1. Subroutine shape: A[[text]]
    var m = RegExp(r'^([A-Za-z0-9_.-]+)\s*\[\[\s*(.*?)\s*\]\]$').firstMatch(raw);
    if (m != null) return upsert(m.group(1)!, _cleanLabel(m.group(2)!), MermaidNodeShape.subroutine);

    // 2. Hexagon shape: A{{text}}
    m = RegExp(r'^([A-Za-z0-9_.-]+)\s*\{\{\s*(.*?)\s*\}\}$').firstMatch(raw);
    if (m != null) return upsert(m.group(1)!, _cleanLabel(m.group(2)!), MermaidNodeShape.hexagon);

    // 3. Parallelogram shape: A[/text/] or A[\text\]
    m = RegExp(r'^([A-Za-z0-9_.-]+)\s*\[[/\\]\s*(.*?)\s*[/\\]\]$').firstMatch(raw);
    if (m != null) return upsert(m.group(1)!, _cleanLabel(m.group(2)!), MermaidNodeShape.parallelogram);

    // 4. Pill shape: A([text])
    m = RegExp(r'^([A-Za-z0-9_.-]+)\s*\(\[\s*(.*?)\s*\]\)$').firstMatch(raw);
    if (m != null) return upsert(m.group(1)!, _cleanLabel(m.group(2)!), MermaidNodeShape.pill);

    // 5. Database/Cylinder shape: A[(text)]
    m = RegExp(r'^([A-Za-z0-9_.-]+)\s*\[\(\s*(.*?)\s*\)\]$').firstMatch(raw);
    if (m != null) return upsert(m.group(1)!, _cleanLabel(m.group(2)!), MermaidNodeShape.database);

    // 6. Circle shape: A((text))
    m = RegExp(r'^([A-Za-z0-9_.-]+)\s*\(\(\s*(.*?)\s*\)\)$').firstMatch(raw);
    if (m != null) return upsert(m.group(1)!, _cleanLabel(m.group(2)!), MermaidNodeShape.circle);

    // 7. Decision Diamond shape: A{text}
    m = RegExp(r'^([A-Za-z0-9_.-]+)\s*\{\s*(.*?)\s*\}$').firstMatch(raw);
    if (m != null) return upsert(m.group(1)!, _cleanLabel(m.group(2)!), MermaidNodeShape.decision);

    // 8. Flag / Asymmetric shape: A>text]
    m = RegExp(r'^([A-Za-z0-9_.-]+)\s*>\s*(.*?)\s*\]$').firstMatch(raw);
    if (m != null) return upsert(m.group(1)!, _cleanLabel(m.group(2)!), MermaidNodeShape.flag);

    // 9. Rounded rect shape: A(text)
    m = RegExp(r'^([A-Za-z0-9_.-]+)\s*\(\s*(.*?)\s*\)$').firstMatch(raw);
    if (m != null) return upsert(m.group(1)!, _cleanLabel(m.group(2)!), MermaidNodeShape.rounded);

    // 10. Process/Rect shape: A[text]
    m = RegExp(r'^([A-Za-z0-9_.-]+)\s*\[\s*(.*?)\s*\]$').firstMatch(raw);
    if (m != null) return upsert(m.group(1)!, _cleanLabel(m.group(2)!), MermaidNodeShape.process);

    // 11. Plain identifier without brackets: A
    final plainMatch = RegExp(r'^([A-Za-z0-9_.-]+)$').firstMatch(raw);
    if (plainMatch != null) {
      final id = plainMatch.group(1)!;
      final existing = nodeMap[id];
      if (existing == null) {
        return upsert(id, id, MermaidNodeShape.process);
      } else if (existing.subgraphId == null && activeSubgraph != null) {
        activeSubgraph.addNode(id);
        final updated = existing.copyWith(subgraphId: activeSubgraph.id);
        nodeMap[id] = updated;
        return updated;
      }
      return existing;
    }

    return null;
  }
}

class _MutableErEntity {
  final String name;
  final String? alias;
  final List<MermaidErAttribute> attributes = [];

  _MutableErEntity({required this.name, this.alias});
}
