import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-first Note & Spec Template definition.
class NoteTemplate {
  final String id;
  final String name;
  final String subtitle;
  final String iconEmoji;
  final String paletteId;
  final String titlePattern;
  final String bodyTemplate;
  final List<String> tags;
  final bool isCustom;

  const NoteTemplate({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.iconEmoji,
    required this.paletteId,
    required this.titlePattern,
    required this.bodyTemplate,
    this.tags = const [],
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subtitle': subtitle,
        'iconEmoji': iconEmoji,
        'paletteId': paletteId,
        'titlePattern': titlePattern,
        'bodyTemplate': bodyTemplate,
        'tags': tags,
        'isCustom': isCustom,
      };

  factory NoteTemplate.fromJson(Map<String, dynamic> json) {
    return NoteTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      subtitle: json['subtitle'] as String? ?? 'Custom saved template',
      iconEmoji: json['iconEmoji'] as String? ?? '📄',
      paletteId: json['paletteId'] as String? ?? 'peach',
      titlePattern: json['titlePattern'] as String? ?? '{{title}}',
      bodyTemplate: json['bodyTemplate'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
      isCustom: json['isCustom'] as bool? ?? true,
    );
  }
}

/// Offline-first template expansion & custom template storage service.
class NoteTemplateService {
  NoteTemplateService._();

  static const String _customTemplatesPrefsKey = 'tack_custom_note_templates_v1';

  static const List<NoteTemplate> builtInTemplates = [
    NoteTemplate(
      id: 'blank',
      name: 'Blank Note',
      subtitle: 'Clean, zero-distraction page',
      iconEmoji: '📝',
      paletteId: 'peach',
      titlePattern: '{{title}}',
      bodyTemplate: '',
    ),
    NoteTemplate(
      id: 'spec_prd',
      name: 'Product Spec (PRD)',
      subtitle: 'Structured product brief with goals, flows & criteria',
      iconEmoji: '📐',
      paletteId: 'cyan',
      titlePattern: 'Spec: {{title}}',
      tags: ['spec', 'work'],
      bodyTemplate: '''---
status: Draft
priority: High
target_date: {{date}}
---

[TOC]

## Problem & Context
What user friction are we solving and why does it matter right now?

## Core User Flow
- [ ] Entry trigger & primary happy path
- [ ] Empty & loading states
- [ ] Error / offline edge cases

## Guardrails & Out of Scope
> [!IMPORTANT]
> Explicit design or engineering constraints that must not break.
''',
    ),
    NoteTemplate(
      id: 'design_rulebook',
      name: 'Design Rulebook',
      subtitle: 'Component tokens, rules & Do/Don\'t toggles',
      iconEmoji: '🎨',
      paletteId: 'lavender',
      titlePattern: 'Rules: {{title}}',
      tags: ['design', 'rules'],
      bodyTemplate: '''---
status: Approved
priority: Medium
---

## Visual Tokens
| Token | Value | Usage |
| :--- | :--- | :--- |
| Surface | `#F8F9FA` | Main canvas |
| Radius | `16dp` | Interactive cards |
| Touch Target | `48x48dp` | Minimum tap size |

## Interaction Guidelines
>▸ Do: Keep primary actions effortless
> Surface the single primary action within thumb reach.

>▸ Don't: Stack modal dialogs
> Avoid asking administrative questions before capture.
''',
    ),
    NoteTemplate(
      id: 'decision_log',
      name: 'Decision Log (ADR)',
      subtitle: 'Options weighed, trade-offs & final call',
      iconEmoji: '⚖️',
      paletteId: 'amber',
      titlePattern: 'ADR ({{date}}): {{title}}',
      tags: ['decision', 'work'],
      bodyTemplate: '''---
status: In Review
target_date: {{date}}
---

## Context
Why is this decision needed on {{date}}?

## Options Considered
| Option | Pros | Cons |
| :--- | :--- | :--- |
| Option A | Simple, fast | Less extensible |
| Option B | Flexible | Higher complexity |

## Decision & Next Steps
- [ ] Document final choice
- [ ] Link impacted specs via [[Wiki-Links]]
''',
    ),
    NoteTemplate(
      id: 'meeting_notes',
      name: 'Meeting Notes',
      subtitle: 'Agenda, key takeaways & action items',
      iconEmoji: '🗓️',
      paletteId: 'lime',
      titlePattern: 'Sync • {{date}}',
      tags: ['meeting', 'work'],
      bodyTemplate: '''## Discussion Points ({{time}})
- 

## Key Decisions
> [!NOTE]
> Main takeaway agreed upon by the team.

## Action Items
- [ ] Follow-up item 1
- [ ] Follow-up item 2
''',
    ),
    NoteTemplate(
      id: 'cornell_notes',
      name: 'Cornell Notes',
      subtitle: 'Cues, detailed notes & summary synthesis',
      iconEmoji: '🧠',
      paletteId: 'rose',
      titlePattern: '{{title}}',
      tags: ['study'],
      bodyTemplate: '''## Key Questions & Cues
- What is the core principle behind...?

## Detailed Notes
- 

## Summary Synthesis
> [!TIP]
> Distill the entire note into 2-3 memorable sentences here.
''',
    ),
  ];

  static String formatIsoDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  static String formatShortTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  /// Expands `{{date}}`, `{{time}}`, and `{{title}}` placeholders.
  static String expandTokens(
    String templateText, {
    String? customTitle,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final safeTitle = (customTitle == null || customTitle.trim().isEmpty)
        ? 'Untitled'
        : customTitle.trim();
    return templateText
        .replaceAll('{{date}}', formatIsoDate(timestamp))
        .replaceAll('{{time}}', formatShortTime(timestamp))
        .replaceAll('{{title}}', safeTitle);
  }

  static Future<List<NoteTemplate>> loadCustomTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_customTemplatesPrefsKey);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => NoteTemplate.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<List<NoteTemplate>> loadAllTemplates() async {
    final custom = await loadCustomTemplates();
    return [...builtInTemplates, ...custom];
  }

  static Future<NoteTemplate> saveCustomTemplate({
    required String name,
    required String bodyTemplate,
    required String paletteId,
    String iconEmoji = '✨',
    List<String> tags = const [],
  }) async {
    final existing = List<NoteTemplate>.from(await loadCustomTemplates());
    final created = NoteTemplate(
      id: 'tpl_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'Custom Template' : name.trim(),
      subtitle: 'Saved custom template',
      iconEmoji: iconEmoji,
      paletteId: paletteId,
      titlePattern: '{{title}}',
      bodyTemplate: bodyTemplate,
      tags: tags,
      isCustom: true,
    );
    existing.insert(0, created);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _customTemplatesPrefsKey,
      jsonEncode(existing.map((e) => e.toJson()).toList()),
    );
    return created;
  }

  static Future<void> deleteCustomTemplate(String id) async {
    final existing = List<NoteTemplate>.from(await loadCustomTemplates());
    existing.removeWhere((t) => t.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _customTemplatesPrefsKey,
      jsonEncode(existing.map((e) => e.toJson()).toList()),
    );
  }
}

