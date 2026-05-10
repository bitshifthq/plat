import 'package:meta/meta.dart';

import '../model/plat.dart';
import '../model/plat_snapshot.dart';

/// Reconstructs declarative model values from immutable snapshots.
@internal
extension PlatSnapshotMapping on PlatSnapshot {
  /// Rebuilds the declarative [Plat] subtree represented by this snapshot.
  Plat toPane() => switch (this) {
    final SplitSnapshot split => PlatSplit(
      id: split.id,
      size: split.size,
      axis: split.axis,
      children: [for (final child in split.children) child.toPane()],
      resizable: split.resizable,
    ),
    final TabGroupSnapshot tabs => PlatTabGroup(
      [for (final tab in tabs.tabs) tab.toEntry()],
      id: tabs.id,
      size: tabs.size,
      activeIndex: tabs.activeIndex,
      acceptsDrops: tabs.acceptsDrops,
      side: tabs.side,
    ),
    final SlotSnapshot slot => PlatSlot(
      id: slot.id,
      size: slot.size,
      child: slot.child?.toPane(),
      persistent: slot.persistent,
      boundsMaximize: slot.boundsMaximize,
    ),
    final LeafSnapshot leaf => PlatLeaf(
      id: leaf.id,
      size: leaf.size,
      data: leaf.data,
      title: leaf.title,
      locked: leaf.locked,
      draggable: leaf.draggable,
    ),
  };
}

/// Reconstructs declarative tab values from immutable snapshots.
@internal
extension TabSnapshotMapping on TabSnapshot {
  /// Rebuilds the declarative [PlatTab] represented by this snapshot.
  PlatTab toEntry() => PlatTab(
    child: child.toPane(),
    title: title,
    pinned: pinned,
    locked: locked,
    preview: preview,
  );
}
