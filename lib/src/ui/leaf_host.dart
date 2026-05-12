import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart' show internal;

import 'plat_scope.dart';

@internal
final class PlatLeafHost extends StatefulWidget {
  final String leafId;
  final Widget child;
  final PlatLeafKeyRegistry registry;

  const PlatLeafHost({
    required super.key,
    required this.leafId,
    required this.registry,
    required this.child,
  });

  @override
  State<PlatLeafHost> createState() => _PlatLeafHostState();
}

class _PlatLeafHostState extends State<PlatLeafHost> {
  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    final key = widget.key;
    assert(key is GlobalKey, 'PlatLeafHost must be mounted with a GlobalKey.');
    widget.registry.removeLeafKeyIfCurrent(widget.leafId, key! as GlobalKey);
    super.dispose();
  }
}
