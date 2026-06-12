import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plat_example/src/workspace/presets.dart';
import 'package:plat_example/src/workspace/workspace.dart';

void main() {
  group('WorkspaceExample', () {
    const goldenKey = Key('workspace-golden');

    Future<void> pumpWorkspace(
      WidgetTester tester,
      ThemePreset preset, {
      Size size = const Size(390, 720),
    }) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        RepaintBoundary(
          key: goldenKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: WorkspaceExample(initialPreset: preset)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> expectWorkspaceGolden(
      WidgetTester tester,
      ThemePreset preset,
      String fileName, {
      Size size = const Size(390, 720),
    }) async {
      await pumpWorkspace(tester, preset, size: size);

      await expectLater(find.byKey(goldenKey), matchesGoldenFile(fileName));
    }

    Future<void> expectDropHintGolden(
      WidgetTester tester,
      ThemePreset preset,
      String fileName,
    ) async {
      await pumpWorkspace(tester, preset, size: const Size(1200, 820));

      final source = tester.getCenter(find.text('Editor').first);
      final target = tester.getCenter(find.text('Editor').last);
      final gesture = await tester.startGesture(source);
      addTearDown(gesture.up);
      await tester.pump();
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.moveTo(target);
      await tester.pumpAndSettle();

      await expectLater(find.byKey(goldenKey), matchesGoldenFile(fileName));
    }

    Future<void> expectResponsiveRender(
      WidgetTester tester,
      ThemePreset preset,
      Size size,
    ) async {
      await pumpWorkspace(tester, preset, size: size);

      expect(find.byKey(goldenKey), findsOneWidget);
    }

    group('compact width', () {
      testWidgets('renders Material', (tester) async {
        await expectWorkspaceGolden(
          tester,
          .material,
          '../../goldens/workspace_material_compact.png',
        );
      });

      testWidgets('renders Compact', (tester) async {
        await expectWorkspaceGolden(
          tester,
          .compact,
          '../../goldens/workspace_compact_compact.png',
        );
      });

      testWidgets('renders IntelliJ IDEA', (tester) async {
        await expectWorkspaceGolden(
          tester,
          .idea,
          '../../goldens/workspace_idea_compact.png',
        );
      });

      testWidgets('renders Dracula', (tester) async {
        await expectWorkspaceGolden(
          tester,
          .dracula,
          '../../goldens/workspace_dracula_compact.png',
        );
      });

      testWidgets('renders One Dark Pro', (tester) async {
        await expectWorkspaceGolden(
          tester,
          .oneDark,
          '../../goldens/workspace_oneDark_compact.png',
        );
      });
    });

    group('wide width', () {
      testWidgets('renders Material', (tester) async {
        await expectWorkspaceGolden(
          tester,
          .material,
          '../../goldens/workspace_material_wide.png',
          size: const Size(1200, 820),
        );
      });

      testWidgets('renders Compact', (tester) async {
        await expectWorkspaceGolden(
          tester,
          .compact,
          '../../goldens/workspace_compact_wide.png',
          size: const Size(1200, 820),
        );
      });

      testWidgets('renders IntelliJ IDEA', (tester) async {
        await expectWorkspaceGolden(
          tester,
          .idea,
          '../../goldens/workspace_idea_wide.png',
          size: const Size(1200, 820),
        );
      });

      testWidgets('renders Dracula', (tester) async {
        await expectWorkspaceGolden(
          tester,
          .dracula,
          '../../goldens/workspace_dracula_wide.png',
          size: const Size(1200, 820),
        );
      });

      testWidgets('renders One Dark Pro', (tester) async {
        await expectWorkspaceGolden(
          tester,
          .oneDark,
          '../../goldens/workspace_oneDark_wide.png',
          size: const Size(1200, 820),
        );
      });
    });

    group('drop hint', () {
      testWidgets('renders Material', (tester) async {
        await expectDropHintGolden(
          tester,
          .material,
          '../../goldens/workspace_material_drop_hint_wide.png',
        );
      });

      testWidgets('renders Compact', (tester) async {
        await expectDropHintGolden(
          tester,
          .compact,
          '../../goldens/workspace_compact_drop_hint_wide.png',
        );
      });

      testWidgets('renders IntelliJ IDEA', (tester) async {
        await expectDropHintGolden(
          tester,
          .idea,
          '../../goldens/workspace_idea_drop_hint_wide.png',
        );
      });
    });

    group('320px width', () {
      testWidgets('renders Material', (tester) async {
        await expectResponsiveRender(tester, .material, const Size(320, 640));
      });

      testWidgets('renders Compact', (tester) async {
        await expectResponsiveRender(tester, .compact, const Size(320, 640));
      });

      testWidgets('renders IntelliJ IDEA', (tester) async {
        await expectResponsiveRender(tester, .idea, const Size(320, 640));
      });

      testWidgets('renders Dracula', (tester) async {
        await expectResponsiveRender(tester, .dracula, const Size(320, 640));
      });

      testWidgets('renders One Dark Pro', (tester) async {
        await expectResponsiveRender(tester, .oneDark, const Size(320, 640));
      });
    });

    group('390px width', () {
      testWidgets('renders Material', (tester) async {
        await expectResponsiveRender(tester, .material, const Size(390, 720));
      });

      testWidgets('renders Compact', (tester) async {
        await expectResponsiveRender(tester, .compact, const Size(390, 720));
      });

      testWidgets('renders IntelliJ IDEA', (tester) async {
        await expectResponsiveRender(tester, .idea, const Size(390, 720));
      });

      testWidgets('renders Dracula', (tester) async {
        await expectResponsiveRender(tester, .dracula, const Size(390, 720));
      });

      testWidgets('renders One Dark Pro', (tester) async {
        await expectResponsiveRender(tester, .oneDark, const Size(390, 720));
      });
    });

    group('640px width', () {
      testWidgets('renders Material', (tester) async {
        await expectResponsiveRender(tester, .material, const Size(640, 720));
      });

      testWidgets('renders Compact', (tester) async {
        await expectResponsiveRender(tester, .compact, const Size(640, 720));
      });

      testWidgets('renders IntelliJ IDEA', (tester) async {
        await expectResponsiveRender(tester, .idea, const Size(640, 720));
      });

      testWidgets('renders Dracula', (tester) async {
        await expectResponsiveRender(tester, .dracula, const Size(640, 720));
      });

      testWidgets('renders One Dark Pro', (tester) async {
        await expectResponsiveRender(tester, .oneDark, const Size(640, 720));
      });
    });

    group('960px width', () {
      testWidgets('renders Material', (tester) async {
        await expectResponsiveRender(tester, .material, const Size(960, 720));
      });

      testWidgets('renders Compact', (tester) async {
        await expectResponsiveRender(tester, .compact, const Size(960, 720));
      });

      testWidgets('renders IntelliJ IDEA', (tester) async {
        await expectResponsiveRender(tester, .idea, const Size(960, 720));
      });

      testWidgets('renders Dracula', (tester) async {
        await expectResponsiveRender(tester, .dracula, const Size(960, 720));
      });

      testWidgets('renders One Dark Pro', (tester) async {
        await expectResponsiveRender(tester, .oneDark, const Size(960, 720));
      });
    });

    group('1200px width', () {
      testWidgets('renders Material', (tester) async {
        await expectResponsiveRender(tester, .material, const Size(1200, 820));
      });

      testWidgets('renders Compact', (tester) async {
        await expectResponsiveRender(tester, .compact, const Size(1200, 820));
      });

      testWidgets('renders IntelliJ IDEA', (tester) async {
        await expectResponsiveRender(tester, .idea, const Size(1200, 820));
      });

      testWidgets('renders Dracula', (tester) async {
        await expectResponsiveRender(tester, .dracula, const Size(1200, 820));
      });

      testWidgets('renders One Dark Pro', (tester) async {
        await expectResponsiveRender(tester, .oneDark, const Size(1200, 820));
      });
    });
  });
}
