import 'package:flutter/material.dart';
import 'package:plat/plat.dart';

import 'presets.dart';

WidgetStateProperty<Color?> _chipFill(
  Color selected,
  Color hovered, {
  Color? rest,
  Color? dragged,
}) => WidgetStateProperty.resolveWith((states) {
  if (states.contains(WidgetState.dragged)) return dragged;
  if (states.contains(WidgetState.selected)) return selected;
  if (states.contains(WidgetState.hovered)) return hovered;
  return rest;
});

WidgetStateProperty<Color?> _chipText(Color selected, Color rest) =>
    WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return selected;
      return rest;
    });

PlatDividerTheme _flatDivider(Color canvas) => PlatDividerTheme(
  hitSlop: 6,
  decoration: WidgetStatePropertyAll(BoxDecoration(color: canvas)),
);

WidgetStateProperty<Color?> _ideaChipFill() =>
    WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.dragged)) {
        return ideaTabDraggedFill;
      }
      if (states.contains(WidgetState.selected)) {
        return ideaTabSelectedFill;
      }
      if (states.contains(WidgetState.hovered)) {
        return ideaTabHoverFill;
      }
      return Colors.transparent;
    });

PlatDividerTheme _splitDivider(Color color, Color accent) => PlatDividerTheme(
  color: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.dragged)) {
      return accent;
    }
    return color;
  }),
);

extension ThemePresetPlatTheme on ThemePreset {
  PlatThemeData platTheme() {
    final palette = this.palette;
    return switch (this) {
      .material => PlatThemeData(
        tabBar: PlatTabBarTheme(
          size: 40,
          spacing: 4,
          padding: const .symmetric(horizontal: 6, vertical: 5),
          backgroundColor: palette.lowSurface,
          divider: BorderSide(color: palette.border),
          chipBorderRadius: const BorderRadius.all(Radius.circular(999)),
          labelPadding: const .symmetric(horizontal: 14, vertical: 6),
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          indicatorWeight: 0,
          chipBackgroundColor: _chipFill(
            palette.accent.withValues(alpha: 0.16),
            palette.accent.withValues(alpha: 0.08),
            rest: Colors.transparent,
          ),
          chipForegroundColor: _chipText(palette.accent, palette.muted),
        ),
        divider: _splitDivider(palette.border, palette.accent),
        dropHint: PlatDropHintTheme(
          fill: palette.accent.withValues(alpha: 0.14),
          border: BorderSide(color: palette.accent),
        ),
        leafDragHandleBackgroundColor: palette.lowSurface,
      ),
      .compact => PlatThemeData(
        tabBar: PlatTabBarTheme(
          size: 30,
          padding: const .symmetric(horizontal: 2, vertical: 2),
          backgroundColor: palette.lowSurface,
          divider: BorderSide(color: palette.border),
          chipBorderRadius: const BorderRadius.all(Radius.circular(2)),
          labelPadding: const .symmetric(horizontal: 6, vertical: 4),
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          indicatorColor: palette.accent,
          indicatorWeight: 0,
          chipBackgroundColor: _chipFill(
            palette.accent,
            palette.surface,
            rest: Colors.transparent,
          ),
          chipForegroundColor: _chipText(Colors.white, palette.foreground),
        ),
        divider: _splitDivider(palette.border, palette.accent),
        dropHint: PlatDropHintTheme(
          edgeFraction: 0.16,
          fill: palette.accent.withValues(alpha: 0.16),
          border: BorderSide(color: palette.accent),
        ),
        leafDragHandleBackgroundColor: palette.lowSurface,
      ),
      .idea => PlatThemeData(
        tabBar: PlatTabBarTheme(
          size: 38,
          spacing: 4,
          padding: const .all(5),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
          ),
          divider: BorderSide(color: palette.border.withValues(alpha: 0.72)),
          chipBorderRadius: const BorderRadius.all(Radius.circular(6)),
          labelPadding: const EdgeInsetsDirectional.only(
            start: 10,
            end: 5,
            top: 6,
            bottom: 6,
          ),
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          indicatorWeight: 0,
          indicatorPadding: const .symmetric(horizontal: 8),
          chipBackgroundColor: _ideaChipFill(),
          chipForegroundColor: _chipText(palette.foreground, palette.muted),
        ),
        divider: _flatDivider(palette.canvas),
        dropHint: const PlatDropHintTheme(
          fill: ideaDropHintFill,
          border: .none,
        ),
        leafDragHandleBackgroundColor: palette.lowSurface,
      ),
      .dracula => PlatThemeData(
        tabBar: PlatTabBarTheme(
          size: 36,
          spacing: 2,
          padding: const .only(left: 4, right: 4, top: 3),
          backgroundColor: palette.lowSurface,
          divider: BorderSide(color: palette.border),
          labelColor: palette.foreground,
          unselectedLabelColor: palette.muted,
          chipBorderRadius: .zero,
          labelPadding: const EdgeInsetsDirectional.only(
            start: 9,
            end: 5,
            top: 6,
            bottom: 6,
          ),
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          indicatorColor: const Color(0xFFFF79C6),
          indicatorPadding: const .symmetric(horizontal: 9),
          chipBackgroundColor: _chipFill(
            Colors.transparent,
            const Color(0xFFFF79C6).withValues(alpha: 0.10),
            rest: Colors.transparent,
            dragged: Color.alphaBlend(
              const Color(0xFFFF79C6).withValues(alpha: 0.26),
              palette.raised,
            ),
          ),
          chipForegroundColor: _chipText(
            const Color(0xFFFFFFFF),
            palette.muted,
          ),
        ),
        divider: _splitDivider(palette.border, palette.accent),
        dropHint: PlatDropHintTheme(
          fill: palette.accent.withValues(alpha: 0.20),
          border: BorderSide(color: palette.accent, width: 1.5),
        ),
        leafDragHandleBackgroundColor: palette.lowSurface,
      ),
      .oneDark => PlatThemeData(
        tabBar: PlatTabBarTheme(
          padding: const .only(left: 2, right: 2, top: 2),
          backgroundColor: palette.lowSurface,
          divider: BorderSide(color: palette.border),
          labelColor: palette.foreground,
          unselectedLabelColor: palette.muted,
          chipBorderRadius: .zero,
          indicatorColor: palette.accent,
          indicatorWeight: 0,
          indicatorPadding: const .symmetric(horizontal: 10),
          labelPadding: const EdgeInsetsDirectional.only(
            start: 9,
            end: 5,
            top: 5,
            bottom: 5,
          ),
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          chipBackgroundColor: _chipFill(
            palette.raised,
            palette.surface,
            rest: Colors.transparent,
            dragged: palette.raised,
          ),
          chipForegroundColor: _chipText(palette.foreground, palette.muted),
        ),
        divider: _splitDivider(palette.border, palette.accent),
        dropHint: PlatDropHintTheme(
          fill: palette.accent.withValues(alpha: 0.22),
          border: BorderSide(color: palette.accent, width: 1.5),
        ),
        leafDragHandleBackgroundColor: palette.lowSurface,
      ),
    };
  }
}
