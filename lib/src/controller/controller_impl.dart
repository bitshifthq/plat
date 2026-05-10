part of 'controller.dart';

PlatNode _initialControllerRoot(Plat? initialPlat) => initialPlat == null
    ? TabGroupNode.empty()
    : (lowerPane(initialPlat) ?? TabGroupNode.empty());

/// Default implementation of [PlatController].
@internal
final class PlatControllerImpl extends PlatController {
  /// Cap on undo and redo stack depth. Older entries fall off the
  /// bottom when the limit is exceeded.
  final int undoLimit;

  /// Cap on the most-recently-focused leaf list used by close-time
  /// refocus.
  final int recentLimit;

  /// Policy for incoming ids that already exist in this controller.
  final IdConflict idConflict;

  final _undo = <PlatNode>[];
  final _redo = <PlatNode>[];
  final _recent = <String>[]; // most-recent first

  PlatNode _root;
  String? _maximizedId;
  String? _focusedLeafId;
  var _interactionDepth = 0;
  PlatNode? _interactionStartRoot;

  PlatControllerImpl({
    Plat? initialPlat,
    int undoLimit = 100,
    int recentLimit = 200,
    IdConflict idConflict = .reject,
  }) : this._(
         _initialControllerRoot(initialPlat),
         undoLimit: undoLimit,
         recentLimit: recentLimit,
         idConflict: idConflict,
       );

  PlatControllerImpl._(
    PlatNode root, {
    required this.undoLimit,
    required this.recentLimit,
    required this.idConflict,
  }) : _root = root,
       _focusedLeafId = root.focusedLeaf()?.id,
       _maximizedId = root.maximizedPane()?.id,
       super._base() {
    final initialFocusId = _focusedLeafId;
    if (initialFocusId != null) _recent.add(initialFocusId);
  }

  @override
  bool get canRedo => _redo.isNotEmpty;

  @override
  bool get canUndo => _undo.isNotEmpty;

  @override
  LeafSnapshot? get focusedLeaf {
    final id = focusedLeafId();
    final view = id == null ? null : snapshot(id);
    return view is LeafSnapshot ? view : null;
  }

  @override
  List<String> get recentLeafIds => [
    for (final id in _recent)
      if (_nodeAt(id) case LeafNode()) id,
  ];

  @override
  PlatSnapshot get root => snapshotOf(_root);

  @override
  String? activeTabId(String tabGroupId) {
    final node = _nodeAt(tabGroupId);
    return node is TabGroupNode ? node.activeTab()?.id : null;
  }

  @override
  bool clearHistory() {
    if (_undo.isEmpty && _redo.isEmpty) return false;
    _undo.clear();
    _redo.clear();
    notifyListeners();
    return true;
  }

  @override
  bool close(String id) {
    final context = _removalContext(id, respectLocks: true);
    if (context == null) return false;
    return _commitRemoval(_root.closePane(id), context);
  }

  @override
  bool contains(String ancestorId, String descendantId) {
    final path = _root.pathTo(descendantId);
    if (path == null) return false;
    return path.any((node) => node.id == ancestorId);
  }

  @override
  String? firstTabGroupId() => _root.firstTabGroup()?.id;

  @override
  bool focus(String id) {
    if (_nodeAt(id) == null) return false;
    final next = _root.focus(id);
    final leafId = next.focusedLeaf()?.id;
    if (leafId == null) return false;
    final changed = _commitTransient(next);
    if (changed) _touchRecent(leafId);
    return changed;
  }

  @override
  String? focusedLeafId() => _focusedLeafId;

  @override
  String? focusedTabGroupId() {
    final leafId = _focusedLeafId;
    if (leafId != null) {
      final tabGroupId = tabGroupContaining(leafId);
      if (tabGroupId != null) return tabGroupId;
    }
    return firstTabGroupId();
  }

  @override
  bool insertSplitChild({
    required String splitId,
    required Plat child,
    int? index,
  }) {
    if (_nodeAt(splitId) is! SplitNode) return false;
    final lowered = tryLowerPane(child);
    if (lowered == null) return false;
    final base = _resolveIncomingIdConflicts(lowered, protectedIds: {splitId});
    if (base == null || base.findNode(splitId) is! SplitNode) return false;
    return _commit(base.insertChild(splitId, lowered, index: index));
  }

  @override
  bool insertTab({
    required String tabGroupId,
    required PlatTab tab,
    int? index,
    bool activate = true,
  }) {
    if (_nodeAt(tabGroupId) is! TabGroupNode) return false;
    final lowered = tryLowerTab(tab);
    if (lowered == null) return false;
    final base = _resolveIncomingIdConflicts(
      lowered.child,
      protectedIds: {tabGroupId},
      preserveEmptyTabGroupIds: {tabGroupId},
    );
    if (base == null || base.findNode(tabGroupId) is! TabGroupNode) {
      return false;
    }
    var next = base.insertTab(
      tabGroupId,
      lowered,
      index: index,
      activate: activate,
    );
    if (activate) next = _focusAndTouch(next, lowered.id);
    return _commit(next);
  }

  @override
  bool insertTabBeside({
    required String targetId,
    required PlatSide side,
    required PlatTab tab,
  }) {
    final beforeLeafIds = tab.id == null ? _root.leafIds.toSet() : null;
    final changed = split(
      targetId: targetId,
      side: side,
      sibling: _singleTabPane(tab),
    );
    if (changed) {
      final id = tab.id ?? _firstNewLeafId(beforeLeafIds!);
      if (id != null) focus(id);
    }
    return changed;
  }

  @override
  bool insertTabIntoSlot({required String slotId, required PlatTab tab}) {
    final slot = _nodeAt(slotId);
    if (slot is! SlotNode || slot.child != null) return false;
    final child = tryLowerPane(_singleTabPane(tab));
    if (child == null) return false;
    final base = _resolveIncomingIdConflicts(child, protectedIds: {slotId});
    if (base == null) return false;
    final target = base.findNode(slotId);
    if (target is! SlotNode || target.child != null) return false;
    var next = base.setSlotChild(slotId, child) ?? TabGroupNode.empty();
    final leafId = child.firstLeaf()?.id;
    if (leafId != null) next = _focusAndTouch(next, leafId);
    return _commit(next);
  }

  @override
  String? maximizedId() => _maximizedId;

  @override
  bool moveTab({
    required String tabId,
    required String tabGroupId,
    int? index,
    bool activate = true,
  }) {
    final origin = _directTabOf(tabId);
    if (origin == null) return false;
    if (_nodeAt(tabGroupId) is! TabGroupNode) return false;
    var next = _root.moveTab(
      tabId,
      tabGroupId,
      index: index,
      activate: activate,
    );
    if (identical(next, _root)) {
      if (activate && origin.group.id == tabGroupId) return focus(tabId);
      return false;
    }
    if (activate) next = _focusAndTouch(next, tabId);
    return _commit(next);
  }

  @override
  bool moveTabBeside({
    required String tabId,
    required String targetId,
    required PlatSide side,
  }) {
    final origin = _directTabOf(tabId);
    if (origin == null) return false;
    if (origin.tab.child.findNode(targetId) != null) return false;
    if (targetId == origin.group.id && origin.group.tabs.length == 1) {
      return false;
    }

    final tab = _tabOf(origin.tab);
    var changed = false;
    transaction(() {
      if (!remove(tabId)) return;
      changed = split(
        targetId: targetId,
        side: side,
        sibling: _singleTabPane(tab),
      );
      if (changed) focus(tabId);
    });
    return changed;
  }

  @override
  bool moveTabIntoSlot({required String tabId, required String slotId}) {
    final origin = _directTabOf(tabId);
    final slot = _nodeAt(slotId);
    if (origin == null || slot is! SlotNode || slot.child != null) {
      return false;
    }

    final tab = _tabOf(origin.tab);
    var changed = false;
    transaction(() {
      if (!remove(tabId)) return;
      changed = setSlotChild(slotId: slotId, child: _singleTabPane(tab));
      focus(tabId);
    });
    return changed;
  }

  @override
  String? nextTabGroupId(String? currentTabGroupId, {int delta = 1}) {
    final order = [for (final tabs in _root.tabGroups) tabs.id];
    if (order.isEmpty) return null;
    if (currentTabGroupId == null) return order.first;
    final currentIndex = order.indexOf(currentTabGroupId);
    if (currentIndex < 0) return order.first;
    if (delta == 0) return currentTabGroupId;
    final nextIndex = (currentIndex + delta) % order.length;
    return order[nextIndex < 0 ? nextIndex + order.length : nextIndex];
  }

  @override
  String? parentOf(String childId) {
    final path = _root.pathTo(childId);
    if (path == null || path.length < 2) return null;
    return path[path.length - 2].id;
  }

  @override
  List<String> pathTo(String targetId) {
    return _root
            .pathTo(targetId)
            ?.map((node) => node.id)
            .toList(growable: false) ??
        const [];
  }

  @override
  bool redo() {
    if (_redo.isEmpty) return false;
    _pushUndo(_root, clearRedo: false);
    _replaceRoot(_redo.removeLast());
    return true;
  }

  @override
  bool remove(String id) {
    final context = _removalContext(id, respectLocks: false);
    if (context == null) return false;
    return _commitRemoval(_root.remove(id), context);
  }

  @override
  String renderRootId() {
    final maxId = _maximizedId;
    if (maxId == null) return _root.id;
    final path = _root.pathTo(maxId);
    if (path == null) return _root.id;
    for (final node in path.reversed.skip(1)) {
      if (node is SlotNode && node.boundsMaximize) return node.id;
    }
    return maxId;
  }

  @override
  bool reorderTab({
    required String tabGroupId,
    required int from,
    required int to,
  }) {
    final node = _nodeAt(tabGroupId);
    if (node is! TabGroupNode) return false;
    if (from < 0 || from >= node.tabs.length) return false;
    final clamped = to.clamp(0, node.tabs.length - 1);
    if (from == clamped) return false;
    return _commit(_root.reorderTab(tabGroupId, from, to));
  }

  @override
  bool replace(Plat plat) {
    final lowered = tryLowerRootPane(plat);
    if (!lowered.valid) return false;
    return _commit(lowered.node ?? TabGroupNode.empty());
  }

  @override
  bool resizeSplit(String splitId, List<PlatSize> sizes) {
    final split = _nodeAt(splitId);
    if (split is! SplitNode || split.children.length != sizes.length) {
      return false;
    }
    return _commit(_root.resizeSplit(splitId, sizes));
  }

  @override
  bool setHidden(String id, {required bool hidden}) {
    return _commit(_root.setHidden(id, hidden: hidden));
  }

  @override
  bool setLocked(String tabId, {required bool locked}) {
    return _commit(_root.setTabFlags(tabId, locked: locked));
  }

  @override
  bool setMaximized(String id, {required bool maximized}) {
    if (_nodeAt(id) == null) return false;
    if (maximized) {
      if (_maximizedId == id) return false;
      return _commitTransient(_root.maximize(id));
    }
    if (_maximizedId != id) return false;
    return _commitTransient(_root.restore());
  }

  @override
  bool setPinned(String tabId, {required bool pinned}) {
    return _commit(_root.setTabFlags(tabId, pinned: pinned));
  }

  @override
  bool setPreview(String tabId, {required bool preview}) {
    return _commit(_root.setTabFlags(tabId, preview: preview));
  }

  @override
  bool setSize(String id, PlatSize size) {
    return _commit(_root.setPlatSize(id, size));
  }

  @override
  bool setSlotChild({required String slotId, Plat? child}) {
    if (_nodeAt(slotId) is! SlotNode) return false;
    final lowered = child == null ? null : tryLowerPane(child);
    if (lowered == null) {
      if (child == null) {
        return _commit(
          _root.setSlotChild(slotId, null) ?? TabGroupNode.empty(),
        );
      }
      return false;
    }
    final base = _resolveIncomingIdConflicts(lowered, protectedIds: {slotId});
    if (base == null || base.findNode(slotId) is! SlotNode) return false;
    return _commit(base.setSlotChild(slotId, lowered) ?? TabGroupNode.empty());
  }

  @override
  bool setTabBarSide(String tabGroupId, TabBarSide side) {
    return _commitTransient(_root.setTabBarSide(tabGroupId, side));
  }

  @override
  PlatSnapshot? snapshot(String id) {
    final node = _nodeAt(id);
    return node == null ? null : snapshotOf(node);
  }

  @override
  bool split({
    required String targetId,
    required PlatSide side,
    required Plat sibling,
  }) {
    final lowered = tryLowerPane(sibling);
    if (lowered == null) return false;
    final base = _resolveIncomingIdConflicts(lowered, protectedIds: {targetId});
    if (base == null || base.findNode(targetId) == null) return false;
    return _commit(base.split(targetId, side, lowered));
  }

  @override
  bool splitActiveTab({required String tabGroupId, required PlatSide side}) {
    final source = _nodeAt(tabGroupId);
    if (source is! TabGroupNode || source.tabs.length < 2) return false;
    final activeId = source.activeTab()?.id;
    if (activeId == null) return false;
    return moveTabBeside(tabId: activeId, targetId: tabGroupId, side: side);
  }

  @override
  String? tabGroupContaining(String id) => _root.tabGroupOf(id)?.id;

  @override
  T transaction<T>(ValueGetter<T> body) {
    _beginInteraction();
    try {
      return body();
    } finally {
      _endInteraction();
    }
  }

  @override
  bool undo() {
    if (_undo.isEmpty) return false;
    _redo.add(_root);
    if (_redo.length > undoLimit) _redo.removeAt(0);
    _replaceRoot(_undo.removeLast());
    return true;
  }

  void _beginInteraction() {
    if (_interactionDepth == 0) _interactionStartRoot = _root;
    _interactionDepth++;
  }

  bool _commit(PlatNode next) => _replaceRoot(next, pushUndo: true);

  bool _commitRemoval(
    PlatNode? nextRoot,
    ({String refocusTargetId, Set<String> removedLeafIds, bool hadFocusInside})
    context,
  ) {
    if (identical(nextRoot, _root)) return false;
    final base = nextRoot ?? TabGroupNode.empty();
    if (!context.hadFocusInside) return _commit(base);
    final refocused = _refocusAfterClose(
      base,
      context.refocusTargetId,
      context.removedLeafIds,
    );
    return _replaceRoot(refocused, pushUndo: true);
  }

  bool _commitTransient(PlatNode next) => _replaceRoot(next);

  ({TabGroupNode group, int index, TabNode tab})? _directTabOf(String tabId) =>
      _root.directTabOf(tabId);

  void _endInteraction() {
    if (_interactionDepth == 0) return;
    _interactionDepth--;
    if (_interactionDepth == 0 && _interactionStartRoot != null) {
      if (!identical(_interactionStartRoot, _root)) {
        _pushUndo(_interactionStartRoot!);
      }
      _interactionStartRoot = null;
    }
  }

  String? _firstNewLeafId(Set<String> previousLeafIds) {
    for (final id in _root.leafIds) {
      if (!previousLeafIds.contains(id)) return id;
    }
    return null;
  }

  PlatNode _focusAndTouch(PlatNode next, String id) {
    final focused = next.focus(id);
    final leafId = focused.focusedLeaf()?.id;
    if (leafId != null) _touchRecent(leafId);
    return focused;
  }

  PlatNode? _nodeAt(String id) => _root.findNode(id);

  void _pushUndo(PlatNode prev, {bool clearRedo = true}) {
    _undo.add(prev);
    if (_undo.length > undoLimit) _undo.removeAt(0);
    if (clearRedo) _redo.clear();
  }

  PlatNode _refocusAfterClose(
    PlatNode next,
    String formerTabGroupId,
    Set<String> removedIds,
  ) {
    for (final id in _recent) {
      if (removedIds.contains(id)) continue;
      if (next.findNode(id) case LeafNode()) {
        _touchRecent(id);
        return next.focus(id);
      }
    }

    final formerTabGroup = next.findNode(formerTabGroupId);
    final formerActiveLeaf = formerTabGroup is TabGroupNode
        ? formerTabGroup.activeLeaf()
        : null;
    if (formerActiveLeaf != null) {
      _touchRecent(formerActiveLeaf.id);
      return next.focus(formerActiveLeaf.id);
    }

    final firstTabGroup = next.firstTabGroup();
    final activeLeaf = firstTabGroup?.activeLeaf();
    if (activeLeaf != null) {
      _touchRecent(activeLeaf.id);
      return next.focus(activeLeaf.id);
    }

    return next;
  }

  ({String refocusTargetId, Set<String> removedLeafIds, bool hadFocusInside})?
  _removalContext(String id, {required bool respectLocks}) {
    final focusedId = _focusedLeafId;
    final tab = _directTabOf(id);
    if (tab != null) {
      if (respectLocks && tab.tab.locked) return null;
      final removedLeafIds = tab.tab.child.leafIds.toSet();
      return (
        refocusTargetId: tab.group.id,
        removedLeafIds: removedLeafIds,
        hadFocusInside: focusedId != null && removedLeafIds.contains(focusedId),
      );
    }

    final node = _nodeAt(id);
    if (node == null) return null;
    if (respectLocks) {
      if (node case final LeafNode leaf when leaf.locked) return null;
      if (node case final TabGroupNode tabs) {
        final lockedTabs = tabs.tabs.where((tab) => tab.locked).toList();
        if (lockedTabs.length == tabs.tabs.length) return null;
        final removedLeafIds = lockedTabs.isEmpty
            ? tabs.leafIds.toSet()
            : {
                for (final tab in tabs.tabs.where((tab) => !tab.locked))
                  ...tab.child.leafIds,
              };
        return (
          refocusTargetId: tabs.id,
          removedLeafIds: removedLeafIds,
          hadFocusInside:
              focusedId != null && removedLeafIds.contains(focusedId),
        );
      }
    }

    final removedLeafIds = node.leafIds.toSet();
    return (
      refocusTargetId: tabGroupContaining(id) ?? id,
      removedLeafIds: removedLeafIds,
      hadFocusInside: focusedId != null && removedLeafIds.contains(focusedId),
    );
  }

  PlatNode _removeIncomingConflict(
    PlatNode root,
    String id, {
    required Set<String> preserveEmptyTabGroupIds,
  }) {
    final directTab = root.directTabOf(id);
    if (directTab != null &&
        preserveEmptyTabGroupIds.contains(directTab.group.id) &&
        directTab.group.tabs.length == 1) {
      return root.replace(
            directTab.group.id,
            directTab.group.copyWith(tabs: [], activeIndex: 0),
          ) ??
          TabGroupNode.empty();
    }
    return root.remove(id) ?? TabGroupNode.empty();
  }

  bool _replaceRoot(PlatNode next, {bool pushUndo = false}) {
    if (identical(next, _root)) return false;
    if (pushUndo && _interactionDepth == 0) _pushUndo(_root);
    _root = next;
    _syncState();
    notifyListeners();
    return true;
  }

  PlatNode? _resolveIncomingIdConflicts(
    PlatNode incoming, {
    Set<String> protectedIds = const {},
    Set<String> preserveEmptyTabGroupIds = const {},
  }) {
    final conflicts = [
      for (final id in incoming.subtreeIds)
        if (_root.findNode(id) != null) id,
    ];
    if (conflicts.isEmpty) return _root;
    if (idConflict == .reject) return null;

    var next = _root;
    for (final id in conflicts) {
      if (protectedIds.contains(id)) return null;
      if (next.findNode(id) == null) continue;
      next = _removeIncomingConflict(
        next,
        id,
        preserveEmptyTabGroupIds: preserveEmptyTabGroupIds,
      );
    }
    return next;
  }

  Plat _singleTabPane(PlatTab tab) => .tabs([tab], id: generateNodeId());

  void _syncState() {
    _focusedLeafId = _root.focusedLeaf()?.id;
    _maximizedId = _root.maximizedPane()?.id;
  }

  PlatTab _tabOf(TabNode tab) => PlatTab(
    child: snapshotOf(tab.child).toPane(),
    title: tab.title,
    pinned: tab.pinned,
    locked: tab.locked,
    preview: tab.preview,
  );

  void _touchRecent(String leafId) {
    _recent
      ..remove(leafId)
      ..insert(0, leafId);
    if (_recent.length > recentLimit) {
      _recent.removeRange(recentLimit, _recent.length);
    }
  }
}
