import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plat/plat.dart';
import 'package:plat/src/ui/drop/drag_payload.dart';
import 'package:plat/src/ui/drop/drop_operation.dart';

import '../../../helpers.dart';
import '../ui_test_helpers.dart';

void main() {
  group('DropOverlay', () {
    testWidgets(
      'rejected cross-view center drops leave both controllers unchanged',
      (tester) async {
        final source = controllerFromLeaves([tab('a')]);
        final destination = controllerFromLeaves([tab('b')]);
        addTearDown(source.dispose);
        addTearDown(destination.dispose);

        final attempts = <DropAttempt>[];
        await _pumpTwoViews(
          tester,
          source: source,
          destination: destination,
          destinationPolicy: (attempt) {
            attempts.add(attempt);
            return false;
          },
        );

        await _dragTabTo(tester, 'a', tester.getCenter(find.text('body:b')));

        expect(_leafValues(source), ['a']);
        expect(_leafValues(destination), ['b']);

        final attempt = attempts.last;
        expect(attempt.tab.id, 'a');
        expect(attempt.target.id, destination.rootId);
        expect(attempt.zone, DropZone.center);
        expect(identical(attempt.sourceController, source), isTrue);
      },
    );

    testWidgets('accepted cross-view center drops move the tab', (
      tester,
    ) async {
      final source = controllerFromLeaves([tab('a')]);
      final destination = controllerFromLeaves([tab('b')]);
      addTearDown(source.dispose);
      addTearDown(destination.dispose);

      await _pumpTwoViews(
        tester,
        source: source,
        destination: destination,
        destinationPolicy: (_) => true,
      );

      await _dragTabTo(tester, 'a', tester.getCenter(find.text('body:b')));

      expect(source.leafIds, isEmpty);
      expect(_leafValues(destination), ['b', 'a']);
    });

    testWidgets('edge hovers report structural zones to the policy', (
      tester,
    ) async {
      final source = controllerFromLeaves([tab('a')]);
      final destination = controllerFromLeaves([tab('b')]);
      addTearDown(source.dispose);
      addTearDown(destination.dispose);

      final attempts = <DropAttempt>[];
      await _pumpTwoViews(
        tester,
        source: source,
        destination: destination,
        destinationPolicy: (attempt) {
          attempts.add(attempt);
          return false;
        },
      );

      final target = tester.getTopLeft(
        find.byKey(const ValueKey('view:right')),
      );
      await _dragTabTo(tester, 'a', target + const Offset(6, 120));

      expect(attempts.last.zone, DropZone.left);
      expect(attempts.last.target.id, destination.rootId);
    });

    testWidgets(
      'cross-view edge drops keep the source when destination insert no-ops',
      (tester) async {
        final source = PlatController(
          initialPlat: .tabs([
            tabPaneWith(id: 'right', title: 'source-tab'),
          ], id: 'source'),
        );
        final destination = PlatController(
          initialPlat: .tabs([tabPaneWith(id: 'b', title: 'b')], id: 'right'),
        );
        addTearDown(source.dispose);
        addTearDown(destination.dispose);

        await _pumpTwoViews(
          tester,
          source: source,
          destination: destination,
          destinationPolicy: (_) => true,
        );

        final target = tester.getTopLeft(
          find.byKey(const ValueKey('view:right')),
        );
        await _dragTabTo(tester, 'source-tab', target + const Offset(6, 120));

        expect(_leafValues(source), ['right']);
        expect(_leafValues(destination), ['b']);
      },
    );

    testWidgets(
      'cross-view tab bar drops keep the source when destination insert fails',
      (tester) async {
        final source = PlatController(
          initialPlat: .tabs([
            tabPaneWith(id: 'right', title: 'source-tab'),
          ], id: 'source'),
        );
        final destination = PlatController(
          initialPlat: .tabs([tabPaneWith(id: 'b', title: 'b')], id: 'right'),
        );
        addTearDown(source.dispose);
        addTearDown(destination.dispose);

        await _pumpTwoViews(
          tester,
          source: source,
          destination: destination,
          destinationPolicy: (_) => true,
        );

        await _dragTabTo(
          tester,
          'source-tab',
          tester.getCenter(find.text('b')),
        );

        expect(_leafValues(source), ['right']);
        expect(_leafValues(destination), ['b']);
      },
    );

    testWidgets('cross-view center drops honor destination replace policy', (
      tester,
    ) async {
      final source = PlatController(
        initialPlat: .tabs([
          tabPaneWith(id: 'b', title: 'source-tab'),
        ], id: 'source'),
      );
      final destination = PlatController(
        idConflict: .replace,
        initialPlat: .tabs([
          tabPaneWith(id: 'b', title: 'destination-tab'),
        ], id: 'destination'),
      );
      addTearDown(source.dispose);
      addTearDown(destination.dispose);

      await _pumpTwoViews(
        tester,
        source: source,
        destination: destination,
        destinationPolicy: (_) => true,
      );

      await _dragTabTo(
        tester,
        'source-tab',
        tester.getCenter(find.text('body:b').last),
      );

      expect(source.leafIds, isEmpty);
      final tabs =
          destination.snapshot(destination.rootId)! as TabGroupSnapshot;
      expect(tabs.tabs, hasLength(1));
      expect(tabs.tabs.single.title, 'source-tab');
    });

    testWidgets('same-view tab body edge drops split beside the tab group', (
      tester,
    ) async {
      final controller = controllerFromLeaves([tab('a'), tab('b')]);
      addTearDown(controller.dispose);
      controller.focus('b');

      await _pumpOneView(tester, controller);

      final bodyCenter = tester.getCenter(find.text('body:b'));
      final viewLeft = tester.getTopLeft(find.byKey(const ValueKey('view'))).dx;
      await _dragTabTo(tester, 'a', Offset(viewLeft + 6, bodyCenter.dy));

      final root = controller.root;
      expect(root, isA<SplitSnapshot>());
      final split = root as SplitSnapshot;
      expect(split.children, hasLength(2));

      final left = split.children[0] as TabGroupSnapshot;
      final right = split.children[1] as TabGroupSnapshot;
      expect(left.tabs.single.id, 'a');
      expect(right.tabs.single.id, 'b');
    });

    testWidgets('same-view tab body center drops activate the dragged tab', (
      tester,
    ) async {
      final controller = controllerFromLeaves([tab('a'), tab('b')]);
      addTearDown(controller.dispose);

      await _pumpOneView(tester, controller);

      await _dragTabTo(tester, 'b', tester.getCenter(find.text('body:a')));

      final tabs = controller.snapshot(controller.rootId)! as TabGroupSnapshot;
      expect(tabs.tabs.map((tab) => tab.id).toList(), ['a', 'b']);
      expect(tabs.activeTab?.id, 'b');
      expect(controller.focusedLeaf?.id, 'b');
    });

    test('same-controller leaf center drop wraps the leaf as a tab', () {
      final controller = PlatController(
        initialPlat: .row(
          id: 'root',
          children: [
            const .leaf(id: 'leaf', title: 'leaf', draggable: true),
            .tabs([tabPane('tab')], id: 'tabs'),
          ],
        ),
      );
      addTearDown(controller.dispose);

      final operation = resolveDropOperation(
        controller: controller,
        payload: _leafPayload(controller, 'leaf'),
        target: controller.snapshot('tabs')!,
        zone: DropZone.center,
        nearestSide: DropZone.left,
        policy: null,
      );

      expect(operation, isNotNull);
      operation!.accept();

      final tabs = controller.snapshot('tabs')! as TabGroupSnapshot;
      expect(tabs.tabs.map((tab) => tab.id).toList(), ['tab', 'leaf']);
    });

    test('same-controller leaf edge drop splits beside another leaf', () {
      final controller = PlatController(
        initialPlat: .tabs([_draggableTab('a'), tabPane('b')], id: 'tabs'),
      );
      addTearDown(controller.dispose);

      final operation = resolveDropOperation(
        controller: controller,
        payload: _leafPayload(controller, 'a'),
        target: controller.snapshot('b')!,
        zone: DropZone.right,
        nearestSide: DropZone.right,
        policy: null,
      );

      expect(operation, isNotNull);
      operation!.accept();

      final tabs = controller.snapshot(controller.rootId)! as TabGroupSnapshot;
      final split = tabs.tabs.single.child as SplitSnapshot;
      expect(split.axis, SplitAxis.horizontal);
      expect(split.children.map((child) => child.id).toList(), ['b', 'a']);
    });

    test('same-controller leaf center drop fills an empty slot', () {
      final controller = PlatController(
        initialPlat: .row(
          id: 'root',
          children: [
            const .slot(id: 'slot', persistent: true),
            .tabs([_draggableTab('a')], id: 'tabs'),
          ],
        ),
      );
      addTearDown(controller.dispose);

      final operation = resolveDropOperation(
        controller: controller,
        payload: _leafPayload(controller, 'a'),
        target: controller.snapshot('slot')!,
        zone: DropZone.center,
        nearestSide: DropZone.left,
        policy: null,
      );

      expect(operation, isNotNull);
      operation!.accept();

      final slot = controller.snapshot('slot')! as SlotSnapshot;
      expect(slot.child, isA<LeafSnapshot>());
      expect(slot.child!.id, 'a');
    });

    test('same-controller leaf drops on its own ancestor are rejected', () {
      final controller = PlatController(
        initialPlat: .row(
          id: 'root',
          children: [
            const .leaf(id: 'leaf', title: 'leaf', draggable: true),
            .tabs([tabPane('tab')]),
          ],
        ),
      );
      addTearDown(controller.dispose);

      final operation = resolveDropOperation(
        controller: controller,
        payload: _leafPayload(controller, 'leaf'),
        target: controller.snapshot('root')!,
        zone: DropZone.right,
        nearestSide: DropZone.right,
        policy: null,
      );

      expect(operation, isNull);
      expect(controller.leafIds.toList(), ['leaf', 'tab']);
    });
  });
}

Future<void> _dragTabTo(WidgetTester tester, String tabLabel, Offset to) async {
  final from = tester.getCenter(find.text(tabLabel));
  final gesture = await tester.startGesture(from);
  await tester.pump();

  final delta = to - from;
  final distance = delta.distance;
  final lead = Offset(
    (delta.dx / distance) * (kTouchSlop + 1),
    (delta.dy / distance) * (kTouchSlop + 1),
  );

  await gesture.moveBy(lead);
  await tester.pump();
  await gesture.moveTo(to);
  await tester.pump();
  await gesture.up();
  await tester.pump();
}

List<String> _leafValues(PlatController controller) => [
  for (final id in controller.leafIds) id,
];

LeafDragPayload _leafPayload(PlatController controller, String id) {
  final snapshot = controller.snapshot(id);
  if (snapshot is! LeafSnapshot) {
    throw StateError('Expected "$id" to resolve to a draggable leaf.');
  }
  return LeafDragPayload(leaf: snapshot, source: controller);
}

PlatTab _draggableTab(String id) => PlatTab(
  child: .leaf(id: id, title: id, draggable: true),
  title: id,
);

Future<void> _pumpOneView(
  WidgetTester tester,
  PlatController controller,
) async {
  await tester.pumpWidget(
    testHost(
      SizedBox(
        width: 320,
        height: 240,
        child: PlatView(
          key: const ValueKey('view'),
          controller: controller,
          leafBuilder: (_, leaf) => Center(child: Text('body:${leaf.id}')),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpTwoViews(
  WidgetTester tester, {
  required PlatController source,
  required PlatController destination,
  DropPolicy? destinationPolicy,
}) async {
  await tester.pumpWidget(
    testHost(
      SizedBox(
        width: 640,
        height: 240,
        child: Row(
          children: [
            Expanded(
              child: PlatView(
                key: const ValueKey('view:left'),
                controller: source,
                leafBuilder: (_, leaf) =>
                    Center(child: Text('body:${leaf.id}')),
              ),
            ),
            Expanded(
              child: PlatView(
                key: const ValueKey('view:right'),
                controller: destination,
                dropPolicy: destinationPolicy,
                leafBuilder: (_, leaf) =>
                    Center(child: Text('body:${leaf.id}')),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}
