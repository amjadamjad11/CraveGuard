import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

/// Skeleton loading placeholders using the shimmer package.
/// Provides factory methods for common loading patterns.
class CgShimmerLoading extends StatelessWidget {
  final Widget child;

  const CgShimmerLoading({super.key, required this.child});

  /// A single card-shaped shimmer placeholder.
  factory CgShimmerLoading.card({
    Key? key,
    double height = 120,
    double borderRadius = 20,
  }) {
    return CgShimmerLoading(
      key: key,
      child: _ShimmerBox(height: height, borderRadius: borderRadius),
    );
  }

  /// A list of shimmer card placeholders.
  factory CgShimmerLoading.list({
    Key? key,
    int itemCount = 4,
    double itemHeight = 80,
    double spacing = 12,
  }) {
    return CgShimmerLoading(
      key: key,
      child: Column(
        children: List.generate(itemCount, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i < itemCount - 1 ? spacing : 0),
            child: _ShimmerBox(height: itemHeight, borderRadius: 16),
          );
        }),
      ),
    );
  }

  /// A text-line shimmer placeholder.
  factory CgShimmerLoading.text({
    Key? key,
    int lines = 3,
    double lineHeight = 14,
    double spacing = 10,
  }) {
    return CgShimmerLoading(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(lines, (i) {
          // Last line is shorter to look natural
          final widthFactor = i == lines - 1 ? 0.6 : (i == 0 ? 0.9 : 1.0);
          return Padding(
            padding: EdgeInsets.only(bottom: i < lines - 1 ? spacing : 0),
            child: FractionallySizedBox(
              widthFactor: widthFactor,
              child: _ShimmerBox(height: lineHeight, borderRadius: 6),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardDark,
      highlightColor: AppColors.cardDarkElevated,
      child: child,
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double height;
  final double borderRadius;

  const _ShimmerBox({required this.height, required this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
