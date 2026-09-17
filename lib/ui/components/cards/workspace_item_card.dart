import 'package:flutter/material.dart';

import '../../../domain/models/base_item.dart';
import '../../../domain/models/clipboard_item.dart';
import '../../../domain/models/sticky_note.dart';
import '../../../state/workspace_provider.dart';
import 'clipboard_card.dart';
import 'neo_note_card.dart';
import 'smart_note_list_card.dart';
import 'sticky_note_card.dart';

/// Polymorphic Workspace Card Factory that renders the appropriate tactile card
/// based on the active ViewMode (Notebook list vs Grid) and ItemType.
class WorkspaceItemCard extends StatelessWidget {
  final BaseWorkspaceItem item;
  final HomeViewMode viewMode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final int index;
  final bool isGrid;

  const WorkspaceItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onLongPress,
    this.viewMode = HomeViewMode.stickyGrid,
    this.index = 0,
    this.isGrid = true,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Notebook Mode: Render spiral spine notebook card with colored index numbers
    if (viewMode == HomeViewMode.notebook) {
      return SmartNoteListCard(
        item: item,
        index: index,
        onTap: onTap,
        onLongPress: onLongPress,
      );
    }

    // 2. Grid Mode: Polymorphic rendering by concrete domain type
    if (item is StickyNote) {
      return StickyNoteCard(
        item: item,
        onTap: onTap,
        onLongPress: onLongPress,
      );
    }

    if (item is ClipboardItem) {
      return ClipboardCard(
        item: item as ClipboardItem,
        onTap: onTap,
      );
    }

    // 3. Default (TextNote, WhiteboardCanvasItem): NeoNoteCard
    return NeoNoteCard(
      item: item,
      isGrid: isGrid,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
