import 'package:flutter_test/flutter_test.dart';
import 'package:plat/plat.dart';
import 'package:plat/src/core/tree/tree.dart' show LeafNode;

void main() {
  group('LeafNode', () {
    test('uses the documented defaults', () {
      const leaf = LeafNode(id: 'p');

      expect(leaf.title, '');
      expect(leaf.locked, isFalse);
      expect(leaf.draggable, isFalse);
      expect(leaf.focused, isFalse);
      expect(leaf.maximized, isFalse);
      expect(leaf.hidden, isFalse);
      expect(leaf.size, const PlatSize.auto());
      expect(leaf.data, isNull);
    });

    test('preserves opaque host data', () {
      expect(
        const LeafNode(id: 'p', data: 'project-tree').data,
        'project-tree',
      );
    });

    group('copyWith', () {
      test('overrides named fields without changing the id', () {
        const original = LeafNode(id: 'p', title: 'a');
        const target = PlatSize.fixed(.pixel(200));

        expect(original.copyWith(title: 'b').title, 'b');
        expect(original.copyWith(focused: true).focused, isTrue);
        expect(original.copyWith(maximized: true).maximized, isTrue);
        expect(original.copyWith(hidden: true).hidden, isTrue);
        expect(original.copyWith(locked: true).locked, isTrue);
        expect(original.copyWith(draggable: true).draggable, isTrue);
        expect(original.copyWith(size: target).size, target);
        expect(original.copyWith(title: 'b').id, original.id);
      });
    });

    group('equality', () {
      test('matches when every field matches and differs otherwise', () {
        const a = LeafNode(id: 'p', title: 'p', locked: true);
        const b = LeafNode(id: 'p', title: 'p', locked: true);
        const base = LeafNode(id: 'p', title: 'a');

        expect(a, b);
        expect(a.hashCode, b.hashCode);
        expect(base, isNot(const LeafNode(id: 'p', title: 'b')));
        expect(
          const LeafNode(id: 'p'),
          isNot(const LeafNode(id: 'p', focused: true)),
        );
        expect(
          const LeafNode(id: 'p', data: 'a'),
          isNot(const LeafNode(id: 'p', data: 'b')),
        );
      });
    });

    group('toString', () {
      test('renders the plain, titled, and flagged forms', () {
        expect(const LeafNode(id: 'p').toString(), 'Leaf(p)');
        expect(
          const LeafNode(id: 'p', title: 'Profile').toString(),
          'Leaf(p, "Profile")',
        );
        expect(
          const LeafNode(
            id: 'p',
            locked: true,
            draggable: true,
            focused: true,
            maximized: true,
          ).toString(),
          'Leaf(p, locked, draggable, focused, maximized)',
        );
      });
    });
  });
}
