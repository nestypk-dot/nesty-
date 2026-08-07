import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../shared/widgets/property_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/providers/properties_provider.dart';

class SearchResultsScreen extends ConsumerWidget {
  final String? category;
  const SearchResultsScreen({super.key, this.category});

  bool _matchesCategory(String propertyCategory, String targetCategory) {
    if (targetCategory == 'All Types') return true;
    
    final propCatLower = propertyCategory.toLowerCase();
    final targetLower = targetCategory.toLowerCase();
    
    if (targetLower == 'apartments') {
      return propCatLower == 'apartments' || propCatLower == 'suites' || propCatLower == 'apartment';
    } else if (targetLower == 'houses') {
      return propCatLower == 'houses' || propCatLower == 'villas' || propCatLower == 'cottages' || propCatLower == 'house' || propCatLower == 'villa' || propCatLower == 'cottage';
    } else if (targetLower == 'rooms') {
      return propCatLower == 'rooms' || propCatLower == 'resort' || propCatLower == 'room' || propCatLower == 'resorts';
    }
    
    return propCatLower == targetLower;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allProperties = ref.watch(allPropertiesProvider);
    final filteredProperties = category == null || category == 'All Types'
        ? allProperties
        : allProperties.where((p) => _matchesCategory(p.category, category!)).toList();

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
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // 1. Top Search Header
                  _buildSearchHeader(context, category),
                  
                  // 2. Sort & Stats Header
                  _buildStatsHeader(context, filteredProperties.length),

                  // 3. Results List
                  Expanded(
                    child: filteredProperties.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off_rounded, size: 64, color: AppTheme.primaryColor.withOpacity(0.3)),
                                const SizedBox(height: 16),
                                Text(
                                  'No stays found in this category',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Try searching all types or checking back later.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredProperties.length,
                            itemBuilder: (context, index) {
                              final property = filteredProperties[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 32),
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
                ],
              ),

              // 4. Floating Map Toggle Button
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: _buildMapToggle(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context, String? selectedCategory) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/search'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.sectionColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedCategory != null && selectedCategory != 'All Types'
                          ? '$selectedCategory in Pakistan'
                          : 'Stays in Pakistan',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                    ),
                    Text(
                      'Safe & verified • 2 guests',
                      style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => context.push('/filters'),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Icon(Icons.tune, size: 18, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$count stays found',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          GestureDetector(
            onTap: () {
              // Show sort options
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: const [
                  Text('Sort', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 18, color: AppTheme.textPrimary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapToggle(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/map'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.textPrimary.withOpacity(0.9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: AppTheme.surfaceShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Show map',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.map_outlined, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
