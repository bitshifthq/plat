import 'package:flutter/material.dart' show Theme;
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Default divider used in splits. Reads visuals from [PlatThemeData].
///
/// Pure paint widget — gestures live on the split's render object.
final class PlatDivider extends StatelessWidget {
  /// Active interaction states (`hovered`, `dragged`).
  final Set<WidgetState> states;

  const PlatDivider({super.key, required this.states});

  @override
  Widget build(BuildContext context) {
    final dividerTheme = PlatTheme.of(context).divider;
    final decoration = dividerTheme.decoration?.resolve(states);
    if (decoration != null) return DecoratedBox(decoration: decoration);

    final resolvedColor = dividerTheme.color?.resolve(states);
    return ColoredBox(color: resolvedColor ?? _defaultColor(context, states));
  }

  static Color _defaultColor(BuildContext context, Set<WidgetState> states) {
    final cs = Theme.of(context).colorScheme;
    if (states.contains(WidgetState.dragged) ||
        states.contains(WidgetState.hovered)) {
      return cs.primary;
    }
    return cs.outlineVariant;
  }
}
