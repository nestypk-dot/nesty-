import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/theme/app_theme.dart';

class FilterScreen extends ConsumerStatefulWidget {
  const FilterScreen({super.key});

  @override
  ConsumerState<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends ConsumerState<FilterScreen> {
  RangeValues _priceRange = const RangeValues(50, 500);
  String _selectedPropertyType = 'House';
  int _guests = 1;
  final Set<String> _selectedAmenities = {'Wifi'};

  final List<Map<String, dynamic>> _propertyTypes = [
    {'name': 'House', 'icon': Icons.home_outlined},
    {'name': 'Apartment', 'icon': Icons.apartment_outlined},
    {'name': 'Guesthouse', 'icon': Icons.cottage_outlined},
    {'name': 'Hotel', 'icon': Icons.hotel_outlined},
  ];

  final List<String> _amenities = [
    'Wifi', 'Kitchen', 'Pool', 'Free parking', 'Air conditioning', 'Washer', 'TV', 'Dryer'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Filters',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _priceRange = const RangeValues(50, 500);
                _selectedPropertyType = 'House';
                _guests = 1;
                _selectedAmenities.clear();
                _selectedAmenities.add('Wifi');
              });
            },
            child: const Text(
              'Reset',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 24),
                  
                  // Price Range
                  _buildSectionTitle('Price range'),
                  const Text(
                    'The average nightly price is \$124',
                    style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 24),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 1000,
                    divisions: 100,
                    activeColor: Theme.of(context).primaryColor,
                    inactiveColor: Colors.grey.shade200,
                    labels: RangeLabels(
                      '\$${_priceRange.start.round()}',
                      '\$${_priceRange.end.round()}',
                    ),
                    onChanged: (values) => setState(() => _priceRange = values),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPriceBox('min price', '\$${_priceRange.start.round()}'),
                      _buildPriceBox('max price', '\$${_priceRange.end.round()}'),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 32),

                  // Property Type
                  _buildSectionTitle('Property type'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _propertyTypes.map((type) {
                      final isSelected = _selectedPropertyType == type['name'];
                      return _buildPropertyTypeCard(
                        type['name'],
                        type['icon'],
                        isSelected,
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 32),

                  // Guests
                  _buildSectionTitle('Guests'),
                  const SizedBox(height: 16),
                  _buildGuestCounter(),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 32),

                  // Amenities
                  _buildSectionTitle('Amenities'),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _amenities.length,
                    itemBuilder: (context, index) {
                      final amenity = _amenities[index];
                      final isSelected = _selectedAmenities.contains(amenity);
                      return _buildAmenityItem(amenity, isSelected);
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildPriceBox(String label, String value) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        ],
      ),
    );
  }

  Widget _buildPropertyTypeCard(String name, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedPropertyType = name),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade50 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.black : Colors.grey.shade700),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                color: isSelected ? Colors.black : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestCounter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Number of guests', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            Text('Including adults and kids', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        Row(
          children: [
            _buildCounterButton(Icons.remove, () {
              if (_guests > 1) setState(() => _guests--);
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('$_guests', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            _buildCounterButton(Icons.add, () => setState(() => _guests++)),
          ],
        ),
      ],
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 18, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildAmenityItem(String name, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedAmenities.remove(name);
          } else {
            _selectedAmenities.add(name);
          }
        });
      },
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.white,
              border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade400),
              borderRadius: BorderRadius.circular(6),
            ),
            child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
