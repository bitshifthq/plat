import 'package:flutter/material.dart';

import 'preset_card.dart';
import 'presets.dart';

final class ThemeSelector extends StatelessWidget {
  final ThemePreset preset;
  final ValueChanged<ThemePreset> onPresetChanged;
  final bool compact;

  const ThemeSelector({
    super.key,
    required this.preset,
    required this.onPresetChanged,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: compact ? const .all(10) : const .all(16),
        child: compact
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(preset: preset),
                  const SizedBox(height: 10),
                  _PresetStrip(preset, onPresetChanged),
                ],
              )
            : Column(
                crossAxisAlignment: .start,
                children: [
                  _Header(preset: preset),
                  const SizedBox(height: 16),
                  Expanded(child: _PresetGrid(preset, onPresetChanged)),
                ],
              ),
      ),
    );
  }
}

final class _Header extends StatelessWidget {
  final ThemePreset preset;

  const _Header({required this.preset});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DefaultTextStyle.merge(
      style: TextStyle(color: colors.onSurface),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            'Workspace themes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            preset.description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            'Colors, density, shape, dividers, and tab bars.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

final class _PresetGrid extends StatelessWidget {
  final ThemePreset preset;
  final ValueChanged<ThemePreset> onPresetChanged;

  const _PresetGrid(this.preset, this.onPresetChanged);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      childAspectRatio: 1.18,
      crossAxisCount: 2,
      children: [
        for (final value in ThemePreset.values)
          PresetCard(value, preset, onPresetChanged),
      ],
    );
  }
}

final class _PresetStrip extends StatelessWidget {
  final ThemePreset preset;
  final ValueChanged<ThemePreset> onPresetChanged;

  const _PresetStrip(this.preset, this.onPresetChanged);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 126,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final value in [
            preset,
            for (final value in ThemePreset.values)
              if (value != preset) value,
          ])
            SizedBox(
              width: 204,
              child: PresetCard(value, preset, onPresetChanged),
            ),
        ],
      ),
    );
  }
}
