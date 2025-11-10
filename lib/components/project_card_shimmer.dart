import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ProjectCardShimmer extends StatelessWidget {
  const ProjectCardShimmer({super.key});

  Widget _buildShimmerBox(double height, double width, {double radius = 8}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildShimmerBox(40, 40, radius: 20),
                  const SizedBox(width: 10),
                  _buildShimmerBox(20, 120),
                ],
              ),
              const SizedBox(height: 12),

              _buildShimmerBox(200, double.infinity),

              const SizedBox(height: 12),

              _buildShimmerBox(24, double.infinity),
              const SizedBox(height: 8),

              Row(
                children: [
                  _buildShimmerBox(20, 60),
                  const SizedBox(width: 8),
                  _buildShimmerBox(20, 80),
                ],
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
