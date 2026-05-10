part of 'tree.dart';

/// Arranges two or more [children] along an [axis], separated by
/// draggable dividers.
///
/// Each child claims its slot through its own [PlatSize]; dividers
/// rewrite the resizable children's `initial` extent on drag. A split
/// must always hold at least two children. Whenever pruning would
/// drop it below that, the surviving child takes the split's place
/// and inherits its [size]. See [cleanTree] and [_rewrite].
@internal
final class SplitNode extends PlatNode {
  /// Axis children are laid out along.
  final SplitAxis axis;

  /// When true, dividers in this split accept drag input and rewrite
  /// the resizable children's `initial` extent. When false, children
  /// keep their declared sizes verbatim.
  final bool resizable;

  /// The split's children, in order along [axis]. Always two or more.
  final List<PlatNode> children;

  SplitNode({
    required super.id,
    required this.axis,
    required this.children,
    this.resizable = true,
    super.size,
    super.hidden,
    super.maximized,
  }) : assert(children.length >= 2, 'splits need at least two children');

  @override
  PlatNode? cleanTree() {
    List<PlatNode>? out;
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final next = child.cleanTree();
      final inline = next is SplitNode && _shouldInline(next);
      if (next == null || inline || !identical(next, child)) {
        out ??= List.of(children.take(i));
      }
      if (next == null) continue;
      if (inline) {
        out!.addAll(next.children);
      } else {
        out?.add(next);
      }
    }
    if (out == null) return this;
    if (out.isEmpty) return null;
    if (out.length == 1) return out.single.resize(size);
    return copyWith(children: out);
  }

  /// Returns a copy with the named fields replaced.
  SplitNode copyWith({
    SplitAxis? axis,
    List<PlatNode>? children,
    bool? resizable,
    PlatSize? size,
    bool? hidden,
    bool? maximized,
  }) => SplitNode(
    id: id,
    axis: axis ?? this.axis,
    children: children ?? this.children,
    resizable: resizable ?? this.resizable,
    size: size ?? this.size,
    hidden: hidden ?? this.hidden,
    maximized: maximized ?? this.maximized,
  );

  /// Returns the nearest split on the path to [target] that owns [target] as a
  /// direct child.
  ({SplitNode parent, int index})? parentOf(String target) {
    final path = pathTo(target);
    if (path == null || path.length < 2) return null;
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

  @override
  PlatNode? replace(String target, PlatNode? replacement) {
    if (id == target) return replacement;
    return _rewrite(target, replacement);
  }

  @override
  String toString() => 'SplitNode($id, $axis, ${children.length} children)';

  @override
  _NodeEditResult _editNode(
    String target,
    PlatNode? Function(PlatNode node) edit,
  ) {
    if (id == target) {
      final next = edit(this);
      return (node: next, found: true, changed: !identical(next, this));
    }
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final result = child.id == target
          ? () {
              final next = edit(child);
              return (
                node: next,
                found: true,
                changed: !identical(next, child),
              );
            }()
          : child._editNode(target, edit);
      if (!result.found) continue;
      if (!result.changed) return (node: this, found: true, changed: false);
      final updated = <PlatNode>[...children.take(i)];
      final next = result.node;
      if (next case final SplitNode split when _shouldInline(split)) {
        updated.addAll(split.children);
      } else if (next != null) {
        updated.add(next);
      }
      updated.addAll(children.skip(i + 1));
      final normalized = _normalizeEditedChildren(updated);
      return (
        node: normalized,
        found: true,
        changed: !identical(normalized, this),
      );
    }
    return (node: this, found: false, changed: false);
  }

  PlatNode? _normalizeEditedChildren(List<PlatNode> updated) {
    if (updated.isEmpty) return null;
    if (updated.length == 1) return updated.single.resize(size);
    if (_sameChildren(updated)) return this;
    return copyWith(children: updated);
  }

  @override
  PlatNode? _resolveFocusTarget(String target) {
    for (final child in children) {
      if (child.id == target) return child;
      final hit = child._resolveFocusTarget(target);
      if (hit != null) return hit;
    }
    return null;
  }

  PlatNode? _rewrite(String target, PlatNode? replacement) {
    List<PlatNode>? out;
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final next = child.id == target
          ? replacement
          : switch (child) {
              final SplitNode s => s._rewrite(target, replacement),
              final TabGroupNode t => t.replace(target, replacement),
              final SlotNode s => s.replace(target, replacement),
              _ => child,
            };
      if (identical(next, child)) {
        out?.add(child);
        continue;
      }
      out ??= List.of(children.take(i));
      if (next == null) continue;
      if (next is SplitNode && _shouldInline(next)) {
        out.addAll(next.children);
      } else {
        out.add(next);
      }
    }
    if (out == null) return this;
    if (out.isEmpty) return null;
    if (out.length == 1) {
      // Carry our size onto the survivor so the parent's layout doesn't
      // shift just because the inner structure simplified.
      return out.single.resize(size);
    }
    return copyWith(children: out);
  }

  bool _sameChildren(List<PlatNode> updated) {
    if (updated.length != children.length) return false;
    for (var i = 0; i < updated.length; i++) {
      if (!identical(updated[i], children[i])) return false;
    }
    return true;
  }

  bool _shouldInline(SplitNode inner) =>
      inner.axis == axis && inner.resizable && resizable;

  @override
  _FocusWriteResult _writeFocus(String focusId, {required bool seenTarget}) {
    final updated = <PlatNode>[];
    var foundTarget = seenTarget;
    var changed = false;
    for (final child in children) {
      if (foundTarget && child.focusedLeaf() == null) {
        updated.add(child);
        continue;
      }
      final result = child._writeFocus(focusId, seenTarget: foundTarget);
      updated.add(result.node);
      foundTarget = result.foundTarget;
      changed = changed || result.changed;
    }
    if (!changed) return (node: this, foundTarget: foundTarget, changed: false);
    return (
      node: copyWith(children: updated),
      foundTarget: foundTarget,
      changed: true,
    );
  }

  @override
  _FocusWriteResult _writeMaximized(String? maxId, {required bool seenTarget}) {
    final shouldMaximize = maxId == id;
    final updated = <PlatNode>[];
    var foundTarget = seenTarget || shouldMaximize;
    var changed = maximized != shouldMaximize;
    for (final child in children) {
      if (foundTarget && child.maximizedPane() == null) {
        updated.add(child);
        continue;
      }
      final result = child._writeMaximized(maxId, seenTarget: foundTarget);
      updated.add(result.node);
      foundTarget = result.foundTarget;
      changed = changed || result.changed;
    }
    if (!changed) return (node: this, foundTarget: foundTarget, changed: false);
    return (
      node: copyWith(children: updated, maximized: shouldMaximize),
      foundTarget: foundTarget,
      changed: true,
    );
  }
}
