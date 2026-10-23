import 'package:material_ui/material_ui.dart';
import 'package:plat/plat.dart';

import 'editor_actions.dart';
import 'presets.dart';
import 'tab_bar_actions.dart';

final class const ThemeSlotShell({
  super.key,
  required final ThemePreset preset,
  required final SlotSnapshot slot,
  required final Widget? child,
  required final ValueChanged<String> onMinimize,
}) extends StatelessWidget {
  bool get _isEmptyEditorSlot => switch (slot.child) {
    TabGroupSnapshot(tabs: []) when slot.id == 'main-slot' => true,
    _ => false,
  };

  bool get _isSideSlot => slot.id == 'left-slot' || slot.id == 'right-slot';

  @override
  Widget build(BuildContext context) {
    final child = this.child;
    if (_isSideSlot) {
      if (child == null) return const SizedBox.shrink();
      return _GroupShell(
        preset: preset,
        child: _ToolWindowShell(
          preset: preset,
          title: slot.child?.firstLeaf?.title ?? '',
          onMinimize: () => onMinimize(slot.id),
          child: child,
        ),
      );
    }

    if (_isEmptyEditorSlot) {
      return _GroupShell(
        preset: preset,
        child: ThemeEditorPlaceholder(preset: preset),
      );
    }

    if (child != null || slot.id != 'main-slot') {
      return child == null
          ? const SizedBox.shrink()
          : _GroupShell(preset: preset, child: child);
    }

    return _GroupShell(
      preset: preset,
      child: ColoredBox(color: Theme.of(context).colorScheme.surface),
    );
  }
}

final class const _GroupShell({
  required final ThemePreset preset,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!preset.chrome.wrapsGroups) return child;
    final colors = Theme.of(context).colorScheme;
    final groupRadius = preset.palette.groupRadius;

    return Padding(
      padding: const EdgeInsets.all(4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: groupRadius,
        ),
        child: ClipRRect(borderRadius: groupRadius, child: child),
      ),
    );
  }
}

final class const _ToolWindowShell({
  required final ThemePreset preset,
  required final String title,
  required final VoidCallback onMinimize,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final chrome = preset.chrome;
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: chrome.wrapsGroups
                ? colors.surface
                : colors.surfaceContainerLow,
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: SizedBox(
            height: PlatTheme.of(context).tabBar.size,
            child: Padding(
              padding: chrome.toolWindowPadding,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: .w500,
                      ),
                    ),
                  ),
                  ThemeMinimizeButton(preset: preset, onPressed: onMinimize),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
