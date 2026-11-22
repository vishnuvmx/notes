# Previous Iteration State (Historical Context Only)

> **Last Updated**: 2026-11-22 09:54:48 · **Model**: gemini-4-neon-high
> **AI AGENTS**: This records what happened in the PREVIOUS session. DO NOT execute these files or next steps unless the user explicitly asks to continue that specific work. Always prioritize the user's current prompt.

## Previous Progress
[gemini-4-neon-high] Chat: "app closes when app opens." — Fixed the crash on launch and rebuilt all three split-per-ABI release APKs:

## Active Working Files & Symbol Map (Skip File Discovery)
- `android/app/src/main/kotlin/com/notes/tacknotes/MainActivity.kt` (907 lines): `MainActivity` (:30), `showQuickCaptureNotificationOn` (:39), `showFallbackStatusNotification` (:97), `getRenderMode` (:158), `onFlutterUiDisplayed` (:162), `onCreate` (:167), `attachSplashOverlayUntilFirstFrame` (:181), `removeSplashOverlay` (:205), `enableHighRefreshRate` (:211), `onNewIntent` (:234), `configureFlutterEngine` (:240), `onDestroy` (:367)
- `lib/core/theme/app_colors.dart` (719 lines): `AppColors` (:10), `normalizePaletteId` (:335), `getPaletteById` (:347), `getPaletteByColor` (:358), `getHighlightColor` (:369), `tryParseHexColor` (:377), `TackColorPalette` (:400), `resolveFill` (:420), `resolveBandColor` (:423), `resolveCardColor` (:426), `resolveSoftBackground` (:428), `resolveTextColor` (:430)
- `lib/core/theme/theme_provider.dart` (76 lines): `ThemeProvider` (:6), `isDarkMode` (:20), `loadSavedThemeMode` (:27), `_loadPersistedTheme` (:38), `setThemeMode` (:54), `toggleTheme` (:68)
- `lib/features/home/screens/home_screen.dart` (785 lines): `HomeScreen` (:35), `createState` (:53), `_HomeScreenState` (:56), `_openItem` (:60), `_openCaptureSheet` (:68), `_handleBottomNavTap` (:78), `_titleForTab` (:91), `_subtitleForTab` (:106), `_showSortSheet` (:119), `build` (:206), `_stackIndexForTab` (:331), `_LibraryView` (:347)
- `lib/features/tasks/screens/today_screen.dart` (1273 lines): `TodayScreen` (:37), `createState` (:44), `_TodayScreenState` (:47), `build` (:76), `_TodaysDailyNoteCard` (:376), `build` (:392), `buildDailyBody` (:398), `_SegmentedTasksCard` (:540), `build` (:570), `_TaskRow` (:870), `build` (:884), `_WorthRevisitingCard` (:1085)
- `lib/main.dart` (139 lines): `main` (:16), `TackApp` (:64), `build` (:70), `_TackScrollBehavior` (:125), `getScrollPhysics` (:129)
- `lib/shared/providers/workspace_provider.dart` (1249 lines): `WorkspaceProvider` (:25), `_nextId` (:39), `_invalidateDerivedCaches` (:83), `notifyListeners` (:105), `_applyPrefsSync` (:137), `_mergeFoldersFromItems` (:151), `_loadPrefsAndItems` (:163), `getItemById` (:184), `restoreItem` (:186), `_sortItemsList` (:390), `resolveEffectiveFolder` (:409), `getChildItems` (:428)
- `lib/shared/widgets/smart_bottom_nav_bar.dart` (611 lines): `SmartBottomNavBar` (:19), `build` (:34), `_LiquidGlassDock` (:93), `createState` (:111), `_LiquidGlassDockState` (:114), `initState` (:129), `didUpdateWidget` (:139), `_springToSlot` (:148), `_handleDragUpdate` (:167), `_handleDragEnd` (:188), `dispose` (:204), `build` (:210)

## Files Modified in Previous Task
- `android/app/src/main/kotlin/com/notes/tacknotes/MainActivity.kt`
- `android/app/src/main/res/drawable-v21/launch_background.xml`
- `android/app/src/main/res/drawable/launch_background.xml`
- `lib/core/theme/app_colors.dart`
- `lib/core/theme/theme_provider.dart`
- `lib/features/home/screens/home_screen.dart`
- `lib/features/tasks/screens/today_screen.dart`
- `lib/main.dart`
- `lib/shared/providers/workspace_provider.dart`
- `lib/shared/widgets/smart_bottom_nav_bar.dart`
- `lib/shared/widgets/tack_card_open_container.dart`
- `pubspec.lock`
- `pubspec.yaml`
- `android/app/src/main/res/drawable-night-v21/launch_background.xml`
- `android/app/src/main/res/values-night-v31/styles.xml`
- `android/app/src/main/res/values-v31/styles.xml`

## Files Discussed / Referenced in Chat
- `assets/images/onboarding/slide3_connected_ideas.jpg`
- `package.json`
- `test/task_reminders_test.dart`
