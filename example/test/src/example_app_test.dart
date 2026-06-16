import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plat_example/src/branding.dart';
import 'package:plat_example/src/example_app.dart';

void main() {
  group('PlatExampleApp', () {
    Future<void> pumpExampleApp(WidgetTester tester, [Size? size]) async {
      if (size != null) {
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      }

      await tester.pumpWidget(const PlatExampleApp());
      await tester.pumpAndSettle();
    }

    Future<void> selectOneDarkPro(WidgetTester tester) async {
      await tester.tap(find.text('One Dark Pro'));
      await tester.pumpAndSettle();
    }

    group('workspace shell', () {
      testWidgets('shows the app title and theme selector title', (
        tester,
      ) async {
        await pumpExampleApp(tester);

        expect(find.text(platDemoTitle), findsOneWidget);
        expect(find.bySemanticsLabel('Plat logo'), findsOneWidget);
        expect(find.text('Workspace themes'), findsOneWidget);
      });

      testWidgets('shows the default Material preset', (tester) async {
        await pumpExampleApp(tester);

        expect(find.text('Material'), findsWidgets);
      });

      testWidgets('renders editor tabs', (tester) async {
        await pumpExampleApp(tester);

        expect(find.text('Editor'), findsWidgets);
      });

      testWidgets('renders the terminal group', (tester) async {
        await pumpExampleApp(tester);

        expect(find.text('Terminal'), findsWidgets);
      });
    });

    group('preset switching', () {
      testWidgets('animates a selected preset', (tester) async {
        await pumpExampleApp(tester);

        await tester.tap(find.text('One Dark Pro'));
        await tester.pump();

        expect(tester.hasRunningAnimations, isTrue);
      });

      testWidgets('shows the selected preset description', (tester) async {
        await pumpExampleApp(tester);

        await selectOneDarkPro(tester);

        expect(find.text('Atom-inspired dark workspace'), findsOneWidget);
      });

      testWidgets('keeps editor tabs after a preset change', (tester) async {
        await pumpExampleApp(tester);

        await selectOneDarkPro(tester);

        expect(find.text('Editor'), findsWidgets);
      });

      testWidgets('keeps the terminal group after a preset change', (
        tester,
      ) async {
        await pumpExampleApp(tester);

        await selectOneDarkPro(tester);

        expect(find.text('Terminal'), findsWidgets);
      });
    });

    group('activity actions', () {
      testWidgets('opens the assets group', (tester) async {
        await pumpExampleApp(tester);

        await tester.tap(find.byTooltip('Open assets'));
        await tester.pumpAndSettle();

        expect(find.text('Assets'), findsWidgets);
      });

      testWidgets('opens the details group', (tester) async {
        await pumpExampleApp(tester);

        await tester.tap(find.byTooltip('Open details'));
        await tester.pumpAndSettle();

        expect(find.text('Details'), findsWidgets);
      });

      testWidgets('hides the terminal group', (tester) async {
        await pumpExampleApp(tester);

        await tester.tap(find.byTooltip('Toggle terminal'));
        await tester.pumpAndSettle();

        expect(find.text('Terminal'), findsNothing);
      });

      testWidgets('shows the terminal group after a second toggle', (
        tester,
      ) async {
        await pumpExampleApp(tester);

        await tester.tap(find.byTooltip('Toggle terminal'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Toggle terminal'));
        await tester.pumpAndSettle();

        expect(find.text('Terminal'), findsWidgets);
      });
    });

    group('editor tab actions', () {
      testWidgets('opens a locked tab', (tester) async {
        await pumpExampleApp(tester);

        await tester.tap(find.byTooltip('Open locked tab'));
        await tester.pumpAndSettle();

        expect(find.text('Locked 1'), findsWidgets);
      });

      testWidgets('opens a pinned tab', (tester) async {
        await pumpExampleApp(tester);

        await tester.tap(find.byTooltip('Open pinned tab'));
        await tester.pumpAndSettle();

        expect(find.text('Pinned 1'), findsWidgets);
      });

      testWidgets('opens a preview tab', (tester) async {
        await pumpExampleApp(tester);

        await tester.tap(find.byTooltip('Open preview tab'));
        await tester.pumpAndSettle();

        expect(find.text('Preview 1'), findsWidgets);
      });
    });

    group('drop policy', () {
      testWidgets('rejects editor tabs in bottom groups', (tester) async {
        await pumpExampleApp(tester, const Size(1200, 820));

        final from = tester.getCenter(find.text('Editor').first);
        final to = tester.getCenter(find.text('Terminal').first);
        await tester.dragFrom(from, to - from);
        await tester.pumpAndSettle();

        expect(find.text('Editor'), findsNWidgets(2));
      });
    });

    group('responsive layout', () {
      testWidgets('renders at compact width', (tester) async {
        await pumpExampleApp(tester, const Size(390, 720));

        expect(find.text('Workspace themes'), findsOneWidget);
      });

      testWidgets('renders at wide width', (tester) async {
        await pumpExampleApp(tester, const Size(1200, 820));

        expect(find.text('Workspace themes'), findsOneWidget);
      });
    });
  });
}
