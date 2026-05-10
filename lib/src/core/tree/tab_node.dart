part of 'tree.dart';

/// Metadata and content for a single tab inside a [TabGroupNode].
@internal
@immutable
final class TabNode {
  /// Child subtree rendered when this tab is active.
  final PlatNode child;

  /// Display label shown in chrome.
  final String title;

  /// When true, the tab is presented as pinned.
  final bool pinned;

  /// When true, the tab refuses to be closed or dragged.
  final bool locked;

  /// When true, the tab is the preview tab for its containing tab group.
  final bool preview;

  const TabNode({
    required this.child,
    this.title = '',
    this.pinned = false,
    this.locked = false,
    this.preview = false,
  }) : assert(
         !preview || (!pinned && !locked),
         'preview tabs cannot be pinned or locked',
       );

  /// Stable tab identity, reusing the wrapped root pane's id.
  String get id => child.id;

  /// Whether this tab's preview-related flag combination is valid.
  bool get hasValidPreviewState => !preview || (!pinned && !locked);

  /// Returns a structurally simplified copy,
  /// or `null` when the child collapses.
  TabNode? cleanTree() {
    final next = child.cleanTree();
    if (next == null) return null;
    if (identical(next, child)) return this;
    return copyWith(child: next);
  }

  /// Returns a copy with the named fields replaced.
  TabNode copyWith({
    PlatNode? child,
    String? title,
    bool? pinned,
    bool? locked,
    bool? preview,
  }) => TabNode(
    child: child ?? this.child,
    title: title ?? this.title,
    pinned: pinned ?? this.pinned,
    locked: locked ?? this.locked,
    preview: preview ?? this.preview,
  );

  /// Returns the first leaf in this tab's subtree, or `null` when none exists.
  LeafNode? firstLeaf() => child.firstLeaf();

  /// Whether any leaf in this tab currently holds focus.
  bool focused() => focusedLeaf() != null;

  /// Returns the first focused leaf in this tab's subtree, or `null` when none
  /// is focused.
  LeafNode? focusedLeaf() => child.focusedLeaf();
}
