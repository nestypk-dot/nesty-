import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../home/domain/property.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/providers/properties_provider.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  const MapViewScreen({super.key});

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  int _selectedPropertyIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.85);

  @override
  Widget build(BuildContext context) {
    final properties = ref.watch(allPropertiesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Mock Google Map Background
          _buildMockMap(),

          // 2. Custom Pins (Price Bubbles)
          ..._buildPins(properties),

          // 3. Top Search & Controls (Airbnb Style)
          _buildTopControls(context),

          // 4. Bottom Property Carousel
          _buildPropertyCarousel(properties),
          
          // 5. Floating Action Buttons (Zoom/Locate)
          _buildFloatingButtons(),

          // 6. Center Bottom "Show list" Button
          _buildShowListButton(context),
        ],
      ),
    );
  }

  Widget _buildMockMap() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFE5E3DF), // Map background color
      ),
      child: Stack(
        children: [
          // A more realistic map image
          Opacity(
            opacity: 0.8,
            child: Image.network(
              'https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=2000',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // Add some grid lines or overlays if needed for "premium" feel
          Container(color: Colors.white.withOpacity(0.1)),
        ],
      ),
    );
  }

  List<Widget> _buildPins(List<Property> properties) {
    final positions = [
      const Offset(60, 280),
      const Offset(220, 220),
      const Offset(180, 400),
      const Offset(40, 480),
      const Offset(280, 350),
      const Offset(140, 150),
    ];

    return List.generate(properties.length, (index) {
      final property = properties[index];
      final isSelected = _selectedPropertyIndex == index;
      final pos = positions[index % positions.length];

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        left: pos.dx,
        top: pos.dy,
        child: GestureDetector(
          onTap: () {
            setState(() => _selectedPropertyIndex = index);
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: isSelected ? 1.15 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Text(
                'PKR ${NumberFormat("#,##0", "en_US").format(property.price)}',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTopControls(BuildContext context) {
    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black),
            ),
          ),
          const SizedBox(width: 12),
          // Search Pill (Airbnb Style)
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.search, color: AppTheme.primaryColor, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Murree',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Mar 15 – 20 • 2 guests',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 25,
                    color: Colors.grey.shade200,
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, size: 20, color: Colors.black87),
                    onPressed: () => context.push('/filters'),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCarousel(List<Property> properties) {
    return Positioned(
      bottom: 110,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 120,
        child: PageView.builder(
          controller: _pageController,
          itemCount: properties.length,
          onPageChanged: (index) {
            setState(() => _selectedPropertyIndex = index);
          },
          itemBuilder: (context, index) {
            final property = properties[index];
            final isSelected = _selectedPropertyIndex == index;
            
            return AnimatedScale(
              duration: const Duration(milliseconds: 300),
              scale: isSelected ? 1.0 : 0.92,
              child: GestureDetector(
                onTap: () => context.push('/property/${property.id}'),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isSelected ? 0.15 : 0.08),
                        blurRadius: isSelected ? 25 : 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          property.imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              property.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                const SizedBox(width: 2),
                                  Text(
                                    '${property.rating}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                                  ),
                                Text(
                                  ' (${property.reviews})',
                                  style: TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(color: AppTheme.primaryColor, fontSize: 13),
                                children: [
                                  TextSpan(
                                    text: 'PKR ${NumberFormat("#,##0", "en_US").format(property.price)}',
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                                  ),
                                  const TextSpan(
                                    text: ' / night',
                                    style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShowListButton(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Show list',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.list_rounded, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Positioned(
      bottom: 250,
      right: 16,
      child: Column(
        children: [
          _buildActionButton(Icons.my_location),
          const SizedBox(height: 12),
          _buildActionButton(Icons.layers_outlined),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Icon(icon, size: 20, color: Colors.black87),
    );
  }
}
