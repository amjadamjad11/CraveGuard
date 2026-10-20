import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A styled card widget with optional gradient or solid color background,
/// rounded corners, optional title/subtitle, child widget, and onTap callback.
class CgCard extends StatelessWidget {
  final Widget? child;
  final String? title;
  final String? subtitle;
  final Gradient? gradient;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const CgCard({
    super.key,
    this.child,
    this.title,
    this.subtitle,
    this.gradient,
    this.backgroundColor,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryDark,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryDark,
              ),
            ),
          ],
          if (child != null) const SizedBox(height: 16),
        ],
        ?child,
      ],
    );

    final decoration = BoxDecoration(
      gradient: gradient,
      color: gradient == null ? (backgroundColor ?? AppColors.cardDark) : null,
      borderRadius: BorderRadius.circular(borderRadius),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: Ink(
          decoration: decoration,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: AppColors.teal.withValues(alpha: 0.15),
            highlightColor: AppColors.teal.withValues(alpha: 0.05),
            child: Padding(
              padding: padding,
              child: content,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: decoration,
      padding: padding,
      child: content,
    );
  }
}
