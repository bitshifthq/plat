import 'package:flutter_test/flutter_test.dart';
import 'package:plat/plat.dart';

import '../../helpers.dart';

void main() {
  group('PlatController', () {
    group('rootId / renderRootId', () {
      test('rootId reflects the live root after a mutation', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        final before = c.rootId;
        c.insertTab(tabGroupId: c.rootId, tab: tabPane('b'));

        expect(c.rootId, before);
      });

      test('renderRootId equals rootId when nothing is maximized', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        expect(c.renderRootId(), c.rootId);
      });

      test('renderRootId collapses to the maximized node by default', () {
        final c = PlatController(
          initialPlat: .row(
            id: generateNodeId(),
            children: [
              .tabs([tabPane('a')], id: 'left'),
              .tabs([tabPane('b')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);

        c.setMaximized('right', maximized: true);

        expect(c.renderRootId(), 'right');
      });

      test('renderRootId stops at the innermost boundsMaximize SlotNode', () {
        final c = PlatController(
          initialPlat: .row(
            id: generateNodeId(),
            children: [
              .slot(
                id: 'slot',
                boundsMaximize: true,
                child: .tabs([tabPane('a')], id: 'inside'),
              ),
              .tabs([tabPane('peer')], id: 'outside'),
            ],
          ),
        );
        addTearDown(c.dispose);

        c.setMaximized('inside', maximized: true);

        expect(c.renderRootId(), 'slot');
      });

      test('renderRootId without an enclosing SlotNode renders the maximized '
          'node alone', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);

        c.setMaximized('a', maximized: true);

        expect(c.renderRootId(), 'a');
      });

      test('innermost boundsMaximize SlotNode wins when nested', () {
        final c = controllerFromTree(
          SlotNode(
            id: 'outer-scope',
            persistent: true,
            boundsMaximize: true,
            child: SlotNode(
              id: 'inner-scope',
              persistent: true,
              boundsMaximize: true,
              child: TabGroupNode(id: 't', tabs: treeTabs([tab('a')])),
            ),
          ),
        );
        addTearDown(c.dispose);

        c.setMaximized('a', maximized: true);

        expect(
          (c.snapshot(c.renderRootId())! as SlotSnapshot).id,
          'inner-scope',
        );
      });
    });

    group('view', () {
      test('new naming API exposes tab group snapshots and parameters', () {
        final c = PlatController(
          initialPlat: .tabs([tabPaneWith(id: 'a', title: 'a')], id: 'group'),
        );
        addTearDown(c.dispose);

        final inserted = c.insertTab(
          tabGroupId: 'group',
          tab: tabPaneWith(id: 'b', title: 'b'),
        );
        c.setTabBarSide('group', .bottom);

        final snapshot = c.snapshot('group')! as TabGroupSnapshot;
        expect(inserted, isTrue);
        expect(snapshot.tabs.map((tab) => tab.id), ['a', 'b']);
        expect(snapshot.side, TabBarSide.bottom);
        expect(c.tabGroupContaining('b'), 'group');
      });

      test('returns a typed snapshot for an existing node', () {
        final c = PlatController(
          initialPlat: .tabs(
            [tabPane('a'), tabPane('b')],
            id: 'group',
            activeIndex: 1,
          ),
        );
        addTearDown(c.dispose);

        final snapshot = c.snapshot('group')! as TabGroupSnapshot;

        expect(snapshot.tabs.map((l) => l.id).toList(), ['a', 'b']);
        expect(snapshot.activeIndex, 1);
      });

      test('returns null for unknown ids', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        expect(c.snapshot('missing'), isNull);
      });
    });

    group('childrenOf', () {
      test('returns split child ids in order', () {
        final c = PlatController(
          initialPlat: .row(
            id: 'row',
            children: [
              .tabs([tabPane('a')], id: 'left'),
              .tabs([tabPane('b')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);

        expect(_childrenIdsOf(c, 'row'), ['left', 'right']);
        expect(_childrenIdsOf(c, 'left'), isEmpty);
        expect(_childrenIdsOf(c, 'missing'), isEmpty);
      });

      test('returns the wrapped node id for a non-empty SlotNode', () {
        final c = PlatController(
          initialPlat: .slot(
            id: 'slot',
            persistent: true,
            child: .tabs([tabPane('a')], id: 'group'),
          ),
        );
        addTearDown(c.dispose);

        expect(_childrenIdsOf(c, 'slot'), ['group']);
      });
    });

    group('leavesIn', () {
      test('yields every leaf below the node in tree order', () {
        final c = PlatController(
          initialPlat: .row(
            id: 'row',
            children: [
              .tabs([tabPane('a'), tabPane('b')], id: 'left'),
              .tabs([tabPane('c')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);

        expect(_leavesIn(c, 'row'), ['a', 'b', 'c']);
        expect(_leavesIn(c, 'left'), ['a', 'b']);
      });
    });

    group('parentOf', () {
      test(
        'walks up one level, returns null at the root and for unknown ids',
        () {
          final c = PlatController(
            initialPlat: .row(
              id: 'row',
              children: [
                .tabs([tabPane('a')], id: 'left'),
                .tabs([tabPane('b')], id: 'right'),
              ],
            ),
          );
          addTearDown(c.dispose);

          expect(c.parentOf('left'), 'row');
          expect(c.parentOf('row'), isNull);
          expect(c.parentOf('missing'), isNull);
        },
      );
    });

    group('pathTo', () {
      test('returns root-to-id ids inclusive', () {
        final c = PlatController(
          initialPlat: .row(
            id: 'row',
            children: [
              .slot(
                id: 'slot',
                child: .tabs([tabPane('a')], id: 'group'),
              ),
              .tabs([tabPane('b')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);

        expect(c.pathTo('a'), ['row', 'slot', 'group', 'a']);
        expect(c.pathTo('missing'), isEmpty);
      });
    });

    group('tabGroupContaining', () {
      test(
        'returns the enclosing TabGroupNode id for a leaf, null otherwise',
        () {
          final c = PlatController(
            initialPlat: .tabs([tabPane('a')], id: 'group'),
          );
          addTearDown(c.dispose);

          expect(c.tabGroupContaining('a'), 'group');
          expect(c.tabGroupContaining('missing'), isNull);
        },
      );
    });

    group('leafIds and tabGroupIds', () {
      test('expose every leaf and tab group id in tree order', () {
        final c = PlatController(
          initialPlat: .row(
            id: generateNodeId(),
            children: [
              .tabs([tabPane('a'), tabPane('b')], id: 'left'),
              .tabs([tabPane('c')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);

        expect(c.leafIds.toList(), ['a', 'b', 'c']);
        expect(c.tabGroupIds.toList(), ['left', 'right']);
      });
    });

    group('isHidden / isMaximized', () {
      test('reflects hidden and maximized flags after updates', () {
        final c = PlatController(
          initialPlat: .row(
            id: generateNodeId(),
            children: [
              .tabs([tabPane('a')], id: 'left'),
              .tabs([tabPane('b')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);

        expect(c.snapshot('left')?.hidden ?? false, isFalse);
        expect(c.maximizedId() == 'left', isFalse);

        c.setHidden('left', hidden: true);
        c.setMaximized('right', maximized: true);

        expect(c.snapshot('left')?.hidden ?? false, isTrue);
        expect(c.maximizedId() == 'right', isTrue);
      });

      test('return false for unknown ids', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        expect(c.snapshot('missing')?.hidden ?? false, isFalse);
        expect(c.maximizedId() == 'missing', isFalse);
      });
    });

    group('leaf', () {
      test('returns the payload for a leaf id, null otherwise', () {
        final c = PlatController(
          initialPlat: .tabs([tabPane('a')], id: 'group'),
        );
        addTearDown(c.dispose);

        expect(_leafSnapshot(c, 'a')?.id, 'a');
        expect(_leafSnapshot(c, 'a')?.title, 'a');
        expect(_leafSnapshot(c, 'group'), isNull);
        expect(_leafSnapshot(c, 'missing'), isNull);
      });
    });

    group('sizeOf', () {
      test('reports each node sizing slot', () {
        const fixed = PlatSize.fixed(.pixel(220));
        final c = PlatController(
          initialPlat: .row(
            id: generateNodeId(),
            children: [
              .tabs([tabPane('a')], id: 'left', size: fixed),
              .tabs([tabPane('b')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);

        expect(c.snapshot('left')?.size, fixed);
        expect(c.snapshot('right')?.size, const PlatSize.auto());
        expect(c.snapshot('missing')?.size, isNull);
      });
    });

    group('insertTab', () {
      test('an empty controller exposes an empty TabGroupNode root', () {
        final c = PlatController();
        addTearDown(c.dispose);

        expect(c.snapshot(c.rootId), isA<TabGroupSnapshot>());
        expect((c.snapshot(c.rootId)! as TabGroupSnapshot).tabs, isEmpty);
      });

      test('generates ids for public layouts that omit them', () {
        final c = PlatController(initialPlat: .tabs([tabPaneWith(title: 'a')]));
        addTearDown(c.dispose);

        final root = c.root as TabGroupSnapshot;

        expect(root.id, startsWith('p_'));
        expect(root.tabs.single.id, startsWith('p_'));
        expect(root.tabs.single.id, isNot(root.id));
      });

      test('activates the inserted tab by default', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        c.insertTab(tabGroupId: c.rootId, tab: tabPane('b'));

        expect((c.snapshot(c.rootId)! as TabGroupSnapshot).activeIndex, 1);
        expect(c.focusedLeaf?.id, 'b');
      });

      test('rejects an inserted tab whose ids already exist by default', () {
        final c = PlatController(
          initialPlat: .tabs([tabPane('a'), tabPane('b')], id: 'group'),
        );
        addTearDown(c.dispose);

        final changed = c.insertTab(tabGroupId: c.rootId, tab: tabPane('b'));

        expect(changed, isFalse);
        expect(
          (c.snapshot(c.rootId)! as TabGroupSnapshot).tabs.map((t) => t.id),
          ['a', 'b'],
        );
      });

      test(
        'replace conflict policy removes existing conflicts before insert',
        () {
          final c = PlatController(
            idConflict: .replace,
            initialPlat: .row(
              id: 'root',
              children: [
                .tabs([tabPane('a')], id: 'left'),
                .tabs([tabPane('b')], id: 'right'),
              ],
            ),
          );
          addTearDown(c.dispose);

          final changed = c.insertTab(tabGroupId: 'left', tab: tabPane('b'));

          expect(changed, isTrue);
          expect(c.tabGroupContaining('b'), 'left');
          expect(c.snapshot('right'), isNull);
        },
      );

      test(
        'replace conflict policy can replace the only tab in target group',
        () {
          final c = PlatController(
            idConflict: .replace,
            initialPlat: .tabs([
              tabPaneWith(id: 'b', title: 'old'),
            ], id: 'group'),
          );
          addTearDown(c.dispose);

          final changed = c.insertTab(
            tabGroupId: 'group',
            tab: tabPaneWith(id: 'b', title: 'new'),
          );

          expect(changed, isTrue);
          final tabs = c.snapshot('group')! as TabGroupSnapshot;
          expect(tabs.tabs, hasLength(1));
          expect(tabs.tabs.single.title, 'new');
        },
      );
    });

    group('insertTabIntoSlot', () {
      test('seeds an empty persistent SlotNode with a TabGroupNode child', () {
        final c = controllerFromTree(SlotNode(id: 's', persistent: true));
        addTearDown(c.dispose);

        final changed = c.insertTabIntoSlot(slotId: 's', tab: tabPane('a'));

        expect(changed, isTrue);
        final s = c.snapshot(c.rootId)! as SlotSnapshot;
        expect(s.persistent, isTrue);
        expect((s.child! as TabGroupSnapshot).tabs.single.id, 'a');
      });

      test('reseeds a persistent SlotNode whose child has collapsed', () {
        final c = controllerFromTree(
          SlotNode(
            id: 'main',
            persistent: true,
            child: TabGroupNode(id: 'inner', tabs: treeTabs([tab('a')])),
          ),
        );
        addTearDown(c.dispose);
        c.close('a');
        expect((c.snapshot(c.rootId)! as SlotSnapshot).child, isNull);

        c.insertTabIntoSlot(slotId: 'main', tab: tabPane('b'));

        final s = c.snapshot(c.rootId)! as SlotSnapshot;
        expect(s.id, 'main');
        expect((s.child! as TabGroupSnapshot).tabs.single.id, 'b');
      });

      test('returns false when the slot is not empty', () {
        final c = controllerFromTree(
          SlotNode(
            id: 'main',
            persistent: true,
            child: TabGroupNode(id: 'inner', tabs: treeTabs([tab('a')])),
          ),
        );
        addTearDown(c.dispose);

        final changed = c.insertTabIntoSlot(slotId: 'main', tab: tabPane('b'));

        expect(changed, isFalse);
      });
    });

    group('insertSplitChild', () {
      test('inserts a child into a split at the requested index', () {
        final c = PlatController(
          initialPlat: .row(
            id: 'root',
            children: [
              .tabs([tabPane('a')], id: 'left'),
              .tabs([tabPane('b')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);

        c.insertSplitChild(
          splitId: 'root',
          child: .tabs([tabPane('mid')], id: 'mid-group'),
          index: 1,
        );

        expect(
          (c.snapshot(c.rootId)! as SplitSnapshot).children.map(
            (child) => child.id,
          ),
          ['left', 'mid-group', 'right'],
        );
      });
    });

    group('setSlotChild', () {
      test('sets and clears the slot child', () {
        final c = controllerFromTree(SlotNode(id: 'slot', persistent: true));
        addTearDown(c.dispose);

        final set = c.setSlotChild(
          slotId: 'slot',
          child: .tabs([tabPane('a')], id: 'group'),
        );

        expect(set, isTrue);
        expect((c.snapshot(c.rootId)! as SlotSnapshot).child?.id, 'group');

        final cleared = c.setSlotChild(slotId: 'slot');

        expect(cleared, isTrue);
        expect((c.snapshot(c.rootId)! as SlotSnapshot).child, isNull);
      });

      test('returns false for an unknown slot id', () {
        final c = controllerFromTree(SlotNode(id: 'slot', persistent: true));
        addTearDown(c.dispose);

        final changed = c.setSlotChild(
          slotId: 'missing',
          child: .tabs([tabPane('a')], id: 'group'),
        );

        expect(changed, isFalse);
      });

      test('returns false for a non-slot id', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        final changed = c.setSlotChild(
          slotId: c.rootId,
          child: .tabs([tabPane('b')], id: 'group'),
        );

        expect(changed, isFalse);
      });
    });

    group('close', () {
      test('returns true when it closes a leaf', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);

        final changed = c.close('a');

        expect(changed, isTrue);
      });

      test('a Leaf id closes that leaf', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);

        c.close('a');

        expect(c.leafIds.contains('a'), isFalse);
        expect(c.leafIds.contains('b'), isTrue);
      });

      test('no-ops on a locked leaf', () {
        final c = controllerFromLeaves([tab('a', locked: true)]);
        addTearDown(c.dispose);

        c.close('a');

        expect((c.snapshot(c.rootId)! as TabGroupSnapshot).tabs, hasLength(1));
      });

      test('returns false on a locked leaf', () {
        final c = controllerFromLeaves([tab('a', locked: true)]);
        addTearDown(c.dispose);

        final changed = c.close('a');

        expect(changed, isFalse);
      });

      test('returns false for an unknown id', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        final changed = c.close('missing');

        expect(changed, isFalse);
      });

      test('closing the last leaf leaves an empty stub root', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        c.close('a');

        expect(c.snapshot(c.rootId), isA<TabGroupSnapshot>());
        expect((c.snapshot(c.rootId)! as TabGroupSnapshot).tabs, isEmpty);
      });

      test('a TabGroupNode id closes the whole group', () {
        final c = PlatController(
          initialPlat: .row(
            id: generateNodeId(),
            children: [
              .tabs([tabPane('a')], id: 'left'),
              .tabs([tabPane('b')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);

        c.close('left');

        expect(c.snapshot('left'), isNull);
        expect(c.leafIds.toList(), ['b']);
      });

      test('partial-locked TabGroupNode keeps locked leaves', () {
        final c = controllerFromLeaves([tab('a', locked: true), tab('b')]);
        addTearDown(c.dispose);

        c.close(c.rootId);

        expect(
          (c.snapshot(c.rootId)! as TabGroupSnapshot).tabs.map((p) => p.id),
          ['a'],
        );
      });

      test('all-locked TabGroupNode is a no-op', () {
        final c = controllerFromLeaves([
          tab('a', locked: true),
          tab('b', locked: true),
        ]);
        addTearDown(c.dispose);

        c.close(c.rootId);

        expect((c.snapshot(c.rootId)! as TabGroupSnapshot).tabs, hasLength(2));
      });
    });

    group('remove', () {
      test('removes a locked tab structurally', () {
        final c = controllerFromLeaves([tab('a', locked: true), tab('b')]);
        addTearDown(c.dispose);

        final changed = c.remove('a');

        expect(changed, isTrue);
        expect(c.leafIds.toList(), ['b']);
      });
    });

    group('split / moveTab', () {
      test('split returns true when it inserts a sibling group', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);

        final changed = c.split(
          targetId: c.rootId,
          side: .right,
          sibling: .tabs([tabPane('c')], id: 'right-group'),
        );

        expect(changed, isTrue);
      });

      test('split inserts the sibling beside the target', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);
        final targetId = c.rootId;

        c.split(
          targetId: targetId,
          side: .right,
          sibling: .tabs([tabPane('c')], id: 'right-group'),
        );

        final s = c.snapshot(c.rootId)! as SplitSnapshot;
        expect((s.children[0] as TabGroupSnapshot).id, targetId);
        expect((s.children[1] as TabGroupSnapshot).id, 'right-group');
      });

      test('split inlines into an existing same-axis split', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);

        c.split(
          targetId: c.rootId,
          side: .right,
          sibling: .tabs([tabPane('c')], id: 'group-c'),
        );
        final s = c.snapshot(c.rootId)! as SplitSnapshot;
        c.split(
          targetId: (s.children.last as TabGroupSnapshot).id,
          side: .right,
          sibling: .tabs([tabPane('d')], id: 'group-d'),
        );

        expect((c.snapshot(c.rootId)! as SplitSnapshot).children, hasLength(3));
      });

      test('split returns false for an unknown target id', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        final changed = c.split(
          targetId: 'missing',
          side: .right,
          sibling: .tabs([tabPane('b')], id: 'right-group'),
        );

        expect(changed, isFalse);
      });

      test(
        'split returns false when the sibling collapses to an empty tree',
        () {
          final c = controllerFromLeaves([tab('a')]);
          addTearDown(c.dispose);

          final changed = c.split(
            targetId: c.rootId,
            side: .right,
            sibling: const .slot(id: 'empty'),
          );

          expect(changed, isFalse);
        },
      );

      test('moveTab returns true when it relocates a tab', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);
        c.focus('b');
        c.splitActiveTab(tabGroupId: c.rootId, side: .right);
        final left =
            (c.snapshot(c.rootId)! as SplitSnapshot).children.first
                as TabGroupSnapshot;

        final changed = c.moveTab(tabId: 'b', tabGroupId: left.id);

        expect(changed, isTrue);
      });

      test('moveTab removes from source and inserts at destination', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);
        c.focus('b');
        c.splitActiveTab(tabGroupId: c.rootId, side: .right);
        final left =
            (c.snapshot(c.rootId)! as SplitSnapshot).children.first
                as TabGroupSnapshot;
        final right =
            (c.snapshot(c.rootId)! as SplitSnapshot).children.last
                as TabGroupSnapshot;

        c.moveTab(tabId: 'b', tabGroupId: left.id);

        expect(c.snapshot(c.rootId), isA<TabGroupSnapshot>());
        expect(c.snapshot(right.id), isNull);
        expect(
          (c.snapshot(c.rootId)! as TabGroupSnapshot).tabs.map((p) => p.id),
          ['a', 'b'],
        );
      });

      test('moveTab activates a same-group no-op move', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);

        final changed = c.moveTab(tabId: 'b', tabGroupId: c.rootId, index: 1);

        expect(changed, isTrue);
        expect(c.focusedLeaf?.id, 'b');
      });

      test('moveTab returns false when the destination is not tabs', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);
        c.focus('b');
        c.splitActiveTab(tabGroupId: c.rootId, side: .right);

        final changed = c.moveTab(tabId: 'b', tabGroupId: c.rootId);

        expect(changed, isFalse);
      });
    });

    group('focus', () {
      test('returns true when it changes the focused leaf', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);

        final changed = c.focus('b');

        expect(changed, isTrue);
      });

      test('a Leaf id focuses it directly', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);

        c.focus('b');

        expect(c.focusedLeaf?.id, 'b');
      });

      test('a TabGroupNode id focuses its active leaf', () {
        final c = PlatController(
          initialPlat: .row(
            id: generateNodeId(),
            children: [
              .tabs([tabPane('a'), tabPane('b')], id: 'left'),
              .tabs([tabPane('c')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);

        c.focus('right');

        expect(c.focusedLeaf?.id, 'c');
      });

      test('sets Leaf.focused on the target and clears every other', () {
        final c = controllerFromLeaves([tab('a'), tab('b'), tab('c')]);
        addTearDown(c.dispose);

        c.focus('b');

        final t = c.snapshot(c.rootId)! as TabGroupSnapshot;
        expect(_focusedTabIds(t), ['b']);
      });

      test('focus on a Leaf also activates it within its TabGroupNode', () {
        final c = controllerFromLeaves([tab('a'), tab('b'), tab('c')]);
        addTearDown(c.dispose);

        c.focus('c');

        expect((c.snapshot(c.rootId)! as TabGroupSnapshot).activeIndex, 2);
        expect((c.snapshot(c.rootId)! as TabGroupSnapshot).activeLeaf?.id, 'c');
      });

      test('an empty target TabGroupNode is a no-op', () {
        final c = controllerFromTree(
          SlotNode(
            id: 'main',
            persistent: true,
            child: TabGroupNode(id: 'inner', tabs: treeTabs([tab('a')])),
          ),
        );
        addTearDown(c.dispose);
        c.focus('a');
        c.close('a');

        c.focus('main');

        expect(c.focusedLeaf, isNull);
      });

      test(
        'focused flag travels with a Leaf across moves to a new sibling',
        () {
          final c = controllerFromLeaves([tab('a'), tab('b')]);
          addTearDown(c.dispose);
          c.focus('b');

          c.moveTabBeside(tabId: 'b', targetId: c.rootId, side: .right);

          final right =
              (c.snapshot(c.rootId)! as SplitSnapshot).children.last
                  as TabGroupSnapshot;
          expect(right.tabs.single.focused, isTrue);
          expect(c.focusedLeaf?.id, 'b');
        },
      );

      test('returns false when the target leaf is already focused', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);
        c.focus('b');

        final changed = c.focus('b');

        expect(changed, isFalse);
      });

      test('returns false when the target tab group is empty', () {
        final c = controllerFromTree(
          SlotNode(
            id: 'main',
            persistent: true,
            child: TabGroupNode(id: 'inner', tabs: treeTabs([tab('a')])),
          ),
        );
        addTearDown(c.dispose);
        c.focus('a');
        c.close('a');

        final changed = c.focus('main');

        expect(changed, isFalse);
      });
    });

    group('focusedTabGroupId', () {
      test('resolves through the focused leaf', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);
        c.focus('b');
        c.splitActiveTab(tabGroupId: c.rootId, side: .right);
        final right =
            (c.snapshot(c.rootId)! as SplitSnapshot).children.last
                as TabGroupSnapshot;

        c.focus('b');

        expect(c.focusedTabGroupId(), right.id);
      });

      test('falls back to the first tab group when nothing is focused', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        expect(c.focusedTabGroupId(), c.rootId);
      });
    });

    group('refocus on close', () {
      test('prefers the most-recently focused leaf', () {
        final c = controllerFromLeaves([tab('a'), tab('b'), tab('c')]);
        addTearDown(c.dispose);
        c.focus('a');
        c.focus('b');
        c.focus('c');

        c.close('c');

        expect(c.focusedLeaf?.id, 'b');
      });

      test('falls back to the next-active leaf in the same TabGroupNode', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);
        c.focus('b');

        c.close('b');

        expect(c.focusedLeaf?.id, 'a');
      });

      test(
        'falls back to the first tab group when origin TabGroupNode prunes',
        () {
          final c = controllerFromLeaves([tab('a'), tab('b')]);
          addTearDown(c.dispose);
          c.focus('b');
          c.splitActiveTab(tabGroupId: c.rootId, side: .right);
          final right =
              (c.snapshot(c.rootId)! as SplitSnapshot).children.last
                  as TabGroupSnapshot;
          c.focus(right.tabs.single.id);

          c.close(right.tabs.single.id);

          expect(c.focusedLeaf?.id, 'a');
        },
      );

      test('closing the last leaf leaves focus null', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);
        c.focus('a');

        c.close('a');

        expect(c.focusedLeaf, isNull);
      });

      test('closing a non-focused leaf does not change focus', () {
        final c = controllerFromLeaves([tab('a'), tab('b'), tab('c')]);
        addTearDown(c.dispose);
        c.focus('a');

        c.close('c');

        expect(c.focusedLeaf?.id, 'a');
      });
    });

    group('recentLeaves', () {
      test('filters out leaves no longer in the tree', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);
        c.focus('a');
        c.focus('b');

        c.close('a');

        expect(c.recentLeafIds, isNot(contains('a')));
      });
    });

    group('setMaximized', () {
      test('maximize returns true when it changes the maximized node', () {
        final c = PlatController(
          initialPlat: .row(
            id: generateNodeId(),
            children: [
              .tabs([tabPane('a')], id: 'left'),
              .tabs([tabPane('b')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);

        final changed = c.setMaximized('right', maximized: true);

        expect(changed, isTrue);
      });

      test('maximize sets the flag', () {
        final c = PlatController(
          initialPlat: .row(
            id: generateNodeId(),
            children: [
              .tabs([tabPane('a')], id: 'left'),
              .tabs([tabPane('b')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);

        c.setMaximized('right', maximized: true);

        expect(_maximizedPane(c)?.id, 'right');
      });

      test('maximize returns false when the node is already maximized', () {
        final c = PlatController(
          initialPlat: .row(
            id: generateNodeId(),
            children: [
              .tabs([tabPane('a')], id: 'left'),
              .tabs([tabPane('b')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);
        c.setMaximized('right', maximized: true);

        final changed = c.setMaximized('right', maximized: true);

        expect(changed, isFalse);
      });

      test('maximize clears any previously maximized node', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);
        c.focus('b');
        c.splitActiveTab(tabGroupId: c.rootId, side: .right);
        final left =
            (c.snapshot(c.rootId)! as SplitSnapshot).children.first
                as TabGroupSnapshot;
        final right =
            (c.snapshot(c.rootId)! as SplitSnapshot).children.last
                as TabGroupSnapshot;

        c.setMaximized(left.id, maximized: true);
        expect(_maximizedPane(c)?.id, left.id);

        c.setMaximized(right.id, maximized: true);
        expect(_maximizedPane(c)?.id, right.id);
      });

      test('maximize is auto-cleared when the maximized node is removed', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);
        c.focus('b');
        c.splitActiveTab(tabGroupId: c.rootId, side: .right);
        final right =
            (c.snapshot(c.rootId)! as SplitSnapshot).children.last
                as TabGroupSnapshot;
        c.setMaximized(right.id, maximized: true);

        c.close(right.id);

        expect(_maximizedPane(c), isNull);
      });

      test('clearing the maximized node returns true and removes the flag', () {
        final c = PlatController(
          initialPlat: .row(
            id: generateNodeId(),
            children: [
              .tabs([tabPane('a')], id: 'left'),
              .tabs([tabPane('b')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);
        c.setMaximized('left', maximized: true);

        final changed = c.setMaximized('left', maximized: false);

        expect(changed, isTrue);
        expect(_maximizedPane(c), isNull);
      });

      test('clearing a node returns false when nothing is maximized', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        final changed = c.setMaximized(c.rootId, maximized: false);

        expect(changed, isFalse);
      });

      test('clearing a different node leaves the maximized node unchanged', () {
        final c = PlatController(
          initialPlat: .row(
            id: generateNodeId(),
            children: [
              .tabs([tabPane('a')], id: 'left'),
              .tabs([tabPane('b')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);
        c.setMaximized('left', maximized: true);

        final changed = c.setMaximized('right', maximized: false);

        expect(changed, isFalse);
        expect(_maximizedPane(c)?.id, 'left');
      });

      test('maximizing an unknown id returns false', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        final changed = c.setMaximized('missing', maximized: true);

        expect(changed, isFalse);
      });

      test('focus and maximize changes are not pushed to undo', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);
        expect(c.canUndo, isFalse);

        c.focus('b');
        c.setMaximized(c.rootId, maximized: true);

        expect(c.canUndo, isFalse);
      });
    });

    group('pin / lock', () {
      test('pin returns true when it changes the flag', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        final changed = c.setPinned('a', pinned: true);

        expect(changed, isTrue);
      });

      test('pin writes the tab flag', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        c.setPinned('a', pinned: true);

        expect(_tabSnapshot(c, 'a')!.pinned, isTrue);
      });

      test('pin returns false when the tab is already pinned', () {
        final c = PlatController(
          initialPlat: .tabs([tabPane('a', pinned: true)]),
        );
        addTearDown(c.dispose);

        final changed = c.setPinned('a', pinned: true);

        expect(changed, isFalse);
      });

      test('unpin returns true when it clears the flag', () {
        final c = PlatController(
          initialPlat: .tabs([tabPane('a', pinned: true)]),
        );
        addTearDown(c.dispose);

        final changed = c.setPinned('a', pinned: false);

        expect(changed, isTrue);
      });

      test('unpin returns false when the leaf is already unpinned', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        final changed = c.setPinned('a', pinned: false);

        expect(changed, isFalse);
      });

      test('lock returns true when it changes the flag', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        final changed = c.setLocked('a', locked: true);

        expect(changed, isTrue);
      });

      test('lock writes the leaf flag', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        c.setLocked('a', locked: true);

        expect(_leafSnapshot(c, 'a')!.locked, isTrue);
      });

      test('lock returns false when the leaf is already locked', () {
        final c = controllerFromLeaves([tab('a', locked: true)]);
        addTearDown(c.dispose);

        final changed = c.setLocked('a', locked: true);

        expect(changed, isFalse);
      });

      test('unlock returns true when it clears the flag', () {
        final c = controllerFromLeaves([tab('a', locked: true)]);
        addTearDown(c.dispose);

        final changed = c.setLocked('a', locked: false);

        expect(changed, isTrue);
      });

      test('unlock returns false when the leaf is already unlocked', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        final changed = c.setLocked('a', locked: false);

        expect(changed, isFalse);
      });

      test('preview returns true when it changes the flag', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        final changed = c.setPreview('a', preview: true);

        expect(changed, isTrue);
      });

      test('preview removes an existing sibling preview', () {
        final c = PlatController(
          initialPlat: .tabs([
            tabPane('preview', preview: true),
            tabPane('b'),
            tabPane('c'),
          ], id: 'group'),
        );
        addTearDown(c.dispose);

        c.setPreview('c', preview: true);

        final group = c.snapshot('group')! as TabGroupSnapshot;
        expect(group.tabs.map((tab) => tab.id).toList(), ['b', 'c']);
        expect(_previewTabIds(group), ['c']);
        expect(group.tabs.last.preview, isTrue);
      });

      test('unpreview returns true when it clears the flag', () {
        final c = PlatController(
          initialPlat: .tabs([tabPane('preview', preview: true)], id: 'group'),
        );
        addTearDown(c.dispose);

        final changed = c.setPreview('preview', preview: false);

        expect(changed, isTrue);
        final group = c.snapshot('group')! as TabGroupSnapshot;
        expect(group.tabs.single.preview, isFalse);
      });
    });

    group('hide / show', () {
      test('hide returns true when it hides a visible node', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);

        final changed = c.setHidden(c.rootId, hidden: true);

        expect(changed, isTrue);
      });

      test('hide returns false when the node is already hidden', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);
        c.setHidden(c.rootId, hidden: true);

        final changed = c.setHidden(c.rootId, hidden: true);

        expect(changed, isFalse);
      });

      test('show returns true when it reveals a hidden node', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);
        c.setHidden(c.rootId, hidden: true);

        final changed = c.setHidden(c.rootId, hidden: false);

        expect(changed, isTrue);
      });

      test('show no-ops when the node is already visible', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);
        var notifies = 0;
        c.addListener(() => notifies++);

        c.setHidden('a', hidden: false);

        expect(notifies, 0);
      });

      test('show returns false when the node is already visible', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);

        final changed = c.setHidden(c.rootId, hidden: false);

        expect(changed, isFalse);
      });

      test('hide returns true for an existing node', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);

        final changed = c.setHidden(c.rootId, hidden: true);

        expect(changed, isTrue);
      });

      test('hide returns false for an unknown node', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        final changed = c.setHidden('missing', hidden: true);

        expect(changed, isFalse);
      });
    });

    group('setSize / resize', () {
      test('setSize returns true when it changes a node size', () {
        final c = PlatController(
          initialPlat: .row(
            id: generateNodeId(),
            children: [
              .tabs([tabPane('a')], id: 'left'),
              .tabs([tabPane('b')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);
        const target = PlatSize.fixed(.pixel(180));

        final changed = c.setSize('left', target);

        expect(changed, isTrue);
      });

      test('setSize updates one node', () {
        final c = PlatController(
          initialPlat: .row(
            id: generateNodeId(),
            children: [
              .tabs([tabPane('a')], id: 'left'),
              .tabs([tabPane('b')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);
        const target = PlatSize.fixed(.pixel(180));

        c.setSize('left', target);

        expect(c.snapshot('left')?.size, target);
      });

      test('setSize returns false when the size is unchanged', () {
        final c = PlatController(
          initialPlat: .row(
            id: 'row',
            children: [
              .tabs(
                [tabPane('a')],
                id: 'left',
                size: const .fixed(.pixel(180)),
              ),
              .tabs([tabPane('b')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);

        final changed = c.setSize('left', const .fixed(.pixel(180)));

        expect(changed, isFalse);
      });

      test('setSize notifies once per call', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);
        c.focus('b');
        c.splitActiveTab(tabGroupId: c.rootId, side: .right);
        final right =
            (c.snapshot(c.rootId)! as SplitSnapshot).children.last
                as TabGroupSnapshot;
        var notifies = 0;
        c.addListener(() => notifies++);

        c.setSize(right.id, const .fixed(.pixel(240)));

        expect(notifies, 1);
      });

      test('resize updates split children positionally', () {
        final c = PlatController(
          initialPlat: .row(
            id: 'row',
            children: [
              .tabs([tabPane('a')], id: 'left'),
              .tabs([tabPane('b')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);
        const left = PlatSize.resizable(initial: .fraction(0.3));
        const right = PlatSize.resizable(initial: .fraction(0.7));

        c.resizeSplit('row', const [left, right]);

        expect(c.snapshot('left')?.size, left);
        expect(c.snapshot('right')?.size, right);
      });

      test('resize returns true when split child sizes change', () {
        final c = PlatController(
          initialPlat: .row(
            id: 'row',
            children: [
              .tabs([tabPane('a')], id: 'left'),
              .tabs([tabPane('b')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);
        const left = PlatSize.resizable(initial: .fraction(0.3));
        const right = PlatSize.resizable(initial: .fraction(0.7));

        final changed = c.resizeSplit('row', const [left, right]);

        expect(changed, isTrue);
      });

      test('resize returns false when split child sizes are unchanged', () {
        final c = PlatController(
          initialPlat: .row(
            id: 'row',
            children: [
              .tabs(
                [tabPane('a')],
                id: 'left',
                size: const .fixed(.pixel(180)),
              ),
              .tabs(
                [tabPane('b')],
                id: 'right',
                size: const .fixed(.pixel(220)),
              ),
            ],
          ),
        );
        addTearDown(c.dispose);

        final changed = c.resizeSplit('row', const [
          .fixed(.pixel(180)),
          .fixed(.pixel(220)),
        ]);

        expect(changed, isFalse);
      });

      test('resize returns false for a non-split id', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        final changed = c.resizeSplit(c.rootId, const [.fixed(.pixel(180))]);

        expect(changed, isFalse);
      });

      test('resize returns false when the size count is invalid', () {
        final c = PlatController(
          initialPlat: .row(
            id: 'row',
            children: [
              .tabs([tabPane('a')], id: 'left'),
              .tabs([tabPane('b')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);

        final changed = c.resizeSplit('row', const [.fixed(.pixel(180))]);

        expect(changed, isFalse);
      });
    });

    group('reorderLeaf', () {
      test('returns true when it reorders leaves', () {
        final c = controllerFromLeaves([tab('a'), tab('b'), tab('c')]);
        addTearDown(c.dispose);

        final changed = c.reorderTab(tabGroupId: c.rootId, from: 0, to: 2);

        expect(changed, isTrue);
      });

      test('returns false when the target position is unchanged', () {
        final c = controllerFromLeaves([tab('a'), tab('b'), tab('c')]);
        addTearDown(c.dispose);

        final changed = c.reorderTab(tabGroupId: c.rootId, from: 1, to: 1);

        expect(changed, isFalse);
      });

      test('returns false when the source index is invalid', () {
        final c = controllerFromLeaves([tab('a'), tab('b'), tab('c')]);
        addTearDown(c.dispose);

        final changed = c.reorderTab(tabGroupId: c.rootId, from: 9, to: 1);

        expect(changed, isFalse);
      });
    });

    group('setTabBarSide', () {
      test('returns true when it changes the side', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);

        final changed = c.setTabBarSide(c.rootId, .left);

        expect(changed, isTrue);
      });

      test('updates the side on the snapshot', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);

        c.setTabBarSide(c.rootId, .left);

        expect(
          (c.snapshot(c.rootId)! as TabGroupSnapshot).side,
          TabBarSide.left,
        );
      });

      test('is transient and does not push undo', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        c.setTabBarSide(c.rootId, .right);

        expect(c.canUndo, isFalse);
      });

      test('does not notify on an unchanged side', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);
        var notifies = 0;
        c.addListener(() => notifies++);

        c.setTabBarSide(c.rootId, .top);

        expect(notifies, 0);
      });

      test('returns false on an unchanged side', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        final changed = c.setTabBarSide(c.rootId, .top);

        expect(changed, isFalse);
      });

      test('is a no-op on a non-tab group id', () {
        final c = PlatController(
          initialPlat: .row(
            id: 's',
            children: [
              .tabs([tabPane('a')], id: 'left'),
              .tabs([tabPane('b')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);
        var notifies = 0;
        c.addListener(() => notifies++);

        c.setTabBarSide('s', .right);

        expect(notifies, 0);
        expect((c.snapshot('left')! as TabGroupSnapshot).side, TabBarSide.top);
      });

      test('returns false on a non-tab group id', () {
        final c = PlatController(
          initialPlat: .row(
            id: 's',
            children: [
              .tabs([tabPane('a')], id: 'left'),
              .tabs([tabPane('b')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);

        final changed = c.setTabBarSide('s', .right);

        expect(changed, isFalse);
      });
    });

    group('replace(Plat)', () {
      test('swaps in a new tree and pushes an undo entry', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        final changed = c.replace(
          .tabs([tabPane('b'), tabPane('c')], id: 'after'),
        );

        expect(changed, isTrue);
        expect(c.tabGroupIds.toList(), ['after']);
        expect(c.leafIds.toList(), ['b', 'c']);
        expect(c.canUndo, isTrue);
      });

      test('returns false for duplicate ids', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        final changed = c.replace(
          .row(
            id: generateNodeId(),
            children: [
              .tabs([tabPane('a')], id: 'dup'),
              .tabs([tabPane('b')], id: 'dup'),
            ],
          ),
        );

        expect(changed, isFalse);
        expect(c.leafIds.toList(), ['a']);
      });

      test('replaces a collapsing root with an empty tab group', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        final changed = c.replace(const .tabs([]));

        expect(changed, isTrue);
        expect(c.root, isA<TabGroupSnapshot>());
        expect((c.root as TabGroupSnapshot).tabs, isEmpty);
      });
    });

    group('insertTabBeside', () {
      test('wraps the tab in a new sibling group on the requested side', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);
        final targetId = c.rootId;

        final changed = c.insertTabBeside(
          targetId: targetId,
          side: .right,
          tab: tabPane('b'),
        );

        expect(changed, isTrue);
        final root = c.snapshot(c.rootId)! as SplitSnapshot;
        expect(root.children.first.id, targetId);
        expect((root.children.last as TabGroupSnapshot).tabs.single.id, 'b');
      });

      test('focuses the inserted tab', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        c.insertTabBeside(targetId: c.rootId, side: .right, tab: tabPane('b'));

        expect(c.focusedLeaf?.id, 'b');
      });

      test('focuses an inserted tab with a generated id', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        final changed = c.insertTabBeside(
          targetId: c.rootId,
          side: .right,
          tab: tabPaneWith(title: 'generated'),
        );

        expect(changed, isTrue);
        expect(c.focusedLeaf?.title, 'generated');
        expect(c.focusedLeaf?.id, startsWith('p_'));
      });
    });

    group('moveTabBeside', () {
      test('moves the tab into a new sibling group on the requested side', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);
        final sourceId = c.rootId;

        final changed = c.moveTabBeside(
          tabId: 'b',
          targetId: sourceId,
          side: .right,
        );

        expect(changed, isTrue);
        final root = c.snapshot(c.rootId)! as SplitSnapshot;
        final right = root.children.last as TabGroupSnapshot;
        expect(right.tabs.single.id, 'b');
      });

      test("returns false when target is inside the tab's own subtree", () {
        final c = controllerFromTree(
          TabGroupNode(
            id: 'outer',
            tabs: [
              TabNode(
                child: TabGroupNode(id: 'inner', tabs: treeTabs([tab('a')])),
                title: 'wrapper',
              ),
            ],
          ),
        );
        addTearDown(c.dispose);

        final changed = c.moveTabBeside(
          tabId: 'outer',
          targetId: 'inner',
          side: .right,
        );

        expect(changed, isFalse);
      });
    });

    group('moveTabIntoSlot', () {
      test('moves the tab into an empty slot', () {
        final c = controllerFromTree(
          SplitNode(
            id: 'row',
            axis: .horizontal,
            children: [
              TabGroupNode(id: 'group', tabs: treeTabs([tab('a')])),
              SlotNode(id: 'slot', persistent: true),
            ],
          ),
        );
        addTearDown(c.dispose);

        final changed = c.moveTabIntoSlot(tabId: 'a', slotId: 'slot');

        expect(changed, isTrue);
        final slot = c.snapshot('slot')! as SlotSnapshot;
        expect((slot.child! as TabGroupSnapshot).tabs.single.id, 'a');
      });

      test('returns false when the slot is not empty', () {
        final c = controllerFromTree(
          SplitNode(
            id: 'row',
            axis: .horizontal,
            children: [
              TabGroupNode(id: 'group', tabs: treeTabs([tab('a')])),
              SlotNode(
                id: 'slot',
                persistent: true,
                child: TabGroupNode(id: 'inner', tabs: treeTabs([tab('b')])),
              ),
            ],
          ),
        );
        addTearDown(c.dispose);

        final changed = c.moveTabIntoSlot(tabId: 'a', slotId: 'slot');

        expect(changed, isFalse);
      });
    });

    group('firstTabGroupId', () {
      test('returns the first tab group in tree order', () {
        final c = PlatController(
          initialPlat: .row(
            id: 'row',
            children: [
              .tabs([tabPane('a')], id: 'left'),
              .tabs([tabPane('b')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);

        expect(c.firstTabGroupId(), 'left');
      });

      test('returns null when the tree has no tab groups', () {
        final c = controllerFromTree(SlotNode(id: 'slot', persistent: true));
        addTearDown(c.dispose);

        expect(c.firstTabGroupId(), isNull);
      });
    });

    group('nextTabGroupId', () {
      test('returns firstTabGroupId when current is null', () {
        final c = PlatController(
          initialPlat: .row(
            id: 'row',
            children: [
              .tabs([tabPane('a')], id: 'left'),
              .tabs([tabPane('b')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);

        expect(c.nextTabGroupId(null), 'left');
      });

      test('cycles forward through tab groups in tree order', () {
        final c = PlatController(
          initialPlat: .row(
            id: 'row',
            children: [
              .tabs([tabPane('a')], id: 'left'),
              .tabs([tabPane('b')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);

        expect(c.nextTabGroupId('left'), 'right');
        expect(c.nextTabGroupId('right'), 'left');
      });

      test('moves backward with a negative delta', () {
        final c = PlatController(
          initialPlat: .row(
            id: 'row',
            children: [
              .tabs([tabPane('a')], id: 'left'),
              .tabs([tabPane('b')], id: 'right'),
            ],
          ),
        );
        addTearDown(c.dispose);

        expect(c.nextTabGroupId('left', delta: -1), 'right');
      });

      test('returns null when the tree has no tab groups', () {
        final c = controllerFromTree(SlotNode(id: 'slot', persistent: true));
        addTearDown(c.dispose);

        expect(c.nextTabGroupId(null), isNull);
      });
    });

    group('clearHistory', () {
      test('drops both undo and redo stacks without touching the tree', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);
        c.insertTab(tabGroupId: c.rootId, tab: tabPane('b'));
        c.undo();
        expect(c.canUndo, isFalse);
        expect(c.canRedo, isTrue);
        final beforeIds = c.leafIds.toList();

        final changed = c.clearHistory();

        expect(changed, isTrue);
        expect(c.canUndo, isFalse);
        expect(c.canRedo, isFalse);
        expect(c.leafIds.toList(), beforeIds);
      });

      test('returns false when history is already empty', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        final changed = c.clearHistory();

        expect(changed, isFalse);
      });

      test('notifies when it clears observable history state', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);
        c.insertTab(tabGroupId: c.rootId, tab: tabPane('b'));
        var notifies = 0;
        c.addListener(() => notifies++);

        c.clearHistory();

        expect(notifies, 1);
      });
    });

    group('undo / redo / transaction', () {
      test('undo restores the prior root', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);
        c.insertTab(tabGroupId: c.rootId, tab: tabPane('b'));

        final changed = c.undo();

        expect(changed, isTrue);
        expect(c.leafIds, ['a']);
      });

      test('redo reapplies the change', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);
        c.insertTab(tabGroupId: c.rootId, tab: tabPane('b'));
        c.undo();

        final changed = c.redo();

        expect(changed, isTrue);
        expect(c.leafIds, ['a', 'b']);
      });

      test('undo and redo return false when there is nothing to apply', () {
        final c = controllerFromLeaves([tab('a')]);
        addTearDown(c.dispose);

        expect(c.undo(), isFalse);
        expect(c.redo(), isFalse);
      });

      test('undo restores focus snapshotted at the structural commit', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);
        c.focus('b');
        c.insertTabBeside(targetId: c.rootId, side: .right, tab: tabPane('c'));
        expect(c.focusedLeaf?.id, 'c');

        c.undo();

        expect(c.focusedLeaf?.id, 'b');
      });

      test('transaction coalesces multiple resizes into one undo', () {
        final c = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(c.dispose);
        c.focus('b');
        c.splitActiveTab(tabGroupId: c.rootId, side: .right);
        final splitId = c.rootId;
        final beforeSizes = _splitChildSizes(c, splitId);

        c.transaction(() => _resizeSplitThroughFractions(c, splitId));
        c.undo();

        final afterUndoSizes = _splitChildSizes(c, splitId);

        expect(afterUndoSizes, beforeSizes);
      });
    });
  });
}

List<String> _childrenIdsOf(PlatController c, String id) {
  final node = c.snapshot(id);
  return switch (node) {
    final SplitSnapshot split => [for (final child in split.children) child.id],
    final SlotSnapshot slot when slot.child != null => [slot.child!.id],
    _ => const [],
  };
}

List<String> _focusedTabIds(TabGroupSnapshot group) => [
  for (final tab in group.tabs)
    if (tab.focused) tab.id,
];

LeafSnapshot? _leafSnapshot(PlatController c, String id) {
  final node = c.snapshot(id);
  return node is LeafSnapshot ? node : null;
}

List<String> _leavesIn(PlatController c, String id) {
  final node = c.snapshot(id);
  if (node == null) return const [];
  final ids = <String>[];
  void walk(PlatSnapshot s) {
    switch (s) {
      case final LeafSnapshot leaf:
        ids.add(leaf.id);
      case final SplitSnapshot split:
        for (final child in split.children) {
          walk(child);
        }
      case final TabGroupSnapshot tabs:
        for (final tab in tabs.tabs) {
          walk(tab.child);
        }
      case final SlotSnapshot slot:
        final c = slot.child;
        if (c != null) walk(c);
    }
  }

  walk(node);
  return ids;
}

PlatSnapshot? _maximizedPane(PlatController c) {
  final id = c.maximizedId();
  return id == null ? null : c.snapshot(id);
}

List<String> _previewTabIds(TabGroupSnapshot group) => [
  for (final tab in group.tabs)
    if (tab.preview) tab.id,
];

void _resizeSplitThroughFractions(PlatController c, String splitId) {
  for (final width in [0.6, 0.7, 0.8]) {
    c.resizeSplit(splitId, [
      .resizable(initial: .fraction(width)),
      .resizable(initial: .fraction(1 - width)),
    ]);
  }
}

List<PlatSize> _splitChildSizes(PlatController c, String splitId) {
  return [
    for (final child in (c.snapshot(splitId)! as SplitSnapshot).children)
      child.size,
  ];
}

TabSnapshot? _tabSnapshot(PlatController c, String id) {
  TabSnapshot? visit(PlatSnapshot snapshot) {
    switch (snapshot) {
      case LeafSnapshot():
        return null;
      case final SplitSnapshot split:
        for (final child in split.children) {
          final tab = visit(child);
          if (tab != null) return tab;
        }
      case final TabGroupSnapshot group:
        for (final tab in group.tabs) {
          if (tab.id == id) return tab;
          final nested = visit(tab.child);
          if (nested != null) return nested;
        }
      case final SlotSnapshot slot:
        final child = slot.child;
        if (child != null) return visit(child);
    }

    return null;
  }

  return visit(c.root);
}
