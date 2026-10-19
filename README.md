<div align="center">
  <img src="icon.png" width="96" height="96" alt="Tack Logo" />
  <h1>Tack</h1>
  <p><strong>Tactile Note-Taking, Flowchart Whiteboards, Sticky Notes & Clipboard Management for Android</strong></p>
  <p>Built with Flutter & Dart</p>

  [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
  [![Platform](https://img.shields.io/badge/Platform-Android-green.svg)](https://flutter.dev)
  [![Flutter](https://img.shields.io/badge/Flutter-%5E3.13.1-02569B.svg?logo=flutter)](https://flutter.dev)
</div>

---

## 📖 Overview

**Tack** is an open-source, mobile-first workspace application designed to unify everyday note-taking workflows into an ergonomic Android experience. It combines long-form Markdown notes, colorful tactile sticky notes, an infinite flowchart whiteboard canvas, and a clipboard snippet buffer into a single offline-first application.

All data is stored locally on the device using structured JSON serialization, with built-in export and import capabilities for manual backups.

---

## ✨ Features

### 📝 Rich Text & Markdown Notes
- Support for headings, bold, italic, strikethrough, blockquotes, and ordered/unordered lists.
- Interactive task checklists with tap-to-toggle completion.
- Fenced code blocks with multi-language syntax highlighting.
- Native rendering of Mermaid flowchart diagrams directly inside notes.
- Word count, character count, and estimated reading time calculation.
- Tagging and instant search filtering.

### 🎨 Tactile Sticky Notes
- Quick scratchpad interface designed for rapid capture.
- 8 curated stationery pastel colors with optimized light and dark mode contrast tokens.
- Tactile card layouts with subtle rotation angles, soft shadows, and micro-press feedback.
- Priority pins for highlighting essential reminders.

### 🗺️ Flowchart Whiteboard Canvas
- 6000×6000px virtual infinite canvas with smooth 2D pan and zoom gestures.
- Magnetic 20px snap-to-grid alignment for precise layout.
- Standard flowchart node shapes: **Start/End** (capsule), **Process** (rectangle), **Decision** (diamond), and **I/O** (parallelogram).
- Directional Bézier connectors with interactive edit, reverse, and delete context capsules.
- Live radar minimap for canvas spatial awareness.
- High-resolution document export to PNG image and multi-page vector PDF.

### 📋 Clipboard Management
- Temporal history buffer for frequently copied snippets.
- One-tap copy action to return text directly to the system clipboard.
- Pin state to preserve essential clips across sessions.

### 📱 Android System Integrations
- **Quick Actions App Widget**: Home screen widget for one-tap capture.
- **Quick Settings Tile**: Pull-down status bar tile service for rapid note creation.
- **Dynamic App Shortcuts**: Launcher long-press shortcuts pointing to recent and favorite notes.
- **Text Selection Action**: System-wide `ACTION_PROCESS_TEXT` ("Save to Tack") integration.

### 🔒 Local Persistence & Backup
- On-device local storage without external server requirements.
- Full workspace JSON backup export and restore workflows.
- Soft-delete Trash bin with individual item restoration or permanent emptying.

---

## 🎨 Design System

Tack uses a cohesive design token system:

| Token Category | Specification |
| :--- | :--- |
| **Typography** | `DM Sans` across all weights, with -2% letter spacing for modern geometric legibility. |
| **Surface Colors** | Light Surface: `#F8F9FA`, Light Card: `#FFFFFF`<br>Dark Surface: `#121316`, Dark Card: `#1E1F24` |
| **Pastel Palette** | 8 paired tones: *Sunset Peach*, *Warm Amber*, *Coral Blush*, *Lavender Mist*, *Cyan Breeze*, *Lime Zing*, *Rose Bubble*, and *Slate Pure*. |
| **Iconography** | Clean outline and solid iconography via `lucide_icons_flutter` and `heroicons`. |
| **Radii & Elevation** | 8dp (small), 16dp (cards/buttons), 24dp (sheets/dialogs), 999dp (pill). Soft diffused drop shadows. |
| **Touch Targets** | Ergonomic 48×48dp minimum interactive touch targets. |

---

## 🏗️ Architecture

The codebase follows clean, layered object-oriented principles:

```
lib/
├── core/         # Design tokens (colors, typography, spacing, icons) and utility helpers
├── domain/       # Polymorphic domain models, abstract repository contracts, and platform services
├── data/         # Repository implementations, storage drivers, and initial seed data
├── state/        # Reactive state providers (WorkspaceProvider, ThemeProvider)
└── ui/           # Reusable widgets, toolbars, dialogs, cards, and full screens
```

- **Domain Model Hierarchy**: All workspace elements (`TextNote`, `StickyNote`, `WhiteboardCanvasItem`, `ClipboardItem`) inherit from an abstract `BaseWorkspaceItem` base class.
- **Polymorphism**: Search, tagging, trash, archiving, and serialization operate polymorphically across all workspace item types.
- **Decoupled Repositories**: Data access is mediated through the `IWorkspaceRepository` contract, separating persistence mechanics from application state.

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version `^3.13.1` or newer)
- [Dart SDK](https://dart.dev/get-dart) (included with Flutter)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) with Flutter extension
- Android SDK with platform tools (API level 21+)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/vishnuvmx/notes.git
   cd notes
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify the environment**:
   ```bash
   flutter doctor
   ```

4. **Run on an Android device or emulator**:
   ```bash
   flutter run
   ```

### Building for Release

To build an optimized Android App Bundle (AAB) or APK:

```bash
# Build an APK
flutter build apk --release

# Build split APKs per ABI (ARM64, ARMv7, x86_64)
flutter build apk --split-per-abi --release

# Build an Android App Bundle
flutter build appbundle --release
```

---

## 📁 Repository Structure

```
.
├── .github/              # Issue and Pull Request templates
├── android/              # Native Android project, manifest, widgets, and services
│   └── app/src/main/     # Kotlin sources, resources, widget layouts, and shortcuts
├── icons/                # Vector SVG icon assets
├── lib/                  # Dart application sources
│   ├── core/             # Theme tokens, typography, colors, and math/date utilities
│   ├── data/             # Repository implementation and initial onboarding data
│   ├── domain/           # Models (BaseItem, TextNote, StickyNote, Whiteboard, Clipboard)
│   ├── state/            # Provider state management
│   └── ui/               # Screens (home, editor, whiteboard, settings) and components
├── web/                  # Web support configuration and assets
├── windows/              # Windows runner configuration
├── CONTRIBUTING.md       # Contribution guidelines and pull request instructions
├── LICENSE               # MIT open-source license
├── pubspec.yaml          # Project dependencies and configuration
└── README.md             # Repository documentation
```

---

## 🤝 Contributing

Community contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code style, issue reporting guidelines, and the pull request submission process.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
All third-party libraries and dependencies retain their respective open-source licenses (BSD, MIT, Apache-2.0, ISC).
