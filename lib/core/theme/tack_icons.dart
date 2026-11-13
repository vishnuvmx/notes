import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'app_colors.dart';

enum HeroIconStyle { outline, solid }

/// Central Iconography for Tack powered by Lucide Icons and custom SVGs.
/// Follows docs/design/07-design-system.md §6:
/// - Single `TackIcon` wrapper across the app.
/// - Semantic fixes: sort != list-view, saving != undo, forward chevron != chevron-down.
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

  // Primary Navigation (5-slot bar: Today · Library · + Capture · Boards · Search)
  static const IconData today = LucideIcons.calendarCheck2;
  static const IconData library = LucideIcons.library;
  static const IconData inbox = LucideIcons.inbox;
  static const IconData boards = LucideIcons.gitFork;
  static const IconData home = LucideIcons.sun;
  static const IconData notes = LucideIcons.fileText;
  static const IconData sticky = LucideIcons.pin;
  static const IconData whiteboard = LucideIcons.gitFork;
  static const IconData clipboard = LucideIcons.inbox;
  static const IconData plus = LucideIcons.plus;

  // Actions & Controls (Semantic fixes per 07-design-system.md §6)
  static const IconData menu = LucideIcons.menu;
  static const IconData search = LucideIcons.search;
  static const IconData close = LucideIcons.x;
  static const IconData check = LucideIcons.check;
  static const IconData checkCircle = LucideIcons.circleCheck;
  static const IconData back = LucideIcons.arrowLeft;
  static const IconData more = LucideIcons.ellipsis;
  static const IconData share = LucideIcons.share2;
  static const IconData copy = LucideIcons.copy;
  static const IconData exportData = LucideIcons.upload;
  static const IconData importData = LucideIcons.download;
  static const IconData undo = LucideIcons.undo2;
  static const IconData redo = LucideIcons.redo2;
  static const IconData palette = LucideIcons.palette;
  static const IconData clock = LucideIcons.clock;
  static const IconData sort = LucideIcons.arrowUpDown;
  static const IconData saving = LucideIcons.refreshCw;
  static const IconData command = LucideIcons.terminal;
  static const IconData task = LucideIcons.squareCheckBig;
  static const IconData taskOpen = LucideIcons.square;
  static const IconData folder = LucideIcons.folder;
  static const IconData folderPlus = LucideIcons.folderPlus;
  static const IconData graph = LucideIcons.network;

  // Views & Folders
  static const IconData gridView = LucideIcons.layoutGrid;
  static const IconData listView = LucideIcons.arrowUpDown; // Semantic sort alias
  static const IconData star = LucideIcons.pin; // Pin replaces Favorite star
  static const IconData archive = LucideIcons.archive;
  static const IconData trash = LucideIcons.trash2;
  static const IconData settings = LucideIcons.settings;
  static const IconData sun = LucideIcons.sun;
  static const IconData moon = LucideIcons.moon;
  static const IconData user = LucideIcons.circleUser;
  static const IconData notification = LucideIcons.bell;
  static const IconData chevronDown = LucideIcons.chevronDown;
  static const IconData chevronUp = LucideIcons.chevronUp;
  static const IconData chevronLeft = LucideIcons.chevronLeft;
  static const IconData chevronRight = LucideIcons.chevronRight;
  static const IconData edit = LucideIcons.pencil;
  static const IconData reader = LucideIcons.bookOpen;
  static const IconData tag = LucideIcons.hash;
  static const IconData eye = LucideIcons.eye;
  static const IconData eyeOff = LucideIcons.eyeOff;
  static const IconData imageOff = LucideIcons.imageOff;
  static const IconData externalLink = LucideIcons.externalLink;

  // Board shapes & tools
  static const IconData play = LucideIcons.play;
  static const IconData square = LucideIcons.square;
  static const IconData diamond = LucideIcons.diamond;
  static const IconData flow = LucideIcons.gitFork;
  static const IconData cursor = LucideIcons.mousePointer;
  static const IconData hand = LucideIcons.hand;
  static const IconData move = LucideIcons.move;
  static const IconData photo = LucideIcons.image;
  static const IconData camera = LucideIcons.camera;
  static const IconData minus = LucideIcons.minus;
  static const IconData pencil = LucideIcons.pencil;
  static const IconData link = LucideIcons.link2;
  static const IconData pin = LucideIcons.pin;
  static const IconData stickyNote = LucideIcons.stickyNote;
  static const IconData map = LucideIcons.map;
  static const IconData scan = LucideIcons.scan;
  static const IconData maximize = LucideIcons.maximize2;
  static const IconData arrowLeftRight = LucideIcons.arrowLeftRight;

  // Tag & category aliases
  static const IconData bolt = LucideIcons.zap;
  static const IconData sparkles = LucideIcons.sparkles;
  static const IconData briefcase = LucideIcons.briefcase;
  static const IconData calendar = LucideIcons.calendar;
  static const IconData lock = LucideIcons.lock;
}

/// Aesthetic Icon builder with consistent sizing and token-resolved colors.
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
    final tokens = TackTokens.of(context);
    final effectiveColor = color ??
        IconTheme.of(context).color ??
        tokens.textPrimary;

    if (icon is String) {
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

/// Bespoke Pin Motif widget (`06-design-directions.md` Direction A: "Paper & Pin").
/// Used on pinned cards, active nav slot dot, and board ports.
class TackPinBadge extends StatelessWidget {
  final double size;
  final bool showIcon;
  final Color? color;

  const TackPinBadge({
    super.key,
    this.size = 14,
    this.showIcon = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TackTokens.of(context);
    final resolvedColor = color ?? tokens.accentPin;
    if (!showIcon) {
      return Semantics(
        label: 'Pinned',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: resolvedColor,
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    return Semantics(
      label: 'Pinned',
      child: Icon(
        TackIcons.pin,
        size: size,
        color: resolvedColor,
      ),
    );
  }
}
