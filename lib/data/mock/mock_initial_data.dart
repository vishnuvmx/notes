import '../../domain/models/base_item.dart';
import '../../domain/models/text_note.dart';
import '../../domain/models/sticky_note.dart';
import '../../domain/models/whiteboard_item.dart';
import '../../domain/models/clipboard_item.dart';

/// Clean, tactile onboarding starter items matching Tack's neo-pop design identity.
class MockInitialData {
  static List<BaseWorkspaceItem> getInitialItems() {
    final now = DateTime.now();

    return [
      // 1. Neo-Pop Welcome Note
      TextNote(
        id: 'tack_welcome_note',
        title: 'Welcome to Tack',
        content:
            '# Workspace Overview\n\n'
            'Tack is designed for structured notes, sticky boards, and flowchart diagrams.\n\n'
            '### Quick Checklist\n'
            '[x] Explore your workspace dashboard\n'
            '[ ] Tap (+) below to create a note or sticky\n'
            '[ ] Apply **bold**, *italics*, and <u>underline</u> formatting\n'
            '[ ] Build a diagram on the whiteboard canvas\n'
            '### Color Hex Codes\n'
            'Type any hex code like #565656, #FF8F6B, or #1BA5BA to preview its color tint directly in the text.\n\n'
            '> "Clarity begins with structured notes."\n\n'
            '#welcome #guide #notes',
        createdAt: now.subtract(const Duration(minutes: 5)),
        updatedAt: now.subtract(const Duration(minutes: 5)),
        paletteId: 'peach',
        isFavorite: true,
        tags: ['welcome', 'guide', 'notes'],
        estimatedMinutes: 2,
      ),

      // 2. Playful Sticky Pastel
      StickyNote(
        id: 'tack_starter_sticky',
        title: 'Quick Note',
        content:
            'Shortcuts:\n'
            '• Tap (+) to add items\n'
            '• Star items for quick filtering\n'
            '• Toggle between list and grid feed\n'
            '• Switch themes in top header',
        createdAt: now.subtract(const Duration(minutes: 15)),
        updatedAt: now.subtract(const Duration(minutes: 15)),
        paletteId: 'amber',
        rotationAngle: -0.02,
        priority: 1,
        isFavorite: false,
      ),

      // 3. Figma-Style Starter Flowchart Whiteboard
      WhiteboardCanvasItem(
        id: 'tack_starter_whiteboard',
        title: 'Project Workflow Template',
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        paletteId: 'cyan',
        isFavorite: false,
        nodes: [
          const CanvasNode(
            id: 'node_spark',
            text: 'Project Proposal',
            shapeType: CanvasNodeType.startEnd,
            x: 2920,
            y: 2700,
            width: 160,
            height: 52,
            paletteId: 'coral',
          ),
          const CanvasNode(
            id: 'node_sketch',
            text: 'Design & Review',
            shapeType: CanvasNodeType.process,
            x: 2910,
            y: 2830,
            width: 180,
            height: 56,
            paletteId: 'lime',
          ),
          const CanvasNode(
            id: 'node_ship',
            text: 'Launch & Measure',
            shapeType: CanvasNodeType.startEnd,
            x: 2920,
            y: 2970,
            width: 160,
            height: 52,
            paletteId: 'amber',
          ),
        ],
        edges: [
          const CanvasEdge(
            id: 'flow_edge_1',
            fromNodeId: 'node_spark',
            toNodeId: 'node_sketch',
            fromPort: 'bottom',
            toPort: 'top',
          ),
          const CanvasEdge(
            id: 'flow_edge_2',
            fromNodeId: 'node_sketch',
            toNodeId: 'node_ship',
            fromPort: 'bottom',
            toPort: 'top',
          ),
        ],
      ),

      // 4. Sample Clipboard Card
      ClipboardItem(
        id: 'tack_starter_clip',
        title: 'Tack Design Tokens',
        clipText: 'Peach: #FF8F6B • Amber: #F5B842 • Cyan: #1BA5BA • Lime: #B2CD4D',
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        paletteId: 'lavender',
        isPinned: true,
        sourceApp: 'Tack Design System',
      ),
    ];
  }
}
