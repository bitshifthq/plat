import 'package:flutter/material.dart';
import 'package:plat/plat.dart';

import 'presets.dart';

final class ThemeMinimizeButton extends StatelessWidget {
  final ThemePreset preset;
  final VoidCallback onPressed;

  const ThemeMinimizeButton({
    super.key,
    required this.preset,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = preset.chrome.tabAction;
    return Center(
      child: IconButton(
        tooltip: 'Minimize',
        onPressed: onPressed,
        padding: .zero,
        iconSize: style.iconSize,
        constraints: BoxConstraints.tight(Size.square(style.size)),
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(colors.onSurfaceVariant),
          overlayColor: WidgetStatePropertyAll(
            colors.primary.withValues(alpha: 0.12),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: style.radius),
          ),
        ),
        icon: const Icon(Icons.remove),
      ),
    );
  }

  static Widget? forGroup({
    required ThemePreset preset,
    required TabGroupSnapshot tabs,
    required ValueChanged<String> onPressed,
  }) {
    final target = switch (tabs.id) {
      'bottom-tabs' => 'bottom-slot',
      _ => null,
    };

    return switch (target) {
      final String id => ThemeMinimizeButton(
        preset: preset,
        onPressed: () => onPressed(id),
      ),
      _ => null,
    };
  }
}
