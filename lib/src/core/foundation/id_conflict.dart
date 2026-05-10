part of 'foundation.dart';

/// How a controller handles incoming pane ids that already exist in its tree.
enum IdConflict {
  /// Reject the whole incoming mutation when any incoming id already exists.
  reject,

  /// Remove existing destination nodes at conflicting ids before attaching the
  /// incoming pane.
  replace,
}
