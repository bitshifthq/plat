import 'package:flutter/material.dart' show ColorScheme, ThemeData;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plat/plat.dart';

import 'ui_test_helpers.dart';

void main() {
  group('PlatDivider', () {
    testWidgets(
      'uses colorScheme.outlineVariant at rest and primary when hovered',
      (tester) async {
        const cs = ColorScheme.dark(
          outlineVariant: Color(0xFF3A3A3A),
          primary: Color(0xFF6BA1FF),
        );

        await tester.pumpWidget(
          _dividerHost(cs, const PlatDivider(states: <WidgetState>{})),
        );
        expect(
          tester.widget<ColoredBox>(find.byType(ColoredBox)).color,
          const Color(0xFF3A3A3A),
        );

        await tester.pumpWidget(
          _dividerHost(cs, const PlatDivider(states: {WidgetState.hovered})),
        );
        expect(
          tester.widget<ColoredBox>(find.byType(ColoredBox)).color,
          const Color(0xFF6BA1FF),
        );
      },
    );

    testWidgets('theme color resolver overrides the colorScheme fallback', (
      tester,
    ) async {
      const themed = Color(0xFFFFAA00);
      final theme = PlatThemeData(
        divider: PlatDividerTheme(
          color: WidgetStateProperty.resolveWith<Color?>((_) => themed),
        ),
      );

      await tester.pumpWidget(
        _dividerHost(
          const ColorScheme.dark(),
          PlatTheme(
            data: theme,
            child: const PlatDivider(states: <WidgetState>{}),
          ),
        ),
      );

      expect(tester.widget<ColoredBox>(find.byType(ColoredBox)).color, themed);
    });

    testWidgets('theme color resolver returning null falls back to default', (
      tester,
    ) async {
      const cs = ColorScheme.dark(outlineVariant: Color(0xFF3A3A3A));
      final theme = PlatThemeData(
        divider: PlatDividerTheme(
          color: WidgetStateProperty.resolveWith<Color?>((_) => null),
        ),
      );

      await tester.pumpWidget(
        _dividerHost(
          cs,
          PlatTheme(
            data: theme,
            child: const PlatDivider(states: <WidgetState>{}),
          ),
        ),
      );

      expect(
        tester.widget<ColoredBox>(find.byType(ColoredBox)).color,
        const Color(0xFF3A3A3A),
      );
    });

    testWidgets('theme decoration resolver wins over color', (tester) async {
      const decoration = BoxDecoration(color: Color(0xFFAA00FF));
      final theme = PlatThemeData(
        divider: PlatDividerTheme(
          decoration: WidgetStateProperty.resolveWith<Decoration?>(
            (_) => decoration,
          ),
          color: WidgetStateProperty.resolveWith<Color?>(
            (_) => const Color(0xFF00FF00),
          ),
        ),
      );

      await tester.pumpWidget(
        _dividerHost(
          const ColorScheme.dark(),
          PlatTheme(
            data: theme,
            child: const PlatDivider(states: <WidgetState>{}),
          ),
        ),
      );

      expect(find.byType(ColoredBox), findsNothing);
      expect(
        tester.widget<DecoratedBox>(find.byType(DecoratedBox)).decoration,
        decoration,
      );
    });
  });
}

Widget _dividerHost(ColorScheme colorScheme, Widget child) =>
    testHost(child, theme: ThemeData(colorScheme: colorScheme), overlay: false);
