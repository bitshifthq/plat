import 'package:flutter/material.dart' show TabBarTheme, TabBarThemeData, Theme;
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart' show internal;

import '../../model/plat_snapshot.dart';
import '../drop/drag_payload.dart';
import '../theme.dart';
import 'chip.dart';
import 'view.dart';

BorderSide? _materialDivider(TabBarThemeData theme) {
  final color = theme.dividerColor;
  if (color == null) return null;
  final width = theme.dividerHeight ?? 1;
  if (width <= 0) return null;
  return BorderSide(color: color, width: width);
}

PlatTabDetails _placeholderDetails({
  required TabGroupSnapshot tabs,
  required TabSnapshot tab,
  required int index,
}) {
  return PlatTabDetails(
    snapshot: tab,
    group: tabs,
    index: index,
    states: const {.dragged},
  );
}

/// Builds the tab bar for a single [TabGroupSnapshot] group.
typedef PlatTabBarBuilder =
    PlatTabBar Function(BuildContext context, TabGroupSnapshot tabs);

/// Renders a single tab.
///
/// Also used for the dragged-tab placeholder slot
/// ([PlatTabBar.placeholderBuilder]).
typedef PlatTabBuilder =
    Widget Function(BuildContext context, PlatTabDetails tab);

/// Renders the dragged-tab feedback widget that follows the pointer.
/// Returning `null` falls through to the package default: the source tab
/// chrome, sized to the rendered chip, with the built-in close button hidden.
typedef DragFeedbackBuilder =
    Widget? Function(BuildContext context, PlatTabDetails tab);

/// Tab strip for the surrounding [TabGroupSnapshot] group.
///
/// [leading] and [trailing] sit at the start and end of the bar outside the
/// strip. [stripLeading] and [stripTrailing] sit inline with the tabs and move
/// with the strip when it scrolls.
///
/// Common bar styling can be set directly on the widget. When non-null,
/// each styling param overrides the matching field on the inherited
/// [PlatTabBarTheme]; null falls through to the theme.
final class PlatTabBar extends StatelessWidget {
  /// Widget pinned at the start of the bar, outside the tab strip.
  final Widget? leading;

  /// Widget pinned at the end of the bar, outside the tab strip.
  final Widget? trailing;

  /// Widget inserted before the first tab inside the strip.
  final Widget? stripLeading;

  /// Widget inserted after the last tab inside the strip.
  final Widget? stripTrailing;

  /// Renders a single tab for this bar. When null, the bar falls back to
  /// [PlatTabChip].
  final PlatTabBuilder? tabBuilder;

  /// Renders the preview placeholder for a dragged tab.
  final PlatTabBuilder? placeholderBuilder;

  /// Renders the dragged-tab feedback widget that follows the pointer.
  /// Returning `null` falls through to the package default: the source tab
  /// chrome, sized to the rendered chip, with the built-in close button hidden.
  final DragFeedbackBuilder? dragFeedbackBuilder;

  /// Padding inside the bar around its content. Overrides
  /// [PlatTabBarTheme.padding] when non-null.
  final EdgeInsetsGeometry? padding;

  /// Gap between adjacent tabs. Overrides [PlatTabBarTheme.spacing]
  /// when non-null.
  final double? spacing;

  /// Decoration drawn behind the bar's padded content. Overrides
  /// [PlatTabBarTheme.decoration] when non-null. For a plain background
  /// fill, pass `BoxDecoration(color: ...)`.
  final Decoration? decoration;

  /// Continuous baseline drawn on the body-facing edge of the bar.
  /// Overrides [PlatTabBarTheme.divider] when non-null; otherwise an
  /// explicitly configured Material tab divider may be used.
  final BorderSide? divider;

  /// Where tabs anchor inside the strip when the total tab extent is
  /// smaller than the bar. Overrides [PlatTabBarTheme.alignment] when
  /// non-null. Only meaningful under [TabStripFit.scrollable].
  final TabStripAlignment? alignment;

  /// How tabs are laid out along the bar. Overrides
  /// [PlatTabBarTheme.fit] when non-null.
  final TabStripFit? fit;

  /// Padding inside each default tab chip around its content. Overrides
  /// [PlatTabBarTheme.labelPadding] when non-null.
  final EdgeInsetsGeometry? labelPadding;

  /// Corner shape of each default chip. Overrides
  /// [PlatTabBarTheme.chipBorderRadius] when non-null.
  final BorderRadiusGeometry? chipBorderRadius;

  /// Text color for selected tabs. Overrides [PlatTabBarTheme.labelColor].
  final Color? labelColor;

  /// Text style for selected tabs. Overrides [PlatTabBarTheme.labelStyle].
  final TextStyle? labelStyle;

  /// Text color for unselected tabs.
  /// Overrides [PlatTabBarTheme.unselectedLabelColor].
  final Color? unselectedLabelColor;

  /// Text style for unselected tabs.
  /// Overrides [PlatTabBarTheme.unselectedLabelStyle].
  final TextStyle? unselectedLabelStyle;

  /// Default tab overlay color for hover / focus / press states. Overrides
  /// [PlatTabBarTheme.overlayColor] when non-null.
  final WidgetStateProperty<Color?>? overlayColor;

  /// Selected-tab indicator decoration. Overrides
  /// [PlatTabBarTheme.indicator] when non-null.
  final Decoration? indicator;

  /// Selected-tab indicator color. Overrides
  /// [PlatTabBarTheme.indicatorColor] when non-null.
  final Color? indicatorColor;

  /// Selected-tab indicator thickness. Overrides
  /// [PlatTabBarTheme.indicatorWeight] when non-null.
  final double? indicatorWeight;

  /// Insets applied to the selected-tab indicator. Overrides
  /// [PlatTabBarTheme.indicatorPadding] when non-null.
  final EdgeInsetsGeometry? indicatorPadding;

  /// Mouse cursor over each tab. Overrides [PlatTabBarTheme.mouseCursor] when
  /// non-null; otherwise an explicitly configured Material tab cursor may be
  /// used.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  const PlatTabBar({
    super.key,
    this.leading,
    this.trailing,
    this.stripLeading,
    this.stripTrailing,
    this.tabBuilder,
    this.placeholderBuilder,
    this.dragFeedbackBuilder,
    this.padding,
    this.spacing,
    this.decoration,
    this.divider,
    this.alignment,
    this.fit,
    this.labelPadding,
    this.chipBorderRadius,
    this.labelColor,
    this.labelStyle,
    this.unselectedLabelColor,
    this.unselectedLabelStyle,
    this.overlayColor,
    this.indicator,
    this.indicatorColor,
    this.indicatorWeight,
    this.indicatorPadding,
    this.mouseCursor,
  });

  @override
  Widget build(BuildContext context) {
    final baseTheme = PlatTheme.of(context);
    final theme = baseTheme.tabBar.copyWith(
      padding: padding,
      spacing: spacing,
      decoration: decoration,
      divider: divider,
      alignment: alignment,
      fit: fit,
      labelPadding: labelPadding,
      chipBorderRadius: chipBorderRadius,
      labelColor: labelColor,
      labelStyle: labelStyle,
      unselectedLabelColor: unselectedLabelColor,
      unselectedLabelStyle: unselectedLabelStyle,
      overlayColor: overlayColor,
      indicator: indicator,
      indicatorColor: indicatorColor,
      indicatorWeight: indicatorWeight,
      indicatorPadding: indicatorPadding,
      mouseCursor: mouseCursor,
    );
    final binding = _PlatTabBarBinding.of(context);
    final side = binding.tabs.side;

    Widget child = Padding(
      padding: theme.padding,
      child: Flex(
        crossAxisAlignment: .stretch,
        direction: side.isVertical ? .vertical : .horizontal,
        children: <Widget>[
          ?leading,
          Expanded(
            child: PlatTabStrip(
              theme: theme,
              view: binding.tabs,
              chips: binding.chips,
              hover: binding.hover,
              stripLeading: stripLeading,
              stripTrailing: stripTrailing,
              buildPlaceholder: (context, tab) {
                final details = _placeholderDetails(
                  tabs: binding.tabs,
                  tab: tab,
                  index: binding.hover?.at ?? -1,
                );
                final chip = platTabScope(
                  details: details,
                  child: Builder(
                    builder: (context) =>
                        tabBuilder?.call(context, details) ??
                        const PlatTabChip(),
                  ),
                );
                final placeholder = placeholderBuilder;

                return IgnorePointer(
                  child: placeholder == null
                      ? chip
                      : Stack(
                          fit: .passthrough,
                          children: [
                            Opacity(opacity: 0, child: chip),
                            Positioned.fill(
                              child: platTabScope(
                                details: details,
                                child: Builder(
                                  builder: (context) =>
                                      placeholder(context, details),
                                ),
                              ),
                            ),
                          ],
                        ),
                );
              },
            ),
          ),
          ?trailing,
        ],
      ),
    );

    if (theme.decoration != null) {
      child = DecoratedBox(decoration: theme.decoration!, child: child);
    } else {
      child = ColoredBox(
        color: theme.backgroundColor ?? Theme.of(context).colorScheme.surface,
        child: child,
      );
    }

    final dividerSide =
        theme.divider ?? _materialDivider(TabBarTheme.of(context));
    if (dividerSide != null) {
      child = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: switch (side) {
            .top => Border(bottom: dividerSide),
            .bottom => Border(top: dividerSide),
            .left => Border(right: dividerSide),
            .right => Border(left: dividerSide),
          },
        ),
        child: child,
      );
    }

    return PlatTheme(
      data: baseTheme.copyWith(tabBar: theme),
      child: child,
    );
  }
}

@internal
Widget platTabBarScope({
  Key? key,
  required TabGroupSnapshot tabs,
  required List<Widget> chips,
  required ({int at, TabDragPayload payload})? hover,
  required Widget child,
}) {
  return _PlatTabBarBinding(
    key: key,
    tabs: tabs,
    chips: chips,
    hover: hover,
    child: child,
  );
}

final class _PlatTabBarBinding extends InheritedWidget {
  final TabGroupSnapshot tabs;
  final List<Widget> chips;
  final ({int at, TabDragPayload payload})? hover;

  const _PlatTabBarBinding({
    super.key,
    required this.tabs,
    required this.chips,
    required this.hover,
    required super.child,
  });

  @override
  bool updateShouldNotify(_PlatTabBarBinding old) =>
      !identical(old.tabs, tabs) ||
      !identical(old.chips, chips) ||
      old.hover != hover;

  static _PlatTabBarBinding of(BuildContext context) {
    final binding = context
        .dependOnInheritedWidgetOfExactType<_PlatTabBarBinding>();
    assert(
      binding != null,
      'PlatTabBar must be placed inside a PlatView tab bar slot.',
    );
    return binding!;
  }
}
