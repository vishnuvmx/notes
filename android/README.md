# Tack Android Integration (`android/`)

This directory contains the native Android project wrapper, build configurations, and platform integration services for the **Tack** application.

---

## 📱 Android-Specific Features

### 1. Quick Actions App Widget
- **Class**: `TackQuickActionWidgetProvider.kt`
- **Configuration**: `res/xml/widget_quick_actions_info.xml`
- **Layout**: `res/layout/widget_quick_actions.xml`
- Provides a home screen widget allowing users to launch quick note creation directly without navigating through the full application hierarchy.

### 2. Quick Capture Status Bar Tile
- **Class**: `TackQuickCaptureTileService.kt`
- Registers a Quick Settings tile in the Android notification shade. Tapping the tile launches Tack into quick-capture mode.

### 3. Dynamic and Static Shortcuts
- **Static Shortcuts**: `res/xml/shortcuts.xml` declares launcher shortcuts for "New Note" and "New Board".
- **Dynamic Shortcuts**: Synchronized via `AndroidShortcutsService.kt` / `MainActivity.kt` using Android's `ShortcutManager` to show recently edited or starred notes when long-pressing the app launcher icon.

### 4. Text Selection Intent (`ACTION_PROCESS_TEXT`)
- `MainActivity.kt` registers an `intent-filter` for `android.intent.action.PROCESS_TEXT`.
- Allows users selecting text in any third-party Android application (e.g., browser, chat) to choose "Save to Tack" directly from the system text selection toolbar.

---

## ⚙️ Build Configuration

- **Application ID / Namespace**: `com.notes.tacknotes`
- **Gradle Plugins**: Kotlin DSL (`build.gradle.kts`)
- **Compatibility**:
  - `minSdk`: Flutter minimum SDK (API level 21+)
  - `targetSdk`: Flutter target SDK
  - `compileSdk`: Flutter compile SDK
  - Java Version: `JavaVersion.VERSION_17`
  - Kotlin JVM Target: `17`

---

## 📦 Building Android Artifacts

From the root project directory:

```bash
# Debug APK
flutter run -d android

# Release APK
flutter build apk --release

# Split APKs (smaller file size per target architecture: arm64-v8a, armeabi-v7a, x86_64)
flutter build apk --split-per-abi --release

# Android App Bundle for Google Play distribution
flutter build appbundle --release
```

---

## 🔒 Permissions & Privacy

Tack requires standard platform capabilities for its functionality:
- File storage access via `path_provider` for saving local JSON databases and exported PDF/PNG documents.
- Camera and gallery access via `image_picker` for attaching images to whiteboard nodes.
- No network permissions are required for note persistence; data remains local to the device.
