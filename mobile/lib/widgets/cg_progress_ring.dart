import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A circular progress ring widget with animated transitions,
/// center label, sub-label, and color that changes based on value.
class CgProgressRing extends StatelessWidget {
  final double value;
  final double size;
  final double strokeWidth;
  final String? centerLabel;
  final String? subLabel;
  final Color? overrideColor;
  final Duration animationDuration;

  const CgProgressRing({
    super.key,
    required this.value,
    this.size = 120,
    this.strokeWidth = 10,
    this.centerLabel,
    this.subLabel,
    this.overrideColor,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  Color get _ringColor {
    if (overrideColor != null) return overrideColor!;
    if (value <= 0.33) return AppColors.mintGreen;
    if (value <= 0.66) return AppColors.amber;
    return AppColors.coral;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: animationDuration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background track
              CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  value: 1.0,
                  strokeWidth: strokeWidth,
                  color: AppColors.navyLight.withValues(alpha: 0.4),
                ),
              ),
              // Progress arc
              CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  value: animatedValue,
                  strokeWidth: strokeWidth,
                  color: _ringColor,
                ),
              ),
              // Center labels
              if (centerLabel != null || subLabel != null)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (centerLabel != null)
                      Text(
                        centerLabel!,
                        style: TextStyle(
                          fontSize: size * 0.2,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                    if (subLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subLabel!,
                        style: TextStyle(
                          fontSize: size * 0.1,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final double strokeWidth;
  final Color color;

  _RingPainter({
    required this.value,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * value,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}
