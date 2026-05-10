import 'package:meta/meta.dart' show internal;

import '../core/tree/tree.dart';
import '../model/plat.dart';

const _invalidLowerResult = (valid: false, node: null);

/// Compiles a [Plat] description into a tree of [PlatNode]s.
///
/// Validates that every provided id in [layout] is unique and runs the result
/// through [PlatNode.cleanTree], so the returned tree carries no empty
/// tab groups, redundant single-child splits, or non-persistent slots
/// around nothing. Returns `null` when the entire layout collapses to
/// nothing. Throws [ArgumentError] on duplicate provided ids.
@internal
PlatNode? lowerPane(Plat layout) {
  final duplicate = _duplicateId(layout, <String>{});
  if (duplicate != null) {
    throw ArgumentError(
      'duplicate Plat id "$duplicate": every node, including '
      'leaves, needs a unique String',
    );
  }
  return _lower(layout).cleanTree();
}

@internal
TabNode lowerTab(PlatTab tab) {
  if (tab.preview && (tab.pinned || tab.locked)) {
    throw ArgumentError.value(
      tab,
      'tab',
      'preview tabs cannot be pinned or locked',
    );
  }
  final child = lowerPane(tab.child);
  if (child == null) {
    throw ArgumentError.value(tab, 'tab', 'collapses to an empty tree');
  }
  return TabNode(
    child: child,
    title: tab.title,
    pinned: tab.pinned,
    locked: tab.locked,
    preview: tab.preview,
  );
}

/// Non-throwing variant used by controller attach APIs.
@internal
PlatNode? tryLowerPane(Plat layout) {
  if (_duplicateId(layout, <String>{}) != null) return null;
  return _tryLower(layout)?.cleanTree();
}

/// Non-throwing root-lowering variant.
///
/// Unlike [tryLowerPane], a root layout that structurally collapses to nothing
/// is still valid and reports `(valid: true, node: null)`.
@internal
LowerResult tryLowerRootPane(Plat layout) {
  if (_duplicateId(layout, <String>{}) != null) {
    return _invalidLowerResult;
  }
  final lowered = _tryLowerRoot(layout);
  if (!lowered.valid) return lowered;
  return _validLowerResult(lowered.node?.cleanTree());
}

/// Non-throwing variant used by controller attach APIs.
@internal
TabNode? tryLowerTab(PlatTab tab) {
  if (tab.preview && (tab.pinned || tab.locked)) return null;
  final child = tryLowerPane(tab.child);
  if (child == null) return null;
  return TabNode(
    child: child,
    title: tab.title,
    pinned: tab.pinned,
    locked: tab.locked,
    preview: tab.preview,
  );
}

String? _duplicateId(Plat node, Set<String> seen) {
  final id = node.id;
  if (id != null && !seen.add(id)) return id;
  return switch (node) {
    PlatSplit(:final children) => _firstDuplicateIn([
      for (final child in children) child,
    ], seen),
    PlatTabGroup(:final tabs) => _firstDuplicateIn([
      for (final tab in tabs) tab.child,
    ], seen),
    PlatSlot(:final child) => child == null ? null : _duplicateId(child, seen),
    PlatLeaf() => null,
  };
}

String? _firstDuplicateIn(List<Plat> nodes, Set<String> seen) {
  for (final node in nodes) {
    final duplicate = _duplicateId(node, seen);
    if (duplicate != null) return duplicate;
  }
  return null;
}

String _idOf(Plat pane) => pane.id ?? generateNodeId();

PlatNode _lower(Plat node) => switch (node) {
  final PlatSplit split => SplitNode(
    id: _idOf(split),
    axis: split.axis,
    size: split.size,
    resizable: split.resizable,
    children: [for (final child in split.children) _lower(child)],
  ),
  final PlatTabGroup tabs => () {
    final previewCount = tabs.tabs.where((tab) => tab.preview).length;
    if (previewCount > 1) {
      throw ArgumentError.value(
        tabs,
        'tabs',
        'a tab group may contain at most one preview tab',
      );
    }
    return TabGroupNode(
      id: _idOf(tabs),
      side: tabs.side,
      size: tabs.size,
      activeIndex: tabs.activeIndex,
      acceptsDrops: tabs.acceptsDrops,
      tabs: [for (final tab in tabs.tabs) lowerTab(tab)],
    );
  }(),
  final PlatLeaf leaf => _lowerLeaf(leaf),
  final PlatSlot slot => SlotNode(
    id: _idOf(slot),
    size: slot.size,
    persistent: slot.persistent,
    boundsMaximize: slot.boundsMaximize,
    child: slot.child == null ? null : _lower(slot.child!),
  ),
};

LeafNode _lowerLeaf(PlatLeaf leaf) => LeafNode(
  id: _idOf(leaf),
  size: leaf.size,
  data: leaf.data,
  title: leaf.title,
  locked: leaf.locked,
  draggable: leaf.draggable,
);

PlatNode? _tryLower(Plat node) => switch (node) {
  final PlatSplit split => _tryLowerSplit(split),
  final PlatTabGroup tabs => _tryLowerTabs(tabs),
  final PlatLeaf leaf => _lowerLeaf(leaf),
  final PlatSlot slot => _tryLowerSlot(slot),
};

LowerResult _tryLowerRoot(Plat node) => switch (node) {
  final PlatSplit split => _tryLowerRootSplit(split),
  final PlatTabGroup tabs => _tryLowerRootTabs(tabs),
  final PlatLeaf leaf => _validLowerResult(_lowerLeaf(leaf)),
  final PlatSlot slot => _tryLowerRootSlot(slot),
};

LowerResult _tryLowerRootSlot(PlatSlot slot) {
  final child = slot.child;
  final PlatNode? lowered;
  if (child == null) {
    lowered = null;
  } else {
    final result = _tryLowerRoot(child);
    if (!result.valid) return result;
    lowered = result.node;
  }
  return _validLowerResult(
    SlotNode(
      id: _idOf(slot),
      size: slot.size,
      persistent: slot.persistent,
      boundsMaximize: slot.boundsMaximize,
      child: lowered,
    ),
  );
}

LowerResult _tryLowerRootSplit(PlatSplit split) {
  final children = <PlatNode>[];
  for (final child in split.children) {
    final lowered = _tryLowerRoot(child);
    if (!lowered.valid) return lowered;
    final node = lowered.node?.cleanTree();
    if (node != null) children.add(node);
  }
  return _validLowerResult(
    SplitNode(
      id: _idOf(split),
      axis: split.axis,
      size: split.size,
      resizable: split.resizable,
      children: children,
    ),
  );
}

LowerResult _tryLowerRootTabs(PlatTabGroup tabs) {
  final previewCount = tabs.tabs.where((tab) => tab.preview).length;
  if (previewCount > 1) return _invalidLowerResult;

  final loweredTabs = <TabNode>[];
  for (final tab in tabs.tabs) {
    if (tab.preview && (tab.pinned || tab.locked)) {
      return _invalidLowerResult;
    }
    final child = _tryLowerRoot(tab.child);
    if (!child.valid || child.node == null) return _invalidLowerResult;
    loweredTabs.add(
      TabNode(
        child: child.node!,
        title: tab.title,
        pinned: tab.pinned,
        locked: tab.locked,
        preview: tab.preview,
      ),
    );
  }

  return _validLowerResult(
    TabGroupNode(
      id: _idOf(tabs),
      side: tabs.side,
      size: tabs.size,
      activeIndex: tabs.activeIndex,
      acceptsDrops: tabs.acceptsDrops,
      tabs: loweredTabs,
    ),
  );
}

SlotNode? _tryLowerSlot(PlatSlot slot) {
  final child = slot.child;
  final PlatNode? lowered;
  if (child == null) {
    lowered = null;
  } else {
    lowered = _tryLower(child);
    if (lowered == null) return null;
  }
  return SlotNode(
    id: _idOf(slot),
    size: slot.size,
    persistent: slot.persistent,
    boundsMaximize: slot.boundsMaximize,
    child: lowered,
  );
}

SplitNode? _tryLowerSplit(PlatSplit split) {
  final children = <PlatNode>[];
  for (final child in split.children) {
    final lowered = _tryLower(child);
    if (lowered == null) return null;
    children.add(lowered);
  }
  return SplitNode(
    id: _idOf(split),
    axis: split.axis,
    size: split.size,
    resizable: split.resizable,
    children: children,
  );
}

TabGroupNode? _tryLowerTabs(PlatTabGroup tabs) {
  final previewCount = tabs.tabs.where((tab) => tab.preview).length;
  if (previewCount > 1) return null;

  final loweredTabs = <TabNode>[];
  for (final tab in tabs.tabs) {
    final lowered = tryLowerTab(tab);
    if (lowered == null) return null;
    loweredTabs.add(lowered);
  }

  return TabGroupNode(
    id: _idOf(tabs),
    side: tabs.side,
    size: tabs.size,
    activeIndex: tabs.activeIndex,
    acceptsDrops: tabs.acceptsDrops,
    tabs: loweredTabs,
  );
}

LowerResult _validLowerResult(PlatNode? node) => (valid: true, node: node);

@internal
typedef LowerResult = ({bool valid, PlatNode? node});
