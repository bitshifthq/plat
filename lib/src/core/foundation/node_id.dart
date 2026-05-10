part of 'foundation.dart';

final _idRandom = Random();
var _idSeq = 0;

/// Creates a fresh layout id, unique within the running process.
@internal
String generateNodeId() {
  _idSeq = (_idSeq + 1) & 0x7fffffff;
  final random = _idRandom.nextInt(0x7fffffff);
  return 'p_${random.toRadixString(36)}_${_idSeq.toRadixString(36)}';
}
