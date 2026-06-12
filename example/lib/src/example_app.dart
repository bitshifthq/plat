import 'package:flutter/material.dart';

import 'workspace/workspace.dart';

final class PlatExampleApp extends StatelessWidget {
  const PlatExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plat workspace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const Scaffold(body: WorkspaceExample()),
    );
  }
}
