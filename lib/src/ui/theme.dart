// ignore_for_file: prefer_constructors_over_static_methods
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart'
    show TabBarThemeData, Theme, ThemeData, ThemeExtension;
import 'package:flutter/widgets.dart';

/// Default tab chip cursor resolver. Resolves to
/// [SystemMouseCursors.click] for normal/hovered/selected/focused,
/// [SystemMouseCursors.grabbing] while a chip is being dragged, and
/// [SystemMouseCursors.forbidden] when the chip is disabled.
///
/// Locked tabs are still activatable, so Plat does not add
/// [WidgetState.disabled] for locked tabs. Hosts override via
/// [PlatTabBarTheme.mouseCursor].
final defaultPlatTabCursor = WidgetStateProperty.resolveWith<MouseCursor>((
  states,
) {
  if (states.contains(WidgetState.disabled)) {
    return SystemMouseCursors.forbidden;
  }
  if (states.contains(WidgetState.dragged)) {
    return SystemMouseCursors.grabbing;
  }
  return SystemMouseCursors.click;
});

WidgetStateProperty<Color?>? _lerpColorStateProperty(
  WidgetStateProperty<Color?>? a,
  WidgetStateProperty<Color?>? b,
  double t,
) {
  if (a == null && b == null) return null;

  return WidgetStateProperty.resolveWith(
    (states) => Color.lerp(a?.resolve(states), b?.resolve(states), t),
  );
}

WidgetStateProperty<Decoration?>? _lerpDecorationStateProperty(
  WidgetStateProperty<Decoration?>? a,
  WidgetStateProperty<Decoration?>? b,
  double t,
) {
  if (a == null && b == null) return null;

  return WidgetStateProperty.resolveWith(
    (states) => Decoration.lerp(a?.resolve(states), b?.resolve(states), t),
  );
}

/// Split divider visuals and hit area.
@immutable
final class PlatDividerTheme {
  /// Logical pixel thickness of the drawable divider line.
  final double thickness;

  /// Hit-test slop around the divider line (extends each side).
  final double hitSlop;

  /// State-driven decoration, resolved per [WidgetState] set. Takes
  /// precedence over [color]. `null` (or a resolver returning `null`)
  /// falls through to [color].
  final WidgetStateProperty<Decoration?>? decoration;

  /// State-driven color, resolved per [WidgetState] set. `null` (or a
  /// resolver returning `null`) falls back to `colorScheme.primary`
  /// when hovered or dragged, and `colorScheme.outlineVariant`
  /// otherwise, at render time.
  final WidgetStateProperty<Color?>? color;

  /// Mouse cursor over the divider's hit area. `null` falls back to
  /// `SystemMouseCursors.resizeColumn` for horizontal splits and
  /// `SystemMouseCursors.resizeRow` for vertical splits at render time.
  final MouseCursor? cursor;

  const PlatDividerTheme({
    this.thickness = 1,
    this.hitSlop = 4,
    this.decoration,
    this.color,
    this.cursor,
  });

  @override
  int get hashCode =>
      Object.hash(thickness, hitSlop, decoration, color, cursor);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlatDividerTheme &&
          other.thickness == thickness &&
          other.hitSlop == hitSlop &&
          other.decoration == decoration &&
          other.color == color &&
          other.cursor == cursor;

  PlatDividerTheme copyWith({
    double? thickness,
    double? hitSlop,
    WidgetStateProperty<Decoration?>? decoration,
    WidgetStateProperty<Color?>? color,
    MouseCursor? cursor,
  }) => PlatDividerTheme(
    thickness: thickness ?? this.thickness,
    hitSlop: hitSlop ?? this.hitSlop,
    decoration: decoration ?? this.decoration,
    color: color ?? this.color,
    cursor: cursor ?? this.cursor,
  );

  static PlatDividerTheme lerp(
    PlatDividerTheme a,
    PlatDividerTheme b,
    double t,
  ) {
    if (identical(a, b)) return a;
    final pickB = t >= 0.5;
    return PlatDividerTheme(
      thickness: lerpDouble(a.thickness, b.thickness, t)!,
      hitSlop: lerpDouble(a.hitSlop, b.hitSlop, t)!,
      decoration: _lerpDecorationStateProperty(a.decoration, b.decoration, t),
      color: _lerpColorStateProperty(a.color, b.color, t),
      cursor: pickB ? b.cursor : a.cursor,
    );
  }
}

/// Drop hint overlay visuals and timing.
///
/// The overlay paints fill and border at the drop-zone bounds. Corner radius is
/// derived from the destination's enclosing `ClipRRect`, so rounded edges stay
/// aligned without another public styling field.
@immutable
final class PlatDropHintTheme {
  /// Fill color for the drop hint overlay. `null` resolves to
  /// `colorScheme.primary` at 18 % opacity at render time.
  final Color? fill;

  /// Border for the drop hint overlay. `null` resolves to a 2 px stroke
  /// of `colorScheme.primary` at render time.
  final BorderSide? border;

  /// Duration of the hint appear/disappear transition.
  final Duration duration;

  /// How the hint enters and exits. Defaults to
  /// `AnimatedSwitcher.defaultTransitionBuilder`.
  final AnimatedSwitcherTransitionBuilder transitionBuilder;

  /// Fraction of each edge that counts as an edge drop zone.
  /// `0.25` means the outer 25% on each side splits, while the center accepts
  /// a tab-group drop.
  final double edgeFraction;

  const PlatDropHintTheme({
    this.fill,
    this.border,
    this.duration = const Duration(milliseconds: 120),
    this.transitionBuilder = AnimatedSwitcher.defaultTransitionBuilder,
    this.edgeFraction = 0.25,
  });

  @override
  int get hashCode =>
      Object.hash(fill, border, duration, transitionBuilder, edgeFraction);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlatDropHintTheme &&
          other.fill == fill &&
          other.border == border &&
          other.duration == duration &&
          other.transitionBuilder == transitionBuilder &&
          other.edgeFraction == edgeFraction;

  PlatDropHintTheme copyWith({
    Color? fill,
    BorderSide? border,
    Duration? duration,
    AnimatedSwitcherTransitionBuilder? transitionBuilder,
    double? edgeFraction,
  }) => PlatDropHintTheme(
    fill: fill ?? this.fill,
    border: border ?? this.border,
    duration: duration ?? this.duration,
    transitionBuilder: transitionBuilder ?? this.transitionBuilder,
    edgeFraction: edgeFraction ?? this.edgeFraction,
  );

  static PlatDropHintTheme lerp(
    PlatDropHintTheme a,
    PlatDropHintTheme b,
    double t,
  ) {
    if (identical(a, b)) return a;
    final pickB = t >= 0.5;
    return PlatDropHintTheme(
      fill: Color.lerp(a.fill, b.fill, t),
      border: a.border == null && b.border == null
          ? null
          : BorderSide.lerp(a.border ?? .none, b.border ?? .none, t),
      duration: pickB ? b.duration : a.duration,
      transitionBuilder: pickB ? b.transitionBuilder : a.transitionBuilder,
      edgeFraction: lerpDouble(a.edgeFraction, b.edgeFraction, t)!,
    );
  }
}

/// Tab bar layout, decoration, and tab-flow knobs.
@immutable
final class PlatTabBarTheme {
  /// Thickness of the tab bar — perpendicular to chip flow. For top /
  /// bottom bars this is height; for left / right bars this is width.
  final double size;

  /// Padding inside the tab bar around its content.
  final EdgeInsetsGeometry padding;

  /// Decoration (background color, border, shadow). Applied behind the
  /// padded content so it covers the bar edge to edge. Takes precedence
  /// over [backgroundColor].
  final Decoration? decoration;

  /// Solid background fill for the bar. Used only when [decoration] is
  /// `null`. `null` resolves to `colorScheme.surface` at render time.
  final Color? backgroundColor;

  /// How tabs are laid out along the bar.
  final TabStripFit fit;

  /// Maximum tab width when [fit] is [TabStripFit.expand].
  final double? chipMaxWidth;

  /// Minimum tab width when [fit] is [TabStripFit.expand].
  final double? chipMinWidth;

  /// Width assigned to pinned tabs when [fit] is [TabStripFit.expand]. `null`
  /// means pinned tabs share the available width like every other tab.
  final double? pinnedChipWidth;

  /// Gap between adjacent tabs.
  final double spacing;

  /// Scroll physics for the tab strip. `null` defers to the platform
  /// default (bouncy on iOS / macOS, clamping elsewhere).
  final ScrollPhysics? physics;

  /// Where tabs anchor inside the strip when their total extent is smaller
  /// than the bar. Only meaningful under [TabStripFit.scrollable].
  final TabStripAlignment alignment;

  /// Continuous baseline on the body-facing edge of the bar. When null,
  /// [PlatTabBar] uses an explicitly configured Material tab divider if
  /// present.
  final BorderSide? divider;

  /// Mouse cursor over tabs. `null` resolves to [defaultPlatTabCursor].
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// Corner shape of each default chip.
  final BorderRadiusGeometry? chipBorderRadius;

  /// Padding inside each default tab chip around its content. Mirrors
  /// Material `TabBar.labelPadding`.
  final EdgeInsetsGeometry labelPadding;

  /// Text color for selected tabs. May be a [WidgetStateColor]. When null,
  /// falls back to [TabBarThemeData.labelColor], then `colorScheme.onSurface`.
  final Color? labelColor;

  /// Text style for selected tabs. Merged on top of
  /// [TabBarThemeData.labelStyle] when present, otherwise
  /// `textTheme.labelMedium`.
  final TextStyle? labelStyle;

  /// Text color for unselected tabs. May be a [WidgetStateColor]. When null,
  /// falls back to [TabBarThemeData.unselectedLabelColor], then
  /// `colorScheme.onSurfaceVariant`.
  final Color? unselectedLabelColor;

  /// Text style for unselected tabs. Merged on top of
  /// [TabBarThemeData.unselectedLabelStyle] when present, otherwise
  /// [TabBarThemeData.labelStyle] or `textTheme.labelMedium`.
  final TextStyle? unselectedLabelStyle;

  /// Overlay painted by the default tab chip for hovered / focused / pressed
  /// states. This is a non-Material overlay because plat's tab strip does not
  /// require a [Material] ancestor. When null, falls back to
  /// [TabBarThemeData.overlayColor], then a compact Material-like hover /
  /// press overlay.
  final WidgetStateProperty<Color?>? overlayColor;

  /// Decoration drawn as the selected-tab indicator strip on the body-facing
  /// edge of the selected chip. When non-null, [indicatorColor] is ignored.
  final Decoration? indicator;

  /// Color of the selected-tab indicator. When null, falls back to
  /// [TabBarThemeData.indicatorColor], then `colorScheme.primary`.
  final Color? indicatorColor;

  /// Thickness of the selected-tab indicator.
  final double indicatorWeight;

  /// Insets applied to the selected-tab indicator.
  final EdgeInsetsGeometry indicatorPadding;

  /// State-driven background color of each default chip. `null` (or a
  /// resolver returning `null`) falls back to an opaque accent-tinted
  /// surface while dragged, `colorScheme.surfaceContainerHigh` while selected,
  /// and `colorScheme.surface` otherwise.
  final WidgetStateProperty<Color?>? chipBackgroundColor;

  /// State-driven foreground color of each default chip's content, including
  /// text and icons. `null` (or a resolver returning `null`) falls back to
  /// [labelColor] / [unselectedLabelColor], matching
  /// [TabBarThemeData] label colors, then `colorScheme.onSurface` /
  /// `onSurfaceVariant` at render time.
  final WidgetStateProperty<Color?>? chipForegroundColor;

  const PlatTabBarTheme({
    this.size = 32,
    this.padding = const EdgeInsets.symmetric(horizontal: 4),
    this.decoration,
    this.backgroundColor,
    this.fit = .scrollable,
    this.chipMaxWidth,
    this.chipMinWidth,
    this.pinnedChipWidth,
    this.spacing = 0,
    this.physics,
    this.alignment = .start,
    this.divider,
    this.mouseCursor,
    this.chipBorderRadius,
    this.labelPadding = const .symmetric(horizontal: 12, vertical: 8),
    this.labelColor,
    this.labelStyle,
    this.unselectedLabelColor,
    this.unselectedLabelStyle,
    this.overlayColor,
    this.indicator,
    this.indicatorColor,
    this.indicatorWeight = 2,
    this.indicatorPadding = EdgeInsets.zero,
    this.chipBackgroundColor,
    this.chipForegroundColor,
  });

  @override
  int get hashCode => Object.hashAll([
    size,
    padding,
    decoration,
    backgroundColor,
    fit,
    chipMaxWidth,
    chipMinWidth,
    pinnedChipWidth,
    spacing,
    physics,
    alignment,
    divider,
    mouseCursor,
    chipBorderRadius,
    labelPadding,
    labelColor,
    labelStyle,
    unselectedLabelColor,
    unselectedLabelStyle,
    overlayColor,
    indicator,
    indicatorColor,
    indicatorWeight,
    indicatorPadding,
    chipBackgroundColor,
    chipForegroundColor,
  ]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlatTabBarTheme &&
          other.size == size &&
          other.padding == padding &&
          other.decoration == decoration &&
          other.backgroundColor == backgroundColor &&
          other.fit == fit &&
          other.chipMaxWidth == chipMaxWidth &&
          other.chipMinWidth == chipMinWidth &&
          other.pinnedChipWidth == pinnedChipWidth &&
          other.spacing == spacing &&
          other.physics == physics &&
          other.alignment == alignment &&
          other.divider == divider &&
          other.mouseCursor == mouseCursor &&
          other.chipBorderRadius == chipBorderRadius &&
          other.labelPadding == labelPadding &&
          other.labelColor == labelColor &&
          other.labelStyle == labelStyle &&
          other.unselectedLabelColor == unselectedLabelColor &&
          other.unselectedLabelStyle == unselectedLabelStyle &&
          other.overlayColor == overlayColor &&
          other.indicator == indicator &&
          other.indicatorColor == indicatorColor &&
          other.indicatorWeight == indicatorWeight &&
          other.indicatorPadding == indicatorPadding &&
          other.chipBackgroundColor == chipBackgroundColor &&
          other.chipForegroundColor == chipForegroundColor;

  PlatTabBarTheme copyWith({
    double? size,
    EdgeInsetsGeometry? padding,
    Decoration? decoration,
    Color? backgroundColor,
    TabStripFit? fit,
    double? chipMaxWidth,
    double? chipMinWidth,
    double? pinnedChipWidth,
    double? spacing,
    ScrollPhysics? physics,
    TabStripAlignment? alignment,
    BorderSide? divider,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
    BorderRadiusGeometry? chipBorderRadius,
    EdgeInsetsGeometry? labelPadding,
    Color? labelColor,
    TextStyle? labelStyle,
    Color? unselectedLabelColor,
    TextStyle? unselectedLabelStyle,
    WidgetStateProperty<Color?>? overlayColor,
    Decoration? indicator,
    Color? indicatorColor,
    double? indicatorWeight,
    EdgeInsetsGeometry? indicatorPadding,
    WidgetStateProperty<Color?>? chipBackgroundColor,
    WidgetStateProperty<Color?>? chipForegroundColor,
  }) => PlatTabBarTheme(
    size: size ?? this.size,
    padding: padding ?? this.padding,
    decoration: decoration ?? this.decoration,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    fit: fit ?? this.fit,
    chipMaxWidth: chipMaxWidth ?? this.chipMaxWidth,
    chipMinWidth: chipMinWidth ?? this.chipMinWidth,
    pinnedChipWidth: pinnedChipWidth ?? this.pinnedChipWidth,
    spacing: spacing ?? this.spacing,
    physics: physics ?? this.physics,
    alignment: alignment ?? this.alignment,
    divider: divider ?? this.divider,
    mouseCursor: mouseCursor ?? this.mouseCursor,
    chipBorderRadius: chipBorderRadius ?? this.chipBorderRadius,
    labelPadding: labelPadding ?? this.labelPadding,
    labelColor: labelColor ?? this.labelColor,
    labelStyle: labelStyle ?? this.labelStyle,
    unselectedLabelColor: unselectedLabelColor ?? this.unselectedLabelColor,
    unselectedLabelStyle: unselectedLabelStyle ?? this.unselectedLabelStyle,
    overlayColor: overlayColor ?? this.overlayColor,
    indicator: indicator ?? this.indicator,
    indicatorColor: indicatorColor ?? this.indicatorColor,
    indicatorWeight: indicatorWeight ?? this.indicatorWeight,
    indicatorPadding: indicatorPadding ?? this.indicatorPadding,
    chipBackgroundColor: chipBackgroundColor ?? this.chipBackgroundColor,
    chipForegroundColor: chipForegroundColor ?? this.chipForegroundColor,
  );

  static PlatTabBarTheme lerp(PlatTabBarTheme a, PlatTabBarTheme b, double t) {
    if (identical(a, b)) return a;
    final pickB = t >= 0.5;
    return PlatTabBarTheme(
      size: lerpDouble(a.size, b.size, t)!,
      padding: .lerp(a.padding, b.padding, t)!,
      decoration: Decoration.lerp(a.decoration, b.decoration, t),
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t),
      fit: pickB ? b.fit : a.fit,
      chipMaxWidth: lerpDouble(a.chipMaxWidth, b.chipMaxWidth, t),
      chipMinWidth: lerpDouble(a.chipMinWidth, b.chipMinWidth, t),
      pinnedChipWidth: lerpDouble(a.pinnedChipWidth, b.pinnedChipWidth, t),
      spacing: lerpDouble(a.spacing, b.spacing, t)!,
      physics: pickB ? b.physics : a.physics,
      alignment: pickB ? b.alignment : a.alignment,
      divider: a.divider == null && b.divider == null
          ? null
          : .lerp(a.divider ?? .none, b.divider ?? .none, t),
      mouseCursor: pickB ? b.mouseCursor : a.mouseCursor,
      chipBorderRadius: BorderRadiusGeometry.lerp(
        a.chipBorderRadius,
        b.chipBorderRadius,
        t,
      ),
      labelPadding: .lerp(a.labelPadding, b.labelPadding, t)!,
      labelColor: Color.lerp(a.labelColor, b.labelColor, t),
      labelStyle: TextStyle.lerp(a.labelStyle, b.labelStyle, t),
      unselectedLabelColor: Color.lerp(
        a.unselectedLabelColor,
        b.unselectedLabelColor,
        t,
      ),
      unselectedLabelStyle: TextStyle.lerp(
        a.unselectedLabelStyle,
        b.unselectedLabelStyle,
        t,
      ),
      overlayColor: _lerpColorStateProperty(a.overlayColor, b.overlayColor, t),
      indicator: Decoration.lerp(a.indicator, b.indicator, t),
      indicatorColor: Color.lerp(a.indicatorColor, b.indicatorColor, t),
      indicatorWeight: lerpDouble(a.indicatorWeight, b.indicatorWeight, t)!,
      indicatorPadding: .lerp(a.indicatorPadding, b.indicatorPadding, t)!,
      chipBackgroundColor: _lerpColorStateProperty(
        a.chipBackgroundColor,
        b.chipBackgroundColor,
        t,
      ),
      chipForegroundColor: _lerpColorStateProperty(
        a.chipForegroundColor,
        b.chipForegroundColor,
        t,
      ),
    );
  }
}

/// `InheritedTheme` exposing a [PlatThemeData] to descendants.
///
/// Use [PlatTheme.of] inside a builder to resolve the active values.
/// Falls back to a default [PlatThemeData] when no ancestor is found.
final class PlatTheme extends InheritedTheme {
  final PlatThemeData data;

  const PlatTheme({super.key, required this.data, required super.child});

  @override
  bool updateShouldNotify(PlatTheme old) => old.data != data;

  @override
  Widget wrap(BuildContext context, Widget child) {
    return PlatTheme(data: data, child: child);
  }

  static PlatThemeData of(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<PlatTheme>();
    if (inherited != null) return inherited.data;

    return Theme.of(context).extension<PlatThemeData>() ??
        const PlatThemeData();
  }
}

/// Visuals, layout knobs, and timing for the Plat UI.
///
/// Tab styling falls back to matching [ThemeData.tabBarTheme] /
/// [TabBarThemeData] values where the concepts overlap. Values set here
/// are Plat-specific and take precedence over Material tab theme values.
///
/// State-driven values use [WidgetStateProperty] so the same field
/// resolves to different values for hovered / focused / selected /
/// dragged / disabled. The mapping between [WidgetState]s and the
/// package's intrinsic states is:
///
/// - `WidgetState.selected` — tab is active in its group
/// - `WidgetState.focused`  — tab contains the focused leaf
/// - `WidgetState.hovered`  — pointer is over a default tab or divider
/// - `WidgetState.dragged`  — tab or divider is being dragged
/// - `WidgetState.disabled` — reserved for custom disabled tab chrome
@immutable
final class PlatThemeData extends ThemeExtension<PlatThemeData> {
  /// Tab bar layout, decoration, and tab-flow knobs.
  final PlatTabBarTheme tabBar;

  /// Split divider visuals and hit area.
  final PlatDividerTheme divider;

  /// Drop hint overlay visuals and timing.
  final PlatDropHintTheme dropHint;

  /// Background color for the reserved leaf drag-handle strip.
  ///
  /// Defaults to transparent so leaf content controls its own surface. Set this
  /// when an app wants the strip to match a known pane background.
  final Color? leafDragHandleBackgroundColor;

  const PlatThemeData({
    this.tabBar = const PlatTabBarTheme(),
    this.divider = const PlatDividerTheme(),
    this.dropHint = const PlatDropHintTheme(),
    this.leafDragHandleBackgroundColor,
  });

  @override
  int get hashCode =>
      Object.hash(tabBar, divider, dropHint, leafDragHandleBackgroundColor);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlatThemeData &&
          other.tabBar == tabBar &&
          other.divider == divider &&
          other.dropHint == dropHint &&
          other.leafDragHandleBackgroundColor == leafDragHandleBackgroundColor;

  @override
  PlatThemeData copyWith({
    PlatTabBarTheme? tabBar,
    PlatDividerTheme? divider,
    PlatDropHintTheme? dropHint,
    Color? leafDragHandleBackgroundColor,
  }) => PlatThemeData(
    tabBar: tabBar ?? this.tabBar,
    divider: divider ?? this.divider,
    dropHint: dropHint ?? this.dropHint,
    leafDragHandleBackgroundColor:
        leafDragHandleBackgroundColor ?? this.leafDragHandleBackgroundColor,
  );

  @override
  PlatThemeData lerp(ThemeExtension<PlatThemeData>? other, double t) {
    if (other is! PlatThemeData) return this;
    if (identical(this, other)) return this;
    return PlatThemeData(
      tabBar: .lerp(tabBar, other.tabBar, t),
      divider: .lerp(divider, other.divider, t),
      dropHint: .lerp(dropHint, other.dropHint, t),
      leafDragHandleBackgroundColor: Color.lerp(
        leafDragHandleBackgroundColor,
        other.leafDragHandleBackgroundColor,
        t,
      ),
    );
  }
}

/// Where chips anchor inside a [TabStripFit.scrollable] strip.
///
/// Has no effect under [TabStripFit.expand] or when the tabs overflow.
enum TabStripAlignment {
  /// Leading edge.
  start,

  /// Center of the bar.
  center,

  /// Trailing edge.
  end,
}

/// How a tab group lays its chips inside the available bar extent.
enum TabStripFit {
  /// Chips keep their intrinsic width, and the bar scrolls when they overflow.
  scrollable,

  /// Chips share the bar's main-axis extent.
  ///
  /// [PlatTabBarTheme.chipMinWidth] and [PlatTabBarTheme.chipMaxWidth] bound
  /// the shared width. Pinned chips can claim
  /// [PlatTabBarTheme.pinnedChipWidth], and the selected tab keeps room for a
  /// square affordance when possible.
  expand,
}
