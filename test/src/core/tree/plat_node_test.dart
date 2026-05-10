import 'package:flutter_test/flutter_test.dart';
import 'package:plat/plat.dart';

import '../../../helpers.dart';

void main() {
  group('PlatNode', () {
    group('PlatNode', () {
      group('findNode', () {
        test('walks every node kind to reach the matching id', () {
          final tree = hSplit('outer', [
            SlotNode(
              id: 'slot',
              child: TabGroupNode(id: 'group', tabs: treeTabs([tab('a')])),
            ),
            TabGroupNode(id: 'right', tabs: treeTabs([tab('b'), tab('c')])),
          ]);

          expect(tree.findNode('outer'), same(tree));
          expect(tree.findNode('slot'), isA<SlotNode>());
          expect(tree.findNode('group'), isA<TabGroupNode>());
          expect(tree.findNode('a'), isA<LeafNode>());
          expect(tree.findNode('right'), isA<TabGroupNode>());
          expect(tree.findNode('b'), isA<LeafNode>());
        });

        test('returns null for an absent id', () {
          final root = TabGroupNode(id: 'group', tabs: treeTabs([tab('a')]));

          expect(root.findNode('nope'), isNull);
        });
      });

      group('pathTo', () {
        test('returns the inclusive root-to-target path', () {
          final root = hSplit('outer', [
            SlotNode(
              id: 'slot',
              child: TabGroupNode(id: 'group', tabs: treeTabs([tab('a')])),
            ),
            TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
          ]);

          final path = root.pathTo('a');

          expect(path!.map((p) => p.id).toList(), [
            'outer',
            'slot',
            'group',
            'a',
          ]);
        });

        test('returns a single-element path when target is the receiver', () {
          final root = TabGroupNode(id: 'group', tabs: treeTabs([tab('a')]));

          expect(root.pathTo('group')?.single, same(root));
        });

        test('returns null when the target is not in the subtree', () {
          final root = TabGroupNode(id: 'group', tabs: treeTabs([tab('a')]));

          expect(root.pathTo('missing'), isNull);
        });
      });

      group('tabGroupOf', () {
        test(
          'returns the enclosing TabGroupNode of a leaf, walking through Slots',
          () {
            final root = hSplit('root', [
              SlotNode(
                id: 'slot',
                child: TabGroupNode(id: 'group', tabs: treeTabs([tab('a')])),
              ),
              TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
            ]);

            expect(root.tabGroupOf('a')?.id, 'group');
            expect(root.tabGroupOf('b')?.id, 'right');
          },
        );

        test('returns null for standalone leaves and unknown ids', () {
          final root = hSplit('root', [
            TabGroupNode(id: 'group', tabs: treeTabs([tab('a')])),
            tab('standalone'),
          ]);

          expect(root.tabGroupOf('standalone'), isNull);
          expect(root.tabGroupOf('missing'), isNull);
        });
      });

      group('leafIds', () {
        test('yields every reachable leaf in tree order', () {
          final root = hSplit('root', [
            SlotNode(
              id: 'slot',
              child: TabGroupNode(
                id: 'left',
                tabs: treeTabs([tab('a'), tab('b')]),
              ),
            ),
            TabGroupNode(id: 'right', tabs: treeTabs([tab('c')])),
          ]);

          expect(root.leafIds.map((id) => id).toList(), ['a', 'b', 'c']);
        });

        test('handles boundary node shapes', () {
          expect(tab('a').leafIds.toList(), ['a']);
          expect(TabGroupNode.empty().leafIds, isEmpty);
        });
      });

      group('subtreeIds', () {
        test('yields every reachable node id in tree order', () {
          final root = hSplit('root', [
            SlotNode(
              id: 'slot',
              child: TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
            ),
            TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
          ]);

          expect(root.subtreeIds.map((id) => id).toList(), [
            'root',
            'slot',
            'left',
            'a',
            'right',
            'b',
          ]);
        });
      });

      group('tabGroups', () {
        test('yields every TabGroupNode in the subtree in tree order', () {
          final root = hSplit('root', [
            TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
            TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
          ]);

          expect(root.tabGroups.map((t) => t.id).toList(), ['left', 'right']);
        });

        test('is empty for a standalone Leaf', () {
          expect(tab('a').tabGroups, isEmpty);
        });
      });

      group('focusedLeaf', () {
        test('finds the focused Leaf anywhere in the subtree', () {
          final flat = TabGroupNode(
            id: 'group',
            tabs: treeTabs([tab('a'), tab('b').copyWith(focused: true)]),
          );
          final nested = hSplit('root', [
            TabGroupNode(
              id: 'left',
              tabs: treeTabs([tab('a'), tab('b').copyWith(focused: true)]),
              activeIndex: 1,
            ),
            TabGroupNode(id: 'right', tabs: treeTabs([tab('c')])),
          ]);

          expect(flat.focusedLeaf()?.id, 'b');
          expect(nested.focusedLeaf()?.id, 'b');
        });

        test('returns null when no leaf is focused', () {
          final root = TabGroupNode(
            id: 'group',
            tabs: treeTabs([tab('a'), tab('b')]),
          );

          expect(root.focusedLeaf(), isNull);
        });
      });

      group('maximizedPane', () {
        test('returns the maximized node when it sits below this subtree', () {
          final root = hSplit('root', [
            TabGroupNode(
              id: 'left',
              tabs: treeTabs([tab('a')]),
              maximized: true,
            ),
            TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
          ]);

          expect(root.maximizedPane()?.id, 'left');
        });

        test('returns the receiver when it is itself maximized', () {
          final root = TabGroupNode(
            id: 'group',
            tabs: treeTabs([tab('a')]),
            maximized: true,
          );

          expect(root.maximizedPane(), same(root));
        });

        test('returns null when nothing is maximized', () {
          final root = TabGroupNode(id: 'group', tabs: treeTabs([tab('a')]));

          expect(root.maximizedPane(), isNull);
        });
      });

      group('addLeafTo', () {
        test(
          'returns a fresh single-TabGroupNode root when targetId is null',
          () {
            final root = TabGroupNode(id: 'group', tabs: treeTabs([tab('a')]));

            final next = root.addLeafTo(null, tab('b'));

            expect(leafIds((next as TabGroupNode).tabs), ['b']);
          },
        );

        test('inserts into the target TabGroupNode', () {
          final root = TabGroupNode(id: 'group', tabs: treeTabs([tab('a')]));

          final next = root.addLeafTo('group', tab('b'));

          expect(leafIds((next as TabGroupNode).tabs), ['a', 'b']);
        });

        test('respects insertAt inside the target TabGroupNode', () {
          final root = TabGroupNode(
            id: 'group',
            tabs: treeTabs([tab('a'), tab('b')]),
          );

          final next = root.addLeafTo('group', tab('mid'), insertAt: 1);

          expect(leafIds((next as TabGroupNode).tabs), ['a', 'mid', 'b']);
        });

        test('seeds a new TabGroupNode inside an empty SlotNode target', () {
          final root = SlotNode(id: 'slot', persistent: true);

          final next = root.addLeafTo('slot', tab('a')) as SlotNode;

          expect(leafIds((next.child! as TabGroupNode).tabs), ['a']);
        });

        test(
          'routes a SplitNode target to its first TabGroupNode descendant',
          () {
            final root = hSplit('root', [
              TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
              TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
            ]);

            final next = root.addLeafTo('root', tab('new'));
            final firstTabGroup =
                (next as SplitNode).children.first as TabGroupNode;

            expect(leafIds(firstTabGroup.tabs), ['a', 'new']);
          },
        );

        test(
          'prefers the focusedHint TabGroupNode inside a SplitNode target',
          () {
            final root = hSplit('root', [
              TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
              TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
            ]);

            final next = root.addLeafTo(
              'root',
              tab('new'),
              focusedHint: 'right',
            );
            final hintedTabs =
                (next as SplitNode).children.last as TabGroupNode;

            expect(leafIds(hintedTabs.tabs), ['b', 'new']);
          },
        );

        test('seeds a new TabGroupNode when the SplitNode has no '
            'TabGroupNode descendant', () {
          final root = hSplit('root', [
            SlotNode(id: 'left', persistent: true),
            SlotNode(id: 'right', persistent: true),
          ]);

          final next = root.addLeafTo('root', tab('new')) as SplitNode;

          expect(next.children, hasLength(3));
          expect(next.children.last, isA<TabGroupNode>());
        });

        test('throws when the target is a Leaf', () {
          final root = TabGroupNode(id: 'group', tabs: treeTabs([tab('a')]));

          expect(
            () => root.addLeafTo('a', tab('b')),
            throwsA(isA<StateError>()),
          );
        });
      });

      group('insertLeaf', () {
        test('appends when insertAt is null', () {
          final root = TabGroupNode(id: 'group', tabs: treeTabs([tab('a')]));

          final next = root.insertLeaf('group', tab('b'));

          expect(leafIds((next as TabGroupNode).tabs), ['a', 'b']);
        });

        test('activates the inserted leaf by default', () {
          final root = TabGroupNode(
            id: 'group',
            tabs: treeTabs([tab('a'), tab('b')]),
          );

          final next =
              root.insertLeaf('group', tab('mid'), insertAt: 1) as TabGroupNode;

          expect(next.activeIndex, 1);
        });

        test('preserves activeIndex when activate is false', () {
          final root = TabGroupNode(
            id: 'group',
            tabs: treeTabs([tab('a'), tab('b')]),
            activeIndex: 1,
          );

          final next =
              root.insertLeaf('group', tab('mid'), activate: false)
                  as TabGroupNode;

          expect(next.activeIndex, 1);
        });

        test('clamps insertAt to the valid range', () {
          final base = TabGroupNode(id: 'group', tabs: treeTabs([tab('a')]));

          final tooHigh =
              base.insertLeaf('group', tab('b'), insertAt: 99) as TabGroupNode;
          final tooLow =
              base.insertLeaf('group', tab('b'), insertAt: -5) as TabGroupNode;

          expect(leafIds(tooHigh.tabs), ['a', 'b']);
          expect(leafIds(tooLow.tabs), ['b', 'a']);
        });
      });

      group('insertTab preview semantics', () {
        test('replaces an existing preview at the same position when index is '
            'omitted', () {
          final root = TabGroupNode(
            id: 'group',
            tabs: [
              treeTab('a'),
              treeTab('preview', preview: true),
              treeTab('b'),
            ],
            activeIndex: 1,
          );

          final next =
              root.insertTab('group', treeTab('new-preview', preview: true))
                  as TabGroupNode;

          expect(next.tabs.map((tab) => tab.id).toList(), [
            'a',
            'new-preview',
            'b',
          ]);
          expect(_previewTabIds(next), ['new-preview']);
          expect(next.tabs[1].preview, isTrue);
        });

        test(
          'honors the requested final index when replacing an existing preview',
          () {
            final root = TabGroupNode(
              id: 'group',
              tabs: [
                treeTab('a'),
                treeTab('preview', preview: true),
                treeTab('b'),
              ],
            );

            final next =
                root.insertTab(
                      'group',
                      treeTab('new-preview', preview: true),
                      index: 0,
                    )
                    as TabGroupNode;

            expect(next.tabs.map((tab) => tab.id).toList(), [
              'new-preview',
              'a',
              'b',
            ]);
            expect(_previewTabIds(next), ['new-preview']);
          },
        );
      });

      group('removeLeaf', () {
        test('removes the leaf and shifts activeIndex left when needed', () {
          final root = TabGroupNode(
            id: 'group',
            tabs: treeTabs([tab('a'), tab('b'), tab('c')]),
            activeIndex: 2,
          );

          final next = root.removeLeaf('a')! as TabGroupNode;

          expect(leafIds(next.tabs), ['b', 'c']);
          expect(next.activeIndex, 1);
        });

        test('keeps activeIndex when removing a later leaf', () {
          final root = TabGroupNode(
            id: 'group',
            tabs: treeTabs([tab('a'), tab('b'), tab('c')]),
          );

          final next = root.removeLeaf('c')! as TabGroupNode;

          expect(next.activeIndex, 0);
        });

        test('clamps activeIndex when the active leaf is removed', () {
          final root = TabGroupNode(
            id: 'group',
            tabs: treeTabs([tab('a'), tab('b')]),
            activeIndex: 1,
          );

          final next = root.removeLeaf('b')! as TabGroupNode;

          expect(next.activeIndex, 0);
        });

        test('returns the same instance when leaf is not in the tree', () {
          final root = TabGroupNode(id: 'group', tabs: treeTabs([tab('a')]));

          expect(root.removeLeaf('nope'), same(root));
        });

        test('returns null when the last leaf is removed', () {
          final root = TabGroupNode(id: 'group', tabs: treeTabs([tab('a')]));

          expect(root.removeLeaf('a'), isNull);
        });

        test('removes the leaf and unwraps the parent split when it '
            'collapses', () {
          final root = hSplit('root', [
            TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
            TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
          ]);

          final next = root.removeLeaf('a');

          expect(next, isA<TabGroupNode>());
          expect((next! as TabGroupNode).id, 'right');
        });
      });

      group('reorderLeaf', () {
        test('moves a leaf forward and tracks active', () {
          final root = TabGroupNode(
            id: 'group',
            tabs: treeTabs([tab('a'), tab('b'), tab('c')]),
          );

          final next = root.reorderLeaf('group', 0, 2) as TabGroupNode;

          expect(leafIds(next.tabs), ['b', 'c', 'a']);
          expect(next.activeIndex, 2);
        });

        test('moves a leaf backward and tracks active', () {
          final root = TabGroupNode(
            id: 'group',
            tabs: treeTabs([tab('a'), tab('b'), tab('c')]),
            activeIndex: 2,
          );

          final next = root.reorderLeaf('group', 2, 0) as TabGroupNode;

          expect(leafIds(next.tabs), ['c', 'a', 'b']);
          expect(next.activeIndex, 0);
        });

        test('returns the same instance when from equals clamped to', () {
          final root = TabGroupNode(
            id: 'group',
            tabs: treeTabs([tab('a'), tab('b')]),
          );

          expect(root.reorderLeaf('group', 0, 0), same(root));
        });

        test('clamps to to leaves.length - 1', () {
          final root = TabGroupNode(
            id: 'group',
            tabs: treeTabs([tab('a'), tab('b')]),
          );

          final next = root.reorderLeaf('group', 0, 99) as TabGroupNode;

          expect(leafIds(next.tabs), ['b', 'a']);
        });

        test('throws when from is out of bounds', () {
          final root = TabGroupNode(
            id: 'group',
            tabs: treeTabs([tab('a'), tab('b')]),
          );

          expect(
            () => root.reorderLeaf('group', 5, 0),
            throwsA(isA<RangeError>()),
          );
          expect(
            () => root.reorderLeaf('group', -1, 0),
            throwsA(isA<RangeError>()),
          );
        });
      });

      group('moveLeaf', () {
        test(
          'reorders inside the origin TabGroupNode when destination matches',
          () {
            final root = TabGroupNode(
              id: 'group',
              tabs: treeTabs([tab('a'), tab('b'), tab('c')]),
            );

            final next =
                root.moveLeaf('a', 'group', insertAt: 2)! as TabGroupNode;

            expect(leafIds(next.tabs), ['b', 'a', 'c']);
          },
        );

        test('relocates across TabGroupNode preserving both groups', () {
          final root = hSplit('root', [
            TabGroupNode(id: 'left', tabs: treeTabs([tab('a'), tab('keep')])),
            TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
          ]);

          final next = root.moveLeaf('a', 'right')! as SplitNode;

          expect(leafIds((next.findNode('left')! as TabGroupNode).tabs), [
            'keep',
          ]);
          expect(leafIds((next.findNode('right')! as TabGroupNode).tabs), [
            'b',
            'a',
          ]);
        });

        test('promotes the surviving TabGroupNode when origin collapses', () {
          final root = hSplit('root', [
            TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
            TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
          ]);

          final next = root.moveLeaf('a', 'right');

          expect(next, isA<TabGroupNode>());
          expect(leafIds((next! as TabGroupNode).tabs), ['b', 'a']);
        });

        test('returns same instance when leaf is unknown', () {
          final root = TabGroupNode(id: 'group', tabs: treeTabs([tab('a')]));

          expect(root.moveLeaf('nope', 'group'), same(root));
        });

        test('returns same instance when destination is unknown', () {
          final root = hSplit('root', [
            TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
            TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
          ]);

          final next = root.moveLeaf('a', 'missing');

          expect(next, same(root));
        });

        test('replaces the destination preview when moving a preview tab', () {
          final root = hSplit('root', [
            TabGroupNode(
              id: 'left',
              tabs: [treeTab('moving', preview: true), treeTab('keep')],
            ),
            TabGroupNode(
              id: 'right',
              tabs: [treeTab('preview', preview: true), treeTab('b')],
            ),
          ]);

          final next = root.moveTab('moving', 'right') as SplitNode;

          final right = next.findNode('right')! as TabGroupNode;
          expect(right.tabs.map((tab) => tab.id).toList(), ['moving', 'b']);
          expect(_previewTabIds(right), ['moving']);
        });
      });

      group('setTabFlags preview', () {
        test('promoting a tab to preview removes a sibling preview', () {
          final root = TabGroupNode(
            id: 'group',
            tabs: [
              treeTab('preview', preview: true),
              treeTab('b'),
              treeTab('c'),
            ],
            activeIndex: 2,
          );

          final next = root.setTabFlags('c', preview: true) as TabGroupNode;

          expect(next.tabs.map((tab) => tab.id).toList(), ['b', 'c']);
          expect(_previewTabIds(next), ['c']);
          expect(next.tabs.last.preview, isTrue);
          expect(next.activeIndex, 1);
        });

        test('clears preview in place when demoting a preview tab', () {
          final root = TabGroupNode(
            id: 'group',
            tabs: [treeTab('preview', preview: true), treeTab('b')],
          );

          final next =
              root.setTabFlags('preview', preview: false) as TabGroupNode;

          expect(next.tabs.map((tab) => tab.id).toList(), ['preview', 'b']);
          expect(_previewTabIds(next), isEmpty);
        });
      });

      group('split', () {
        test('splitting a leaf inside a tab group wraps inside that tab '
            'instead of reusing an outer same-axis split', () {
          final root = hSplit('outer', [
            TabGroupNode(id: 'group', tabs: treeTabs([tab('a')])),
            TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
          ]);

          final next = root.split('a', .right, tab('c')) as SplitNode;

          expect(next.children, hasLength(2));
          final group = next.children.first as TabGroupNode;
          expect(group.id, 'group');
          expect(group.tabs, hasLength(1));
          expect(group.tabs.single.child, isA<SplitNode>());
          final inner = group.tabs.single.child as SplitNode;
          expect(inner.axis, SplitAxis.horizontal);
          expect(inner.children.map((child) => child.id).toList(), ['a', 'c']);
        });
      });

      group('replace', () {
        test(
          'returns the replacement when target is the receiver TabGroupNode',
          () {
            final root = TabGroupNode(id: 'group', tabs: treeTabs([tab('a')]));
            final swapped = TabGroupNode(
              id: 'replacement',
              tabs: treeTabs([tab('x')]),
            );

            expect(root.replace('group', swapped), same(swapped));
          },
        );

        test('returns null when the receiver is replaced with null', () {
          final root = TabGroupNode(id: 'group', tabs: treeTabs([tab('a')]));

          expect(root.replace('group', null), isNull);
        });

        test('throws when target is unknown on a Leaf', () {
          final leaf = tab('a');

          expect(
            () => leaf.replace('missing', null),
            throwsA(isA<StateError>()),
          );
        });

        test('replaces a SplitNode child and unwraps to the survivor', () {
          final root = hSplit('root', [
            TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
            TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
          ]);

          final next = root.replace('right', null);

          expect(next, isA<TabGroupNode>());
          expect((next! as TabGroupNode).id, 'left');
        });

        test('replaces a SlotNode child and preserves the wrapper id', () {
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
      });

      group('resize', () {
        test('returns the same instance when size is identical', () {
          final root = TabGroupNode(id: 'group', tabs: treeTabs([tab('a')]));

          expect(root.resize(root.size), same(root));
        });

        test('updates size for every concrete subtype', () {
          const target = PlatSize.fixed(.pixel(120));

          expect(
            TabGroupNode(
              id: 't',
              tabs: treeTabs([tab('a')]),
            ).resize(target).size,
            target,
          );
          expect(
            SlotNode(id: 's', persistent: true).resize(target).size,
            target,
          );
          expect(
            hSplit('sp', [
              TabGroupNode(id: 'a', tabs: treeTabs([tab('a')])),
              TabGroupNode(id: 'b', tabs: treeTabs([tab('b')])),
            ]).resize(target).size,
            target,
          );
          expect(tab('a').resize(target).size, target);
        });
      });

      group('resizeSplit', () {
        test('applies sizes positionally', () {
          final root = hSplit('root', [
            TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
            TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
          ]);

          final next =
              root.resizeSplit('root', const [
                    .resizable(initial: .fraction(0.3)),
                    .resizable(initial: .fraction(0.7)),
                  ])
                  as SplitNode;

          expect(
            next.children[0].size,
            const PlatSize.resizable(initial: .fraction(0.3)),
          );
          expect(
            next.children[1].size,
            const PlatSize.resizable(initial: .fraction(0.7)),
          );
        });

        test('throws when the id is not a SplitNode', () {
          final root = TabGroupNode(id: 'group', tabs: treeTabs([tab('a')]));

          expect(
            () => root.resizeSplit('group', const [.auto(), .auto()]),
            throwsA(isA<StateError>()),
          );
        });

        test('throws when sizes length mismatches children', () {
          final root = hSplit('root', [
            TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
            TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
          ]);

          expect(
            () => root.resizeSplit('root', const [.auto()]),
            throwsA(isA<ArgumentError>()),
          );
        });
      });

      group('dropLeaf', () {
        group('center zone', () {
          test('appends a leaf to the target TabGroupNode', () {
            final root = TabGroupNode(id: 'group', tabs: treeTabs([tab('a')]));

            final next = root.dropLeaf(tab('b'), 'group', DropZone.center);

            expect(leafIds((next! as TabGroupNode).tabs), ['a', 'b']);
          });

          test('seeds a TabGroupNode inside an empty SlotNode target', () {
            final root = SlotNode(id: 'slot', persistent: true);

            final next =
                root.dropLeaf(tab('a'), 'slot', DropZone.center)! as SlotNode;

            expect(leafIds((next.child! as TabGroupNode).tabs), ['a']);
          });

          test('inserts at insertAt when provided', () {
            final root = TabGroupNode(
              id: 'group',
              tabs: treeTabs([tab('a'), tab('c')]),
            );

            final next = root.dropLeaf(
              tab('b'),
              'group',
              DropZone.center,
              insertAt: 1,
            );

            expect(leafIds((next! as TabGroupNode).tabs), ['a', 'b', 'c']);
          });
        });

        group('edge zones', () {
          test('aligns axis and sibling order with the drop edge', () {
            final base = TabGroupNode(id: 'group', tabs: treeTabs([tab('a')]));

            final right =
                base.dropLeaf(tab('b'), 'group', DropZone.right)! as SplitNode;
            final left =
                base.dropLeaf(tab('b'), 'group', DropZone.left)! as SplitNode;
            final bottom =
                base.dropLeaf(tab('b'), 'group', DropZone.bottom)! as SplitNode;
            final top =
                base.dropLeaf(tab('b'), 'group', DropZone.top)! as SplitNode;

            expect(right.axis, SplitAxis.horizontal);
            expect(leafIds((right.children.first as TabGroupNode).tabs), ['a']);
            expect(leafIds((right.children.last as TabGroupNode).tabs), ['b']);

            expect(left.axis, SplitAxis.horizontal);
            expect(leafIds((left.children.first as TabGroupNode).tabs), ['b']);
            expect(leafIds((left.children.last as TabGroupNode).tabs), ['a']);

            expect(bottom.axis, SplitAxis.vertical);
            expect(leafIds((bottom.children.last as TabGroupNode).tabs), ['b']);

            expect(top.axis, SplitAxis.vertical);
            expect(leafIds((top.children.first as TabGroupNode).tabs), ['b']);
          });

          test('inlines into a same-axis parent instead of nesting', () {
            final root = hSplit('root', [
              TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
              TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
            ]);

            final next = root.dropLeaf(tab('c'), 'right', DropZone.right);

            expect((next! as SplitNode).children, hasLength(3));
          });

          test('cross-axis edge drop nests a new split', () {
            final root = hSplit('root', [
              TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
              TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
            ]);

            final next = root.dropLeaf(tab('c'), 'right', DropZone.bottom);
            final outer = next! as SplitNode;

            expect(outer.axis, SplitAxis.horizontal);
            expect(outer.children.last, isA<SplitNode>());
            expect((outer.children.last as SplitNode).axis, SplitAxis.vertical);
          });

          test('returns same instance when the target id is unknown', () {
            final root = TabGroupNode(id: 'group', tabs: treeTabs([tab('a')]));

            expect(
              root.dropLeaf(tab('b'), 'missing', DropZone.right),
              same(root),
            );
          });
        });

        group('size halving', () {
          test('halves a fractional initial size when inlining next to a '
              'sibling', () {
            final root = SplitNode(
              id: 'root',
              axis: .horizontal,
              children: [
                TabGroupNode(
                  id: 'left',
                  tabs: treeTabs([tab('a')]),
                  size: const .resizable(initial: .fraction(1)),
                ),
                TabGroupNode(
                  id: 'right',
                  tabs: treeTabs([tab('b')]),
                  size: const .resizable(initial: .fraction(1)),
                ),
              ],
            );

            final next =
                root.dropLeaf(tab('c'), 'right', DropZone.right)! as SplitNode;

            expect(
              next.children[1].size,
              const PlatSize.resizable(initial: .fraction(0.5)),
            );
            expect(
              next.children[2].size,
              const PlatSize.resizable(initial: .fraction(0.5)),
            );
          });

          test('halves the sibling size even when the parent SplitNode sits '
              'below a SlotNode-rooted tree', () {
            final root = SlotNode(
              id: 'outer',
              persistent: true,
              child: SplitNode(
                id: 'inner',
                axis: .horizontal,
                children: [
                  TabGroupNode(
                    id: 'left',
                    tabs: treeTabs([tab('a')]),
                    size: const .resizable(initial: .fraction(1)),
                  ),
                  TabGroupNode(
                    id: 'right',
                    tabs: treeTabs([tab('b')]),
                    size: const .resizable(initial: .fraction(1)),
                  ),
                ],
              ),
            );

            final next = root.dropLeaf(tab('c'), 'right', DropZone.right)!;
            final inner = (next as SlotNode).child! as SplitNode;

            expect(
              inner.children[1].size,
              const PlatSize.resizable(initial: .fraction(0.5)),
            );
            expect(
              inner.children[2].size,
              const PlatSize.resizable(initial: .fraction(0.5)),
            );
          });
        });

        group('locked dividers', () {
          test('nests a new split when the parent is not resizable', () {
            final root = SplitNode(
              id: 'root',
              axis: .horizontal,
              resizable: false,
              children: [
                TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
                TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
              ],
            );

            final next =
                root.dropLeaf(tab('c'), 'right', DropZone.right)! as SplitNode;

            expect(next.children, hasLength(2));
            expect(next.children.last, isA<SplitNode>());
          });
        });

        group('self drop', () {
          test('center self-drop with no insertAt returns same instance', () {
            final root = TabGroupNode(
              id: 'group',
              tabs: treeTabs([tab('a'), tab('b')]),
            );

            final next = root.dropLeaf(tab('a'), 'group', DropZone.center);

            expect(next, same(root));
          });

          test('center self-drop with insertAt reorders within the group', () {
            final root = TabGroupNode(
              id: 'group',
              tabs: treeTabs([tab('a'), tab('b'), tab('c')]),
            );

            final next = root.dropLeaf(
              tab('a'),
              'group',
              DropZone.center,
              insertAt: 2,
            );

            expect(leafIds((next! as TabGroupNode).tabs), ['b', 'a', 'c']);
          });

          test('edge self-drop is a no-op when the leaf is the sole tab', () {
            final root = TabGroupNode(id: 'group', tabs: treeTabs([tab('a')]));

            final next = root.dropLeaf(tab('a'), 'group', DropZone.right);

            expect(next, same(root));
          });
        });

        group('relocation', () {
          test(
            'places without removing when leaf is unknown to the receiver',
            () {
              final root = TabGroupNode(
                id: 'group',
                tabs: treeTabs([tab('a')]),
              );

              final next = root.dropLeaf(
                tab('foreign'),
                'group',
                DropZone.center,
              );

              expect(leafIds((next! as TabGroupNode).tabs), ['a', 'foreign']);
            },
          );

          test(
            'removes the leaf from its origin TabGroupNode when relocating',
            () {
              final root = TabGroupNode(
                id: 'group',
                tabs: treeTabs([tab('a'), tab('b')]),
              );

              final next = root.dropLeaf(tab('b'), 'group', DropZone.right)!;

              final splits = next as SplitNode;
              expect(leafIds((splits.children[0] as TabGroupNode).tabs), ['a']);
              expect(leafIds((splits.children[1] as TabGroupNode).tabs), ['b']);
            },
          );
        });
      });

      group('focus', () {
        test('sets focused on exactly one leaf and clears the rest', () {
          final root = TabGroupNode(
            id: 'group',
            tabs: treeTabs([
              tab('a').copyWith(focused: true),
              tab('b'),
              tab('c'),
            ]),
          );

          final next = root.focus('c') as TabGroupNode;

          expect(next.tabs[0].focused(), isFalse);
          expect(next.tabs[1].focused(), isFalse);
          expect(next.tabs[2].focused(), isTrue);
        });

        test(
          'updates the enclosing TabGroupNode activeIndex to the focused leaf',
          () {
            final root = TabGroupNode(
              id: 'group',
              tabs: treeTabs([tab('a'), tab('b'), tab('c')]),
            );

            final next = root.focus('c') as TabGroupNode;

            expect(next.activeIndex, 2);
          },
        );

        test('returns the same instance when focus already matches', () {
          final root = TabGroupNode(
            id: 'group',
            tabs: treeTabs([tab('a').copyWith(focused: true), tab('b')]),
          );

          expect(root.focus('a'), same(root));
        });
      });

      group('maximize', () {
        test('marks exactly the named node maximized, clearing any previous '
            'flag', () {
          final root = hSplit('root', [
            TabGroupNode(
              id: 'left',
              tabs: treeTabs([tab('a')]),
              maximized: true,
            ),
            TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
          ]);

          final next = root.maximize('right') as SplitNode;

          expect(next.children[0].maximized, isFalse);
          expect(next.children[1].maximized, isTrue);
        });
      });

      group('restore', () {
        test('clears every maximize flag', () {
          final root = hSplit('root', [
            TabGroupNode(
              id: 'left',
              tabs: treeTabs([tab('a')]),
              maximized: true,
            ),
            TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
          ]);

          final next = root.restore() as SplitNode;

          expect(_maximizedChildIds(next), isEmpty);
        });

        test('returns the same instance when nothing was maximized', () {
          final root = hSplit('root', [
            TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
            TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
          ]);

          expect(root.restore(), same(root));
        });
      });

      group('hide / show', () {
        test('hide sets the hidden flag on every concrete subtype', () {
          expect(
            TabGroupNode(id: 't', tabs: treeTabs([tab('a')])).hide().hidden,
            isTrue,
          );
          expect(SlotNode(id: 's', persistent: true).hide().hidden, isTrue);
          expect(
            hSplit('sp', [
              TabGroupNode(id: 'a', tabs: treeTabs([tab('a')])),
              TabGroupNode(id: 'b', tabs: treeTabs([tab('b')])),
            ]).hide().hidden,
            isTrue,
          );
          expect(tab('a').hide().hidden, isTrue);
        });

        test('hide returns the same instance when already hidden', () {
          final t = TabGroupNode(
            id: 't',
            tabs: treeTabs([tab('a')]),
            hidden: true,
          );

          expect(t.hide(), same(t));
        });

        test('show clears the hidden flag', () {
          final t = TabGroupNode(
            id: 't',
            tabs: treeTabs([tab('a')]),
            hidden: true,
          );

          expect(t.show().hidden, isFalse);
        });

        test('show returns the same instance when already visible', () {
          final t = TabGroupNode(id: 't', tabs: treeTabs([tab('a')]));

          expect(t.show(), same(t));
        });
      });
    });

    group('cleanTree', () {
      test('returns the input unchanged when nothing needs cleaning', () {
        final treeInNormalForm = hSplit('root', [
          TabGroupNode(id: 'left', tabs: treeTabs([tab('a')])),
          TabGroupNode(id: 'right', tabs: treeTabs([tab('b')])),
        ]);
        final standalone = tab('a');

        expect(treeInNormalForm.cleanTree(), same(treeInNormalForm));
        expect(standalone.cleanTree(), same(standalone));
      });

      test('returns null when the tree collapses entirely', () {
        expect(TabGroupNode.empty().cleanTree(), isNull);
        expect(SlotNode(id: 's').cleanTree(), isNull);
        expect(
          SlotNode(
            id: 's',
            child: TabGroupNode.empty(id: 'group'),
          ).cleanTree(),
          isNull,
        );
        expect(
          SplitNode(
            id: 'outer',
            axis: .horizontal,
            children: [
              TabGroupNode.empty(id: 'a'),
              TabGroupNode.empty(id: 'b'),
            ],
          ).cleanTree(),
          isNull,
        );
      });

      test('keeps a persistent SlotNode as a stub when its child is gone', () {
        final directlyEmpty =
            SlotNode(id: 's', persistent: true).cleanTree()! as SlotNode;
        final childCollapses =
            SlotNode(
                  id: 's',
                  persistent: true,
                  child: TabGroupNode.empty(id: 'group'),
                ).cleanTree()!
                as SlotNode;

        expect(directlyEmpty.child, isNull);
        expect(childCollapses.id, 's');
        expect(childCollapses.child, isNull);
      });

      test('inlines a same-axis nested resizable SplitNode', () {
        final root = hSplit('outer', [
          TabGroupNode(id: 'left', tabs: treeTabs([tab('left')])),
          hSplit('inner', [
            TabGroupNode(id: 'a', tabs: treeTabs([tab('a')])),
            TabGroupNode(id: 'b', tabs: treeTabs([tab('b')])),
          ]),
        ]);

        final next = root.cleanTree()! as SplitNode;

        expect(next.findNode('inner'), isNull);
        expect(next.children, hasLength(3));
      });

      test('keeps a same-axis nested SplitNode when either side is not '
          'resizable', () {
        final innerLocked = hSplit('outer-b', [
          TabGroupNode(id: 'right', tabs: treeTabs([tab('right')])),
          SplitNode(
            id: 'inner-b',
            axis: .horizontal,
            resizable: false,
            children: [
              TabGroupNode(id: 'b1', tabs: treeTabs([tab('b1')])),
              TabGroupNode(id: 'b2', tabs: treeTabs([tab('b2')])),
            ],
          ),
        ]);

        expect(
          (innerLocked.cleanTree()! as SplitNode).findNode('inner-b'),
          isA<SplitNode>(),
        );
      });

      test('unwraps a single-child SplitNode and carries the wrapper size '
          'onto the survivor', () {
        final outer = SplitNode(
          id: 'outer',
          axis: .horizontal,
          size: const .fixed(.pixel(200)),
          children: [
            TabGroupNode(id: 'keep', tabs: treeTabs([tab('a')])),
            TabGroupNode(id: 'drop'),
          ],
        );

        final next = outer.cleanTree();

        expect(next, isA<TabGroupNode>());
        expect((next! as TabGroupNode).id, 'keep');
        expect(next.size, const PlatSize.fixed(.pixel(200)));
      });
    });
  });
}

List<String> leafIds(Iterable<Object> items) => [
  for (final item in items)
    switch (item) {
      final LeafNode leaf => leaf.id,
      final TabNode tab => tab.id,
      _ => throw ArgumentError('Unsupported item: $item'),
    },
];

List<String> _previewTabIds(TabGroupNode group) => [
  for (final tab in group.tabs)
    if (tab.preview) tab.id,
];

List<String> _maximizedChildIds(SplitNode split) => [
  for (final child in split.children)
    if (child.maximized) child.id,
];

PlatSide? _sideFromZone(DropZone zone) => switch (zone) {
  DropZone.center => null,
  DropZone.left => .left,
  DropZone.right => .right,
  DropZone.top => .top,
  DropZone.bottom => .bottom,
};

TabNode _treeTabFromLeaf(LeafNode leaf) =>
    TabNode(child: leaf, title: leaf.title, locked: leaf.locked);

extension _PaneNodeTestCompat on PlatNode {
  PlatNode addLeafTo(
    String? targetId,
    LeafNode leaf, {
    String? focusedHint,
    int? insertAt,
    bool activate = true,
  }) {
    final tab = _treeTabFromLeaf(leaf);
    if (targetId == null) {
      return TabGroupNode(id: generateNodeId(), tabs: [tab]);
    }

    final target = findNode(targetId);
    return switch (target) {
      TabGroupNode() => insertTab(
        targetId,
        tab,
        index: insertAt,
        activate: activate,
      ),
      final SlotNode s when s.child == null => setSlotChild(
        targetId,
        TabGroupNode(id: generateNodeId(), tabs: [tab]),
      )!,
      final SlotNode s => addLeafTo(
        s.child!.id,
        leaf,
        focusedHint: focusedHint,
        insertAt: insertAt,
        activate: activate,
      ),
      final SplitNode s => () {
        final hinted = focusedHint == null ? null : s.findNode(focusedHint);
        final tabsGroup =
            (hinted is TabGroupNode ? hinted : null) ?? s.tabGroups.firstOrNull;
        if (tabsGroup != null) {
          return insertTab(
            tabsGroup.id,
            tab,
            index: insertAt,
            activate: activate,
          );
        }
        return insertChild(
          s.id,
          TabGroupNode(id: generateNodeId(), tabs: [tab]),
        );
      }(),
      _ => throw StateError(
        '$targetId is not a TabGroupNode / SlotNode / SplitNode',
      ),
    };
  }

  PlatNode? dropLeaf(
    LeafNode leaf,
    String targetId,
    DropZone zone, {
    int? insertAt,
  }) {
    final target = findNode(targetId);
    if (target == null) return this;

    final tab = _treeTabFromLeaf(leaf);
    final origin = directTabOf(leaf.id);
    if (zone == DropZone.center) {
      return switch (target) {
        TabGroupNode() => () {
          if (origin != null && origin.group.id == targetId) {
            if (insertAt == null) return this;
            return reorderTab(
              origin.group.id,
              origin.index,
              insertAt > origin.index ? insertAt - 1 : insertAt,
            );
          }
          if (origin != null) {
            return moveTab(leaf.id, targetId, index: insertAt);
          }
          return insertTab(targetId, tab, index: insertAt);
        }(),
        final SlotNode slot when slot.child == null => () {
          final nextTabs = TabGroupNode(id: generateNodeId(), tabs: [tab]);
          if (origin == null) return setSlotChild(slot.id, nextTabs);
          final removed = removeTab(leaf.id);
          if (removed == null) return null;
          return removed.setSlotChild(slot.id, nextTabs)?.focus(leaf.id);
        }(),
        _ => this,
      };
    }

    final side = _sideFromZone(zone)!;
    if (origin == null) {
      return split(
        targetId,
        side,
        TabGroupNode(id: generateNodeId(), tabs: [tab]),
      );
    }
    if (origin.tab.child.findNode(targetId) != null) return this;
    if (targetId == origin.group.id && origin.group.tabs.length == 1) {
      return this;
    }

    final removed = removeTab(leaf.id);
    if (removed == null) return null;
    return removed
        .split(targetId, side, TabGroupNode(id: generateNodeId(), tabs: [tab]))
        .focus(leaf.id);
  }

  PlatNode insertLeaf(
    String tabGroupId,
    LeafNode leaf, {
    int? insertAt,
    bool activate = true,
  }) => insertTab(
    tabGroupId,
    _treeTabFromLeaf(leaf),
    index: insertAt,
    activate: activate,
  );

  PlatNode? moveLeaf(
    String leafId,
    String destinationTabGroupId, {
    int? insertAt,
    bool activate = true,
  }) => moveTab(
    leafId,
    destinationTabGroupId,
    index: insertAt,
    activate: activate,
  );

  PlatNode? removeLeaf(String leafId) => remove(leafId);

  PlatNode reorderLeaf(String tabGroupId, int from, int to) =>
      reorderTab(tabGroupId, from, to);
}
