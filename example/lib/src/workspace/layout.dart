import 'package:plat/plat.dart';

import 'activity_target.dart';

const themeMainSlotId = 'main-slot';

final Plat themeLayout = .row(
  children: [
    .slot(
      id: 'left-slot',
      persistent: true,
      child: ThemePanelTarget.navigator.pane,
      size: const .resizable(initial: .fraction(0.22), min: .pixel(136)),
    ),
    .column(
      children: [
        .slot(
          id: themeMainSlotId,
          persistent: true,
          child: .tabs([
            .leaf(id: 'editor', title: 'Editor'),
            .leaf(id: 'preview', title: 'Preview', preview: true),
            .leaf(id: 'settings', title: 'Settings'),
          ], id: 'main-tabs'),
        ),
        .slot(
          id: 'bottom-slot',
          size: const .resizable(initial: .fraction(0.28), min: .pixel(120)),
          child: .tabs([
            .leaf(id: 'terminal', title: 'Terminal'),
            .leaf(id: 'problems', title: 'Problems'),
            .leaf(id: 'output', title: 'Output'),
          ], id: 'bottom-tabs'),
        ),
      ],
    ),
    .slot(
      id: 'right-slot',
      persistent: true,
      child: ThemePanelTarget.outline.pane,
      size: const .resizable(initial: .fraction(0.2), min: .pixel(124)),
    ),
  ],
);

SlotSnapshot? findThemeSlot(PlatSnapshot? snapshot, String id) {
  return switch (snapshot) {
    null => null,
    SlotSnapshot(id: final slotId) when slotId == id => snapshot,
    SlotSnapshot(:final child) => findThemeSlot(child, id),
    SplitSnapshot(:final children) => _firstWhereNotNull(
      children,
      (child) => findThemeSlot(child, id),
    ),
    TabGroupSnapshot(:final tabs) => _firstWhereNotNull(
      tabs,
      (tab) => findThemeSlot(tab.child, id),
    ),
    LeafSnapshot() => null,
  };
}

String? firstThemeTabGroupIn(PlatSnapshot? snapshot) {
  return switch (snapshot) {
    null => null,
    TabGroupSnapshot(id: final id) => id,
    SlotSnapshot(:final child) => firstThemeTabGroupIn(child),
    SplitSnapshot(:final children) => _firstWhereNotNull(
      children,
      firstThemeTabGroupIn,
    ),
    LeafSnapshot() => null,
  };
}

T? _firstWhereNotNull<T, V>(Iterable<V> values, T? Function(V value) select) {
  for (final value in values) {
    final hit = select(value);
    if (hit != null) return hit;
  }
  return null;
}
