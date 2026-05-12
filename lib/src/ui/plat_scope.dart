import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart' show internal;

@internal
PlatLeafKeyRegistry? maybePlatLeafKeyRegistryOf(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<_InheritedPlatScope>()?.registry;

@internal
PlatLeafKeyRegistry platLeafKeyRegistryOf(BuildContext context) {
  final registry = maybePlatLeafKeyRegistryOf(context);
  assert(registry != null, 'PlatView must be mounted under a PlatScope.');
  return registry!;
}

@internal
final class PlatLeafKeyRegistry {
  final _leafKeys = <String, GlobalKey>{};

  GlobalKey leafKeyFor(String id) {
    return _leafKeys.putIfAbsent(id, () => GlobalKey(debugLabel: 'leaf:$id'));
  }

  void removeLeafKeyIfCurrent(String id, GlobalKey key) {
    if (identical(_leafKeys[id], key)) _leafKeys.remove(id);
  }
}

/// Runtime boundary for one or more plat views.
///
/// Wrap a common ancestor in [PlatScope] to let descendant plat views share
/// leaf widget state across structural moves and cross-view handoff. The scope
/// also ensures an [Overlay] exists for drag/drop when the ambient tree does
/// not already provide one.
class PlatScope extends StatefulWidget {
  final Widget child;

  const PlatScope({super.key, required this.child});

  @override
  State<PlatScope> createState() => _PlatScopeState();
}

class _PlatScopeState extends State<PlatScope> {
  final _registry = PlatLeafKeyRegistry();

  @override
  Widget build(BuildContext context) {
    Widget tree = _InheritedPlatScope(registry: _registry, child: widget.child);
    if (Overlay.maybeOf(context) == null) {
      final scopedTree = tree;
      tree = Overlay(
        initialEntries: [OverlayEntry(builder: (_) => scopedTree)],
      );
    }
    return tree;
  }
}

class _InheritedPlatScope extends InheritedWidget {
  final PlatLeafKeyRegistry registry;

  const _InheritedPlatScope({required this.registry, required super.child});

  @override
  bool updateShouldNotify(_InheritedPlatScope oldWidget) {
    return !identical(oldWidget.registry, registry);
  }
}
