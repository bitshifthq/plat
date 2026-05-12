import 'package:flutter/material.dart'
    show
        ColorScheme,
        Icons,
        MaterialLocalizations,
        TabBarTheme,
        TabBarThemeData,
        Theme,
        Tooltip;
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart' show internal;

import '../../core/foundation/foundation.dart' show TabBarSide;
import '../../model/plat_snapshot.dart';
import '../theme.dart';

Color? _defaultOverlayColor(
  ColorScheme colors,
  Set<WidgetState> states,
  bool selected,
) {
  if (states.contains(WidgetState.pressed)) {
    return colors.primary.withValues(alpha: 0.10);
  }
  if (states.contains(WidgetState.hovered)) {
    return (selected ? colors.primary : colors.onSurface).withValues(
      alpha: 0.08,
    );
  }
  return null;
}

Color _indicatorColor(BuildContext context, PlatTabBarTheme theme) {
  return theme.indicatorColor ??
      TabBarTheme.of(context).indicatorColor ??
      Theme.of(context).colorScheme.primary;
}

Color? _materialLabelColor(
  TabBarThemeData theme,
  Set<WidgetState> states,
  bool selected,
) {
  final labelColor = theme.labelColor;
  if (labelColor is WidgetStateColor) return labelColor.resolve(states);
  if (selected) return labelColor;
  return WidgetStateProperty.resolveAs<Color?>(
        theme.unselectedLabelColor,
        states,
      ) ??
      labelColor?.withValues(alpha: labelColor.a * 0.7);
}

TextStyle? _materialLabelStyle(TabBarThemeData theme, bool selected) {
  if (selected) return theme.labelStyle;
  return theme.unselectedLabelStyle ?? theme.labelStyle;
}

Color? _platLabelColor(
  PlatTabBarTheme theme,
  Set<WidgetState> states,
  bool selected,
) {
  if (selected) {
    return WidgetStateProperty.resolveAs<Color?>(theme.labelColor, states);
  }

  final unselectedLabelColor = WidgetStateProperty.resolveAs<Color?>(
    theme.unselectedLabelColor,
    states,
  );
  if (unselectedLabelColor != null) return unselectedLabelColor;

  final labelColor = theme.labelColor;
  if (labelColor is WidgetStateColor) return labelColor.resolve(states);
  return null;
}

Color _defaultChipBackground(
  ColorScheme colors,
  Set<WidgetState> states,
  bool selected,
) {
  if (states.contains(WidgetState.dragged)) {
    return Color.alphaBlend(
      colors.primary.withValues(alpha: 0.26),
      colors.surfaceContainerHigh,
    );
  }
  return selected ? colors.surfaceContainerHigh : colors.surface;
}

/// Default composable tab chip used by [PlatTabBar].
///
/// Hosts can use this directly from [PlatTabBar.tabBuilder] to keep plat's
/// standard tab treatment while replacing the leading, label, or trailing
/// content.
final class PlatTabChip extends StatelessWidget {
  /// Optional widget before the label.
  final Widget? leading;

  /// Optional label widget. Defaults to the tab title, falling back to id.
  final Widget? label;

  /// Optional widget after the label.
  final Widget? trailing;

  /// Gap between leading / label / trailing slots.
  final double gap;

  /// Padding around this chip's content. When null, falls back to
  /// [PlatTabBarTheme.labelPadding].
  final EdgeInsetsGeometry? labelPadding;

  /// How to clip this chip's content.
  final Clip clipBehavior;

  const PlatTabChip({
    super.key,
    this.leading,
    this.label,
    this.trailing,
    this.gap = 6,
    this.labelPadding,
    this.clipBehavior = .none,
  });

  @override
  Widget build(BuildContext context) {
    final tab = _PlatTabScope.of(context);
    final theme = PlatTheme.of(context).tabBar;
    final materialTabTheme = TabBarTheme.of(context);
    final states = tab.states;
    final colorScheme = Theme.of(context).colorScheme;
    final selected = states.contains(WidgetState.selected);

    final background =
        theme.chipBackgroundColor?.resolve(states) ??
        _defaultChipBackground(colorScheme, states, selected);
    final foreground =
        theme.chipForegroundColor?.resolve(states) ??
        _platLabelColor(theme, states, selected) ??
        _materialLabelColor(materialTabTheme, states, selected) ??
        (selected ? colorScheme.onSurface : colorScheme.onSurfaceVariant);
    final baseStyle =
        _materialLabelStyle(materialTabTheme, selected) ??
        Theme.of(context).textTheme.labelMedium ??
        const TextStyle();
    final stateStyle = selected ? theme.labelStyle : theme.unselectedLabelStyle;
    final style = baseStyle.merge(stateStyle).copyWith(color: foreground);
    final overlay =
        theme.overlayColor?.resolve(states) ??
        materialTabTheme.overlayColor?.resolve(states) ??
        _defaultOverlayColor(colorScheme, states, selected);

    final child = Container(
      alignment: .center,
      padding: labelPadding ?? theme.labelPadding,
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: background,
        borderRadius: theme.chipBorderRadius,
        border: _indicatorBorder(context, theme, states, tab.group.side),
      ),
      foregroundDecoration: overlay == null
          ? null
          : BoxDecoration(color: overlay, borderRadius: theme.chipBorderRadius),
      child: _content(tab, style),
    );

    return _withStackedIndicator(context, child, theme, states, tab.group.side);
  }

  Widget _content(PlatTabDetails tab, TextStyle style) {
    final effectiveLabel =
        label ??
        Text(
          tab.snapshot.title.isEmpty ? tab.snapshot.id : tab.snapshot.title,
          maxLines: 1,
          overflow: .ellipsis,
        );

    final content = leading == null && trailing == null
        ? effectiveLabel
        : LayoutBuilder(
            builder: (context, constraints) => Row(
              mainAxisSize: constraints.maxWidth.isFinite ? .max : .min,
              children: [
                if (leading != null) ...[leading!, SizedBox(width: gap)],
                Flexible(
                  fit: constraints.maxWidth.isFinite ? .tight : .loose,
                  child: effectiveLabel,
                ),
                if (trailing != null) ...[SizedBox(width: gap), trailing!],
              ],
            ),
          );

    return IconTheme.merge(
      data: IconThemeData(color: style.color),
      child: DefaultTextStyle.merge(
        style: style,
        maxLines: 1,
        overflow: .ellipsis,
        child: content,
      ),
    );
  }

  BoxBorder? _indicatorBorder(
    BuildContext context,
    PlatTabBarTheme theme,
    Set<WidgetState> states,
    TabBarSide side,
  ) {
    if (!states.contains(WidgetState.selected)) return null;
    if (theme.indicator != null || theme.indicatorPadding != .zero) {
      return null;
    }
    if (theme.indicatorWeight <= 0) return null;

    final borderSide = BorderSide(
      color: _indicatorColor(context, theme),
      width: theme.indicatorWeight,
    );
    return switch (side) {
      .top => Border(bottom: borderSide),
      .bottom => Border(top: borderSide),
      .left => Border(right: borderSide),
      .right => Border(left: borderSide),
    };
  }

  Widget _withStackedIndicator(
    BuildContext context,
    Widget child,
    PlatTabBarTheme theme,
    Set<WidgetState> states,
    TabBarSide side,
  ) {
    if (!states.contains(WidgetState.selected)) return child;
    if (theme.indicator == null && theme.indicatorPadding == .zero) {
      return child;
    }
    if (theme.indicatorWeight <= 0) return child;

    final decoration =
        theme.indicator ??
        BoxDecoration(color: _indicatorColor(context, theme));
    final insets = theme.indicatorPadding.resolve(
      Directionality.maybeOf(context),
    );
    final positioned = switch (side) {
      .top => Positioned(
        left: insets.left,
        right: insets.right,
        bottom: insets.bottom,
        height: theme.indicatorWeight,
        child: DecoratedBox(decoration: decoration),
      ),
      .bottom => Positioned(
        left: insets.left,
        right: insets.right,
        top: insets.top,
        height: theme.indicatorWeight,
        child: DecoratedBox(decoration: decoration),
      ),
      .left => Positioned(
        top: insets.top,
        bottom: insets.bottom,
        right: insets.right,
        width: theme.indicatorWeight,
        child: DecoratedBox(decoration: decoration),
      ),
      .right => Positioned(
        top: insets.top,
        bottom: insets.bottom,
        left: insets.left,
        width: theme.indicatorWeight,
        child: DecoratedBox(decoration: decoration),
      ),
    };

    return Stack(fit: .passthrough, children: [child, positioned]);
  }
}

/// Small close affordance suitable for [PlatTabChip.trailing].
final class PlatTabCloseButton extends StatelessWidget {
  /// Called when the close button is pressed.
  ///
  /// When null, the button closes the surrounding Plat tab if used inside a
  /// [PlatTabChip] or [PlatTabBar.tabBuilder].
  final VoidCallback? onPressed;

  /// Tooltip shown while hovering the close button. When null, falls back to
  /// Material's localized close label when available.
  final String? tooltip;

  /// Semantic label for assistive technologies. When null, uses [tooltip].
  final String? semanticLabel;

  /// Icon color.
  final Color? color;

  /// Background color while hovered.
  final Color? hoverColor;

  /// Logical size of the hit area.
  final double size;

  /// Logical size of the icon.
  final double iconSize;

  const PlatTabCloseButton({
    super.key,
    this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.color,
    this.hoverColor,
    this.size = 16,
    this.iconSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final scope = _PlatTabScope.maybeScopeOf(context);
    final hideCloseButton = scope?.hideCloseButton ?? false;

    final colorScheme = Theme.of(context).colorScheme;
    final effectiveOnPressed = onPressed ?? scope?.close;
    final enabled = effectiveOnPressed != null;
    final effectiveTooltip =
        tooltip ??
        Localizations.of<MaterialLocalizations>(
          context,
          MaterialLocalizations,
        )?.closeButtonTooltip;
    final effectiveSemanticLabel = semanticLabel ?? effectiveTooltip;
    final effectiveColor =
        color ??
        (enabled
            ? IconTheme.of(context).color ?? colorScheme.onSurfaceVariant
            : colorScheme.onSurface.withValues(alpha: 0.38));

    Widget child = _HoverBox(
      cursor: !enabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      builder: (context, {required hovered}) => Semantics(
        button: true,
        enabled: enabled,
        label: effectiveSemanticLabel,
        child: GestureDetector(
          onTap: effectiveOnPressed,
          behavior: .opaque,
          child: Container(
            width: size,
            height: size,
            alignment: .center,
            decoration: BoxDecoration(
              color: hovered && effectiveOnPressed != null
                  ? hoverColor ?? colorScheme.onSurface.withValues(alpha: 0.08)
                  : null,
              borderRadius: .circular(4),
            ),
            child: Icon(Icons.close, size: iconSize, color: effectiveColor),
          ),
        ),
      ),
    );
    if (effectiveTooltip case final tooltip?) {
      child = Tooltip(message: tooltip, child: child);
    }
    if (hideCloseButton) {
      child = Visibility(
        visible: false,
        maintainState: true,
        maintainAnimation: true,
        maintainSize: true,
        child: child,
      );
    }
    return child;
  }
}

/// Details passed to tab chrome builders.
///
/// The package owns tab activation, drag wiring, hover / pressed state, and
/// locked-tab handling. Custom tab widgets read this object to reflect state
/// without taking over Plat's tab mechanics.
///
/// Use [snapshot] for tab data and [states] for visual state.
@immutable
final class PlatTabDetails {
  /// Public immutable tab snapshot.
  final TabSnapshot snapshot;

  /// The group that owns the tab bar currently building this tab.
  final TabGroupSnapshot group;

  /// Index in [group]. For drag placeholders this is the preview index.
  final int index;

  /// Current interaction states for the tab.
  final Set<WidgetState> states;

  @internal
  PlatTabDetails({
    required this.snapshot,
    required this.group,
    required this.index,
    required Set<WidgetState> states,
  }) : states = Set.unmodifiable(states);
}

@internal
Widget platTabScope({
  Key? key,
  required PlatTabDetails details,
  VoidCallback? close,
  bool hideCloseButton = false,
  required Widget child,
}) {
  return _PlatTabScope(
    key: key,
    details: details,
    close: close,
    hideCloseButton: hideCloseButton,
    child: child,
  );
}

final class _PlatTabScope extends InheritedWidget {
  final PlatTabDetails details;
  final VoidCallback? close;
  final bool hideCloseButton;

  const _PlatTabScope({
    super.key,
    required this.details,
    this.close,
    this.hideCloseButton = false,
    required super.child,
  });

  @override
  bool updateShouldNotify(_PlatTabScope old) =>
      old.details != details ||
      old.close != close ||
      old.hideCloseButton != hideCloseButton;

  static PlatTabDetails? maybeOf(BuildContext context) {
    return maybeScopeOf(context)?.details;
  }

  static _PlatTabScope? maybeScopeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_PlatTabScope>();
  }

  static PlatTabDetails of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No Plat tab details found in context.');
    return scope!;
  }
}

final class _HoverBox extends StatefulWidget {
  final MouseCursor cursor;
  final Widget Function(BuildContext context, {required bool hovered}) builder;

  const _HoverBox({required this.cursor, required this.builder});

  @override
  State<_HoverBox> createState() => _HoverBoxState();
}

final class _HoverBoxState extends State<_HoverBox> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: widget.builder(context, hovered: _hovered),
    );
  }

  void _setHovered(bool value) {
    if (!mounted || _hovered == value) return;
    setState(() => _hovered = value);
  }
}
