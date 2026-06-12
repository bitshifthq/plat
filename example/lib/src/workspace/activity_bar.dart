import 'package:flutter/material.dart';
import 'package:plat/plat.dart';

import 'activity_button.dart';
import 'activity_target.dart';
import 'presets.dart';

final class ThemeActivityBar extends StatelessWidget {
  final ThemePreset preset;
  final PlatController controller;
  final _ActivitySide _side;

  const ThemeActivityBar.left({
    super.key,
    required this.preset,
    required this.controller,
  }) : _side = .left;

  const ThemeActivityBar.right({
    super.key,
    required this.preset,
    required this.controller,
  }) : _side = .right;

  List<ThemePanelTarget> get _targets => switch (_side) {
    .left => leftPanelTargets,
    .right => rightPanelTargets,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: preset.chrome.activityBarColor(colors),
          border: switch (_side) {
            .left => BorderDirectional(end: _border(theme)),
            .right => BorderDirectional(start: _border(theme)),
          },
        ),
        child: SizedBox(
          width: preset.chrome.activityBarWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              children: [
                for (final target in _targets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ThemeActivityButton(
                      preset: preset,
                      icon: target.icon,
                      tooltip: 'Open ${target.title.toLowerCase()}',
                      active: _selected(target),
                      onPressed: () => _open(target),
                    ),
                  ),
                if (_side == .left) ...[
                  const Spacer(),
                  ThemeActivityButton(
                    preset: preset,
                    icon: Icons.terminal,
                    tooltip: 'Toggle terminal',
                    active: _visible('bottom-slot'),
                    onPressed: () => _toggle('bottom-slot'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  BorderSide _border(ThemeData theme) => preset.chrome.hasActivityBarBorder
      ? BorderSide(color: theme.dividerColor)
      : .none;

  void _open(ThemePanelTarget target) {
    if (_selected(target)) {
      controller.setHidden(target.slotId, hidden: true);
      return;
    }
    controller.setSlotChild(slotId: target.slotId);
    controller.setSlotChild(slotId: target.slotId, child: target.pane);
    controller.setHidden(target.slotId, hidden: false);
  }

  bool _selected(ThemePanelTarget target) {
    final slot = controller.snapshot(target.slotId);
    if (slot is! SlotSnapshot || slot.hidden) return false;
    final child = slot.child;
    if (child is! LeafSnapshot) return false;
    return child.id == target.leafId;
  }

  void _toggle(String id) {
    final hidden = controller.snapshot(id)?.hidden ?? false;
    controller.setHidden(id, hidden: !hidden);
  }

  bool _visible(String id) => controller.snapshot(id)?.hidden == false;
}

enum _ActivitySide { left, right }
