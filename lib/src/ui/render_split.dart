import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart' show internal;

import '../core/foundation/foundation.dart';

const _zeroSlop = DeviceGestureSettings(touchSlop: 0);
const _leafDragHandleSize = Size(22, 4);

/// Pixel allocation for [platSizes] within [available] main-axis pixels.
/// Concrete sizes (`FixedSize`, or `FlexibleSize` with a non-auto
/// `initial`) claim pixels up front; the leftover splits equally among
/// auto-initial `FlexibleSize` siblings.
///
/// When no auto siblings exist, `FlexibleSize` claims are scaled to
/// fill the leftover after fixed claims. This keeps the layout intact
/// after a structural mutation that leaves sibling fractions out of
/// balance (closing a sibling so the rest sum below 1, or over-claimed
/// pixel siblings totalling more than `available`).
List<double> _computeSizes(List<PlatSize> platSizes, double available) {
  final claimed = List<double>.filled(platSizes.length, 0);
  final shareIndices = <int>[];
  final flexibleIndices = <int>[];
  var flexibleConsumed = 0.0;
  var fixedConsumed = 0.0;
  for (var i = 0; i < platSizes.length; i++) {
    final size = platSizes[i];
    final pixels = size.claim(available);
    if (pixels == null) {
      shareIndices.add(i);
    } else {
      claimed[i] = pixels;
      if (size is FlexibleSize) {
        flexibleIndices.add(i);
        flexibleConsumed += pixels;
      } else {
        fixedConsumed += pixels;
      }
    }
  }
  if (shareIndices.isNotEmpty) {
    final per =
        (available - fixedConsumed - flexibleConsumed).clamp(0.0, available) /
        shareIndices.length;
    for (final i in shareIndices) {
      claimed[i] = per;
    }
    return claimed;
  }
  if (flexibleIndices.isNotEmpty && flexibleConsumed > 0) {
    final availableForFlexible = (available - fixedConsumed).clamp(
      0.0,
      available,
    );
    if ((flexibleConsumed - availableForFlexible).abs() > 0.5) {
      final scale = availableForFlexible / flexibleConsumed;
      for (final i in flexibleIndices) {
        claimed[i] *= scale;
      }
    }
  }
  return claimed;
}

typedef _Drag = ({
  Offset startGlobal,
  _Slot left,
  _Slot right,
  double available,
});

typedef _PairUpdate = ({PlatSize leftSize, PlatSize rightSize});

typedef _Slot = ({String id, PlatSize size, double pixels});

class _SplitParentData extends ContainerBoxParentData<RenderBox> {
  // `contentId == null` discriminates a divider from a content child.
  String? contentId;
  PlatSize? platSize;
}

/// Tags a child of [PlatSplit] as a content pane or a divider. Content
/// children carry the [String] and [PlatSize] used by the render
/// object's sizing pass; dividers carry no extra data.
@internal
class PlatSlotData extends ParentDataWidget<_SplitParentData> {
  final String? contentId;
  final PlatSize? platSize;

  const PlatSlotData.content({
    super.key,
    required String this.contentId,
    required PlatSize this.platSize,
    required super.child,
  });

  const PlatSlotData.divider({super.key, required super.child})
    : contentId = null,
      platSize = null;

  @override
  void applyParentData(RenderObject renderObject) {
    final data = renderObject.parentData! as _SplitParentData;
    if (data.contentId == contentId && data.platSize == platSize) return;
    data.contentId = contentId;
    data.platSize = platSize;
    renderObject.parent?.markNeedsLayout();
  }

  @override
  Type get debugTypicalAncestorWidgetClass => PlatSplit;
}

/// Hover/drag indices published by [RenderPlatSplit] and read by the
/// divider widgets. Leaves never subscribe.
@internal
class DividerInteraction extends ChangeNotifier {
  int? _hovered;
  int? _dragging;

  int? get hoveredIndex => _hovered;

  int? get draggingIndex => _dragging;

  void setHovered(int? value) {
    if (_hovered == value) return;
    _hovered = value;
    notifyListeners();
  }

  void setDragging(int? value) {
    if (_dragging == value) return;
    _dragging = value;
    notifyListeners();
  }
}

/// Render-object widget for a [PlatSplit] node. Children alternate content
/// and divider via [PlatSlotData].
@internal
class PlatSplit extends MultiChildRenderObjectWidget {
  final Axis axis;
  final double spacing;
  final double hitSlop;
  final bool resizable;
  final DividerInteraction interaction;
  final ValueChanged<List<PlatSize>> onCommit;
  final MouseCursor? cursor;

  const PlatSplit({
    super.key,
    required this.axis,
    required this.spacing,
    required this.hitSlop,
    required this.resizable,
    required this.interaction,
    required this.onCommit,
    required super.children,
    this.cursor,
  });

  @override
  RenderPlatSplit createRenderObject(BuildContext context) => RenderPlatSplit(
    axis: axis,
    spacing: spacing,
    hitSlop: hitSlop,
    resizable: resizable,
    interaction: interaction,
    onCommit: onCommit,
    cursor: cursor,
  );

  @override
  void updateRenderObject(BuildContext context, RenderPlatSplit renderObject) {
    renderObject
      ..axis = axis
      ..spacing = spacing
      ..hitSlop = hitSlop
      ..resizable = resizable
      ..interaction = interaction
      ..onCommit = onCommit
      ..cursor = cursor;
  }
}

/// Owns layout, hit-testing, mouse cursor, and drag gestures for a
/// [PlatSplit]. A single drag recognizer per split owns every divider;
/// live drag updates reflow this render object alone — leaves and
/// divider widgets do not rebuild.
@internal
class RenderPlatSplit extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _SplitParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _SplitParentData>
    implements MouseTrackerAnnotation {
  RenderPlatSplit({
    required this._axis,
    required this._spacing,
    required this.hitSlop,
    required this.resizable,
    required this.interaction,
    required this.onCommit,
    this._cursor,
  });

  Axis _axis;
  double _spacing;
  double hitSlop;
  bool resizable;
  DividerInteraction interaction;
  ValueChanged<List<PlatSize>> onCommit;
  MouseCursor? _cursor;

  set cursor(MouseCursor? value) {
    if (_cursor == value) return;
    _cursor = value;
    if (!attached) return;
    markNeedsPaint();

    // TODO(elias8): Need to rework on this.
    // The annotation is reported by this render object directly, not
    // through a paint layer, so the per-frame mouse-tracker sweep does
    // not pick up the new cursor on its own. Force a device update.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) RendererBinding.instance.mouseTracker.updateAllDevices();
    });
  }

  // Plat snapshot, refilled every performLayout.
  final _slots = <_Slot>[];
  final _gutterCenters = <double>[];
  double _availableMain = 0;

  // Drag-only override. Setting triggers markNeedsLayout, no rebuild.
  Map<String, PlatSize>? _liveSizes;

  // `_pending` is set on PointerDown; the recognizer consumes it in
  // onDragStart. `_drag` is non-null while a drag is live.
  int? _pending;
  _Drag? _drag;

  DragGestureRecognizer? _recognizer;

  Axis get axis => _axis;

  set axis(Axis value) {
    if (_axis == value) return;
    _axis = value;
    if (attached) _resetRecognizer();
    markNeedsLayout();
  }

  double get spacing => _spacing;

  set spacing(double value) {
    if (_spacing == value) return;
    _spacing = value;
    markNeedsLayout();
  }

  bool get _isHorizontal => _axis == Axis.horizontal;

  double _mainOf(Offset point) => _isHorizontal ? point.dx : point.dy;

  Offset _mainOffset(double main) =>
      _isHorizontal ? Offset(main, 0) : Offset(0, main);

  BoxConstraints _tightAxis(double main, double cross) =>
      BoxConstraints.tightFor(
        width: _isHorizontal ? main : cross,
        height: _isHorizontal ? cross : main,
      );

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _SplitParentData) {
      child.parentData = _SplitParentData();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _resetRecognizer();
  }

  @override
  void detach() {
    _recognizer?.dispose();
    _recognizer = null;
    super.detach();
  }

  void _resetRecognizer() {
    _recognizer?.dispose();
    _recognizer =
        (_isHorizontal
              ? HorizontalDragGestureRecognizer(debugOwner: this)
              : VerticalDragGestureRecognizer(debugOwner: this))
          ..gestureSettings = _zeroSlop
          ..onStart = _onDragStart
          ..onUpdate = _onDragUpdate
          ..onEnd = (_) {
            _finishDrag();
          }
          ..onCancel = _finishDrag;
  }

  @override
  void performLayout() {
    _slots.clear();
    _gutterCenters.clear();

    final (mainExtent, crossExtent) = _isHorizontal
        ? (constraints.maxWidth, constraints.maxHeight)
        : (constraints.maxHeight, constraints.maxWidth);

    final platSizes = _readContentSizes(overrides: _liveSizes);
    if (platSizes.isEmpty || !mainExtent.isFinite || mainExtent <= 0) {
      size = constraints.smallest;
      return;
    }

    final dividerCount = childCount - platSizes.length;
    _availableMain = (mainExtent - dividerCount * _spacing).clamp(
      0.0,
      mainExtent,
    );
    final pixels = _computeSizes(platSizes, _availableMain);

    var offset = 0.0;
    var contentIndex = 0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final data = child.parentData! as _SplitParentData;
      final isContent = data.contentId != null;
      final mainSize = isContent ? pixels[contentIndex] : _spacing;
      child.layout(_tightAxis(mainSize, crossExtent));
      data.offset = _mainOffset(offset);
      if (isContent) {
        _slots.add((
          id: data.contentId!,
          size: data.platSize!,
          pixels: mainSize,
        ));
        contentIndex++;
      } else {
        _gutterCenters.add(offset + _spacing / 2);
      }
      offset += mainSize;
    }

    size = constraints.biggest;
  }

  /// Walk content children and return their [PlatSize]s, with any
  /// [overrides] applied. Used by the layout pass and the drag-end
  /// commit path.
  List<PlatSize> _readContentSizes({Map<String, PlatSize>? overrides}) {
    final result = <PlatSize>[];
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final data = child.parentData! as _SplitParentData;
      final id = data.contentId;
      if (id != null) result.add(overrides?[id] ?? data.platSize!);
    }
    return result;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    if (_drag != null) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    final gutter = _gutterAt(position);
    final liveGutter = (gutter != null && !_isLockedAt(gutter)) ? gutter : null;
    if (liveGutter != null && _isLeafDragHandleHit(position)) {
      interaction.setHovered(null);
      return hitTestChildren(result, position: position);
    }
    interaction.setHovered(liveGutter);
    if (liveGutter != null) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return hitTestChildren(result, position: position);
  }

  bool _isLeafDragHandleHit(Offset position) {
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final data = child.parentData! as _SplitParentData;
      if (data.contentId == null) continue;
      final rect =
          Offset(
            data.offset.dx + (child.size.width - _leafDragHandleSize.width) / 2,
            data.offset.dy,
          ) &
          _leafDragHandleSize;
      if (rect.contains(position)) return true;
    }
    return false;
  }

  int? _gutterAt(Offset position) {
    final main = _mainOf(position);
    final halfHit = _spacing / 2 + hitSlop;
    for (var i = 0; i < _gutterCenters.length; i++) {
      if ((main - _gutterCenters[i]).abs() <= halfHit) return i;
    }
    return null;
  }

  bool _isLockedAt(int dividerIndex) =>
      !resizable ||
      _slots[dividerIndex].size is FixedSize ||
      _slots[dividerIndex + 1].size is FixedSize;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is! PointerDownEvent) return;
    final gutter = _gutterAt(event.localPosition);
    if (gutter == null || _isLockedAt(gutter)) return;
    _pending = gutter;
    _recognizer?.addPointer(event);
  }

  @override
  MouseCursor get cursor {
    return _cursor ??
        (_isHorizontal
            ? SystemMouseCursors.resizeColumn
            : SystemMouseCursors.resizeRow);
  }

  @override
  PointerEnterEventListener? get onEnter => null;

  @override
  PointerExitEventListener? get onExit {
    return (_) => interaction.setHovered(null);
  }

  @override
  bool get validForMouseTracker => attached;

  void _onDragStart(DragStartDetails details) {
    final pending = _pending;
    if (pending == null || pending >= _gutterCenters.length) return;
    final left = _slots[pending];
    final right = _slots[pending + 1];
    if (left.size is! FlexibleSize || right.size is! FlexibleSize) return;
    _drag = (
      startGlobal: details.globalPosition,
      left: left,
      right: right,
      available: _availableMain,
    );
    interaction.setDragging(pending);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final drag = _drag;
    if (drag == null) return;
    final delta = _mainOf(details.globalPosition) - _mainOf(drag.startGlobal);
    final updated = _resizePair(drag, delta);
    if (updated == null) return;
    _liveSizes = {
      drag.left.id: updated.leftSize,
      drag.right.id: updated.rightSize,
    };
    markNeedsLayout();
  }

  void _finishDrag() {
    final overrides = _liveSizes;
    _drag = null;
    _pending = null;
    _liveSizes = null;
    interaction.setDragging(null);
    if (overrides == null) return;
    markNeedsLayout();
    onCommit(_readContentSizes(overrides: overrides));
  }

  _PairUpdate? _resizePair(_Drag drag, double delta) {
    final left = drag.left.size as FlexibleSize;
    final right = drag.right.size as FlexibleSize;
    final leftBounds = left.bounds(drag.available);
    final rightBounds = right.bounds(drag.available);

    final wantLeft = (drag.left.pixels + delta).clamp(
      leftBounds.min,
      leftBounds.max,
    );
    final wantRight = (drag.right.pixels - (wantLeft - drag.left.pixels)).clamp(
      rightBounds.min,
      rightBounds.max,
    );
    final shift = drag.right.pixels - wantRight;
    if (shift == 0) return null;

    return (
      leftSize: left.withPixels(drag.left.pixels + shift, drag.available),
      rightSize: right.withPixels(drag.right.pixels - shift, drag.available),
    );
  }
}

extension on PlatExtent {
  double maxBound(double available) =>
      this is AutoExtent ? available : pixels(available);

  double minBound(double available) =>
      this is AutoExtent ? 0 : pixels(available);

  /// Resolve to pixels. [AutoExtent] resolves to 0 — call [minBound] or
  /// [maxBound] when you want auto to mean "no bound".
  double pixels(double available) => switch (this) {
    Pixels(:final value) => value,
    Fraction(:final value) => value * available,
    AutoExtent() => 0,
  };
}

extension on PlatSize {
  /// Pixels claimed up front; `null` when this size shares the leftover
  /// (an auto-initial `FlexibleSize`).
  double? claim(double available) => switch (this) {
    FixedSize(:final extent) => extent.pixels(available),
    FlexibleSize(:final initial, :final min, :final max) =>
      initial is AutoExtent
          ? null
          : initial
                .pixels(available)
                .clamp(min.minBound(available), max.maxBound(available)),
  };
}

extension on FlexibleSize {
  ({double min, double max}) bounds(double available) =>
      (min: min.minBound(available), max: max.maxBound(available));

  /// Rewrite [initial] to reflect [newPixels], preserving the original
  /// unit (`Fraction` stays fractional, anything else becomes `Pixels`).
  FlexibleSize withPixels(double newPixels, double available) {
    final PlatExtent next = switch (initial) {
      Fraction() when available > 0 => .fraction(
        (newPixels / available).clamp(0.0, 1.0),
      ),
      _ => .pixel(newPixels),
    };
    return copyWith(initial: next);
  }
}
