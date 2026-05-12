import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart' show internal;

import '../controller/controller.dart';
import '../core/foundation/foundation.dart';
import '../model/plat_snapshot.dart';
import 'divider.dart';
import 'render_split.dart';
import 'theme.dart';

/// Renders a [SplitSnapshot] via [PlatSplit]. Owns the per-split
/// [DividerInteraction] and forwards drag-end commits to the controller.
@internal
class SplitRender extends StatefulWidget {
  /// Snapshot of the split node.
  final SplitSnapshot view;
  final PlatController controller;
  final Widget Function(BuildContext, PlatSnapshot) childBuilder;

  const SplitRender({
    super.key,
    required this.view,
    required this.controller,
    required this.childBuilder,
  });

  @override
  State<SplitRender> createState() => _SplitRenderState();
}

class _SplitRenderState extends State<SplitRender> {
  final _interaction = DividerInteraction();

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final visible = [
      for (final child in view.children)
        if (!child.hidden) child,
    ];
    if (visible.isEmpty) return const SizedBox.shrink();

    final dividerTheme = PlatTheme.of(context).divider;
    return PlatSplit(
      interaction: _interaction,
      cursor: dividerTheme.cursor,
      resizable: view.resizable,
      hitSlop: dividerTheme.hitSlop,
      spacing: dividerTheme.thickness,
      axis: view.axis == .horizontal ? .horizontal : .vertical,
      onCommit: (sizes) => widget.controller.resizeSplit(
        view.id,
        _mergeVisibleSizes(view.children, sizes),
      ),
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) _divider(i - 1),
          _content(visible[i]),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _interaction.dispose();
    super.dispose();
  }

  Widget _content(PlatSnapshot child) => PlatSlotData.content(
    contentId: child.id,
    platSize: child.size,
    child: RepaintBoundary(child: widget.childBuilder(context, child)),
  );

  Widget _divider(int index) => PlatSlotData.divider(
    child: ListenableBuilder(
      listenable: _interaction,
      builder: (context, _) {
        final states = <WidgetState>{
          if (_interaction.hoveredIndex == index) .hovered,
          if (_interaction.draggingIndex == index) .dragged,
        };
        return PlatDivider(states: states);
      },
    ),
  );
}

List<PlatSize> _mergeVisibleSizes(
  List<PlatSnapshot> children,
  List<PlatSize> visibleSizes,
) {
  if (children.length == visibleSizes.length) return visibleSizes;

  final merged = <PlatSize>[];
  var visibleIndex = 0;
  for (final child in children) {
    if (child.hidden) {
      merged.add(child.size);
      continue;
    }
    if (visibleIndex >= visibleSizes.length) return visibleSizes;
    merged.add(visibleSizes[visibleIndex]);
    visibleIndex++;
  }
  return visibleIndex == visibleSizes.length ? merged : visibleSizes;
}
