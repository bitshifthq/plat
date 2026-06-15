import 'package:flutter/material.dart' show ThemeData;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plat/plat.dart';

import '../../helpers.dart';
import 'ui_test_helpers.dart';

void main() {
  group('PlatView', () {
    group('goldens', () {
      setUpAll(loadTestFonts);

      group('tabs', () {
        testWidgets('renders a single tab group', (tester) async {
          final controller = controllerFromLeaves([
            const LeafNode(id: 'main', title: 'main.dart'),
            const LeafNode(id: 'readme', title: 'README.md'),
          ]);

          await _pumpGolden(tester, controller);

          await expectLater(
            find.byType(PlatView),
            matchesGoldenFile('goldens/single_tabs.png'),
          );
        });

        testWidgets('renders the tab bar on bottom', (tester) async {
          await _pumpTabsSideGolden(tester, .bottom, tabBarSize: 32);

          await expectLater(
            find.byType(PlatView),
            matchesGoldenFile('goldens/tabs_side_bottom.png'),
          );
        });

        testWidgets('renders the tab bar on left', (tester) async {
          await _pumpTabsSideGolden(tester, .left, tabBarSize: 160);

          await expectLater(
            find.byType(PlatView),
            matchesGoldenFile('goldens/tabs_side_left.png'),
          );
        });

        testWidgets('renders the tab bar on right', (tester) async {
          await _pumpTabsSideGolden(tester, .right, tabBarSize: 160);

          await expectLater(
            find.byType(PlatView),
            matchesGoldenFile('goldens/tabs_side_right.png'),
          );
        });
      });

      group('splits', () {
        testWidgets('renders a horizontal split', (tester) async {
          final controller = controllerFromLeaves([
            const LeafNode(id: 'a', title: 'main.dart'),
            const LeafNode(id: 'b', title: 'lib/util.dart'),
          ]);
          controller.focus('b');
          controller.splitActiveTab(
            tabGroupId: controller.rootId,
            side: .right,
          );

          await _pumpGolden(tester, controller);

          await expectLater(
            find.byType(PlatView),
            matchesGoldenFile('goldens/horizontal_split.png'),
          );
        });

        testWidgets('renders a nested split', (tester) async {
          final controller = controllerFromLeaves([
            const LeafNode(id: 'top', title: 'top'),
            const LeafNode(id: 'bottom', title: 'bottom'),
          ]);
          controller.focus('bottom');
          controller.splitActiveTab(
            tabGroupId: controller.rootId,
            side: .bottom,
          );

          final bottomGroupId = controller.tabGroupContaining('bottom')!;
          controller.insertTabBeside(
            targetId: bottomGroupId,
            side: .right,
            tab: tabPaneWith(id: 'br', title: 'bottom-right'),
          );

          await _pumpGolden(tester, controller);

          await expectLater(
            find.byType(PlatView),
            matchesGoldenFile('goldens/nested_split.png'),
          );
        });

        testWidgets('renders a maximized leaf', (tester) async {
          final controller = controllerFromLeaves([
            const LeafNode(id: 'a', title: 'main.dart'),
            const LeafNode(id: 'b', title: 'lib/util.dart'),
          ]);
          controller.focus('b');
          controller.splitActiveTab(
            tabGroupId: controller.rootId,
            side: .right,
          );
          controller.setMaximized(
            controller.tabGroupContaining('b')!,
            maximized: true,
          );

          await _pumpGolden(tester, controller);

          await expectLater(
            find.byType(PlatView),
            matchesGoldenFile('goldens/maximized_leaf.png'),
          );
        });
      });
    });
  });
}

Future<void> _pumpGolden(
  WidgetTester tester,
  PlatController controller, {
  PlatThemeData? theme,
}) async {
  await tester.binding.setSurfaceSize(const Size(640, 360));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  Widget child = PlatView(
    controller: controller,
    leafBuilder: (_, leaf) => ColoredBox(
      color: const Color(0xFF202020),
      child: Center(
        child: Text(
          leaf.title,
          style: const TextStyle(
            color: Color(0xFFEAEAEA),
            fontFamily: 'Roboto',
            fontSize: 14,
          ),
        ),
      ),
    ),
  );
  if (theme != null) {
    child = PlatTheme(data: theme, child: child);
  }

  await tester.pumpWidget(
    testHost(
      ColoredBox(color: const Color(0xFF101010), child: child),
      theme: ThemeData(fontFamily: 'Roboto'),
    ),
  );
  await tester.pump();
}

Future<void> _pumpTabsSideGolden(
  WidgetTester tester,
  TabBarSide side, {
  required double tabBarSize,
}) async {
  final controller = controllerFromLeaves([
    const LeafNode(id: 'main', title: 'main.dart'),
    const LeafNode(id: 'readme', title: 'README.md'),
  ]);
  controller.setTabBarSide(controller.rootId, side);

  await _pumpGolden(
    tester,
    controller,
    theme: PlatThemeData(tabBar: PlatTabBarTheme(size: tabBarSize)),
  );
}
