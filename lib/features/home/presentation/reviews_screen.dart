import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/review.dart';

class ReviewsScreen extends StatelessWidget {
  final String propertyId;
  final double averageRating;
  final int totalReviews;

  const ReviewsScreen({
    super.key,
    required this.propertyId,
    required this.averageRating,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Reviews ($totalReviews)',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Rating Summary Header
            _buildRatingSummary(context),
            
            const SizedBox(height: 32),
            const Divider(color: AppTheme.borderColor, thickness: 0.5),
            const SizedBox(height: 32),

            // 2. Reviews List Header
            Text(
              '$totalReviews reviews',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // 3. Reviews List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mockReviews.length,
              separatorBuilder: (context, index) => const SizedBox(height: 32),
              itemBuilder: (context, index) {
                return _buildReviewItem(context, mockReviews[index]);
              },
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSummary(BuildContext context) {
    // Mock counts for rating distribution
    final distribution = {
      5: 85,
      4: 15,
      3: 5,
      2: 2,
      1: 1,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Average Rating Big Text
        Column(
          children: [
            Text(
              averageRating.toString(),
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < averageRating.floor() ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: AppTheme.textPrimary,
                  size: 16,
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              '$totalReviews total',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        const SizedBox(width: 48),

        // Distribution Bars
        Expanded(
          child: Column(
            children: List.generate(5, (index) {
              final star = 5 - index;
              final count = distribution[star] ?? 0;
              final percentage = count / 108; // Total mock sum

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      star.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: AppTheme.sectionColor,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.textPrimary),
                          minHeight: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItem(BuildContext context, Review review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User Meta
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: CachedNetworkImageProvider(review.userImageUrl),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(review.date),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Review Content
        Text(
          review.comment,
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w400,
          ),
        ),
        
        if (review.images != null && review.images!.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: review.images!.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: review.images![index],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 16),
        InkWell(
          onTap: () {},
          child: const Text(
            'Show more',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
