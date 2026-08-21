import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerPostCard extends StatelessWidget {
  const ShimmerPostCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ShimmerLoading(width: 48, height: 48, borderRadius: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ShimmerLoading(width: 150, height: 16),
                      const SizedBox(height: 8),
                      const ShimmerLoading(width: 100, height: 14),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const ShimmerLoading(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            const ShimmerLoading(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            const ShimmerLoading(width: 200, height: 14),
            const SizedBox(height: 16),
            const ShimmerLoading(
              width: double.infinity,
              height: 200,
              borderRadius: 12,
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerConnectionCard extends StatelessWidget {
  const ShimmerConnectionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: const ShimmerLoading(width: 56, height: 56, borderRadius: 28),
        title: const ShimmerLoading(width: 120, height: 16),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: ShimmerLoading(width: 80, height: 14),
        ),
        trailing: const ShimmerLoading(width: 80, height: 32, borderRadius: 16),
      ),
    );
  }
}

class ShimmerProjectCard extends StatelessWidget {
  const ShimmerProjectCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: ShimmerLoading(width: double.infinity, height: 20),
                ),
                const SizedBox(width: 16),
                const ShimmerLoading(width: 80, height: 24, borderRadius: 20),
              ],
            ),
            const SizedBox(height: 12),
            const ShimmerLoading(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            const ShimmerLoading(width: 200, height: 14),
            const SizedBox(height: 16),
            const Row(
              children: [
                ShimmerLoading(width: 60, height: 24, borderRadius: 12),
                SizedBox(width: 8),
                ShimmerLoading(width: 80, height: 24, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 16),
            const ShimmerLoading(width: double.infinity, height: 1),
            const SizedBox(height: 16),
            const ShimmerLoading(
              width: double.infinity,
              height: 40,
              borderRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}
