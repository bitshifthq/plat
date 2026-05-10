import 'package:flutter_test/flutter_test.dart';

import '../../../helpers.dart';

void main() {
  group('SplitNode', () {
    group('constructor', () {
      test('validates child count', () {
        expect(
          () => SplitNode(
            id: 's',
            axis: .horizontal,
            children: [
              TabGroupNode(id: 'a', tabs: treeTabs([tab('a')])),
            ],
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    test('constructor sets every field to its documented default', () {
      final s = _minimalSplit();

      expect(s.resizable, isTrue);
      expect(s.size, const PlatSize.auto());
      expect(s.hidden, isFalse);
    });

    test('preserves per-child sizes on construction', () {
      final s = SplitNode(
        id: 's',
        axis: .horizontal,
        children: [
          TabGroupNode(
            id: 'a',
            tabs: treeTabs([tab('a')]),
            size: const .fixed(.pixel(200)),
          ),
          TabGroupNode(
            id: 'b',
            tabs: treeTabs([tab('b')]),
            size: const .resizable(initial: .fraction(0.4)),
          ),
          TabGroupNode(id: 'c', tabs: treeTabs([tab('c')])),
        ],
      );

      expect(s.children[0].size, const PlatSize.fixed(.pixel(200)));
      expect(
        s.children[1].size,
        const PlatSize.resizable(initial: .fraction(0.4)),
      );
      expect(s.children[2].size, const PlatSize.auto());
    });

    group('copyWith', () {
      test('overrides provided fields and preserves the id', () {
        final s = _minimalSplit();
        final updated = s.copyWith(resizable: false, axis: .vertical);

        expect(updated.resizable, isFalse);
        expect(updated.axis, SplitAxis.vertical);
        expect(updated.id, s.id);
      });
    });

    group('parentOf', () {
      test('returns the immediate parent split and child index', () {
        final root = hSplit('root', [
          TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
          TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
        ]);

        final found = root.parentOf('right');

        expect(found?.parent.id, 'root');
        expect(found?.index, 1);
      });

      test('walks through SlotNode wrappers to reach inner splits', () {
        final inner = hSplit('inner', [
          TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
          TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
        ]);
        final root = SplitNode(
          id: 'root',
          axis: .vertical,
          children: [
            SlotNode(id: 'slot', child: inner),
            TabGroupNode(id: 'terminal', tabs: treeTabs([tab('t')])),
          ],
        );

        final found = root.parentOf('right');

        expect(found?.parent.id, 'inner');
        expect(found?.index, 1);
      });

      test('returns null for the receiver, leaves, and missing ids', () {
        final root = hSplit('root', [
          TabGroupNode(id: 'group', tabs: treeTabs([tab('a')])),
          TabGroupNode(id: 'other', tabs: treeTabs([tab('b')])),
        ]);

        expect(root.parentOf('root'), isNull);
        expect(root.parentOf('a'), isNull);
        expect(root.parentOf('missing'), isNull);
      });
    });

    group('replace', () {
      test('returns the replacement when target is the receiver', () {
        final original = _minimalSplit();
        final swap = TabGroupNode(id: 't', tabs: treeTabs([tab('x')]));

        expect(original.replace(original.id, swap), same(swap));
      });

      test('returns null when the receiver is replaced with null', () {
        expect(_minimalSplit().replace('s', null), isNull);
      });

      test('returns the same instance when target is unknown', () {
        final original = _minimalSplit();

        expect(original.replace('missing', null), same(original));
      });

      test('drops a null replacement and unwraps to the survivor', () {
        final root = hSplit('root', [
          TabGroupNode(id: 'keep', tabs: treeTabs([tab('a')])),
          TabGroupNode(id: 'drop', tabs: treeTabs([tab('b')])),
        ]);

        final next = root.replace('drop', null);

        expect(next, isA<TabGroupNode>());
        expect((next! as TabGroupNode).id, 'keep');
      });

      test('carries the parent size onto the unwrapped survivor', () {
        final outer = SplitNode(
          id: 'outer',
          axis: .horizontal,
          size: const .fixed(.pixel(200)),
          children: [
            TabGroupNode(id: 'keep', tabs: treeTabs([tab('a')])),
            TabGroupNode(id: 'drop', tabs: treeTabs([tab('b')])),
          ],
        );

        final next = outer.replace('drop', null)! as TabGroupNode;

        expect(next.id, 'keep');
        expect(next.size, const PlatSize.fixed(.pixel(200)));
      });

      test('inlines a same-axis resizable SplitNode replacement', () {
        final inner = hSplit('inner', [
          TabGroupNode(id: 'a', tabs: treeTabs([tab('a')])),
          TabGroupNode(id: 'b', tabs: treeTabs([tab('b')])),
        ]);
        final outer = hSplit('outer', [
          TabGroupNode(id: 'left', tabs: treeTabs([tab('left')])),
          inner,
        ]);
        final touched = inner.copyWith(size: const .fixed(.pixel(100)));

        final next = outer.replace('inner', touched)! as SplitNode;

        expect(next.findNode('inner'), isNull);
        expect(next.children, hasLength(3));
      });

      test('keeps a same-axis SplitNode replacement when either side is not '
          'resizable', () {
        final inner = SplitNode(
          id: 'inner',
          axis: .horizontal,
          resizable: false,
          children: [
            TabGroupNode(id: 'a', tabs: treeTabs([tab('a')])),
            TabGroupNode(id: 'b', tabs: treeTabs([tab('b')])),
          ],
        );
        final outer = hSplit('outer', [
          TabGroupNode(id: 'left', tabs: treeTabs([tab('left')])),
          inner,
        ]);
        final touched = inner.copyWith(size: const .fixed(.pixel(100)));

        final next = outer.replace('inner', touched)! as SplitNode;

        expect(next.findNode('inner'), isA<SplitNode>());
      });
    });

    test('toString reports axis and child count', () {
      expect(
        hSplit('root', [
          TabGroupNode(id: 'a', tabs: treeTabs([tab('a')])),
          TabGroupNode(id: 'b', tabs: treeTabs([tab('b')])),
        ]).toString(),
        'SplitNode(root, SplitAxis.horizontal, 2 children)',
      );
    });
  });
}

SplitNode _minimalSplit() => SplitNode(
  id: 's',
  axis: .horizontal,
  children: [
    TabGroupNode(id: 'a', tabs: treeTabs([tab('a')])),
    TabGroupNode(id: 'b', tabs: treeTabs([tab('b')])),
  ],
);
