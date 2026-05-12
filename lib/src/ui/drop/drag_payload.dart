import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart' show internal;

import '../../controller/controller.dart';
import '../../model/plat_snapshot.dart';

@immutable
@internal
sealed class PlatDragPayload {
  final PlatController source;
  final Offset feedbackAnchor;

  String get id;

  const PlatDragPayload({required this.source, this.feedbackAnchor = .zero});
}

@immutable
@internal
final class TabDragPayload extends PlatDragPayload {
  final TabSnapshot tab;
  final String sourceTabGroupId;

  const TabDragPayload({
    required this.tab,
    required super.source,
    required this.sourceTabGroupId,
    required super.feedbackAnchor,
  });

  @override
  String get id => tab.id;
}

@immutable
@internal
final class LeafDragPayload extends PlatDragPayload {
  final LeafSnapshot leaf;

  const LeafDragPayload({required this.leaf, required super.source});

  @override
  String get id => leaf.id;
}
