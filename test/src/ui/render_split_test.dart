import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plat/plat.dart';
import 'package:plat/src/ui/split.dart';

import '../../helpers.dart';
import 'ui_test_helpers.dart';

void main() {
  group('SplitRender', () {
    group('A4 sizing', () {
      testWidgets('fraction initial yields value × available pixels', (
        tester,
      ) async {
        final c = controllerFromTree(
          SplitNode(
            id: 's',
            axis: .horizontal,
            children: [
              TabGroupNode(
                id: 'left',
                size: const .resizable(initial: .fraction(0.3)),
                tabs: treeTabs([tab('a')]),
              ),
              TabGroupNode(
                id: 'right',
                size: const .resizable(initial: .fraction(0.7)),
                tabs: treeTabs([tab('b')]),
              ),
            ],
          ),
        );
        await tester.pumpWidget(_centered(_app(c, theme: _theme())));
        expect(_bodyWidth(tester, 'a'), closeTo(180, 0.5));
        expect(_bodyWidth(tester, 'b'), closeTo(420, 0.5));
      });

      testWidgets('auto siblings split the leftover equally', (tester) async {
        final c = _h([
          TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
          TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
        ]);
        await tester.pumpWidget(_centered(_app(c, theme: _theme())));
        expect(_bodyWidth(tester, 'a'), closeTo(300, 0.5));
        expect(_bodyWidth(tester, 'b'), closeTo(300, 0.5));
      });
    });

    group('A5 mixed sizing', () {
      testWidgets('fixed claims first, autos share leftover', (tester) async {
        final c = _h([
          TabGroupNode(
            id: 'fix',
            size: const .fixed(.pixel(120)),
            tabs: treeTabs([tab('f')]),
          ),
          TabGroupNode(id: 'a1', tabs: treeTabs([tab('a')])),
          TabGroupNode(id: 'a2', tabs: treeTabs([tab('b')])),
        ]);
        await tester.pumpWidget(_centered(_app(c, theme: _theme())));
        expect(_bodyWidth(tester, 'f'), closeTo(120, 0.5));
        expect(_bodyWidth(tester, 'a'), closeTo(240, 0.5));
        expect(_bodyWidth(tester, 'b'), closeTo(240, 0.5));
      });
    });

    group('rebalance after structural change', () {
      testWidgets(
        'splitting next to a fully-claimed sibling does not collapse the new '
        'pane',
        (tester) async {
          final c = controllerFromTree(
            SplitNode(
              id: 's',
              axis: .horizontal,
              children: [
                TabGroupNode(
                  id: 'left',
                  size: const .resizable(initial: .fraction(0.6)),
                  tabs: treeTabs([tab('a'), tab('b')]),
                ),
                TabGroupNode(
                  id: 'right',
                  size: const .resizable(initial: .fraction(0.4)),
                  tabs: treeTabs([tab('c')]),
                ),
              ],
            ),
          );
          await tester.pumpWidget(_centered(_app(c, theme: _theme())));
          c.focus('b');
          c.splitActiveTab(tabGroupId: 'left', side: .right);
          await tester.pump();

          expect(_bodyWidth(tester, 'a'), closeTo(180, 0.5));
          expect(_bodyWidth(tester, 'b'), closeTo(180, 0.5));
          expect(_bodyWidth(tester, 'c'), closeTo(240, 0.5));
        },
      );

      testWidgets(
        'removing a sibling rescales remaining claims to fill the available '
        'extent',
        (tester) async {
          final c = controllerFromTree(
            SplitNode(
              id: 's',
              axis: .horizontal,
              children: [
                TabGroupNode(
                  id: 'a1',
                  size: const .resizable(initial: .fraction(0.5)),
                  tabs: treeTabs([tab('a')]),
                ),
                TabGroupNode(
                  id: 'a2',
                  size: const .resizable(initial: .fraction(0.3)),
                  tabs: treeTabs([tab('b')]),
                ),
                TabGroupNode(
                  id: 'a3',
                  size: const .resizable(initial: .fraction(0.2)),
                  tabs: treeTabs([tab('c')]),
                ),
              ],
            ),
          );
          await tester.pumpWidget(_centered(_app(c, theme: _theme())));
          c.close('a3');
          await tester.pump();

          expect(_bodyWidth(tester, 'a'), closeTo(375, 0.5));
          expect(_bodyWidth(tester, 'b'), closeTo(225, 0.5));
        },
      );
    });

    group('A6 spacing pixel exactness', () {
      testWidgets('two children + spacing 4 yields exactly 4px gap', (
        tester,
      ) async {
        final c = _h([
          TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
          TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
        ]);
        await tester.pumpWidget(
          _centered(_app(c, theme: _theme(thickness: 4))),
        );
        final left = _bodyWidth(tester, 'a');
        final right = _bodyWidth(tester, 'b');
        expect(left + right + 4, closeTo(600, 0.5));
      });
    });

    group('A10 fixed neighbour locks divider', () {
      testWidgets(
        'cursor over a divider with a FixedSize side does not switch',
        (tester) async {
          final c = _h([
            TabGroupNode(
              id: 'left',
              size: const .fixed(.pixel(120)),
              tabs: treeTabs([tab('a')]),
            ),
            TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
          ]);
          await tester.pumpWidget(
            _centered(_app(c, theme: _theme(thickness: 4))),
          );
          expect(
            find.byWidgetPredicate(
              (widget) =>
                  widget is MouseRegion &&
                  widget.cursor == SystemMouseCursors.resizeColumn,
            ),
            findsNothing,
          );
        },
      );

      testWidgets('drag over a fixed-neighbour gutter does not change sizes', (
        tester,
      ) async {
        final c = _h([
          TabGroupNode(
            id: 'left',
            size: const .fixed(.pixel(120)),
            tabs: treeTabs([tab('a')]),
          ),
          TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
        ]);
        await tester.pumpWidget(
          _centered(_app(c, theme: _theme(thickness: 4))),
        );
        final before = _bodyWidth(tester, 'a');
        await tester.dragFrom(
          tester.getTopLeft(find.byType(PlatView)) + const Offset(122, 100),
          const Offset(80, 0),
        );
        await tester.pump();
        expect(_bodyWidth(tester, 'a'), closeTo(before, 0.5));
      });
    });

    group('A11 non-resizable splits lock the divider', () {
      testWidgets('resizable: false means the cursor never switches', (
        tester,
      ) async {
        final c = controllerFromTree(
          SplitNode(
            id: 's',
            axis: .horizontal,
            resizable: false,
            children: [
              TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
              TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
            ],
          ),
        );
        await tester.pumpWidget(
          _centered(_app(c, theme: _theme(thickness: 4))),
        );
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is MouseRegion &&
                widget.cursor == SystemMouseCursors.resizeColumn,
          ),
          findsNothing,
        );
      });
    });

    group('B3/B4 divider theme resolves hover/drag states', () {
      testWidgets('hover and drag flow into PlatDividerTheme.color', (
        tester,
      ) async {
        const idle = Color(0xFF102030);
        const hovered = Color(0xFF405060);
        const dragged = Color(0xFF708090);
        final c = _h([
          TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
          TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
        ]);
        final theme = PlatThemeData(
          divider: PlatDividerTheme(
            thickness: 4,
            color: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.dragged)) return dragged;
              if (states.contains(WidgetState.hovered)) return hovered;
              return idle;
            }),
          ),
        );
        await tester.pumpWidget(_centered(_app(c, theme: theme)));

        expect(_dividerColor(tester), idle);

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(_dividerCenter(tester));
        await tester.pump();
        expect(_dividerColor(tester), hovered);

        final gesture = await tester.startGesture(_dividerCenter(tester));
        await gesture.moveBy(const Offset(20, 0));
        await tester.pump();
        expect(_dividerColor(tester), dragged);

        await gesture.up();
        await tester.pump();
      });
    });

    group('B5 commit calls controller once on drag end', () {
      testWidgets('controller notify count: one for drag end, none mid-drag', (
        tester,
      ) async {
        final c = _h([
          TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
          TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
        ]);
        await tester.pumpWidget(
          _centered(_app(c, theme: _theme(thickness: 4))),
        );
        var notifies = 0;
        c.addListener(() => notifies++);

        final gesture = await tester.startGesture(_dividerCenter(tester));
        await gesture.moveBy(const Offset(10, 0));
        await tester.pump();
        await gesture.moveBy(const Offset(10, 0));
        await tester.pump();
        await gesture.moveBy(const Offset(10, 0));
        await tester.pump();
        expect(notifies, 0);

        await gesture.up();
        await tester.pump();
        expect(notifies, 1);
      });

      testWidgets('dragging visible panes ignores hidden split children', (
        tester,
      ) async {
        const hiddenSize = PlatSize.resizable(initial: .fraction(0.2));
        final c = _h([
          TabGroupNode(
            id: 'left',
            size: const .resizable(initial: .fraction(0.4)),
            tabs: treeTabs([tab('a')]),
          ),
          TabGroupNode(
            id: 'hidden',
            size: hiddenSize,
            tabs: treeTabs([tab('hidden-leaf')]),
          ),
          TabGroupNode(
            id: 'right',
            size: const .resizable(initial: .fraction(0.4)),
            tabs: treeTabs([tab('b')]),
          ),
        ]);
        c.setHidden('hidden', hidden: true);
        await tester.pumpWidget(
          _centered(_app(c, theme: _theme(thickness: 4))),
        );

        final gesture = await tester.startGesture(_dividerCenter(tester));
        await gesture.moveBy(const Offset(20, 0));
        await tester.pump();
        await gesture.up();
        await tester.pump();

        expect(tester.takeException(), isNull);
        final split = c.snapshot('s')! as SplitSnapshot;
        expect(split.children[1].id, 'hidden');
        expect(split.children[1].size, hiddenSize);
      });
    });

    group(
      'C1 split has no LayoutBuilder / Flex / Positioned in its widget tree',
      () {
        testWidgets(
          'the split itself does not compose layout via LayoutBuilder',
          (tester) async {
            final split = await _pumpSplitChrome(tester);

            expect(_splitChromeUses(split, LayoutBuilder), isFalse);
          },
        );

        testWidgets('the split itself does not compose layout via Flex', (
          tester,
        ) async {
          final split = await _pumpSplitChrome(tester);

          expect(_splitChromeUses(split, Flex), isFalse);
        });

        testWidgets('the split itself does not compose layout via Positioned', (
          tester,
        ) async {
          final split = await _pumpSplitChrome(tester);

          expect(_splitChromeUses(split, Positioned), isFalse);
        });
      },
    );

    group('C2 dividers do not own gesture recognizers', () {
      testWidgets(
        'no widget-level Horizontal/VerticalDragGestureRecognizer for dividers',
        (tester) async {
          final c = _h([
            TabGroupNode(id: 'a1', tabs: treeTabs([tab('a')])),
            TabGroupNode(id: 'a2', tabs: treeTabs([tab('b')])),
            TabGroupNode(id: 'a3', tabs: treeTabs([tab('c')])),
          ]);
          await tester.pumpWidget(
            _centered(_app(c, theme: _theme(thickness: 4))),
          );
          final found = find.byWidgetPredicate((widget) {
            if (widget is! RawGestureDetector) return false;
            return widget.gestures.keys.any(
              (type) =>
                  type == HorizontalDragGestureRecognizer ||
                  type == VerticalDragGestureRecognizer,
            );
          });
          expect(found, findsNothing);
        },
      );
    });

    group('C3 cursor without MouseRegion overlay', () {
      testWidgets('no resize-cursor MouseRegion exists during drag', (
        tester,
      ) async {
        final c = _h([
          TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
          TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
        ]);
        await tester.pumpWidget(
          _centered(_app(c, theme: _theme(thickness: 4))),
        );
        final gesture = await tester.startGesture(_dividerCenter(tester));
        await gesture.moveBy(const Offset(20, 0));
        await tester.pump();
        final overlays = find.byWidgetPredicate(
          (widget) =>
              widget is MouseRegion &&
              (widget.cursor == SystemMouseCursors.resizeColumn ||
                  widget.cursor == SystemMouseCursors.resizeRow),
        );
        expect(overlays, findsNothing);
        await gesture.up();
      });
    });

    group('C5 single keyed subtree per child', () {
      testWidgets(
        'each pane has exactly one widget keyed by its id (no double keying)',
        (tester) async {
          final c = _h([
            TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
            TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
          ]);
          await tester.pumpWidget(
            _centered(_app(c, theme: _theme(thickness: 4))),
          );
          final ancestors = find.ancestor(
            of: find.text('body:a'),
            matching: find.byWidgetPredicate(
              (widget) => widget.key == const ValueKey('left'),
            ),
          );
          expect(ancestors, findsOneWidget);
        },
      );
    });

    group('C6 hover does not rebuild leaves', () {
      testWidgets('hovering a divider does not re-invoke leafBuilder', (
        tester,
      ) async {
        final c = _h([
          TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
          TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
        ]);
        var leafBuilds = 0;
        await tester.pumpWidget(
          _centered(
            testHost(
              PlatView(
                controller: c,
                leafBuilder: (_, p) {
                  leafBuilds++;
                  return Center(child: Text('body:${p.title}'));
                },
              ),
            ),
          ),
        );
        final initial = leafBuilds;
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await gesture.moveTo(_dividerCenter(tester));
        await tester.pumpAndSettle();
        expect(leafBuilds, initial);
      });
    });

    group('D1 leaf builder is not invoked during drag', () {
      testWidgets('mid-drag pumps yield zero leaf rebuilds', (tester) async {
        final c = _h([
          TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
          TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
        ]);
        var leafBuilds = 0;
        await tester.pumpWidget(
          _centered(
            testHost(
              PlatView(
                controller: c,
                leafBuilder: (_, p) {
                  leafBuilds++;
                  return Center(child: Text('body:${p.title}'));
                },
              ),
            ),
          ),
        );
        final initial = leafBuilds;
        await _dragDividerInSteps(tester);

        expect(leafBuilds - initial, 0);
      });
    });

    group('D5 children are repaint boundaries', () {
      testWidgets('every visible content child sits under a RepaintBoundary', (
        tester,
      ) async {
        final c = _h([
          TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
          TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
        ]);
        await tester.pumpWidget(
          _centered(_app(c, theme: _theme(thickness: 4))),
        );
        expect(_hasRepaintBoundary(tester, 'a'), isTrue);
        expect(_hasRepaintBoundary(tester, 'b'), isTrue);
      });
    });
  });
}

Widget _app(PlatController c, {PlatThemeData? theme}) {
  Widget child = PlatView(
    controller: c,
    leafBuilder: (_, p) => Center(child: Text('body:${p.title}')),
  );
  if (theme != null) child = PlatTheme(data: theme, child: child);
  return testHost(child);
}

double _bodyWidth(WidgetTester tester, String id) => tester
    .getSize(
      find
          .ancestor(
            of: find.text('body:$id'),
            matching: find.byWidgetPredicate(
              (widget) => widget.key is GlobalKey,
            ),
          )
          .first,
    )
    .width;

Widget _centered(Widget child) =>
    Center(child: SizedBox(width: 600, height: 200, child: child));

Offset _dividerCenter(WidgetTester tester) =>
    tester.getCenter(find.byType(PlatView));

Color _dividerColor(WidgetTester tester) => tester
    .widget<ColoredBox>(
      find.descendant(
        of: find.byType(PlatDivider),
        matching: find.byType(ColoredBox),
      ),
    )
    .color;

Future<void> _dragDividerInSteps(WidgetTester tester) async {
  final gesture = await tester.startGesture(_dividerCenter(tester));
  addTearDown(() async {
    await gesture.up();
  });
  for (var i = 0; i < 10; i++) {
    await gesture.moveBy(const Offset(5, 0));
    await tester.pump();
  }
}

PlatController _h(List<PlatNode> children) => controllerFromTree(
  SplitNode(id: 's', axis: .horizontal, children: children),
);

bool _hasRepaintBoundary(WidgetTester tester, String id) {
  final boundary = find.ancestor(
    of: find.text('body:$id'),
    matching: find.byType(RepaintBoundary),
  );
  return boundary.evaluate().isNotEmpty;
}

Future<Element> _pumpSplitChrome(WidgetTester tester) async {
  final c = _h([
    TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
    TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
  ]);
  await tester.pumpWidget(_centered(_app(c, theme: _theme(thickness: 4))));
  return tester.element(find.byType(SplitRender));
}

bool _splitChromeUses(Element split, Type type) {
  var found = false;
  void walk(Element e) {
    if (found) return;
    if (e.widget.runtimeType == type) {
      found = true;
      return;
    }
    if (e.widget is RepaintBoundary) return;
    e.visitChildren(walk);
  }

  split.visitChildren(walk);
  return found;
}

PlatThemeData _theme({double thickness = 0, double hitSlop = 8}) =>
    PlatThemeData(
      divider: PlatDividerTheme(thickness: thickness, hitSlop: hitSlop),
    );
