part of 'tree.dart';

/// A structural wrapper around a single, optional [child].
///
/// Slots anchor stable ids in regions that may be empty, scope a
/// maximize to its subtree ([boundsMaximize]), and let chrome paint
/// around the child. A bare slot with no flags is decorative and
/// disappears when its child does; a [persistent] slot stays put as
/// an empty stub.
@internal
final class SlotNode extends PlatNode {
  /// The wrapped node, or `null` when the slot is empty.
  final PlatNode? child;

  /// When true, the slot survives losing its child and stays in the
  /// tree as an empty stub. When false (the default), the slot is
  /// pruned alongside its child.
  final bool persistent;

  /// When true, a maximize triggered inside this slot expands to fill
  /// the slot's bounds rather than the whole tree.
  final bool boundsMaximize;

  SlotNode({
    required super.id,
    this.child,
    this.persistent = false,
    this.boundsMaximize = false,
    super.size,
    super.hidden,
    super.maximized,
  });

  @override
  PlatNode? cleanTree() {
    final c = child;
    final next = c?.cleanTree();
    if (next == null && !persistent) return null;
    if (identical(next, c)) return this;
    return copyWith(child: next, clearChild: next == null);
  }

  /// Returns a copy with the named fields replaced. Pass
  /// `clearChild: true` to drop the child without supplying a
  /// replacement (the [child] argument is ignored when set).
  SlotNode copyWith({
    PlatNode? child,
    bool clearChild = false,
    bool? persistent,
    bool? boundsMaximize,
    PlatSize? size,
    bool? hidden,
    bool? maximized,
  }) => SlotNode(
    id: id,
    child: clearChild ? null : (child ?? this.child),
    persistent: persistent ?? this.persistent,
    boundsMaximize: boundsMaximize ?? this.boundsMaximize,
    size: size ?? this.size,
    hidden: hidden ?? this.hidden,
    maximized: maximized ?? this.maximized,
  );

  @override
  PlatNode? replace(String target, PlatNode? replacement) {
    if (id == target) return replacement;
    final c = child;
    if (c == null) return this;
    final PlatNode? next;
    if (c.id == target) {
      next = replacement;
    } else {
      next = switch (c) {
        final SplitNode s => s.replace(target, replacement),
        final TabGroupNode t => t.replace(target, replacement),
        final SlotNode s => s.replace(target, replacement),
        _ => c,
      };
    }
    if (identical(next, c)) return this;
    if (next == null && !persistent) return null;
    return copyWith(child: next, clearChild: next == null);
  }

  @override
  String toString() {
    final flags = [
      if (persistent) 'persistent',
      if (boundsMaximize) 'boundsMaximize',
    ].join(', ');
    final body = child == null ? 'empty' : '$child';
    return flags.isEmpty
        ? 'SlotNode($id, $body)'
        : 'SlotNode($id, $flags, $body)';
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
    final c = child;
    if (c == null) return (node: this, found: false, changed: false);
    final result = c._editNode(target, edit);
    if (!result.found) return (node: this, found: false, changed: false);
    if (!result.changed) return (node: this, found: true, changed: false);
    final next = result.node;
    if (next == null && !persistent) {
      return (node: null, found: true, changed: true);
    }
    return (
      node: copyWith(child: next, clearChild: next == null),
      found: true,
      changed: true,
    );
  }

  @override
  PlatNode? _resolveFocusTarget(String target) {
    final c = child;
    if (c == null) return null;
    if (c.id == target) return c;
    return c._resolveFocusTarget(target);
  }

  @override
  _FocusWriteResult _writeFocus(String focusId, {required bool seenTarget}) {
    final c = child;
    if (c == null) return (node: this, foundTarget: seenTarget, changed: false);
    if (seenTarget && c.focusedLeaf() == null) {
      return (node: this, foundTarget: true, changed: false);
    }
    final result = c._writeFocus(focusId, seenTarget: seenTarget);
    if (!result.changed) {
      return (node: this, foundTarget: result.foundTarget, changed: false);
    }
    return (
      node: copyWith(child: result.node),
      foundTarget: result.foundTarget,
      changed: true,
    );
  }

  @override
  _FocusWriteResult _writeMaximized(String? maxId, {required bool seenTarget}) {
    final shouldMaximize = maxId == id;
    final c = child;
    final foundTarget = seenTarget || shouldMaximize || maxId == null;
    if (c == null) {
      if (maximized == shouldMaximize) {
        return (node: this, foundTarget: foundTarget, changed: false);
      }
      return (
        node: copyWith(maximized: shouldMaximize),
        foundTarget: foundTarget,
        changed: true,
      );
    }
    final childCanChange = c.maximizedPane() != null || !seenTarget;
    final result = childCanChange
        ? c._writeMaximized(maxId, seenTarget: seenTarget || shouldMaximize)
        : (node: c, foundTarget: foundTarget, changed: false);
    final nextSelf = maximized == shouldMaximize
        ? this
        : copyWith(maximized: shouldMaximize);
    if (!childCanChange && identical(nextSelf, this)) {
      return (
        node: this,
        foundTarget: seenTarget || shouldMaximize,
        changed: false,
      );
    }
    final nextChild = childCanChange ? result.node : c;
    final changed =
        !identical(nextSelf, this) ||
        (childCanChange && !identical(nextChild, c));
    if (!changed) {
      return (node: this, foundTarget: result.foundTarget, changed: false);
    }
    return (
      node: copyWith(child: nextChild, maximized: shouldMaximize),
      foundTarget: result.foundTarget,
      changed: true,
    );
  }
}
