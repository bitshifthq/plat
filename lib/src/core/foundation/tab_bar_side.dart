part of 'foundation.dart';

/// Which edge of a body the tab bar sits on.
enum TabBarSide {
  /// Top edge. The conventional browser and IDE editor-tab placement.
  top,

  /// Bottom edge, mirroring [top].
  bottom,

  /// Left edge, with chips stacked vertically.
  left,

  /// Right edge, with chips stacked vertically.
  right;

  /// True for [top] and [bottom], where chips stack left-to-right.
  bool get isHorizontal => !isVertical;

  /// True for [left] and [right], where chips stack top-to-bottom.
  bool get isVertical => this == left || this == right;
}
