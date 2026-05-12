import 'package:flutter/material.dart' show Theme;
import 'package:flutter/rendering.dart' show RenderBox, RenderClipRRect;
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart' show internal;

import '../../controller/controller.dart';
import '../../model/plat_snapshot.dart';
import '../theme.dart';
import 'drag_payload.dart';
import 'drop_attempt.dart';
import 'drop_operation.dart';
import 'drop_zone.dart';

typedef _AncestorClip = ({
  BorderRadius radius,
  bool touchesLeft,
  bool touchesRight,
  bool touchesTop,
  bool touchesBottom,
});

typedef _DropGeometry = ({DropZone zone, DropZone nearestSide});

/// Overlays a node's body to detect edge / center drops. The outer
/// [PlatDropHintTheme.edgeFraction] on each side is an edge zone; the
/// inner area is center.
@internal
class DropOverlay extends StatefulWidget {
  final Widget child;
  final PlatSnapshot target;
  final PlatController controller;
  final DropPolicy? dropPolicy;

  const DropOverlay({
    super.key,
    required this.target,
    required this.controller,
    required this.child,
    this.dropPolicy,
  });

  @override
  State<DropOverlay> createState() => _DropOverlayState();
}

class _DropOverlayState extends State<DropOverlay> {
  DropZone? _zone;
  _AncestorClip? _clip;

  @override
  Widget build(BuildContext context) {
    final theme = PlatTheme.of(context);
    return DragTarget<PlatDragPayload>(
      onWillAcceptWithDetails: (d) => _hover(d, theme),
      onMove: (d) => _hover(d, theme),
      onLeave: (_) => _setHover(null, null),
      onAcceptWithDetails: (d) {
        final operation = _operationFor(d, theme);
        _setHover(null, null);
        operation?.accept();
      },
      builder: (context, _, _) => Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_zone != null)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedSwitcher(
                  duration: theme.dropHint.duration,
                  transitionBuilder: theme.dropHint.transitionBuilder,
                  child: _ZoneHint(
                    key: ValueKey(_zone),
                    zone: _zone!,
                    clip: _clip,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  _AncestorClip? _ancestorClip() {
    final clip = context.findAncestorWidgetOfExactType<ClipRRect>();
    final geometry = clip?.borderRadius;
    if (geometry == null) return null;
    final box = context.findRenderObject() as RenderBox?;
    final clipBox = context.findAncestorRenderObjectOfType<RenderClipRRect>();
    if (box == null || clipBox == null || !box.hasSize || !clipBox.hasSize) {
      return null;
    }
    final offset = box.localToGlobal(Offset.zero);
    final clipOffset = clipBox.localToGlobal(Offset.zero);
    final rightInset =
        clipOffset.dx + clipBox.size.width - (offset.dx + box.size.width);
    final bottomInset =
        clipOffset.dy + clipBox.size.height - (offset.dy + box.size.height);
    const epsilon = 0.5;
    return (
      radius: geometry.resolve(Directionality.maybeOf(context)),
      touchesLeft: (offset.dx - clipOffset.dx).abs() <= epsilon,
      touchesRight: rightInset.abs() <= epsilon,
      touchesTop: (offset.dy - clipOffset.dy).abs() <= epsilon,
      touchesBottom: bottomInset.abs() <= epsilon,
    );
  }

  _DropGeometry _dropGeometry(Offset local, Size size, double edgeFraction) {
    final fx = local.dx / size.width;
    final fy = local.dy / size.height;
    final edges = [fx, 1 - fx, fy, 1 - fy];
    final minEdge = edges.reduce((a, b) => a < b ? a : b);
    final nearestSide = switch (edges.indexOf(minEdge)) {
      0 => DropZone.left,
      1 => DropZone.right,
      2 => DropZone.top,
      _ => DropZone.bottom,
    };
    return (
      zone: minEdge >= edgeFraction ? DropZone.center : nearestSide,
      nearestSide: nearestSide,
    );
  }

  bool _hover(DragTargetDetails<PlatDragPayload> d, PlatThemeData theme) {
    final operation = _operationFor(d, theme);
    _setHover(operation?.zone, operation == null ? null : _ancestorClip());
    return operation != null;
  }

  void _setHover(DropZone? zone, _AncestorClip? clip) {
    if (_zone == zone && _clip == clip) return;
    setState(() {
      _zone = zone;
      _clip = clip;
    });
  }

  DropOperation? _operationFor(
    DragTargetDetails<PlatDragPayload> d,
    PlatThemeData theme,
  ) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final local = box.globalToLocal(d.offset + d.data.feedbackAnchor);
    if (!(Offset.zero & box.size).contains(local)) return null;
    final geometry = _dropGeometry(
      local,
      box.size,
      theme.dropHint.edgeFraction,
    );

    return resolveDropOperation(
      controller: widget.controller,
      payload: d.data,
      target: widget.target,
      zone: geometry.zone,
      nearestSide: geometry.nearestSide,
      policy: widget.dropPolicy,
    );
  }
}

class _ZoneHint extends StatelessWidget {
  final DropZone zone;
  final _AncestorClip? clip;

  const _ZoneHint({super.key, required this.zone, required this.clip});

  @override
  Widget build(BuildContext context) {
    final theme = PlatTheme.of(context);
    final cs = Theme.of(context).colorScheme;
    final fill = theme.dropHint.fill ?? cs.primary.withValues(alpha: 0.18);
    final border =
        theme.dropHint.border ?? BorderSide(color: cs.primary, width: 2);
    final hint = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        border: Border.fromBorderSide(border),
        borderRadius: _radiusForZone(zone, clip),
      ),
      child: const SizedBox.expand(),
    );

    if (zone == .center) return hint;

    return Align(
      alignment: switch (zone) {
        .center => .center,
        .left => .centerLeft,
        .right => .centerRight,
        .top => .topCenter,
        .bottom => .bottomCenter,
      },
      child: FractionallySizedBox(
        widthFactor: zone == .left || zone == .right ? .5 : null,
        heightFactor: zone == .top || zone == .bottom ? .5 : null,
        child: hint,
      ),
    );
  }

  /// Picks corner radii to match the destination on the edges shared
  /// with it; interior edges stay square.
  static BorderRadius _radiusForZone(DropZone zone, _AncestorClip? clip) {
    if (clip == null) return BorderRadius.zero;
    final r = clip.radius;
    Radius tl() => clip.touchesTop && clip.touchesLeft ? r.topLeft : .zero;
    Radius tr() => clip.touchesTop && clip.touchesRight ? r.topRight : .zero;
    Radius bl() =>
        clip.touchesBottom && clip.touchesLeft ? r.bottomLeft : .zero;
    Radius br() =>
        clip.touchesBottom && clip.touchesRight ? r.bottomRight : .zero;
    return switch (zone) {
      .center => BorderRadius.only(
        topLeft: tl(),
        topRight: tr(),
        bottomLeft: bl(),
        bottomRight: br(),
      ),
      .left => BorderRadius.only(topLeft: tl(), bottomLeft: bl()),
      .right => BorderRadius.only(topRight: tr(), bottomRight: br()),
      .top => BorderRadius.only(topLeft: tl(), topRight: tr()),
      .bottom => BorderRadius.only(bottomLeft: bl(), bottomRight: br()),
    };
  }
}
