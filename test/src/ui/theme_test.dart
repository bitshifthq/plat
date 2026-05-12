import 'package:flutter/material.dart' show ThemeData;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plat/plat.dart';

import 'ui_test_helpers.dart';

void main() {
  group('PlatTheme', () {
    group('PlatThemeData', () {
      test('copyWith updates provided fields and keeps the rest', () {
        const base = PlatThemeData();

        final updated = base.copyWith(
          tabBar: const PlatTabBarTheme(size: 48, fit: .expand),
        );

        expect(updated.tabBar.size, 48);
        expect(updated.tabBar.fit, TabStripFit.expand);
        expect(updated.divider, base.divider);
        expect(updated.dropHint, base.dropHint);
      });

      test('lerp interpolates scalar theme fields', () {
        final lerped = const PlatThemeData(tabBar: PlatTabBarTheme(spacing: 2))
            .lerp(
              const PlatThemeData(
                tabBar: PlatTabBarTheme(size: 48, spacing: 6, fit: .expand),
                divider: PlatDividerTheme(thickness: 5, hitSlop: 12),
              ),
              0.5,
            );

        expect(lerped.tabBar.size, 40);
        expect(lerped.tabBar.spacing, 4);
        expect(lerped.tabBar.fit, TabStripFit.expand);
        expect(lerped.divider.thickness, 3);
        expect(lerped.divider.hitSlop, 8);
      });
    });

    group('PlatTabBarTheme', () {
      test('chip background and foreground resolvers fire per state', () {
        const normalBg = Color(0xFFAAAAAA);
        const hoveredBg = Color(0xFFBBBBBB);
        const normalFg = Color(0xFF222222);
        const hoveredFg = Color(0xFF333333);

        final theme = PlatTabBarTheme(
          chipBackgroundColor: WidgetStateProperty.resolveWith<Color?>(
            (states) =>
                states.contains(WidgetState.hovered) ? hoveredBg : normalBg,
          ),
          chipForegroundColor: WidgetStateProperty.resolveWith<Color?>(
            (states) =>
                states.contains(WidgetState.hovered) ? hoveredFg : normalFg,
          ),
        );

        expect(theme.chipBackgroundColor!.resolve(const {}), normalBg);
        expect(
          theme.chipBackgroundColor!.resolve(const {WidgetState.hovered}),
          hoveredBg,
        );
        expect(theme.chipForegroundColor!.resolve(const {}), normalFg);
        expect(
          theme.chipForegroundColor!.resolve(const {WidgetState.hovered}),
          hoveredFg,
        );
      });

      test('lerp interpolates state-driven color properties per state', () {
        const aNormalBg = Color(0xFF000000);
        const aHoveredBg = Color(0xFF222222);
        const bNormalBg = Color(0xFF888888);
        const bHoveredBg = Color(0xFFFFFFFF);
        const aNormalFg = Color(0xFF101010);
        const aHoveredFg = Color(0xFF303030);
        const bNormalFg = Color(0xFF909090);
        const bHoveredFg = Color(0xFFE0E0E0);

        final aBg = WidgetStateProperty.resolveWith<Color?>(
          (states) =>
              states.contains(WidgetState.hovered) ? aHoveredBg : aNormalBg,
        );
        final bBg = WidgetStateProperty.resolveWith<Color?>(
          (states) =>
              states.contains(WidgetState.hovered) ? bHoveredBg : bNormalBg,
        );
        final aFg = WidgetStateProperty.resolveWith<Color?>(
          (states) =>
              states.contains(WidgetState.hovered) ? aHoveredFg : aNormalFg,
        );
        final bFg = WidgetStateProperty.resolveWith<Color?>(
          (states) =>
              states.contains(WidgetState.hovered) ? bHoveredFg : bNormalFg,
        );

        final a = PlatTabBarTheme(
          chipBackgroundColor: aBg,
          chipForegroundColor: aFg,
        );
        final b = PlatTabBarTheme(
          chipBackgroundColor: bBg,
          chipForegroundColor: bFg,
        );

        final mid = PlatTabBarTheme.lerp(a, b, 0.25);
        expect(
          mid.chipBackgroundColor!.resolve(const {}),
          Color.lerp(aNormalBg, bNormalBg, 0.25),
        );
        expect(
          mid.chipBackgroundColor!.resolve(const {WidgetState.hovered}),
          Color.lerp(aHoveredBg, bHoveredBg, 0.25),
        );
        expect(
          mid.chipForegroundColor!.resolve(const {}),
          Color.lerp(aNormalFg, bNormalFg, 0.25),
        );
        expect(
          mid.chipForegroundColor!.resolve(const {WidgetState.hovered}),
          Color.lerp(aHoveredFg, bHoveredFg, 0.25),
        );
      });
    });

    group('PlatDropHintTheme', () {
      test(
        'copyWith updates duration, edgeFraction, and transitionBuilder',
        () {
          Widget builder(Widget child, Animation<double> anim) => child;
          const base = PlatDropHintTheme();
          final updated = base.copyWith(
            duration: const Duration(milliseconds: 240),
            edgeFraction: 0.4,
            transitionBuilder: builder,
          );
          expect(updated.duration, const Duration(milliseconds: 240));
          expect(updated.edgeFraction, 0.4);
          expect(updated.transitionBuilder, same(builder));
        },
      );

      test(
        'lerp interpolates edgeFraction and pivots discrete fields at 0.5',
        () {
          Widget builderA(Widget child, Animation<double> anim) => child;
          Widget builderB(Widget child, Animation<double> anim) => child;
          final a = PlatDropHintTheme(
            duration: const Duration(milliseconds: 80),
            edgeFraction: 0.2,
            transitionBuilder: builderA,
          );
          final b = PlatDropHintTheme(
            duration: const Duration(milliseconds: 160),
            edgeFraction: 0.6,
            transitionBuilder: builderB,
          );
          final mid = PlatDropHintTheme.lerp(a, b, 0.5);
          expect(mid.edgeFraction, closeTo(0.4, 0.001));
          expect(mid.duration, const Duration(milliseconds: 160));
          expect(mid.transitionBuilder, same(builderB));

          final low = PlatDropHintTheme.lerp(a, b, 0.4);
          expect(low.duration, const Duration(milliseconds: 80));
          expect(low.transitionBuilder, same(builderA));
        },
      );
    });

    group('PlatTheme', () {
      testWidgets('of falls back to the default theme without an ancestor', (
        tester,
      ) async {
        late PlatThemeData resolved;

        await tester.pumpWidget(
          testHost(
            Builder(
              builder: (context) {
                resolved = PlatTheme.of(context);
                return const SizedBox();
              },
            ),
            overlay: false,
          ),
        );

        expect(resolved, const PlatThemeData());
      });

      testWidgets('of returns the nearest ancestor override', (tester) async {
        late PlatThemeData resolved;
        const theme = PlatThemeData(tabBar: PlatTabBarTheme(size: 44));

        await tester.pumpWidget(
          testHost(
            PlatTheme(
              data: theme,
              child: Builder(
                builder: (context) {
                  resolved = PlatTheme.of(context);
                  return const SizedBox();
                },
              ),
            ),
            overlay: false,
          ),
        );

        expect(resolved.tabBar.size, 44);
      });

      testWidgets('of falls back to ThemeData extension when present', (
        tester,
      ) async {
        late PlatThemeData resolved;
        const theme = PlatThemeData(tabBar: PlatTabBarTheme(size: 52));

        await tester.pumpWidget(
          testHost(
            Builder(
              builder: (context) {
                resolved = PlatTheme.of(context);
                return const SizedBox();
              },
            ),
            theme: ThemeData(extensions: const [theme]),
            overlay: false,
          ),
        );

        expect(resolved.tabBar.size, 52);
      });
    });
  });
}
