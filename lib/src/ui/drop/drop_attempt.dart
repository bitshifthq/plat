import '../../controller/controller.dart';
import '../../model/plat_snapshot.dart';
import 'drop_zone.dart';

/// Decides whether a pending drop is allowed.
typedef DropPolicy = bool Function(DropAttempt attempt);

/// A pending drop being evaluated by the host drop policy.
final class const DropAttempt({
  /// Tab being dragged.
  required final TabSnapshot tab,

  /// Snapshot of the node the drag is hovering over.
  ///
  /// For tab payloads, body drops resolve to the surrounding tab group when
  /// possible, so [DropZone.center] means "drop into this group."
  required final PlatSnapshot target,

  /// Where the drop would land relative to [target].
  required final DropZone zone,

  /// Origin of the drag. Hosts can compare this with the destination view's
  /// controller when they care about cross-view policy. Identity comparison
  /// only — do not mutate through this reference.
  required final PlatController sourceController,
});
