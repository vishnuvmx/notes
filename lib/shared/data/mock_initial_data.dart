import '../models/base_item.dart';
import '../../features/notes/models/text_note.dart';
import '../../features/tasks/services/open_tasks_service.dart';
import '../../features/whiteboard/models/whiteboard_item.dart';

/// Default starter note and flowchart board showcasing Tack's full capabilities.
class MockInitialData {
  static const String welcomeNoteId = 'tack_welcome_note';
  static const String starterBoardId = 'tack_starter_whiteboard';

  static TextNote buildStarterNote(DateTime now) {
    final todayDay = DateTime(now.year, now.month, now.day);
    final todayDueToken = OpenTasksService.formatDueToken(todayDay);

    final content = '''---
status: Approved
priority: High
aliases: [How Tack Works, Starter Guide]
---

Tack is an offline-first workspace uniting rich Markdown notes, interactive tasks, and flowchart boards locally on your device.

[TOC]

![Tactile paper notes, pins, and checklists in Tack — tap to zoom](assets/images/onboarding/slide1_tactile_grid.jpg)

## 1. Rich Writing & Formatting

Write in clean Markdown using the keyboard toolbar or type `/` on a new line for instant block commands.

- **Bold**, *italic*, __underline__, ~~strikethrough~~, ==highlight==, and ==cyan:palette highlights==
- Inline `code` chips, superscript E = mc^2^, subscript H~2~O, and live swatches #FF8F6B #1BA5BA #9D84D6
- Clickable links like [Markdown Reference](https://www.markdownguide.org/) and interactive footnotes[^1]

1. Fold any heading section in Reader mode using the chevron beside its title
2. Double-tap to jump from Reader mode straight into editing at that spot
3. Press Back from Edit mode to auto-save and return calmly to Reader mode

> Every keystroke saves automatically to device storage with zero cloud setup required.

## 2. Callouts, Toggles & Definitions

> [!TIP] Capture From Anywhere
> Tap **(+)** at the bottom to drop a fast **Inbox** thought, open a **Note**, or sketch a **Board**.

> [!IMPORTANT] Local-First Privacy
> Everything lives on your device. Export a portable JSON snapshot anytime from **Settings → Export backup**.

> [!NOTE] Clean Graph Connections
> Link notes and boards with WikiLinks to build an interactive **Knowledge Graph** automatically.

>▸ Tap to expand toggle details
> Collapse checklists, background specs, or reference notes inside tidy toggles using `>▸ Title` or `<details>`.

Tack
: Tactile Android notebook and board studio built around calm Paper & Pin design.
Local Sanctuary
: Zero accounts or external syncing—exportable anytime as Markdown, PDF, PNG, or JSON.

## 3. Interactive Tasks & Today Feed

Checklist items inside notes automatically surface in **Home → To-Do**, with live filtering and recurrence:

- [x] Explore Home to switch between To-Do and Completed views
- [ ] Tap this checkbox in Reader mode to test live completion
- [ ] Review daily focus goals $todayDueToken @repeat(daily)
- [ ] Pin an important note to your notification shade from the menu

## 4. Tables, LaTeX Math & Code

Tap **Edit Table** above any Markdown table to adjust rows, columns, and alignments visually:

| Capability | Trigger / Syntax | Where to Try |
| :--- | :--- | :--- |
| Slash Commands | Type `/` on blank line | Edit mode anywhere |
| Scheduled Tasks | `- [ ]` + `@due(today)` | Home → To-Do tab |
| Board Embeds | `![[Capture to Clarity]]` | Reader mode below |
| Hero Lightbox | Tap any image block | Above & Gallery |

Render inline equations like \$\\nabla \\cdot \\mathbf{E} = \\frac{\\rho}{\\varepsilon_0}\$ or centered display math:

\$\$
f(x) = \\int_{-\\infty}^{\\infty} \\hat{f}(\\xi)\\, e^{2\\pi i \\xi x}\\, d\\xi
\$\$

```dart
// Syntax-highlighted code blocks include a one-tap Copy action
Future<void> captureThought(String title) async {
  await workspace.createNote(title: title, isInbox: true);
}
```

## 5. Diagrams, Live Boards & Sub-Notes

Write flowcharts, sequences, timelines, or pie charts directly in `mermaid`—zoom interactively or tap **Open in Whiteboard**:

```mermaid
flowchart LR
  A(["Capture"]) --> B{"Format?"}
  B -->|Words| C["Markdown Note"]
  B -->|Spatial| D["Flowchart Board"]
  C -.-> E[/"Graph & Today"/]
  D ==> E
```

Embed boards inside notes, jump via [[Capture to Clarity]], or branch sub-notes from **⋯ → Add Sub-note**:

![[Capture to Clarity]]

---

## Gallery & Export

![Floating cloud meadows — private space to think offline](assets/images/onboarding/floating_cloud_meadows.jpg)

Inline thumbnails fit right beside text too ![Local sanctuary badge](assets/images/onboarding/slide4_local_sanctuary.jpg) and zoom cleanly in the same Hero viewer. Ready to share? Open **⋯ → Export PDF** or **Save as Image**.

#guide #showcase #workflow

[^1]: Footnotes automatically collect at the bottom of your note with clickable reference badges.''';

    return TextNote(
      id: welcomeNoteId,
      title: 'Tack Complete Guide',
      content: content,
      createdAt: now.subtract(const Duration(minutes: 5)),
      updatedAt: now.subtract(const Duration(minutes: 5)),
      paletteId: 'amber',
      isFavorite: true,
      tags: const ['guide', 'showcase', 'workflow'],
      links: const ['Capture to Clarity'],
      estimatedMinutes: 3,
    );
  }

  static WhiteboardCanvasItem buildStarterBoard(DateTime now) {
    return WhiteboardCanvasItem(
      id: starterBoardId,
      title: 'Capture to Clarity',
      createdAt: now.subtract(const Duration(hours: 1)),
      updatedAt: now.subtract(const Duration(hours: 1)),
      paletteId: 'cyan',
      isFavorite: true,
      nodes: const [
        CanvasNode(
          id: 'wb_header',
          text: 'TACK WORKFLOW · IDEA TO CLARITY',
          shapeType: CanvasNodeType.textOnly,
          x: 2850,
          y: 2635,
          width: 300,
          height: 34,
          paletteId: 'slate',
        ),
        CanvasNode(
          id: 'wb_start',
          text: 'Spark an Idea\nTap (+)',
          shapeType: CanvasNodeType.startEnd,
          x: 2910,
          y: 2690,
          width: 180,
          height: 54,
          paletteId: 'coral',
        ),
        CanvasNode(
          id: 'wb_capture',
          text: 'Quick Capture\nInbox or Share Menu',
          shapeType: CanvasNodeType.inputOutput,
          x: 2895,
          y: 2795,
          width: 210,
          height: 64,
          paletteId: 'amber',
        ),
        CanvasNode(
          id: 'wb_decision',
          text: 'Spatial Flow\nor Structured Text?',
          shapeType: CanvasNodeType.decision,
          x: 2902,
          y: 2910,
          width: 196,
          height: 96,
          paletteId: 'lavender',
        ),
        CanvasNode(
          id: 'wb_note_proc',
          text: 'Markdown Note\nTables · Math · Code',
          shapeType: CanvasNodeType.process,
          x: 2675,
          y: 3060,
          width: 190,
          height: 70,
          paletteId: 'lime',
        ),
        CanvasNode(
          id: 'wb_board_proc',
          text: 'Whiteboard Flow\nShapes · Pan · Export',
          shapeType: CanvasNodeType.process,
          x: 3135,
          y: 3060,
          width: 190,
          height: 70,
          paletteId: 'cyan',
        ),
        CanvasNode(
          id: 'wb_hub',
          text: 'Sync',
          shapeType: CanvasNodeType.connector,
          x: 2972,
          y: 3184,
          width: 56,
          height: 56,
          paletteId: 'peach',
        ),
        CanvasNode(
          id: 'wb_sticky',
          text: 'Board Pro Tips:\n• Double-tap to edit\n• Tap node for + branch\n• Pan/Zoom & Export',
          shapeType: CanvasNodeType.sticky,
          x: 2635,
          y: 3265,
          width: 196,
          height: 124,
          paletteId: 'rose',
        ),
        CanvasNode(
          id: 'wb_spec',
          text: 'Tack Complete Guide\nOpen live spec & checklist',
          shapeType: CanvasNodeType.specCard,
          x: 2888,
          y: 3290,
          width: 224,
          height: 120,
          paletteId: 'amber',
          linkedNoteId: welcomeNoteId,
        ),
        CanvasNode(
          id: 'wb_image',
          text: 'Connected Ideas',
          shapeType: CanvasNodeType.image,
          x: 3175,
          y: 3245,
          width: 175,
          height: 175,
          paletteId: 'lavender',
          imagePath: 'assets/images/onboarding/slide3_connected_ideas.jpg',
        ),
        CanvasNode(
          id: 'wb_done',
          text: 'Ready in Today\nOffline & Yours',
          shapeType: CanvasNodeType.startEnd,
          x: 2905,
          y: 3465,
          width: 190,
          height: 52,
          paletteId: 'lime',
        ),
      ],
      edges: const [
        CanvasEdge(
          id: 'e_start_cap',
          fromNodeId: 'wb_start',
          toNodeId: 'wb_capture',
          fromPort: 'bottom',
          toPort: 'top',
        ),
        CanvasEdge(
          id: 'e_cap_dec',
          fromNodeId: 'wb_capture',
          toNodeId: 'wb_decision',
          fromPort: 'bottom',
          toPort: 'top',
        ),
        CanvasEdge(
          id: 'e_dec_note',
          fromNodeId: 'wb_decision',
          toNodeId: 'wb_note_proc',
          label: 'Linear',
          fromPort: 'left',
          toPort: 'top',
        ),
        CanvasEdge(
          id: 'e_dec_board',
          fromNodeId: 'wb_decision',
          toNodeId: 'wb_board_proc',
          label: 'Visual',
          fromPort: 'right',
          toPort: 'top',
        ),
        CanvasEdge(
          id: 'e_note_hub',
          fromNodeId: 'wb_note_proc',
          toNodeId: 'wb_hub',
          fromPort: 'bottom',
          toPort: 'left',
        ),
        CanvasEdge(
          id: 'e_board_hub',
          fromNodeId: 'wb_board_proc',
          toNodeId: 'wb_hub',
          fromPort: 'bottom',
          toPort: 'right',
        ),
        CanvasEdge(
          id: 'e_hub_spec',
          fromNodeId: 'wb_hub',
          toNodeId: 'wb_spec',
          label: 'Live Spec',
          fromPort: 'bottom',
          toPort: 'top',
        ),
        CanvasEdge(
          id: 'e_spec_img',
          fromNodeId: 'wb_spec',
          toNodeId: 'wb_image',
          label: 'Graph',
          fromPort: 'right',
          toPort: 'left',
        ),
        CanvasEdge(
          id: 'e_spec_done',
          fromNodeId: 'wb_spec',
          toNodeId: 'wb_done',
          fromPort: 'bottom',
          toPort: 'top',
        ),
      ],
    );
  }

  /// Upgrades an unmodified legacy starter note/board from v1 to the
  /// comprehensive v2 showcase, leaving user-edited or trashed items untouched.
  static BaseWorkspaceItem? tryUpgradeLegacyStarter(
    BaseWorkspaceItem item,
    DateTime now,
  ) {
    if (item.isTrash) return null;
    if (item.id == welcomeNoteId && item is TextNote) {
      final isUnmodifiedLegacy = item.content.contains('# Tack in 30 seconds') &&
          !item.content.contains('assets/images/onboarding/');
      if (isUnmodifiedLegacy) {
        return buildStarterNote(now);
      }
    } else if (item.id == starterBoardId && item is WhiteboardCanvasItem) {
      final isUnmodifiedLegacy = item.nodes.length == 5 &&
          item.nodes.any((n) => n.id == 'n_idea') &&
          !item.nodes.any((n) => n.id == 'wb_start');
      if (isUnmodifiedLegacy) {
        return buildStarterBoard(now);
      }
    }
    return null;
  }

  static List<BaseWorkspaceItem> getInitialItems() {
    final now = DateTime.now();
    return [
      buildStarterNote(now),
      buildStarterBoard(now),
    ];
  }
}
