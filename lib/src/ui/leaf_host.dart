import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart' show internal;

import 'plat_scope.dart';

@internal
final class const PlatLeafHost({
  required super.key,
  required final String leafId,
  required final PlatLeafKeyRegistry registry,
  required final Widget child,
}) extends StatefulWidget {
  @override
  State<PlatLeafHost> createState() => _PlatLeafHostState();
}

class _PlatLeafHostState() extends State<PlatLeafHost> {
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
