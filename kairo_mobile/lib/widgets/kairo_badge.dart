import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum KairoBadgeVariant { success, error, warning, info, neutral }

class KairoBadge extends StatelessWidget {
  final String text;
  final KairoBadgeVariant variant;
  final IconData? icon;

  const KairoBadge({
    super.key,
    required this.text,
    this.variant = KairoBadgeVariant.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (variant) {
      case KairoBadgeVariant.success:
        bgColor = AppColors.success.withOpacity(0.15);
        textColor = AppColors.success;
        break;
      case KairoBadgeVariant.error:
        bgColor = AppColors.error.withOpacity(0.15);
        textColor = AppColors.error;
        break;
      case KairoBadgeVariant.warning:
        bgColor = AppColors.warning.withOpacity(0.15);
        textColor = AppColors.warning;
        break;
      case KairoBadgeVariant.info:
        bgColor = const Color(0xFF3B82F6).withOpacity(0.15);
        textColor = const Color(0xFF3B82F6);
        break;
      case KairoBadgeVariant.neutral:
      default:
        final theme = Theme.of(context);
        bgColor = theme.dividerColor;
        textColor = theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
