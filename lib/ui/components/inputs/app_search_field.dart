import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';

/// Unified search input component for Tack (`07-design-system.md` §7).
/// Features:
/// - Single visual container border (`1dp` `border/subtle` unfocused, `1.5dp` `border/focus` focused)
/// - `r-sm` (`8dp`) corner radius
/// - Integrated clear (X) button with 48dp touch target
/// - Zero inner `InputDecoration` border leaking (`AppInputDecorations.bareWithHint`)
class AppSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final Widget? leading;
  final EdgeInsetsGeometry? margin;
  final double height;
  final double borderRadius;

  const AppSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Search notes, boards, tasks, or type an action…',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.leading,
    this.margin,
    this.height = 48,
    this.borderRadius = AppSpacing.rSm,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isLocalController = false;
  bool _isLocalFocusNode = false;
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = TextEditingController();
      _isLocalController = true;
    } else {
      _controller = widget.controller!;
    }

    if (widget.focusNode == null) {
      _focusNode = FocusNode();
      _isLocalFocusNode = true;
    } else {
      _focusNode = widget.focusNode!;
    }

    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_handleControllerChange);
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (_isLocalController) {
        _controller.removeListener(_handleControllerChange);
        _controller.dispose();
        _isLocalController = false;
      } else {
        _controller.removeListener(_handleControllerChange);
      }
      _controller = widget.controller ?? TextEditingController();
      _isLocalController = widget.controller == null;
      _controller.addListener(_handleControllerChange);
      _hasText = _controller.text.isNotEmpty;
    }

    if (oldWidget.focusNode != widget.focusNode) {
      if (_isLocalFocusNode) {
        _focusNode.removeListener(_handleFocusChange);
        _focusNode.dispose();
        _isLocalFocusNode = false;
      } else {
        _focusNode.removeListener(_handleFocusChange);
      }
      _focusNode = widget.focusNode ?? FocusNode();
      _isLocalFocusNode = widget.focusNode == null;
      _focusNode.addListener(_handleFocusChange);
      _isFocused = _focusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    _focusNode.removeListener(_handleFocusChange);
    if (_isLocalController) _controller.dispose();
    if (_isLocalFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    final nowHasText = _controller.text.isNotEmpty;
    if (_hasText != nowHasText && mounted) {
      setState(() => _hasText = nowHasText);
    }
  }

  void _handleFocusChange() {
    if (_isFocused != _focusNode.hasFocus && mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  void _handleClear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final bgColor = _isFocused ? tokens.surfacePrimary : tokens.canvasSunken;
    final borderColor = _isFocused ? tokens.borderFocus : tokens.borderSubtle;

    return Container(
      margin: widget.margin,
      height: widget.height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: borderColor,
          width: _isFocused ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.s3),
          widget.leading ??
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s1),
                child: TackIcon(
                  TackIcons.search,
                  size: 18,
                  color: _isFocused ? tokens.textPrimary : tokens.textTertiary,
                ),
              ),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              textInputAction: TextInputAction.search,
              onTapOutside: (_) => _focusNode.unfocus(),
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              style: AppTypography.bodySm(
                color: tokens.textPrimary,
                weight: FontWeight.w500,
              ),
              cursorColor: tokens.textPrimary,
              decoration: AppInputDecorations.bareWithHint(
                widget.hintText,
                hintStyle: AppTypography.bodySm(color: tokens.textTertiary),
              ),
            ),
          ),
          if (_hasText)
            Semantics(
              label: 'Clear search text',
              button: true,
              child: SizedBox(
                width: AppSpacing.minTouchTarget,
                height: AppSpacing.minTouchTarget,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: AppSpacing.minTouchTarget,
                    minHeight: AppSpacing.minTouchTarget,
                  ),
                  icon: TackIcon(
                    TackIcons.close,
                    size: 16,
                    color: tokens.textTertiary,
                  ),
                  onPressed: _handleClear,
                ),
              ),
            )
          else
            const SizedBox(width: AppSpacing.s3),
        ],
      ),
    );
  }
}
