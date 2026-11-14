import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:notes/core/theme/app_colors.dart';
import 'package:notes/features/notes/services/latex_math_service.dart';
import 'package:notes/features/notes/widgets/markdown_math_view.dart';
import 'package:notes/features/notes/widgets/rich_note_content_view.dart';

Widget _wrapPreview({
  required String markdown,
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
}) {
  final isDark = brightness == Brightness.dark;
  return MaterialApp(
    theme: ThemeData(
      brightness: brightness,
      extensions: [isDark ? TackTokens.dark : TackTokens.light],
    ),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: RichNoteContentView(
            content: markdown,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('LatexMathService — inline & block detection', () {
    test('matches valid inline equations and skips currency/escapes', () {
      const sample =
          r'Energy $E = mc^2$, indexed $a_1 + b^2$, price $5 and $10, plus $x^2$, escaped \$x\$.';
      final firstStart = sample.indexOf(r'$E');
      final m1 = LatexMathService.tryMatchInlineMath(sample, firstStart);
      expect(m1, isNotNull);
      expect(m1!.expression, 'E = mc^2');
      expect(m1.isDisplay, isFalse);

      final secondStart = sample.indexOf(r'$a_1');
      final m2 = LatexMathService.tryMatchInlineMath(sample, secondStart);
      expect(m2, isNotNull);
      expect(m2!.expression, 'a_1 + b^2');

      final currencyStart = sample.indexOf(r'$5');
      expect(LatexMathService.tryMatchInlineMath(sample, currencyStart), isNull);

      final secondCurrencyStart = sample.indexOf(r'$10');
      expect(
        LatexMathService.tryMatchInlineMath(sample, secondCurrencyStart),
        isNull,
      );

      final trailingMathStart = sample.indexOf(r'$x^2');
      final m3 = LatexMathService.tryMatchInlineMath(sample, trailingMathStart);
      expect(m3, isNotNull);
      expect(m3!.expression, 'x^2');

      final escapedStart = sample.indexOf(r'$x\$');
      expect(LatexMathService.tryMatchInlineMath(sample, escapedStart), isNull);

      expect(
        LatexMathService.tryMatchInlineMath(r'Cost ($10/$20)', 6),
        isNull,
      );
      expect(
        LatexMathService.tryMatchInlineMath(r'$ x + y $', 0),
        isNull,
      );
    });

    test(r'consumes single-line and multi-line $$...$$ blocks cleanly', () {
      final single = [r'$$ \frac{-b \pm \sqrt{b^2 - 4ac}}{2a} $$'];
      final b1 = LatexMathService.tryConsumeBlockMath(single, 0);
      expect(b1, isNotNull);
      expect(b1!.expression, r'\frac{-b \pm \sqrt{b^2 - 4ac}}{2a}');
      expect(b1.nextLineIndex, 1);

      final multi = [
        r'$$',
        r'\int_0^1 x^2 \, dx = \frac{1}{3}',
        r'$$',
        'After block',
      ];
      final b2 = LatexMathService.tryConsumeBlockMath(multi, 0);
      expect(b2, isNotNull);
      expect(b2!.expression, r'\int_0^1 x^2 \, dx = \frac{1}{3}');
      expect(b2.nextLineIndex, 3);

      final unclosed = [r'$$', r'a + b'];
      expect(LatexMathService.tryConsumeBlockMath(unclosed, 0), isNull);
    });
  });

  group('Markdown Math Preview Rendering', () {
    testWidgets('renders inline and block LaTeX inside RichNoteContentView',
        (tester) async {
      const md = '''
Pythagorean theorem: \$a^2 + b^2 = c^2\$, bold **\$E = mc^2\$**, and price \$5 to \$10.

\$\$
\\frac{1}{n} \\sum_{i=1}^{n} x_i
\$\$

- Checklist formula \$x_1 * y_1\$
- Code stays literal: `\$not_math\$`
''';

      await tester.pumpWidget(_wrapPreview(markdown: md));
      await tester.pumpAndSettle();

      expect(find.byType(InlineMathView), findsNWidgets(3));
      expect(find.byType(BlockMathView), findsOneWidget);
      expect(find.byType(Math), findsNWidgets(4));
      expect(find.textContaining(r'$not_math$'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not parse \$\$...\$\$ inside fenced code blocks',
        (tester) async {
      const md = '''
```latex
\$\$
E = mc^2
\$\$
```
''';
      await tester.pumpWidget(_wrapPreview(markdown: md));
      await tester.pumpAndSettle();

      expect(find.byType(BlockMathView), findsNothing);
      expect(find.byType(Math), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('falls back gracefully to raw text for invalid LaTeX',
        (tester) async {
      const md = r'''
Broken inline $\frac{1$ in prose.

$$
\definitelyNotACommand{abc}
$$
''';

      await tester.pumpWidget(_wrapPreview(markdown: md));
      await tester.pumpAndSettle();

      expect(find.byType(InlineMathView), findsOneWidget);
      expect(find.byType(BlockMathView), findsOneWidget);
      expect(find.text(r'$\frac{1$'), findsOneWidget);
      expect(
        find.textContaining(r'\definitelyNotACommand{abc}'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('matches dark/light theme colors and respects text scaling',
        (tester) async {
      const md = '''
Inline \$x^2 + 1\$

\$\$
\\alpha + \\beta = \\gamma
\$\$
''';

      // Dark mode + 1.5x text scale
      await tester.pumpWidget(
        _wrapPreview(
          markdown: md,
          brightness: Brightness.dark,
          textScale: 1.5,
        ),
      );
      await tester.pumpAndSettle();

      final mathWidgets =
          tester.widgetList<Math>(find.byType(Math)).toList(growable: false);
      expect(mathWidgets, hasLength(2));
      for (final m in mathWidgets) {
        expect(m.textScaleFactor, closeTo(1.5, 0.01));
        expect(m.textStyle?.color, AppColors.darkTextPrimary);
      }

      // Light mode + 1.0x text scale
      await tester.pumpWidget(
        _wrapPreview(
          markdown: md,
          brightness: Brightness.light,
          textScale: 1.0,
        ),
      );
      await tester.pumpAndSettle();

      final lightMathWidgets =
          tester.widgetList<Math>(find.byType(Math)).toList(growable: false);
      expect(lightMathWidgets, hasLength(2));
      for (final m in lightMathWidgets) {
        expect(m.textScaleFactor, closeTo(1.0, 0.01));
        expect(m.textStyle?.color, AppColors.lightTextPrimary);
      }
      expect(tester.takeException(), isNull);
    });
  });
}
