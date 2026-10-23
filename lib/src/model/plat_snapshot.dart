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
sealed class const PlatSnapshot({
  /// Stable identity, mirroring the underlying node.
  required final String id,

  /// Allocation hint for the parent split.
  required final PlatSize size,

  /// True when the node is excluded from layout.
  required final bool hidden,

  /// True when this node is the one currently maximized within its
  /// scope.
  required final bool maximized,
}) {
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
final class const LeafSnapshot({
  required super.id,
  required super.size,
  required super.hidden,
  required super.maximized,

  /// Opaque host payload.
  required final Object? data,

  /// Display label.
  required final String title,

  /// True when the leaf refuses close and drag operations.
  required final bool locked,

  /// True when the default UI may expose a handle for dragging this leaf.
  required final bool draggable,

  /// True when this leaf currently holds focus.
  required final bool focused,
}) extends PlatSnapshot {
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
  bool operator ==(Object other) {
    return identical(this, other) ||
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
}

/// Snapshot of a slot node wrapping an optional [child].
@immutable
final class const SlotSnapshot({
  required super.id,
  required super.size,
  required super.hidden,
  required super.maximized,

  /// The wrapped snapshot, or `null` when the slot is empty.
  required final PlatSnapshot? child,

  /// True when the slot stays in the tree even after losing its
  /// child.
  required final bool persistent,

  /// True when a maximize triggered inside this slot stays bounded
  /// by the slot rather than expanding to fill the whole tree.
  required final bool boundsMaximize,
}) extends PlatSnapshot {
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
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SlotSnapshot &&
            other.id == id &&
            other.size == size &&
            other.hidden == hidden &&
            other.maximized == maximized &&
            other.persistent == persistent &&
            other.boundsMaximize == boundsMaximize &&
            other.child == child;
  }
}

/// Snapshot of a split node arranging [children] along [axis].
@immutable
final class const SplitSnapshot({
  required super.id,
  required super.size,
  required super.hidden,
  required super.maximized,

  /// Axis children are laid out along.
  required final SplitAxis axis,

  /// Children, in order along [axis].
  required final List<PlatSnapshot> children,

  /// True when dividers in this split accept drag input.
  required final bool resizable,
}) extends PlatSnapshot {
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
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SplitSnapshot &&
            other.id == id &&
            other.size == size &&
            other.hidden == hidden &&
            other.maximized == maximized &&
            other.axis == axis &&
            other.resizable == resizable &&
            _snapshotsEqual(other.children, children);
  }
}

/// Snapshot of a tab group.
@immutable
final class const TabSnapshot({
  /// Stable identity of the wrapped tab child.
  required final String id,

  /// Display label shown in chrome.
  required final String title,

  /// True when the tab is presented as pinned.
  required final bool pinned,

  /// True when the tab refuses close and drag operations.
  required final bool locked,

  /// True when the tab is the preview tab for its containing tab group.
  required final bool preview,

  /// True when this tab is active in its group.
  /// Mirrors `i == TabGroupSnapshot.activeIndex` so callers can dispatch
  /// without the parent snapshot.
  required final bool selected,

  /// Child subtree rendered when this tab is active.
  required final PlatSnapshot child,
}) {
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
  int get hashCode {
    return Object.hash(id, title, pinned, locked, preview, selected, child);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TabSnapshot &&
            other.id == id &&
            other.title == title &&
            other.pinned == pinned &&
            other.locked == locked &&
            other.preview == preview &&
            other.selected == selected &&
            other.child == child;
  }
}

/// Snapshot of a tab group.
@immutable
final class const TabGroupSnapshot({
  required super.id,
  required super.size,
  required super.hidden,
  required super.maximized,

  /// The tabs managed by this group, in display order.
  required final List<TabSnapshot> tabs,

  /// Index of the active tab, or `0` when [tabs] is empty.
  required final int activeIndex,

  /// True when this group's body accepts tab drops from other groups or views.
  required final bool acceptsDrops,

  /// Edge of the body where the tab bar sits.
  required final TabBarSide side,
}) extends PlatSnapshot {
  /// The focused leaf in the active tab, or that tab's first leaf when
  /// unfocused.
  LeafSnapshot? get activeLeaf {
    return activeTab == null
        ? null
        : activeTab!.focusedLeaf ?? activeTab!.firstLeaf;
  }

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
  bool operator ==(Object other) {
    return identical(this, other) ||
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
}
