import 'dart:math' as math;

import 'package:flutter/material.dart' show Theme;
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart' show internal;

import '../controller/controller.dart';
import '../model/plat_snapshot.dart';
import 'drop/drag_payload.dart';
import 'theme.dart';

const _handleSize = Size(22, 4);
const _handleHoverRadius = 6.0;
const _revealFraction = 0.18;
const _minRevealExtent = 24.0;
const _maxRevealFraction = 0.5;

@internal
final class PlatLeafDragHandleHost extends StatefulWidget {
  final LeafSnapshot leaf;
  final PlatController controller;
  final Widget child;

  const PlatLeafDragHandleHost({
    super.key,
    required this.leaf,
    required this.controller,
    required this.child,
  });

  @override
  State<PlatLeafDragHandleHost> createState() => _PlatLeafDragHandleHostState();
}

final class _PlatLeafDragHandleHostState extends State<PlatLeafDragHandleHost> {
  var _visible = false;
  var _handleHovered = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.leaf.draggable || widget.leaf.locked) return widget.child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final background = PlatTheme.of(context).leafDragHandleBackgroundColor;
        return MouseRegion(
          onExit: (_) => _setVisible(false),
          onHover: (event) => _setHover(event.localPosition, size),
          child: Column(
            children: [
              ColoredBox(
                color: background ?? const Color(0x00000000),
                child: SizedBox(
                  height: _handleSize.height,
                  child: Center(child: _animatedHandle(context)),
                ),
              ),
              Expanded(child: widget.child),
            ],
          ),
        );
      },
    );
  }

  bool _isInRevealRegion(Offset local, Size size) {
    if (size.width <= 0 || size.height <= 0) return false;
    final maxReveal = size.height * _maxRevealFraction;
    final reveal = math
        .max(size.height * _revealFraction, _minRevealExtent)
        .clamp(0.0, math.min(size.height, maxReveal));
    final triggerWidth = math.min(
      size.width,
      math.max(_handleSize.width * 2, size.width * 0.25),
    );
    final dx = (local.dx - size.width / 2).abs();
    return local.dy >= 0 && local.dy <= reveal && dx <= triggerWidth / 2;
  }

  bool _isDirectHandleHover(Offset local, Size size) {
    final center = Offset(size.width / 2, _handleSize.height / 2);
    return (local - center).distance <= _handleHoverRadius;
  }

  void _setHover(Offset local, Size size) {
    final visible = _isInRevealRegion(local, size);
    final handleHovered = visible && _isDirectHandleHover(local, size);
    if (_visible == visible && _handleHovered == handleHovered) return;
    _visible = visible;
    _handleHovered = handleHovered;
    setState(() {});
  }

  void _setVisible(bool value) {
    if (_visible == value && !_handleHovered) return;
    _visible = value;
    if (!value) _handleHovered = false;
    setState(() {});
  }

  Widget _animatedHandle(BuildContext context) {
    final opacity = !_visible ? 0.0 : (_handleHovered ? 1.0 : 0.62);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 120),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      child: opacity == 0
          ? SizedBox.fromSize(key: const ValueKey('hidden'), size: _handleSize)
          : Draggable<LeafDragPayload>(
              key: ValueKey(opacity),
              data: LeafDragPayload(
                leaf: widget.leaf,
                source: widget.controller,
              ),
              feedback: Opacity(opacity: 0.9, child: _dots(context, 1)),
              childWhenDragging: Opacity(
                opacity: 0.4,
                child: _dots(context, opacity),
              ),
              rootOverlay: true,
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: _dots(context, opacity),
              ),
            ),
    );
  }

  Widget _dots(BuildContext context, double opacity) {
    return CustomPaint(
      painter: _LeafDragHandleDotsPainter(
        Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: opacity),
      ),
      child: SizedBox.fromSize(size: _handleSize),
    );
  }
}

final class _LeafDragHandleDotsPainter extends CustomPainter {
  final Color color;

  const _LeafDragHandleDotsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final radius = math.min(size.width, size.height) / 2.35;
    final gap = math.min(size.width * 0.28, 6.0);
    final center = Offset(size.width / 2, size.height / 2);

    for (final dx in [-gap, 0.0, gap]) {
      canvas.drawCircle(center + Offset(dx, 0), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LeafDragHandleDotsPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
