import 'package:flutter/material.dart';
import 'package:plat/plat.dart';

import 'activity_bar.dart';
import 'editor_actions.dart';
import 'empty_pane.dart';
import 'layout.dart';
import 'presets.dart';
import 'slot_shell.dart';
import 'tab_bar_actions.dart';
import 'tabs.dart';

final class ThemeWorkspaceView extends StatelessWidget {
  final PlatController controller;
  final ThemePreset preset;
  final bool showTabBarActions;
  final ValueChanged<ThemeEditorTabKind> onOpenEditorTab;

  const ThemeWorkspaceView({
    super.key,
    required this.controller,
    required this.preset,
    required this.showTabBarActions,
    required this.onOpenEditorTab,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ThemeActivityBar.left(preset: preset, controller: controller),
        Expanded(
          child: PlatView(
            controller: controller,
            tabBar: (context, tabs) => PlatTabBar(
              trailing: showTabBarActions
                  ? ThemeMinimizeButton.forGroup(
                      preset: preset,
                      tabs: tabs,
                      onPressed: (id) => controller.setHidden(id, hidden: true),
                    )
                  : null,
              tabBuilder: (context, tab) =>
                  ThemeTabChip(preset: preset, tab: tab),
            ),
            leafBuilder: (context, leaf) => ThemeEmptyPane(
              preset: preset,
              leaf: leaf,
              onOpenEditorTab: onOpenEditorTab,
            ),
            slotBuilder: (context, slot, child) => ThemeSlotShell(
              preset: preset,
              slot: slot,
              onMinimize: (id) => controller.setHidden(id, hidden: true),
              child: child,
            ),
            dropPolicy: _dropPolicy,
          ),
        ),
        ThemeActivityBar.right(preset: preset, controller: controller),
      ],
    );
  }

  bool _dropPolicy(DropAttempt attempt) {
    final sourceGroup = attempt.sourceController.tabGroupContaining(
      attempt.tab.id,
    );
    if (sourceGroup == null || !_isEditorArea(sourceGroup)) return true;
    return _isEditorArea(attempt.target.id);
  }

  bool _isEditorArea(String id) =>
      controller.pathTo(id).contains(themeMainSlotId);
}
