import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// "Make Today's" / "Quick Tack" Action Widget matching the Figma design.
/// Features a vivid red squircle container, centered bold header,
/// and a white card with 3 tactile action items.
typedef QuickTackWidget = MakeTodaysWidget;

class MakeTodaysWidget extends StatelessWidget {
  final VoidCallback? onWorthRemembering;
  final VoidCallback? onDoneWorks;
  final VoidCallback? onPlanDay;
  final VoidCallback? onHeaderTap;
  final double? width;
  final double? height;

  const MakeTodaysWidget({
    super.key,
    this.onWorthRemembering,
    this.onDoneWorks,
    this.onPlanDay,
    this.onHeaderTap,
    this.width,
    this.height,
  });

  static const Color widgetRed = Color(0xFFE50000);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      constraints: const BoxConstraints(
        minWidth: 260,
        maxWidth: 380,
      ),
      decoration: BoxDecoration(
        color: widgetRed,
        borderRadius: BorderRadius.circular(42),
        boxShadow: [
          BoxShadow(
            color: widgetRed.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Centered Header: "Make Today's"
          GestureDetector(
            onTap: onHeaderTap,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                'Make Today’s',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ),
          ),

          // Inner White Card with 3 Action Rows
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Worth remembering....
                _buildActionRow(
                  label: 'Worth remembering....',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onWorthRemembering?.call();
                  },
                ),

                const Divider(height: 1, thickness: 0.6, color: Color(0xFFF0F1F4)),

                // 2. Done with your works?
                _buildActionRow(
                  label: 'Done with your works?',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onDoneWorks?.call();
                  },
                ),

                const Divider(height: 1, thickness: 0.6, color: Color(0xFFF0F1F4)),

                // 3. Plan your day
                _buildActionRow(
                  label: 'Plan your day',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onPlanDay?.call();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.primaryDark.withValues(alpha: 0.06),
        highlightColor: AppColors.primaryDark.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              // Bold Black Plus Icon
              const Text(
                '+',
                style: TextStyle(
                  color: Color(0xFF000000),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 18),
              // Action Label
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    color: const Color(0xFF000000),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
