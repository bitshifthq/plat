import 'package:flutter/material.dart';
import 'package:plat/plat.dart';

import 'presets.dart';

IconData _tabIcon(TabSnapshot tab) {
  if (tab.locked) return Icons.lock_outline;
  if (tab.pinned) return Icons.push_pin_outlined;
  if (tab.preview) return Icons.visibility_outlined;

  return switch (tab.id) {
    'nav' || 'assets' => Icons.folder_outlined,
    'preview' => Icons.visibility_outlined,
    'settings' => Icons.tune,
    'terminal' => Icons.terminal,
    'problems' => Icons.error_outline,
    'outline' || 'details' => Icons.list_alt,
    _ => Icons.insert_drive_file_outlined,
  };
}

final class ThemeTabChip extends StatelessWidget {
  final ThemePreset preset;
  final PlatTabDetails tab;

  const ThemeTabChip({super.key, required this.preset, required this.tab});

  bool get _closeable => !tab.snapshot.locked && !tab.snapshot.pinned;

  bool get _showCloseButton => preset.chrome.tab.shouldShowCloseButton(
    states: tab.states,
    locked: tab.snapshot.locked,
    pinned: tab.snapshot.pinned,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final style = preset.chrome.tab;
        final finite = constraints.maxWidth.isFinite;
        final showLeading =
            !finite || constraints.maxWidth >= style.leadingMinWidth;
        final showCloseSlot =
            _closeable &&
            (style.reserveCloseButtonSpace || _showCloseButton) &&
            (!finite || constraints.maxWidth >= style.closeMinWidth);
        final chip = PlatTabChip(
          leading: showLeading
              ? _TabLeadingIcon(preset: preset, icon: _tabIcon(tab.snapshot))
              : null,
          label: Text(tab.snapshot.title),
          trailing: showCloseSlot
              ? _TabCloseButton(preset: preset, visible: _showCloseButton)
              : null,
          gap: style.gap,
        );

        if (preset != .oneDark || !tab.states.contains(WidgetState.selected)) {
          return chip;
        }

        return Stack(
          fit: .passthrough,
          children: [
            chip,
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const .all(Radius.circular(999)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

final class _TabCloseButton extends StatelessWidget {
  final ThemePreset preset;
  final bool visible;

  const _TabCloseButton({required this.preset, required this.visible});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = preset.chrome.tab;
    return Visibility(
      visible: visible,
      maintainAnimation: true,
      maintainSize: true,
      maintainState: true,
      child: PlatTabCloseButton(
        size: style.closeButtonSize,
        iconSize: style.closeIconSize,
        hoverColor: style.closeHoverColor(colors),
      ),
    );
  }
}

final class _TabLeadingIcon extends StatelessWidget {
  final ThemePreset preset;
  final IconData icon;

  const _TabLeadingIcon({required this.preset, required this.icon});

  @override
  Widget build(BuildContext context) {
    final style = preset.chrome.tab;
    return SizedBox.square(
      dimension: style.leadingIconSize,
      child: Center(child: Icon(icon, size: style.leadingGlyphSize)),
    );
  }
}
