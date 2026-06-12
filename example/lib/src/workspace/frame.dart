import 'package:flutter/material.dart';

import 'presets.dart';

final class ThemePreviewFrame extends StatelessWidget {
  final ThemePreset preset;
  final Widget child;

  const ThemePreviewFrame({
    super.key,
    required this.preset,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final chrome = preset.chrome;
    final palette = preset.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: chrome.frameColor(colors),
        borderRadius: palette.frameRadius,
        border: chrome.hasFrameBorder ? .all(color: theme.dividerColor) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(borderRadius: palette.frameRadius, child: child),
      ),
    );
  }
}
