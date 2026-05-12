import 'package:flutter/material.dart' show TabBarTheme;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart' show internal;

import '../../controller/controller.dart';
import '../../controller/snapshot_mapping.dart';
import '../../model/plat_snapshot.dart';
import '../drop/drag_payload.dart';
import '../drop/drop_attempt.dart';
import '../drop/overlay.dart' show DropOverlay;
import '../theme.dart';
import 'bar.dart';
import 'chip.dart';

Widget _defaultTabFeedback({
  required BoxConstraints constraints,
  required Size? size,
  required Widget child,
}) {
  final width =
      size?.width ??
      (constraints.hasBoundedWidth ? constraints.maxWidth : null);
  final height =
      size?.height ??
      (constraints.hasBoundedHeight ? constraints.maxHeight : null);
  return width == null && height == null
      ? child
      : SizedBox(width: width, height: height, child: child);
}

/// Internal coordinator for a single [TabGroupSnapshot] group.
@internal
final class PlatTabGroupView extends StatelessWidget {
  final TabGroupSnapshot view;
  final PlatTabBarBuilder? tabBar;
  final PlatController controller;
  final Widget Function(String id) platBuilder;
  final DropPolicy? dropPolicy;

  const PlatTabGroupView({
    super.key,
    required this.view,
    required this.controller,
    this.tabBar,
    required this.platBuilder,
    this.dropPolicy,
  });

  @override
  Widget build(BuildContext context) {
    if (view.tabs.isEmpty) return const SizedBox.shrink();

    final theme = PlatTheme.of(context);
    final bar = tabBar?.call(context, view) ?? const PlatTabBar();
    final tabBuilder = bar.tabBuilder;
    final tabs = [
      for (final (index, tab) in view.tabs.indexed)
        MetaData(
          metaData: tab.id,
          key: ValueKey(tab.id),
          child: _DraggableTab(
            view: view,
            tab: tab,
            index: index,
            sourceController: controller,
            dragFeedbackBuilder: bar.dragFeedbackBuilder,
            tabBuilder: (context, tabDetails) {
              if (tabBuilder != null) return tabBuilder(context, tabDetails);
              return const PlatTabChip();
            },
          ),
        ),
    ];

    final isVertical = view.side.isVertical;
    final barHost = SizedBox(
      width: isVertical ? theme.tabBar.size : null,
      height: isVertical ? null : theme.tabBar.size,
      child: _TabBarDropTarget(
        tabs: view,
        controller: controller,
        dropPolicy: dropPolicy,
        builder: (_, hover) =>
            platTabBarScope(tabs: view, chips: tabs, hover: hover, child: bar),
      ),
    );

    Widget body = Listener(
      behavior: .translucent,
      onPointerDown: (_) => controller.focus(view.id),
      child: IndexedStack(
        sizing: StackFit.expand,
        index: view.activeIndex,
        children: [
          for (final tab in view.tabs)
            KeyedSubtree(
              key: ValueKey(tab.id),
              child: platBuilder(tab.child.id),
            ),
        ],
      ),
    );

    if (view.acceptsDrops) {
      body = DropOverlay(
        target: view,
        controller: controller,
        dropPolicy: dropPolicy,
        child: body,
      );
    }

    return Flex(
      crossAxisAlignment: .stretch,
      direction: isVertical ? .horizontal : .vertical,
      children: switch (view.side) {
        .top || .left => [barHost, Expanded(child: body)],
        .bottom || .right => [Expanded(child: body), barHost],
      },
    );
  }
}

/// Internal strip used by [PlatTabBar].
@internal
final class PlatTabStrip extends StatefulWidget {
  final TabGroupSnapshot view;
  final PlatTabBarTheme theme;
  final List<Widget> chips;
  final ({int at, TabDragPayload payload})? hover;
  final Widget? stripLeading;
  final Widget? stripTrailing;
  final Widget Function(BuildContext context, TabSnapshot tab) buildPlaceholder;

  const PlatTabStrip({
    super.key,
    required this.view,
    required this.theme,
    required this.chips,
    required this.hover,
    required this.buildPlaceholder,
    this.stripLeading,
    this.stripTrailing,
  });

  @override
  State<PlatTabStrip> createState() => _PlatTabStripState();
}

class _PlatTabStripState extends State<PlatTabStrip> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant PlatTabStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldActive = oldWidget.view.activeTab?.id;
    final newActive = widget.view.activeTab?.id;
    if (oldActive != newActive && newActive != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollActiveIntoView(newActive);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVertical = widget.view.side.isVertical;
    if (widget.theme.fit == .expand && !isVertical) {
      return Row(
        crossAxisAlignment: .stretch,
        children: [
          if (widget.stripLeading != null) widget.stripLeading!,
          Expanded(child: LayoutBuilder(builder: _fitChips)),
          if (widget.stripTrailing != null) widget.stripTrailing!,
        ],
      );
    }

    final children = _stripChildren(
      context: context,
      view: widget.view,
      chips: widget.chips,
      hover: widget.hover,
      spacing: widget.theme.spacing,
      buildPlaceholder: widget.buildPlaceholder,
      leading: widget.stripLeading,
      trailing: widget.stripTrailing,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final main = isVertical ? constraints.maxHeight : constraints.maxWidth;
        final flex = Flex(
          mainAxisSize: .min,
          direction: isVertical ? .vertical : .horizontal,
          mainAxisAlignment: switch (widget.theme.alignment) {
            .start => .start,
            .center => .center,
            .end => .end,
          },
          crossAxisAlignment: .stretch,
          children: children,
        );
        final stretched = main.isFinite
            ? ConstrainedBox(
                constraints: isVertical
                    ? BoxConstraints(minHeight: main)
                    : BoxConstraints(minWidth: main),
                child: flex,
              )
            : flex;
        return SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: isVertical ? .vertical : .horizontal,
          physics: widget.theme.physics,
          child: isVertical
              ? IntrinsicWidth(child: stretched)
              : IntrinsicHeight(child: stretched),
        );
      },
    );
  }

  Widget _fitChips(BuildContext context, BoxConstraints constraints) {
    final pinnedWidth = widget.theme.pinnedChipWidth;
    final pinnedCount = widget.view.tabs.where((t) => t.pinned).length;
    final nonPinnedCount = widget.view.tabs.length - pinnedCount;
    final pinnedFootprint = pinnedWidth == null
        ? 0.0
        : pinnedCount * pinnedWidth;
    var share = nonPinnedCount > 0
        ? (constraints.maxWidth - pinnedFootprint) / nonPinnedCount
        : 0.0;
    if (widget.theme.chipMaxWidth != null) {
      share = share.clamp(0.0, widget.theme.chipMaxWidth!);
    }
    share = share.clamp(widget.theme.chipMinWidth ?? 0.0, double.infinity);
    var selectedShare = share;

    final selectedMinWidth = _selectedChipMinWidth(widget.theme);
    final selectedCount = widget.view.tabs
        .where((t) => t.selected && !t.pinned)
        .length;
    if (selectedCount > 0 && selectedShare < selectedMinWidth) {
      final flexibleCount = nonPinnedCount - selectedCount;
      selectedShare = selectedMinWidth;
      var remaining =
          constraints.maxWidth -
          pinnedFootprint -
          selectedShare * selectedCount;
      if (remaining < 0) {
        selectedShare =
            ((constraints.maxWidth - pinnedFootprint) / selectedCount).clamp(
              0.0,
              double.infinity,
            );
        remaining = 0;
      }

      share = flexibleCount > 0 ? remaining / flexibleCount : 0.0;
      if (widget.theme.chipMaxWidth != null) {
        share = share.clamp(0.0, widget.theme.chipMaxWidth!);
      }
      if (widget.theme.chipMinWidth case final chipMinWidth?
          when flexibleCount > 0 &&
              pinnedFootprint +
                      selectedShare * selectedCount +
                      chipMinWidth * flexibleCount <=
                  constraints.maxWidth) {
        share = share.clamp(chipMinWidth, double.infinity);
      } else {
        share = share.clamp(0.0, double.infinity);
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _stripChildren(
        context: context,
        view: widget.view,
        chips: widget.chips,
        hover: widget.hover,
        spacing: widget.theme.spacing,
        buildPlaceholder: widget.buildPlaceholder,
        wrapChip: (tab, child) => SizedBox(
          width: switch ((tab.pinned && pinnedWidth != null, tab.selected)) {
            (true, _) => pinnedWidth,
            (false, true) => selectedShare,
            (false, false) => share,
          },
          child: child,
        ),
      ),
    );
  }

  double _selectedChipMinWidth(PlatTabBarTheme theme) {
    final maxWidth = theme.chipMaxWidth;
    if (maxWidth != null && theme.size > maxWidth) return maxWidth;
    return theme.size;
  }

  void _scrollActiveIntoView(String activeId) {
    final root = context.findRenderObject();
    if (root == null) return;
    final target = _findTabChipMetadata(root, activeId);
    if (target == null || !target.attached || !target.hasSize) return;
    target.showOnScreen(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }
}

final class _DraggableTab extends StatefulWidget {
  final int index;
  final TabSnapshot tab;
  final TabGroupSnapshot view;
  final PlatTabBuilder tabBuilder;
  final PlatController sourceController;
  final DragFeedbackBuilder? dragFeedbackBuilder;

  const _DraggableTab({
    required this.view,
    required this.tab,
    required this.index,
    required this.sourceController,
    required this.tabBuilder,
    this.dragFeedbackBuilder,
  });

  @override
  State<_DraggableTab> createState() => _DraggableTabState();
}

final class _DraggableTabState extends State<_DraggableTab> {
  Size? _feedbackSize;
  var _hovered = false;
  var _pressed = false;
  var _dragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = PlatTheme.of(context);
    final states = _resolveStates();
    final tabDetails = PlatTabDetails(
      snapshot: widget.tab,
      group: widget.view,
      index: widget.index,
      states: states,
    );
    final closeTab = widget.tab.locked
        ? null
        : () => widget.sourceController.close(widget.tab.id);
    final tappable = _TabSizeObserver(
      onChanged: _setFeedbackSize,
      child: GestureDetector(
        behavior: .opaque,
        onTap: () => widget.sourceController.focus(widget.tab.id),
        child: Listener(
          onPointerDown: (_) => _setPressed(true),
          onPointerUp: (_) => _setPressed(false),
          onPointerCancel: (_) => _setPressed(false),
          child: MouseRegion(
            cursor: _resolveCursor(context, theme.tabBar, states),
            onEnter: (_) => _setHovered(true),
            onExit: (_) {
              _setHovered(false);
              _setPressed(false);
            },
            child: platTabScope(
              details: tabDetails,
              close: closeTab,
              child: Builder(
                builder: (context) => widget.tabBuilder(context, tabDetails),
              ),
            ),
          ),
        ),
      ),
    );
    if (widget.tab.locked) return tappable;

    return LayoutBuilder(
      builder: (context, constraints) {
        final customFeedbackDetails = PlatTabDetails(
          snapshot: widget.tab,
          group: widget.view,
          index: widget.index,
          states: {...states, WidgetState.dragged},
        );
        final defaultFeedbackDetails = PlatTabDetails(
          snapshot: widget.tab,
          group: widget.view,
          index: widget.index,
          states: const {WidgetState.dragged},
        );
        final customFeedbackBuilder = widget.dragFeedbackBuilder;
        Widget defaultFeedback() {
          return _defaultTabFeedback(
            constraints: constraints,
            size: _feedbackSize,
            child: platTabScope(
              details: defaultFeedbackDetails,
              hideCloseButton: true,
              child: Builder(
                builder: (context) =>
                    widget.tabBuilder(context, defaultFeedbackDetails),
              ),
            ),
          );
        }

        final feedback = customFeedbackBuilder == null
            ? defaultFeedback()
            : platTabScope(
                details: customFeedbackDetails,
                hideCloseButton: true,
                child: Builder(
                  builder: (context) {
                    final hostFeedback = customFeedbackBuilder(
                      context,
                      customFeedbackDetails,
                    );
                    return hostFeedback ?? defaultFeedback();
                  },
                ),
              );
        final capturedFeedback = InheritedTheme.captureAll(context, feedback);
        return Draggable<TabDragPayload>(
          data: TabDragPayload(
            tab: widget.tab,
            sourceTabGroupId: widget.view.id,
            source: widget.sourceController,
            feedbackAnchor: _feedbackAnchor,
          ),
          dragAnchorStrategy: _centerDragAnchorStrategy,
          onDragStarted: () => _setDragging(true),
          onDragEnd: (_) => _setDragging(false),
          onDraggableCanceled: (_, _) => _setDragging(false),
          feedback: capturedFeedback,
          childWhenDragging: const SizedBox.shrink(),
          child: tappable,
        );
      },
    );
  }

  Set<WidgetState> _resolveStates() => {
    if (widget.tab.selected) WidgetState.selected,
    if (widget.tab.focused) WidgetState.focused,
    if (_hovered) WidgetState.hovered,
    if (_pressed) WidgetState.pressed,
    if (_dragging) WidgetState.dragged,
  };

  MouseCursor _resolveCursor(
    BuildContext context,
    PlatTabBarTheme theme,
    Set<WidgetState> states,
  ) {
    return theme.mouseCursor?.resolve(states) ??
        TabBarTheme.of(context).mouseCursor?.resolve(states) ??
        defaultPlatTabCursor.resolve(states);
  }

  void _setHovered(bool value) {
    if (!mounted || _hovered == value) return;
    setState(() => _hovered = value);
  }

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  void _setDragging(bool value) {
    if (!mounted) return;
    if (_dragging == value && !_hovered && !_pressed) return;
    setState(() {
      _dragging = value;
      _hovered = false;
      _pressed = false;
    });
  }

  void _setFeedbackSize(Size size) {
    if (!mounted || _feedbackSize == size) return;
    setState(() => _feedbackSize = size);
  }

  Offset get _feedbackAnchor {
    final size = _feedbackSize;
    if (size == null) return Offset.zero;
    return Offset(size.width / 2, size.height / 2);
  }
}

Offset _centerDragAnchorStrategy(
  Draggable<Object> draggable,
  BuildContext context,
  Offset position,
) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return Offset.zero;
  return Offset(box.size.width / 2, box.size.height / 2);
}

final class _TabSizeObserver extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onChanged;

  const _TabSizeObserver({required this.onChanged, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderTabSizeObserver(onChanged);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderTabSizeObserver renderObject,
  ) {
    renderObject.onChanged = onChanged;
  }
}

final class _RenderTabSizeObserver extends RenderProxyBox {
  ValueChanged<Size> onChanged;
  Size? _lastSize;

  _RenderTabSizeObserver(this.onChanged);

  @override
  void performLayout() {
    super.performLayout();
    if (_lastSize == size) return;
    _lastSize = size;
    WidgetsBinding.instance.addPostFrameCallback((_) => onChanged(size));
  }
}

final class _TabBarDropTarget extends StatefulWidget {
  final TabGroupSnapshot tabs;
  final PlatController controller;
  final DropPolicy? dropPolicy;
  final Widget Function(BuildContext, ({int at, TabDragPayload payload})?)
  builder;

  const _TabBarDropTarget({
    required this.tabs,
    required this.controller,
    required this.dropPolicy,
    required this.builder,
  });

  @override
  State<_TabBarDropTarget> createState() => _TabBarDropTargetState();
}

class _TabBarDropTargetState extends State<_TabBarDropTarget> {
  ({int at, TabDragPayload payload})? _hover;

  @override
  Widget build(BuildContext context) {
    return DragTarget<TabDragPayload>(
      onWillAcceptWithDetails: (details) {
        if (!_canAccept(details)) return false;
        _update(details);
        return true;
      },
      onMove: (details) {
        if (!_canAccept(details)) {
          _set(null);
          return;
        }
        _update(details);
      },
      onLeave: (_) => _set(null),
      onAcceptWithDetails: (details) {
        if (!_canAccept(details)) {
          _set(null);
          return;
        }
        final at = _resolveAt(details);
        _set(null);
        if (details.data.source == widget.controller) {
          widget.controller.moveTab(
            tabId: details.data.tab.id,
            tabGroupId: widget.tabs.id,
            index: at,
          );
          return;
        }
        final inserted = widget.controller.insertTab(
          tabGroupId: widget.tabs.id,
          tab: details.data.tab.toEntry(),
          index: at,
        );
        if (inserted) details.data.source.close(details.data.tab.id);
      },
      builder: (context, _, _) => widget.builder(context, _hover),
    );
  }

  bool _canAccept(DragTargetDetails<TabDragPayload> details) {
    if (!widget.tabs.acceptsDrops) return false;
    return widget.dropPolicy?.call(
          DropAttempt(
            tab: details.data.tab,
            target: widget.tabs,
            zone: .center,
            sourceController: details.data.source,
          ),
        ) ??
        true;
  }

  int _resolveAt(DragTargetDetails<TabDragPayload> details) {
    final tabs = widget.tabs.tabs;
    if (tabs.isEmpty) return 0;
    final root = context.findRenderObject();
    if (root == null) return 0;
    final chips = _collectTabChipMetadata(root);

    final isVertical = widget.tabs.side.isVertical;
    final dragId = details.data.tab.id;
    var insertAt = 0;
    for (var i = 0; i < tabs.length; i++) {
      final box = chips[tabs[i].id];
      if (box == null || !box.hasSize) continue;
      final extent = isVertical ? box.size.height : box.size.width;
      if (tabs[i].id == dragId && extent == 0) continue;
      final centre = isVertical
          ? box.localToGlobal(Offset(0, box.size.height / 2)).dy
          : box.localToGlobal(Offset(box.size.width / 2, 0)).dx;
      final pointerOffset = details.offset + details.data.feedbackAnchor;
      final pointer = isVertical ? pointerOffset.dy : pointerOffset.dx;
      if (pointer <= centre) break;
      insertAt = i + 1;
    }
    return insertAt.clamp(0, tabs.length);
  }

  void _update(DragTargetDetails<TabDragPayload> details) =>
      _set((at: _resolveAt(details), payload: details.data));

  void _set(({int at, TabDragPayload payload})? next) {
    if (next == _hover) return;
    setState(() => _hover = next);
  }
}

List<Widget> _stripChildren({
  required BuildContext context,
  required TabGroupSnapshot view,
  required List<Widget> chips,
  required ({int at, TabDragPayload payload})? hover,
  required double spacing,
  required Widget Function(BuildContext context, TabSnapshot tab)
  buildPlaceholder,
  Widget? leading,
  Widget? trailing,
  Widget Function(TabSnapshot tab, Widget child)? wrapChip,
}) {
  final hoverTab = hover?.payload.tab;
  final hoverAt = hover?.at;
  final slots = <Widget>[];
  for (var i = 0; i < view.tabs.length; i++) {
    if (hoverAt == i && hoverTab != null) {
      slots.add(
        _wrapChip(hoverTab, buildPlaceholder(context, hoverTab), wrapChip),
      );
    }
    slots.add(_wrapChip(view.tabs[i], chips[i], wrapChip));
  }
  if (hoverAt == view.tabs.length && hoverTab != null) {
    slots.add(
      _wrapChip(hoverTab, buildPlaceholder(context, hoverTab), wrapChip),
    );
  }

  final isVertical = view.side.isVertical;
  final result = <Widget>[?leading];
  for (var i = 0; i < slots.length; i++) {
    if (i > 0 && spacing > 0) {
      result.add(
        SizedBox(
          width: isVertical ? null : spacing,
          height: isVertical ? spacing : null,
        ),
      );
    }
    result.add(slots[i]);
  }
  if (trailing != null) result.add(trailing);
  return result;
}

Widget _wrapChip(
  TabSnapshot tab,
  Widget child,
  Widget Function(TabSnapshot tab, Widget child)? wrapChip,
) => wrapChip?.call(tab, child) ?? child;

Map<String, RenderMetaData> _collectTabChipMetadata(RenderObject root) {
  final chips = <String, RenderMetaData>{};

  void visit(RenderObject node) {
    if (node is RenderMetaData && node.metaData is String) {
      final id = node.metaData as String;
      chips[id] = node;
      return;
    }
    node.visitChildren(visit);
  }

  visit(root);
  return chips;
}

RenderMetaData? _findTabChipMetadata(RenderObject root, String id) {
  RenderMetaData? hit;

  void visit(RenderObject node) {
    if (hit != null) return;
    if (node is RenderMetaData && node.metaData == id) {
      hit = node;
      return;
    }
    node.visitChildren(visit);
  }

  visit(root);
  return hit;
}
