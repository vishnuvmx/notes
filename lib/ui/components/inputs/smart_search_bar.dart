import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../state/workspace_provider.dart';

/// Animated search bar widget for Tack with cute HeroIcons.
class SmartSearchBar extends StatefulWidget {
  final VoidCallback onClose;

  const SmartSearchBar({super.key, required this.onClose});

  @override
  State<SmartSearchBar> createState() => _SmartSearchBarState();
}

class _SmartSearchBarState extends State<SmartSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initial = context.read<WorkspaceProvider>().searchQuery;
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspace = context.watch<WorkspaceProvider>();
    final iconColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
          borderRadius: AppSpacing.roundedPill,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
        child: TextField(
          controller: _controller,
          autofocus: true,
          style: theme.textTheme.bodyLarge,
          onChanged: (val) => workspace.setSearchQuery(val),
          decoration: InputDecoration(
            hintText: 'Search notes, stickies, whiteboards...',
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: TackIcon(TackIcons.search, size: 20, color: iconColor),
            ),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: TackIcon(TackIcons.close, size: 18, color: iconColor),
                    onPressed: () {
                      _controller.clear();
                      workspace.setSearchQuery('');
                    },
                  )
                : IconButton(
                    icon: TackIcon(TackIcons.close, size: 18, color: iconColor),
                    onPressed: widget.onClose,
                  ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
