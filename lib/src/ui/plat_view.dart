import 'package:flutter/widgets.dart';

import '../controller/controller.dart';
import 'drop/drop_attempt.dart';
import 'pane_view.dart';
import 'plat_scope.dart';
import 'select_builder.dart';
import 'shortcuts.dart';
import 'tabs/bar.dart';

/// Renders a [PlatController]'s layout tree.
///
/// Subscribes to controller changes and re-renders only the affected subtree.
/// Each split and tab subtree keys off its node id so the element tree is
/// reused across edits.
///
/// Required parameters:
/// - [controller] — the controller driving the tree.
/// - [leafBuilder] — host content for each [LeafSnapshot]. Used both for
///   standalone leaves (sidebars, tool strips) and active tab contents;
///   dispatch on [LeafSnapshot.data] to vary content.
///
/// All other parameters are optional. Each defaults to package-owned
/// rendering that reads visuals from the ambient [PlatTheme].
///
/// ```dart
/// PlatView(
///   controller: controller,
///   leafBuilder: (ctx, leaf) => MyEditor(leaf: leaf),
///   tabBar: (ctx, tabs) => PlatTabBar(
///     dragFeedbackBuilder: (ctx, tab) => MyDragFeedback(tab: tab),
///   ),
///   slotBuilder: (ctx, slot, child) => slot.id == 'editor-root'
///       ? MyCard(child: child ?? const _EmptyState())
///       : (child ?? const SizedBox.shrink()),
/// );
/// ```
///
/// For per-group variation, pass a builder to [tabBar]. It receives the
/// current [TabGroupSnapshot] directly.
///
/// Visuals (tab chrome, divider colors, drop hints, and animation timing) live
/// in [PlatThemeData]. Wrap the [PlatView] in [PlatTheme] to override them.
///
/// Wrap a common ancestor in [PlatScope] when more than one [PlatView] should
/// preserve leaf widget state across cross-view moves. Standalone [PlatView]s
/// create a local [PlatScope] automatically when none is present.
///
/// Keyboard shortcuts (close, split, focus-direction, undo, etc.) are
/// installed automatically using platform-default bindings. Pass
/// [autofocus] = `false` to skip the initial focus request — required
/// when more than one [PlatView] sits in the same tree.
class PlatView extends StatelessWidget {
  /// Controller driving the layout tree.
  final PlatController controller;

  /// Renders a [LeafSnapshot]'s content.
  final LeafBuilder leafBuilder;

  /// Builds the widget mounted inside every tab group's bar slot.
  /// Defaults to `const PlatTabBar()` when null.
  final PlatTabBarBuilder? tabBar;

  /// Renders a [PlatSlot] wrapper. Default: passes the child through
  /// unchanged (or a neutral placeholder when the slot is empty).
  final SlotBuilder? slotBuilder;

  /// Decides whether a pending drop is allowed.
  final DropPolicy? dropPolicy;

  /// Whether the view should claim keyboard focus when first mounted.
  /// Pass `false` when more than one [PlatView] sits in the same tree
  /// to avoid focus-fighting; the user clicks into the view to activate
  /// shortcuts.
  final bool autofocus;

  const PlatView({
    super.key,
    required this.controller,
    required this.leafBuilder,
    this.tabBar,
    this.slotBuilder,
    this.dropPolicy,
    this.autofocus = true,
  });

  @override
  Widget build(BuildContext context) {
    if (maybePlatLeafKeyRegistryOf(context) == null) {
      return PlatScope(child: Builder(builder: _buildScoped));
    }
    return _buildScoped(context);
  }

  Widget _buildScoped(BuildContext context) {
    return Shortcuts(
      shortcuts: PlatKeyBindings.platformDefault().activators,
      child: Actions(
        actions: actionsFor(controller),
        child: Focus(
          autofocus: autofocus,
          child: SelectListenableBuilder<PlatController, String>(
            listenable: controller,
            selector: (controller) => controller.renderRootId(),
            builder: (context, paneId) => PlatPaneView(
              paneId: paneId,
              tabBar: tabBar,
              key: ValueKey(paneId),
              controller: controller,
              dropPolicy: dropPolicy,
              leafBuilder: leafBuilder,
              slotBuilder: slotBuilder,
            ),
          ),
        ),
      ),
    );
  }
}
