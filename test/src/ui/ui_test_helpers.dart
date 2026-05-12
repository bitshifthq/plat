import 'package:flutter/material.dart' show Theme, ThemeData;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plat/plat.dart';

Future<void> pumpPlatView(
  WidgetTester tester,
  PlatController controller, {
  Size size = const Size(320, 200),
  LeafBuilder? leafBuilder,
  PlatTabBarBuilder? tabBar,
  SlotBuilder? slotBuilder,
  DropPolicy? dropPolicy,
  ThemeData? theme,
  bool autofocus = true,
}) async {
  await tester.pumpWidget(
    testHost(
      SizedBox(
        width: size.width,
        height: size.height,
        child: PlatView(
          controller: controller,
          leafBuilder:
              leafBuilder ??
              (_, leaf) => Center(child: Text('body:${leaf.id}')),
          tabBar: tabBar,
          slotBuilder: slotBuilder,
          dropPolicy: dropPolicy,
          autofocus: autofocus,
        ),
      ),
      theme: theme,
    ),
  );
  await tester.pump();
}

Widget testHost(Widget child, {ThemeData? theme, bool overlay = true}) {
  Widget hosted = overlay
      ? Overlay(initialEntries: [OverlayEntry(builder: (_) => child)])
      : child;
  hosted = MediaQuery(
    data: const MediaQueryData(),
    child: Directionality(textDirection: TextDirection.ltr, child: hosted),
  );
  return theme == null ? hosted : Theme(data: theme, child: hosted);
}
