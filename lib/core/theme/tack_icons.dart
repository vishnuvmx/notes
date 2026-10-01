import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum HeroIconStyle { outline, solid }

/// Central Minimalist & Modern Iconography for Tack powered by Lucide Icons.
/// Sleek, consistent stroke weight, subtle rounded corners, zero clunky brutalism or playful slop.
class TackIcons {
  TackIcons._();

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

/// Aesthetic Icon builder with consistent sizing and sleek Lucide styling.
class TackIcon extends StatelessWidget {
  final IconData icon;
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
    return Icon(
      icon,
      size: size,
      color: color,
    );
  }
}
