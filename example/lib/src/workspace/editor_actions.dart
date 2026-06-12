import 'package:flutter/material.dart';

import 'presets.dart';

final class ThemeEditorActions extends StatelessWidget {
  final ThemePreset preset;
  final ValueChanged<ThemeEditorTabKind> onOpenTab;

  const ThemeEditorActions({
    super.key,
    required this.preset,
    required this.onOpenTab,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        for (final kind in ThemeEditorTabKind.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: _EditorActionButton(
              preset: preset,
              kind: kind,
              onPressed: () => onOpenTab(kind),
            ),
          ),
      ],
    );
  }
}

final class ThemeEditorPlaceholder extends StatelessWidget {
  final ThemePreset preset;

  const ThemeEditorPlaceholder({super.key, required this.preset});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: .min,
              children: [
                Icon(
                  Icons.tab_outlined,
                  size: 28,
                  color: colors.onSurfaceVariant.withValues(alpha: 0.72),
                ),
                const SizedBox(height: 10),
                Text(
                  'No editor tabs open',
                  textAlign: .center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: .w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Open a tab from Navigator to continue.',
                  textAlign: .center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum ThemeEditorTabKind {
  normal('Document', Icons.article_outlined),
  pinned('Pinned', Icons.push_pin_outlined),
  locked('Locked', Icons.lock_outline),
  preview('Preview', Icons.visibility_outlined);

  final String label;
  final IconData icon;

  const ThemeEditorTabKind(this.label, this.icon);
}

final class _EditorActionButton extends StatelessWidget {
  final ThemePreset preset;
  final ThemeEditorTabKind kind;
  final VoidCallback onPressed;

  const _EditorActionButton({
    required this.preset,
    required this.kind,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final action = preset.chrome.editorAction;
    return Tooltip(
      message: 'Open ${kind.label.toLowerCase()} tab',
      child: SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(kind.icon, size: action.iconSize),
          label: Text(kind.label),
          style: _style(context, action),
        ),
      ),
    );
  }

  ButtonStyle _style(BuildContext context, PresetActionButton action) {
    final colors = Theme.of(context).colorScheme;
    return ButtonStyle(
      alignment: .centerLeft,
      visualDensity: preset.palette.density,
      tapTargetSize: .shrinkWrap,
      minimumSize: WidgetStatePropertyAll(Size.fromHeight(action.size)),
      padding: WidgetStatePropertyAll(
        EdgeInsetsDirectional.only(start: action.startPadding, end: 8),
      ),
      foregroundColor: WidgetStatePropertyAll(colors.onSurface),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed)) {
          return colors.primary.withValues(alpha: 0.10);
        }
        return Colors.transparent;
      }),
      overlayColor: WidgetStatePropertyAll(
        colors.primary.withValues(alpha: 0.08),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: action.radius),
      ),
      iconColor: WidgetStatePropertyAll(colors.onSurfaceVariant),
      iconSize: WidgetStatePropertyAll(action.iconSize),
      textStyle: WidgetStatePropertyAll(
        Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: .w500, height: 1.1),
      ),
    );
  }
}
