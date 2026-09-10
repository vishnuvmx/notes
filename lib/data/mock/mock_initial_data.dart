import '../../domain/models/base_item.dart';
import '../../domain/models/text_note.dart';
import '../../domain/models/sticky_note.dart';
import '../../domain/models/whiteboard_item.dart';
import '../../domain/models/clipboard_item.dart';

/// Seeded initial mock data reflecting all screenshots and product features.
class MockInitialData {
  static List<BaseWorkspaceItem> getInitialItems() {
    final now = DateTime.now();

    return [
      // Neo-Pop Reference Mockup Notes (Screenshot 1)
      TextNote(
        id: 'mockup_01',
        title: 'Not sure where this is going',
        content:
            "Don't read the caption, its all same, you dumb dumb, did you even read this though.\n\nDon't read the caption, its all same, you dumb dumb, did you even read this though.",
        createdAt: now.subtract(const Duration(minutes: 5)),
        updatedAt: now.subtract(const Duration(minutes: 5)),
        paletteId: 'lavender',
        isFavorite: false,
        tags: ['work', 'Ideas'],
        estimatedMinutes: 3,
      ),
      TextNote(
        id: 'mockup_02',
        title: 'Yes, created all notes on same day 😐',
        content:
            "Don't read the caption, its all same, you dumb dumb, did you even read this though.\n\nDon't read the caption, its all same, you dumb dumb.",
        createdAt: now.subtract(const Duration(minutes: 10)),
        updatedAt: now.subtract(const Duration(minutes: 10)),
        paletteId: 'lime',
        isFavorite: true,
        tags: ['Personal', 'Daily'],
        estimatedMinutes: 2,
      ),
      TextNote(
        id: 'mockup_03',
        title: 'This is a mockup stupid',
        content:
            "Don't read the caption, its all same, you dumb dumb, did you even read this though.\n\nDon't read the caption, its all same, you dumb dumb, did you even read this though.",
        createdAt: now.subtract(const Duration(minutes: 20)),
        updatedAt: now.subtract(const Duration(minutes: 20)),
        paletteId: 'cyan',
        isFavorite: false,
        tags: ['Personal', 'Design'],
        estimatedMinutes: 4,
      ),
      TextNote(
        id: 'mockup_04',
        title: 'What do you expect from me 🤬?',
        content:
            "Don't read the caption, its all same, you dumb dumb, did you even read this though.\n\nDon't read the caption, its all same, you dumb dumb, did you even read this though.",
        createdAt: now.subtract(const Duration(minutes: 30)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
        paletteId: 'amber',
        isFavorite: false,
        tags: ['Fitness', 'Workout'],
        estimatedMinutes: 5,
      ),

      // 1. Text Note from Screenshot 5
      TextNote(
        id: 'note_01',
        title: 'How to Build Trust on Your Website',
        content:
            'Key strategies to build trust with your website visitors and convert them into loyal advocates.\n\n'
            '1. Clear value proposition\n'
            '2. Transparent contact information\n'
            '3. Genuine customer testimonials and case studies\n'
            '4. Secure checkout guarantees and clear refund policies.',
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        paletteId: 'peach',
        isFavorite: true,
        tags: ['Design', 'Conversion', 'UX'],
        estimatedMinutes: 5,
      ),

      // 2. Text Note from Screenshot 5
      TextNote(
        id: 'note_02',
        title: 'Trust Badges',
        content:
            'Showcase your achievements, security certifications, and partner logos to build immediate credibility with first-time visitors.',
        createdAt: now.subtract(const Duration(hours: 4)),
        updatedAt: now.subtract(const Duration(hours: 4)),
        paletteId: 'cyan',
        isFavorite: false,
        tags: ['Marketing', 'Security'],
        estimatedMinutes: 3,
      ),

      // 3. Text Note from Screenshot 5
      TextNote(
        id: 'note_03',
        title: 'Add Contacts',
        content:
            'Make it easy for people to reach you via social media, email, direct chat, and phone. Responsive communication turns hesitant visitors into customers.',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        paletteId: 'lavender',
        isFavorite: true,
        tags: ['Support', 'Operations'],
        estimatedMinutes: 4,
      ),

      // 4. Text Note from Screenshot 5
      TextNote(
        id: 'note_04',
        title: 'Case Studies',
        content:
            'Use real examples of how your product solves problems for your customers. Highlight the before-and-after metric changes and client quotes.',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
        paletteId: 'amber',
        isFavorite: false,
        tags: ['Growth', 'Stories'],
        estimatedMinutes: 6,
      ),

      // 5. Text Note from Screenshot 5
      TextNote(
        id: 'note_05',
        title: 'Clear Refund Policy',
        content:
            'Offer a transparent and easy return or refund policy for your customers. It de-risks purchases and dramatically lowers buyer friction.',
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 4)),
        paletteId: 'lime',
        isFavorite: false,
        tags: ['Legal', 'Sales'],
        estimatedMinutes: 2,
      ),

      // 6. Text Note from Screenshot 5
      TextNote(
        id: 'note_06',
        title: 'Social Proof',
        content:
            'Show testimonials, reviews, ratings, and video feedback from happy customers. Verified reviews increase conversion rates by up to 270%.',
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now.subtract(const Duration(days: 6)),
        paletteId: 'rose',
        isFavorite: true,
        tags: ['Strategy', 'Growth'],
        estimatedMinutes: 4,
      ),

      // 7. Sticky Note (Sunset Peach) from Screenshot 1 & 3
      StickyNote(
        id: 'sticky_01',
        title: 'Q3 Product Goals',
        content: 'Refactor mobile canvas touch gesture recognizer & optimize font cache loading.',
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        paletteId: 'peach',
        rotationAngle: -0.02,
        priority: 1,
        isFavorite: true,
      ),

      // 8. Sticky Note (Warm Amber) from Screenshot 1 & 3
      StickyNote(
        id: 'sticky_02',
        title: 'Design Critique',
        content: 'Review the soft pastel contrast ratios in dark mode with the UX team at 3 PM.',
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        paletteId: 'amber',
        rotationAngle: 0.015,
        priority: 0,
      ),

      // 9. Sticky Note (Coral Blush)
      StickyNote(
        id: 'sticky_03',
        title: 'Groceries & Supplies',
        content: '• Organic Oat Milk\n• Espresso roast beans\n• Sticky tabs\n• Drawing pens',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        paletteId: 'coral',
        rotationAngle: -0.01,
        priority: 0,
      ),

      // 10. Sticky Note (Lavender Mist)
      StickyNote(
        id: 'sticky_04',
        title: 'Flutter Key Takeaways',
        content: 'Polymorphism via BaseWorkspaceItem makes search & filtering super clean across tabs!',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
        paletteId: 'lavender',
        rotationAngle: 0.02,
        priority: 2,
        isFavorite: true,
      ),

      // 11. Sticky Note (Cyan Breeze)
      StickyNote(
        id: 'sticky_05',
        title: 'Idea: Voice Memos',
        content: 'Explore Android speech-to-text integration for quick floating sticky notes.',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
        paletteId: 'cyan',
        rotationAngle: -0.015,
        priority: 0,
      ),

      // 12. Sticky Note (Lime Zing)
      StickyNote(
        id: 'sticky_06',
        title: 'Workout Schedule',
        content: 'Mon: Upper body\nTue: 5km run\nThu: Core & Legs\nSat: Yoga & stretch',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
        paletteId: 'lime',
        rotationAngle: 0.01,
        priority: 0,
      ),

      // 13. Whiteboard Flowchart Canvas (Screenshot 4: Prime Number Checker)
      WhiteboardCanvasItem(
        id: 'whiteboard_01',
        title: 'Prime Number Checker',
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        paletteId: 'cyan',
        isFavorite: true,
        nodes: [
          const CanvasNode(
            id: 'node_start',
            text: 'Start',
            shapeType: CanvasNodeType.startEnd,
            x: 120,
            y: 30,
            width: 110,
            height: 48,
            paletteId: 'coral',
          ),
          const CanvasNode(
            id: 'node_input',
            text: 'Input number n',
            shapeType: CanvasNodeType.inputOutput,
            x: 95,
            y: 115,
            width: 160,
            height: 54,
            paletteId: 'lime',
          ),
          const CanvasNode(
            id: 'node_dec1',
            text: 'Is n < 2?',
            shapeType: CanvasNodeType.decision,
            x: 105,
            y: 205,
            width: 140,
            height: 68,
            paletteId: 'lavender',
          ),
          const CanvasNode(
            id: 'node_print_not_prime1',
            text: 'Print "Not Prime"',
            shapeType: CanvasNodeType.inputOutput,
            x: 270,
            y: 220,
            width: 140,
            height: 50,
            paletteId: 'amber',
          ),
          const CanvasNode(
            id: 'node_set_i',
            text: 'Set i = 2',
            shapeType: CanvasNodeType.process,
            x: 100,
            y: 310,
            width: 150,
            height: 52,
            paletteId: 'lime',
          ),
          const CanvasNode(
            id: 'node_dec2',
            text: 'Is i * i > n?',
            shapeType: CanvasNodeType.decision,
            x: 100,
            y: 395,
            width: 150,
            height: 68,
            paletteId: 'lavender',
          ),
          const CanvasNode(
            id: 'node_print_prime',
            text: 'Print "Prime"',
            shapeType: CanvasNodeType.inputOutput,
            x: 105,
            y: 495,
            width: 140,
            height: 50,
            paletteId: 'amber',
          ),
          const CanvasNode(
            id: 'node_end',
            text: 'End',
            shapeType: CanvasNodeType.startEnd,
            x: 120,
            y: 575,
            width: 110,
            height: 48,
            paletteId: 'coral',
          ),
        ],
        edges: [
          const CanvasEdge(
            id: 'edge_1',
            fromNodeId: 'node_start',
            toNodeId: 'node_input',
          ),
          const CanvasEdge(
            id: 'edge_2',
            fromNodeId: 'node_input',
            toNodeId: 'node_dec1',
          ),
          const CanvasEdge(
            id: 'edge_3',
            fromNodeId: 'node_dec1',
            toNodeId: 'node_print_not_prime1',
            label: 'Yes',
            fromPort: 'right',
            toPort: 'left',
          ),
          const CanvasEdge(
            id: 'edge_4',
            fromNodeId: 'node_dec1',
            toNodeId: 'node_set_i',
            label: 'No',
          ),
          const CanvasEdge(
            id: 'edge_5',
            fromNodeId: 'node_set_i',
            toNodeId: 'node_dec2',
          ),
          const CanvasEdge(
            id: 'edge_6',
            fromNodeId: 'node_dec2',
            toNodeId: 'node_print_prime',
            label: 'Yes',
          ),
          const CanvasEdge(
            id: 'edge_7',
            fromNodeId: 'node_print_prime',
            toNodeId: 'node_end',
          ),
        ],
      ),

      // 14. Clipboard Item
      ClipboardItem(
        id: 'clip_01',
        title: 'Flutter Clean Architecture Snippet',
        clipText: 'abstract class IWorkspaceRepository {\n  Future<List<BaseWorkspaceItem>> getAllActiveItems();\n}',
        createdAt: now.subtract(const Duration(minutes: 35)),
        updatedAt: now.subtract(const Duration(minutes: 35)),
        paletteId: 'slate',
        isPinned: true,
        sourceApp: 'VS Code / Android Studio',
      ),

      // 15. Clipboard Item
      ClipboardItem(
        id: 'clip_02',
        title: 'Design Token Hex Codes',
        clipText: 'Peach: #FF8F6B | Amber: #F5B842 | Lavender: #9D84D6 | Cyan: #1BA5BA',
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(hours: 3)),
        paletteId: 'slate',
        isPinned: false,
        sourceApp: 'Figma',
      ),
    ];
  }
}
