import 'package:meta/meta.dart' show internal;

import '../core/tree/tree.dart';
import '../model/plat_snapshot.dart';

/// Materialises a [LeafNode] from a [LeafSnapshot]. Round-trips every
/// field carried by the snapshot.
@internal
LeafNode leafNodeFromSnapshot(LeafSnapshot s) => LeafNode(
  id: s.id,
  size: s.size,
  hidden: s.hidden,
  maximized: s.maximized,
  data: s.data,
  title: s.title,
  locked: s.locked,
  draggable: s.draggable,
  focused: s.focused,
);

/// Materialises a [PlatNode] from a [PlatSnapshot]. Round-trips the full tree.
@internal
PlatNode platNodeFromSnapshot(PlatSnapshot s) => switch (s) {
  final SplitSnapshot split => SplitNode(
    id: split.id,
    size: split.size,
    hidden: split.hidden,
    maximized: split.maximized,
    axis: split.axis,
    children: [for (final child in split.children) platNodeFromSnapshot(child)],
    resizable: split.resizable,
  ),
  final TabGroupSnapshot tabs => TabGroupNode(
    id: tabs.id,
    size: tabs.size,
    hidden: tabs.hidden,
    maximized: tabs.maximized,
    tabs: [
      for (final tab in tabs.tabs)
        TabNode(
          child: platNodeFromSnapshot(tab.child),
          title: tab.title,
          pinned: tab.pinned,
          locked: tab.locked,
          preview: tab.preview,
        ),
    ],
    activeIndex: tabs.activeIndex,
    acceptsDrops: tabs.acceptsDrops,
    side: tabs.side,
  ),
  final SlotSnapshot slot => SlotNode(
    id: slot.id,
    size: slot.size,
    hidden: slot.hidden,
    maximized: slot.maximized,
    child: slot.child == null ? null : platNodeFromSnapshot(slot.child!),
    persistent: slot.persistent,
    boundsMaximize: slot.boundsMaximize,
  ),
  final LeafSnapshot leaf => leafNodeFromSnapshot(leaf),
};

/// Lifts a tree node into its snapshot variant, recursing into
/// children. The returned [PlatSnapshot] carries no live references
/// back into the tree.
@internal
PlatSnapshot snapshotOf(PlatNode node) => switch (node) {
  final SplitNode s => SplitSnapshot(
    id: s.id,
    size: s.size,
    hidden: s.hidden,
    maximized: s.maximized,
    axis: s.axis,
    children: [for (final child in s.children) snapshotOf(child)],
    resizable: s.resizable,
  ),
  final TabGroupNode t => TabGroupSnapshot(
    id: t.id,
    size: t.size,
    hidden: t.hidden,
    maximized: t.maximized,
    tabs: [
      for (var i = 0; i < t.tabs.length; i++)
        _tabSnapshotOf(t.tabs[i], selected: i == t.activeIndex),
    ],
    activeIndex: t.activeIndex,
    acceptsDrops: t.acceptsDrops,
    side: t.side,
  ),
  final SlotNode s => SlotSnapshot(
    id: s.id,
    size: s.size,
    hidden: s.hidden,
    maximized: s.maximized,
    child: s.child == null ? null : snapshotOf(s.child!),
    persistent: s.persistent,
    boundsMaximize: s.boundsMaximize,
  ),
  final LeafNode l => _leafSnapshotOf(l),
};

LeafSnapshot _leafSnapshotOf(LeafNode l) => LeafSnapshot(
  id: l.id,
  size: l.size,
  hidden: l.hidden,
  maximized: l.maximized,
  data: l.data,
  title: l.title,
  locked: l.locked,
  draggable: l.draggable,
  focused: l.focused,
);

TabSnapshot _tabSnapshotOf(TabNode tab, {required bool selected}) =>
    TabSnapshot(
      id: tab.id,
      title: tab.title,
      pinned: tab.pinned,
      locked: tab.locked,
      preview: tab.preview,
      selected: selected,
      child: snapshotOf(tab.child),
    );
