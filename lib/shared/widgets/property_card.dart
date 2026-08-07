import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'nesty_image.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';

class PropertyCard extends ConsumerStatefulWidget {
  final String propertyId;
  final String imageUrl;
  final String location;
  final String title;
  final double price;
  final double rating;
  final String? category;
  final VoidCallback? onTap;

  const PropertyCard({
    super.key,
    required this.propertyId,
    required this.imageUrl,
    required this.location,
    required this.title,
    required this.price,
    required this.rating,
    this.category,
    this.onTap,
  });

  @override
  ConsumerState<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends ConsumerState<PropertyCard> {
  @override
  Widget build(BuildContext context) {
    final isFavorite = ref.watch(authProvider).favorites.contains(widget.propertyId);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            AspectRatio(
              aspectRatio: 1.0, 
              child: Stack(
                children: [
                  Hero(
                    tag: 'property_image_${widget.imageUrl}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: NestyImage(
                        src: widget.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  // Heart Icon
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        ref.read(authProvider.notifier).toggleFavorite(widget.propertyId);
                      },
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? AppTheme.primaryColor : Colors.white,
                        size: 24,
                        shadows: const [
                          Shadow(
                            color: Colors.black26, blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Category Tag
                  if (widget.category != null)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 4, offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.category!.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF222222),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Details Section
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 4, right: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.black),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.location,
                           style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            widget.rating.toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.plusJakartaSans(color: Colors.black, fontSize: 16),
                          children: [
                            TextSpan(
                              text: 'PKR ${NumberFormat("#,##0", "en_US").format(widget.price)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w900, 
                                color: AppTheme.primaryColor, // Emerald Green
                                fontSize: 19,
                              ),
                            ),
                            TextSpan(
                              text: ' / night',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w900, 
                                color: Colors.black,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
