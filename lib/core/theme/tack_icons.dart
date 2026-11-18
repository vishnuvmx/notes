import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import 'app_colors.dart';

enum HeroIconStyle { outline, solid }

/// Descriptor for Tack's unified Tabler icon glyphs (`tabler_icons_plus`).
///
/// - Renders crisp 2px rounded-stroke Tabler glyphs cleanly across Light & Dark modes.
/// - Supports optional [solid] (`*Filled`) glyphs when [HeroIconStyle.solid] is passed
///   for active navigation destinations, favorites, checkboxes, and pins.
class TackGlyph {
  final IconData outline;
  final IconData? solid;
  final double opticalScale;

  const TackGlyph(
    this.outline, {
    this.solid,
    this.opticalScale = 1.0,
  });

  /// Resolve the active glyph for [style], falling back to [outline] when no
  /// filled variant exists.
  IconData resolve(HeroIconStyle style) =>
      style == HeroIconStyle.solid ? (solid ?? outline) : outline;
}

/// Central Iconography for Tack powered by Tabler Icons (`tabler_icons_plus`).
///
/// Always render icons through `TackIcon(...)` rather than `Icon(...)`.
class TackIcons {
  TackIcons._();

  // Primary Workspace & Canvas Aliases
  static const TackGlyph homeSvg = TackGlyph(
    TablerIcons.home,
    solid: TablerIcons.homeFilled,
  );
  static const TackGlyph notesSvg = TackGlyph(TablerIcons.notes);
  static const TackGlyph whiteboardSvg = TackGlyph(
    TablerIcons.presentation,
    solid: TablerIcons.presentationFilled,
  );
  static const TackGlyph clipboardSvg = TackGlyph(
    TablerIcons.clipboard,
    solid: TablerIcons.clipboardFilled,
  );
  static const TackGlyph plusSvg = TackGlyph(TablerIcons.plus);
  static const TackGlyph selectSvg = TackGlyph(
    TablerIcons.pointer,
    solid: TablerIcons.pointerFilled,
  );
  static const TackGlyph handSvg = TackGlyph(TablerIcons.handStop);
  static const TackGlyph connectorSvg = TackGlyph(TablerIcons.vectorBezier2);
  static const TackGlyph textSvg = TackGlyph(TablerIcons.typography);
  static const TackGlyph imageSvg = TackGlyph(
    TablerIcons.photo,
    solid: TablerIcons.photoFilled,
  );
  static const TackGlyph drawSvg = TackGlyph(
    TablerIcons.pencil,
    solid: TablerIcons.pencilFilled,
  );
  static const TackGlyph editSvg = TackGlyph(
    TablerIcons.edit,
    solid: TablerIcons.editFilled,
  );
  static const TackGlyph eyeSvg = TackGlyph(
    TablerIcons.eye,
    solid: TablerIcons.eyeFilled,
  );
  static const TackGlyph undoSvg = TackGlyph(TablerIcons.arrowBackUp);
  static const TackGlyph redoSvg = TackGlyph(TablerIcons.arrowForwardUp);
  static const TackGlyph searchSvg = TackGlyph(
    TablerIcons.search,
    solid: TablerIcons.searchFilled,
  );
  static const TackGlyph copySvg = TackGlyph(
    TablerIcons.copy,
    solid: TablerIcons.copyFilled,
  );
  static const TackGlyph pasteSvg = TackGlyph(
    TablerIcons.clipboardCheck,
    solid: TablerIcons.clipboardCheckFilled,
  );

  // Navigation & Primary Tabs
  static const TackGlyph today = TackGlyph(
    TablerIcons.calendarEvent,
    solid: TablerIcons.calendarEventFilled,
  );
  static const TackGlyph library = TackGlyph(
    TablerIcons.library,
    solid: TablerIcons.libraryFilled,
  );
  static const TackGlyph inbox = TackGlyph(TablerIcons.inbox);
  static const TackGlyph boards = TackGlyph(
    TablerIcons.presentation,
    solid: TablerIcons.presentationFilled,
  );
  static const TackGlyph home = homeSvg;
  static const TackGlyph notes = notesSvg;
  static const TackGlyph sticky = TackGlyph(TablerIcons.note);
  static const TackGlyph whiteboard = whiteboardSvg;
  static const TackGlyph clipboard = clipboardSvg;
  static const TackGlyph plus = plusSvg;

  // App Bar & Common Actions
  static const TackGlyph menu = TackGlyph(
    TablerIcons.menu2,
    solid: TablerIcons.menu2Filled,
  );
  static const TackGlyph search = searchSvg;
  static const TackGlyph close = TackGlyph(
    TablerIcons.x,
    solid: TablerIcons.xFilled,
  );
  static const TackGlyph check = TackGlyph(TablerIcons.check);
  static const TackGlyph checkCircle = TackGlyph(
    TablerIcons.circleCheck,
    solid: TablerIcons.circleCheckFilled,
  );
  static const TackGlyph back = TackGlyph(TablerIcons.arrowLeft);
  static const TackGlyph more = TackGlyph(
    TablerIcons.dots,
    solid: TablerIcons.dotsFilled,
  );
  static const TackGlyph share = TackGlyph(TablerIcons.share);
  static const TackGlyph copy = copySvg;
  static const TackGlyph paste = pasteSvg;
  static const TackGlyph exportData = TackGlyph(TablerIcons.fileExport);
  static const TackGlyph importData = TackGlyph(TablerIcons.fileImport);
  static const TackGlyph undo = undoSvg;
  static const TackGlyph redo = redoSvg;
  static const TackGlyph palette = TackGlyph(
    TablerIcons.palette,
    solid: TablerIcons.paletteFilled,
  );
  static const TackGlyph clock = TackGlyph(
    TablerIcons.clock,
    solid: TablerIcons.clockFilled,
  );
  static const TackGlyph sort = TackGlyph(TablerIcons.arrowsSort);
  static const TackGlyph saving = TackGlyph(TablerIcons.loader2);
  static const TackGlyph command = TackGlyph(TablerIcons.command);

  // Todo / Tasks
  static const TackGlyph task = TackGlyph(
    TablerIcons.squareCheck,
    solid: TablerIcons.squareCheckFilled,
  );
  static const TackGlyph taskOpen = TackGlyph(TablerIcons.square);
  static const TackGlyph todayTasks = TackGlyph(
    TablerIcons.listCheck,
    solid: TablerIcons.listCheckFilled,
  );

  // Folders & Views
  static const TackGlyph folder = TackGlyph(
    TablerIcons.folder,
    solid: TablerIcons.folderFilled,
  );
  static const TackGlyph folderPlus = TackGlyph(TablerIcons.folderPlus);
  static const TackGlyph folderTree = TackGlyph(TablerIcons.listTree);
  static const TackGlyph graph = TackGlyph(TablerIcons.topologyStar3);
  static const TackGlyph gridView = TackGlyph(
    TablerIcons.layoutGrid,
    solid: TablerIcons.layoutGridFilled,
  );
  static const TackGlyph listView = TackGlyph(
    TablerIcons.list,
    solid: TablerIcons.listFilled,
  );

  // Secondary / Drawer / Settings
  static const TackGlyph star = TackGlyph(
    TablerIcons.star,
    solid: TablerIcons.starFilled,
  );
  static const TackGlyph archive = TackGlyph(
    TablerIcons.archive,
    solid: TablerIcons.archiveFilled,
  );
  static const TackGlyph trash = TackGlyph(
    TablerIcons.trash,
    solid: TablerIcons.trashFilled,
  );
  static const TackGlyph settings = TackGlyph(
    TablerIcons.settings,
    solid: TablerIcons.settingsFilled,
  );
  static const TackGlyph sun = TackGlyph(
    TablerIcons.sun,
    solid: TablerIcons.sunFilled,
  );
  static const TackGlyph moon = TackGlyph(
    TablerIcons.moon,
    solid: TablerIcons.moonFilled,
  );
  static const TackGlyph user = TackGlyph(
    TablerIcons.user,
    solid: TablerIcons.userFilled,
  );
  static const TackGlyph notification = TackGlyph(
    TablerIcons.bell,
    solid: TablerIcons.bellFilled,
  );

  // Editor & Formatting
  static const TackGlyph chevronDown = TackGlyph(
    TablerIcons.chevronDown,
    solid: TablerIcons.chevronDownFilled,
  );
  static const TackGlyph chevronUp = TackGlyph(TablerIcons.chevronUp);
  static const TackGlyph chevronLeft = TackGlyph(TablerIcons.chevronLeft);
  static const TackGlyph chevronRight = TackGlyph(
    TablerIcons.chevronRight,
    solid: TablerIcons.chevronRightFilled,
  );
  static const TackGlyph edit = editSvg;
  static const TackGlyph reader = eyeSvg;
  static const TackGlyph tag = TackGlyph(
    TablerIcons.tag,
    solid: TablerIcons.tagFilled,
  );
  static const TackGlyph eye = eyeSvg;
  static const TackGlyph eyeOff = TackGlyph(TablerIcons.eyeOff);
  static const TackGlyph imageOff = TackGlyph(TablerIcons.photoOff);
  static const TackGlyph externalLink = TackGlyph(
    TablerIcons.externalLink,
    solid: TablerIcons.externalLinkFilled,
  );
  static const TackGlyph play = TackGlyph(
    TablerIcons.playerPlay,
    solid: TablerIcons.playerPlayFilled,
  );
  static const TackGlyph bold = TackGlyph(TablerIcons.bold);
  static const TackGlyph italic = TackGlyph(TablerIcons.italic);
  static const TackGlyph underline = TackGlyph(TablerIcons.underline);
  static const TackGlyph strikethrough = TackGlyph(TablerIcons.strikethrough);
  static const TackGlyph code = TackGlyph(TablerIcons.code);
  static const TackGlyph quote = TackGlyph(TablerIcons.blockquote);
  static const TackGlyph bulletList = TackGlyph(TablerIcons.list);
  static const TackGlyph numberedList = TackGlyph(TablerIcons.listNumbers);
  static const TackGlyph heading1 = TackGlyph(TablerIcons.h1);
  static const TackGlyph heading2 = TackGlyph(TablerIcons.h2);
  static const TackGlyph heading3 = TackGlyph(TablerIcons.h3);
  static const TackGlyph table = TackGlyph(
    TablerIcons.table,
    solid: TablerIcons.tableFilled,
  );
  static const TackGlyph alignLeft = TackGlyph(TablerIcons.alignLeft);
  static const TackGlyph alignCenter = TackGlyph(TablerIcons.alignCenter);
  static const TackGlyph alignRight = TackGlyph(TablerIcons.alignRight);

  // Whiteboard & Canvas Tools
  static const TackGlyph square = TackGlyph(
    TablerIcons.square,
    solid: TablerIcons.squareFilled,
  );
  static const TackGlyph diamond = TackGlyph(
    TablerIcons.diamond,
    solid: TablerIcons.diamondFilled,
  );
  static const TackGlyph flow = TackGlyph(TablerIcons.gitBranch);
  static const TackGlyph cursor = selectSvg;
  static const TackGlyph hand = handSvg;
  static const TackGlyph move = TackGlyph(TablerIcons.arrowsMove);
  static const TackGlyph photo = imageSvg;
  static const TackGlyph camera = TackGlyph(
    TablerIcons.camera,
    solid: TablerIcons.cameraFilled,
  );
  static const TackGlyph minus = TackGlyph(TablerIcons.minus);
  static const TackGlyph pencil = drawSvg;
  static const TackGlyph link = TackGlyph(
    TablerIcons.link,
    solid: TablerIcons.linkFilled,
  );
  static const TackGlyph pin = TackGlyph(
    TablerIcons.pin,
    solid: TablerIcons.pinFilled,
  );
  static const TackGlyph stickyNote = TackGlyph(TablerIcons.note);
  static const TackGlyph map = TackGlyph(TablerIcons.map);
  static const TackGlyph scan = TackGlyph(TablerIcons.scan);
  static const TackGlyph maximize = TackGlyph(TablerIcons.maximize);
  static const TackGlyph collapse = TackGlyph(TablerIcons.minimize);
  static const TackGlyph arrowLeftRight =
      TackGlyph(TablerIcons.arrowsLeftRight);
  static const TackGlyph bolt = TackGlyph(
    TablerIcons.bolt,
    solid: TablerIcons.boltFilled,
  );
  static const TackGlyph sparkles = TackGlyph(
    TablerIcons.sparkles,
    solid: TablerIcons.sparklesFilled,
  );
  static const TackGlyph briefcase = TackGlyph(
    TablerIcons.briefcase,
    solid: TablerIcons.briefcaseFilled,
  );
  static const TackGlyph calendar = TackGlyph(
    TablerIcons.calendar,
    solid: TablerIcons.calendarFilled,
  );
  static const TackGlyph lock = TackGlyph(
    TablerIcons.lock,
    solid: TablerIcons.lockFilled,
  );

  // Status & Feedback
  static const TackGlyph info = TackGlyph(
    TablerIcons.infoCircle,
    solid: TablerIcons.infoCircleFilled,
  );
  static const TackGlyph warning = TackGlyph(
    TablerIcons.alertTriangle,
    solid: TablerIcons.alertTriangleFilled,
  );
  static const TackGlyph error = TackGlyph(
    TablerIcons.alertCircle,
    solid: TablerIcons.alertCircleFilled,
  );
  static const TackGlyph success = checkCircle;
  static const TackGlyph flag = TackGlyph(
    TablerIcons.flag,
    solid: TablerIcons.flagFilled,
  );
  static const TackGlyph refresh = TackGlyph(TablerIcons.refresh);
  static const TackGlyph save = TackGlyph(
    TablerIcons.deviceFloppy,
    solid: TablerIcons.deviceFloppyFilled,
  );
  static const TackGlyph shield = TackGlyph(
    TablerIcons.shield,
    solid: TablerIcons.shieldFilled,
  );
  static const TackGlyph lightbulb = TackGlyph(
    TablerIcons.bulb,
    solid: TablerIcons.bulbFilled,
  );
  static const TackGlyph workflow = TackGlyph(
    TablerIcons.sitemap,
    solid: TablerIcons.sitemapFilled,
  );
  static const TackGlyph layers = TackGlyph(
    TablerIcons.stack2,
    solid: TablerIcons.stack2Filled,
  );
  static const TackGlyph arrowUp = TackGlyph(TablerIcons.arrowUp);
  static const TackGlyph arrowDown = TackGlyph(TablerIcons.arrowDown);
  static const TackGlyph arrowLeft = TackGlyph(TablerIcons.arrowLeft);
  static const TackGlyph arrowRight = TackGlyph(TablerIcons.arrowRight);

  // Editor & Canvas Extras
  static const TackGlyph add = plusSvg;
  static const TackGlyph alert = warning;
  static const TackGlyph crop = TackGlyph(TablerIcons.crop);
  static const TackGlyph expandNavigation = TackGlyph(
    TablerIcons.layoutSidebarLeftExpand,
    solid: TablerIcons.layoutSidebarLeftExpandFilled,
  );
  static const TackGlyph grid = TackGlyph(TablerIcons.gridDots);
  static const TackGlyph imageTool = TackGlyph(TablerIcons.photoPlus);
  static const TackGlyph nestedList = TackGlyph(TablerIcons.listTree);
  static const TackGlyph paragraph = TackGlyph(TablerIcons.pilcrow);
  static const TackGlyph smile = TackGlyph(
    TablerIcons.moodSmile,
    solid: TablerIcons.moodSmileFilled,
  );
  static const TackGlyph textTool = textSvg;
  static const TackGlyph visibility = eyeSvg;
}

/// Unified icon widget supporting [TackGlyph] pairs (outline/solid) and
/// raw [IconData] values.
class TackIcon extends StatelessWidget {
  final dynamic icon;
  final double size;
  final Color? color;
  final dynamic style;

  const TackIcon(
    this.icon, {
    super.key,
    this.size = 22.0,
    this.color,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeIconColor = IconTheme.of(context).color;
    final effectiveColor =
        color ??
        themeIconColor ??
        (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    if (icon is TackGlyph) {
      final glyphSpec = icon as TackGlyph;
      final resolvedStyle = style == HeroIconStyle.solid
          ? HeroIconStyle.solid
          : HeroIconStyle.outline;
      final glyph = glyphSpec.resolve(resolvedStyle);
      final iconWidget = Icon(
        glyph,
        size: size,
        color: effectiveColor,
      );

      if (glyphSpec.opticalScale == 1.0) {
        return SizedBox(
          width: size,
          height: size,
          child: Center(child: iconWidget),
        );
      }

      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Transform.scale(
            scale: glyphSpec.opticalScale,
            child: iconWidget,
          ),
        ),
      );
    }

    if (icon is IconData) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(
            icon as IconData,
            size: size,
            color: effectiveColor,
          ),
        ),
      );
    }

    return SizedBox(width: size, height: size);
  }
}

/// Custom tactile Pin Badge matching Tack's visual language.
class TackPinBadge extends StatelessWidget {
  final Color? color;
  final double size;
  final bool showIcon;

  const TackPinBadge({
    super.key,
    this.color,
    this.size = 14.0,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final resolvedColor = color ?? tokens.accentPin;

    if (!showIcon) {
      return Container(
        width: size * 0.65,
        height: size * 0.65,
        decoration: BoxDecoration(
          color: resolvedColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: tokens.surfacePrimary.withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
      );
    }

    return TackIcon(
      TackIcons.pin,
      size: size,
      color: resolvedColor,
      style: HeroIconStyle.solid,
    );
  }
}
