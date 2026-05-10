import 'package:flutter_test/flutter_test.dart';
import 'package:plat/plat.dart';
import 'package:plat/src/controller/snapshot_builder.dart' show snapshotOf;

import '../../helpers.dart';

void main() {
  group('PlatSnapshot', () {
    group('of(SplitNode)', () {
      test('horizontal SplitNode becomes a SplitSnapshot', () {
        final node = hSplit('row', [
          TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
          TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
        ]);
        final view = snapshotOf(node) as SplitSnapshot;

        expect(view.id, 'row');
        expect(view.children.map((c) => c.id).toList(), ['left', 'right']);
        expect(view.resizable, isTrue);
      });

      test('vertical SplitNode becomes a SplitSnapshot', () {
        final node = SplitNode(
          id: 'column',
          axis: .vertical,
          children: [
            TabGroupNode(id: 'top', tabs: treeTabs([tab('a')])),
            TabGroupNode(id: 'bottom', tabs: treeTabs([tab('b')])),
          ],
        );
        final view = snapshotOf(node) as SplitSnapshot;

        expect(view.children.map((c) => c.id).toList(), ['top', 'bottom']);
      });

      test('carries resizable through', () {
        final node = SplitNode(
          id: 'row',
          axis: .horizontal,
          resizable: false,
          children: [
            TabGroupNode(id: 'a', tabs: treeTabs([tab('a')])),
            TabGroupNode(id: 'b', tabs: treeTabs([tab('b')])),
          ],
        );
        final view = snapshotOf(node) as SplitSnapshot;

        expect(view.resizable, isFalse);
      });
    });

    group('of(TabGroupNode)', () {
      test('non-empty TabGroupNode reports its tabs and active tab', () {
        final node = TabGroupNode(
          id: 'group',
          tabs: [
            treeTab('a'),
            TabNode(
              child: hSplit('workspace', [tab('b'), tab('c')]),
              title: 'workspace',
              pinned: true,
              locked: true,
            ),
            treeTab('preview', preview: true),
          ],
          activeIndex: 1,
        );
        final view = snapshotOf(node) as TabGroupSnapshot;

        expect(view.tabs.map((tab) => tab.id).toList(), [
          'a',
          'workspace',
          'preview',
        ]);
        expect(view.activeIndex, 1);
        expect(view.activeTab?.id, 'workspace');
        expect(view.activeTab?.title, 'workspace');
        expect(view.activeTab?.pinned, isTrue);
        expect(view.activeTab?.locked, isTrue);
        expect(view.activeTab?.preview, isFalse);
        expect(view.tabs[2].preview, isTrue);
        expect(view.activeTab?.child, isA<SplitSnapshot>());
        expect(view.activeLeaf?.id, 'b');
        expect(view.acceptsDrops, isTrue);
      });

      test(
        'empty TabGroupNode reports a zero activeIndex and a null activeTab',
        () {
          final node = TabGroupNode(id: 'group');
          final view = snapshotOf(node) as TabGroupSnapshot;

          expect(view.tabs, isEmpty);
          expect(view.activeIndex, 0);
          expect(view.activeTab, isNull);
        },
      );

      test('side reflects the underlying TabGroupNode', () {
        final node = TabGroupNode(
          id: 'g',
          tabs: treeTabs([tab('a')]),
          side: .bottom,
        );
        final view = snapshotOf(node) as TabGroupSnapshot;
        expect(view.side, TabBarSide.bottom);
      });
    });

    group('of(SlotNode)', () {
      test('wrapped child snapshot appears on the view', () {
        final node = SlotNode(
          id: 'slot',
          persistent: true,
          boundsMaximize: true,
          child: TabGroupNode(id: 'group', tabs: treeTabs([tab('a')])),
        );
        final view = snapshotOf(node) as SlotSnapshot;

        expect(view.child, isA<TabGroupSnapshot>());
        expect(view.child?.id, 'group');
        expect(view.persistent, isTrue);
        expect(view.boundsMaximize, isTrue);
      });

      test('empty SlotNode reports null child', () {
        final node = SlotNode(id: 'slot', persistent: true);
        final view = snapshotOf(node) as SlotSnapshot;
        expect(view.child, isNull);
      });
    });

    group('of(Leaf)', () {
      test('extracts leaf props and focused flag', () {
        final node = tab('a').copyWith(focused: true);
        final view = snapshotOf(node) as LeafSnapshot;

        expect(view.id, 'a');
        expect(view.title, 'a');
        expect(view.focused, isTrue);
      });
    });

    group('equality', () {
      SlotSnapshot slotWith(PlatNode child) =>
          snapshotOf(SlotNode(id: 'slot', persistent: true, child: child))
              as SlotSnapshot;

      test('SlotSnapshot inequality fires when child content differs', () {
        final a = slotWith(
          TabGroupNode(id: 'group', tabs: treeTabs([tab('a')])),
        );
        final b = slotWith(
          TabGroupNode(id: 'group', tabs: treeTabs([tab('different')])),
        );

        expect(a, isNot(equals(b)));
      });

      test('SlotSnapshot inequality fires when the child id differs', () {
        final a = slotWith(
          TabGroupNode(id: 'group-a', tabs: treeTabs([tab('x')])),
        );
        final b = slotWith(
          TabGroupNode(id: 'group-b', tabs: treeTabs([tab('x')])),
        );

        expect(a, isNot(equals(b)));
      });

      SplitSnapshot rowWith(PlatNode firstChild) =>
          snapshotOf(hSplit('row', [firstChild, treeTab('z').child]))
              as SplitSnapshot;

      test('SplitSnapshot inequality fires when child content differs', () {
        final a = rowWith(TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])));
        final b = rowWith(
          TabGroupNode(id: 'left', tabs: treeTabs([tab('different')])),
        );

        expect(a, isNot(equals(b)));
      });

      test('SplitSnapshot inequality fires when a child id differs', () {
        final a = rowWith(
          TabGroupNode(id: 'left-a', tabs: treeTabs([tab('x')])),
        );
        final b = rowWith(
          TabGroupNode(id: 'left-b', tabs: treeTabs([tab('x')])),
        );

        expect(a, isNot(equals(b)));
      });

      test('SplitSnapshot inequality fires when a child size differs', () {
        final a = rowWith(
          TabGroupNode(
            id: 'left',
            size: const .fixed(.pixel(120)),
            tabs: treeTabs([tab('x')]),
          ),
        );
        final b = rowWith(
          TabGroupNode(
            id: 'left',
            size: const .fixed(.pixel(240)),
            tabs: treeTabs([tab('x')]),
          ),
        );

        expect(a, isNot(equals(b)));
      });

      TabSnapshot tabWith(PlatNode child) {
        final tabs =
            snapshotOf(
                  TabGroupNode(
                    id: 'group',
                    tabs: [TabNode(child: child, title: 't')],
                  ),
                )
                as TabGroupSnapshot;
        return tabs.tabs.single;
      }

      test('TabSnapshot inequality fires when child content differs', () {
        final a = tabWith(
          TabGroupNode(id: 'inner', tabs: treeTabs([tab('a')])),
        );
        final b = tabWith(
          TabGroupNode(id: 'inner', tabs: treeTabs([tab('different')])),
        );

        expect(a, isNot(equals(b)));
      });

      test('TabSnapshot inequality fires when the child id differs', () {
        final a = tabWith(
          TabGroupNode(id: 'inner-a', tabs: treeTabs([tab('x')])),
        );
        final b = tabWith(
          TabGroupNode(id: 'inner-b', tabs: treeTabs([tab('x')])),
        );

        expect(a, isNot(equals(b)));
      });

      test('TabSnapshot inequality fires when the focused leaf flips', () {
        final a = tabWith(
          TabGroupNode(
            id: 'inner',
            tabs: treeTabs([tab('x').copyWith(focused: true), tab('y')]),
          ),
        );
        final b = tabWith(
          TabGroupNode(
            id: 'inner',
            tabs: treeTabs([tab('x'), tab('y').copyWith(focused: true)]),
          ),
        );

        expect(a, isNot(equals(b)));
      });
    });

    group('common fields', () {
      test('hidden and maximized flow from the underlying node', () {
        final node = TabGroupNode(
          id: 'group',
          tabs: treeTabs([tab('a')]),
          hidden: true,
          maximized: true,
        );
        final view = snapshotOf(node);

        expect(view.hidden, isTrue);
        expect(view.maximized, isTrue);
      });

      test('size flows through unchanged', () {
        const size = PlatSize.fixed(.pixel(220));
        final node = TabGroupNode(
          id: 'group',
          tabs: treeTabs([tab('a')]),
          size: size,
        );
        expect(snapshotOf(node).size, size);
      });
    });
  });
}
