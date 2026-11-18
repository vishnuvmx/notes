import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes/core/routing/app_router.dart';
import 'package:notes/core/services/onboarding_service.dart';
import 'package:notes/core/theme/app_spacing.dart';
import 'package:notes/core/theme/app_theme.dart';
import 'package:notes/core/theme/theme_provider.dart';
import 'package:notes/features/home/screens/home_screen.dart';
import 'package:notes/features/onboarding/screens/onboarding_screen.dart';
import 'package:notes/shared/data/i_workspace_repo.dart';
import 'package:notes/shared/models/base_item.dart';
import 'package:notes/shared/providers/workspace_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _EmptyMockRepo extends IWorkspaceRepository {
  @override
  List<BaseWorkspaceItem> get cachedActiveItems => const [];

  @override
  Future<List<BaseWorkspaceItem>> getAllActiveItems() async => const [];

  @override
  Future<List<BaseWorkspaceItem>> getArchivedItems() async => const [];

  @override
  Future<List<BaseWorkspaceItem>> getFavoriteItems() async => const [];

  @override
  Future<BaseWorkspaceItem?> getItemById(String id) async => null;

  @override
  Future<List<BaseWorkspaceItem>> getItemsByType(ItemType? type) async =>
      const [];

  @override
  Future<List<BaseWorkspaceItem>> getTrashItems() async => const [];

  @override
  Future<void> moveToTrash(String id) async {}

  @override
  Future<void> restoreItem(String id) async {}

  @override
  Future<void> toggleArchive(String id) async {}

  @override
  Future<void> toggleFavorite(String id) async {}

  @override
  Future<void> deletePermanently(String id) async {}

  @override
  Future<void> emptyTrash() async {}

  @override
  Future<void> saveItem(BaseWorkspaceItem item) async {}

  @override
  Future<List<BaseWorkspaceItem>> searchItems(
    String query, {
    ItemType? type,
  }) async =>
      const [];
}

Widget _wrapRoot({
  required bool initialShowOnboarding,
  ThemeData? theme,
  MediaQueryData? mediaQuery,
}) {
  final workspace = WorkspaceProvider(_EmptyMockRepo());
  final themeProv = ThemeProvider();
  Widget app = MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: workspace),
      ChangeNotifierProvider.value(value: themeProv),
    ],
    child: MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      home: TackRootNavigator(
        initialShowOnboarding: initialShowOnboarding,
      ),
    ),
  );
  if (mediaQuery != null) {
    app = MediaQuery(data: mediaQuery, child: app);
  }
  return app;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('OnboardingService persistence', () {
    test('defaults to uncompleted on fresh install and persists markCompleted', () async {
      expect(await OnboardingService.shouldShowOnboarding(), isTrue);
      expect(await OnboardingService.hasCompleted(), isFalse);

      await OnboardingService.markCompleted();
      expect(await OnboardingService.hasCompleted(), isTrue);
      expect(await OnboardingService.shouldShowOnboarding(), isFalse);

      await OnboardingService.reset();
      expect(await OnboardingService.shouldShowOnboarding(), isTrue);
    });
  });

  group('OnboardingScreen flow & responsiveness', () {
    testWidgets(
      'first launch walks through all 4 slides (including floating_cloud_meadows.jpg), hides Skip on final slide, and enters HomeScreen',
      (tester) async {
        await tester.pumpWidget(_wrapRoot(initialShowOnboarding: true));
        await tester.pumpAndSettle();

        expect(find.byType(OnboardingScreen), findsOneWidget);
        expect(find.byType(HomeScreen), findsNothing);
        expect(find.text('Notes & stickies,\nwith a tactile twist'), findsOneWidget);
        expect(find.text('Skip'), findsOneWidget);

        // Verify touch targets >= 48dp
        final skipSize = tester.getSize(find.byKey(const ValueKey('onboarding_skip')));
        expect(skipSize.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
        final ctaSize = tester.getSize(find.byKey(const ValueKey('onboarding_primary_cta')));
        expect(ctaSize.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));

        // Slide 1 -> Slide 2 (uses floating_cloud_meadows.jpg hero)
        await tester.tap(find.byKey(const ValueKey('onboarding_primary_cta')));
        await tester.pumpAndSettle();
        expect(find.text('All your ideas,\nweightlessly organized'), findsOneWidget);
        final cloudImageFinder = find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName ==
                  OnboardingScreen.cloudMeadowsAsset,
        );
        expect(cloudImageFinder, findsOneWidget);

        // Slide 2 -> Slide 3
        await tester.tap(find.byKey(const ValueKey('onboarding_primary_cta')));
        await tester.pumpAndSettle();
        expect(find.text('#Tags and\n[[WikiLinks]]'), findsOneWidget);

        // Slide 3 -> Slide 4: Skip vanishes (no redundant exits) and CTA reads Start Writing
        await tester.tap(find.byKey(const ValueKey('onboarding_primary_cta')));
        await tester.pumpAndSettle();
        expect(find.text('Everything in\nyour control'), findsOneWidget);
        expect(find.text('Skip'), findsNothing);
        expect(find.text('Start Writing'), findsOneWidget);

        // Complete onboarding -> persists pref and transitions into HomeScreen
        await tester.tap(find.byKey(const ValueKey('onboarding_primary_cta')));
        await tester.pumpAndSettle();

        expect(await OnboardingService.hasCompleted(), isTrue);
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(OnboardingScreen), findsNothing);
      },
    );

    testWidgets(
      'Skip exits onboarding immediately and returning launch opens HomeScreen directly',
      (tester) async {
        await tester.pumpWidget(_wrapRoot(initialShowOnboarding: true));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('onboarding_skip')));
        await tester.pumpAndSettle();
        expect(await OnboardingService.hasCompleted(), isTrue);
        expect(find.byType(HomeScreen), findsOneWidget);

        // Subsequent launch skips onboarding
        await tester.pumpWidget(_wrapRoot(initialShowOnboarding: false));
        await tester.pumpAndSettle();
        expect(find.byType(OnboardingScreen), findsNothing);
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );

    testWidgets(
      'renders cleanly in dark mode on compact 360x640 viewport at 1.25x text scale',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 640),
                textScaler: TextScaler.linear(1.25),
              ),
              child: OnboardingScreen(onCompleted: () {}),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        for (int i = 0; i < 3; i++) {
          await tester.tap(find.byKey(const ValueKey('onboarding_primary_cta')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      },
    );
  });
}
