import 'package:flutter/material.dart';

import 'presets.dart';

final class ThemeActivityButton extends StatelessWidget {
  final ThemePreset preset;
  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onPressed;

  const ThemeActivityButton({
    super.key,
    required this.preset,
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = preset.chrome.activityButton;
    final foreground = active ? colors.onSurface : colors.onSurfaceVariant;
    return SizedBox.square(
      dimension: style.size,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: .zero,
        iconSize: style.iconSize,
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(foreground),
          backgroundColor: WidgetStatePropertyAll(
            active ? style.background(colors) : null,
          ),
          overlayColor: WidgetStatePropertyAll(
            colors.primary.withValues(alpha: 0.14),
          ),
          side: WidgetStatePropertyAll(active ? style.border(colors) : .none),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: style.radius),
          ),
        ),
        icon: Icon(icon),
      ),
    );
  }
}
