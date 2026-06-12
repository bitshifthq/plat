import 'package:flutter/material.dart';

import 'presets.dart';

final class PresetCard extends StatelessWidget {
  final ThemePreset value;
  final ThemePreset selected;
  final ValueChanged<ThemePreset> onSelected;

  const PresetCard(this.value, this.selected, this.onSelected, {super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final active = value == selected;
        final compact = constraints.maxWidth < 150;
        final palette = value.palette;
        return Padding(
          padding: const .only(bottom: 8, right: 8),
          child: InkWell(
            onTap: () => onSelected(value),
            borderRadius: palette.cardRadius,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: compact ? const .all(8) : const .all(12),
              decoration: BoxDecoration(
                color: active ? palette.raised : palette.surface,
                borderRadius: palette.cardRadius,
                border: Border.all(
                  color: active ? palette.accent : palette.border,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: palette.accent.withValues(alpha: 0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: compact ? _CompactContent(value) : _FullContent(value),
            ),
          ),
        );
      },
    );
  }
}

final class _CardHeader extends StatelessWidget {
  final ThemePreset value;
  final bool showShape;

  const _CardHeader({required this.value, this.showShape = false});

  @override
  Widget build(BuildContext context) {
    final palette = value.palette;
    return Row(
      children: [
        Expanded(
          child: Text(
            value.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (showShape) ...[
          Text(
            value.shape,
            style: TextStyle(
              color: palette.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
        ],
        _Swatch(color: palette.accent),
      ],
    );
  }
}

final class _CompactContent extends StatelessWidget {
  final ThemePreset value;

  const _CompactContent(this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        _CardHeader(value: value),
        const SizedBox(height: 8),
        _PreviewStrip(preset: value),
      ],
    );
  }
}

final class _FullContent extends StatelessWidget {
  final ThemePreset value;

  const _FullContent(this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        _CardHeader(value: value, showShape: true),
        const SizedBox(height: 3),
        Text(
          value.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: value.palette.muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        _PreviewStrip(preset: value),
      ],
    );
  }
}

final class _PreviewStrip extends StatelessWidget {
  final ThemePreset preset;
  const _PreviewStrip({required this.preset});

  @override
  Widget build(BuildContext context) {
    final palette = preset.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.lowSurface,
        borderRadius: palette.chipRadius,
        border: Border.all(color: palette.border),
      ),
      child: Padding(
        padding: const .all(4),
        child: Row(
          children: [
            _PreviewTab(preset, 46, selected: true),
            const SizedBox(width: 4),
            _PreviewTab(preset, 34),
            const SizedBox(width: 4),
            _PreviewTab(preset, 26),
          ],
        ),
      ),
    );
  }
}

final class _PreviewTab extends StatelessWidget {
  final ThemePreset preset;
  final int flex;
  final bool selected;
  const _PreviewTab(this.preset, this.flex, {this.selected = false});

  @override
  Widget build(BuildContext context) {
    final palette = preset.palette;
    return Expanded(
      flex: flex,
      child: Container(
        height: preset.chrome.tab.previewHeight,
        decoration: BoxDecoration(
          color: selected ? palette.accent : palette.surface,
          borderRadius: palette.chipRadius,
        ),
      ),
    );
  }
}

final class _Swatch extends StatelessWidget {
  final Color color;
  const _Swatch({required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: const SizedBox.square(dimension: 14),
    );
  }
}
