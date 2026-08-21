import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum KairoButtonVariant { primary, secondary, outline, ghost }

class KairoButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final KairoButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool isFullWidth;

  const KairoButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = KairoButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color backgroundColor;
    Color foregroundColor;
    BorderSide? border;

    switch (variant) {
      case KairoButtonVariant.primary:
        backgroundColor = AppColors.primary;
        foregroundColor = Colors.white;
        break;
      case KairoButtonVariant.secondary:
        backgroundColor = theme.colorScheme.surface;
        foregroundColor = theme.textTheme.bodyLarge?.color ?? AppColors.textPrimary;
        border = BorderSide(color: theme.dividerColor);
        break;
      case KairoButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.primary;
        border = const BorderSide(color: AppColors.primary);
        break;
      case KairoButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = theme.textTheme.bodyLarge?.color ?? AppColors.textPrimary;
        break;
    }

    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: foregroundColor,
              strokeWidth: 2,
            ),
          )
        else if (icon != null)
          Icon(icon, size: 20, color: foregroundColor),
        if (isLoading || icon != null) const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: foregroundColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );

    final style = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: variant == KairoButtonVariant.primary ? 4 : 0,
      shadowColor: AppColors.primary.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: border ?? BorderSide.none,
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    );

    return isFullWidth
        ? SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: style,
              child: content,
            ),
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: style,
            child: content,
          );
  }
}
