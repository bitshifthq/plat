import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plat/plat.dart';
import 'package:plat/src/ui/drop/drag_payload.dart';
import 'package:plat/src/ui/split.dart';

import '../../helpers.dart';
import 'ui_test_helpers.dart';

void main() {
  group('PlatView', () {
    group('rendering', () {
      testWidgets('only the active tab body renders (IndexedStack)', (
        tester,
      ) async {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        await tester.pumpWidget(_app(c));

        expect(find.text('body:a'), findsOneWidget);
        expect(find.text('body:b'), findsNothing);

        c.focus('b');
        await tester.pump();
        expect(find.text('body:a'), findsNothing);
        expect(find.text('body:b'), findsOneWidget);
      });

      testWidgets('split renders both children', (tester) async {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        c.focus('b');
        c.splitActiveTab(tabGroupId: c.rootId, side: .right);
        await tester.pumpWidget(_app(c));

        expect(find.text('body:a'), findsOneWidget);
        expect(find.text('body:b'), findsOneWidget);
      });

      testWidgets('renders a newly added leaf after a controller mutation', (
        tester,
      ) async {
        final c = controllerFromLeaves([tab('a')]);
        await tester.pumpWidget(_app(c));
        expect(find.text('body:a'), findsOneWidget);

        c.insertTab(tabGroupId: c.rootId, tab: tabPane('b'));
        await tester.pump();
        expect(find.text('body:b'), findsOneWidget);
      });

      testWidgets('tap on tab activates and focuses it', (tester) async {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        await tester.pumpWidget(_app(c));

        await tester.tap(find.text('b'));
        await tester.pump();
        expect(find.text('body:b'), findsOneWidget);
        expect(c.focusedLeaf?.id, 'b');
      });

      testWidgets('Leaf is rendered via leafBuilder when standalone', (
        tester,
      ) async {
        final c = controllerFromTree(
          SplitNode(
            id: 's',
            axis: .horizontal,
            children: [
              const LeafNode(id: 'tree', data: 'project-tree'),
              TabGroupNode(id: 'editor', tabs: treeTabs([tab('a')])),
            ],
          ),
        );
        await tester.pumpWidget(
          testHost(
            PlatView(
              controller: c,
              leafBuilder: (_, p) => p.data is String
                  ? Center(child: Text('panel:${p.data}'))
                  : Text('body:${p.title}'),
            ),
          ),
        );
        expect(find.text('panel:project-tree'), findsOneWidget);
        expect(find.text('body:a'), findsOneWidget);
      });

      testWidgets('draggable leaves reveal a drag handle near the top center', (
        tester,
      ) async {
        final c = PlatController(
          initialPlat: .row(
            children: [
              const .leaf(id: 'drag', title: 'drag', draggable: true),
              .tabs([tabPane('tab')]),
            ],
          ),
        );
        await tester.pumpWidget(
          SizedBox(width: 300, height: 200, child: _app(c)),
        );

        expect(find.byType(Draggable<LeafDragPayload>), findsNothing);

        final leafHost = _leafHostFinder('drag');
        final target =
            tester.getTopLeft(leafHost) +
            Offset(tester.getSize(leafHost).width / 2, 8);
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: target);
        await gesture.moveTo(target);
        await tester.pump();

        expect(find.byType(Draggable<LeafDragPayload>), findsOneWidget);
        await gesture.removePointer();
      });

      testWidgets('non-draggable leaves do not reveal a drag handle', (
        tester,
      ) async {
        final c = PlatController(
          initialPlat: .row(
            children: [
              const .leaf(id: 'drag', title: 'drag'),
              .tabs([tabPane('tab')]),
            ],
          ),
        );
        await tester.pumpWidget(
          SizedBox(width: 300, height: 200, child: _app(c)),
        );

        final leafHost = _leafHostFinder('drag');
        final target =
            tester.getTopLeft(leafHost) +
            Offset(tester.getSize(leafHost).width / 2, 8);
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: target);
        await gesture.moveTo(target);
        await tester.pump();

        expect(find.byType(Draggable<LeafDragPayload>), findsNothing);
        await gesture.removePointer();
      });

      testWidgets('draggable leaf handle reserves a top strip', (tester) async {
        final c = PlatController(
          initialPlat: .row(
            children: [
              const .leaf(id: 'drag', title: 'drag', draggable: true),
              .tabs([tabPane('tab')]),
            ],
          ),
        );
        await tester.pumpWidget(
          SizedBox(width: 300, height: 200, child: _app(c)),
        );

        final viewTop = tester.getTopLeft(find.byType(PlatView)).dy;
        final leafTop = tester.getTopLeft(_leafHostFinder('drag')).dy;

        expect(leafTop - viewTop, closeTo(4, 0.5));
      });

      testWidgets('draggable leaf handle wins over adjacent split divider', (
        tester,
      ) async {
        final c = PlatController(
          initialPlat: const .column(
            children: [
              .leaf(id: 'top', title: 'top'),
              .leaf(id: 'bottom', title: 'bottom', draggable: true),
            ],
          ),
        );
        await tester.pumpWidget(
          SizedBox(width: 300, height: 200, child: _app(c)),
        );

        final leafHost = _leafHostFinder('bottom');
        final target =
            tester.getTopLeft(leafHost) +
            Offset(tester.getSize(leafHost).width / 2, 2);
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: target);
        await gesture.moveTo(target);
        await tester.pumpAndSettle();

        expect(find.byType(Draggable<LeafDragPayload>), findsOneWidget);
        await gesture.removePointer();
      });

      testWidgets(
        'leaf handle drops on its own ancestor leave the tree intact',
        (tester) async {
          final c = PlatController(
            initialPlat: .row(
              id: 'root',
              children: [
                const .leaf(id: 'drag', title: 'drag', draggable: true),
                .tabs([tabPane('tab')]),
              ],
            ),
          );
          await tester.pumpWidget(
            SizedBox(width: 300, height: 200, child: _app(c)),
          );

          final leafHost = _leafHostFinder('drag');
          final revealAt =
              tester.getTopLeft(leafHost) +
              Offset(tester.getSize(leafHost).width / 2, 4);
          final hover = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await hover.addPointer(location: revealAt);
          await hover.moveTo(revealAt);
          await tester.pump();

          final from = tester.getCenter(
            find.byType(Draggable<LeafDragPayload>),
          );
          final to =
              tester.getTopRight(find.byType(PlatView)) + const Offset(-2, 2);
          final drag = await tester.startGesture(from);
          await drag.moveTo(to);
          await tester.pump();
          await drag.up();
          await hover.removePointer();
          await tester.pump();

          expect(c.leafIds.toList(), ['drag', 'tab']);
          expect(c.snapshot('root'), isA<SplitSnapshot>());
        },
      );
    });

    group('tab bar slots', () {
      testWidgets('tabBar renders the supplied widget in each group', (
        tester,
      ) async {
        final c = controllerFromLeaves([tab('a')]);
        await tester.pumpWidget(
          _app(
            c,
            tabBar: (_, tabs) => const PlatTabBar(
              leading: Text('lead'),
              trailing: Text('trail'),
            ),
          ),
        );

        expect(find.text('lead'), findsOneWidget);
        expect(find.text('trail'), findsOneWidget);
      });

      testWidgets('tabBar builder receives the surrounding group', (
        tester,
      ) async {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        c.focus('b');
        c.splitActiveTab(tabGroupId: c.rootId, side: .right);
        final left =
            (c.snapshot(c.rootId)! as SplitSnapshot).children.first
                as TabGroupSnapshot;
        final right =
            (c.snapshot(c.rootId)! as SplitSnapshot).children.last
                as TabGroupSnapshot;

        await tester.pumpWidget(
          _app(
            c,
            tabBar: (_, tabs) => PlatTabBar(trailing: Text('trail:${tabs.id}')),
          ),
        );

        expect(find.text('trail:${left.id}'), findsOneWidget);
        expect(find.text('trail:${right.id}'), findsOneWidget);
      });

      testWidgets('inline tabs leading and trailing render', (tester) async {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        await tester.pumpWidget(
          _app(
            c,
            tabBar: (_, tabs) => const PlatTabBar(
              stripLeading: Text('inlineL'),
              stripTrailing: Text('inlineT'),
            ),
          ),
        );

        expect(find.text('inlineL'), findsOneWidget);
        expect(find.text('inlineT'), findsOneWidget);
      });

      testWidgets(
        'tab data changes rebuild tab chrome without rebuilding parent split',
        (tester) async {
          final c = PlatController(
            initialPlat: .row(
              id: 'split',
              children: [
                .tabs([
                  tabPaneWith(id: 'a', title: 'a', data: 'before'),
                ], id: 'left'),
                .tabs([
                  tabPaneWith(id: 'b', title: 'b', data: 'stable'),
                ], id: 'right'),
              ],
            ),
          );
          await tester.pumpWidget(
            testHost(
              PlatView(
                controller: c,
                leafBuilder: (_, p) => Center(child: Text('body:${p.title}')),
                tabBar: (_, _) => PlatTabBar(
                  tabBuilder: (_, tab) => Text('tab:${tab.snapshot.data}'),
                ),
              ),
            ),
          );
          final splitBefore = tester.widget<SplitRender>(
            find.byType(SplitRender),
          );

          expect(find.text('tab:before'), findsOneWidget);

          c.replace(
            .row(
              id: 'split',
              children: [
                .tabs([
                  tabPaneWith(id: 'a', title: 'a', data: 'after'),
                ], id: 'left'),
                .tabs([
                  tabPaneWith(id: 'b', title: 'b', data: 'stable'),
                ], id: 'right'),
              ],
            ),
          );
          await tester.pump();

          expect(find.text('tab:after'), findsOneWidget);
          expect(find.text('tab:before'), findsNothing);
          expect(
            tester.widget<SplitRender>(find.byType(SplitRender)),
            same(splitBefore),
          );
        },
      );

      testWidgets('split layout changes rebuild the parent split', (
        tester,
      ) async {
        final c = _twoSidedController();
        await tester.pumpWidget(_app(c));
        final splitBefore = tester.widget<SplitRender>(
          find.byType(SplitRender),
        );

        c.setSize('left', const .fixed(.pixel(160)));
        await tester.pump();

        expect(
          tester.widget<SplitRender>(find.byType(SplitRender)),
          isNot(same(splitBefore)),
        );
      });
    });

    group('hidden children', () {
      testWidgets('a hidden child is excluded from layout', (tester) async {
        final c = _twoSidedController();
        await tester.pumpWidget(_app(c));
        expect(find.text('body:a'), findsOneWidget);
        expect(find.text('body:b'), findsOneWidget);

        c.setHidden('right', hidden: true);
        await tester.pump();
        expect(find.text('body:b'), findsNothing);

        c.setHidden('right', hidden: false);
        await tester.pump();
        expect(find.text('body:b'), findsOneWidget);
      });

      testWidgets('toggleHidden flips visibility', (tester) async {
        final c = _twoSidedController();
        await tester.pumpWidget(_app(c));

        c.setHidden('left', hidden: true);
        await tester.pump();
        expect(find.text('body:a'), findsNothing);

        c.setHidden('left', hidden: false);
        await tester.pump();
        expect(find.text('body:a'), findsOneWidget);
      });
    });

    group('sizing', () {
      testWidgets('FixedSize gives a child its exact pixel extent', (
        tester,
      ) async {
        final c = controllerFromTree(
          SplitNode(
            id: 's',
            axis: .horizontal,
            children: [
              TabGroupNode(
                id: 'left',
                size: const .fixed(.pixel(120)),
                tabs: treeTabs([tab('a')]),
              ),
              TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
            ],
          ),
        );
        await tester.pumpWidget(
          SizedBox(width: 600, height: 200, child: _app(c)),
        );
        final leftWidth = _bodyWidth(tester, 'a');
        expect(leftWidth, lessThanOrEqualTo(120));
        expect(find.text('body:b'), findsOneWidget);
      });
    });

    group('divider drag', () {
      testWidgets('moves visually in sync with the mouse', (tester) async {
        final c = _dividerController();
        await tester.pumpWidget(_centered(_app(c)));

        final before = _bodyWidth(tester, 'a');
        await tester.drag(_dividerFinder(), const Offset(200, 0));
        await tester.pump();
        expect(_bodyWidth(tester, 'a') - before, closeTo(200, 0.5));
      });

      testWidgets('tracks the pointer 1:1 from the very first pixel', (
        tester,
      ) async {
        final c = _dividerController();
        await tester.pumpWidget(_centered(_app(c)));

        final before = _bodyWidth(tester, 'a');
        await tester.drag(_dividerFinder(), const Offset(5, 0));
        await tester.pump();
        expect(_bodyWidth(tester, 'a') - before, closeTo(5, 0.5));
      });

      testWidgets('clamps at min/max and resumes on drag-back', (tester) async {
        final c = controllerFromTree(
          SplitNode(
            id: 's',
            axis: .horizontal,
            children: [
              TabGroupNode(
                id: 'left',
                size: const .resizable(
                  initial: .fraction(0.5),
                  max: .fraction(0.6),
                ),
                tabs: treeTabs([tab('a')]),
              ),
              TabGroupNode(
                id: 'right',
                size: const .resizable(initial: .fraction(0.5)),
                tabs: treeTabs([tab('b')]),
              ),
            ],
          ),
        );
        await tester.pumpWidget(_centered(_app(c)));

        final before = _bodyWidth(tester, 'a');
        final gesture = await tester.startGesture(
          tester.getCenter(_dividerFinder()),
        );
        await gesture.moveBy(const Offset(200, 0));
        await tester.pump();
        final clamped = _bodyWidth(tester, 'a');
        await gesture.moveBy(const Offset(-160, 0));
        await tester.pump();
        final resumed = _bodyWidth(tester, 'a');
        await gesture.up();

        expect(clamped, lessThanOrEqualTo(360.5));
        expect(clamped, greaterThan(before));
        expect(resumed, closeTo(before + 40, 0.5));
      });
    });

    group('maximize render root', () {
      testWidgets('no maximize: renders all leaves', (tester) async {
        final c = _twoSidedController();
        await tester.pumpWidget(_app(c));
        expect(find.text('body:a'), findsOneWidget);
        expect(find.text('body:b'), findsOneWidget);
      });

      testWidgets('maximize a leaf: renders only that leaf', (tester) async {
        final c = _twoSidedController();
        await tester.pumpWidget(_app(c));
        c.setMaximized('a', maximized: true);
        await tester.pump();
        expect(find.text('body:a'), findsOneWidget);
        expect(find.text('body:b'), findsNothing);
      });

      testWidgets(
        'maximize inside boundsMaximize SlotNode: renders the SlotNode',
        (tester) async {
          final c = controllerFromTree(
            SplitNode(
              id: 'outer',
              axis: .horizontal,
              children: [
                TabGroupNode(id: 'sidebar', tabs: treeTabs([tab('s')])),
                SlotNode(
                  id: 'editors',
                  persistent: true,
                  boundsMaximize: true,
                  child: SplitNode(
                    id: 'inner',
                    axis: .horizontal,
                    children: [
                      TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
                      TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
                    ],
                  ),
                ),
              ],
            ),
          );
          await tester.pumpWidget(_app(c));
          c.setMaximized('a', maximized: true);
          await tester.pump();
          expect(find.text('body:s'), findsNothing);
          expect(find.text('body:a'), findsOneWidget);
          expect(find.text('body:b'), findsOneWidget);
        },
      );

      testWidgets('maximize outside boundsMaximize SlotNode: renders alone', (
        tester,
      ) async {
        final c = controllerFromTree(
          SplitNode(
            id: 'outer',
            axis: .horizontal,
            children: [
              TabGroupNode(id: 'sidebar', tabs: treeTabs([tab('s')])),
              SlotNode(
                id: 'editors',
                persistent: true,
                boundsMaximize: true,
                child: TabGroupNode(id: 'inner', tabs: treeTabs([tab('a')])),
              ),
            ],
          ),
        );
        await tester.pumpWidget(_app(c));
        c.setMaximized('sidebar', maximized: true);
        await tester.pump();
        expect(find.text('body:s'), findsOneWidget);
        expect(find.text('body:a'), findsNothing);
      });
    });

    group('leaf state preservation', () {
      testWidgets('moveTab into a different group keeps leaf state', (
        tester,
      ) async {
        final c = controllerFromTree(
          SplitNode(
            id: 's',
            axis: .horizontal,
            children: [
              TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
              TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
            ],
          ),
        );
        await tester.pumpWidget(_counterApp(c));

        await tester.tap(find.byKey(const ValueKey('bump:a')));
        await tester.tap(find.byKey(const ValueKey('bump:a')));
        await tester.pump();
        expect(_counterValue(tester, 'a'), 2);

        c.moveTab(tabId: 'a', tabGroupId: 'right');
        await tester.pump();

        expect(_counterValue(tester, 'a'), 2);
      });

      testWidgets('splitActiveTab keeps leaf state', (tester) async {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        c.focus('a');
        await tester.pumpWidget(_counterApp(c));

        await tester.tap(find.byKey(const ValueKey('bump:a')));
        await tester.tap(find.byKey(const ValueKey('bump:a')));
        await tester.tap(find.byKey(const ValueKey('bump:a')));
        await tester.pump();
        expect(_counterValue(tester, 'a'), 3);

        c.splitActiveTab(tabGroupId: c.rootId, side: .right);
        await tester.pump();

        expect(_counterValue(tester, 'a'), 3);
      });

      testWidgets('moveTabBeside keeps leaf state', (tester) async {
        final c = controllerFromTree(
          SplitNode(
            id: 's',
            axis: .horizontal,
            children: [
              TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
              TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
            ],
          ),
        );
        await tester.pumpWidget(_counterApp(c));

        await tester.tap(find.byKey(const ValueKey('bump:a')));
        await tester.pump();
        expect(_counterValue(tester, 'a'), 1);

        c.moveTabBeside(tabId: 'a', targetId: 'right', side: .right);
        await tester.pump();

        expect(_counterValue(tester, 'a'), 1);
      });

      testWidgets(
        'splitActiveTab on a tab whose child is a split keeps leaf state',
        (tester) async {
          final c = controllerFromTree(
            TabGroupNode(
              id: 'tabs',
              tabs: [
                TabNode(
                  title: 'a',
                  child: SplitNode(
                    id: 'col-a',
                    axis: .vertical,
                    children: [tab('editor-a'), tab('terminal-a')],
                  ),
                ),
                TabNode(
                  title: 'b',
                  child: SplitNode(
                    id: 'col-b',
                    axis: .vertical,
                    children: [tab('editor-b'), tab('terminal-b')],
                  ),
                ),
              ],
            ),
          );
          c.focus('terminal-a');
          await tester.pumpWidget(_counterApp(c));

          await tester.tap(find.byKey(const ValueKey('bump:terminal-a')));
          await tester.tap(find.byKey(const ValueKey('bump:terminal-a')));
          await tester.pump();
          expect(_counterValue(tester, 'terminal-a'), 2);

          c.splitActiveTab(tabGroupId: 'tabs', side: .right);
          await tester.pump();

          expect(_counterValue(tester, 'terminal-a'), 2);
        },
      );

      testWidgets('moveTabIntoSlot keeps leaf state', (tester) async {
        final c = controllerFromTree(
          SplitNode(
            id: 's',
            axis: .horizontal,
            children: [
              TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
              SlotNode(id: 'slot', persistent: true),
            ],
          ),
        );
        await tester.pumpWidget(_counterApp(c));

        await tester.tap(find.byKey(const ValueKey('bump:a')));
        await tester.tap(find.byKey(const ValueKey('bump:a')));
        await tester.pump();
        expect(_counterValue(tester, 'a'), 2);

        c.moveTabIntoSlot(tabId: 'a', slotId: 'slot');
        await tester.pump();

        expect(_counterValue(tester, 'a'), 2);
      });

      testWidgets('closing and reinserting a leaf resets its widget state', (
        tester,
      ) async {
        final c = controllerFromLeaves([tab('a')]);
        await tester.pumpWidget(_counterApp(c));

        await tester.tap(find.byKey(const ValueKey('bump:a')));
        await tester.tap(find.byKey(const ValueKey('bump:a')));
        await tester.pump();
        expect(_counterValue(tester, 'a'), 2);

        c.close('a');
        await tester.pump();
        expect(find.byKey(const ValueKey('bump:a')), findsNothing);

        c.insertTab(tabGroupId: c.rootId, tab: tabPane('a'));
        await tester.pump();

        expect(_counterValue(tester, 'a'), 0);
      });

      testWidgets('shared PlatScope preserves state across views', (
        tester,
      ) async {
        final left = controllerFromLeaves([tab('a')]);
        final right = controllerFromLeaves([tab('b')]);
        await tester.pumpWidget(_sharedCounterApp(left, right));

        await tester.tap(find.byKey(const ValueKey('bump:a')));
        await tester.tap(find.byKey(const ValueKey('bump:a')));
        await tester.pump();
        expect(_counterValue(tester, 'a'), 2);

        right.insertTab(tabGroupId: right.rootId, tab: tabPane('a'));
        left.close('a');
        await tester.pump();

        expect(_counterValue(tester, 'a'), 2);
      });

      testWidgets('standalone PlatView creates a local PlatScope', (
        tester,
      ) async {
        final c = controllerFromTree(
          SplitNode(
            id: 's',
            axis: .horizontal,
            children: [
              TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
              TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
            ],
          ),
        );
        await tester.pumpWidget(_bareCounterApp(c));

        await tester.tap(find.byKey(const ValueKey('bump:a')));
        await tester.tap(find.byKey(const ValueKey('bump:a')));
        await tester.pump();
        expect(_counterValue(tester, 'a'), 2);

        c.moveTab(tabId: 'a', tabGroupId: 'right');
        await tester.pump();

        expect(_counterValue(tester, 'a'), 2);
      });

      testWidgets('separate scopes do not preserve state across views', (
        tester,
      ) async {
        final left = controllerFromLeaves([tab('a')]);
        final right = controllerFromLeaves([tab('b')]);
        await tester.pumpWidget(_splitScopeCounterApp(left, right));

        await tester.tap(find.byKey(const ValueKey('bump:a')));
        await tester.tap(find.byKey(const ValueKey('bump:a')));
        await tester.pump();
        expect(_counterValue(tester, 'a'), 2);

        right.insertTab(tabGroupId: right.rootId, tab: tabPane('a'));
        left.close('a');
        await tester.pump();

        expect(_counterValue(tester, 'a'), 0);
      });
    });

    group('SlotNode rendering', () {
      testWidgets('persistent empty SlotNode renders via the slot builder', (
        tester,
      ) async {
        final c = _twoSidedController(persistentLeft: true);
        await tester.pumpWidget(_app(c, slotBuilder: _slotLabel));

        expect(find.text('empty:left-slot'), findsNothing);

        c.close('a');
        await tester.pump();

        expect(find.text('empty:left-slot'), findsOneWidget);
        expect(find.text('body:b'), findsOneWidget);
      });

      testWidgets(
        'persistent SlotNode wrapping a SplitNode renders the slot builder '
        'when all descendant leaves are gone',
        (tester) async {
          final c = controllerFromTree(
            SplitNode(
              id: 'outer',
              axis: .vertical,
              children: [
                SlotNode(
                  id: 'editor-root',
                  persistent: true,
                  child: SplitNode(
                    id: 'editor-splits',
                    axis: .horizontal,
                    children: [
                      TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
                      TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
                    ],
                  ),
                ),
                TabGroupNode(id: 'terminal', tabs: treeTabs([tab('t')])),
              ],
            ),
          );
          await tester.pumpWidget(_app(c, slotBuilder: _slotLabel));

          c.close('a');
          c.close('b');
          await tester.pump();

          expect(find.text('empty:editor-root'), findsOneWidget);
          expect(find.text('body:t'), findsOneWidget);
        },
      );

      testWidgets('non-persistent TabGroupNode is pruned (no slot rendered)', (
        tester,
      ) async {
        final c = _twoSidedController();
        await tester.pumpWidget(_app(c, slotBuilder: _slotLabel));

        c.close('a');
        await tester.pump();

        expect(find.text('empty:left-slot'), findsNothing);
        expect(find.text('body:b'), findsOneWidget);
      });
    });
  });
}

Widget _app(
  PlatController c, {
  PlatTabBarBuilder? tabBar,
  SlotBuilder? slotBuilder,
}) => testHost(
  PlatView(
    controller: c,
    leafBuilder: (_, p) => Center(child: Text('body:${p.title}')),
    tabBar: tabBar,
    slotBuilder: slotBuilder,
  ),
);

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

Finder _leafHostFinder(String id) => find
    .ancestor(
      of: find.text('body:$id'),
      matching: find.byWidgetPredicate((widget) => widget.key is GlobalKey),
    )
    .first;

Widget _centered(Widget child) =>
    Center(child: SizedBox(width: 600, height: 200, child: child));

PlatController _dividerController() => controllerFromTree(
  SplitNode(
    id: 's',
    axis: .horizontal,
    children: [
      TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
      TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
    ],
  ),
);

Finder _dividerFinder() => find.byType(PlatView);

Widget _slotLabel(BuildContext context, SlotSnapshot slot, Widget? child) =>
    child ?? Text('empty:${slot.id}');

Widget _counterApp(PlatController c) => testHost(
  PlatView(
    controller: c,
    leafBuilder: (_, p) => _Counter(label: p.title),
  ),
);

Widget _sharedCounterApp(PlatController left, PlatController right) => testHost(
  SizedBox(
    width: 600,
    height: 240,
    child: PlatScope(
      child: Row(
        children: [
          Expanded(
            child: PlatView(
              controller: left,
              autofocus: false,
              leafBuilder: (_, p) => _Counter(label: p.title),
            ),
          ),
          Expanded(
            child: PlatView(
              controller: right,
              autofocus: false,
              leafBuilder: (_, p) => _Counter(label: p.title),
            ),
          ),
        ],
      ),
    ),
  ),
  overlay: false,
);

Widget _bareCounterApp(PlatController c) => testHost(
  SizedBox(
    width: 600,
    height: 240,
    child: PlatView(
      controller: c,
      leafBuilder: (_, p) => _Counter(label: p.title),
    ),
  ),
  overlay: false,
);

Widget _splitScopeCounterApp(PlatController left, PlatController right) =>
    testHost(
      SizedBox(
        width: 600,
        height: 240,
        child: Row(
          children: [
            Expanded(
              child: PlatView(
                controller: left,
                autofocus: false,
                leafBuilder: (_, p) => _Counter(label: p.title),
              ),
            ),
            Expanded(
              child: PlatView(
                controller: right,
                autofocus: false,
                leafBuilder: (_, p) => _Counter(label: p.title),
              ),
            ),
          ],
        ),
      ),
    );

int _counterValue(WidgetTester tester, String label) => tester
    .state<_CounterState>(
      find.byWidgetPredicate(
        (widget) => widget is _Counter && widget.label == label,
      ),
    )
    .count;

PlatController _twoSidedController({bool persistentLeft = false}) =>
    controllerFromTree(
      SplitNode(
        id: 's',
        axis: .horizontal,
        children: [
          if (persistentLeft)
            SlotNode(
              id: 'left-slot',
              persistent: true,
              child: TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
            )
          else
            TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
          TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
        ],
      ),
    );

class _Counter extends StatefulWidget {
  final String label;

  const _Counter({required this.label});

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  var count = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('bump:${widget.label}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => count += 1),
      child: Center(child: Text('count:${widget.label}:$count')),
    );
  }
}
