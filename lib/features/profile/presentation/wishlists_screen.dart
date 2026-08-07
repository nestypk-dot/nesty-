import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../shared/widgets/nesty_bottom_nav.dart';
import '../../../shared/widgets/property_card.dart';
import '../../../core/providers/auth_provider.dart';
import '../../home/providers/properties_provider.dart';

class WishlistsScreen extends ConsumerWidget {
  const WishlistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final allProperties = ref.watch(allPropertiesProvider);

    final wishlistItems = allProperties
        .where((p) => authState.favorites.contains(p.id))
        .toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: Text(
            'Wishlists',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: Colors.black,
            ),
          ),
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        body: SafeArea(
          child: wishlistItems.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: wishlistItems.length,
                  itemBuilder: (context, index) {
                    final property = wishlistItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: PropertyCard(
                        propertyId: property.id,
                        imageUrl: property.imageUrl,
                        location: property.location,
                        title: property.title,
                        price: property.price,
                        rating: property.rating,
                        category: property.category,
                        onTap: () => context.push('/property/${property.id}'),
                      ),
                    );
                  },
                ),
        ),
        bottomNavigationBar: const NestyBottomNav(currentIndex: 1),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFE6F4EA),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded, size: 48, color: Color(0xFF00674F)),
            ),
            const SizedBox(height: 24),
            Text(
              'Create your first wishlist',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'As you search, tap the heart icon to save your favorite stays and cabins in Pakistan here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00674F),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Start searching',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
