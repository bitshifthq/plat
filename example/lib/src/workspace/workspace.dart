import 'package:flutter/material.dart';
import 'package:plat/plat.dart';

import 'editor_actions.dart';
import 'frame.dart';
import 'layout.dart';
import 'plat_theme.dart';
import 'presets.dart';
import 'selector.dart';
import 'workspace_view.dart';

final class WorkspaceExample extends StatefulWidget {
  final ThemePreset initialPreset;

  const WorkspaceExample({super.key, this.initialPreset = .material});

  @override
  State<WorkspaceExample> createState() => _WorkspaceExampleState();
}

final class _WorkspaceExampleState extends State<WorkspaceExample> {
  late final PlatController _controller;
  late ThemePreset _preset;
  var _nextEditorTab = 1;

  @override
  void initState() {
    super.initState();
    _preset = widget.initialPreset;
    _controller = PlatController(initialPlat: themeLayout);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openEditorTab(ThemeEditorTabKind kind) {
    final count = _nextEditorTab++;
    final PlatTab tab = .leaf(
      id: '${kind.name}-$count',
      title: '${kind.label} $count',
      pinned: kind == .pinned,
      locked: kind == .locked,
      preview: kind == .preview,
    );
    final targetGroup = _focusedEditorGroupId ?? _firstEditorGroupId;
    if (targetGroup == null) {
      _controller.insertTabIntoSlot(slotId: themeMainSlotId, tab: tab);
      return;
    }

    _controller.insertTab(tabGroupId: targetGroup, tab: tab);
  }

  String? get _focusedEditorGroupId {
    final group = _controller.focusedTabGroupId();
    if (group == null || !_isEditorArea(group)) return null;
    return group;
  }

  String? get _firstEditorGroupId => firstThemeTabGroupIn(_mainSlot?.child);

  SlotSnapshot? get _mainSlot =>
      findThemeSlot(_controller.root, themeMainSlotId);

  bool _isEditorArea(String id) =>
      _controller.pathTo(id).contains(themeMainSlotId);

  @override
  Widget build(BuildContext context) {
    final theme = _preset.palette
        .materialTheme(Theme.of(context))
        .copyWith(extensions: [_preset.platTheme()]);
    return AnimatedTheme(
      data: theme,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final colors = Theme.of(context).colorScheme;
          final compact = constraints.maxWidth < 720;
          final selector = ThemeSelector(
            preset: _preset,
            compact: compact,
            onPresetChanged: (preset) => setState(() => _preset = preset),
          );
          final preview = ColoredBox(
            color: colors.surfaceContainerLow,
            child: Padding(
              padding: compact ? const .all(10) : const .all(16),
              child: ThemePreviewFrame(
                preset: _preset,
                child: ThemeWorkspaceView(
                  controller: _controller,
                  preset: _preset,
                  showTabBarActions: !compact,
                  onOpenEditorTab: _openEditorTab,
                ),
              ),
            ),
          );

          return ColoredBox(
            color: colors.surfaceContainerLowest,
            child: Flex(
              direction: compact ? .vertical : .horizontal,
              children: [
                SizedBox(width: compact ? null : 304, child: selector),
                Expanded(child: preview),
              ],
            ),
          );
        },
      ),
    );
  }
}
