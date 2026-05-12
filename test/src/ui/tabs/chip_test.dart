import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart'
    show ColorScheme, Icons, MaterialApp, TabBarThemeData, ThemeData;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plat/plat.dart';

import '../../../helpers.dart';
import '../ui_test_helpers.dart';

void main() {
  group('PlatTabChip', () {
    group('default tab fallback', () {
      testWidgets('falls back to the tab id when title is empty', (
        tester,
      ) async {
        final controller = controllerFromLeaves([const LeafNode(id: 'a')]);
        addTearDown(controller.dispose);

        await pumpPlatView(tester, controller);

        expect(find.text('a'), findsOneWidget);
      });

      testWidgets(
        'selected tab uses the Material primary color for its accent',
        (tester) async {
          final controller = controllerFromLeaves([tab('a')]);
          addTearDown(controller.dispose);

          await pumpPlatView(
            tester,
            controller,
            theme: ThemeData(
              colorScheme: const ColorScheme.dark(primary: Color(0xFF6BA1FF)),
            ),
          );

          final border = _defaultTabBorder(tester, 'a');

          expect(border.bottom.color, const Color(0xFF6BA1FF));
        },
      );

      testWidgets(
        'uses Material TabBarTheme label values when Plat values are unset',
        (tester) async {
          const selectedColor = Color(0xFF0055AA);
          const unselectedColor = Color(0xFF445566);
          final controller = controllerFromLeaves([tab('a'), tab('b')]);
          addTearDown(controller.dispose);

          await pumpPlatView(
            tester,
            controller,
            theme: ThemeData(
              tabBarTheme: const TabBarThemeData(
                labelColor: selectedColor,
                unselectedLabelColor: unselectedColor,
                labelStyle: TextStyle(fontSize: 15),
                unselectedLabelStyle: TextStyle(fontSize: 11),
              ),
            ),
          );

          expect(
            _defaultTextStyleFinder('a', selectedColor, 15),
            findsOneWidget,
          );
          expect(
            _defaultTextStyleFinder('b', unselectedColor, 11),
            findsOneWidget,
          );
        },
      );

      testWidgets('Plat label values override Material TabBarTheme values', (
        tester,
      ) async {
        const materialColor = Color(0xFFAA0000);
        const platColor = Color(0xFF0055AA);
        final controller = controllerFromLeaves([tab('a')]);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          testHost(
            PlatTheme(
              data: const PlatThemeData(
                tabBar: PlatTabBarTheme(
                  labelColor: platColor,
                  labelStyle: TextStyle(fontSize: 13),
                ),
              ),
              child: SizedBox(
                width: 320,
                height: 200,
                child: PlatView(
                  controller: controller,
                  leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
                ),
              ),
            ),
            theme: ThemeData(
              tabBarTheme: const TabBarThemeData(
                labelColor: materialColor,
                labelStyle: TextStyle(fontSize: 20),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(_defaultTextStyleFinder('a', platColor, 13), findsOneWidget);
        expect(_defaultTextStyleFinder('a', materialColor, 20), findsNothing);
      });

      testWidgets('Plat labelColor supports WidgetStateColor', (tester) async {
        const selectedColor = Color(0xFF0055AA);
        const unselectedColor = Color(0xFF445566);
        final stateColor = WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? selectedColor
              : unselectedColor,
        );
        final controller = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          testHost(
            PlatTheme(
              data: PlatThemeData(
                tabBar: PlatTabBarTheme(labelColor: stateColor),
              ),
              child: SizedBox(
                width: 320,
                height: 200,
                child: PlatView(
                  controller: controller,
                  leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          _defaultTextStyleFinder('a', selectedColor, null),
          findsOneWidget,
        );
        expect(
          _defaultTextStyleFinder('b', unselectedColor, null),
          findsOneWidget,
        );
      });

      testWidgets('Plat unselectedLabelColor overrides stateful labelColor '
          'for unselected tabs', (tester) async {
        const selectedColor = Color(0xFF0055AA);
        const stateUnselectedColor = Color(0xFF445566);
        const explicitUnselectedColor = Color(0xFF118877);
        final stateColor = WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? selectedColor
              : stateUnselectedColor,
        );
        final controller = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          testHost(
            PlatTheme(
              data: PlatThemeData(
                tabBar: PlatTabBarTheme(
                  labelColor: stateColor,
                  unselectedLabelColor: explicitUnselectedColor,
                ),
              ),
              child: SizedBox(
                width: 320,
                height: 200,
                child: PlatView(
                  controller: controller,
                  leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          _defaultTextStyleFinder('a', selectedColor, null),
          findsOneWidget,
        );
        expect(
          _defaultTextStyleFinder('b', explicitUnselectedColor, null),
          findsOneWidget,
        );
        expect(
          _defaultTextStyleFinder('b', stateUnselectedColor, null),
          findsNothing,
        );
      });

      testWidgets(
        'uses Material TabBarTheme overlay when Plat overlay is unset',
        (tester) async {
          const overlay = Color(0x22112233);
          final controller = controllerFromLeaves([tab('a')]);
          addTearDown(controller.dispose);

          await pumpPlatView(
            tester,
            controller,
            theme: ThemeData(
              tabBarTheme: const TabBarThemeData(
                overlayColor: WidgetStatePropertyAll(overlay),
              ),
            ),
          );

          final foreground = _defaultTabContainer(
            tester,
            'a',
          ).foregroundDecoration;

          expect(foreground, isA<BoxDecoration>());
          final box = foreground! as BoxDecoration;
          expect(box.color, overlay);
        },
      );

      testWidgets('uses a compact Material-like default hover overlay', (
        tester,
      ) async {
        const scheme = ColorScheme.light(
          primary: Color(0xFF0055AA),
          onSurface: Color(0xFF223344),
        );
        final controller = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(controller.dispose);

        await pumpPlatView(
          tester,
          controller,
          theme: ThemeData(colorScheme: scheme),
        );

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: tester.getCenter(find.text('b')));
        addTearDown(() async {
          await gesture.removePointer();
        });
        await tester.pump();

        final foreground = _defaultTabContainer(
          tester,
          'b',
        ).foregroundDecoration;

        expect(foreground, isA<BoxDecoration>());
        final box = foreground! as BoxDecoration;
        expect(box.color, scheme.onSurface.withValues(alpha: 0.08));
      });

      testWidgets('local chip padding and clipping override theme defaults', (
        tester,
      ) async {
        final controller = controllerFromLeaves([tab('a')]);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          testHost(
            PlatTheme(
              data: const PlatThemeData(
                tabBar: PlatTabBarTheme(labelPadding: EdgeInsets.all(20)),
              ),
              child: SizedBox(
                width: 320,
                height: 200,
                child: PlatView(
                  controller: controller,
                  leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
                  tabBar: (_, _) => PlatTabBar(
                    tabBuilder: (_, _) => const PlatTabChip(
                      labelPadding: EdgeInsets.zero,
                      clipBehavior: Clip.hardEdge,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final container = _defaultTabContainer(tester, 'a');

        expect(container.padding, EdgeInsets.zero);
        expect(container.clipBehavior, Clip.hardEdge);
      });

      testWidgets('overlay color follows the chip border radius', (
        tester,
      ) async {
        const radius = BorderRadius.all(Radius.circular(9));
        const overlay = Color(0x22112233);
        final controller = controllerFromLeaves([tab('a')]);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          testHost(
            PlatTheme(
              data: const PlatThemeData(
                tabBar: PlatTabBarTheme(
                  chipBorderRadius: radius,
                  overlayColor: WidgetStatePropertyAll(overlay),
                ),
              ),
              child: SizedBox(
                width: 320,
                height: 200,
                child: PlatView(
                  controller: controller,
                  leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final foreground = _defaultTabContainer(
          tester,
          'a',
        ).foregroundDecoration;

        expect(foreground, isA<BoxDecoration>());
        final box = foreground! as BoxDecoration;
        expect(box.color, overlay);
        expect(box.borderRadius, radius);
      });
    });

    group('PlatTabCloseButton', () {
      testWidgets('falls back to Material close tooltip', (tester) async {
        await tester.pumpWidget(const MaterialApp(home: PlatTabCloseButton()));

        expect(find.byTooltip('Close'), findsOneWidget);
      });

      testWidgets('falls back to Material close semantics when disabled', (
        tester,
      ) async {
        const scheme = ColorScheme.light(
          onSurface: Color(0xFF111111),
          onSurfaceVariant: Color(0xFF222222),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(colorScheme: scheme),
            home: const PlatTabCloseButton(),
          ),
        );

        final semantics = tester
            .widgetList<Semantics>(
              find.descendant(
                of: find.byType(PlatTabCloseButton),
                matching: find.byType(Semantics),
              ),
            )
            .singleWhere((widget) => widget.properties.label == 'Close');
        final icon = tester.widget<Icon>(
          find.descendant(
            of: find.byType(PlatTabCloseButton),
            matching: find.byIcon(Icons.close),
          ),
        );

        expect(semantics.properties.label, 'Close');
        expect(semantics.properties.enabled, isFalse);
        expect(icon.color, scheme.onSurface.withValues(alpha: 0.38));
      });
    });
  });
}

Border _defaultTabBorder(WidgetTester tester, String label) {
  final container = _defaultTabContainer(tester, label);
  final decoration = container.decoration;
  if (decoration is! BoxDecoration) {
    throw StateError('Expected default tab container to use BoxDecoration.');
  }
  final border = decoration.border;
  if (border is! Border) {
    throw StateError('Expected selected default tab to expose a Border.');
  }
  return border;
}

Container _defaultTabContainer(WidgetTester tester, String label) {
  return tester.widget<Container>(
    find.ancestor(of: find.text(label), matching: find.byType(Container)).first,
  );
}

Finder _defaultTextStyleFinder(String label, Color color, double? fontSize) {
  return find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((widget) {
      return widget is DefaultTextStyle &&
          widget.style.color == color &&
          (fontSize == null || widget.style.fontSize == fontSize);
    }),
  );
}
