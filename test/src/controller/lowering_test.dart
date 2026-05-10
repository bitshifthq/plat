import 'package:flutter_test/flutter_test.dart';
import 'package:plat/plat.dart';
import 'package:plat/src/controller/lowering.dart' show lowerPane;

import '../../helpers.dart';

void main() {
  group('lowerPane', () {
    group('structural mapping', () {
      test('PlatSplit with horizontal axis becomes a horizontal SplitNode', () {
        final node = PlatSplit(
          id: 'row',
          axis: .horizontal,
          children: [
            PlatTabGroup([
              tabPaneWith(id: 'a', title: 'a'),
            ], id: generateNodeId()),
            PlatTabGroup([
              tabPaneWith(id: 'b', title: 'b'),
            ], id: generateNodeId()),
          ],
        );

        final lowered = lowerPane(node)! as SplitNode;

        expect(lowered.id, 'row');
        expect(lowered.axis, SplitAxis.horizontal);
        expect(lowered.children, hasLength(2));
      });

      test('PlatSplit with vertical axis becomes a vertical SplitNode', () {
        final node = PlatSplit(
          id: generateNodeId(),
          axis: .vertical,
          children: [
            PlatTabGroup([
              tabPaneWith(id: 'a', title: 'a'),
            ], id: generateNodeId()),
            PlatTabGroup([
              tabPaneWith(id: 'b', title: 'b'),
            ], id: generateNodeId()),
          ],
        );

        final lowered = lowerPane(node)! as SplitNode;

        expect(lowered.axis, SplitAxis.vertical);
      });

      test('PlatTabGroup preserves tabs, activeIndex, acceptsDrops, side', () {
        final node = PlatTabGroup(
          [
            tabPaneWith(id: 'a', title: 'a'),
            const PlatTab(
              title: 'nested',
              pinned: true,
              locked: true,
              child: .row(
                id: 'nested',
                children: [
                  .leaf(id: 'left', title: 'left'),
                  .leaf(id: 'right', title: 'right'),
                ],
              ),
            ),
            tabPaneWith(id: 'c', title: 'c'),
          ],
          id: 'group',
          activeIndex: 2,
          acceptsDrops: false,
          side: .right,
        );

        final lowered = lowerPane(node)! as TabGroupNode;

        expect(lowered.id, 'group');
        expect(lowered.tabs.map((tab) => tab.id), ['a', 'nested', 'c']);
        expect(lowered.activeIndex, 2);
        expect(lowered.acceptsDrops, isFalse);
        expect(lowered.side, TabBarSide.right);
        expect(lowered.tabs[1].title, 'nested');
        expect(lowered.tabs[1].pinned, isTrue);
        expect(lowered.tabs[1].locked, isTrue);
        expect(lowered.tabs[1].preview, isFalse);
        expect(lowered.tabs[1].child, isA<SplitNode>());
      });

      test('PlatTabGroup preserves preview tabs', () {
        final node = PlatTabGroup([
          tabPaneWith(id: 'a', title: 'a'),
          tabPaneWith(id: 'b', title: 'b', preview: true),
        ], id: 'group');

        final lowered = lowerPane(node)! as TabGroupNode;

        expect(lowered.tabs[0].preview, isFalse);
        expect(lowered.tabs[1].preview, isTrue);
      });

      test('throws when a tab group contains more than one preview tab', () {
        final node = PlatTabGroup([
          tabPaneWith(id: 'a', title: 'a', preview: true),
          tabPaneWith(id: 'b', title: 'b', preview: true),
        ], id: 'group');

        expect(() => lowerPane(node), throwsArgumentError);
      });

      test('PlatLeaf lowers to a LeafNode with matching fields', () {
        final lowered =
            lowerPane(
                  const PlatLeaf(
                    id: 'a',
                    title: 'a',
                    data: 'payload',
                    draggable: true,
                  ),
                )!
                as LeafNode;

        expect(lowered.id, 'a');
        expect(lowered.title, 'a');
        expect(lowered.data, 'payload');
        expect(lowered.draggable, isTrue);
      });

      test('PlatLeaf carries its size onto the lowered leaf', () {
        const size = PlatSize.fixed(.pixel(40));

        final lowered =
            lowerPane(const PlatLeaf(id: 'a', size: size))! as LeafNode;

        expect(lowered.size, size);
        expect(lowered.id, 'a');
      });

      test('PlatSlot preserves persistence, boundsMaximize, and child', () {
        final node = PlatSlot(
          id: 'slot',
          persistent: true,
          boundsMaximize: true,
          child: PlatTabGroup([tabPaneWith(id: 'a', title: 'a')], id: 'group'),
        );

        final lowered = lowerPane(node)! as SlotNode;

        expect(lowered.id, 'slot');
        expect(lowered.persistent, isTrue);
        expect(lowered.boundsMaximize, isTrue);
        expect(lowered.child, isA<TabGroupNode>());
      });

      test('PlatSlot with no child lowers to an empty SlotNode stub when '
          'persistent', () {
        const node = PlatSlot(id: 'slot', persistent: true);

        final lowered = lowerPane(node)! as SlotNode;

        expect(lowered.child, isNull);
        expect(lowered.persistent, isTrue);
      });
    });

    group('id and size preservation', () {
      test('every structural id reaches the lowered tree unchanged', () {
        final node = PlatSplit(
          id: 'row',
          axis: .horizontal,
          children: [
            PlatTabGroup([tabPaneWith(id: 'a', title: 'a')], id: 'left'),
            PlatSplit(
              id: 'column',
              axis: .vertical,
              children: [
                PlatTabGroup([tabPaneWith(id: 'b', title: 'b')], id: 'top'),
                PlatSlot(
                  id: 'slot',
                  child: PlatTabGroup([
                    tabPaneWith(id: 'c', title: 'c'),
                  ], id: 'bottom'),
                ),
              ],
            ),
          ],
        );

        final lowered = lowerPane(node)!;

        final ids = _structuralIdsIn(lowered);

        expect(ids, containsAll(_expectedStructuralIds));
      });

      test('size flows through onto the lowered node', () {
        const size = PlatSize.fixed(.pixel(220));
        final node = PlatTabGroup(
          [tabPaneWith(id: 'a', title: 'a')],
          id: generateNodeId(),
          size: size,
        );

        expect(lowerPane(node)!.size, size);
      });

      test('SplitNode resizable flag flows through lowering', () {
        final node = PlatSplit(
          id: generateNodeId(),
          axis: .horizontal,
          resizable: false,
          children: [
            PlatTabGroup([
              tabPaneWith(id: 'a', title: 'a'),
            ], id: generateNodeId()),
            PlatTabGroup([
              tabPaneWith(id: 'b', title: 'b'),
            ], id: generateNodeId()),
          ],
        );

        final lowered = lowerPane(node)! as SplitNode;

        expect(lowered.resizable, isFalse);
      });
    });

    group('id uniqueness', () {
      test('rejects duplicate structural ids', () {
        final layout = PlatSplit(
          id: generateNodeId(),
          axis: .horizontal,
          children: [
            PlatTabGroup([tabPaneWith(id: 'a', title: 'a')], id: 'group'),
            PlatTabGroup([tabPaneWith(id: 'b', title: 'b')], id: 'group'),
          ],
        );

        expect(() => lowerPane(layout), throwsArgumentError);
      });

      test('rejects an id collision between a structural node and a leaf', () {
        final layout = PlatSplit(
          id: generateNodeId(),
          axis: .horizontal,
          children: [
            PlatTabGroup([
              tabPaneWith(id: 'shared', title: 'shared'),
            ], id: generateNodeId()),
            PlatTabGroup([tabPaneWith(id: 'b', title: 'b')], id: 'shared'),
          ],
        );

        expect(() => lowerPane(layout), throwsArgumentError);
      });

      test(
        'rejects duplicate leaf ids across different TabGroupNode groups',
        () {
          final layout = PlatSplit(
            id: generateNodeId(),
            axis: .horizontal,
            children: [
              PlatTabGroup([
                tabPaneWith(id: 'a', title: 'a'),
              ], id: generateNodeId()),
              PlatTabGroup([
                tabPaneWith(id: 'a', title: 'a'),
              ], id: generateNodeId()),
            ],
          );

          expect(() => lowerPane(layout), throwsArgumentError);
        },
      );
    });

    group('cleanup at the boundary', () {
      test('returns null when the entire lowered tree collapses', () {
        final layout = PlatSplit(
          id: generateNodeId(),
          axis: .horizontal,
          children: [
            const PlatTabGroup([], id: 'a'),
            const PlatTabGroup([], id: 'b'),
          ],
        );

        expect(lowerPane(layout), isNull);
      });

      test('inlines a same-axis nested split when spacing matches', () {
        final layout = PlatSplit(
          id: 'outer',
          axis: .horizontal,
          children: [
            PlatTabGroup([tabPaneWith(id: 'l', title: 'l')], id: 'left'),
            PlatSplit(
              id: 'inner',
              axis: .horizontal,
              children: [
                PlatTabGroup([
                  tabPaneWith(id: 'a', title: 'a'),
                ], id: generateNodeId()),
                PlatTabGroup([
                  tabPaneWith(id: 'b', title: 'b'),
                ], id: generateNodeId()),
              ],
            ),
          ],
        );

        final lowered = lowerPane(layout)! as SplitNode;

        expect(lowered.findNode('inner'), isNull);
        expect(lowered.children, hasLength(3));
      });

      test('prunes an empty non-persistent SlotNode', () {
        final layout = PlatSplit(
          id: generateNodeId(),
          axis: .horizontal,
          children: [
            const PlatSlot(id: 'drop'),
            PlatTabGroup([tabPaneWith(id: 'k', title: 'k')], id: 'keep'),
          ],
        );

        final lowered = lowerPane(layout)!;

        expect(lowered, isA<TabGroupNode>());
        expect((lowered as TabGroupNode).id, 'keep');
      });

      test('keeps an empty persistent SlotNode as a stub', () {
        final layout = PlatSplit(
          id: generateNodeId(),
          axis: .horizontal,
          children: [
            const PlatSlot(id: 'keep', persistent: true),
            PlatTabGroup([tabPaneWith(id: 'a', title: 'a')], id: 'side'),
          ],
        );

        final lowered = lowerPane(layout)! as SplitNode;

        expect(lowered.findNode('keep'), isA<SlotNode>());
      });
    });
  });
}

const _expectedStructuralIds = [
  'row',
  'left',
  'column',
  'top',
  'slot',
  'bottom',
];

Set<String> _structuralIdsIn(PlatNode node) {
  return {
    for (final id in _expectedStructuralIds)
      if (node.findNode(id) != null) id,
  };
}
