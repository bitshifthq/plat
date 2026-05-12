import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart'
    show ColorScheme, Icons, TabBarThemeData, ThemeData;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plat/plat.dart';

import '../../../helpers.dart';
import '../ui_test_helpers.dart';

void main() {
  group('PlatTabBar', () {
    group('PlatTabBarTheme.physics', () {
      testWidgets('forwards a custom ScrollPhysics to the strip scroll view', (
        tester,
      ) async {
        final controller = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          testHost(
            PlatTheme(
              data: const PlatThemeData(
                tabBar: PlatTabBarTheme(physics: BouncingScrollPhysics()),
              ),
              child: PlatView(
                controller: controller,
                leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
              ),
            ),
          ),
        );

        final scroll = tester.widget<SingleChildScrollView>(
          find.descendant(
            of: find.byType(PlatTabBar),
            matching: find.byType(SingleChildScrollView),
          ),
        );
        expect(scroll.physics, isA<BouncingScrollPhysics>());
      });

      testWidgets('defers to the platform default when null (passes null to '
          'SingleChildScrollView)', (tester) async {
        final controller = controllerFromLeaves([tab('a')]);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          testHost(
            PlatView(
              controller: controller,
              leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
            ),
          ),
        );

        final scroll = tester.widget<SingleChildScrollView>(
          find.descendant(
            of: find.byType(PlatTabBar),
            matching: find.byType(SingleChildScrollView),
          ),
        );
        expect(scroll.physics, isNull);
      });
    });

    group('PlatTabBarTheme.alignment', () {
      testWidgets('center anchors a narrow strip in the middle of the bar', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(800, 200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = controllerFromLeaves([tab('a')]);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          testHost(
            PlatTheme(
              data: const PlatThemeData(
                tabBar: PlatTabBarTheme(alignment: .center),
              ),
              child: PlatView(
                controller: controller,
                leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
                tabBar: (_, tabs) => PlatTabBar(
                  tabBuilder: (_, t) => SizedBox(
                    width: 60,
                    child: Center(child: Text('chip:${t.snapshot.id}')),
                  ),
                ),
              ),
            ),
          ),
        );

        final chipCenter = tester.getCenter(find.text('chip:a'));
        final barCenter = tester.getCenter(find.byType(PlatTabBar));
        expect((chipCenter.dx - barCenter.dx).abs(), lessThan(1.0));
      });

      testWidgets('start packs chips to the leading edge', (tester) async {
        tester.view.physicalSize = const Size(800, 200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = controllerFromLeaves([tab('a')]);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          testHost(
            PlatView(
              controller: controller,
              leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
              tabBar: (_, tabs) => PlatTabBar(
                tabBuilder: (_, t) => SizedBox(
                  width: 60,
                  child: Center(child: Text('chip:${t.snapshot.id}')),
                ),
              ),
            ),
          ),
        );

        final chipLeft = tester.getTopLeft(find.text('chip:a')).dx;
        final barLeft = tester.getTopLeft(find.byType(PlatTabBar)).dx;
        expect(chipLeft - barLeft, lessThan(20.0));
      });
    });

    group('PlatTabBarTheme.divider', () {
      const dividerColor = Color(0xFFFF00FF);
      const dividerSide = BorderSide(color: dividerColor, width: 2);

      final dividerBorderFinder = find.byWidgetPredicate((widget) {
        if (widget is! DecoratedBox) return false;
        final decoration = widget.decoration;
        if (decoration is! BoxDecoration) return false;
        final border = decoration.border;
        if (border is! Border) return false;
        final any = [border.top, border.right, border.bottom, border.left];
        return any.any((s) => s.color == dividerColor);
      });

      testWidgets('paints on the bottom edge for top-side bars', (
        tester,
      ) async {
        final controller = controllerFromLeaves([tab('a')]);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          testHost(
            PlatTheme(
              data: const PlatThemeData(
                tabBar: PlatTabBarTheme(divider: dividerSide),
              ),
              child: PlatView(
                controller: controller,
                leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
              ),
            ),
          ),
        );

        expect(dividerBorderFinder, findsOneWidget);
        final border = _boxBorder(tester, dividerBorderFinder);

        expect(border.bottom.color, dividerColor);
        expect(border.top, BorderSide.none);
        expect(border.left, BorderSide.none);
        expect(border.right, BorderSide.none);
      });

      testWidgets('paints nothing when null', (tester) async {
        final controller = controllerFromLeaves([tab('a')]);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          testHost(
            PlatView(
              controller: controller,
              leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
            ),
          ),
        );

        expect(dividerBorderFinder, findsNothing);
      });

      testWidgets(
        'uses Material TabBarTheme divider when Plat divider is unset',
        (tester) async {
          final controller = controllerFromLeaves([tab('a')]);
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            testHost(
              PlatView(
                controller: controller,
                leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
              ),
              theme: ThemeData(
                tabBarTheme: const TabBarThemeData(
                  dividerColor: dividerColor,
                  dividerHeight: 2,
                ),
              ),
            ),
          );

          expect(dividerBorderFinder, findsOneWidget);
          final border = _boxBorder(tester, dividerBorderFinder);

          expect(border.bottom.color, dividerColor);
          expect(border.bottom.width, 2);
        },
      );
    });

    group('PlatTabBarTheme.mouseCursor', () {
      testWidgets('default resolver uses click for normal chips', (
        tester,
      ) async {
        final controller = controllerFromLeaves([tab('a')]);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          testHost(
            PlatView(
              controller: controller,
              leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
            ),
          ),
        );

        expect(
          _tabMouseCursorFinder('a', SystemMouseCursors.click),
          findsOneWidget,
        );
      });

      testWidgets('default resolver keeps locked chips clickable', (
        tester,
      ) async {
        final controller = controllerFromLeaves([tab('a', locked: true)]);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          testHost(
            PlatView(
              controller: controller,
              leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
            ),
          ),
        );

        expect(
          _tabMouseCursorFinder('a', SystemMouseCursors.click),
          findsOneWidget,
        );
      });

      testWidgets('host override resolves to a custom cursor', (tester) async {
        final controller = controllerFromLeaves([tab('a')]);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          testHost(
            PlatTheme(
              data: const PlatThemeData(
                tabBar: PlatTabBarTheme(
                  mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.text),
                ),
              ),
              child: PlatView(
                controller: controller,
                leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
              ),
            ),
          ),
        );

        expect(
          _tabMouseCursorFinder('a', SystemMouseCursors.text),
          findsOneWidget,
        );
      });

      testWidgets(
        'uses Material TabBarTheme cursor when Plat cursor is unset',
        (tester) async {
          final controller = controllerFromLeaves([tab('a')]);
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            testHost(
              PlatView(
                controller: controller,
                leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
              ),
              theme: ThemeData(
                tabBarTheme: const TabBarThemeData(
                  mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.text),
                ),
              ),
            ),
          );

          expect(
            _tabMouseCursorFinder('a', SystemMouseCursors.text),
            findsOneWidget,
          );
        },
      );
    });

    group('PlatTabBar widget overrides', () {
      testWidgets('padding overrides PlatTabBarTheme.padding', (tester) async {
        final controller = controllerFromLeaves([tab('a')]);
        addTearDown(controller.dispose);

        const widgetPadding = EdgeInsets.fromLTRB(11, 13, 17, 19);

        await tester.pumpWidget(
          testHost(
            PlatTheme(
              data: const PlatThemeData(
                tabBar: PlatTabBarTheme(
                  padding: EdgeInsets.symmetric(horizontal: 99),
                ),
              ),
              child: PlatView(
                controller: controller,
                leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
                tabBar: (_, _) => const PlatTabBar(padding: widgetPadding),
              ),
            ),
          ),
        );

        final padding = tester.widget<Padding>(
          find
              .descendant(
                of: find.byType(PlatTabBar),
                matching: find.byType(Padding),
              )
              .first,
        );
        expect(padding.padding, widgetPadding);
      });

      testWidgets('spacing overrides PlatTabBarTheme.spacing', (tester) async {
        final controller = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          testHost(
            PlatTheme(
              data: const PlatThemeData(tabBar: PlatTabBarTheme(spacing: 8)),
              child: PlatView(
                controller: controller,
                leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
                tabBar: (_, _) => const PlatTabBar(spacing: 24),
              ),
            ),
          ),
        );

        final aRight = tester.getTopRight(find.text('a')).dx;
        final bLeft = tester.getTopLeft(find.text('b')).dx;
        expect(bLeft - aRight, greaterThanOrEqualTo(24.0));
      });

      testWidgets('decoration overrides PlatTabBarTheme.decoration', (
        tester,
      ) async {
        const widgetDecoration = BoxDecoration(color: Color(0xFF445566));

        final controller = controllerFromLeaves([tab('a')]);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          testHost(
            PlatTheme(
              data: const PlatThemeData(
                tabBar: PlatTabBarTheme(
                  decoration: BoxDecoration(color: Color(0xFF000000)),
                ),
              ),
              child: PlatView(
                controller: controller,
                leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
                tabBar: (_, _) =>
                    const PlatTabBar(decoration: widgetDecoration),
              ),
            ),
          ),
        );

        expect(_tabBarDecorationFinder(widgetDecoration), findsOneWidget);
      });

      testWidgets('divider overrides PlatTabBarTheme.divider', (tester) async {
        const widgetDividerColor = Color(0xFF00FFAA);
        const widgetDivider = BorderSide(color: widgetDividerColor, width: 3);

        final controller = controllerFromLeaves([tab('a')]);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          testHost(
            PlatTheme(
              data: const PlatThemeData(
                tabBar: PlatTabBarTheme(
                  divider: BorderSide(color: Color(0xFFFF00FF)),
                ),
              ),
              child: PlatView(
                controller: controller,
                leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
                tabBar: (_, _) => const PlatTabBar(divider: widgetDivider),
              ),
            ),
          ),
        );

        expect(
          _tabBarBottomDividerFinder(color: widgetDividerColor, width: 3),
          findsOneWidget,
        );
      });

      testWidgets('alignment overrides PlatTabBarTheme.alignment', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(800, 200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = controllerFromLeaves([tab('a')]);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          testHost(
            PlatTheme(
              data: const PlatThemeData(
                tabBar: PlatTabBarTheme(alignment: .end),
              ),
              child: PlatView(
                controller: controller,
                leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
                tabBar: (_, _) => PlatTabBar(
                  alignment: .center,
                  tabBuilder: (_, t) => SizedBox(
                    width: 60,
                    child: Center(child: Text('chip:${t.snapshot.id}')),
                  ),
                ),
              ),
            ),
          ),
        );

        final chipCenter = tester.getCenter(find.text('chip:a'));
        final barCenter = tester.getCenter(find.byType(PlatTabBar));
        expect((chipCenter.dx - barCenter.dx).abs(), lessThan(1.0));
      });

      testWidgets('fit overrides PlatTabBarTheme.fit', (tester) async {
        tester.view.physicalSize = const Size(600, 200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          testHost(
            PlatView(
              controller: controller,
              leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
              tabBar: (_, _) => PlatTabBar(
                fit: .expand,
                tabBuilder: (_, t) =>
                    Center(child: Text('chip:${t.snapshot.id}')),
              ),
            ),
          ),
        );

        final aWidth = tester.getSize(find.text('chip:a')).width;
        final bWidth = tester.getSize(find.text('chip:b')).width;
        final aCenter = tester.getCenter(find.text('chip:a'));
        final bCenter = tester.getCenter(find.text('chip:b'));
        expect((aWidth - bWidth).abs(), lessThan(1.0));
        expect(bCenter.dx - aCenter.dx, greaterThan(200.0));
      });

      testWidgets('expand fit stretches chip slots to the chip edges', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = controllerFromLeaves([tab('a')]);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          testHost(
            SizedBox(
              width: 320,
              height: 200,
              child: PlatView(
                controller: controller,
                leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
                tabBar: (_, _) =>
                    const PlatTabBar(fit: .expand, tabBuilder: _slottedTabChip),
              ),
            ),
          ),
        );
        await tester.pump();

        final chip = find
            .ancestor(of: find.text('label'), matching: find.byType(Container))
            .first;
        final chipRect = tester.getRect(chip);
        final leadingRect = tester.getRect(find.text('leading'));
        final trailingRect = tester.getRect(find.text('trailing'));

        expect(leadingRect.left - chipRect.left, closeTo(12, 1));
        expect(chipRect.right - trailingRect.right, closeTo(12, 1));
      });

      testWidgets('expand fit reserves icon-sized width for the active chip', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = controllerFromLeaves([
          for (var i = 0; i < 24; i++) tab('t$i'),
        ]);
        addTearDown(controller.dispose);
        controller.focus('t12');

        await tester.pumpWidget(
          testHost(
            PlatTheme(
              data: const PlatThemeData(tabBar: PlatTabBarTheme(fit: .expand)),
              child: SizedBox(
                width: 320,
                height: 200,
                child: PlatView(
                  controller: controller,
                  leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
                  tabBar: (_, _) => PlatTabBar(
                    tabBuilder: (_, tab) => SizedBox.expand(
                      key: ValueKey('chip:${tab.snapshot.id}'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final selectedWidth = tester
            .getSize(find.byKey(const ValueKey('chip:t12')))
            .width;
        final otherWidth = tester
            .getSize(find.byKey(const ValueKey('chip:t0')))
            .width;

        expect(selectedWidth, greaterThanOrEqualTo(32));
        expect(selectedWidth, greaterThan(otherWidth));
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'chipBorderRadius overrides PlatTabBarTheme.chipBorderRadius',
        (tester) async {
          const widgetRadius = BorderRadius.all(Radius.circular(9));

          final controller = controllerFromLeaves([tab('a')]);
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            testHost(
              PlatTheme(
                data: const PlatThemeData(
                  tabBar: PlatTabBarTheme(chipBorderRadius: BorderRadius.zero),
                ),
                child: PlatView(
                  controller: controller,
                  leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
                  tabBar: (_, _) =>
                      const PlatTabBar(chipBorderRadius: widgetRadius),
                ),
              ),
            ),
          );

          expect(_tabChipBorderRadiusFinder(widgetRadius), findsOneWidget);
        },
      );
    });

    group('PlatTabBuilder', () {
      testWidgets('tabBuilder can return a scoped default chip', (
        tester,
      ) async {
        final controller = controllerFromLeaves([tab('a')]);
        addTearDown(controller.dispose);

        await pumpPlatView(
          tester,
          controller,
          tabBar: (_, _) =>
              PlatTabBar(tabBuilder: (_, _) => const PlatTabChip()),
        );

        expect(find.text('a'), findsOneWidget);
      });

      testWidgets('tabBuilder receives group metadata and hover state', (
        tester,
      ) async {
        final controller = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(controller.dispose);

        await pumpPlatView(
          tester,
          controller,
          tabBar: (_, _) => PlatTabBar(
            tabBuilder: (_, tab) => Text(
              'tab:${tab.snapshot.id}:${tab.group.id}:'
              '${tab.index}:'
              '${tab.states.contains(WidgetState.hovered)}',
            ),
          ),
        );

        expect(find.text('tab:a:${controller.rootId}:0:false'), findsOneWidget);

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(
          location: tester.getCenter(find.textContaining('tab:a:')),
        );
        addTearDown(() async {
          await gesture.removePointer();
        });
        await tester.pump();

        expect(find.text('tab:a:${controller.rootId}:0:true'), findsOneWidget);
      });

      testWidgets('tabBuilder locked tab receives locked tab details', (
        tester,
      ) async {
        final controller = controllerFromLeaves([
          tab('a', locked: true),
          tab('b'),
        ]);
        addTearDown(controller.dispose);

        final tabsById = await _captureBuiltTabs(tester, controller);

        expect(_tabContext(tabsById, 'a').snapshot.locked, isTrue);
      });

      testWidgets('tabBuilder active tab receives selected tab details', (
        tester,
      ) async {
        final controller = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(controller.dispose);
        controller.focus('b');

        final tabsById = await _captureBuiltTabs(tester, controller);

        expect(
          _tabContext(tabsById, 'b').states.contains(WidgetState.selected),
          isTrue,
        );
      });

      testWidgets('tabBuilder focused tab receives focused tab details', (
        tester,
      ) async {
        final controller = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(controller.dispose);
        controller.focus('b');

        final tabsById = await _captureBuiltTabs(tester, controller);

        expect(
          _tabContext(tabsById, 'b').states.contains(WidgetState.focused),
          isTrue,
        );
      });

      testWidgets('tabBuilder stable tab id renders changed public data', (
        tester,
      ) async {
        final controller = PlatController(
          initialPlat: .tabs([
            tabPaneWith(id: 'a', title: 'a', data: 'before'),
          ], id: 'group'),
        );
        addTearDown(controller.dispose);

        await pumpPlatView(
          tester,
          controller,
          tabBar: (_, _) => PlatTabBar(
            tabBuilder: (_, tab) => Text('tab:${tab.snapshot.data}'),
          ),
        );

        controller.replace(
          .tabs([tabPaneWith(id: 'a', title: 'a', data: 'after')], id: 'group'),
        );
        await tester.pump();

        expect(find.text('tab:after'), findsOneWidget);
      });
    });

    group('PlatTabBar.dragFeedbackBuilder', () {
      testWidgets('unlocked tab drag passes drag feedback details', (
        tester,
      ) async {
        final controller = controllerFromLeaves([tab('a')]);
        addTearDown(controller.dispose);
        String? feedbackFor;

        await pumpPlatView(
          tester,
          controller,
          tabBar: (_, _) => PlatTabBar(
            dragFeedbackBuilder: (_, tab) {
              feedbackFor = tab.snapshot.id;
              expect(tab.states.contains(WidgetState.dragged), isTrue);
              return Text('feedback:${tab.snapshot.id}');
            },
          ),
        );

        final gesture = await _beginDrag(tester, find.text('a'));
        addTearDown(gesture.up);

        expect(feedbackFor, 'a');
      });

      testWidgets('unlocked tab drag renders the supplied feedback widget', (
        tester,
      ) async {
        final controller = controllerFromLeaves([tab('a')]);
        addTearDown(controller.dispose);

        await pumpPlatView(
          tester,
          controller,
          tabBar: (_, _) => PlatTabBar(
            dragFeedbackBuilder: (_, tab) =>
                Text('feedback:${tab.snapshot.id}'),
          ),
        );

        final gesture = await _beginDrag(tester, find.text('a'));
        addTearDown(gesture.up);

        expect(find.text('feedback:a'), findsOneWidget);
      });

      testWidgets('locked tab drag does not call the feedback builder', (
        tester,
      ) async {
        final controller = controllerFromLeaves([
          tab('a', locked: true),
          tab('b', locked: true),
        ]);
        addTearDown(controller.dispose);
        String? feedbackFor;

        await pumpPlatView(
          tester,
          controller,
          tabBar: (_, _) => PlatTabBar(
            dragFeedbackBuilder: (_, tab) {
              feedbackFor = tab.snapshot.id;
              return Text('feedback:${tab.snapshot.id}');
            },
          ),
        );

        final gesture = await tester.startGesture(
          tester.getCenter(find.text('a')),
        );
        addTearDown(gesture.up);
        await tester.pump();
        await gesture.moveBy(const Offset(kTouchSlop + 1, 0));
        await tester.pump();

        expect(feedbackFor, isNull);
      });

      testWidgets('default feedback does not scale or fade the inactive chip', (
        tester,
      ) async {
        final controller = controllerFromLeaves([tab('a')]);
        addTearDown(controller.dispose);

        await pumpPlatView(
          tester,
          controller,
          tabBar: (_, _) => PlatTabBar(
            tabBuilder: (_, tab) => Text(
              tab.states.contains(WidgetState.dragged) ? 'feedback' : 'tab',
            ),
          ),
        );

        final gesture = await _beginDrag(tester, find.text('tab'));
        addTearDown(gesture.up);

        final feedback = find.text('feedback');
        expect(feedback, findsWidgets);
        expect(
          find.ancestor(
            of: feedback,
            matching: _uniformScaleTransformFinder(1.05),
          ),
          findsNothing,
        );
        expect(
          find.ancestor(of: feedback, matching: _fadedOpacityFinder),
          findsNothing,
        );
      });

      testWidgets('default feedback matches the rendered chip size', (
        tester,
      ) async {
        final controller = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(controller.dispose);

        await pumpPlatView(
          tester,
          controller,
          tabBar: (_, _) => PlatTabBar(
            fit: .expand,
            tabBuilder: (_, tab) =>
                SizedBox.expand(key: ValueKey('chip-${tab.snapshot.id}')),
          ),
        );

        final source = find.byKey(const ValueKey('chip-a'));
        final sourceSize = tester.getSize(source);
        final gesture = await tester.startGesture(tester.getCenter(source));
        addTearDown(gesture.up);
        await tester.pump();
        await gesture.moveBy(const Offset(0, 80));
        await tester.pump();

        final feedbackSize = tester.getSize(
          find.byKey(const ValueKey('chip-a')).last,
        );
        expect(feedbackSize, sourceSize);
      });

      testWidgets('default feedback captures the source tab theme', (
        tester,
      ) async {
        const chipColor = Color(0xFF123456);
        const chipRadius = BorderRadius.all(Radius.circular(13));
        final controller = controllerFromLeaves([tab('a')]);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          testHost(
            PlatTheme(
              data: const PlatThemeData(
                tabBar: PlatTabBarTheme(
                  chipBackgroundColor: WidgetStatePropertyAll(chipColor),
                  chipBorderRadius: chipRadius,
                ),
              ),
              child: PlatView(
                controller: controller,
                leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
                tabBar: (_, _) => PlatTabBar(
                  tabBuilder: (_, _) => const PlatTabChip(label: Text('tab:a')),
                ),
              ),
            ),
          ),
        );

        final gesture = await tester.startGesture(
          tester.getCenter(find.text('tab:a')),
        );
        addTearDown(gesture.up);
        await tester.pump();
        await gesture.moveBy(const Offset(0, 80));
        await tester.pump();

        final container = tester.widget<Container>(
          find
              .ancestor(
                of: find.text('tab:a'),
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is Container && widget.decoration is BoxDecoration,
                ),
              )
              .last,
        );
        final decoration = switch (container.decoration) {
          final BoxDecoration value => value,
          _ => throw StateError('Expected tab chip to use BoxDecoration.'),
        };

        expect(decoration.color, chipColor);
        expect(decoration.borderRadius, chipRadius);
      });

      testWidgets('default feedback is centered on the pointer', (
        tester,
      ) async {
        final controller = controllerFromLeaves([tab('a')]);
        addTearDown(controller.dispose);

        await pumpPlatView(
          tester,
          controller,
          tabBar: (_, _) => PlatTabBar(
            tabBuilder: (_, tab) {
              return SizedBox(
                key: ValueKey('chip-${tab.snapshot.id}'),
                width: 90,
                height: 24,
              );
            },
          ),
        );

        final chip = find.byKey(const ValueKey('chip-a'));
        final sourceCenter = tester.getCenter(chip);
        final gesture = await tester.startGesture(sourceCenter);
        addTearDown(gesture.up);
        await tester.pump();
        const delta = Offset(0, 80);
        await gesture.moveBy(delta);
        await tester.pump();

        final feedbackCenter = tester.getCenter(chip.last);
        expect((feedbackCenter - (sourceCenter + delta)).distance, lessThan(1));
      });

      testWidgets('default feedback renders inactive drag states', (
        tester,
      ) async {
        final controller = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(controller.dispose);

        await pumpPlatView(
          tester,
          controller,
          tabBar: (_, _) => PlatTabBar(
            tabBuilder: (_, tab) {
              final dragged = tab.states.contains(WidgetState.dragged);
              final selected = tab.states.contains(WidgetState.selected);
              final focused = tab.states.contains(WidgetState.focused);
              return SizedBox(
                key: ValueKey('chip-${tab.snapshot.id}'),
                width: 120,
                child: Text(
                  'states:${selected ? 'selected' : 'inactive'}:'
                  '${focused ? 'focused' : 'unfocused'}:'
                  '${dragged ? 'dragged' : 'idle'}',
                ),
              );
            },
          ),
        );

        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const ValueKey('chip-a'))),
        );
        addTearDown(gesture.up);
        await tester.pump();
        await gesture.moveBy(const Offset(0, 80));
        await tester.pump();

        expect(find.text('states:inactive:unfocused:dragged'), findsOneWidget);
      });

      testWidgets('default feedback uses the dragged accent background', (
        tester,
      ) async {
        const primary = Color(0xFF6750A4);
        const scheme = ColorScheme.light(primary: primary);
        final controller = controllerFromLeaves([tab('a')]);
        addTearDown(controller.dispose);

        await pumpPlatView(
          tester,
          controller,
          theme: ThemeData(colorScheme: scheme),
        );

        final gesture = await _beginDrag(tester, find.text('a'));
        addTearDown(gesture.up);

        final decoration = _tabChipDecoration(tester, find.text('a').last);
        expect(
          decoration.color,
          Color.alphaBlend(
            primary.withValues(alpha: 0.26),
            scheme.surfaceContainerHigh,
          ),
        );
        expect(decoration.color!.a, 1);
      });

      testWidgets('default feedback hides the standard close button', (
        tester,
      ) async {
        final controller = controllerFromLeaves([tab('a')]);
        addTearDown(controller.dispose);

        await pumpPlatView(
          tester,
          controller,
          tabBar: (_, _) => PlatTabBar(
            tabBuilder: (_, _) =>
                const PlatTabChip(trailing: PlatTabCloseButton()),
          ),
        );

        expect(find.byIcon(Icons.close), findsOneWidget);

        final gesture = await tester.startGesture(
          tester.getCenter(find.text('a')),
        );
        addTearDown(gesture.up);
        await tester.pump();
        await gesture.moveBy(const Offset(0, 80));
        await tester.pump();

        final hidden = tester.widget<Visibility>(
          find
              .ancestor(
                of: find.byIcon(Icons.close),
                matching: find.byType(Visibility),
              )
              .last,
        );
        expect(hidden.visible, isFalse);
        expect(hidden.maintainSize, isTrue);
      });
    });

    group('PlatTabBar placeholder spacing', () {
      testWidgets('default placeholder renders a dragged inactive chip', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(800, 200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = controllerFromLeaves([tab('a'), tab('b'), tab('c')]);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          testHost(
            PlatView(
              controller: controller,
              leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
              tabBar: (_, _) => PlatTabBar(
                tabBuilder: (_, t) {
                  final dragged = t.states.contains(WidgetState.dragged);
                  final selected = t.states.contains(WidgetState.selected);
                  return SizedBox(
                    width: 90,
                    child: Text(
                      'chip:${t.snapshot.id}:'
                      '${selected ? 'selected' : 'inactive'}:'
                      '${dragged ? 'dragged' : 'idle'}',
                    ),
                  );
                },
              ),
            ),
          ),
        );

        final source = tester.getCenter(find.text('chip:a:selected:idle'));
        final bCenter = tester.getCenter(find.text('chip:b:inactive:idle'));
        final gesture = await tester.startGesture(source);
        addTearDown(gesture.up);
        await tester.pump();
        await gesture.moveBy(const Offset(kTouchSlop + 1, 0));
        await tester.pump();
        await gesture.moveTo(bCenter);
        await tester.pump();

        expect(
          find.descendant(
            of: find.byType(PlatTabBar),
            matching: find.text('chip:a:inactive:dragged'),
          ),
          findsOneWidget,
        );
      });

      testWidgets('placeholder gets the same gap on both sides as chips', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(800, 200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = controllerFromLeaves([tab('a'), tab('b'), tab('c')]);
        addTearDown(controller.dispose);

        const spacing = 10.0;

        await tester.pumpWidget(
          testHost(
            PlatView(
              controller: controller,
              leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
              tabBar: (_, _) => PlatTabBar(
                spacing: spacing,
                tabBuilder: (_, t) => SizedBox(
                  width: 60,
                  child: Center(child: Text('chip:${t.snapshot.id}')),
                ),
                placeholderBuilder: (_, t) => SizedBox(
                  width: 60,
                  child: Center(child: Text('ph:${t.snapshot.id}')),
                ),
              ),
            ),
          ),
        );

        expect(_countSpacers(tester, spacing), 2);

        final source = tester.getCenter(find.text('chip:a'));
        final bCenter = tester.getCenter(find.text('chip:b'));
        final gesture = await tester.startGesture(source);
        addTearDown(() async {
          await gesture.up();
        });
        await tester.pump();
        await gesture.moveBy(const Offset(kTouchSlop + 1, 0));
        await tester.pump();
        await gesture.moveTo(bCenter);
        await tester.pump();

        expect(find.text('ph:a'), findsOneWidget);

        expect(_countSpacers(tester, spacing), 3);
      });
    });

    group('auto-scroll-to-active', () {
      testWidgets('scrolls a far-right active chip into view on focus change', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(240, 200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = controllerFromLeaves([
          tab('a'),
          tab('b'),
          tab('c'),
          tab('d'),
          tab('e'),
          tab('f'),
          tab('g'),
          tab('h'),
        ]);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          testHost(
            PlatView(
              controller: controller,
              leafBuilder: (_, leaf) => Text('body:${leaf.id}'),
              tabBar: (_, tabs) => PlatTabBar(
                tabBuilder: (_, t) => SizedBox(
                  width: 80,
                  child: Center(child: Text('chip:${t.snapshot.id}')),
                ),
              ),
            ),
          ),
        );

        expect(find.text('chip:h'), findsOneWidget);
        final initialOffset = _stripScrollOffset(tester);
        expect(initialOffset, 0.0);

        controller.focus('h');
        await tester.pumpAndSettle();

        final scrolledOffset = _stripScrollOffset(tester);
        expect(scrolledOffset, greaterThan(initialOffset));
      });
    });
  });
}

final _fadedOpacityFinder = find.byWidgetPredicate(
  (widget) => widget is Opacity && widget.opacity < 1,
);

Future<TestGesture> _beginDrag(WidgetTester tester, Finder chip) async {
  final from = tester.getCenter(chip);
  final gesture = await tester.startGesture(from);
  await tester.pump();
  await gesture.moveBy(const Offset(kTouchSlop + 1, 0));
  await tester.pump();
  return gesture;
}

Border _boxBorder(WidgetTester tester, Finder finder) {
  final decoration = tester.widget<DecoratedBox>(finder).decoration;
  if (decoration is! BoxDecoration) {
    throw StateError('Expected DecoratedBox to use BoxDecoration.');
  }
  final border = decoration.border;
  if (border is! Border) {
    throw StateError('Expected BoxDecoration to expose a Border.');
  }
  return border;
}

Future<Map<String, PlatTabDetails>> _captureBuiltTabs(
  WidgetTester tester,
  PlatController controller,
) async {
  final tabsById = <String, PlatTabDetails>{};
  await pumpPlatView(
    tester,
    controller,
    tabBar: (_, _) => PlatTabBar(
      tabBuilder: (_, tab) {
        tabsById[tab.snapshot.id] = tab;
        return Text(tab.snapshot.title);
      },
    ),
  );
  return tabsById;
}

int _countSpacers(WidgetTester tester, double spacing) {
  return tester
      .widgetList<SizedBox>(
        find.descendant(
          of: find.byType(PlatTabBar),
          matching: find.byType(SizedBox),
        ),
      )
      .where((b) => b.width == spacing || b.height == spacing)
      .length;
}

Widget _slottedTabChip(BuildContext context, PlatTabDetails tab) {
  return const PlatTabChip(
    leading: Text('leading'),
    label: Text('label'),
    trailing: Text('trailing'),
  );
}

double _stripScrollOffset(WidgetTester tester) {
  final scrollable = tester.widget<SingleChildScrollView>(
    find.descendant(
      of: find.byType(PlatTabBar),
      matching: find.byType(SingleChildScrollView),
    ),
  );
  final controller = scrollable.controller;
  if (controller == null) {
    throw StateError(
      'Expected the tab strip scroll view to expose a controller.',
    );
  }
  return controller.offset;
}

Finder _tabBarBottomDividerFinder({
  required Color color,
  required double width,
}) {
  return find.byWidgetPredicate((widget) {
    if (widget is! DecoratedBox) return false;
    final decoration = widget.decoration;
    if (decoration is! BoxDecoration) return false;
    final border = decoration.border;
    if (border is! Border) return false;
    return border.bottom.color == color && border.bottom.width == width;
  });
}

Finder _tabBarDecorationFinder(Decoration decoration) {
  return find.byWidgetPredicate(
    (widget) => widget is DecoratedBox && widget.decoration == decoration,
  );
}

Finder _tabChipBorderRadiusFinder(BorderRadiusGeometry radius) {
  return find.byWidgetPredicate((widget) {
    if (widget is! Container) return false;
    final decoration = widget.decoration;
    return decoration is BoxDecoration && decoration.borderRadius == radius;
  });
}

BoxDecoration _tabChipDecoration(WidgetTester tester, Finder label) {
  final container = tester.widget<Container>(
    find
        .ancestor(
          of: label,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container && widget.decoration is BoxDecoration,
          ),
        )
        .last,
  );
  final decoration = container.decoration;
  if (decoration is! BoxDecoration) {
    throw StateError('Expected tab chip to use BoxDecoration.');
  }
  return decoration;
}

PlatTabDetails _tabContext(Map<String, PlatTabDetails> tabsById, String id) {
  final tab = tabsById[id];
  if (tab == null) {
    throw StateError('Expected builder to receive tab "$id".');
  }
  return tab;
}

Finder _tabMouseCursorFinder(String label, MouseCursor cursor) {
  return find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate(
      (widget) => widget is MouseRegion && widget.cursor == cursor,
    ),
  );
}

Finder _uniformScaleTransformFinder(double scale) {
  return find.byWidgetPredicate((widget) {
    if (widget is! Transform) return false;
    final matrix = widget.transform;
    return (matrix.entry(0, 0) - scale).abs() < 1e-6 &&
        (matrix.entry(1, 1) - scale).abs() < 1e-6;
  });
}
