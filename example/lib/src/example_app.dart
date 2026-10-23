import 'package:material_ui/material_ui.dart';

import 'branding.dart';
import 'workspace/workspace.dart';

final class const PlatExampleApp({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: platDemoTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const Scaffold(body: WorkspaceExample()),
    );
  }
}
