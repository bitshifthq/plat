import 'package:plat/plat.dart';
import 'package:plat/src/core/tree/tree.dart';

export 'package:plat/src/core/tree/tree.dart';
export 'package:plat/src/model/plat_snapshot.dart' show SplitSnapshot;

Plat asLayout(PlatNode node) => switch (node) {
  final LeafNode leaf => PlatLeaf(
    id: leaf.id,
    size: leaf.size,
    data: leaf.data,
    title: leaf.title,
    locked: leaf.locked,
    draggable: leaf.draggable,
  ),
  final TabGroupNode tabs => PlatTabGroup(
    [for (final tab in tabs.tabs) _tabToEntry(tab)],
    id: tabs.id,
    size: tabs.size,
    activeIndex: tabs.activeIndex,
    acceptsDrops: tabs.acceptsDrops,
    side: tabs.side,
  ),
  final SplitNode split => PlatSplit(
    id: split.id,
    axis: split.axis,
    children: [for (final child in split.children) asLayout(child)],
    size: split.size,
    resizable: split.resizable,
  ),
  final SlotNode slot => PlatSlot(
    id: slot.id,
    size: slot.size,
    child: slot.child == null ? null : asLayout(slot.child!),
    persistent: slot.persistent,
    boundsMaximize: slot.boundsMaximize,
  ),
};

PlatController controllerFromLeaves(List<LeafNode> leaves) => PlatController(
  initialPlat: .tabs([
    for (final leaf in leaves) _tabEntryFromLeaf(leaf),
  ], id: generateNodeId()),
);

PlatController controllerFromTree(PlatNode root) =>
    PlatController(initialPlat: asLayout(root));

SplitNode hSplit(String id, List<PlatNode> children) =>
    SplitNode(id: id, axis: .horizontal, children: children);

LeafNode tab(String id, {bool locked = false}) =>
    LeafNode(id: id, title: id, locked: locked);

PlatTab tabPane(
  String id, {
  bool pinned = false,
  bool locked = false,
  bool preview = false,
}) => _tabPane(
  id: id,
  title: id,
  pinned: pinned,
  locked: locked,
  preview: preview,
);

PlatTab tabPaneWith({
  String? id,
  String title = '',
  Object? data,
  bool pinned = false,
  bool locked = false,
  bool preview = false,
}) => _tabPane(
  id: id,
  title: title,
  data: data,
  pinned: pinned,
  locked: locked,
  preview: preview,
);

TabNode treeTab(
  String id, {
  bool pinned = false,
  bool locked = false,
  bool preview = false,
}) => TabNode(
  child: tab(id),
  title: id,
  pinned: pinned,
  locked: locked,
  preview: preview,
);

List<TabNode> treeTabs(Iterable<LeafNode> leaves) => [
  for (final leaf in leaves)
    TabNode(child: leaf, title: leaf.title, locked: leaf.locked),
];

Iterable<String> _leafIdsInSnapshot(PlatSnapshot snapshot) sync* {
  switch (snapshot) {
    case final LeafSnapshot leaf:
      yield leaf.id;
    case final SplitSnapshot split:
      for (final child in split.children) {
        yield* _leafIdsInSnapshot(child);
      }
    case final TabGroupSnapshot tabs:
      for (final tab in tabs.tabs) {
        yield* _leafIdsInSnapshot(tab.child);
      }
    case final SlotSnapshot slot:
      final child = slot.child;
      if (child != null) yield* _leafIdsInSnapshot(child);
  }
}

PlatTab _tabEntryFromLeaf(LeafNode leaf) => PlatTab(
  child: .leaf(
    id: leaf.id,
    size: leaf.size,
    data: leaf.data,
    title: leaf.title,
    locked: leaf.locked,
  ),
  title: leaf.title,
  locked: leaf.locked,
);

Iterable<String> _tabGroupIdsInSnapshot(PlatSnapshot snapshot) sync* {
  switch (snapshot) {
    case LeafSnapshot():
      break;
    case final SplitSnapshot split:
      for (final child in split.children) {
        yield* _tabGroupIdsInSnapshot(child);
      }
    case final TabGroupSnapshot tabs:
      yield tabs.id;
      for (final tab in tabs.tabs) {
        yield* _tabGroupIdsInSnapshot(tab.child);
      }
    case final SlotSnapshot slot:
      final child = slot.child;
      if (child != null) yield* _tabGroupIdsInSnapshot(child);
  }
}

PlatTab _tabPane({
  required String? id,
  required String title,
  Object? data,
  required bool pinned,
  required bool locked,
  required bool preview,
}) => PlatTab(
  child: .leaf(id: id, data: data, title: title, locked: locked),
  title: title,
  pinned: pinned,
  locked: locked,
  preview: preview,
);

PlatTab _tabToEntry(TabNode tab) => PlatTab(
  child: asLayout(tab.child),
  title: tab.title,
  pinned: tab.pinned,
  locked: tab.locked,
  preview: tab.preview,
);

extension PlatControllerTestIds on PlatController {
  Iterable<String> get leafIds => _leafIdsInSnapshot(root);

  String get rootId => root.id;

  Iterable<String> get tabGroupIds => _tabGroupIdsInSnapshot(root);
}
