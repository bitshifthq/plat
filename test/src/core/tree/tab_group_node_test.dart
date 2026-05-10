import 'package:flutter_test/flutter_test.dart';

import '../../../helpers.dart';

void main() {
  group('TabGroupNode', () {
    group('TabGroupNode', () {
      group('constructor', () {
        test('validates activeIndex bounds', () {
          expect(
            () => TabGroupNode(
              id: 't',
              tabs: treeTabs([tab('a'), tab('b')]),
              activeIndex: 99,
            ),
            throwsA(isA<AssertionError>()),
          );
          expect(
            () => TabGroupNode(
              id: 't',
              tabs: treeTabs([tab('a')]),
              activeIndex: -1,
            ),
            throwsA(isA<AssertionError>()),
          );
          expect(
            () => TabGroupNode(id: 't', activeIndex: 1),
            throwsA(isA<AssertionError>()),
          );
          expect(TabGroupNode(id: 't').activeIndex, 0);
        });

        test('uses the documented defaults', () {
          final tabsNode = TabGroupNode(id: 't', tabs: treeTabs([tab('a')]));

          expect(tabsNode.side, TabBarSide.top);
          expect(tabsNode.acceptsDrops, isTrue);
          expect(tabsNode.hidden, isFalse);
          expect(tabsNode.activeIndex, 0);
        });
      });

      group('TabGroupNode.empty', () {
        test('creates an empty group and preserves explicit ids', () {
          final explicit = TabGroupNode.empty(id: 'stub');
          final generatedA = TabGroupNode.empty();
          final generatedB = TabGroupNode.empty();

          expect(explicit.tabs, isEmpty);
          expect(explicit.activeLeaf(), isNull);
          expect(explicit.id, 'stub');
          expect(generatedA.id, isNot(generatedB.id));
        });
      });

      group('activeLeaf', () {
        test('returns the active leaf or null when the group is empty', () {
          final populated = TabGroupNode(
            id: 't',
            tabs: treeTabs([tab('a'), tab('b'), tab('c')]),
            activeIndex: 1,
          );

          expect(populated.activeLeaf()?.id, 'b');
          expect(TabGroupNode.empty().activeLeaf(), isNull);
        });
      });

      group('copyWith', () {
        test('overrides provided fields and preserves untouched ones', () {
          final original = TabGroupNode(
            id: 't',
            tabs: treeTabs([tab('a')]),
            side: .right,
          );

          final updated = original.copyWith(
            side: .left,
            acceptsDrops: false,
            activeIndex: 0,
          );

          expect(updated.side, TabBarSide.left);
          expect(updated.acceptsDrops, isFalse);
          expect(updated.activeIndex, 0);
          expect(updated.id, original.id);
          expect(updated.tabs, original.tabs);
        });

        test('preserves size when the tabs list becomes empty', () {
          final original = TabGroupNode(
            id: 't',
            tabs: treeTabs([tab('a')]),
            size: const .resizable(initial: .fraction(0.6)),
          );

          final emptied = original.copyWith(tabs: const []);

          expect(emptied.tabs, isEmpty);
          expect(
            emptied.size,
            const PlatSize.resizable(initial: .fraction(0.6)),
          );
        });
      });

      test('toString reports the tab count, active index, and side', () {
        expect(
          TabGroupNode(
            id: 't',
            tabs: treeTabs([tab('a'), tab('b')]),
            activeIndex: 1,
            side: .bottom,
          ).toString(),
          'TabGroupNode(t, 2 tabs, active=1, side=TabBarSide.bottom)',
        );
      });
    });

    group('TabBarSide', () {
      test('reports horizontal and vertical sides consistently', () {
        expect(TabBarSide.top.isHorizontal, isTrue);
        expect(TabBarSide.bottom.isHorizontal, isTrue);
        expect(TabBarSide.left.isVertical, isTrue);
        expect(TabBarSide.right.isVertical, isTrue);
        expect(TabBarSide.top.isVertical, isFalse);
        expect(TabBarSide.left.isHorizontal, isFalse);
      });
    });
  });
}
