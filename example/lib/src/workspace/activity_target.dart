import 'package:material_ui/material_ui.dart';
import 'package:plat/plat.dart';

const List<ThemePanelTarget> leftPanelTargets = [.navigator, .assets];

const List<ThemePanelTarget> rightPanelTargets = [.outline, .details];

enum ThemePanelTarget({
  required final String slotId,
  required final String leafId,
  required final String title,
  required final IconData icon,
}) {
  navigator(
    slotId: 'left-slot',
    leafId: 'nav',
    title: 'Navigator',
    icon: Icons.folder_outlined,
  ),
  assets(
    slotId: 'left-slot',
    leafId: 'assets',
    title: 'Assets',
    icon: Icons.image_outlined,
  ),
  outline(
    slotId: 'right-slot',
    leafId: 'outline',
    title: 'Outline',
    icon: Icons.list_alt,
  ),
  details(
    slotId: 'right-slot',
    leafId: 'details',
    title: 'Details',
    icon: Icons.tune,
  );

  Plat get pane => .leaf(id: leafId, title: title, locked: true);
}
