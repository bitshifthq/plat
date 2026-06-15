import 'dart:io';

import 'package:flutter/services.dart';

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
