import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart' show internal;

import '../../controller/controller.dart';
import '../../model/plat_snapshot.dart';

@immutable
@internal
sealed class const PlatDragPayload({
  required final PlatController source,
  final Offset feedbackAnchor = .zero,
}) {
  String get id;
}

@immutable
@internal
final class const TabDragPayload({
  required final TabSnapshot tab,
  required super.source,
  required final String sourceTabGroupId,
  required super.feedbackAnchor,
}) extends PlatDragPayload {
  @override
  String get id => tab.id;
}

@immutable
@internal
final class const LeafDragPayload({
  required final LeafSnapshot leaf,
  required super.source,
}) extends PlatDragPayload {
  @override
  String get id => leaf.id;
}
