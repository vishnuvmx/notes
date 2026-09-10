import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';

export 'package:heroicons/heroicons.dart';

/// Central Cute & Aesthetic Iconography for Tack using HeroIcons.
/// Features soft rounded caps, playful weights, and modern outline/solid styles.
class TackIcons {
  TackIcons._();

  // Navigation
  static const HeroIcons home = HeroIcons.home;
  static const HeroIcons notes = HeroIcons.documentText;
  static const HeroIcons sticky = HeroIcons.bookmark;
  static const HeroIcons whiteboard = HeroIcons.pencilSquare;
  static const HeroIcons clipboard = HeroIcons.clipboardDocumentList;
  static const HeroIcons plus = HeroIcons.plus;

  // Actions & Controls
  static const HeroIcons menu = HeroIcons.bars3BottomLeft;
  static const HeroIcons search = HeroIcons.magnifyingGlass;
  static const HeroIcons close = HeroIcons.xMark;
  static const HeroIcons check = HeroIcons.check;
  static const HeroIcons checkCircle = HeroIcons.checkCircle;
  static const HeroIcons back = HeroIcons.arrowLeft;
  static const HeroIcons more = HeroIcons.ellipsisVertical;
  static const HeroIcons share = HeroIcons.share;
  static const HeroIcons copy = HeroIcons.clipboardDocument;
  static const HeroIcons undo = HeroIcons.arrowUturnLeft;
  static const HeroIcons redo = HeroIcons.arrowUturnRight;
  static const HeroIcons palette = HeroIcons.swatch;

  // Views & Folders
  static const HeroIcons gridView = HeroIcons.squares2x2;
  static const HeroIcons listView = HeroIcons.queueList;
  static const HeroIcons star = HeroIcons.star;
  static const HeroIcons archive = HeroIcons.archiveBox;
  static const HeroIcons trash = HeroIcons.trash;
  static const HeroIcons settings = HeroIcons.cog6Tooth;
  static const HeroIcons sun = HeroIcons.sun;
  static const HeroIcons moon = HeroIcons.moon;
  static const HeroIcons user = HeroIcons.user;
  static const HeroIcons notification = HeroIcons.bell;
  static const HeroIcons chevronDown = HeroIcons.chevronDown;
  static const HeroIcons tag = HeroIcons.tag;

  // Whiteboard shapes & tools
  static const HeroIcons play = HeroIcons.play;
  static const HeroIcons square = HeroIcons.stop;
  static const HeroIcons diamond = HeroIcons.cube;
  static const HeroIcons flow = HeroIcons.arrowTrendingUp;
  static const HeroIcons cursor = HeroIcons.cursorArrowRays;
  static const HeroIcons hand = HeroIcons.handRaised;
  static const HeroIcons photo = HeroIcons.photo;
  static const HeroIcons pin = HeroIcons.mapPin;
}

/// Aesthetic HeroIcon builder with consistent sizing and cute styling.
class TackIcon extends StatelessWidget {
  final HeroIcons icon;
  final double size;
  final Color? color;
  final HeroIconStyle style;

  const TackIcon(
    this.icon, {
    super.key,
    this.size = 22,
    this.color,
    this.style = HeroIconStyle.outline,
  });

  @override
  Widget build(BuildContext context) {
    return HeroIcon(
      icon,
      size: size,
      color: color,
      style: style,
    );
  }
}
