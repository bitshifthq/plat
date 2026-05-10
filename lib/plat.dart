/// Resizable, reorderable workspace layouts for Flutter.
///
/// A [Plat] is anything that can sit in the layout tree: a [PlatSplit],
/// [PlatTabGroup], [PlatSlot], or [PlatLeaf]. [PlatController] owns the tree
/// and drives mutations.
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
