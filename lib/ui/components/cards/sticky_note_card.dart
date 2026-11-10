import 'package:flutter/material.dart';
import '../../../domain/models/base_item.dart';
import 'neo_note_card.dart';

/// Legacy wrapper for StickyNoteCard that delegates to the unified Paper & Pin
/// [NeoNoteCard] (`05` §7.2, `07` §7: no card rotation in grid; 6dp object-color band).
class StickyNoteCard extends StatelessWidget {
  final BaseWorkspaceItem item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const StickyNoteCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return NeoNoteCard(
      item: item,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
