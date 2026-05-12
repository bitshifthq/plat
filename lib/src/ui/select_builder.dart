// ignore_for_file: unsafe_variance
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart' show internal;

/// `ListenableBuilder` variant that rebuilds only when the value
/// produced by [selector] passes [buildWhen] — analogous to
/// `BlocBuilder.buildWhen`. The default [buildWhen] rebuilds when the
/// new value is not equal (`!=`) to the previous one.
///
/// Useful for selecting a slice of a richer [Listenable] (for example,
/// one pane's view from a `PlatController`) and skipping rebuilds
/// when the rest of the listenable's state changes.
///
/// ```dart
/// SelectListenableBuilder<MyStore, MySlice>(
///   listenable: bigStore,
///   selector: (store) => store.slice,
///   buildWhen: (prev, next) => prev.id != next.id,
///   builder: (context, slice) => SliceWidget(slice),
/// );
/// ```
@internal
class SelectListenableBuilder<L extends Listenable, T> extends StatefulWidget {
  /// Source the builder subscribes to.
  final L listenable;

  /// Pulls the slice this builder cares about. Called once on mount and
  /// on every [listenable] notification.
  final T Function(L listenable) selector;

  /// Renders the slice. Re-invoked only when [buildWhen] approves.
  final Widget Function(BuildContext context, T value) builder;

  /// Decides whether a notification should rebuild. Defaults to
  /// `next != previous`.
  final bool Function(T previous, T next)? buildWhen;

  const SelectListenableBuilder({
    super.key,
    required this.listenable,
    required this.selector,
    required this.builder,
    this.buildWhen,
  });

  @override
  State<SelectListenableBuilder<L, T>> createState() =>
      _SelectListenableBuilderState<L, T>();
}

class _SelectListenableBuilderState<L extends Listenable, T>
    extends State<SelectListenableBuilder<L, T>> {
  late T _value;

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);

  @override
  void didUpdateWidget(covariant SelectListenableBuilder<L, T> old) {
    super.didUpdateWidget(old);
    if (!identical(widget.listenable, old.listenable)) {
      old.listenable.removeListener(_onChange);
      widget.listenable.addListener(_onChange);
      _value = widget.selector(widget.listenable);
    }
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_onChange);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _value = widget.selector(widget.listenable);
    widget.listenable.addListener(_onChange);
  }

  void _onChange() {
    final next = widget.selector(widget.listenable);
    final shouldBuild = widget.buildWhen?.call(_value, next) ?? next != _value;
    if (!shouldBuild) return;
    setState(() => _value = next);
  }
}
