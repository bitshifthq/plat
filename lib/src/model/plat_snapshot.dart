import 'package:meta/meta.dart' show immutable;

import '../core/foundation/foundation.dart';

T? _firstNonNull<T, V>(Iterable<V> values, T? Function(V value) select) {
  for (final value in values) {
    final hit = select(value);
    if (hit != null) return hit;
  }
  return null;
}

bool _tabsEqual(List<TabSnapshot> a, List<TabSnapshot> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _snapshotsEqual(List<PlatSnapshot> a, List<PlatSnapshot> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Immutable, value-typed view of a layout-tree node.
///
/// Snapshots carry no mutability and no live references; they are safe to
/// compare, hash, and store in widget state for rebuild diffing. The four
/// variants ([SplitSnapshot], [TabGroupSnapshot], [SlotSnapshot],
/// [LeafSnapshot]) mirror the four node kinds.
sealed class PlatSnapshot {
  /// Stable identity, mirroring the underlying node.
  final String id;

  /// True when the node is excluded from layout.
  final bool hidden;

  /// Allocation hint for the parent split.
  final PlatSize size;

  /// True when this node is the one currently maximized within its
  /// scope.
  final bool maximized;

  const PlatSnapshot({
    required this.id,
    required this.size,
    required this.hidden,
    required this.maximized,
  });

  /// The first leaf in this subtree in tree order, or `null` when none exists.
  LeafSnapshot? get firstLeaf => switch (this) {
    final LeafSnapshot leaf => leaf,
    final SplitSnapshot split => _firstNonNull(
      split.children,
      (child) => child.firstLeaf,
    ),
    final TabGroupSnapshot tabs => _firstNonNull(
      tabs.tabs,
      (tab) => tab.firstLeaf,
    ),
    final SlotSnapshot slot => slot.child?.firstLeaf,
  };

  /// The first focused leaf in this subtree, or `null` when none is focused.
  LeafSnapshot? get focusedLeaf => switch (this) {
    final LeafSnapshot leaf => leaf.focused ? leaf : null,
    final SplitSnapshot split => _firstNonNull(
      split.children,
      (child) => child.focusedLeaf,
    ),
    final TabGroupSnapshot tabs => _firstNonNull(
      tabs.tabs,
      (tab) => tab.focusedLeaf,
    ),
    final SlotSnapshot slot => slot.child?.focusedLeaf,
  };
}

/// Snapshot of a leaf node.
///
/// Carries the leaf's [data], [title], and state flags. Two leaf snapshots
/// compare equal when every field matches.
@immutable
final class LeafSnapshot extends PlatSnapshot {
  /// True when the leaf refuses close and drag operations.
  final bool locked;

  /// True when the default UI may expose a handle for dragging this leaf.
  final bool draggable;

  /// True when this leaf currently holds focus.
  final bool focused;

  /// Display label.
  final String title;

  /// Opaque host payload.
  final Object? data;

  const LeafSnapshot({
    required super.id,
    required super.size,
    required super.hidden,
    required super.maximized,
    required this.data,
    required this.title,
    required this.locked,
    required this.draggable,
    required this.focused,
  });

  @override
  int get hashCode => Object.hash(
    id,
    size,
    hidden,
    maximized,
    data,
    title,
    locked,
    draggable,
    focused,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeafSnapshot &&
          other.id == id &&
          other.size == size &&
          other.hidden == hidden &&
          other.maximized == maximized &&
          other.data == data &&
          other.title == title &&
          other.locked == locked &&
          other.draggable == draggable &&
          other.focused == focused;
}

/// Snapshot of a slot node wrapping an optional [child].
@immutable
final class SlotSnapshot extends PlatSnapshot {
  /// True when the slot stays in the tree even after losing its
  /// child.
  final bool persistent;

  /// True when a maximize triggered inside this slot stays bounded
  /// by the slot rather than expanding to fill the whole tree.
  final bool boundsMaximize;

  /// The wrapped snapshot, or `null` when the slot is empty.
  final PlatSnapshot? child;

  const SlotSnapshot({
    required super.id,
    required super.size,
    required super.hidden,
    required super.maximized,
    required this.child,
    required this.persistent,
    required this.boundsMaximize,
  });

  @override
  int get hashCode => Object.hash(
    id,
    size,
    hidden,
    maximized,
    persistent,
    boundsMaximize,
    child,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlotSnapshot &&
          other.id == id &&
          other.size == size &&
          other.hidden == hidden &&
          other.maximized == maximized &&
          other.persistent == persistent &&
          other.boundsMaximize == boundsMaximize &&
          other.child == child;
}

/// Snapshot of a split node arranging [children] along [axis].
@immutable
final class SplitSnapshot extends PlatSnapshot {
  /// Axis children are laid out along.
  final SplitAxis axis;

  /// True when dividers in this split accept drag input.
  final bool resizable;

  /// Children, in order along [axis].
  final List<PlatSnapshot> children;

  const SplitSnapshot({
    required super.id,
    required super.size,
    required super.hidden,
    required super.maximized,
    required this.axis,
    required this.children,
    required this.resizable,
  });

  @override
  int get hashCode => Object.hash(
    id,
    size,
    hidden,
    maximized,
    axis,
    resizable,
    Object.hashAll(children),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitSnapshot &&
          other.id == id &&
          other.size == size &&
          other.hidden == hidden &&
          other.maximized == maximized &&
          other.axis == axis &&
          other.resizable == resizable &&
          _snapshotsEqual(other.children, children);
}

/// Snapshot of a tab group.
@immutable
final class TabSnapshot {
  /// Stable identity of the wrapped tab child.
  final String id;

  /// Display label shown in chrome.
  final String title;

  /// True when the tab is presented as pinned.
  final bool pinned;

  /// True when the tab refuses close and drag operations.
  final bool locked;

  /// True when the tab is the preview tab for its containing tab group.
  final bool preview;

  /// True when this tab is active in its group.
  /// Mirrors `i == TabGroupSnapshot.activeIndex` so callers can dispatch
  /// without the parent snapshot.
  final bool selected;

  /// Child subtree rendered when this tab is active.
  final PlatSnapshot child;

  const TabSnapshot({
    required this.id,
    required this.title,
    required this.pinned,
    required this.locked,
    required this.preview,
    required this.selected,
    required this.child,
  });

  /// Convenience payload from a leaf-rooted tab or the first leaf in a nested
  /// subtree.
  Object? get data => switch (child) {
    final LeafSnapshot leaf => leaf.data,
    _ => firstLeaf?.data,
  };

  /// The first leaf in this tab's subtree, or `null` when none exists.
  LeafSnapshot? get firstLeaf => child.firstLeaf;

  /// True when any leaf in this tab's subtree currently holds focus.
  ///
  /// Aggregates [LeafSnapshot.focused] over the active subtree: for a
  /// leaf-rooted tab this is `true` iff the wrapped leaf is focused.
  bool get focused => focusedLeaf != null;

  /// The first focused leaf in this tab's subtree,
  /// or `null` when none is focused.
  LeafSnapshot? get focusedLeaf => child.focusedLeaf;

  @override
  int get hashCode =>
      Object.hash(id, title, pinned, locked, preview, selected, child);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TabSnapshot &&
          other.id == id &&
          other.title == title &&
          other.pinned == pinned &&
          other.locked == locked &&
          other.preview == preview &&
          other.selected == selected &&
          other.child == child;
}

/// Snapshot of a tab group.
@immutable
final class TabGroupSnapshot extends PlatSnapshot {
  /// Index of the active tab, or `0` when [tabs] is empty.
  final int activeIndex;

  /// Edge of the body where the tab bar sits.
  final TabBarSide side;

  /// True when this group's body accepts tab drops from other groups or views.
  final bool acceptsDrops;

  /// The tabs managed by this group, in display order.
  final List<TabSnapshot> tabs;

  const TabGroupSnapshot({
    required super.id,
    required super.size,
    required super.hidden,
    required super.maximized,
    required this.tabs,
    required this.activeIndex,
    required this.acceptsDrops,
    required this.side,
  });

  /// The focused leaf in the active tab, or that tab's first leaf when
  /// unfocused.
  LeafSnapshot? get activeLeaf =>
      activeTab == null ? null : activeTab!.focusedLeaf ?? activeTab!.firstLeaf;

  /// The currently active tab, or `null` when [tabs] is empty.
  TabSnapshot? get activeTab => tabs.isEmpty ? null : tabs[activeIndex];

  @override
  int get hashCode => Object.hash(
    id,
    size,
    hidden,
    maximized,
    activeIndex,
    acceptsDrops,
    side,
    Object.hashAll(tabs),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TabGroupSnapshot &&
          other.id == id &&
          other.size == size &&
          other.hidden == hidden &&
          other.maximized == maximized &&
          other.activeIndex == activeIndex &&
          other.acceptsDrops == acceptsDrops &&
          other.side == side &&
          _tabsEqual(other.tabs, tabs);
}
