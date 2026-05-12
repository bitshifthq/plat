import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plat/plat.dart';
import 'package:plat/src/ui/shortcuts.dart';

import '../../helpers.dart';
import 'ui_test_helpers.dart';

void main() {
  group('PlatKeyBindings / actionsFor', () {
    group('PlatKeyBindings', () {
      test('desktop maps the published shortcuts', () {
        final activators = PlatKeyBindings.desktop.activators;

        expect(
          _binding(activators, .keyW, control: true),
          isA<CloseTabIntent>(),
        );
        expect(
          _binding(activators, .keyW, control: true, shift: true),
          isA<CloseGroupIntent>(),
        );
        expect(
          _binding(activators, .backslash, control: true),
          const SplitIntent(axis: Axis.horizontal),
        );
        expect(
          _binding(activators, .backslash, control: true, shift: true),
          const SplitIntent(axis: Axis.vertical, side: .bottom),
        );
        expect(
          _binding(activators, .tab, control: true),
          const CycleTabIntent(1),
        );
        expect(
          _binding(activators, .tab, control: true, shift: true),
          const CycleTabIntent(-1),
        );
        expect(
          _binding(activators, .arrowLeft, control: true, alt: true),
          const FocusDirectionIntent(.left),
        );
        expect(
          _binding(activators, .arrowRight, control: true, alt: true),
          const FocusDirectionIntent(.right),
        );
        expect(
          _binding(activators, .enter, control: true, shift: true),
          const MaximizeIntent(),
        );
        expect(
          _binding(activators, .keyZ, control: true),
          const PlatUndoIntent(),
        );
        expect(
          _binding(activators, .keyZ, control: true, shift: true),
          const PlatRedoIntent(),
        );
        expect(
          (_binding(activators, .digit3, control: true) as JumpTabIntent)
              .oneIndex,
          3,
        );
        expect(
          (_binding(activators, .digit9, control: true) as JumpTabIntent)
              .oneIndex,
          9,
        );
      });

      test('mac maps the published shortcuts and platformDefault matches', () {
        final activators = PlatKeyBindings.mac.activators;

        expect(_binding(activators, .keyW, meta: true), isA<CloseTabIntent>());
        expect(
          _binding(activators, .bracketLeft, meta: true),
          const CycleTabIntent(-1),
        );
        expect(
          _binding(activators, .bracketRight, meta: true),
          const CycleTabIntent(1),
        );

        final expected =
            defaultTargetPlatform == .macOS || defaultTargetPlatform == .iOS
            ? PlatKeyBindings.mac
            : PlatKeyBindings.desktop;

        expect(identical(PlatKeyBindings.platformDefault(), expected), isTrue);
      });
    });

    group('actionsFor', () {
      testWidgets('CloseTabIntent closes the focused tab', (tester) async {
        final controller = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(controller.dispose);
        controller.focus('b');

        final context = await _pumpActionsHost(tester, controller);
        await _invoke(tester, context, const CloseTabIntent());

        expect(_leafValues(controller), ['a']);
      });

      testWidgets('CloseGroupIntent closes the focused tab group', (
        tester,
      ) async {
        final controller = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(controller.dispose);
        controller.focus('b');
        controller.splitActiveTab(tabGroupId: controller.rootId, side: .right);

        final context = await _pumpActionsHost(tester, controller);
        await _invoke(tester, context, const CloseGroupIntent());

        expect(_leafValues(controller), ['a']);
      });

      testWidgets('CycleTabIntent wraps through the focused tab group', (
        tester,
      ) async {
        final controller = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(controller.dispose);
        controller.focus('b');

        final context = await _pumpActionsHost(tester, controller);
        await _invoke(tester, context, const CycleTabIntent(1));
        expect(controller.focusedLeaf?.id, 'a');

        await _invoke(tester, context, const CycleTabIntent(-1));
        expect(controller.focusedLeaf?.id, 'b');
      });

      testWidgets(
        'JumpTabIntent activates the requested tab and clamps overflow',
        (tester) async {
          final controller = controllerFromLeaves([
            tab('a'),
            tab('b'),
            tab('c'),
          ]);
          addTearDown(controller.dispose);
          controller.focus('a');

          final context = await _pumpActionsHost(tester, controller);
          await _invoke(tester, context, const JumpTabIntent(2));
          expect(controller.focusedLeaf?.id, 'b');

          await _invoke(tester, context, const JumpTabIntent(9));
          expect(controller.focusedLeaf?.id, 'c');
        },
      );

      testWidgets(
        'FocusDirectionIntent moves between tab groups in tree order',
        (tester) async {
          final controller = controllerFromLeaves([tab('a'), tab('b')]);
          addTearDown(controller.dispose);
          controller.focus('b');
          controller.splitActiveTab(
            tabGroupId: controller.rootId,
            side: .right,
          );

          final leftTabsId = controller.tabGroupContaining('a')!;
          final rightTabsId = controller.tabGroupContaining('b')!;
          controller.focus('a');

          final context = await _pumpActionsHost(tester, controller);
          await _invoke(tester, context, const FocusDirectionIntent(.right));
          expect(controller.focusedTabGroupId(), rightTabsId);

          await _invoke(tester, context, const FocusDirectionIntent(.left));
          expect(controller.focusedTabGroupId(), leftTabsId);
        },
      );

      testWidgets('MaximizeIntent toggles the focused tab group', (
        tester,
      ) async {
        final controller = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(controller.dispose);
        controller.focus('a');

        final tabGroupId = controller.rootId;
        final context = await _pumpActionsHost(tester, controller);
        await _invoke(tester, context, const MaximizeIntent());
        expect(controller.maximizedId(), tabGroupId);

        await _invoke(tester, context, const MaximizeIntent());
        expect(controller.maximizedId(), isNull);
      });

      testWidgets('SplitIntent splits the focused tab beside its group', (
        tester,
      ) async {
        final controller = controllerFromLeaves([tab('a'), tab('b')]);
        addTearDown(controller.dispose);
        controller.focus('b');

        final context = await _pumpActionsHost(tester, controller);
        await _invoke(
          tester,
          context,
          const SplitIntent(axis: Axis.vertical, side: .bottom),
        );

        final root = controller.snapshot(controller.rootId);
        expect(root, isA<SplitSnapshot>());
        expect((root! as SplitSnapshot).axis, SplitAxis.vertical);
        expect(
          controller.tabGroupContaining('a'),
          isNot(controller.tabGroupContaining('b')),
        );
      });

      testWidgets(
        'PlatUndoIntent and PlatRedoIntent replay structural changes',
        (tester) async {
          final controller = controllerFromLeaves([tab('a')]);
          addTearDown(controller.dispose);

          final context = await _pumpActionsHost(tester, controller);
          controller.insertTab(
            tabGroupId: controller.rootId,
            tab: tabPane('b'),
          );
          await tester.pump();

          await _invoke(tester, context, const PlatUndoIntent());
          expect(_leafValues(controller), ['a']);

          await _invoke(tester, context, const PlatRedoIntent());
          expect(_leafValues(controller), ['a', 'b']);
        },
      );
    });
  });
}

Intent _binding(
  Map<ShortcutActivator, Intent> activators,
  LogicalKeyboardKey trigger, {
  bool control = false,
  bool meta = false,
  bool shift = false,
  bool alt = false,
}) {
  return activators.entries.singleWhere((entry) {
    final key = entry.key;
    return key is SingleActivator &&
        key.trigger == trigger &&
        key.control == control &&
        key.meta == meta &&
        key.shift == shift &&
        key.alt == alt;
  }).value;
}

Future<void> _invoke(
  WidgetTester tester,
  BuildContext context,
  Intent intent,
) async {
  Actions.invoke(context, intent);
  await tester.pump();
}

List<String> _leafValues(PlatController controller) => [
  for (final id in controller.leafIds) id,
];

Future<BuildContext> _pumpActionsHost(
  WidgetTester tester,
  PlatController controller,
) async {
  BuildContext? captured;
  await tester.pumpWidget(
    testHost(
      PlatView(
        controller: controller,
        leafBuilder: (context, leaf) {
          captured ??= context;
          return Text('body:${leaf.id}');
        },
      ),
    ),
  );
  await tester.pump();
  return captured!;
}
