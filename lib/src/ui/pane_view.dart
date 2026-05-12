import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart' show internal;

import '../controller/controller.dart';
import '../model/plat_snapshot.dart';
import 'drop/drop_attempt.dart';
import 'drop/overlay.dart' show DropOverlay;
import 'leaf_drag_handle.dart';
import 'leaf_host.dart';
import 'plat_scope.dart';
import 'select_builder.dart';
import 'split.dart';
import 'tabs/bar.dart';
import 'tabs/view.dart';

bool _slotPassThroughChanged(SlotSnapshot a, SlotSnapshot b) {
  return a.id != b.id ||
      a.size != b.size ||
      a.hidden != b.hidden ||
      a.maximized != b.maximized ||
      a.persistent != b.persistent ||
      a.boundsMaximize != b.boundsMaximize ||
      a.child?.id != b.child?.id;
}

bool _splitLayoutChanged(SplitSnapshot a, SplitSnapshot b) {
  if (a.id != b.id ||
      a.size != b.size ||
      a.hidden != b.hidden ||
      a.maximized != b.maximized ||
      a.axis != b.axis ||
      a.resizable != b.resizable ||
      a.children.length != b.children.length) {
    return true;
  }

  for (var i = 0; i < a.children.length; i++) {
    final left = a.children[i];
    final right = b.children[i];
    if (left.id != right.id ||
        left.size != right.size ||
        left.hidden != right.hidden) {
      return true;
    }
  }
  return false;
}

/// Renders a leaf's body.
///
/// Used for standalone leaves (sidebars, tool strips) and active tab contents.
typedef LeafBuilder = Widget Function(BuildContext context, LeafSnapshot leaf);

/// Renders a [PlatSlot] wrapper. [child] is the already-built widget for
/// the slot's child node, or `null` when the slot is empty.
typedef SlotBuilder =
    Widget Function(BuildContext context, SlotSnapshot slot, Widget? child);

/// Renders one pane and subscribes only to that pane's snapshot.
///
/// The selector keeps the public snapshot value, while [buildWhen] narrows
/// wrapper rebuilds to the fields each render layer actually consumes.
@internal
final class PlatPaneView extends StatelessWidget {
  final String paneId;
  final DropPolicy? dropPolicy;
  final LeafBuilder leafBuilder;
  final PlatController controller;
  final PlatTabBarBuilder? tabBar;
  final SlotBuilder? slotBuilder;

  const PlatPaneView({
    super.key,
    required this.paneId,
    required this.tabBar,
    required this.controller,
    required this.dropPolicy,
    required this.leafBuilder,
    required this.slotBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SelectListenableBuilder<PlatController, PlatSnapshot?>(
      listenable: controller,
      buildWhen: _shouldRebuildPane,
      selector: (controller) => controller.snapshot(paneId),
      builder: (context, snapshot) {
        if (snapshot == null) return const SizedBox.shrink();
        final child = switch (snapshot) {
          final SplitSnapshot s => SplitRender(
            view: s,
            controller: controller,
            childBuilder: (_, child) => _childPane(child.id),
          ),
          final TabGroupSnapshot t => PlatTabGroupView(
            view: t,
            tabBar: tabBar,
            controller: controller,
            dropPolicy: dropPolicy,
            platBuilder: _childPane,
          ),
          final SlotSnapshot s => _renderSlot(context, s),
          final LeafSnapshot l => () {
            final registry = platLeafKeyRegistryOf(context);
            final leafKey = registry.leafKeyFor(l.id);
            return PlatLeafDragHandleHost(
              leaf: l,
              controller: controller,
              child: PlatLeafHost(
                key: leafKey,
                leafId: l.id,
                registry: registry,
                child: leafBuilder(context, l),
              ),
            );
          }(),
        };

        if (snapshot case TabGroupSnapshot()) return child;

        return DropOverlay(
          target: snapshot,
          controller: controller,
          dropPolicy: dropPolicy,
          child: child,
        );
      },
    );
  }

  Widget _childPane(String paneId) {
    return PlatPaneView(
      paneId: paneId,
      tabBar: tabBar,
      key: ValueKey(paneId),
      dropPolicy: dropPolicy,
      controller: controller,
      leafBuilder: leafBuilder,
      slotBuilder: slotBuilder,
    );
  }

  Widget _renderSlot(BuildContext context, SlotSnapshot slot) {
    final child = slot.child == null ? null : _childPane(slot.child!.id);
    final withSlot = slotBuilder?.call(context, slot, child);
    return withSlot ?? child ?? const SizedBox.shrink();
  }

  bool _shouldRebuildPane(PlatSnapshot? previous, PlatSnapshot? next) {
    if (previous == null || next == null) return previous != next;
    if (previous.runtimeType != next.runtimeType) return true;

    return switch ((previous, next)) {
      (final SplitSnapshot a, final SplitSnapshot b) => _splitLayoutChanged(
        a,
        b,
      ),
      (final SlotSnapshot a, final SlotSnapshot b) =>
        slotBuilder == null ? _slotPassThroughChanged(a, b) : a != b,
      _ => previous != next,
    };
  }
}
