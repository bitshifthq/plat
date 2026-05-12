import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plat/plat.dart';

import '../../helpers.dart';
import 'ui_test_helpers.dart';

void main() {
  group('SlotBuilder', () {
    testWidgets('non-empty slot receives the SlotSnapshot', (tester) async {
      final controller = _slotController();
      addTearDown(controller.dispose);

      await pumpPlatView(tester, controller, slotBuilder: _slotBody);

      expect(find.text('slot:slot'), findsOneWidget);
    });

    testWidgets('non-empty slot receives the built child widget', (
      tester,
    ) async {
      final controller = _slotController();
      addTearDown(controller.dispose);

      await pumpPlatView(tester, controller, slotBuilder: _slotBody);

      expect(find.text('body:a'), findsOneWidget);
    });
  });
}

Widget _slotBody(BuildContext context, SlotSnapshot slot, Widget? child) {
  return Column(
    children: [
      Text('slot:${slot.id}'),
      Expanded(child: child ?? const SizedBox()),
    ],
  );
}

PlatController _slotController() {
  return controllerFromTree(
    SlotNode(
      id: 'slot',
      persistent: true,
      child: TabGroupNode(id: 'group', tabs: treeTabs([tab('a')])),
    ),
  );
}
