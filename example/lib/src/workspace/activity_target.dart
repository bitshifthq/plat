import 'package:flutter/material.dart';
import 'package:plat/plat.dart';

const List<ThemePanelTarget> leftPanelTargets = [.navigator, .assets];

const List<ThemePanelTarget> rightPanelTargets = [.outline, .details];

enum ThemePanelTarget {
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

  final String slotId;
  final String leafId;
  final String title;
  final IconData icon;

  const ThemePanelTarget({
    required this.slotId,
    required this.leafId,
    required this.title,
    required this.icon,
  });

  Plat get pane => .leaf(id: leafId, title: title, locked: true);
}
