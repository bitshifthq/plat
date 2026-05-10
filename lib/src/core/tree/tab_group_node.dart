part of 'tree.dart';

/// A tab group over a flat list of [tabs].
///
/// Exactly one tab is active at a time ([activeIndex] / [activeTab]) and its
/// child subtree is the one rendered; the rest sit behind the tab strip and
/// are switched into view on selection.
@internal
final class TabGroupNode extends PlatNode {
  /// Index of the active tab. In `[0, tabs.length)`, or `0` when [tabs] is
  /// empty.
  final int activeIndex;

  /// Edge of the body where the tab bar sits.
  final TabBarSide side;

  /// When true, this group's body accepts tab drops from other groups or views.
  /// Tab-strip reordering still works when false.
  final bool acceptsDrops;

  /// The tabs managed by this group, in display order.
  final List<TabNode> tabs;

  TabGroupNode({
    required super.id,
    this.tabs = const [],
    this.activeIndex = 0,
    this.side = .top,
    this.acceptsDrops = true,
    super.size,
    super.hidden,
    super.maximized,
  }) : assert(
         tabs.isEmpty
             ? activeIndex == 0
             : activeIndex >= 0 && activeIndex < tabs.length,
         'activeIndex must be in [0, tabs.length) (or 0 when empty)',
       );

  /// A tab group with no tabs yet.
  factory TabGroupNode.empty({String? id}) =>
      TabGroupNode(id: id ?? generateNodeId());

  /// Returns the first focused leaf in the active tab, or its first leaf when
  /// unfocused.
  LeafNode? activeLeaf() {
    final activeTab = this.activeTab();
    return activeTab == null
        ? null
        : activeTab.focusedLeaf() ?? activeTab.firstLeaf();
  }

  /// Returns the currently active tab, or `null` when [tabs] is empty.
  TabNode? activeTab() => tabs.isEmpty ? null : tabs[activeIndex];

  @override
  PlatNode? cleanTree() {
    List<TabNode>? out;
    for (var i = 0; i < tabs.length; i++) {
      final tab = tabs[i];
      final next = tab.cleanTree();
      if (next == null || !identical(next, tab)) {
        out ??= List.of(tabs.take(i));
      }
      if (next == null) continue;
      out?.add(next);
    }
    if (out == null) return tabs.isEmpty ? null : this;
    if (out.isEmpty) return null;
    return copyWith(
      tabs: out,
      activeIndex: _activeIndexAfter(out, preferredIndex: activeIndex),
    );
  }

  /// Returns a copy with the named fields replaced.
  TabGroupNode copyWith({
    List<TabNode>? tabs,
    int? activeIndex,
    TabBarSide? side,
    PlatSize? size,
    bool? hidden,
    bool? acceptsDrops,
    bool? maximized,
  }) => TabGroupNode(
    id: id,
    tabs: tabs ?? this.tabs,
    activeIndex: activeIndex ?? this.activeIndex,
    side: side ?? this.side,
    size: size ?? this.size,
    hidden: hidden ?? this.hidden,
    acceptsDrops: acceptsDrops ?? this.acceptsDrops,
    maximized: maximized ?? this.maximized,
  );

  /// Inserts [tab] into this group, applying preview replacement rules.
  TabGroupNode insertTabNode(TabNode tab, {int? index, bool activate = true}) {
    final updated = [...tabs];
    final existingPreviewIndex = tab.preview ? previewIndex() : null;
    if (existingPreviewIndex != null) updated.removeAt(existingPreviewIndex);

    final insertAt = (index ?? existingPreviewIndex ?? updated.length).clamp(
      0,
      updated.length,
    );
    updated.insert(insertAt, tab);
    return copyWith(
      tabs: updated,
      activeIndex: activate
          ? insertAt
          : _activeIndexAfter(updated, preferredIndex: insertAt),
    );
  }

  /// Returns a copy that keeps only locked tabs, or `null` when none remain.
  TabGroupNode? keepLockedTabs() {
    final lockedTabs = tabs.where((tab) => tab.locked).toList(growable: false);
    if (lockedTabs.length == tabs.length) return this;
    return lockedTabs.isEmpty
        ? null
        : copyWith(tabs: lockedTabs, activeIndex: 0);
  }

  /// Index of the preview tab in this group, or `null` when none exists.
  int? previewIndex({String? excludingId}) {
    final index = tabs.indexWhere(
      (tab) => tab.preview && tab.id != excludingId,
    );
    return index < 0 ? null : index;
  }

  /// Removes the tab at [index], preserving the active tab when possible.
  TabGroupNode? removeTabAt(int index) {
    final updated = [...tabs]..removeAt(index);
    return updated.isEmpty
        ? null
        : copyWith(
            tabs: updated,
            activeIndex: _activeIndexAfter(updated, preferredIndex: index),
          );
  }

  /// Moves the tab at [from] to [to], preserving which tab stays active.
  TabGroupNode reorderTabs(int from, int to) {
    if (from < 0 || from >= tabs.length) {
      throw RangeError('from $from out of bounds');
    }
    final clamped = to.clamp(0, tabs.length - 1);
    if (from == clamped) return this;
    final updated = [...tabs];
    updated.insert(clamped, updated.removeAt(from));
    return copyWith(
      tabs: updated,
      activeIndex: _activeIndexAfter(updated, preferredIndex: clamped),
    );
  }

  @override
  PlatNode? replace(String target, PlatNode? replacement) {
    if (id == target) return replacement;

    List<TabNode>? out;
    for (var i = 0; i < tabs.length; i++) {
      final tab = tabs[i];
      final nextChild = tab.child.id == target
          ? replacement
          : switch (tab.child) {
              final SplitNode s => s.replace(target, replacement),
              final TabGroupNode t => t.replace(target, replacement),
              final SlotNode s => s.replace(target, replacement),
              _ => tab.child,
            };
      if (identical(nextChild, tab.child)) {
        out?.add(tab);
        continue;
      }
      final nextTab = nextChild == null
          ? null
          : tab.copyWith(child: nextChild).cleanTree();
      out ??= List.of(tabs.take(i));
      if (nextTab != null) out.add(nextTab);
    }

    if (out == null) return this;
    if (out.isEmpty) return null;

    return copyWith(
      tabs: out,
      activeIndex: _activeIndexAfter(out, preferredIndex: activeIndex),
    );
  }

  /// Replaces the tab at [index] with [tab], removing any sibling preview
  /// when [tab] is preview.
  TabGroupNode replaceTabNodeAt(int index, TabNode tab) {
    final updated = [...tabs];
    var targetIndex = index;
    final existingPreviewIndex = tab.preview
        ? previewIndex(excludingId: tabs[index].id)
        : null;
    if (existingPreviewIndex != null) {
      updated.removeAt(existingPreviewIndex);
      if (existingPreviewIndex < targetIndex) targetIndex--;
    }
    updated[targetIndex] = tab;
    return copyWith(
      tabs: updated,
      activeIndex: _activeIndexAfter(updated, preferredIndex: targetIndex),
    );
  }

  @override
  String toString() =>
      'TabGroupNode($id, ${tabs.length} tabs, active=$activeIndex, '
      'side=$side)';

  /// Resolves the next active index after replacing [tabs] with [nextTabs].
  ///
  /// Keeps the current active tab selected when it still exists; otherwise
  /// falls back to [preferredIndex].
  int _activeIndexAfter(List<TabNode> nextTabs, {required int preferredIndex}) {
    if (nextTabs.isEmpty) return 0;
    final activeId = activeTab()?.id;
    if (activeId != null) {
      final index = nextTabs.indexWhere((tab) => tab.id == activeId);
      if (index >= 0) return index;
    }
    return preferredIndex.clamp(0, nextTabs.length - 1);
  }

  @override
  _NodeEditResult _editNode(
    String target,
    PlatNode? Function(PlatNode node) edit,
  ) {
    if (id == target) {
      final next = edit(this);
      return (node: next, found: true, changed: !identical(next, this));
    }
    for (var i = 0; i < tabs.length; i++) {
      final tab = tabs[i];
      final result = tab.child.id == target
          ? () {
              final next = edit(tab.child);
              return (
                node: next,
                found: true,
                changed: !identical(next, tab.child),
              );
            }()
          : tab.child._editNode(target, edit);
      if (!result.found) continue;
      if (!result.changed) return (node: this, found: true, changed: false);
      final updated = <TabNode>[...tabs.take(i)];
      final nextChild = result.node;
      final nextTab = nextChild == null
          ? null
          : tab.copyWith(child: nextChild).cleanTree();
      if (nextTab != null) updated.add(nextTab);
      updated.addAll(tabs.skip(i + 1));
      final normalized = _normalizeEditedTabs(updated);
      return (
        node: normalized,
        found: true,
        changed: !identical(normalized, this),
      );
    }
    return (node: this, found: false, changed: false);
  }

  PlatNode? _normalizeEditedTabs(List<TabNode> updated) {
    if (updated.isEmpty) return null;
    final nextActiveIndex = _activeIndexAfter(
      updated,
      preferredIndex: activeIndex,
    );
    if (_sameTabs(updated) && nextActiveIndex == activeIndex) {
      return this;
    }
    return copyWith(
      tabs: updated,
      activeIndex: nextActiveIndex < 0
          ? activeIndex.clamp(0, updated.length - 1)
          : nextActiveIndex,
    );
  }

  @override
  PlatNode? _resolveFocusTarget(String target) {
    for (final tab in tabs) {
      final child = tab.child;
      if (child.id == target) return child;
      final hit = child._resolveFocusTarget(target);
      if (hit != null) return hit;
    }
    return null;
  }

  bool _sameTabs(List<TabNode> updated) {
    if (updated.length != tabs.length) return false;
    for (var i = 0; i < updated.length; i++) {
      if (!identical(updated[i], tabs[i])) return false;
    }
    return true;
  }

  @override
  _FocusWriteResult _writeFocus(String focusId, {required bool seenTarget}) {
    final updated = <TabNode>[];
    var foundTarget = seenTarget;
    var changed = false;
    var nextActiveIndex = activeIndex;
    for (var i = 0; i < tabs.length; i++) {
      final tab = tabs[i];
      final needsVisit = !foundTarget || tab.child.focusedLeaf() != null;
      if (!needsVisit) {
        updated.add(tab);
        continue;
      }
      final result = tab.child._writeFocus(focusId, seenTarget: foundTarget);
      final nextTab = identical(result.node, tab.child)
          ? tab
          : tab.copyWith(child: result.node);
      updated.add(nextTab);
      if (result.foundTarget && !foundTarget) nextActiveIndex = i;
      foundTarget = result.foundTarget;
      changed = changed || result.changed;
    }
    if (foundTarget && nextActiveIndex != activeIndex) changed = true;
    if (!changed) return (node: this, foundTarget: foundTarget, changed: false);
    return (
      node: copyWith(tabs: updated, activeIndex: nextActiveIndex),
      foundTarget: foundTarget,
      changed: true,
    );
  }

  @override
  _FocusWriteResult _writeMaximized(String? maxId, {required bool seenTarget}) {
    final shouldMaximize = maxId == id;
    final updated = <TabNode>[];
    var foundTarget = seenTarget || shouldMaximize;
    var changed = maximized != shouldMaximize;
    for (final tab in tabs) {
      final needsVisit = !foundTarget || tab.child.maximizedPane() != null;
      if (!needsVisit) {
        updated.add(tab);
        continue;
      }
      final result = tab.child._writeMaximized(maxId, seenTarget: foundTarget);
      final nextTab = identical(result.node, tab.child)
          ? tab
          : tab.copyWith(child: result.node);
      updated.add(nextTab);
      foundTarget = result.foundTarget;
      changed = changed || result.changed;
    }
    if (!changed) return (node: this, foundTarget: foundTarget, changed: false);
    return (
      node: copyWith(
        tabs: updated,
        activeIndex: activeIndex.clamp(
          0,
          updated.isEmpty ? 0 : updated.length - 1,
        ),
        maximized: shouldMaximize,
      ),
      foundTarget: foundTarget,
      changed: true,
    );
  }
}
