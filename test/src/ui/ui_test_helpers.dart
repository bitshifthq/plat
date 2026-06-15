import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart' show Theme, ThemeData;
import 'package:flutter/services.dart' show FontLoader;
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

Future<void> loadTestFonts() async {
  final fontRoot = _flutterRoot().uri.resolve(
    'bin/cache/artifacts/material_fonts/',
  );

  await Future.wait([
    (FontLoader('Roboto')
          ..addFont(_fontData(fontRoot.resolve('Roboto-Regular.ttf')))
          ..addFont(_fontData(fontRoot.resolve('Roboto-Medium.ttf'))))
        .load(),
    (FontLoader('MaterialIcons')
          ..addFont(_fontData(fontRoot.resolve('MaterialIcons-Regular.otf'))))
        .load(),
  ]);
}

Future<ByteData> _fontData(Uri uri) async {
  final bytes = await File.fromUri(uri).readAsBytes();
  return ByteData.sublistView(Uint8List.fromList(bytes));
}

Directory _flutterRoot() {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null && root.isNotEmpty) return Directory(root);

  final executable = File(Platform.resolvedExecutable);
  return executable.parent.parent.parent.parent.parent;
}
