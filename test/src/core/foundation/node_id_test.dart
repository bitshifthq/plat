import 'package:flutter_test/flutter_test.dart';
import 'package:plat/src/core/foundation/foundation.dart';

void main() {
  group('generateNodeId', () {
    Set<String> generateIds(int count) {
      return {for (var i = 0; i < count; i++) generateNodeId()};
    }

    test('returns distinct ids across repeated calls', () {
      final ids = generateIds(1000);

      expect(ids, hasLength(1000));
    });
  });
}
