import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final int count;
  final double size;

  const StarRating({
    super.key,
    required this.rating,
    this.count = 0,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.star, size: 14, color: Colors.amber),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: -0.2,
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($count)',
            style: TextStyle(
              fontSize: size,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
