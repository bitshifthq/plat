part of 'tree.dart';

PlatExtent _halveExtent(PlatExtent extent) => switch (extent) {
  Pixels(:final value) => .pixel(value / 2),
  Fraction(:final value) => .fraction(value / 2),
  AutoExtent() => extent,
};

typedef _FocusWriteResult = ({PlatNode node, bool foundTarget, bool changed});

typedef _NodeEditResult = ({PlatNode? node, bool found, bool changed});

/// A node in the layout tree.
///
/// Sealed: the only concrete kinds are [LeafNode], [SplitNode],
/// [TabGroupNode], and [SlotNode]. All nodes are immutable; mutating
/// methods return new nodes and leave `this` untouched.
@internal
sealed class PlatNode {
  /// Stable identity for this node.
  final String id;

  /// When true, the node is excluded from layout. Hidden nodes still
  /// occupy a slot in the tree and keep their identity.
  final bool hidden;

  /// Allocation hint for the parent split. Ignored when this node has
  /// no parent split.
  final PlatSize size;

  /// When true, this node is the one currently maximized within its
  /// scope. At most one node in any scope is maximized at a time.
  final bool maximized;

  const PlatNode({
    required this.id,
    this.hidden = false,
    this.maximized = false,
    this.size = const .auto(),
  });

  /// IDs of every leaf in this subtree, in tree order.
  Iterable<String> get leafIds sync* {
    if (this is LeafNode) yield id;
    for (final c in _children) {
      yield* c.leafIds;
    }
  }

  /// IDs of every node in this subtree, in tree order.
  Iterable<String> get subtreeIds sync* {
    yield id;
    for (final c in _children) {
      yield* c.subtreeIds;
    }
  }

  /// Every [TabGroupNode] in this subtree, in tree order.
  Iterable<TabGroupNode> get tabGroups sync* {
    if (this case final TabGroupNode t) yield t;
    for (final c in _children) {
      yield* c.tabGroups;
    }
  }

  Iterable<PlatNode> get _children => switch (this) {
    final SplitNode s => s.children,
    final TabGroupNode t => [for (final tab in t.tabs) tab.child],
    final SlotNode s => s.child == null ? const [] : [s.child!],
    LeafNode() => const [],
  };

  /// Returns a structurally simplified version of this subtree.
  ///
  /// Empty [TabGroupNode]s drop, non-persistent [SlotNode]s drop with
  /// their child, single-child [SplitNode]s collapse onto the
  /// survivor, and same-axis resizable [SplitNode]s inline. Returns
  /// `null` when the subtree collapses entirely.
  @internal
  PlatNode? cleanTree();

  /// Closes the pane identified by [id].
  ///
  /// Locked tab roots are kept. Closing a tab group preserves its locked tabs
  /// when any remain; otherwise the group is removed.
  PlatNode? closePane(String id) {
    final directTab = directTabOf(id);
    if (directTab != null) return directTab.tab.locked ? this : removeTab(id);

    final node = findNode(id);
    if (node == null) return this;
    if (node case final LeafNode leaf when leaf.locked) return this;

    if (node is TabGroupNode) {
      final kept = node.keepLockedTabs();
      if (identical(kept, node)) return this;
      if (kept != null) return replace(node.id, kept);
    }

    return remove(id);
  }

  /// The exact tab with id [tabId] in this subtree, or `null` when none does.
  ({TabGroupNode group, int index, TabNode tab})? directTabOf(String tabId) {
    final path = pathTo(tabId);
    if (path == null || path.length < 2) return null;
    final parent = path[path.length - 2];
    if (parent case final TabGroupNode group) {
      final index = group.tabs.indexWhere((tab) => tab.id == tabId);
      if (index >= 0) {
        return (group: group, index: index, tab: group.tabs[index]);
      }
    }
    return null;
  }

  /// The node with the given id in this subtree, or `null` when none
  /// matches.
  PlatNode? findNode(String id) {
    if (this.id == id) return this;
    for (final c in _children) {
      final hit = c.findNode(id);
      if (hit != null) return hit;
    }
    return null;
  }

  /// Returns the first leaf in this subtree in tree order, or `null` when none
  /// exists.
  LeafNode? firstLeaf() {
    if (this case final LeafNode leaf) return leaf;
    for (final child in _children) {
      final leaf = child.firstLeaf();
      if (leaf != null) return leaf;
    }
    return null;
  }

  /// Returns the first tab group in this subtree in tree order, or `null`
  /// when none exists.
  TabGroupNode? firstTabGroup() {
    if (this case final TabGroupNode tabs) return tabs;
    for (final child in _children) {
      final tabs = child.firstTabGroup();
      if (tabs != null) return tabs;
    }
    return null;
  }

  /// Sets focus on the best leaf under [id], clearing focus elsewhere and
  /// activating matching tabs in each containing [TabGroupNode].
  PlatNode focus(String id) {
    final targetLeafId = _focusTargetFor(id);
    if (targetLeafId == null || targetLeafId == focusedLeaf()?.id) return this;
    final result = _writeFocus(targetLeafId, seenTarget: false);
    return result.foundTarget ? result.node : this;
  }

  /// Returns the first leaf in this subtree with `focused == true`, or `null`
  /// when none is focused.
  LeafNode? focusedLeaf() {
    if (this case final LeafNode leaf when leaf.focused) return leaf;
    for (final child in _children) {
      final leaf = child.focusedLeaf();
      if (leaf != null) return leaf;
    }
    return null;
  }

  /// Returns a copy with `hidden = true`.
  PlatNode hide() => _writeHidden(hidden: true);

  /// Inserts [child] into the [SplitNode] with id [splitId].
  ///
  /// [index] is clamped to `[0, children.length]`; `null` appends.
  PlatNode insertChild(String splitId, PlatNode child, {int? index}) {
    final result = _editNode(splitId, (node) {
      if (node case final SplitNode split) {
        final at = (index ?? split.children.length).clamp(
          0,
          split.children.length,
        );
        final children = [...split.children]..insert(at, child);
        return split.copyWith(children: children);
      }
      throw StateError('$splitId is not a split');
    });
    if (!result.found) throw StateError('$splitId not in tree');
    return result.node!;
  }

  /// Inserts [tab] into the [TabGroupNode] with id [tabGroupId].
  ///
  /// [index] is clamped to `[0, tabs.length]`; `null` appends. When
  /// [activate] is true, the inserted tab becomes the active tab.
  PlatNode insertTab(
    String tabGroupId,
    TabNode tab, {
    int? index,
    bool activate = true,
  }) {
    final result = _editNode(tabGroupId, (node) {
      if (node case final TabGroupNode tabsNode) {
        return tabsNode.insertTabNode(tab, index: index, activate: activate);
      }
      throw StateError('$tabGroupId is not a tab group');
    });
    if (!result.found) throw StateError('$tabGroupId not in tree');
    return result.node!;
  }

  /// Marks the node with the given id as maximized, clearing the
  /// flag everywhere else.
  PlatNode maximize(String id) {
    final result = _writeMaximized(id, seenTarget: false);
    return result.foundTarget ? result.node : this;
  }

  /// Returns the maximized node in this subtree, or `null` when none is
  /// maximized.
  PlatNode? maximizedPane() {
    if (maximized) return this;
    for (final child in _children) {
      final pane = child.maximizedPane();
      if (pane != null) return pane;
    }
    return null;
  }

  /// Moves the tab with id [tabId] into the [TabGroupNode] with id
  /// [tabGroupId].
  ///
  /// When the tab already lives in the destination, this reorders instead.
  PlatNode moveTab(
    String tabId,
    String tabGroupId, {
    int? index,
    bool activate = true,
  }) {
    final origin = directTabOf(tabId);
    if (origin == null) return this;
    if (origin.tab.child.findNode(tabGroupId) != null) return this;
    if (findNode(tabGroupId) is! TabGroupNode) return this;

    if (origin.group.id == tabGroupId) {
      final to = (index ?? origin.group.tabs.length).clamp(
        0,
        origin.group.tabs.length,
      );
      return reorderTab(
        origin.group.id,
        origin.index,
        to > origin.index ? to - 1 : to,
      );
    }

    final removed = removeTab(tabId);
    if (removed == null) return this;
    return removed.insertTab(
      tabGroupId,
      origin.tab,
      index: index,
      activate: activate,
    );
  }

  /// The chain of nodes from this subtree's root down to [target],
  /// inclusive on both ends, or `null` when [target] is not in this
  /// subtree.
  List<PlatNode>? pathTo(String target) {
    if (id == target) return [this];
    for (final c in _children) {
      final sub = c.pathTo(target);
      if (sub != null) return [this, ...sub];
    }
    return null;
  }

  /// Removes the pane identified by [id].
  ///
  /// If [id] identifies a direct tab root, the whole tab is removed. Otherwise
  /// the addressed subtree is removed and the surrounding tree is simplified.
  /// Returns `null` when the whole subtree collapses; returns `this` unchanged
  /// when [id] is not in this subtree.
  PlatNode? remove(String id) {
    final result = _editNode(id, (_) => null);
    return result.found ? result.node : this;
  }

  /// Removes [tabId] from its containing tab group.
  ///
  /// When the group empties, the group itself is dropped and the
  /// surrounding tree simplified (single-child splits collapse,
  /// non-persistent slots prune). Returns `null` when the whole subtree
  /// collapses; returns `this` unchanged when [tabId] is not in this subtree.
  PlatNode? removeTab(String tabId) {
    final origin = directTabOf(tabId);
    if (origin == null) return this;
    final nextGroup = origin.group.removeTabAt(origin.index);
    if (nextGroup == null) {
      // The path-walk in `replace` unwinds the cleanup (collapsing
      // single-child splits, pruning non-persistent slots); a
      // `persistent` SlotNode parent absorbs the null and becomes an
      // empty stub.
      return replace(origin.group.id, null);
    }
    return replace(origin.group.id, nextGroup);
  }

  /// Moves the tab at index [from] in the [TabGroupNode] with id [tabGroupId]
  /// to index [to], preserving which tab is active.
  ///
  /// [from] must be a valid index. [to] is clamped to `[0, tabs.length - 1]`.
  PlatNode reorderTab(String tabGroupId, int from, int to) {
    final target = findNode(tabGroupId);
    if (target is! TabGroupNode) {
      throw StateError(
        target == null
            ? '$tabGroupId not in tree'
            : '$tabGroupId is not a tab group',
      );
    }
    if (from < 0 || from >= target.tabs.length) {
      throw RangeError('from $from out of bounds');
    }
    final reordered = target.reorderTabs(from, to);
    return identical(reordered, target)
        ? this
        : replace(tabGroupId, reordered)!;
  }

  /// Substitutes the node with id [target] for [replacement] in this
  /// subtree.
  ///
  /// [replacement] may be `null` to remove the target outright; the
  /// surrounding tree is then simplified (single-child splits
  /// collapse, non-persistent slots prune). Returns `null` when the
  /// whole subtree collapses; throws [StateError] when [target] is
  /// not present.
  PlatNode? replace(String target, PlatNode? replacement) {
    if (id != target) throw StateError('$target not in tree');
    return replacement;
  }

  /// Returns this node with its [size] set to [next].
  PlatNode resize(PlatSize next) {
    if (identical(size, next)) return this;
    return switch (this) {
      final SplitNode s => s.copyWith(size: next),
      final TabGroupNode t => t.copyWith(size: next),
      final SlotNode s => s.copyWith(size: next),
      final LeafNode p => p.copyWith(size: next),
    };
  }

  /// Rewrites every child of the [SplitNode] with id [splitId] to
  /// match the corresponding entry in [sizes].
  ///
  /// [sizes] must have one entry per child; throws [ArgumentError]
  /// otherwise. Throws [StateError] when [splitId] does not refer to
  /// a split.
  PlatNode resizeSplit(String splitId, List<PlatSize> sizes) {
    final split = _requireSplit(splitId);
    if (sizes.length != split.children.length) {
      throw ArgumentError(
        'sizes length ${sizes.length} != '
        'children ${split.children.length}',
      );
    }
    if (split.children.indexed.every(
      (entry) => entry.$2.size == sizes[entry.$1],
    )) {
      return this;
    }
    final updated = [
      for (var i = 0; i < split.children.length; i++)
        split.children[i].resize(sizes[i]),
    ];
    return replace(splitId, split.copyWith(children: updated))!;
  }

  /// Clears any current maximize in this subtree.
  PlatNode restore() => _writeMaximized(null, seenTarget: false).node;

  /// Sets whether the pane identified by [id] is hidden.
  PlatNode setHidden(String id, {required bool hidden}) {
    final result = _editNode(id, (node) {
      if (node.hidden == hidden) return node;
      return hidden ? node.hide() : node.show();
    });
    return result.changed ? result.node! : this;
  }

  /// Sets the size of the pane identified by [id].
  PlatNode setPlatSize(String id, PlatSize size) {
    final result = _editNode(id, (node) {
      if (node.size == size) return node;
      return node.resize(size);
    });
    return result.changed ? result.node! : this;
  }

  /// Sets the child of the [SlotNode] with id [slotId].
  ///
  /// Pass `null` to clear the slot. Non-persistent slots collapse when
  /// cleared.
  PlatNode? setSlotChild(String slotId, PlatNode? child) {
    final result = _editNode(slotId, (node) {
      if (node case final SlotNode slot) {
        return slot
            .copyWith(child: child, clearChild: child == null)
            .cleanTree();
      }
      throw StateError('$slotId is not a slot');
    });
    if (!result.found) throw StateError('$slotId not in tree');
    return result.node;
  }

  /// Sets the tab bar side of the tab group identified by [tabGroupId].
  PlatNode setTabBarSide(String tabGroupId, TabBarSide side) {
    final result = _editNode(tabGroupId, (node) {
      if (node case final TabGroupNode tabs) {
        return tabs.side == side ? tabs : tabs.copyWith(side: side);
      }
      return node;
    });
    return result.changed ? result.node! : this;
  }

  /// Sets the locked, pinned, and preview flags of the tab identified by
  /// [tabId].
  PlatNode setTabFlags(
    String tabId, {
    bool? locked,
    bool? pinned,
    bool? preview,
  }) {
    final location = directTabOf(tabId);
    if (location == null) return this;

    final current = location.tab;
    final nextLocked = locked ?? current.locked;
    final nextPinned = pinned ?? current.pinned;
    final nextPreview = preview ?? current.preview;
    final updatedTab = current.copyWith(
      locked: nextLocked,
      pinned: nextPinned,
      preview: nextPreview,
    );
    if (!updatedTab.hasValidPreviewState) {
      throw ArgumentError.value(
        tabId,
        'tabId',
        'preview tabs cannot be pinned or locked',
      );
    }
    if (current.locked == nextLocked &&
        current.pinned == nextPinned &&
        current.preview == nextPreview) {
      return this;
    }

    PlatNode child = current.child;
    if (child case final LeafNode leaf) {
      child = leaf.copyWith(locked: nextLocked);
    }
    return replace(
      location.group.id,
      location.group.replaceTabNodeAt(
        location.index,
        updatedTab.copyWith(child: child),
      ),
    )!;
  }

  /// Returns a copy with `hidden = false`.
  PlatNode show() => _writeHidden(hidden: false);

  /// Splits the node at [targetId], placing [sibling] on [side].
  ///
  /// The target keeps its identity. When it already sits inside an unlocked
  /// parent [SplitNode] on the same axis, [sibling] is inserted into that
  /// parent. Otherwise the target is wrapped in a new split that contains both
  /// nodes. Returns `this` unchanged when [targetId] is unknown or when
  /// [sibling] already contains the target.
  PlatNode split(String targetId, PlatSide side, PlatNode sibling) {
    final target = findNode(targetId);
    if (target == null || sibling.findNode(targetId) != null) return this;

    // Walk through any [SlotNode] wrapping the root to reach the nearest
    // ancestor [SplitNode]. Without this, splitting next to a leaf inside a
    // SlotNode-rooted tree always takes the wrap branch and skips the parent-
    // axis halving.
    final p = _nearestParentSplit(targetId);

    if (p != null && p.parent.axis == side._axis && p.parent.resizable) {
      final at = side._afterTarget ? p.index + 1 : p.index;
      final children = [...p.parent.children];
      // Split the target's existing claim 50/50 with the new sibling so other
      // siblings keep their current claims.
      final ts = target.size;
      if (ts is FlexibleSize && ts.initial is! AutoExtent) {
        final halved = _halveExtent(ts.initial);
        children[p.index] = target.resize(ts.copyWith(initial: halved));
        children.insert(at, sibling.resize(.resizable(initial: halved)));
      } else {
        children.insert(at, sibling);
      }
      return replace(p.parent.id, p.parent.copyWith(children: children))!;
    }

    // Carry the target's flexible size onto the new wrapper so siblings
    // outside don't get re-weighted; the inner pair shares the wrapper's
    // extent. [FixedSize] targets keep their locked extent on the inside.
    final outerSize = target.size;
    final flexible = outerSize is FlexibleSize;
    final innerTarget = flexible ? target.resize(const .auto()) : target;
    final wrapper = SplitNode(
      id: generateNodeId(),
      axis: side._axis,
      size: flexible ? outerSize : const .auto(),
      children: side._afterTarget
          ? [innerTarget, sibling]
          : [sibling, innerTarget],
    );
    return replace(targetId, wrapper.cleanTree() ?? wrapper)!;
  }

  /// The deepest [TabGroupNode] in this subtree that encloses [target], or
  /// `null` when none does.
  TabGroupNode? tabGroupOf(String target) {
    final path = pathTo(target);
    if (path == null) return null;
    for (final node in path.reversed) {
      if (node case final TabGroupNode tabs) return tabs;
    }
    return null;
  }

  _NodeEditResult _editNode(
    String target,
    PlatNode? Function(PlatNode node) edit,
  ) {
    if (id == target) {
      final next = edit(this);
      return (node: next, found: true, changed: !identical(next, this));
    }
    return switch (this) {
      final SplitNode split => split._editNode(target, edit),
      final TabGroupNode tabs => tabs._editNode(target, edit),
      final SlotNode slot => slot._editNode(target, edit),
      LeafNode() => (node: this, found: false, changed: false),
    };
  }

  String? _focusTargetFor(String id) {
    final target = _resolveFocusTarget(id);
    return switch (target) {
      final LeafNode leaf => leaf.id,
      final TabGroupNode tabs => () {
        final activeTab = tabs.activeTab();
        return activeTab?.child.focusedLeaf()?.id ??
            activeTab?.child.firstLeaf()?.id;
      }(),
      final PlatNode node => node.focusedLeaf()?.id ?? node.firstLeaf()?.id,
      null => null,
    };
  }

  ({SplitNode parent, int index})? _nearestParentSplit(String target) {
    final path = pathTo(target);
    if (path == null) return null;
    for (var i = path.length - 2; i >= 0; i--) {
      final node = path[i];
      if (node case final SplitNode split) {
        final child = path[i + 1];
        if (child.id != target) continue;
        final index = split.children.indexWhere(
          (candidate) => identical(candidate, child),
        );
        if (index >= 0) return (parent: split, index: index);
      }
    }
    return null;
  }

  SplitNode _requireSplit(String splitId) {
    final target = findNode(splitId);
    return switch (target) {
      final SplitNode split => split,
      null => throw StateError('$splitId not in tree'),
      _ => throw StateError('$splitId is not a split'),
    };
  }

  PlatNode? _resolveFocusTarget(String target) {
    if (id == target) return this;
    return switch (this) {
      final SplitNode split => split._resolveFocusTarget(target),
      final TabGroupNode tabs => tabs._resolveFocusTarget(target),
      final SlotNode slot => slot._resolveFocusTarget(target),
      LeafNode() => null,
    };
  }

  _FocusWriteResult _writeFocus(
    String focusId, {
    required bool seenTarget,
  }) => switch (this) {
    final LeafNode leaf => () {
      final shouldFocus = leaf.id == focusId;
      final foundTarget = seenTarget || shouldFocus;
      if (leaf.focused == shouldFocus) {
        return (
          node: leaf as PlatNode,
          foundTarget: foundTarget,
          changed: false,
        );
      }
      return (
        node: leaf.copyWith(focused: shouldFocus),
        foundTarget: foundTarget,
        changed: true,
      );
    }(),
    final SplitNode split => split._writeFocus(focusId, seenTarget: seenTarget),
    final TabGroupNode tabs => tabs._writeFocus(
      focusId,
      seenTarget: seenTarget,
    ),
    final SlotNode slot => slot._writeFocus(focusId, seenTarget: seenTarget),
  };

  PlatNode _writeHidden({required bool hidden}) {
    if (this.hidden == hidden) return this;
    return switch (this) {
      final SplitNode s => s.copyWith(hidden: hidden),
      final TabGroupNode t => t.copyWith(hidden: hidden),
      final SlotNode s => s.copyWith(hidden: hidden),
      final LeafNode p => p.copyWith(hidden: hidden),
    };
  }

  _FocusWriteResult _writeMaximized(String? maxId, {required bool seenTarget}) {
    final nextSeenTarget = seenTarget || maxId == null;
    return switch (this) {
      final LeafNode leaf => () {
        final shouldMaximize = leaf.id == maxId;
        final foundTarget = seenTarget || shouldMaximize || maxId == null;
        if (leaf.maximized == shouldMaximize) {
          return (
            node: leaf as PlatNode,
            foundTarget: foundTarget,
            changed: false,
          );
        }
        return (
          node: leaf.copyWith(maximized: shouldMaximize),
          foundTarget: foundTarget,
          changed: true,
        );
      }(),
      final SplitNode split => split._writeMaximized(
        maxId,
        seenTarget: nextSeenTarget,
      ),
      final TabGroupNode tabs => tabs._writeMaximized(
        maxId,
        seenTarget: nextSeenTarget,
      ),
      final SlotNode slot => slot._writeMaximized(
        maxId,
        seenTarget: nextSeenTarget,
      ),
    };
  }
}

extension on PlatSide {
  bool get _afterTarget => this == .bottom || this == .right;

  SplitAxis get _axis =>
      this == .left || this == .right ? .horizontal : .vertical;
}
