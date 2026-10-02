import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum HeroIconStyle { outline, solid }

/// Central Minimalist & Modern Iconography for Tack powered by custom SVGs and Lucide Icons.
class TackIcons {
  TackIcons._();

  // Custom App SVGs from /icons
  static const String homeSvg = 'icons/icon-home.svg';
  static const String notesSvg = 'icons/icon-notes.svg';
  static const String whiteboardSvg = 'icons/icon-whiteboard.svg';
  static const String clipboardSvg = 'icons/icon-clipboard.svg';
  static const String plusSvg = 'icons/icon-plus.svg';
  static const String selectSvg = 'icons/icon-select.svg';
  static const String handSvg = 'icons/icon-hand.svg';
  static const String connectorSvg = 'icons/icon-connector.svg';
  static const String textSvg = 'icons/icon-text.svg';
  static const String imageSvg = 'icons/icon-image.svg';
  static const String drawSvg = 'icons/icon-draw.svg';
  static const String editSvg = 'icons/icon-edit.svg';
  static const String eyeSvg = 'icons/icon-eye.svg';
  static const String undoSvg = 'icons/icon-undo.svg';
  static const String redoSvg = 'icons/icon-redo.svg';
  static const String searchSvg = 'icons/icon-search.svg';
  static const String copySvg = 'icons/icon-copy.svg';
  static const String pasteSvg = 'icons/icon-paste.svg';

  // Navigation (Modern & minimal)
  static const IconData home = LucideIcons.home;
  static const IconData notes = LucideIcons.fileText;
  static const IconData sticky = LucideIcons.stickyNote;
  static const IconData whiteboard = LucideIcons.penTool;
  static const IconData clipboard = LucideIcons.clipboardList;
  static const IconData plus = LucideIcons.plus;

  // Actions & Controls
  static const IconData menu = LucideIcons.menu;
  static const IconData search = LucideIcons.search;
  static const IconData close = LucideIcons.x;
  static const IconData check = LucideIcons.check;
  static const IconData checkCircle = LucideIcons.checkCircle2;
  static const IconData back = LucideIcons.arrowLeft;
  static const IconData more = LucideIcons.moreHorizontal;
  static const IconData share = LucideIcons.share2;
  static const IconData copy = LucideIcons.copy;
  static const IconData exportData = LucideIcons.upload;
  static const IconData importData = LucideIcons.download;
  static const IconData undo = LucideIcons.undo;
  static const IconData redo = LucideIcons.redo;
  static const IconData palette = LucideIcons.palette;
  static const IconData clock = LucideIcons.clock;

  // Views & Folders
  static const IconData gridView = LucideIcons.layoutGrid;
  static const IconData listView = LucideIcons.list;
  static const IconData star = LucideIcons.star;
  static const IconData archive = LucideIcons.archive;
  static const IconData trash = LucideIcons.trash2;
  static const IconData settings = LucideIcons.settings;
  static const IconData sun = LucideIcons.sun;
  static const IconData moon = LucideIcons.moon;
  static const IconData user = LucideIcons.user;
  static const IconData notification = LucideIcons.bell;
  static const IconData chevronDown = LucideIcons.chevronDown;
  static const IconData chevronUp = LucideIcons.chevronUp;
  static const IconData edit = LucideIcons.pencil;
  static const IconData reader = LucideIcons.bookOpen;
  static const IconData tag = LucideIcons.tag;

  // Whiteboard shapes & tools
  static const IconData play = LucideIcons.play;
  static const IconData square = LucideIcons.square;
  static const IconData diamond = LucideIcons.diamond;
  static const IconData flow = LucideIcons.gitFork;
  static const IconData cursor = LucideIcons.mousePointer;
  static const IconData hand = LucideIcons.hand;
  static const IconData photo = LucideIcons.image;
  static const IconData camera = LucideIcons.camera;
  static const IconData minus = LucideIcons.minus;
  static const IconData pencil = LucideIcons.pencil;
  static const IconData link = LucideIcons.link;
  static const IconData pin = LucideIcons.pin;

  // Tag & category aliases
  static const IconData bolt = LucideIcons.zap;
  static const IconData briefcase = LucideIcons.briefcase;
  static const IconData calendar = LucideIcons.calendar;
  static const IconData lock = LucideIcons.lock;
}

/// Aesthetic Icon builder with consistent sizing and sleek custom SVG & Lucide styling.
class TackIcon extends StatelessWidget {
  final dynamic icon;
  final double size;
  final Color? color;
  final dynamic style;

  const TackIcon(
    this.icon, {
    super.key,
    this.size = 20,
    this.color,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ??
        IconTheme.of(context).color ??
        (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF191A23));

    if (icon is String) {
      // SVGs have a 24x24 bounding box with 16x16 actual icon art (4px padding all around).
      // Scale by 1.5x so the visible icon glyph matches the target visual size (16 * 1.5 = 24).
      final effectiveSvgSize = size * 1.5;
      return SvgPicture.asset(
        icon as String,
        width: effectiveSvgSize,
        height: effectiveSvgSize,
        colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
      );
    }

    if (icon is IconData) {
      return Icon(
        icon as IconData,
        size: size,
        color: effectiveColor,
      );
    }

    return SizedBox(width: size, height: size);
  }
}
