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
    MermaidCompletionItem(
      label: '---',
      snippet: ' --- ',
      tooltip: 'Open Link',
    ),
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
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF1E212B) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? const Color(0xFF333B4F) : const Color(0xFFCBD5E1);

    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mermaid indicator pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.accentCyan.withValues(alpha: isDark ? 0.25 : 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TackIcon(
                  TackIcons.flow,
                  size: 13,
                  color: AppColors.accentCyan,
                ),
                const SizedBox(width: 4),
                Text(
                  'MERMAID',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: isDark ? AppColors.accentCyan : const Color(0xFF0E7490),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          VerticalDivider(width: 1, thickness: 1, color: borderColor),
          const SizedBox(width: 6),

          // Horizontal scrollable completion chips
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: completions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 5),
              itemBuilder: (context, index) {
                final item = completions[index];
                return Tooltip(
                  message: item.tooltip ?? item.label,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onInsertSnippet(item.snippet);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF293041) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? const Color(0xFF3B4660) : const Color(0xFFE2E8F0),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (onOpenTemplates != null) ...[
            const SizedBox(width: 4),
            Tooltip(
              message: 'Diagram Templates',
              child: IconButton(
                icon: const Icon(Icons.auto_awesome, size: 16, color: AppColors.accentAmber),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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
