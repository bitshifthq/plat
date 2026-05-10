part of 'foundation.dart';

/// A length: absolute logical pixels, a fraction of the parent's
/// available extent, or [PlatExtent.auto] to defer to a default.
///
/// Constructed via [PlatExtent.pixel], [PlatExtent.fraction], or
/// [PlatExtent.auto]. The concrete subclasses are an implementation
/// detail; treat values as opaque and pattern-match only when you need
/// to inspect the variant.
///
/// ```dart
/// const PlatExtent sidebarWidth = .pixel(240);
/// const PlatExtent half = .fraction(0.5);
/// const PlatExtent unspecified = .auto();
/// ```
sealed class PlatExtent {
  const PlatExtent._();

  /// Absolute logical-pixel extent. [value] must be non-negative.
  const factory PlatExtent.pixel(double value) = Pixels._;

  /// Fraction of the parent's available extent. [value] is in `0..1`.
  const factory PlatExtent.fraction(double value) = Fraction._;

  /// Sentinel meaning "no concrete value": defer to the default at
  /// this position. As a size's initial value, the node shares leftover
  /// space with sibling flexible panes; as a min or max bound, it imposes
  /// no bound.
  const factory PlatExtent.auto() = AutoExtent._;
}

/// Absolute logical-pixel extent.
@internal
@immutable
final class Pixels extends PlatExtent {
  /// Pixel count. Non-negative.
  final double value;

  const Pixels._(this.value)
    : assert(value >= 0, 'pixels must be non-negative'),
      super._();

  @override
  int get hashCode => Object.hash('px', value);

  @override
  bool operator ==(Object other) => other is Pixels && other.value == value;

  @override
  String toString() => '${value}px';
}

/// Fraction of the parent's available extent.
@internal
@immutable
final class Fraction extends PlatExtent {
  /// Fraction in `0..1`.
  final double value;

  const Fraction._(this.value)
    : assert(value >= 0 && value <= 1, 'fraction must be in 0..1'),
      super._();

  @override
  int get hashCode => Object.hash('fr', value);

  @override
  bool operator ==(Object other) => other is Fraction && other.value == value;

  @override
  String toString() => '${(value * 100).toStringAsFixed(1)}%';
}

/// The "use the default" extent. See [PlatExtent.auto].
@internal
@immutable
final class AutoExtent extends PlatExtent {
  const AutoExtent._() : super._();

  @override
  int get hashCode => Object.hash('extent', 'auto');

  @override
  bool operator ==(Object other) => other is AutoExtent;

  @override
  String toString() => 'auto';
}

/// How much space a node occupies inside its parent split.
///
/// Constructed via [PlatSize.fixed], [PlatSize.resizable], or
/// [PlatSize.auto]. The concrete subclasses are an implementation
/// detail; treat values as opaque and pattern-match only when you need
/// to inspect the variant.
///
/// - `fixed`: locked extent. The neighbouring divider does not drag.
/// - `resizable`: variable extent, optionally clamped. `initial` is the
///   starting (and current) value; drags rewrite it. `min` and `max`
///   clamp it. Each may be a pixel, a fraction, or `auto`
///   independently.
/// - `auto`: variable extent that shares leftover space with sibling
///   resizables, with no bound.
///
/// ```dart
/// const PlatSize sidebar = .fixed(.pixel(240));
/// const PlatSize body = .auto();
/// const PlatSize panel = .resizable(
///   initial: .fraction(0.3),
///   min: .pixel(200),
/// );
/// ```
sealed class PlatSize {
  const PlatSize._();

  /// Locked extent. The neighbouring divider does not drag.
  /// [extent] must be a concrete value, not [PlatExtent.auto].
  const factory PlatSize.fixed(PlatExtent extent) = FixedSize._;

  /// Variable extent. [initial] is the starting value; drags rewrite
  /// it. [min] and [max] clamp it. Each defaults to [PlatExtent.auto].
  const factory PlatSize.resizable({
    PlatExtent initial,
    PlatExtent min,
    PlatExtent max,
  }) = FlexibleSize._;

  /// Variable extent with no bounds, sharing leftover space with
  /// sibling resizables.
  const factory PlatSize.auto() = FlexibleSize._auto;
}

/// Locked extent. See [PlatSize.fixed].
@internal
@immutable
final class FixedSize extends PlatSize {
  /// The locked length. Never [AutoExtent].
  final PlatExtent extent;

  const FixedSize._(this.extent)
    : assert(
        extent is! AutoExtent,
        'PlatSize.fixed requires a concrete extent (pixel or fraction)',
      ),
      super._();

  @override
  int get hashCode => Object.hash('fixed', extent);

  @override
  bool operator ==(Object other) =>
      other is FixedSize && other.extent == extent;

  @override
  String toString() => 'FixedSize($extent)';
}

/// Variable extent, optionally clamped. See [PlatSize.resizable].
@internal
@immutable
final class FlexibleSize extends PlatSize {
  /// Starting (and current) length. Drags rewrite this in place.
  final PlatExtent initial;

  /// Lower bound, or [PlatExtent.auto] for no bound.
  final PlatExtent min;

  /// Upper bound, or [PlatExtent.auto] for no bound.
  final PlatExtent max;

  const FlexibleSize._({
    this.initial = const AutoExtent._(),
    this.min = const AutoExtent._(),
    this.max = const AutoExtent._(),
  }) : super._();

  const FlexibleSize._auto()
    : initial = const AutoExtent._(),
      min = const AutoExtent._(),
      max = const AutoExtent._(),
      super._();

  /// Returns a copy with the named fields replaced.
  FlexibleSize copyWith({
    PlatExtent? initial,
    PlatExtent? min,
    PlatExtent? max,
  }) => FlexibleSize._(
    initial: initial ?? this.initial,
    min: min ?? this.min,
    max: max ?? this.max,
  );

  @override
  int get hashCode => Object.hash('flexible', initial, min, max);

  @override
  bool operator ==(Object other) =>
      other is FlexibleSize &&
      other.initial == initial &&
      other.min == min &&
      other.max == max;

  @override
  String toString() => 'FlexibleSize(initial: $initial, min: $min, max: $max)';
}
