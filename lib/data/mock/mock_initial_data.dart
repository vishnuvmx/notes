import '../../domain/models/base_item.dart';
import '../../domain/models/text_note.dart';
import '../../domain/models/whiteboard_item.dart';

/// Clean, tactile onboarding starter items matching Tack's neo-pop design identity.
class MockInitialData {
  static List<BaseWorkspaceItem> getInitialItems() {
    final now = DateTime.now();

    return [
      // 1. Single explanatory starter note
      TextNote(
        id: 'tack_welcome_note',
        title: 'How Tack Works',
        content:
            '# Tack in 30 seconds\n\n'
            'Tack keeps everything you jot down in one place.\n\n'
            '### 1. Capture\n'
            'Tap (+) and pick what you need:\n'
            '- **Note** for longer writing\n'
            '- **Sticky** for a quick reminder\n'
            '- **Whiteboard** to draw a flowchart\n'
            '- **Clip** to save text you copy\n\n'
            '### 2. Organize\n'
            'Add tags, star favorites, and archive what you are done with.\n\n'
            '### 3. Find\n'
            'Use search or the filter pills to jump back to anything.\n\n'
            '> Deleted items rest in Trash until you empty it.\n\n'
            '#welcome #guide',
        createdAt: now.subtract(const Duration(minutes: 5)),
        updatedAt: now.subtract(const Duration(minutes: 5)),
        paletteId: 'peach',
        isFavorite: true,
        tags: ['welcome', 'guide'],
        estimatedMinutes: 1,
      ),

      // 2. Single simple whiteboard flow explaining the app
      WhiteboardCanvasItem(
        id: 'tack_starter_whiteboard',
        title: 'How Tack Works (Flow)',
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        paletteId: 'cyan',
        isFavorite: false,
        nodes: [
          const CanvasNode(
            id: 'n_idea',
            text: 'You have an idea',
            shapeType: CanvasNodeType.startEnd,
            x: 2920,
            y: 2700,
            width: 160,
            height: 52,
            paletteId: 'coral',
          ),
          const CanvasNode(
            id: 'n_type',
            text: 'Long or short?',
            shapeType: CanvasNodeType.decision,
            x: 2910,
            y: 2820,
            width: 180,
            height: 90,
            paletteId: 'amber',
          ),
          const CanvasNode(
            id: 'n_note',
            text: 'Write a Note',
            shapeType: CanvasNodeType.process,
            x: 2700,
            y: 2990,
            width: 160,
            height: 56,
            paletteId: 'lime',
          ),
          const CanvasNode(
            id: 'n_sticky',
            text: 'Stick a Sticky',
            shapeType: CanvasNodeType.process,
            x: 3140,
            y: 2990,
            width: 160,
            height: 56,
            paletteId: 'amber',
          ),
          const CanvasNode(
            id: 'n_organize',
            text: 'Tag, star, archive',
            shapeType: CanvasNodeType.process,
            x: 2920,
            y: 3130,
            width: 160,
            height: 56,
            paletteId: 'lavender',
          ),
          const CanvasNode(
            id: 'n_find',
            text: 'Find it with search',
            shapeType: CanvasNodeType.startEnd,
            x: 2920,
            y: 3250,
            width: 160,
            height: 52,
            paletteId: 'cyan',
          ),
        ],
        edges: [
          const CanvasEdge(
            id: 'e1',
            fromNodeId: 'n_idea',
            toNodeId: 'n_type',
            fromPort: 'bottom',
            toPort: 'top',
          ),
          const CanvasEdge(
            id: 'e2',
            fromNodeId: 'n_type',
            toNodeId: 'n_note',
            label: 'Long',
            fromPort: 'left',
            toPort: 'top',
          ),
          const CanvasEdge(
            id: 'e3',
            fromNodeId: 'n_type',
            toNodeId: 'n_sticky',
            label: 'Short',
            fromPort: 'right',
            toPort: 'top',
          ),
          const CanvasEdge(
            id: 'e4',
            fromNodeId: 'n_note',
            toNodeId: 'n_organize',
            fromPort: 'bottom',
            toPort: 'left',
          ),
          const CanvasEdge(
            id: 'e5',
            fromNodeId: 'n_sticky',
            toNodeId: 'n_organize',
            fromPort: 'bottom',
            toPort: 'right',
          ),
          const CanvasEdge(
            id: 'e6',
            fromNodeId: 'n_organize',
            toNodeId: 'n_find',
            fromPort: 'bottom',
            toPort: 'top',
          ),
        ],
      ),
    ];
  }
}
