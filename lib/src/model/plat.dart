import '../core/foundation/foundation.dart';

/// Declarative description of a layout tree.
///
/// `Plat` is a closed value hierarchy: rows, columns, tab groups, slots, and
/// leaves. Compose the shape with the named factories ([Plat.row],
/// [Plat.column], [Plat.tabs], [Plat.slot], [Plat.leaf]) and [PlatTab.leaf].
///
/// ```dart
/// final controller = PlatController(
///   initialPlat: const .row(
///     id: 'root',
///     children: [
///       .tabs(
///         [
///           PlatTab(
///             child: .leaf(id: 'a', title: 'a.dart'),
///             title: 'a.dart',
///           ),
///         ],
///         id: 'left',
///       ),
///       .column(
///         id: 'right',
///         children: [
///           .tabs(
///             [
///               PlatTab(
///                 child: .leaf(id: 'b', title: 'b.dart'),
///                 title: 'b.dart',
///               ),
///             ],
///             id: 'top',
///           ),
///           .slot(
///             id: 'term-slot',
///             child: .tabs(
///               [
///                 PlatTab(
///                   child: .leaf(id: 'term', title: 'Terminal'),
///                   title: 'Terminal',
///                 ),
///               ],
///               id: 'term',
///             ),
///           ),
///         ],
///       ),
///     ],
///   ),
/// );
/// ```
///
/// Nodes may carry an [id]. Omit it for throwaway panes; lowering assigns a
/// generated runtime id. Provide a const id for panes that will be addressed
/// later, such as panes you hide, focus, resize, drop onto, or dispatch in a
/// builder. Provided ids in one `Plat` tree must be unique.
///
/// Every `Plat` constructor and factory is `const`. Prefer const layout values
/// when the shape is static.
sealed class Plat {
  /// Stable identity for the node this `Plat` describes, or `null` when
  /// lowering should generate one.
  final String? id;

  /// Allocation hint applied when this node sits inside a parent split.
  final PlatSize size;

  const Plat({this.id, this.size = const .auto()});

  /// A vertical split over [children]. Shorthand for [PlatSplit.column].
  const factory Plat.column({
    String? id,
    required List<Plat> children,
    PlatSize size,
    bool resizable,
  }) = PlatSplit.column;

  /// A standalone leaf. Redirects to [PlatLeaf.new].
  const factory Plat.leaf({
    String? id,
    PlatSize size,
    Object? data,
    String title,
    bool locked,
    bool draggable,
  }) = PlatLeaf;

  /// A horizontal split over [children]. Shorthand for [PlatSplit.row].
  const factory Plat.row({
    String? id,
    required List<Plat> children,
    PlatSize size,
    bool resizable,
  }) = PlatSplit.row;

  /// A structural slot wrapping an optional [child]. Redirects to
  /// [PlatSlot.new].
  const factory Plat.slot({
    String? id,
    PlatSize size,
    Plat? child,
    bool persistent,
    bool boundsMaximize,
  }) = PlatSlot;

  /// A tab group over [tabs]. Redirects to [PlatTabGroup.new].
  const factory Plat.tabs(
    List<PlatTab> tabs, {
    String? id,
    PlatSize size,
    int activeIndex,
    bool acceptsDrops,
    TabBarSide side,
  }) = PlatTabGroup;
}

/// Metadata and content for a single tab inside a [PlatTabGroup].
///
/// Tabs are wrappers around a single root [child] pane. The wrapped pane may
/// be a [PlatLeaf], a [PlatSplit], a [PlatSlot], or another [PlatTabGroup],
/// which is what enables nested tabbed layouts.
final class PlatTab {
  /// Root pane rendered when this tab is active.
  final Plat child;

  /// Display label shown in chrome.
  final String title;

  /// When true, the tab is presented as pinned.
  final bool pinned;

  /// When true, the tab refuses to be closed or dragged.
  final bool locked;

  /// When true, the tab is the preview tab for its containing tab group.
  final bool preview;

  const PlatTab({
    required this.child,
    this.title = '',
    this.pinned = false,
    this.locked = false,
    this.preview = false,
  }) : assert(
         !preview || (!pinned && !locked),
         'preview tabs cannot be pinned or locked',
       );

  /// Convenience constructor for a tab backed by a single [PlatLeaf].
  factory PlatTab.leaf({
    String? id,
    PlatSize size = const .auto(),
    Object? data,
    String title = '',
    bool pinned = false,
    bool locked = false,
    bool preview = false,
  }) => PlatTab(
    child: .leaf(id: id, size: size, data: data, title: title, locked: locked),
    title: title,
    pinned: pinned,
    locked: locked,
    preview: preview,
  );

  /// Stable tab identity when provided. The tab reuses the wrapped root
  /// pane's id; `null` means lowering will generate one.
  String? get id => child.id;
}

/// A standalone leaf as a structural node.
///
/// Use for sidebars, tool strips, or any single-leaf region outside a tab
/// group.
///
/// `PlatLeaf` carries no `focused` field; focus is runtime state owned by the
/// controller. Seed it after construction with [PlatController.focus].
final class PlatLeaf extends Plat {
  /// Opaque host payload. The host's leaf builder dispatches on this
  /// to render the leaf's content.
  final Object? data;

  /// Display label shown in chrome.
  final String title;

  /// When true, the leaf refuses close and drag operations.
  final bool locked;

  /// When true, the default UI may expose a handle for dragging this leaf.
  final bool draggable;

  const PlatLeaf({
    super.id,
    super.size,
    this.data,
    this.title = '',
    this.locked = false,
    this.draggable = false,
  });
}

/// A structural wrapper around a single, optional [child].
///
/// Slots anchor stable ids in regions that may be empty, keep maximize inside
/// a subtree ([boundsMaximize]), and let chrome paint around the child. A bare
/// slot with no flags is decorative and disappears with its child; a
/// [persistent] slot stays in the tree as an empty stub.
final class PlatSlot extends Plat {
  /// The wrapped pane, or `null` for an empty slot.
  final Plat? child;

  /// When true, the slot survives losing its child and stays in the
  /// tree as an empty stub.
  final bool persistent;

  /// When true, a maximize triggered inside this slot expands to
  /// fill the slot's bounds rather than the whole tree.
  final bool boundsMaximize;

  const PlatSlot({
    super.id,
    super.size,
    this.child,
    this.persistent = false,
    this.boundsMaximize = false,
  });
}

/// A split over [children] along [axis].
///
/// Use the [PlatSplit.row] / [PlatSplit.column] factories, or the
/// corresponding [Plat.row] / [Plat.column] shorthand, when the axis
/// is fixed at the call site.
final class PlatSplit extends Plat {
  /// Axis children are laid out along.
  final SplitAxis axis;

  /// When true, the dividers in this split accept drag input and
  /// rewrite the resizable children's `initial` extent. When false,
  /// children keep their declared sizes verbatim.
  final bool resizable;

  /// Children, in order along [axis]. Two or more.
  final List<Plat> children;

  const PlatSplit({
    super.id,
    required this.axis,
    required this.children,
    super.size,
    this.resizable = true,
  });

  /// A vertical split over [children].
  const factory PlatSplit.column({
    String? id,
    required List<Plat> children,
    PlatSize size,
    bool resizable,
  }) = PlatSplit._column;

  /// A horizontal split over [children].
  const factory PlatSplit.row({
    String? id,
    required List<Plat> children,
    PlatSize size,
    bool resizable,
  }) = PlatSplit._row;

  const PlatSplit._column({
    super.id,
    required this.children,
    super.size,
    this.resizable = true,
  }) : axis = .vertical;

  const PlatSplit._row({
    super.id,
    required this.children,
    super.size,
    this.resizable = true,
  }) : axis = .horizontal;
}

/// A tab group over [tabs].
///
/// The active tab's child subtree is rendered; the rest are available through
/// the tab bar.
final class PlatTabGroup extends Plat {
  /// Edge of the body where the tab bar sits.
  final TabBarSide side;

  /// Index of the tab that starts active. In `[0, tabs.length)`,
  /// or `0` when [tabs] is empty.
  final int activeIndex;

  /// When true, this group's body accepts tab drops from other groups or views.
  /// Tab-strip reordering still works when false.
  final bool acceptsDrops;

  /// The tabs in this group, in display order.
  final List<PlatTab> tabs;

  const PlatTabGroup(
    this.tabs, {
    super.id,
    super.size,
    this.activeIndex = 0,
    this.acceptsDrops = true,
    this.side = .top,
  });
}
