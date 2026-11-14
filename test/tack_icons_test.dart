import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes/core/theme/app_theme.dart';
import 'package:notes/core/theme/tack_icons.dart';
import 'package:notes/features/notes/services/wiki_link_service.dart';
import 'package:notes/features/notes/widgets/editor_formatting_toolbar.dart';
import 'package:notes/features/notes/widgets/slash_command_sheet.dart';

void main() {
  const colorizedIcons = <TackSvgIcon>[
    TackIcons.palette,
    TackIcons.stickyNote,
    TackIcons.sticky,
    TackIcons.pin,
    TackIcons.sparkles,
    TackIcons.lightbulb,
    TackIcons.notification,
    TackIcons.folder,
    TackIcons.folderPlus,
    TackIcons.folderTree,
    TackIcons.photo,
    TackIcons.imageTool,
    TackIcons.camera,
    TackIcons.whiteboard,
    TackIcons.flow,
    TackIcons.workflow,
    TackIcons.graph,
    TackIcons.notes,
    TackIcons.clipboard,
    TackIcons.todayTasks,
  ];

  const sampleIcons = <TackSvgIcon>[
    TackIcons.home,
    TackIcons.plus,
    TackIcons.search,
    TackIcons.user,
    TackIcons.bold,
    TackIcons.italic,
    TackIcons.refresh,
    TackIcons.lock,
    TackIcons.flag,
    TackIcons.cursor,
    TackIcons.add,
    TackIcons.alert,
    TackIcons.crop,
    TackIcons.expandNavigation,
    TackIcons.grid,
    TackIcons.nestedList,
    TackIcons.paragraph,
    TackIcons.smile,
    TackIcons.textTool,
    TackIcons.visibility,
    ...colorizedIcons,
  ];

  group('TackIcons SVG Pack & Optical Sizing', () {
    test('all referenced dark and white SVG assets exist on disk', () {
      for (final icon in sampleIcons) {
        final darkFile = File('icons/dark-icons/${icon.name}.svg');
        final whiteFile = File('icons/white-icons/${icon.name}.svg');
        expect(
          darkFile.existsSync(),
          isTrue,
          reason: 'Missing dark SVG asset: ${darkFile.path}',
        );
        expect(
          whiteFile.existsSync(),
          isTrue,
          reason: 'Missing white SVG asset: ${whiteFile.path}',
        );
      }

      // Ensure every dark-icons/*.svg has a matching white-icons/*.svg.
      final darkFiles = Directory('icons/dark-icons')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.svg'))
          .toList();
      expect(darkFiles, isNotEmpty);
      for (final darkFile in darkFiles) {
        final name = darkFile.uri.pathSegments.last;
        expect(
          File('icons/white-icons/$name').existsSync(),
          isTrue,
          reason: 'Missing paired white SVG for $name',
        );
      }
    });

    testWidgets(
      'TackIcon keeps strict size x size layout box with opticalScale in light & dark mode',
      (tester) async {
        for (final brightness in [Brightness.light, Brightness.dark]) {
          final theme =
              brightness == Brightness.dark ? AppTheme.darkTheme : AppTheme.lightTheme;
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Scaffold(
                body: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final icon in sampleIcons)
                      TackIcon(icon, size: 20),
                  ],
                ),
              ),
            ),
          );
          await tester.pump();

          expect(tester.takeException(), isNull);
          expect(find.byType(SvgPicture), findsNWidgets(sampleIcons.length));

          final firstBox = tester.getSize(find.byType(TackIcon).first);
          expect(firstBox, const Size(20, 20));
        }
      },
    );

    testWidgets(
      'SlashCommandsCatalog and EditorFormattingToolbar render TackIcon SVGs without overflow',
      (tester) async {
        expect(
          SlashCommandsCatalog.all.every((item) => item.icon is TackSvgIcon),
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
      'Colorized TackIcons keep multi-color palette un-flattened across light, dark, and accent tints',
      (tester) async {
        for (final icon in colorizedIcons) {
          expect(
            icon.isSingleColor,
            isFalse,
            reason: '${icon.name} must stay multi-color (isSingleColor: false)',
          );
        }

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Row(
                children: const [
                  TackIcon(TackIcons.graph, color: Color(0xFF1BA5BA)),
                  TackIcon(TackIcons.notes, color: Color(0xFF191A23)),
                  TackIcon(TackIcons.sparkles, color: Colors.white),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        final svgs = tester.widgetList<SvgPicture>(find.byType(SvgPicture)).toList();
        expect(svgs.length, 3);
        // Mid-tone accent in dark mode follows theme -> white-icons;
        // explicit dark ink -> dark-icons; explicit white ink -> white-icons.
        expect((svgs[0].bytesLoader as SvgAssetLoader).assetName, 'icons/white-icons/graph.svg');
        expect((svgs[1].bytesLoader as SvgAssetLoader).assetName, 'icons/dark-icons/notes.svg');
        expect((svgs[2].bytesLoader as SvgAssetLoader).assetName, 'icons/white-icons/sparkles.svg');
        for (final svg in svgs) {
          expect(svg.colorFilter, isNull);
        }
      },
    );
  });
}
