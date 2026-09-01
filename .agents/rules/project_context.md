# Rules & Permanent Project Memory: Tack Android-First Flutter App

**Tack** is an Android-first tactile note-taking, whiteboard flowchart, sticky notes, and clipboard manager app (brand icon: `icon.png`).

1. **Design System & Typography**:
   - Always use `DM Sans` with `-2%` letter spacing (`letterSpacing: -0.3` to `-0.6`).
   - Use `HeroIcons` (`heroicons` package via `TackIcon`) for soft, cute rounded aesthetics instead of generic Material icons.
   - Use the 8 curated sticky pastels with proper light and dark mode contrasts.
   - Maintain minimum 48x48 dp touch targets for all interactive elements.


2. **OOP Domain Principles**:
   - Model all workspace items (`TextNote`, `StickyNote`, `WhiteboardCanvasItem`, `ClipboardItem`) as subclasses of `BaseWorkspaceItem`.
   - Polymorphically handle search, sorting, filtering, and serialization.
   - Decouple domain from data and UI through interfaces (`IWorkspaceRepository`, `IStorageDriver`).

3. **Android UX & Ergonomics**:
   - Use bottom sheets, keyboard-docked toolbars, and gesture-aware canvas controls.
   - Ensure proper predictive back navigation and safe area handling.
