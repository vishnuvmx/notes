import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/tack_icons.dart';

/// Item in the Mermaid Completion Bar.
class MermaidCompletionItem {
  final String label;
  final String snippet;
  final String? tooltip;
  final IconData? icon;
  final int cursorOffsetFromEnd;

  const MermaidCompletionItem({
    required this.label,
    required this.snippet,
    this.tooltip,
    this.icon,
    this.cursorOffsetFromEnd = 0,
  });
}

/// Floating / docked completion strip providing one-tap completions for
/// Mermaid shapes, arrows, labels, and diagram keywords.
class MermaidCompletionBar extends StatelessWidget {
  final ValueChanged<String> onInsertSnippet;
  final VoidCallback? onOpenTemplates;
  final VoidCallback? onClose;

  const MermaidCompletionBar({
    super.key,
    required this.onInsertSnippet,
    this.onOpenTemplates,
    this.onClose,
  });

  static const List<MermaidCompletionItem> completions = [
    // Connectors
    MermaidCompletionItem(
      label: '-->',
      snippet: ' --> ',
      tooltip: 'Solid Arrow',
    ),
    MermaidCompletionItem(
      label: '-->|text|',
      snippet: ' -->|Yes| ',
      tooltip: 'Arrow with Label',
    ),
    MermaidCompletionItem(label: '---', snippet: ' --- ', tooltip: 'Open Link'),
    MermaidCompletionItem(
      label: '-.->',
      snippet: ' -.-> ',
      tooltip: 'Dotted Arrow',
    ),
    MermaidCompletionItem(
      label: '==>',
      snippet: ' ==> ',
      tooltip: 'Thick Arrow',
    ),

    // Node Shapes
    MermaidCompletionItem(
      label: '[Box]',
      snippet: 'A[Process]',
      tooltip: 'Rectangle Process',
    ),
    MermaidCompletionItem(
      label: '(Round)',
      snippet: 'B(Action)',
      tooltip: 'Rounded Rectangle',
    ),
    MermaidCompletionItem(
      label: '([Pill])',
      snippet: 'C([Start / End])',
      tooltip: 'Stadium / Pill Node',
    ),
    MermaidCompletionItem(
      label: '{Decision}',
      snippet: 'D{Condition?}',
      tooltip: 'Rhombus Decision',
    ),
    MermaidCompletionItem(
      label: '[(DB)]',
      snippet: 'E[(Database)]',
      tooltip: 'Cylinder Database',
    ),
    MermaidCompletionItem(
      label: '((Circle))',
      snippet: 'F((Node))',
      tooltip: 'Circle Node',
    ),
    MermaidCompletionItem(
      label: '{{Hex}}',
      snippet: 'G{{Preparation}}',
      tooltip: 'Hexagon Node',
    ),

    // Common Templates / Keywords
    MermaidCompletionItem(
      label: 'graph TD',
      snippet: 'graph TD\n    ',
      tooltip: 'Top-Down Flowchart',
    ),
    MermaidCompletionItem(
      label: 'graph LR',
      snippet: 'graph LR\n    ',
      tooltip: 'Left-Right Flowchart',
    ),
    MermaidCompletionItem(
      label: 'A -> B',
      snippet: 'A[Step A] --> B[Step B]\n',
      tooltip: 'Two Connected Nodes',
    ),
    MermaidCompletionItem(
      label: 'Branch Yes/No',
      snippet: 'C{Check} -->|Yes| D[Success]\n    C -->|No| E[Retry]\n',
      tooltip: 'Decision Branch',
    ),
    MermaidCompletionItem(
      label: 'sequence',
      snippet: 'sequenceDiagram\n    User->>App: Action\n    App-->>User: Response\n',
      tooltip: 'Sequence Template',
    ),
    MermaidCompletionItem(
      label: 'pie',
      snippet: 'pie title Chart\n    "Part A" : 60\n    "Part B" : 40\n',
      tooltip: 'Pie Template',
    ),
    MermaidCompletionItem(
      label: 'subgraph',
      snippet: 'subgraph GroupTitle\n    A --> B\nend\n',
      tooltip: 'Subgraph Container',
    ),
    MermaidCompletionItem(
      label: 'erDiagram',
      snippet: 'erDiagram\n    USER ||--o{ NOTE : writes\n    USER {\n        string id PK\n        string name\n    }\n    NOTE {\n        string id PK\n        string userId FK\n    }\n',
      tooltip: 'ER Diagram Template',
    ),
    MermaidCompletionItem(
      label: 'gantt',
      snippet: 'gantt\n    title Project Plan\n    section Phase 1\n    Design :done, t1, 2026-01-01, 3d\n    Build :active, t2, after t1, 5d\n',
      tooltip: 'Gantt Chart Template',
    ),
    MermaidCompletionItem(
      label: 'mindmap',
      snippet: 'mindmap\n  root((Central Idea))\n    Branch A\n      Leaf 1\n      Leaf 2\n    Branch B\n',
      tooltip: 'Mindmap Template',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = tokens.isDark;
    final cyanAccent = AppColors.getPaletteById('cyan')
        .resolveAccentColor(isDark);
    final amberAccent = AppColors.getPaletteById('amber')
        .resolveAccentColor(isDark);

    return Container(
      constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 3,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tokens.canvasSunken,
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(color: tokens.borderSubtle, width: 1),
        boxShadow: AppSpacing.elev1(isDark),
      ),
      child: Row(
        children: [
          // Mermaid indicator pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cyanAccent.withValues(alpha: isDark ? 0.22 : 0.14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TackIcon(TackIcons.flow, size: 13, color: cyanAccent),
                const SizedBox(width: 4),
                Text(
                  'MERMAID',
                  style: AppTypography.caption(
                    fontSize: 12,
                    weight: FontWeight.w800,
                    color: cyanAccent,
                  ).copyWith(letterSpacing: 0.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 22,
            child: VerticalDivider(
              width: 1,
              thickness: 1,
              color: tokens.borderSubtle,
            ),
          ),
          const SizedBox(width: 6),

          // Horizontal scrollable completion chips
          Expanded(
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: completions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final item = completions[index];
                  return Center(
                    child: Tooltip(
                      message: item.tooltip ?? item.label,
                      child: Material(
                        color: tokens.surfacePrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: tokens.borderSubtle,
                            width: 0.8,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onInsertSnippet(item.snippet);
                          },
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: AppSpacing.minTouchTarget,
                              minHeight: 36,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Center(
                                widthFactor: 1,
                                child: Text(
                                  item.label,
                                  style: AppTypography.caption(
                                    fontSize: 12,
                                    weight: FontWeight.w700,
                                    color: tokens.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          if (onOpenTemplates != null) ...[
            const SizedBox(width: 4),
            Tooltip(
              message: 'Diagram Templates',
              child: IconButton(
                icon: TackIcon(
                  TackIcons.sparkles,
                  size: 18,
                  color: amberAccent,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: AppSpacing.minTouchTarget,
                  minHeight: AppSpacing.minTouchTarget,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onOpenTemplates?.call();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
