<h1 align="center">
  <img src="https://raw.githubusercontent.com/bitshifthq/plat/main/assets/logo.svg" alt="Plat logo" width="128">
  <br>
  Plat
</h1>

<p align="center">
  Composable pane layouts for Flutter.
  <br>
  Split panes, tab groups, drag-and-drop, and controller-driven workspaces.
</p>

<p align="center">
  <a href="https://pub.dev/packages/plat">
    <img alt="pub package" src="https://img.shields.io/pub/v/plat">
  </a>
  <a href="https://github.com/bitshifthq/plat/actions">
    <img alt="ci" src="https://github.com/bitshifthq/plat/actions/workflows/checks.yml/badge.svg">
  </a>
</p>

<p align="center">
  <a href="#about">About</a> ·
  <a href="#features">Features</a> ·
  <a href="#getting-started">Getting started</a> ·
  <a href="#layout">Layout</a> ·
  <a href="#customization">Customization</a>
</p>

## About

Plat is a highly customizable and flexible package for building workspace
layouts, from simple split panes to complex IDE-style editors. It provides tab
groups, resizable splits, drag-and-drop, snapshots, undoable commands, content
builders, and themeable chrome.

## Features

- **Split workspaces**: Compose rows, columns, slots, leaves, and tab groups.
- **Tab workflows**: Reorder, drag, pin, lock, preview, close, and move tabs.
- **Drag-and-drop layouts**: Move tabs or panes within one view or across views.
- **Resizable panes**: Combine fixed, fractional, auto, minimum, and maximum extents.
- **Controller commands**: Focus, close, insert, split, hide, maximize, undo, and redo.
- **Stable snapshots**: Read layout state by id for rendering and commands.
- **Drop policies**: Accept or reject drops by source controller, target, and zone.
- **Composable styling**: Theme dividers, drop hints, tab bars, and tab chips.
- **Keyboard actions**: Built-in shortcuts for focus and layout operations.

## Getting started

Add `plat` to your app:

```sh
flutter pub add plat
```

Or add it manually:

```yaml
dependencies:
  plat: ^0.1.1
```

Then import the package:

```dart
import 'package:plat/plat.dart';
```

## Layout

A `Plat` tree describes the workspace shape:

- `Plat`: a row, column, tab group, slot, or leaf.
- `Plat.row` / `Plat.column`: split children horizontally or vertically.
- `Plat.tabs`: group tabs and render the active tab's child.
- `PlatTab`: tab metadata such as title, pinned, locked, and preview state.
- `Plat.leaf`: a content endpoint rendered by your `leafBuilder`.
- `Plat.slot`: a region for empty states, stable ids, and scoped maximize.
- `id`: stable string identity for builders, focus, drops, and commands.
- `PlatSize` / `PlatExtent`: fixed, fractional, auto, and resizable space.

```dart
final controller = PlatController(
  initialPlat: .row(
    children: [
      .tabs(
        [
          .leaf(id: 'main', title: 'main.dart'),
          .leaf(id: 'readme', title: 'README.md'),
        ],
        id: 'editors',
      ),
      const .slot(
        id: 'inspector',
        size: .fixed(.pixel(280)),
        child: .leaf(id: 'inspector-pane', title: 'Inspector'),
      ),
    ],
  ),
);
```

## Rendering

`PlatView` renders the controller tree. Build each leaf with your widgets;
Plat renders chrome, tabs, dividers, drops, shortcuts, and focus state. Switch
on `leaf.id`, `leaf.title`, or `leaf.data` when panes need different content.

```dart
PlatView(
  controller: controller,
  leafBuilder: (context, leaf) => switch (leaf.id) {
    'inspector-pane' => InspectorPane(leaf: leaf),
    _ => EditorPane(leaf: leaf),
  },
);
```

## Controller

Use `PlatController` to change the workspace. Structural changes support undo
and redo.

```dart
controller.insertTab(
  tabGroupId: 'editors',
  tab: .leaf(id: 'settings', title: 'Settings'),
);

controller.split(
  targetId: 'main',
  side: .right,
  sibling: .tabs([
    .leaf(id: 'preview', title: 'Preview'),
  ]),
);

controller.close('readme');
controller.undo();
```

## Customization

### Theme

`PlatTheme` styles the layout chrome for the `PlatView`s below it. Use it for
dividers, drop feedback, tabs, and animation timing.

```dart
PlatTheme(
  data: const PlatThemeData(
    divider: PlatDividerTheme(thickness: 2, hitSlop: 6),
    dropHint: PlatDropHintTheme(duration: Duration(milliseconds: 160)),
    tabBar: PlatTabBarTheme(
      size: 36,
      fit: .expand,
      chipMinWidth: 72,
      chipMaxWidth: 220,
      labelPadding: .symmetric(horizontal: 10),
    ),
  ),
  child: PlatView(
    controller: controller,
    leafBuilder: (context, leaf) => switch (leaf.id) {
      'inspector-pane' => InspectorPane(leaf: leaf),
      _ => EditorPane(leaf: leaf),
    },
  ),
);
```

### Tab chrome

For a custom tab group, return a `PlatTabBar` from `PlatView.tabBar`. Reuse the
default chip and replace the slots that need custom content.

```dart
PlatView(
  controller: controller,
  tabBar: (context, tabs) => PlatTabBar(
    tabBuilder: (context, tab) => PlatTabChip(
      leading: const Icon(Icons.description, size: 14),
      label: Text(tab.snapshot.title),
      trailing: const PlatTabCloseButton(),
    ),
  ),
  leafBuilder: (context, leaf) => switch (leaf.id) {
    'inspector-pane' => InspectorPane(leaf: leaf),
    _ => EditorPane(leaf: leaf),
  },
);
```

## Multiple views

One `PlatView` can render deeply nested workspaces. Use multiple views when
separate regions or controllers need to exchange tabs, filter drops, or
preserve leaf state during handoff.

```dart
Widget buildPane(BuildContext context, LeafSnapshot leaf) {
  return switch (leaf.id) {
    'inspector-pane' => InspectorPane(leaf: leaf),
    _ => EditorPane(leaf: leaf),
  };
}

PlatScope(
  child: Row(
    children: [
      Expanded(
        child: PlatView(
          controller: mainController,
          leafBuilder: buildPane,
        ),
      ),
      Expanded(
        child: PlatView(
          controller: sideController,
          leafBuilder: buildPane,
          autofocus: false,
          dropPolicy: (attempt) => attempt.sourceController == mainController,
        ),
      ),
    ],
  ),
);
```
