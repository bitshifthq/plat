import 'package:flutter_test/flutter_test.dart';

import '../../../helpers.dart';

void main() {
  group('SlotNode', () {
    test('constructor sets every field to its documented default', () {
      final s = SlotNode(id: 's');

      expect(s.child, isNull);
      expect(s.persistent, isFalse);
      expect(s.boundsMaximize, isFalse);
      expect(s.hidden, isFalse);
      expect(s.size, const PlatSize.auto());
    });

    group('copyWith', () {
      test('preserves every field when called with no arguments', () {
        final original = SlotNode(
          id: 's',
          persistent: true,
          boundsMaximize: true,
          child: TabGroupNode(id: 't', tabs: treeTabs([tab('a')])),
        );

        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.persistent, isTrue);
        expect(copy.boundsMaximize, isTrue);
        expect(copy.child, isA<TabGroupNode>());
      });

      test('overrides the wrapped child when one is given', () {
        final original = SlotNode(
          id: 's',
          child: TabGroupNode(id: 't1', tabs: treeTabs([tab('a')])),
        );
        final swapped = TabGroupNode(id: 't2', tabs: treeTabs([tab('b')]));

        expect(original.copyWith(child: swapped).child, same(swapped));
      });

      test('clearChild removes the child', () {
        final original = SlotNode(
          id: 's',
          child: TabGroupNode(id: 't', tabs: treeTabs([tab('a')])),
        );

        expect(original.copyWith(clearChild: true).child, isNull);
      });
    });

    group('replace', () {
      test('returns the replacement when target is the receiver', () {
        final original = SlotNode(id: 's');
        final swap = TabGroupNode(id: 't', tabs: treeTabs([tab('a')]));

        expect(original.replace('s', swap), same(swap));
      });

      test('returns null when the receiver is replaced with null', () {
        expect(SlotNode(id: 's').replace('s', null), isNull);
      });

      test('returns the same instance when target is unknown', () {
        final original = SlotNode(
          id: 's',
          child: TabGroupNode(id: 't', tabs: treeTabs([tab('a')])),
        );

        expect(original.replace('missing', null), same(original));
        expect(SlotNode(id: 's').replace('missing', null), isA<SlotNode>());
      });

      test('non-persistent SlotNode collapses when its child is removed', () {
        final root = SlotNode(
          id: 'slot',
          child: TabGroupNode(id: 'group', tabs: treeTabs([tab('a')])),
        );

        expect(root.replace('group', null), isNull);
      });

      test('persistent SlotNode stays as a stub when its child is removed', () {
        final root = SlotNode(
          id: 'slot',
          persistent: true,
          child: TabGroupNode(id: 'group', tabs: treeTabs([tab('a')])),
        );

        final next = root.replace('group', null)! as SlotNode;

        expect(next.id, 'slot');
        expect(next.child, isNull);
      });

      test('preserves the wrapper id when swapping the child', () {
        final root = SlotNode(
          id: 'slot',
          persistent: true,
          child: TabGroupNode(id: 'group', tabs: treeTabs([tab('a')])),
        );
        final swapped = TabGroupNode(
          id: 'replacement',
          tabs: treeTabs([tab('x')]),
        );

        final next = root.replace('group', swapped)! as SlotNode;

        expect(next.id, 'slot');
        expect(next.child, same(swapped));
      });

      test('recurses through nested SplitNode and SlotNode descendants', () {
        final splitsRoot = SlotNode(
          id: 'slot',
          persistent: true,
          child: hSplit('inner', [
            TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
            TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
          ]),
        );
        final slotRoot = SlotNode(
          id: 'outer',
          persistent: true,
          child: SlotNode(
            id: 'inner',
            persistent: true,
            child: TabGroupNode(id: 'group', tabs: treeTabs([tab('a')])),
          ),
        );

        final fromSplits = splitsRoot.replace('right', null)! as SlotNode;
        final fromSlot = slotRoot.replace('group', null)! as SlotNode;

        expect((fromSplits.child! as TabGroupNode).id, 'left');
        expect((fromSlot.child! as SlotNode).child, isNull);
      });
    });

    group('removeLeaf', () {
      test('preserves a persistent SlotNode when its only TabGroupNode child '
          'empties', () {
        final root = SlotNode(
          id: 'slot',
          persistent: true,
          child: TabGroupNode(id: 'group', tabs: treeTabs([tab('a')])),
        );

        expect((root.remove('a')! as SlotNode).child, isNull);
      });

      test('collapses a non-persistent SlotNode when its only TabGroupNode '
          'empties', () {
        final root = SlotNode(
          id: 'slot',
          child: TabGroupNode(id: 'group', tabs: treeTabs([tab('a')])),
        );

        expect(root.remove('a'), isNull);
      });
    });

    group('toString', () {
      test('reports the empty body when no child is set', () {
        expect(SlotNode(id: 's').toString(), 'SlotNode(s, empty)');
      });

      test('lists every set flag', () {
        expect(
          SlotNode(id: 's', persistent: true).toString(),
          'SlotNode(s, persistent, empty)',
        );
        expect(
          SlotNode(id: 's', boundsMaximize: true).toString(),
          'SlotNode(s, boundsMaximize, empty)',
        );
      });

      test('embeds the child rendering when present', () {
        final body = SlotNode(
          id: 's',
          child: TabGroupNode(id: 't', tabs: treeTabs([tab('a')])),
        ).toString();

        expect(body, contains('TabGroupNode(t,'));
      });
    });
  });
}
