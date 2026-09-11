import 'package:flutter/material.dart';

enum HeroIconStyle { outline, solid }

/// Central Cute & Tactile Iconography for Tack using Material 3 Rounded glyphs.
/// Features soft hemispherical caps, friendly organic curves, and warm stationery aesthetic.
class TackIcons {
  TackIcons._();

  // Navigation (Cute & tactile)
  static const IconData home = Icons.cottage_rounded;
  static const IconData notes = Icons.sticky_note_2_rounded;
  static const IconData sticky = Icons.bookmark_rounded;
  static const IconData whiteboard = Icons.draw_rounded;
  static const IconData clipboard = Icons.content_paste_rounded;
  static const IconData plus = Icons.add_rounded;

  // Actions & Controls
  static const IconData menu = Icons.notes_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData checkCircle = Icons.check_circle_rounded;
  static const IconData back = Icons.arrow_back_rounded;
  static const IconData more = Icons.more_horiz_rounded;
  static const IconData share = Icons.share_rounded;
  static const IconData copy = Icons.copy_rounded;
  static const IconData exportData = Icons.file_upload_rounded;
  static const IconData importData = Icons.file_download_rounded;
  static const IconData undo = Icons.undo_rounded;
  static const IconData redo = Icons.redo_rounded;
  static const IconData palette = Icons.palette_rounded;

  // Views & Folders
  static const IconData gridView = Icons.grid_view_rounded;
  static const IconData listView = Icons.view_agenda_rounded;
  static const IconData star = Icons.star_rounded;
  static const IconData archive = Icons.archive_rounded;
  static const IconData trash = Icons.delete_outline_rounded;
  static const IconData settings = Icons.tune_rounded;
  static const IconData sun = Icons.wb_sunny_rounded;
  static const IconData moon = Icons.nightlight_round;
  static const IconData user = Icons.face_rounded;
  static const IconData notification = Icons.notifications_rounded;
  static const IconData chevronDown = Icons.keyboard_arrow_down_rounded;
  static const IconData tag = Icons.label_rounded;

  // Whiteboard shapes & tools
  static const IconData play = Icons.stadium_rounded;
  static const IconData square = Icons.crop_square_rounded;
  static const IconData diamond = Icons.change_history_rounded;
  static const IconData flow = Icons.alt_route_rounded;
  static const IconData cursor = Icons.near_me_rounded;
  static const IconData hand = Icons.pan_tool_rounded;
  static const IconData photo = Icons.image_rounded;
  static const IconData minus = Icons.remove_rounded;
  static const IconData pencil = Icons.edit_rounded;
  static const IconData link = Icons.link_rounded;
  static const IconData pin = Icons.push_pin_rounded;

  // Tag & category aliases
  static const IconData bolt = Icons.bolt_rounded;
  static const IconData briefcase = Icons.work_rounded;
}

/// Aesthetic Icon builder with consistent sizing and cute rounded styling.
class TackIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final dynamic style;

  const TackIcon(
    this.icon, {
    super.key,
    this.size = 22,
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
