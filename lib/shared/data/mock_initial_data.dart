import '../models/base_item.dart';
import '../../features/notes/models/text_note.dart';
import '../../features/whiteboard/models/whiteboard_item.dart';

/// Clean, editorial starter items matching Tack's Paper & Pin design identity.
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
            'Tack is a calm, offline-first notebook and board workspace.\n\n'
            '### 1. Capture\n'
            'Tap **(+)** from any screen to jot a quick thought to your **Inbox**, '
            'open a full **Note**, or start a visual **Board**.\n\n'
            '### 2. Today & Triage\n'
            'Your **Today** view collects your daily note, unsorted Inbox captures, '
            'and open `- [ ]` tasks across every note:\n'
            '- [ ] Try checking off this task from Today\n'
            '- [ ] Link notes together with `[[How Tack Works]]`\n\n'
            '### 3. Library & Boards\n'
            'Pin important notes so they stay at the top, or place notes directly '
            'onto a **Board** as live Spec Cards.\n\n'
            '> Deleted items rest in Trash (under **You**) until you empty it.\n\n'
            '#welcome #guide',
        createdAt: now.subtract(const Duration(minutes: 5)),
        updatedAt: now.subtract(const Duration(minutes: 5)),
        paletteId: 'amber',
        isFavorite: true,
        tags: ['welcome', 'guide'],
        links: ['How Tack Works'],
        estimatedMinutes: 1,
      ),

      // 2. Single simple board flow explaining the app
      WhiteboardCanvasItem(
        id: 'tack_starter_whiteboard',
        title: 'Capture to Clarity (Board)',
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        paletteId: 'cyan',
        isFavorite: true,
        nodes: [
          const CanvasNode(
            id: 'n_idea',
            text: 'Quick thought',
            shapeType: CanvasNodeType.startEnd,
            x: 2920,
            y: 2700,
            width: 160,
            height: 52,
            paletteId: 'coral',
          ),
          const CanvasNode(
            id: 'n_type',
            text: 'Need structure?',
            shapeType: CanvasNodeType.decision,
            x: 2910,
            y: 2820,
            width: 180,
            height: 90,
            paletteId: 'amber',
          ),
          const CanvasNode(
            id: 'n_note',
            text: 'Write in Note',
            shapeType: CanvasNodeType.process,
            x: 2700,
            y: 2990,
            width: 160,
            height: 56,
            paletteId: 'lime',
          ),
          const CanvasNode(
            id: 'n_inbox',
            text: 'Save to Inbox',
            shapeType: CanvasNodeType.process,
            x: 3140,
            y: 2990,
            width: 160,
            height: 56,
            paletteId: 'peach',
          ),
          const CanvasNode(
            id: 'n_spec',
            text: 'Pin onto Board\n#welcome',
            shapeType: CanvasNodeType.specCard,
            x: 2890,
            y: 3130,
            width: 220,
            height: 110,
            paletteId: 'lavender',
            linkedNoteId: 'tack_welcome_note',
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
            toNodeId: 'n_inbox',
            label: 'Quick',
            fromPort: 'right',
            toPort: 'top',
          ),
          const CanvasEdge(
            id: 'e4',
            fromNodeId: 'n_note',
            toNodeId: 'n_spec',
            fromPort: 'bottom',
            toPort: 'left',
          ),
          const CanvasEdge(
            id: 'e5',
            fromNodeId: 'n_inbox',
            toNodeId: 'n_spec',
            fromPort: 'bottom',
            toPort: 'right',
          ),
        ],
      ),
    ];
  }
}
