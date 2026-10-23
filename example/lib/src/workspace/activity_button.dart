import 'package:material_ui/material_ui.dart';

import 'presets.dart';

final class const ThemeActivityButton({
  super.key,
  required final ThemePreset preset,
  required final IconData icon,
  required final String tooltip,
  required final bool active,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
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
