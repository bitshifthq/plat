import 'package:flutter/foundation.dart' show ChangeNotifier, ValueGetter;
import 'package:meta/meta.dart' show internal;

import '../core/tree/tree.dart';
import '../model/plat.dart';
import '../model/plat_snapshot.dart';
import 'lowering.dart';
import 'snapshot_builder.dart';
import 'snapshot_mapping.dart';

part 'controller_impl.dart';

/// Owner of a layout tree.
///
/// `PlatController` holds the current tree, applies mutations, and notifies
/// listeners on every change. It also tracks undo / redo history (capped by
/// [PlatController.new]'s `undoLimit`) and a most-recently-focused leaf list
/// (capped by `recentLimit`).
///
/// ```dart
/// final controller = PlatController(
///   initialPlat: .tabs(
///     [.leaf(id: 'main.dart', title: 'main.dart')],
///     id: 'editors',
///   ),
/// );
///
/// controller
///   ..insertTab(
///     tabGroupId: 'editors',
///     tab: .leaf(id: 'readme', title: 'README.md'),
///   )
///   ..focus('main.dart');
/// ```
///
/// State observation is split between cheap id-based queries
/// ([focusedLeafId], [focusedTabGroupId], [maximizedId], [firstTabGroupId],
/// [activeTabId], [nextTabGroupId], [contains], [pathTo],
/// [tabGroupContaining], [parentOf]), and immutable snapshot reads
/// ([root], [snapshot], [focusedLeaf]).
///
/// Mutations come in three flavours:
///
/// - **Recorded** mutations push an undo entry. Most do, including
///   [insertTab], [insertSplitChild], [setSlotChild], [close],
///   [insertTabBeside], [insertTabIntoSlot], [moveTab],
///   [moveTabBeside], [moveTabIntoSlot], [reorderTab], [remove],
///   [resizeSplit], [setSize], [split], [splitActiveTab], [setPinned],
///   [setLocked], [setPreview], and [replace].
/// - **Transient** mutations don't, because they're routinely flipped
///   back: [focus], [setMaximized], and [setTabBarSide].
/// - **Grouped** mutations bundle a sequence into a single undo entry
///   via [transaction].
abstract base class PlatController extends ChangeNotifier {
  /// Creates a controller seeded from [initialPlat] (or empty when omitted).
  ///
  /// [undoLimit] caps the depth of the undo and redo stacks (default `100`).
  /// [recentLimit] caps the most-recently-focused leaf list used by
  /// close-time refocus (default `200`). [idConflict] decides how external
  /// attach mutations handle incoming ids that already exist in this controller
  /// (default [IdConflict.reject]). [replace] ignores [idConflict] because
  /// it swaps the whole tree.
  factory PlatController({
    Plat? initialPlat,
    int undoLimit,
    int recentLimit,
    IdConflict idConflict,
  }) = PlatControllerImpl;

  PlatController._base();

  /// True when [redo] would do something.
  bool get canRedo;

  /// True when [undo] would do something.
  bool get canUndo;

  /// Snapshot of the currently focused leaf, or `null` when nothing is focused.
  LeafSnapshot? get focusedLeaf;

  /// Recently focused leaf ids, most-recent first. Trimmed to the
  /// configured `recentLimit` and to leaves still present in the tree.
  List<String> get recentLeafIds;

  /// Snapshot of the tree's root node.
  PlatSnapshot get root;

  /// Id of the active tab in the tab group at [tabGroupId], or `null`
  /// when [tabGroupId] is not a tab group or the group is empty.
  String? activeTabId(String tabGroupId);

  /// Drops both undo and redo stacks. Does not touch the tree.
  ///
  /// Returns whether any history entry was cleared.
  bool clearHistory();

  /// Closes the node with the given id.
  ///
  /// On a leaf: removes it (no-op when the leaf is locked); the empty
  /// surrounding tree simplifies, and focus shifts to the most recent
  /// surviving leaf when the closed leaf was focused.
  ///
  /// On any other node: removes the whole subtree. Locked leaves
  /// inside a tab group are kept; if that leaves at least one leaf
  /// behind, the group survives. Focus moves to the most recent
  /// surviving leaf when focus was inside the closed subtree. Returns
  /// whether the call changed controller state.
  bool close(String id);

  /// True when [descendantId] sits inside [ancestorId]'s subtree.
  bool contains(String ancestorId, String descendantId);

  /// Id of the first tab group in tree order, or `null` when none exists.
  String? firstTabGroupId();

  /// Sets focus to a leaf.
  ///
  /// [id] may be a leaf id, tab id, tab group id, or any node containing a
  /// leaf. The resolved leaf is focused and its containing tab groups activate
  /// the matching tabs. Doesn't push an undo entry. Returns whether the call
  /// changed controller state.
  bool focus(String id);

  /// Id of the currently focused leaf, or `null` when nothing is focused.
  String? focusedLeafId();

  /// Id of the tab group containing the focused leaf. Falls back to
  /// the first tab group in the tree when the focused leaf is not
  /// inside tabs, or `null` when the tree has no tab groups.
  String? focusedTabGroupId();

  /// Inserts [child] into the split at [splitId].
  ///
  /// [index] picks a slot in the destination (clamped, defaults to append).
  /// Returns false when [splitId] is not a split in the tree or [child] cannot
  /// be attached.
  bool insertSplitChild({
    required String splitId,
    required Plat child,
    int? index,
  });

  /// Inserts [tab] into the tab group at [tabGroupId].
  ///
  /// [index] picks a slot in the destination (clamped, defaults to append).
  /// When [activate] is true, the inserted tab takes focus and becomes the
  /// active tab. Preview tabs are unique per destination group: when [tab] is
  /// preview and the group already contains a preview tab, the existing preview
  /// is removed first. If [index] is omitted, the new preview reuses that slot;
  /// otherwise the provided index is honored in the final list.
  /// Returns false when [tabGroupId] is not a tab group or [tab] cannot be
  /// attached.
  bool insertTab({
    required String tabGroupId,
    required PlatTab tab,
    int? index,
    bool activate = true,
  });

  /// Wraps [tab] in a new single-tab group and inserts it beside [targetId].
  ///
  /// [targetId] is the id of the existing node to split around. The target
  /// keeps its identity; the inserted tab becomes focused.
  bool insertTabBeside({
    required String targetId,
    required PlatSide side,
    required PlatTab tab,
  });

  /// Seeds the empty slot at [slotId] with a new single-tab group for [tab].
  ///
  /// Returns false when [slotId] is not an empty slot or [tab] cannot be
  /// attached.
  bool insertTabIntoSlot({required String slotId, required PlatTab tab});

  /// Id of the currently maximized pane, or `null` when none is maximized.
  String? maximizedId();

  /// Moves a tab into the tab group at [tabGroupId].
  ///
  /// Same-group moves reorder. [index] picks a slot in the destination
  /// (clamped, defaults to append). When [activate] is true, the moved tab
  /// takes focus even if the move does not change the tab order. Preview tabs
  /// follow the same destination-group preview replacement rules as
  /// [insertTab].
  /// Returns whether the call changed controller state.
  bool moveTab({
    required String tabId,
    required String tabGroupId,
    int? index,
    bool activate = true,
  });

  /// Moves the tab identified by [tabId] into a new sibling group beside
  /// [targetId].
  ///
  /// [targetId] is the id of the existing node to split around. Returns false
  /// when the move would target the tab's own subtree or when it would leave
  /// its source group empty in place of the target.
  bool moveTabBeside({
    required String tabId,
    required String targetId,
    required PlatSide side,
  });

  /// Moves the tab identified by [tabId] into the empty slot at [slotId].
  ///
  /// Returns false when [slotId] is not an empty slot.
  bool moveTabIntoSlot({required String tabId, required String slotId});

  /// Id of the next tab group relative to [currentTabGroupId] in tree order,
  /// or `null` when the tree has no tab groups.
  ///
  /// When [currentTabGroupId] is `null`, returns [firstTabGroupId]. Negative
  /// [delta] moves backward.
  String? nextTabGroupId(String? currentTabGroupId, {int delta = 1});

  /// Id of [childId]'s direct parent in the tree, or `null` when
  /// [childId] is the root or not present.
  String? parentOf(String childId);

  /// IDs of every node from the root down to [targetId], inclusive on
  /// both ends. Empty when [targetId] is not in the tree.
  List<String> pathTo(String targetId);

  /// Replays the most recently undone change.
  ///
  /// Returns false when [canRedo] is false.
  bool redo();

  /// Removes the pane with the given id from the tree.
  ///
  /// Unlike [close], this is a structural delete: it does not honor
  /// locked tabs. Returns whether the call changed controller state.
  bool remove(String id);

  /// Id of the subtree to render right now.
  ///
  /// When nothing is maximized, this is [root]'s id. When a node is
  /// maximized, it's the maximized node, unless an ancestor slot pane
  /// declares `boundsMaximize`, in which case the maximize stays
  /// bounded by that slot.
  String renderRootId();

  /// Moves the tab at index [from] within the tab group at [tabGroupId]
  /// to index [to]. [from] must be valid; [to] is clamped. Returns
  /// whether the call changed controller state.
  bool reorderTab({
    required String tabGroupId,
    required int from,
    required int to,
  });

  /// Replaces the entire tree with one lowered from [plat].
  ///
  /// Returns false when [plat] cannot be lowered into a valid tree.
  bool replace(Plat plat);

  /// Rewrites every child of the split at [splitId] to the
  /// matching entry in [sizes]. [sizes] must have one entry per
  /// child. Returns whether the call changed controller state.
  bool resizeSplit(String splitId, List<PlatSize> sizes);

  /// Sets whether the node with the given id is hidden.
  ///
  /// Hidden nodes keep their slot in the tree. Returns whether the
  /// call changed controller state.
  bool setHidden(String id, {required bool hidden});

  /// Sets whether the tab with the given id is locked.
  ///
  /// Locked tabs refuse to be closed or dragged. Returns whether the
  /// call changed controller state.
  bool setLocked(String tabId, {required bool locked});

  /// Sets whether the node with the given id is maximized.
  ///
  /// When [maximized] is true, [id] becomes the sole maximized node.
  /// When [maximized] is false, the call only clears maximize when
  /// [id] is the currently maximized node. Doesn't push an undo entry.
  /// Returns whether the call changed controller state.
  bool setMaximized(String id, {required bool maximized});

  /// Sets whether the tab with the given id is pinned.
  ///
  /// Pinned tabs are conventionally rendered at the head of their tab
  /// group. Returns whether the call changed controller state.
  bool setPinned(String tabId, {required bool pinned});

  /// Sets whether the tab with the given id is the preview tab.
  ///
  /// Each tab group may contain at most one preview tab. Promoting a tab to
  /// preview removes any sibling preview in the same group. Returns whether the
  /// call changed controller state.
  bool setPreview(String tabId, {required bool preview});

  /// Sets the size of the node with the given id. No-op when the id
  /// is not in the tree or the size is identical. Returns whether the
  /// call changed controller state.
  bool setSize(String id, PlatSize size);

  /// Sets the child of the slot at [slotId].
  ///
  /// Pass `null` to clear the slot. Returns false when [slotId] is not a
  /// slot or [child] cannot be attached.
  bool setSlotChild({required String slotId, Plat? child});

  /// Moves the tab bar of the tab group at [tabGroupId] to [side]. No-op
  /// when [tabGroupId] is not a tab group or already on [side]. Doesn't
  /// push an undo entry. Returns whether the call changed controller
  /// state.
  bool setTabBarSide(String tabGroupId, TabBarSide side);

  /// Snapshot of the node with the given id, or `null` when the id
  /// is not in the tree.
  PlatSnapshot? snapshot(String id);

  /// Splits the node at [targetId], placing [sibling] on [side].
  ///
  /// [targetId] is the id of the existing node to split around. The target
  /// keeps its identity. When it already sits inside an unlocked split on the
  /// same axis, [sibling] is inserted beside it in that parent split; otherwise
  /// the target is wrapped in a new split. Returns false when [sibling] cannot
  /// be attached. Returns whether the call changed controller state.
  bool split({
    required String targetId,
    required PlatSide side,
    required Plat sibling,
  });

  /// Moves the active tab in the tab group at [tabGroupId] into a new
  /// sibling group on [side].
  ///
  /// Returns false when the source group has fewer than two tabs or
  /// no active tab.
  bool splitActiveTab({required String tabGroupId, required PlatSide side});

  /// Id of the tab group containing [id], or `null` when [id] is not
  /// inside any tab group.
  String? tabGroupContaining(String id);

  /// Runs [body] with intermediate mutations grouped into a single
  /// undo entry.
  ///
  /// Listeners are still notified on each mutation. Nested
  /// transactions reuse the outer one. Returns the value [body]
  /// returns.
  ///
  /// ```dart
  /// controller.transaction(() {
  ///   controller
  ///     ..insertTab(tabGroupId: groupId, tab: tabA)
  ///     ..insertTab(tabGroupId: groupId, tab: tabB)
  ///     ..focus(tabA.id);
  /// });
  /// ```
  T transaction<T>(ValueGetter<T> body);

  /// Reverts the most recent recorded change.
  ///
  /// Returns false when [canUndo] is false.
  bool undo();
}
