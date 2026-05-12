import 'package:meta/meta.dart' show internal;

import '../../controller/controller.dart';
import '../../controller/snapshot_mapping.dart';
import '../../core/foundation/foundation.dart';
import '../../model/plat.dart' show PlatTab;
import '../../model/plat_snapshot.dart';
import 'drag_payload.dart';
import 'drop_attempt.dart';
import 'drop_zone.dart';

@internal
DropOperation? resolveDropOperation({
  required PlatController controller,
  required PlatDragPayload payload,
  required PlatSnapshot target,
  required DropZone zone,
  required DropZone nearestSide,
  required DropPolicy? policy,
}) {
  final operationTarget = switch (payload) {
    TabDragPayload() => _tabOperationTarget(controller, target),
    _ => target,
  };
  final effectiveZone = _effectiveZone(
    payload: payload,
    target: operationTarget,
    zone: zone,
    nearestSide: nearestSide,
  );

  return switch (payload) {
    final LeafDragPayload p => _leafDrop(
      controller,
      p,
      operationTarget,
      effectiveZone,
    ),
    final TabDragPayload p => _tabDrop(
      controller,
      p,
      operationTarget,
      effectiveZone,
      policy,
    ),
  };
}

bool _canMoveLeaf(PlatController controller, String leafId, String targetId) {
  final leafPath = controller.pathTo(leafId);
  final targetPath = controller.pathTo(targetId);
  return leafPath.isNotEmpty &&
      targetPath.isNotEmpty &&
      !leafPath.contains(targetId) &&
      !targetPath.contains(leafId);
}

bool _canSplitTab(
  PlatController controller,
  TabDragPayload payload,
  PlatSnapshot target,
) {
  if (controller.pathTo(target.id).contains(payload.id)) return false;
  if (target.id != payload.sourceTabGroupId) return true;
  final source = controller.snapshot(payload.sourceTabGroupId);
  return source is TabGroupSnapshot && source.tabs.length > 1;
}

DropZone _effectiveZone({
  required PlatDragPayload payload,
  required PlatSnapshot target,
  required DropZone zone,
  required DropZone nearestSide,
}) {
  if (payload is LeafDragPayload &&
      zone == .center &&
      (target is LeafSnapshot || target is SplitSnapshot)) {
    return nearestSide;
  }
  if (payload is TabDragPayload &&
      target is TabGroupSnapshot &&
      target.id == payload.sourceTabGroupId) {
    final source = payload.source.snapshot(target.id);
    if (source is TabGroupSnapshot && source.tabs.length == 1) return .center;
  }
  return zone;
}

DropOperation? _leafDrop(
  PlatController controller,
  LeafDragPayload payload,
  PlatSnapshot target,
  DropZone zone,
) {
  if (payload.leaf.locked || !payload.leaf.draggable) return null;

  final destination = switch ((target, zone)) {
    (final TabGroupSnapshot t, .center) => (
      targetId: t.id,
      insert: (LeafSnapshot leaf) =>
          controller.insertTab(tabGroupId: t.id, tab: _tabFromLeaf(leaf)),
    ),
    (final SlotSnapshot t, .center) when t.child == null => (
      targetId: t.id,
      insert: (LeafSnapshot leaf) =>
          controller.setSlotChild(slotId: t.id, child: leaf.toPane()),
    ),
    (_, .center) => null,
    (_, final edge) => (
      targetId: target.id,
      insert: (LeafSnapshot leaf) => controller.split(
        targetId: target.id,
        side: edge._side,
        sibling: leaf.toPane(),
      ),
    ),
  };
  if (destination == null) return null;
  if (identical(payload.source, controller) &&
      !_canMoveLeaf(controller, payload.id, destination.targetId)) {
    return null;
  }

  return _operation(
    controller,
    payload,
    zone,
    local: () => _moveLeaf(
      controller,
      payload,
      destination.targetId,
      destination.insert,
    ),
    remote: () => destination.insert(payload.leaf),
  );
}

bool _moveLeaf(
  PlatController controller,
  LeafDragPayload payload,
  String targetId,
  bool Function(LeafSnapshot leaf) insert,
) {
  final leaf = controller.snapshot(payload.id);
  if (leaf is! LeafSnapshot ||
      leaf.locked ||
      !leaf.draggable ||
      !_canMoveLeaf(controller, payload.id, targetId)) {
    return false;
  }

  return controller.transaction(() {
    if (!controller.remove(payload.id)) return false;
    final changed = insert(leaf);
    if (changed) controller.focus(payload.id);
    return changed;
  });
}

DropOperation _operation(
  PlatController controller,
  PlatDragPayload payload,
  DropZone zone, {
  required _DropCommit local,
  required _DropCommit remote,
}) => (
  zone: zone,
  accept: identical(payload.source, controller)
      ? local
      : () {
          if (!remote()) return false;
          payload.source.close(payload.id);
          return true;
        },
);

DropOperation? _tabDrop(
  PlatController controller,
  TabDragPayload payload,
  PlatSnapshot target,
  DropZone zone,
  DropPolicy? policy,
) {
  if (identical(payload.source, controller) &&
      zone != .center &&
      !_canSplitTab(controller, payload, target)) {
    return null;
  }

  final mutation = switch ((target, zone)) {
    (final TabGroupSnapshot t, .center) => (
      local: () => t.id == payload.sourceTabGroupId
          ? controller.focus(payload.id)
          : controller.moveTab(tabId: payload.id, tabGroupId: t.id),
      remote: () =>
          controller.insertTab(tabGroupId: t.id, tab: payload.tab.toEntry()),
    ),
    (final SlotSnapshot t, .center) when t.child == null => (
      local: () => controller.moveTabIntoSlot(tabId: payload.id, slotId: t.id),
      remote: () => controller.insertTabIntoSlot(
        slotId: t.id,
        tab: payload.tab.toEntry(),
      ),
    ),
    (_, .center) => null,
    (_, final edge) => (
      local: () => controller.moveTabBeside(
        tabId: payload.id,
        targetId: target.id,
        side: edge._side,
      ),
      remote: () => controller.insertTabBeside(
        targetId: target.id,
        side: edge._side,
        tab: payload.tab.toEntry(),
      ),
    ),
  };
  if (mutation == null) return null;

  if (policy != null &&
      !policy(
        DropAttempt(
          tab: payload.tab,
          target: target,
          zone: zone,
          sourceController: payload.source,
        ),
      )) {
    return null;
  }

  return _operation(
    controller,
    payload,
    zone,
    local: mutation.local,
    remote: mutation.remote,
  );
}

PlatTab _tabFromLeaf(LeafSnapshot leaf) =>
    PlatTab(child: leaf.toPane(), title: leaf.title, locked: leaf.locked);

PlatSnapshot _tabOperationTarget(
  PlatController controller,
  PlatSnapshot target,
) {
  if (target is TabGroupSnapshot) return target;
  final tabGroupId = controller.tabGroupContaining(target.id);
  final tabGroup = tabGroupId == null ? null : controller.snapshot(tabGroupId);
  return tabGroup is TabGroupSnapshot ? tabGroup : target;
}

@internal
typedef DropOperation = ({DropZone zone, _DropCommit accept});

typedef _DropCommit = bool Function();

extension on DropZone {
  PlatSide get _side => switch (this) {
    DropZone.center => throw StateError('center has no structural side'),
    DropZone.left => .left,
    DropZone.right => .right,
    DropZone.top => .top,
    DropZone.bottom => .bottom,
  };
}
