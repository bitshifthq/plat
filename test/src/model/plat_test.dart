import 'package:flutter_test/flutter_test.dart';
import 'package:plat/plat.dart';

import '../../helpers.dart';

void main() {
  group('Plat', () {
    group('public naming', () {
      test('uses tab and tab group names for declarations', () {
        final node = PlatTabGroup(
          [tabPaneWith(id: 'a', title: 'a')],
          id: 'group',
          side: .right,
        );

        expect(node, isA<PlatTabGroup>());
        expect(node.tabs.single, isA<PlatTab>());
        expect(node.side, TabBarSide.right);
      });

      test(
        'Plat.tabs keeps the concise factory while returning a tab group',
        () {
          final node = Plat.tabs([
            tabPaneWith(id: 'a', title: 'a'),
          ], id: 'group');

          expect(node, isA<PlatTabGroup>());
        },
      );
    });

    group('Plat', () {
      group('id assignment', () {
        test('uses the provided id', () {
          const node = PlatTabGroup([], id: 'group');

          expect(node.id, 'group');
        });

        test('ids are optional in public layout descriptions', () {
          final node = Plat.tabs([tabPaneWith(title: 'a')]);

          expect(node.id, isNull);
          expect((node as PlatTabGroup).tabs.single.id, isNull);
        });
      });

      group('factory redirects', () {
        test('Plat.row produces a horizontal PlatSplit', () {
          final node = Plat.row(
            id: 'row',
            children: [
              PlatTabGroup([tabPaneWith(id: 'a', title: 'a')], id: 'a-group'),
              PlatTabGroup([tabPaneWith(id: 'b', title: 'b')], id: 'b-group'),
            ],
          );

          expect(node, isA<PlatSplit>());
          expect((node as PlatSplit).axis, SplitAxis.horizontal);
        });

        test('Plat.column produces a vertical PlatSplit', () {
          final node = Plat.column(
            id: 'col',
            children: [
              PlatTabGroup([tabPaneWith(id: 'a', title: 'a')], id: 'a-group'),
              PlatTabGroup([tabPaneWith(id: 'b', title: 'b')], id: 'b-group'),
            ],
          );

          expect((node as PlatSplit).axis, SplitAxis.vertical);
        });

        test('Plat.tabs produces a PlatTabGroup', () {
          final node = Plat.tabs([
            tabPaneWith(id: 'a', title: 'a'),
          ], id: 'group');

          expect(node, isA<PlatTabGroup>());
        });

        test('Plat.slot produces a PlatSlot', () {
          const node = Plat.slot(id: 'slot');

          expect(node, isA<PlatSlot>());
        });

        test('Plat.leaf produces a PlatLeaf', () {
          const node = Plat.leaf(id: 'a', title: 'a');

          expect(node, isA<PlatLeaf>());
          expect((node as PlatLeaf).id, 'a');
          expect(node.title, 'a');
        });
      });
    });

    group('PlatSplit', () {
      test('row factory threads resizable through', () {
        final node = PlatSplit.row(
          id: 'row',
          children: [
            PlatTabGroup([tabPaneWith(id: 'a', title: 'a')], id: 'a-group'),
            PlatTabGroup([tabPaneWith(id: 'b', title: 'b')], id: 'b-group'),
          ],
          resizable: false,
        );

        expect(node.axis, SplitAxis.horizontal);
        expect(node.resizable, isFalse);
      });

      test('column factory sets the axis to vertical', () {
        final node = PlatSplit.column(
          id: 'col',
          children: [
            PlatTabGroup([tabPaneWith(id: 'a', title: 'a')], id: 'a-group'),
            PlatTabGroup([tabPaneWith(id: 'b', title: 'b')], id: 'b-group'),
          ],
        );

        expect(node.axis, SplitAxis.vertical);
      });

      test('defaults: resizable, auto size', () {
        final node = PlatSplit.row(
          id: 'row',
          children: [
            PlatTabGroup([tabPaneWith(id: 'a', title: 'a')], id: 'a-group'),
            PlatTabGroup([tabPaneWith(id: 'b', title: 'b')], id: 'b-group'),
          ],
        );

        expect(node.resizable, isTrue);
        expect(node.size, const PlatSize.auto());
      });
    });

    group('PlatTabGroup', () {
      test(
        'defaults: side top, acceptsDrops true, activeIndex 0, auto size',
        () {
          final node = PlatTabGroup([
            tabPaneWith(id: 'a', title: 'a'),
          ], id: 'group');

          expect(node.side, TabBarSide.top);
          expect(node.acceptsDrops, isTrue);
          expect(node.activeIndex, 0);
          expect(node.size, const PlatSize.auto());
        },
      );

      test('preserves tabs, activeIndex, side, acceptsDrops, size', () {
        final node = PlatTabGroup(
          [
            tabPaneWith(id: 'a', title: 'a'),
            const PlatTab(
              title: 'workspace',
              child: .row(
                id: 'workspace',
                children: [
                  .leaf(id: 'left', title: 'left'),
                  .leaf(id: 'right', title: 'right'),
                ],
              ),
              pinned: true,
              locked: true,
            ),
          ],
          id: 'group',
          activeIndex: 1,
          acceptsDrops: false,
          side: .right,
          size: const .fixed(.pixel(200)),
        );

        expect(node.tabs.map((tab) => tab.id), ['a', 'workspace']);
        expect(node.activeIndex, 1);
        expect(node.acceptsDrops, isFalse);
        expect(node.side, TabBarSide.right);
        expect(node.size, const PlatSize.fixed(.pixel(200)));
        expect(node.tabs[1].title, 'workspace');
        expect(node.tabs[1].pinned, isTrue);
        expect(node.tabs[1].locked, isTrue);
      });
    });

    group('PlatTab', () {
      test('uses child id as the tab id', () {
        const tab = PlatTab(
          title: 'editor',
          child: .leaf(id: 'editor', title: 'Editor'),
        );

        expect(tab.id, 'editor');
      });

      test('leaf factory wraps a titled PlatLeaf child', () {
        final tab = PlatTab.leaf(
          id: 'a',
          title: 'a.dart',
          pinned: true,
          locked: true,
          data: 'payload',
        );

        expect(tab.id, 'a');
        expect(tab.title, 'a.dart');
        expect(tab.pinned, isTrue);
        expect(tab.locked, isTrue);
        expect(tab.child, isA<PlatLeaf>());
        expect((tab.child as PlatLeaf).title, 'a.dart');
        expect((tab.child as PlatLeaf).data, 'payload');
      });

      test('preserves preview', () {
        final tab = PlatTab.leaf(id: 'a', title: 'a.dart', preview: true);

        expect(tab.preview, isTrue);
      });

      test('asserts when preview is combined with pinned', () {
        expect(
          () => PlatTab.leaf(
            id: 'a',
            title: 'a.dart',
            pinned: true,
            preview: true,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('asserts when preview is combined with locked', () {
        expect(
          () => PlatTab.leaf(
            id: 'a',
            title: 'a.dart',
            locked: true,
            preview: true,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('PlatSlot', () {
      test('defaults: child null, persistent false, boundsMaximize false', () {
        const node = PlatSlot(id: 'slot');

        expect(node.child, isNull);
        expect(node.persistent, isFalse);
        expect(node.boundsMaximize, isFalse);
      });

      test('preserves persistent, boundsMaximize, and the wrapped child', () {
        final inner = PlatTabGroup([
          tabPaneWith(id: 'a', title: 'a'),
        ], id: 'group');
        final node = PlatSlot(
          id: 'slot',
          persistent: true,
          boundsMaximize: true,
          child: inner,
        );

        expect(node.persistent, isTrue);
        expect(node.boundsMaximize, isTrue);
        expect(node.child, same(inner));
      });
    });

    group('PlatLeaf', () {
      test('carries the provided id and field values', () {
        const node = PlatLeaf(
          id: 'a',
          title: 'a',
          data: 'payload',
          draggable: true,
        );

        expect(node.id, 'a');
        expect(node.title, 'a');
        expect(node.data, 'payload');
        expect(node.draggable, isTrue);
      });

      test('overrides the size when one is given', () {
        const size = PlatSize.fixed(.pixel(40));
        const node = PlatLeaf(id: 'a', size: size);

        expect(node.size, size);
      });
    });
  });
}
