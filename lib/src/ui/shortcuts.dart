import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart' show internal;

import '../controller/controller.dart';
import '../core/foundation/foundation.dart';
import '../model/plat_snapshot.dart';

/// Split the focused leaf along [axis], moving the active tab into a
/// new sibling group on [side].
@internal
final class const SplitIntent({
  required final Axis axis,
  final PlatSide side = .right,
}) extends Intent;

/// Close the focused tab.
@internal
final class const CloseTabIntent() extends Intent;

/// Close every tab in the focused tab group node.
@internal
final class const CloseGroupIntent() extends Intent;

/// Move active tab in the focused tab group node by [delta] (signed).
@internal
final class const CycleTabIntent(final int delta) extends Intent;

/// Activate the n-th tab (1-indexed) in the focused tab group node.
@internal
final class const JumpTabIntent(final int oneIndex) extends Intent;

/// Move focus to the previous / next tab group node in tree order.
@internal
final class const FocusDirectionIntent(final PlatSide direction) extends Intent;

/// Toggle maximize on the focused tab group node.
@internal
final class const MaximizeIntent() extends Intent;

/// Undo a layout change.
@internal
final class const PlatUndoIntent() extends Intent;

/// Redo a layout change.
@internal
final class const PlatRedoIntent() extends Intent;

/// A bundle of keyboard activators mapped to plat intents. The view
/// installs platform-default bindings unconditionally.
@internal
@immutable
final class const PlatKeyBindings(
  final Map<ShortcutActivator, Intent> activators,
) {
  /// Empty bindings. Useful for hosts wiring their own [Shortcuts].
  static const none = PlatKeyBindings(<ShortcutActivator, Intent>{});

  /// macOS / iOS defaults: Cmd-modified.
  static final mac = PlatKeyBindings({
    ..._coreBindings(meta: true),
    const SingleActivator(.bracketLeft, meta: true): const CycleTabIntent(-1),
    const SingleActivator(.bracketRight, meta: true): const CycleTabIntent(1),
  });

  /// Windows / Linux defaults: Ctrl-modified.
  static final desktop = PlatKeyBindings(_coreBindings(control: true));

  /// `mac` on Apple platforms, `desktop` elsewhere.
  factory platformDefault() {
    final isApple =
        defaultTargetPlatform == .macOS || defaultTargetPlatform == .iOS;
    return isApple ? mac : desktop;
  }
}

Map<ShortcutActivator, Intent> _coreBindings({
  bool meta = false,
  bool control = false,
}) {
  final m = meta;
  final c = control;
  return {
    SingleActivator(.keyW, meta: m, control: c): const CloseTabIntent(),
    SingleActivator(.keyW, meta: m, control: c, shift: true):
        const CloseGroupIntent(),
    SingleActivator(.backslash, meta: m, control: c): const SplitIntent(
      axis: .horizontal,
    ),
    SingleActivator(.backslash, meta: m, control: c, shift: true):
        const SplitIntent(axis: .vertical, side: .bottom),
    const SingleActivator(.tab, control: true): const CycleTabIntent(1),
    const SingleActivator(.tab, control: true, shift: true):
        const CycleTabIntent(-1),
    SingleActivator(.arrowLeft, meta: m, control: c, alt: true):
        const FocusDirectionIntent(.left),
    SingleActivator(.arrowRight, meta: m, control: c, alt: true):
        const FocusDirectionIntent(.right),
    SingleActivator(.arrowUp, meta: m, control: c, alt: true):
        const FocusDirectionIntent(.top),
    SingleActivator(.arrowDown, meta: m, control: c, alt: true):
        const FocusDirectionIntent(.bottom),
    SingleActivator(.enter, meta: m, control: c, shift: true):
        const MaximizeIntent(),
    SingleActivator(.keyZ, meta: m, control: c): const PlatUndoIntent(),
    SingleActivator(.keyZ, meta: m, control: c, shift: true):
        const PlatRedoIntent(),
    for (var i = 1; i <= 9; i++)
      SingleActivator(_digitKey(i), meta: m, control: c): JumpTabIntent(i),
  };
}

LogicalKeyboardKey _digitKey(int n) => switch (n) {
  1 => .digit1,
  2 => .digit2,
  3 => .digit3,
  4 => .digit4,
  5 => .digit5,
  6 => .digit6,
  7 => .digit7,
  8 => .digit8,
  9 => .digit9,
  _ => .digit0,
};

/// Actions map binding plat intents to controller mutations. Wired up
/// by [PlatView] internally.
@internal
Map<Type, Action<Intent>> actionsFor(PlatController c) => {
  SplitIntent: _Fn<SplitIntent>((i) {
    final tabGroupId = c.focusedTabGroupId();
    if (tabGroupId != null) {
      c.splitActiveTab(tabGroupId: tabGroupId, side: i.side);
    }
  }),
  CloseTabIntent: _Fn<CloseTabIntent>((_) {
    final tabGroupId = c.focusedTabGroupId();
    final id = tabGroupId == null ? null : c.activeTabId(tabGroupId);
    if (id != null) c.close(id);
  }),
  CloseGroupIntent: _Fn<CloseGroupIntent>((_) {
    final id = c.focusedTabGroupId();
    if (id != null) c.close(id);
  }),
  CycleTabIntent: _Fn<CycleTabIntent>((i) {
    final tabGroupId = c.focusedTabGroupId();
    if (tabGroupId == null) return;
    final view = c.snapshot(tabGroupId);
    if (view is! TabGroupSnapshot || view.tabs.isEmpty) return;
    final n = view.tabs.length;
    final next = ((view.activeIndex + i.delta) % n + n) % n;
    c.focus(view.tabs[next].id);
  }),
  JumpTabIntent: _Fn<JumpTabIntent>((i) {
    final tabGroupId = c.focusedTabGroupId();
    if (tabGroupId == null) return;
    final view = c.snapshot(tabGroupId);
    if (view is! TabGroupSnapshot || view.tabs.isEmpty) return;
    final at = (i.oneIndex - 1).clamp(0, view.tabs.length - 1);
    c.focus(view.tabs[at].id);
  }),
  FocusDirectionIntent: _Fn<FocusDirectionIntent>((i) {
    final delta = i.direction == .left || i.direction == .top ? -1 : 1;
    final next = c.nextTabGroupId(c.focusedTabGroupId(), delta: delta);
    if (next != null) c.focus(next);
  }),
  MaximizeIntent: _Fn<MaximizeIntent>((_) {
    final id = c.focusedTabGroupId();
    if (id != null) c.setMaximized(id, maximized: c.maximizedId() != id);
  }),
  PlatUndoIntent: _Fn<PlatUndoIntent>((_) => c.undo()),
  PlatRedoIntent: _Fn<PlatRedoIntent>((_) => c.redo()),
};

class _Fn<T extends Intent>(void Function(T) run) extends CallbackAction<T> {
  this : super(onInvoke: (i) => run(i));
}
