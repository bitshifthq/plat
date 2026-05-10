part of 'tree.dart';

/// A single content cell in the layout tree.
///
/// Carries an opaque [data] payload, a [title] for chrome, and runtime flags
/// such as [locked] and [focused].
@internal
@immutable
final class LeafNode extends PlatNode {
  /// When true, the leaf refuses to be closed or dragged.
  final bool locked;

  /// True when this leaf currently holds focus inside its tree.
  final bool focused;

  /// When true, the leaf may be dragged by user interaction.
  final bool draggable;

  /// Display label shown in chrome.
  final String title;

  /// Opaque host payload. The tree carries it unchanged; what it means
  /// is up to the host's leaf builder.
  final Object? data;

  const LeafNode({
    required super.id,
    this.data,
    this.title = '',
    this.locked = false,
    this.focused = false,
    this.draggable = false,
    super.hidden = false,
    super.maximized = false,
    super.size = const .auto(),
  });

  @override
  int get hashCode => Object.hash(
    id,
    title,
    locked,
    draggable,
    data,
    size,
    hidden,
    focused,
    maximized,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeafNode &&
          other.id == id &&
          other.title == title &&
          other.locked == locked &&
          other.draggable == draggable &&
          other.data == data &&
          other.size == size &&
          other.hidden == hidden &&
          other.focused == focused &&
          other.maximized == maximized;

  @override
  PlatNode? cleanTree() => this;

  /// Returns a copy with the named fields replaced.
  LeafNode copyWith({
    Object? data,
    String? title,
    bool? locked,
    bool? draggable,
    PlatSize? size,
    bool? hidden,
    bool? focused,
    bool? maximized,
  }) => LeafNode(
    id: id,
    data: data ?? this.data,
    title: title ?? this.title,
    locked: locked ?? this.locked,
    draggable: draggable ?? this.draggable,
    size: size ?? this.size,
    hidden: hidden ?? this.hidden,
    focused: focused ?? this.focused,
    maximized: maximized ?? this.maximized,
  );

  @override
  String toString() {
    final flags = [
      if (locked) 'locked',
      if (draggable) 'draggable',
      if (focused) 'focused',
      if (maximized) 'maximized',
    ].join(', ');
    final body = title.isEmpty ? id : '$id, "$title"';
    return flags.isEmpty ? 'Leaf($body)' : 'Leaf($body, $flags)';
  }
}
