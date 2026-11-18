import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes/core/theme/app_colors.dart';
import 'package:notes/core/theme/app_theme.dart';
import 'package:notes/core/theme/tack_icons.dart';
import 'package:notes/features/notes/services/wiki_link_service.dart';
import 'package:notes/features/notes/widgets/editor_formatting_toolbar.dart';
import 'package:notes/features/notes/widgets/slash_command_sheet.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

void main() {
  const filledCapableIcons = <TackGlyph>[
    TackIcons.home,
    TackIcons.today,
    TackIcons.library,
    TackIcons.boards,
    TackIcons.clipboard,
    TackIcons.star,
    TackIcons.pin,
    TackIcons.notification,
    TackIcons.folder,
    TackIcons.photo,
    TackIcons.sparkles,
    TackIcons.lightbulb,
    TackIcons.shield,
    TackIcons.lock,
  ];

  const sampleIcons = <TackGlyph>[
    TackIcons.plus,
    TackIcons.search,
    TackIcons.user,
    TackIcons.bold,
    TackIcons.italic,
    TackIcons.underline,
    TackIcons.strikethrough,
    TackIcons.code,
    TackIcons.heading1,
    TackIcons.heading2,
    TackIcons.heading3,
    TackIcons.refresh,
    TackIcons.flag,
    TackIcons.cursor,
    TackIcons.hand,
    TackIcons.move,
    TackIcons.crop,
    TackIcons.expandNavigation,
    TackIcons.grid,
    TackIcons.nestedList,
    TackIcons.paragraph,
    TackIcons.smile,
    TackIcons.textTool,
    TackIcons.visibility,
    TackIcons.workflow,
    TackIcons.graph,
    TackIcons.notes,
    TackIcons.sticky,
    TackIcons.todayTasks,
    TackIcons.command,
    TackIcons.sun,
    TackIcons.moon,
    TackIcons.chevronLeft,
    TackIcons.imageOff,
    TackIcons.externalLink,
    TackIcons.square,
    TackIcons.diamond,
    TackIcons.scan,
    TackIcons.arrowLeftRight,
    TackIcons.bolt,
    TackIcons.briefcase,
    ...filledCapableIcons,
  ];

  group('TackIcons Tabler Pack & Optical Sizing', () {
    test('all sampled TackIcons use Tabler font families with non-zero codepoints', () {
      const validFamilies = <String>{'tabler-icons', 'tabler-icons-filled'};
      for (final icon in sampleIcons) {
        expect(icon.outline.codePoint, isPositive);
        expect(icon.outline.fontPackage, 'tabler_icons_plus');
        expect(validFamilies.contains(icon.outline.fontFamily), isTrue);
      }

      // Filled-capable icons expose a distinct solid glyph in the filled family.
      for (final icon in filledCapableIcons) {
        expect(icon.solid, isNotNull);
        expect(icon.solid, isNot(equals(icon.outline)));
        expect(icon.solid!.fontPackage, 'tabler_icons_plus');
        expect(icon.solid!.fontFamily, 'tabler-icons-filled');
      }

      // Stroke-only glyphs like check/plus safely fall back to outline when solid is requested.
      expect(TackIcons.check.resolve(HeroIconStyle.solid), TablerIcons.check);
      expect(TackIcons.plus.resolve(HeroIconStyle.solid), TablerIcons.plus);
    });

    testWidgets(
      'TackIcon keeps strict size x size layout box in light & dark mode',
      (tester) async {
        for (final brightness in [Brightness.light, Brightness.dark]) {
          final theme = brightness == Brightness.dark
              ? AppTheme.darkTheme
              : AppTheme.lightTheme;
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Scaffold(
                body: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final icon in sampleIcons) TackIcon(icon, size: 20),
                  ],
                ),
              ),
            ),
          );
          await tester.pump();

          expect(tester.takeException(), isNull);
          expect(find.byType(Icon), findsNWidgets(sampleIcons.length));

          final firstBox = tester.getSize(find.byType(TackIcon).first);
          expect(firstBox, const Size(20, 20));
        }
      },
    );

    testWidgets(
      'TackIcon switches between Tabler outline and filled glyphs via HeroIconStyle',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  TackIcon(TackIcons.star, style: HeroIconStyle.outline),
                  TackIcon(TackIcons.star, style: HeroIconStyle.solid),
                  TackIcon(TackIcons.check, style: HeroIconStyle.solid),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
        expect(icons.length, 3);
        expect(icons[0].icon, TablerIcons.star);
        expect(icons[1].icon, TablerIcons.starFilled);
        expect(icons[2].icon, TablerIcons.check);
      },
    );

    testWidgets(
      'SlashCommandsCatalog and EditorFormattingToolbar render Tabler TackIcons without overflow',
      (tester) async {
        expect(
          SlashCommandsCatalog.all.every((item) => item.icon is TackGlyph),
          isTrue,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Column(
                children: [
                  const EditorFormattingToolbar(),
                  SlashCommandInlineBar(
                    trigger: const ActiveSlashTrigger(
                      slashOffset: 0,
                      cursorOffset: 1,
                      query: '',
                    ),
                    onSelectCommand: (_) {},
                    onOpenFullSheet: () {},
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'TackIcon applies explicit colors and theme defaults cleanly across light and dark modes',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: Row(
                children: [
                  TackIcon(TackIcons.graph, color: AppColors.pastelCyanLight),
                  TackIcon(TackIcons.notes),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        final darkIcons = tester.widgetList<Icon>(find.byType(Icon)).toList();
        expect(darkIcons[0].color, AppColors.pastelCyanLight);
        expect(darkIcons[1].color, AppColors.darkTextPrimary);
      },
    );
  });
}
