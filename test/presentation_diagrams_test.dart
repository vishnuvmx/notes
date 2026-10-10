import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notes/ui/components/inputs/mermaid/mermaid_diagram_parser.dart';

void main() {
  final md = File('lib/ui/java_micro_project_presentation.md').readAsStringSync();
  final blocks = RegExp(r'```mermaid\r?\n([\s\S]*?)```')
      .allMatches(md)
      .map((m) => m.group(1)!)
      .toList();

  test('presentation contains 4 mermaid diagrams', () {
    expect(blocks.length, 4);
  });

  for (int i = 0; i < blocks.length; i++) {
    test('diagram ${i + 1} parses with all nodes and edges', () {
      final d = MermaidDiagramParser.parse(blocks[i]);
      expect(d.isValid, isTrue, reason: d.parseError);
      expect(d.nodes, isNotEmpty);
      final ids = d.nodes.map((n) => n.id).toSet();
      for (final e in d.edges) {
        expect(ids.contains(e.fromId), isTrue, reason: 'missing ${e.fromId}');
        expect(ids.contains(e.toId), isTrue, reason: 'missing ${e.toId}');
      }
      for (final n in d.nodes) {
        expect(n.label.contains('"'), isFalse, reason: 'unclean label ${n.label}');
      }
    });
  }

  test('class diagram yields 8 class boxes with members', () {
    final d = MermaidDiagramParser.parse(blocks[1]);
    expect(d.isClassDiagram, isTrue);
    expect(d.nodes.length, 8);
    expect(d.edges.length, 7);
    final base = d.nodes.firstWhere((n) => n.id == 'BaseWorkspaceItem');
    expect(base.label.contains('\u00ABabstract\u00BB'), isTrue);
    expect(base.label.contains('---'), isTrue);
  });
}
