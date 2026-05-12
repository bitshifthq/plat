import 'package:flutter/gestures.dart' show PointerDeviceKind, kTouchSlop;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plat/plat.dart';

import '../../../helpers.dart';
import '../ui_test_helpers.dart';

void main() {
  group('PlatTabGroupView', () {
    group('TB1/TB3 drop position follows the pointer', () {
      testWidgets('hovering at the bar far-left commits at insertAt = 0', (
        tester,
      ) async {
        final c = _threeTabs();
        await tester.pumpWidget(_app(c));

        final source = tester.getCenter(find.text('a'));
        final drag = await _dragTo(
          tester,
          from: source,
          to: const Offset(2, 16),
        );
        await drag.up();
        await tester.pump();
        await tester.pump();
        expect(_ids(c), ['a', 'b', 'c']);
      });

      testWidgets('hovering past the last chip commits at insertAt = length', (
        tester,
      ) async {
        final c = _threeTabs();
        await tester.pumpWidget(_app(c));

        final source = tester.getCenter(find.text('a'));
        final cCenter = tester.getCenter(find.text('c'));
        final drag = await _dragTo(
          tester,
          from: source,
          to: Offset(cCenter.dx + 40, 16),
        );
        await drag.up();
        await tester.pump();
        await tester.pump();
        expect(_ids(c), ['b', 'c', 'a']);
      });

      testWidgets('hovering mid-gap between b and c commits between b and c', (
        tester,
      ) async {
        final c = _threeTabs();
        await tester.pumpWidget(_app(c));

        final source = tester.getCenter(find.text('a'));
        final bCenter = tester.getCenter(find.text('b'));
        final cCenter = tester.getCenter(find.text('c'));
        final between = Offset((bCenter.dx + cCenter.dx) / 2, 16);
        final drag = await _dragTo(tester, from: source, to: between);
        await drag.up();
        await tester.pump();
        await tester.pump();
        expect(_ids(c), ['b', 'a', 'c']);
      });
    });

    group('TB2 source chip is excluded from nearest-gap', () {
      testWidgets(
        'dragging the leftmost chip back to its original position keeps order',
        (tester) async {
          final c = _threeTabs();
          await tester.pumpWidget(_app(c));

          final source = tester.getCenter(find.text('a'));
          final drag = await _dragTo(
            tester,
            from: source,
            to: Offset(tester.getTopLeft(find.text('b')).dx - 2, 16),
          );
          await drag.up();
          await tester.pump();
          await tester.pump();
          expect(_ids(c), ['a', 'b', 'c']);
        },
      );
    });

    group('TB5 placeholder lands at preview index', () {
      testWidgets('a default placeholder appears during a hover', (
        tester,
      ) async {
        final c = _threeTabs();
        await tester.pumpWidget(
          _app(
            c,
            tabBuilder: (ctx, tab) {
              final dragged = tab.states.contains(WidgetState.dragged);
              final selected = tab.states.contains(WidgetState.selected);
              return SizedBox(
                width: 60,
                child: Text(
                  '${tab.snapshot.title}:'
                  '${selected ? 'selected' : 'inactive'}:'
                  '${dragged ? 'dragged' : 'idle'}',
                ),
              );
            },
          ),
        );

        final source = tester.getCenter(find.text('a:selected:idle'));
        final bCenter = tester.getCenter(find.text('b:inactive:idle'));
        final drag = await _dragTo(
          tester,
          from: source,
          to: Offset(bCenter.dx, bCenter.dy),
        );

        expect(
          find.descendant(
            of: find.byType(PlatTabBar),
            matching: find.text('a:inactive:dragged'),
          ),
          findsOneWidget,
        );
        await drag.up();
        await tester.pump();
      });

      testWidgets('placeholder keeps the host-built tab shape', (tester) async {
        final c = _threeTabs();
        await tester.pumpWidget(
          _app(
            c,
            tabBuilder: (ctx, tab) => tab.snapshot.id == 'a'
                ? ClipRRect(
                    key: const ValueKey('shape:a'),
                    borderRadius: BorderRadius.circular(8),
                    child: const ColoredBox(
                      color: Color(0xFF3366FF),
                      child: SizedBox(width: 64, height: 20),
                    ),
                  )
                : Text(tab.snapshot.title),
            placeholderBuilder: (ctx, tab) => tab.snapshot.id == 'a'
                ? Stack(
                    fit: StackFit.passthrough,
                    children: [
                      ClipRRect(
                        key: const ValueKey('placeholder:a'),
                        borderRadius: BorderRadius.circular(8),
                        child: const ColoredBox(
                          color: Color(0x663366FF),
                          child: SizedBox(width: 64, height: 20),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        );

        final source = tester.getCenter(find.byKey(const ValueKey('shape:a')));
        final bCenter = tester.getCenter(find.text('b'));
        final drag = await _dragTo(
          tester,
          from: source,
          to: Offset(bCenter.dx, bCenter.dy),
        );

        expect(find.byKey(const ValueKey('placeholder:a')), findsOneWidget);
        await drag.up();
        await tester.pump();
      });

      testWidgets('tabBar tab builders can provide custom placeholders', (
        tester,
      ) async {
        final c = _threeTabs();
        await tester.pumpWidget(
          _app(
            c,
            tabBar: (_, tabs) => PlatTabBar(
              tabBuilder: (_, tab) => Text('wrapped:${tab.snapshot.id}'),
              placeholderBuilder: (_, tab) => KeyedSubtree(
                key: ValueKey('wrapped-placeholder:${tab.snapshot.id}'),
                child: const Stack(
                  fit: StackFit.passthrough,
                  children: [
                    Positioned.fill(
                      child: ColoredBox(color: Color(0x22000000)),
                    ),
                  ],
                ),
              ),
              trailing: const SizedBox.shrink(),
            ),
          ),
        );

        final source = tester.getCenter(find.text('wrapped:a'));
        final bCenter = tester.getCenter(find.text('wrapped:b'));
        final drag = await _dragTo(
          tester,
          from: source,
          to: Offset(bCenter.dx, bCenter.dy),
        );

        expect(
          find.byKey(const ValueKey('wrapped-placeholder:a')),
          findsOneWidget,
        );
        await drag.up();
        await tester.pump();
      });
    });

    group('TBL6 tabBuilder is not invoked for chips during drag moves', () {
      testWidgets('multiple moves yield zero new chip-state rebuilds', (
        tester,
      ) async {
        var chipBuilds = 0;
        final c = _threeTabs();
        await tester.pumpWidget(
          _app(
            c,
            tabBuilder: (ctx, tab) {
              if (tab.snapshot.id != 'a') chipBuilds++;
              return Text(tab.snapshot.title);
            },
          ),
        );

        final source = tester.getCenter(find.text('a'));
        final bCenter = tester.getCenter(find.text('b'));
        final cCenter = tester.getCenter(find.text('c'));
        final drag = await _dragTo(tester, from: source, to: bCenter);
        final afterStart = chipBuilds;

        await drag.moveTo(Offset((bCenter.dx + cCenter.dx) / 2, 16));
        await tester.pump();
        await drag.moveTo(cCenter);
        await tester.pump();
        await drag.moveTo(bCenter);
        await tester.pump();

        expect(chipBuilds - afterStart, 0);
        await drag.up();
        await tester.pump();
      });
    });

    group('drag interaction state', () {
      testWidgets('same-group inactive tab drag clears stale hover state', (
        tester,
      ) async {
        final c = _threeTabs();
        await tester.pumpWidget(
          _app(
            c,
            tabBuilder: (_, tab) {
              final hovered = tab.states.contains(WidgetState.hovered);
              final pressed = tab.states.contains(WidgetState.pressed);
              return Text('${tab.snapshot.id}:$hovered:$pressed');
            },
          ),
        );

        final source = tester.getCenter(find.text('b:false:false'));
        final drag = await _dragTo(
          tester,
          from: source,
          to: Offset(580, source.dy),
          kind: PointerDeviceKind.mouse,
        );
        await drag.up();
        await tester.pump();
        await tester.pump();

        expect(find.textContaining('b:true'), findsNothing);
        expect(find.text('b:false:false'), findsOneWidget);
      });

      testWidgets('same-group no-op tab drop activates the dragged tab', (
        tester,
      ) async {
        final c = _threeTabs();
        await tester.pumpWidget(_app(c));

        final source = tester.getCenter(find.text('b'));
        final drag = await _dragTo(
          tester,
          from: source,
          to: Offset(source.dx, 2),
          kind: PointerDeviceKind.mouse,
        );
        await drag.up();
        await tester.pump();
        await tester.pump();

        expect(c.activeTabId(c.rootId), 'b');
        expect(c.focusedLeaf?.id, 'b');
      });
    });

    group('TB7/TB8 no GlobalKey is allocated for chips', () {
      testWidgets('the rendered tree contains no per-chip GlobalKey', (
        tester,
      ) async {
        final c = _threeTabs();
        await tester.pumpWidget(_app(c));

        expect(_chipGlobalKeyCount(tester), 0);
      });
    });

    group('vertical drop math', () {
      testWidgets(
        'a left-side tab bar resolves the insertion index from the y axis',
        (tester) async {
          final c = _threeTabs();
          c.setTabBarSide(c.rootId, .left);
          await tester.pumpWidget(_app(c));

          final source = tester.getCenter(find.text('a'));
          final bCenter = tester.getCenter(find.text('b'));
          final cCenter = tester.getCenter(find.text('c'));
          final between = Offset(bCenter.dx, (bCenter.dy + cCenter.dy) / 2);
          final drag = await _dragTo(tester, from: source, to: between);
          await drag.up();
          await tester.pump();
          await tester.pump();
          expect(_ids(c), ['b', 'a', 'c']);
        },
      );

      testWidgets(
        'a right-side tab bar resolves insertion past the last chip',
        (tester) async {
          final c = _threeTabs();
          c.setTabBarSide(c.rootId, .right);
          await tester.pumpWidget(_app(c));

          final source = tester.getCenter(find.text('a'));
          final cCenter = tester.getCenter(find.text('c'));
          final drag = await _dragTo(
            tester,
            from: source,
            to: Offset(cCenter.dx, cCenter.dy + 40),
          );
          await drag.up();
          await tester.pump();
          await tester.pump();
          expect(_ids(c), ['b', 'c', 'a']);
        },
      );
    });

    group('tab bar drop gates', () {
      testWidgets('tab bar drops honor the host drop policy', (tester) async {
        final c = _twoGroups();
        final attempts = <DropAttempt>[];
        await tester.pumpWidget(
          _app(
            c,
            dropPolicy: (attempt) {
              attempts.add(attempt);
              return attempt.target.id == 'source';
            },
          ),
        );

        final drag = await _dragTo(
          tester,
          from: tester.getCenter(find.text('a')),
          to: tester.getCenter(find.text('x')),
        );
        await drag.up();
        await tester.pump();
        await tester.pump();

        expect(attempts.map((a) => a.target.id), contains('target'));
        expect(_tabIds(c, 'source'), ['a', 'b']);
        expect(_tabIds(c, 'target'), ['x']);
      });

      testWidgets('tab bars with acceptsDrops false reject dragged tabs', (
        tester,
      ) async {
        final c = _threeTabs(acceptsDrops: false);
        await tester.pumpWidget(_app(c));

        final drag = await _dragTo(
          tester,
          from: tester.getCenter(find.text('a')),
          to: Offset(tester.getCenter(find.text('c')).dx + 40, 16),
        );
        await drag.up();
        await tester.pump();
        await tester.pump();

        expect(_ids(c), ['a', 'b', 'c']);
      });
    });
  });
}

Widget _app(
  PlatController c, {
  PlatTabBarBuilder? tabBar,
  PlatTabBuilder? tabBuilder,
  PlatTabBuilder? placeholderBuilder,
  DropPolicy? dropPolicy,
}) {
  return testHost(
    SizedBox(
      width: 600,
      height: 200,
      child: PlatView(
        controller: c,
        leafBuilder: (_, p) => Center(child: Text('body:${p.title}')),
        dropPolicy: dropPolicy,
        tabBar:
            tabBar ??
            (tabBuilder == null
                ? null
                : (_, tabs) => PlatTabBar(
                    tabBuilder: tabBuilder,
                    placeholderBuilder: placeholderBuilder,
                  )),
      ),
    ),
  );
}

int _chipGlobalKeyCount(WidgetTester tester) {
  var count = 0;
  void visit(Element element) {
    final key = element.widget.key;
    if (key is GlobalKey && key.toString().contains('tab:')) count++;
    element.visitChildren(visit);
  }

  visit(tester.element(find.byType(PlatView)));
  return count;
}

Future<TestGesture> _dragTo(
  WidgetTester tester, {
  required Offset from,
  required Offset to,
  PointerDeviceKind kind = PointerDeviceKind.touch,
}) async {
  final gesture = await tester.startGesture(from, kind: kind);
  await tester.pump();
  final delta = to - from;
  final dist = delta.distance;
  final stepX = (delta.dx / dist) * (kTouchSlop + 1);
  final stepY = (delta.dy / dist) * (kTouchSlop + 1);
  await gesture.moveBy(Offset(stepX, stepY));
  await tester.pump();
  await gesture.moveTo(to);
  await tester.pump();
  return gesture;
}

List<String> _ids(PlatController c) => [
  for (final leaf
      in (c.snapshot(c.tabGroupIds.first)! as TabGroupSnapshot).tabs)
    leaf.id,
];

List<String> _tabIds(PlatController c, String id) => [
  for (final tab in (c.snapshot(id)! as TabGroupSnapshot).tabs) tab.id,
];

PlatController _threeTabs({bool acceptsDrops = true}) => PlatController(
  initialPlat: .tabs(
    [tabPane('a'), tabPane('b'), tabPane('c')],
    id: generateNodeId(),
    acceptsDrops: acceptsDrops,
  ),
);

PlatController _twoGroups() => PlatController(
  initialPlat: .row(
    children: [
      .tabs([tabPane('a'), tabPane('b')], id: 'source'),
      .tabs([tabPane('x')], id: 'target'),
    ],
  ),
);
