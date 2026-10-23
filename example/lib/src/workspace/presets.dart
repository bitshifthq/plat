import 'package:material_ui/material_ui.dart';

const ideaCloseHoverFill = Color(0xFF444A52);
const ideaDropHintFill = Color(0x1479B8FF);
const ideaTabDraggedFill = Color(0x66365B82);
const ideaTabHoverFill = Color(0xFF32465C);
const ideaTabSelectedFill = Color(0xFF365B82);

final class PresetActionButton {
  final double size;
  final double iconSize;
  final double startPadding;
  final BorderRadius radius;

  const new editor({
    this.size = 32,
    this.iconSize = 14,
    this.startPadding = 10,
    this.radius = const .all(.circular(5)),
  });

  const new tab({
    this.size = 24,
    this.iconSize = 14,
    this.startPadding = 0,
    this.radius = const .all(.circular(6)),
  });
}

final class const PresetActivityButton({
  final double size = 36,
  final double iconSize = 18,
  final BorderRadius radius = const .all(Radius.circular(8)),
  final bool usesAccent = false,
  final bool bordered = true,
}) {
  Color background(ColorScheme colors) => usesAccent
      ? colors.primary.withValues(alpha: 0.14)
      : colors.surfaceContainerHigh.withValues(alpha: 0.72);

  BorderSide border(ColorScheme colors) => bordered
      ? BorderSide(color: colors.primary.withValues(alpha: 0.32))
      : .none;
}

final class const PresetChrome({
  final bool wrapsGroups = false,
  final bool frameOnCanvas = false,
  final bool activityBarOnCanvas = false,
  final double activityBarWidth = 42,
  final PresetActivityButton activityButton = const PresetActivityButton(),
  final PresetActionButton editorAction = const PresetActionButton.editor(),
  final PresetActionButton tabAction = const PresetActionButton.tab(),
  final PresetTabChrome tab = const PresetTabChrome(),
  final BorderRadius leafRadius = .zero,
  final EdgeInsetsGeometry toolWindowPadding = const EdgeInsetsDirectional.only(
    start: 10,
    end: 5,
  ),
}) {
  static const material = PresetChrome(
    activityBarWidth: 44,
    tabAction: PresetActionButton.tab(size: 28),
    tab: PresetTabChrome(closeVisibility: PresetCloseVisibility.selected),
  );
  static const compact = PresetChrome(
    activityBarWidth: 36,
    activityButton: PresetActivityButton(
      size: 32,
      iconSize: 17,
      radius: .all(Radius.circular(3)),
    ),
    editorAction: PresetActionButton.editor(
      size: 28,
      iconSize: 13,
      startPadding: 8,
      radius: .all(Radius.circular(2)),
    ),
    tabAction: PresetActionButton.tab(
      size: 22,
      iconSize: 13,
      radius: .all(Radius.circular(3)),
    ),
    tab: PresetTabChrome(
      closeButtonSize: 14,
      closeIconSize: 10,
      gap: 3,
      leadingIconSize: 13,
      leadingGlyphSize: 11,
      closeVisibility: PresetCloseVisibility.always,
      previewHeight: 12,
    ),
    toolWindowPadding: EdgeInsetsDirectional.only(start: 8, end: 3),
  );
  static const idea = PresetChrome(
    wrapsGroups: true,
    frameOnCanvas: true,
    activityBarOnCanvas: true,
    activityButton: PresetActivityButton(usesAccent: true, bordered: false),
    tab: PresetTabChrome(
      closeButtonSize: 15,
      closeIconSize: 10,
      closeHoverFill: ideaCloseHoverFill,
      reserveCloseButtonSpace: true,
      leadingMinWidth: 44,
      closeMinWidth: 52,
      gap: 7,
      leadingIconSize: 14,
    ),
    leafRadius: BorderRadius.vertical(bottom: Radius.circular(9)),
  );
  static const dracula = PresetChrome(
    tab: PresetTabChrome(
      closeHoverUsesAccent: true,
      reserveCloseButtonSpace: true,
      leadingMinWidth: 44,
      closeMinWidth: 52,
      gap: 7,
      leadingIconSize: 14,
    ),
  );
  static const oneDark = PresetChrome(
    activityButton: PresetActivityButton(radius: .all(Radius.circular(3))),
    tab: PresetTabChrome(
      closeButtonSize: 15,
      closeIconSize: 10,
      closeHoverUsesAccent: true,
      reserveCloseButtonSpace: true,
      leadingMinWidth: 44,
      closeMinWidth: 52,
      gap: 7,
      leadingIconSize: 13,
      leadingGlyphSize: 13,
      previewHeight: 12,
    ),
  );
  bool get hasActivityBarBorder => !activityBarOnCanvas;

  bool get hasFrameBorder => !frameOnCanvas;

  Color activityBarColor(ColorScheme colors) => activityBarOnCanvas
      ? colors.surfaceContainerLowest
      : colors.surfaceContainerLow;

  Color frameColor(ColorScheme colors) {
    return frameOnCanvas ? colors.surfaceContainerLowest : colors.surface;
  }
}

enum PresetCloseVisibility() {
  selected,
  selectedOrHovered,
  always;

  bool resolve(Set<WidgetState> states) => switch (this) {
    .selected => states.contains(WidgetState.selected),
    .selectedOrHovered =>
      states.contains(WidgetState.selected) ||
          states.contains(WidgetState.hovered),
    .always => true,
  };
}

final class const PresetPalette({
  required final Color accent,
  required final Color border,
  required final Color canvas,
  required final Color foreground,
  required final Color lowSurface,
  required final Color muted,
  required final Color raised,
  required final Color surface,
  final Brightness brightness = .light,
  final VisualDensity density = .standard,
  final BorderRadius buttonRadius = const .all(Radius.circular(20)),
  final BorderRadius cardRadius = const .all(Radius.circular(12)),
  final BorderRadius chipRadius = const .all(Radius.circular(8)),
  final BorderRadius frameRadius = const .all(Radius.circular(14)),
  final BorderRadius groupRadius = .zero,
}) {
  static const material = PresetPalette(
    accent: Color(0xFF6750A4),
    border: Color(0xFFE0D7E5),
    canvas: Color(0xFFFDFBFF),
    foreground: Color(0xFF1D1B20),
    lowSurface: Color(0xFFF3EDF7),
    muted: Color(0xFF625B71),
    raised: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFBFE),
  );
  static const compact = PresetPalette(
    accent: Color(0xFF0F766E),
    border: Color(0xFFAEB8C5),
    canvas: Color(0xFFEFF3F8),
    foreground: Color(0xFF111827),
    lowSurface: Color(0xFFD7DEE9),
    muted: Color(0xFF64748B),
    raised: Color(0xFFFFFFFF),
    surface: Color(0xFFF8FAFD),
    density: .compact,
    buttonRadius: .all(Radius.circular(2)),
    cardRadius: .all(Radius.circular(2)),
    chipRadius: .all(Radius.circular(1)),
    frameRadius: .zero,
  );
  static const idea = PresetPalette(
    accent: Color(0xFF79B8FF),
    border: Color(0xFF3A3D42),
    canvas: Color(0xFF1E1F22),
    foreground: Color(0xFFE0E3E7),
    lowSurface: Color(0xFF242528),
    muted: Color(0xFFAEB4BE),
    raised: Color(0xFF33363A),
    surface: Color(0xFF2B2D30),
    brightness: .dark,
    buttonRadius: .all(Radius.circular(6)),
    cardRadius: .all(Radius.circular(8)),
    chipRadius: .all(Radius.circular(6)),
    frameRadius: .all(Radius.circular(12)),
    groupRadius: .all(Radius.circular(12)),
  );
  static const dracula = PresetPalette(
    accent: Color(0xFFBD93F9),
    border: Color(0xFF525568),
    canvas: Color(0xFF1E1F29),
    foreground: Color(0xFFF8F8F2),
    lowSurface: Color(0xFF282A36),
    muted: Color(0xFFC7C8D4),
    raised: Color(0xFF44475A),
    surface: Color(0xFF303241),
    brightness: .dark,
    buttonRadius: .all(Radius.circular(8)),
    cardRadius: .all(Radius.circular(8)),
    chipRadius: .all(Radius.circular(6)),
    frameRadius: .all(Radius.circular(10)),
  );
  static const oneDark = PresetPalette(
    accent: Color(0xFF61AFEF),
    border: Color(0xFF3E4451),
    canvas: Color(0xFF191C22),
    foreground: Color(0xFFE6EFF8),
    lowSurface: Color(0xFF21252B),
    muted: Color(0xFFABB2BF),
    raised: Color(0xFF2F3540),
    surface: Color(0xFF282C34),
    brightness: .dark,
    buttonRadius: .all(Radius.circular(2)),
    cardRadius: .all(Radius.circular(2)),
    chipRadius: .zero,
    frameRadius: .zero,
  );

  ThemeData materialTheme(ThemeData base) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: brightness,
        ).copyWith(
          surface: surface,
          onSurface: foreground,
          surfaceContainerLowest: canvas,
          surfaceContainerLow: lowSurface,
          surfaceContainer: surface,
          surfaceContainerHigh: raised,
          outlineVariant: border,
          primary: accent,
          secondary: accent,
        );

    return base.copyWith(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      dividerColor: border,
      cardTheme: CardThemeData(
        color: raised,
        elevation: brightness == .dark ? 0 : 1,
        margin: .zero,
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: lowSurface,
        selectedColor: accent.withValues(alpha: 0.18),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: chipRadius),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        textColor: foreground,
        tileColor: Colors.transparent,
        contentPadding: const .symmetric(horizontal: 14, vertical: 3),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          visualDensity: density,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: foreground,
          visualDensity: density,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: density,
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: buttonRadius),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return muted;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return null;
        }),
      ),
    );
  }
}

final class const PresetTabChrome({
  final double closeButtonSize = 16,
  final double closeIconSize = 11,
  final Color? closeHoverFill,
  final bool closeHoverUsesAccent = false,
  final bool reserveCloseButtonSpace = false,
  final double leadingMinWidth = 64,
  final double closeMinWidth = 42,
  final double gap = 6,
  final double leadingIconSize = 16,
  final double leadingGlyphSize = 14,
  final PresetCloseVisibility closeVisibility =
      PresetCloseVisibility.selectedOrHovered,
  final double previewHeight = 14,
}) {
  Color? closeHoverColor(ColorScheme colors) {
    return closeHoverFill ??
        (closeHoverUsesAccent ? colors.primary.withValues(alpha: 0.18) : null);
  }

  bool shouldShowCloseButton({
    required Set<WidgetState> states,
    required bool locked,
    required bool pinned,
  }) {
    if (states.contains(WidgetState.dragged) || locked || pinned) return false;
    return closeVisibility.resolve(states);
  }
}

enum ThemePreset(
  final String label,
  final String description,
  final String shape, {
  required final PresetPalette palette,
  required final PresetChrome chrome,
}) {
  material(
    'Material',
    'Clean Material workspace',
    'Rounded',
    palette: PresetPalette.material,
    chrome: PresetChrome.material,
  ),
  compact(
    'Compact',
    'Dense technical surface',
    'Square',
    palette: PresetPalette.compact,
    chrome: PresetChrome.compact,
  ),
  idea(
    'IntelliJ IDEA',
    'JetBrains-style rounded workspace',
    'Inset',
    palette: PresetPalette.idea,
    chrome: PresetChrome.idea,
  ),
  dracula(
    'Dracula',
    'High-contrast dark workspace',
    'Vivid',
    palette: PresetPalette.dracula,
    chrome: PresetChrome.dracula,
  ),
  oneDark(
    'One Dark Pro',
    'Atom-inspired dark workspace',
    'Sharp',
    palette: PresetPalette.oneDark,
    chrome: PresetChrome.oneDark,
  ),
}
