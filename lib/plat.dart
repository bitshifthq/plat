/// Resizable, reorderable workspace layouts for Flutter.
///
/// A [Plat] is anything that can sit in the layout tree: a [PlatSplit],
/// [PlatTabGroup], [PlatSlot], or [PlatLeaf]. [PlatController] owns the tree
/// and drives mutations.
///
/// ```dart
/// import 'package:plat/plat.dart';
///
/// final controller = PlatController(
///   initialPlat: .tabs([
///     .leaf(title: 'a.dart'),
///     .leaf(title: 'b.dart'),
///   ]),
/// );
///
/// PlatView(
///   controller: controller,
///   leafBuilder: (context, leaf) => MyEditor(leaf: leaf),
/// );
/// ```
///
/// When multiple [PlatView]s should share state across cross-view moves, wrap
/// their common ancestor in a [PlatScope].
///
/// Visuals (tab chrome, divider colors, drop hints, and animation timing) live
/// in [PlatThemeData]. Wrap a [PlatView] in [PlatTheme] to override them.
library;

export 'src/controller/controller.dart' show PlatController;
export 'src/core/foundation/foundation.dart'
    show IdConflict, PlatExtent, PlatSide, PlatSize, SplitAxis, TabBarSide;
export 'src/model/plat.dart'
    show Plat, PlatLeaf, PlatSlot, PlatSplit, PlatTab, PlatTabGroup;
export 'src/model/plat_snapshot.dart'
    show
        LeafSnapshot,
        PlatSnapshot,
        SlotSnapshot,
        SplitSnapshot,
        TabGroupSnapshot,
        TabSnapshot;
export 'src/ui/divider.dart' show PlatDivider;
export 'src/ui/drop/drop_attempt.dart' show DropAttempt, DropPolicy;
export 'src/ui/drop/drop_zone.dart' show DropZone;
export 'src/ui/pane_view.dart' show LeafBuilder, SlotBuilder;
export 'src/ui/plat_scope.dart' show PlatScope;
export 'src/ui/plat_view.dart' show PlatView;
export 'src/ui/tabs/bar.dart'
    show DragFeedbackBuilder, PlatTabBar, PlatTabBarBuilder, PlatTabBuilder;
export 'src/ui/tabs/chip.dart'
    show PlatTabChip, PlatTabCloseButton, PlatTabDetails;
export 'src/ui/theme.dart'
    show
        PlatDividerTheme,
        PlatDropHintTheme,
        PlatTabBarTheme,
        PlatTheme,
        PlatThemeData,
        TabStripAlignment,
        TabStripFit;
