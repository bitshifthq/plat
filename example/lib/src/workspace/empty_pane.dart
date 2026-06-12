import 'package:flutter/material.dart';
import 'package:plat/plat.dart';

import 'editor_actions.dart';
import 'presets.dart';

final class ThemeEmptyPane extends StatelessWidget {
  final ThemePreset preset;
  final LeafSnapshot leaf;
  final ValueChanged<ThemeEditorTabKind> onOpenEditorTab;

  const ThemeEmptyPane({
    super.key,
    required this.preset,
    required this.leaf,
    required this.onOpenEditorTab,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final leafRadius = preset.chrome.leafRadius;
    return ClipRRect(
      borderRadius: leafRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _surfaceColor(scheme),
          borderRadius: leafRadius,
        ),
        child: switch (leaf.id) {
          'nav' => _NavigatorPane(
            preset: preset,
            onOpenEditorTab: onOpenEditorTab,
          ),
          'assets' || 'outline' || 'details' => const SizedBox.expand(),
          _ => Center(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                leaf.title,
                maxLines: 1,
                overflow: .ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.72),
                  fontWeight: .w600,
                ),
              ),
            ),
          ),
        },
      ),
    );
  }

  Color _surfaceColor(ColorScheme scheme) {
    if (preset.chrome.wrapsGroups) return scheme.surface;

    return switch (leaf.id) {
      'nav' ||
      'assets' ||
      'outline' ||
      'details' => scheme.surfaceContainerLowest,
      'terminal' || 'problems' => scheme.surfaceContainerLow,
      _ => scheme.surface,
    };
  }
}

final class _NavigatorPane extends StatelessWidget {
  final ThemePreset preset;
  final ValueChanged<ThemeEditorTabKind> onOpenEditorTab;

  const _NavigatorPane({required this.preset, required this.onOpenEditorTab});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: .topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Text(
                'Open editor tab',
                maxLines: 1,
                overflow: .ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: .w500,
                ),
              ),
              const SizedBox(height: 10),
              ThemeEditorActions(preset: preset, onOpenTab: onOpenEditorTab),
            ],
          ),
        ),
      ),
    );
  }
}
