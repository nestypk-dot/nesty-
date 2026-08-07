import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/full_screen_image_gallery.dart';
import '../providers/listings_provider.dart';
import '../../home/domain/property.dart';
import '../../host_onboarding/data/host_profile_repository.dart';
import '../../host_onboarding/domain/host_profile.dart';

class AddPropertyScreen extends ConsumerStatefulWidget {
  const AddPropertyScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends ConsumerState<AddPropertyScreen> {
  int currentStep = 1;
  final int totalSteps = 8;
  String? selectedType;

  String? selectedProvince;
  String? selectedCity;

  int bedrooms = 1;
  int bathrooms = 1;
  int maxGuests = 2;
  bool isFamilyFriendly = true;
  bool isBachelorAllowed = false;

  final List<String> selectedAmenities = [];
  final List<String> uploadedPhotos = [];

  // Step 7: House Rules
  bool noSmoking = true;
  bool noParties = true;
  bool petsAllowed = false;
  TimeOfDay checkInTime = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay checkOutTime = const TimeOfDay(hour: 12, minute: 0);
  String selectedCancellationPolicy = 'Moderate - Full refund 5 days before';
  final List<String> selectedQuickRules = [];

  // Step 7: Discounts (Moved here & Optional)
  bool showDiscounts = false;
  final TextEditingController weeklyDiscountController = TextEditingController(
    text: '10',
  );
  final TextEditingController monthlyDiscountController = TextEditingController(
    text: '20',
  );

  // Step 8: Review
  final TextEditingController titleController = TextEditingController(
    text: 'House in Sukkur',
  );
  final TextEditingController descController = TextEditingController();
  final TextEditingController priceController = TextEditingController(
    text: '5000',
  );
  final TextEditingController cleaningFeeController = TextEditingController(
    text: '1000',
  );

  // Step 2 Address Controllers
  final TextEditingController areaController = TextEditingController();
  final TextEditingController blockController = TextEditingController();
  final TextEditingController houseController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController landmarkController = TextEditingController();

  // Step 4 Custom Amenities Controller
  final TextEditingController customAmenitiesController =
      TextEditingController();

  // Map Location Picker State Variables
  double selectedLatitude = 33.6844;
  double selectedLongitude = 73.0479;
  final MapController mapController = MapController();
  final TextEditingController mapSearchController = TextEditingController();
  bool isLocatingUser = false;
  bool isSearchingLocation = false;
  bool _showLocationSuggestions = false;
  List<String> _locationSuggestions = [];
  final FocusNode _mapSearchFocusNode = FocusNode();

  final Map<String, LatLng> cityCoords = {
    'Lahore': const LatLng(31.5204, 74.3587),
    'Rawalpindi': const LatLng(33.5651, 73.0169),
    'Faisalabad': const LatLng(31.4504, 73.1350),
    'Multan': const LatLng(30.1575, 71.5249),
    'Gujranwala': const LatLng(32.1877, 74.1945),
    'Karachi': const LatLng(24.8607, 67.0011),
    'Hyderabad': const LatLng(25.3960, 68.3578),
    'Sukkur': const LatLng(27.7244, 68.8228),
    'Larkana': const LatLng(27.5589, 68.2099),
    'Nawabshah': const LatLng(26.2483, 68.4096),
    'Peshawar': const LatLng(34.0151, 71.5249),
    'Mardan': const LatLng(34.1989, 72.0344),
    'Abbottabad': const LatLng(34.1688, 73.2215),
    'Swat': const LatLng(35.2227, 72.4258),
    'Kohat': const LatLng(33.5869, 71.4414),
    'Quetta': const LatLng(30.1798, 66.9750),
    'Gwadar': const LatLng(25.1264, 62.3224),
    'Khuzdar': const LatLng(27.8119, 66.6110),
    'Chaman': const LatLng(30.9224, 66.4597),
    'Zhob': const LatLng(31.3407, 69.4481),
    'Gilgit': const LatLng(35.9208, 74.3089),
    'Skardu': const LatLng(35.2974, 75.6329),
    'Hunza': const LatLng(36.3167, 74.6500),
    'Chilas': const LatLng(35.4128, 74.1039),
    'Muzaffarabad': const LatLng(34.3700, 73.4711),
    'Mirpur': const LatLng(33.1478, 73.7456),
    'Rawalakot': const LatLng(33.8576, 73.7607),
    'Kotli': const LatLng(33.5156, 73.9019),
    'Islamabad': const LatLng(33.6844, 73.0479),
  };

  Future<void> _reverseGeocode(double lat, double lon) async {
    setState(() {
      isLocatingUser = true;
    });
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&accept-language=en',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'NestyApp/1.0 (contact: support@nesty.com)'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        if (address != null) {
          final String city =
              address['city'] ??
              address['town'] ??
              address['village'] ??
              address['suburb'] ??
              '';
          final String road = address['road'] ?? '';
          final String suburb =
              address['suburb'] ??
              address['neighbourhood'] ??
              address['residential'] ??
              '';
          final String county = address['county'] ?? '';

          setState(() {
            if (suburb.isNotEmpty) {
              areaController.text = suburb;
            } else if (county.isNotEmpty) {
              areaController.text = county;
            }
            if (road.isNotEmpty) {
              streetController.text = road;
            }

            // Match province
            final String state = address['state'] ?? '';
            for (var prov in provinceCities.keys) {
              if (state.toLowerCase().contains(prov.toLowerCase()) ||
                  prov.toLowerCase().contains(state.toLowerCase())) {
                selectedProvince = prov;
                break;
              }
            }

            // Match city
            if (selectedProvince != null) {
              final cities = provinceCities[selectedProvince!]!;
              for (var c in cities) {
                if (city.toLowerCase().contains(c.toLowerCase()) ||
                    c.toLowerCase().contains(city.toLowerCase())) {
                  selectedCity = c;
                  break;
                }
              }
            }
          });
        }
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLocatingUser = false;
        });
      }
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    setState(() {
      isSearchingLocation = true;
    });
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1&accept-language=en',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'NestyApp/1.0 (contact: support@nesty.com)'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final String displayName = data[0]['display_name'] ?? '';

          setState(() {
            selectedLatitude = lat;
            selectedLongitude = lon;
            mapController.move(LatLng(lat, lon), 15.0);
          });

          await _reverseGeocode(lat, lon);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Location found: ${displayName.split(',').take(2).join(',')}',
              ),
              backgroundColor: const Color(0xFF00674F),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No locations found for your search.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error searching location: $e');
    } finally {
      if (mounted) {
        setState(() {
          isSearchingLocation = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLocatingUser = true;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location services are disabled. Please enable them in settings.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are denied.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        selectedLatitude = position.latitude;
        selectedLongitude = position.longitude;
        mapController.move(LatLng(position.latitude, position.longitude), 15.0);
      });

      await _reverseGeocode(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLocatingUser = false;
        });
      }
    }
  }

  void _updateLocationSuggestions(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _showLocationSuggestions = false;
        _locationSuggestions = [];
      });
      return;
    }
    final q = query.toLowerCase();
    final allLocations = [
      ...cityCoords.keys,
      ...provinceCities.values.expand((c) => c),
    ].toSet().toList();
    final matches = allLocations
        .where((loc) => loc.toLowerCase().contains(q))
        .take(6)
        .toList();
    setState(() {
      _locationSuggestions = matches;
      _showLocationSuggestions = matches.isNotEmpty;
    });
  }

  @override
  void dispose() {
    weeklyDiscountController.dispose();
    monthlyDiscountController.dispose();
    titleController.dispose();
    descController.dispose();
    priceController.dispose();
    cleaningFeeController.dispose();
    areaController.dispose();
    blockController.dispose();
    houseController.dispose();
    streetController.dispose();
    landmarkController.dispose();
    customAmenitiesController.dispose();
    _mapSearchFocusNode.removeListener(_handleMapSearchFocusChange);
    mapSearchController.dispose();
    _mapSearchFocusNode.dispose();
    super.dispose();
  }

  final List<String> quickRules = [
    'Quiet hours after 10 PM',
    'No outside guests',
    'Clean before checkout',
    'Report any damages',
  ];

  final List<Map<String, dynamic>> availableAmenities = [
    {'id': 'wifi', 'title': 'WiFi', 'urdu': null, 'icon': Icons.wifi},
    {
      'id': 'ac',
      'title': 'Air Conditioning',
      'urdu': 'اے سی',
      'icon': Icons.air,
    },
    {'id': 'kitchen', 'title': 'Kitchen', 'urdu': 'کچن', 'icon': Icons.kitchen},
    {'id': 'tv', 'title': 'TV', 'urdu': null, 'icon': Icons.tv},
    {
      'id': 'washing_machine',
      'title': 'Washing Machine',
      'urdu': 'واشنگ مشین',
      'icon': Icons.local_laundry_service_outlined,
    },
    {
      'id': 'parking',
      'title': 'Parking',
      'urdu': 'پارکنگ',
      'icon': Icons.directions_car_outlined,
    },
    {
      'id': 'generator',
      'title': 'Generator / Backup',
      'urdu': 'جنریٹر',
      'icon': Icons.electric_bolt_outlined,
    },
  ];

  final Map<String, List<String>> provinceCities = {
    'Punjab': ['Lahore', 'Rawalpindi', 'Faisalabad', 'Multan', 'Gujranwala'],
    'Sindh': ['Karachi', 'Hyderabad', 'Sukkur', 'Larkana', 'Nawabshah'],
    'Khyber Pakhtunkhwa': ['Peshawar', 'Mardan', 'Abbottabad', 'Swat', 'Kohat'],
    'Balochistan': ['Quetta', 'Gwadar', 'Khuzdar', 'Chaman', 'Zhob'],
    'Gilgit-Baltistan': ['Gilgit', 'Skardu', 'Hunza', 'Chilas'],
    'Azad Kashmir': ['Muzaffarabad', 'Mirpur', 'Rawalakot', 'Kotli'],
  };

  final List<Map<String, dynamic>> propertyTypes = [
    {
      'id': 'house',
      'title': 'House',
      'urdu': 'گھر',
      'icon': Icons.home_outlined,
    },
    {
      'id': 'apartment',
      'title': 'Apartment / Flat',
      'urdu': 'اپارٹمنٹ',
      'icon': Icons.apartment_outlined,
    },
    {'id': 'room', 'title': 'Room', 'urdu': 'کمرہ', 'icon': Icons.bed_outlined},
    {
      'id': 'guest_house',
      'title': 'Guest House',
      'urdu': 'گیسٹ ہاؤس',
      'icon': Icons.house_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _mapSearchFocusNode.addListener(_handleMapSearchFocusChange);
  }

  void _handleMapSearchFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final hostProfileAsync = ref.watch(currentHostProfileProvider);

    return hostProfileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      ),
      error: (e, s) => Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Error loading host profile: $e')),
      ),
      data: (profile) {
        if (profile?.status != HostProfileStatus.approved) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.gavel_rounded, size: 48, color: Color(0xFFEF4444)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Access Restricted',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile?.status == HostProfileStatus.pendingReview
                          ? 'Your identity verification application is currently under review by our admin. You will be able to add properties as soon as it is approved.'
                          : profile?.status == HostProfileStatus.rejected
                              ? 'Your host application was rejected.\nReason: ${profile?.rejectionReason}\n\nPlease update and re-submit your profile from home.'
                              : 'You must complete and submit your host identity verification profile before you can list properties.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (profile?.status != HostProfileStatus.pendingReview)
                      ElevatedButton(
                        onPressed: () {
                          context.pop();
                          context.push('/become-host');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Complete Verification',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Add Property Listing',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close, color: Color(0xFF1F2937)),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Stack(
                  children: [
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      height: 6,
                      width:
                          (MediaQuery.of(context).size.width - 48) *
                          (currentStep / totalSteps),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Step $currentStep of $totalSteps',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF9FAFB),
                    const Color(0xFFF3F4F6),
                    AppTheme.primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(child: _buildStepContent()),
              _buildBottomBar(),
            ],
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildStepContent() {
    if (currentStep == 8) {
      if (titleController.text == 'House in Sukkur' ||
          titleController.text.isEmpty) {
        final propType = selectedType != null
            ? selectedType![0].toUpperCase() + selectedType!.substring(1)
            : 'Property';
        titleController.text =
            'Beautiful $propType in ${selectedCity ?? 'Sukkur'}';
      }
      if (descController.text.isEmpty) {
        final propType = selectedType ?? 'property';
        descController.text =
            'This is a beautiful, modern $propType located in the premium area of ${selectedCity ?? 'Sukkur'}, ${selectedProvince ?? 'Sindh'}. Features $bedrooms bedrooms, $bathrooms bathrooms, and fits up to $maxGuests guests. Perfect for families or business travelers.';
      }
    }
    switch (currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      case 5:
        return _buildStep5();
      case 6:
        return _buildStep6();
      case 7:
        return _buildStep7();
      case 8:
        return _buildStep8();
      default:
        return Center(child: Text('Step $currentStep'));
    }
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What type of property is this?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF111827),
                letterSpacing: -1,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Select the type that best describes your property to help guests find you.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.88, // Increased height for text safety
              ),
              itemCount: propertyTypes.length,
              itemBuilder: (context, index) {
                final type = propertyTypes[index];
                final isSelected = selectedType == type['id'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedType = type['id'];
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : const Color(0xFFF3F4F6),
                        width: isSelected ? 2 : 1.5,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.12),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        else
                          BoxShadow(
                            color: Colors.black.withOpacity(0.015),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor.withOpacity(0.1)
                                : const Color(0xFFF9FAFB),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            type['icon'],
                            size: 32,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : const Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          type['title'],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : const Color(0xFF1F2937),
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          type['urdu'],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoNastaliqUrdu(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF9CA3AF),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Where is your property located?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Provide complete address details.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 32),

            // Row 1
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Province / صوبہ *',
                    hint: 'Select province',
                    value: selectedProvince,
                    items: provinceCities.keys.toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedProvince = val;
                        selectedCity = null; // Reset city when province changes
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'City / شہر *',
                    hint: 'Select province first',
                    value: selectedCity,
                    items: selectedProvince != null
                        ? provinceCities[selectedProvince!]!
                        : [],
                    onChanged: (val) {
                      setState(() {
                        selectedCity = val;
                        if (val != null && cityCoords.containsKey(val)) {
                          selectedLatitude = cityCoords[val]!.latitude;
                          selectedLongitude = cityCoords[val]!.longitude;
                          mapController.move(
                            LatLng(selectedLatitude, selectedLongitude),
                            14.0,
                          );
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Row 2
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'Area / Society / Mohalla / علاقہ *',
                    'e.g., DHA, Gulberg, Saddar',
                    controller: areaController,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    'Block / Sector / بلاک',
                    'e.g., Block A, Sector F-7',
                    controller: blockController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Row 3
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'House / Flat / Plot Number *',
                    'e.g., 123, Flat 4B',
                    controller: houseController,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    'Street / Road (Optional)',
                    'e.g., Main Boulevard',
                    controller: streetController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Row 4
            _buildTextField(
              'Nearby Landmark / قریبی نشان',
              'e.g., Near Jama Masjid, Opposite Metro Station',
              controller: landmarkController,
            ),

            const SizedBox(height: 32),

            // Map Header
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 360;
                final title = Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 20,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Pin approximate area',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                );
                final locationButton = OutlinedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: isLocatingUser
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF374151),
                          ),
                        )
                      : const Icon(Icons.my_location, size: 16),
                  label: Text(
                    'Use my location',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      const SizedBox(height: 10),
                      locationButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: 12),
                    locationButton,
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // Premium Interactive Map Container
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Flutter Map View
                    FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: LatLng(
                          selectedLatitude,
                          selectedLongitude,
                        ),
                        initialZoom: 14.0,
                        onPositionChanged: (position, hasGesture) {
                          if (position.center != null) {
                            setState(() {
                              selectedLatitude = position.center!.latitude;
                              selectedLongitude = position.center!.longitude;
                            });
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.nesty.app',
                        ),
                      ],
                    ),

                    // Fixed Center Bouncing/Pulsing Marker
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(
                          bottom: 30,
                        ), // Align pointer tip to center
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 300),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, -5 * (1 - value)),
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  // Pulsing Shadow base
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(
                                        0xFF00674F,
                                      ).withOpacity(0.25),
                                    ),
                                  ),
                                  // Pin Icon
                                  const Icon(
                                    Icons.location_on,
                                    size: 40,
                                    color: Color(0xFF00674F),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Search Bar Floating Over Map
                    _buildMapSearchOverlay(),

                    // Coordinates HUD Overlay
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${selectedLatitude.toStringAsFixed(5)}, ${selectedLongitude.toStringAsFixed(5)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),

                    // Quick center GPS Floating button on the map
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: FloatingActionButton.small(
                        onPressed: _getCurrentLocation,
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF00674F),
                        elevation: 4,
                        child: isLocatingUser
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF00674F),
                                ),
                              )
                            : const Icon(Icons.gps_fixed),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Drag the map to position the center marker at the exact location. Approximate location will be shown to guests.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF6B7280),
              ),
            ),

            const SizedBox(height: 24),

            // Privacy Protection Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5FF), // Very light blue
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF3B82F6),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacy Protection',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Approximate location shown to guests until booking is confirmed',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: true,
                    onChanged: (val) {},
                    activeColor: Colors.white,
                    activeTrackColor: const Color(
                      0xFFB9FBC0,
                    ), // Light teal/cyan
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFFE5E7EB),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitMapSearch() {
    final query = mapSearchController.text.trim();
    if (query.isEmpty) {
      _mapSearchFocusNode.requestFocus();
      return;
    }

    setState(() => _showLocationSuggestions = false);
    FocusScope.of(context).unfocus();
    _searchLocation(query);
  }

  void _clearMapSearch() {
    setState(() {
      mapSearchController.clear();
      _showLocationSuggestions = false;
      _locationSuggestions = [];
    });
    _mapSearchFocusNode.requestFocus();
  }

  Widget _buildMapSearchOverlay() {
    final hasQuery = mapSearchController.text.trim().isNotEmpty;
    final isFocused = _mapSearchFocusNode.hasFocus;
    final canSearch = hasQuery && !isSearchingLocation;

    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFocused
                    ? const Color(0xFF00674F)
                    : const Color(0xFFE5E7EB),
                width: isFocused ? 1.4 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isFocused ? 0.16 : 0.10),
                  blurRadius: isFocused ? 18 : 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F7F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSearchingLocation
                        ? Icons.hourglass_top_rounded
                        : Icons.search_rounded,
                    color: const Color(0xFF00674F),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: mapSearchController,
                    focusNode: _mapSearchFocusNode,
                    maxLines: 1,
                    textInputAction: TextInputAction.search,
                    cursorColor: const Color(0xFF00674F),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'Search city, society, landmark',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      filled: false,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                    onChanged: _updateLocationSuggestions,
                    onSubmitted: (_) => _submitMapSearch(),
                    onTap: () {
                      if (mapSearchController.text.isNotEmpty) {
                        _updateLocationSuggestions(mapSearchController.text);
                      }
                    },
                  ),
                ),
                if (hasQuery) ...[
                  const SizedBox(width: 6),
                  Material(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: _clearMapSearch,
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 32,
                        height: 32,
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 6),
                Material(
                  color: canSearch
                      ? const Color(0xFF00674F)
                      : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: isSearchingLocation
                        ? null
                        : () {
                            if (hasQuery) {
                              _submitMapSearch();
                            } else {
                              _mapSearchFocusNode.requestFocus();
                            }
                          },
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: isSearchingLocation
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                Icons.arrow_forward_rounded,
                                color: canSearch
                                    ? Colors.white
                                    : const Color(0xFF9CA3AF),
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showLocationSuggestions && _locationSuggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 6),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 176),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: _locationSuggestions.length > 3
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  itemCount: _locationSuggestions.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF3F4F6),
                  ),
                  itemBuilder: (context, index) {
                    final suggestion = _locationSuggestions[index];
                    return _buildLocationSuggestionTile(suggestion);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationSuggestionTile(String suggestion) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          mapSearchController.text = suggestion;
          mapSearchController.selection = TextSelection.fromPosition(
            TextPosition(offset: suggestion.length),
          );
          setState(() => _showLocationSuggestions = false);
          FocusScope.of(context).unfocus();
          _searchLocation(suggestion);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF00674F).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: Color(0xFF00674F),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  suggestion,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.north_west_rounded,
                size: 14,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Property details',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us about your space',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 32),

            _buildCounter(
              'Bedrooms / کمرے',
              bedrooms,
              (val) => setState(() => bedrooms = val),
            ),
            const SizedBox(height: 24),
            _buildCounter(
              'Bathrooms / باتھ رومز',
              bathrooms,
              (val) => setState(() => bathrooms = val),
            ),
            const SizedBox(height: 24),
            _buildCounter(
              'Maximum Guests / مہمان',
              maxGuests,
              (val) => setState(() => maxGuests = val),
            ),

            const SizedBox(height: 32),
            const Divider(color: Color(0xFFF3F4F6), thickness: 1),
            const SizedBox(height: 24),

            _buildSwitchItem(
              'Family Friendly / خاندانی',
              'Suitable for families with children',
              isFamilyFriendly,
              (val) => setState(() => isFamilyFriendly = val),
            ),
            const SizedBox(height: 24),
            _buildSwitchItem(
              'Bachelor Allowed',
              'Single persons can book',
              isBachelorAllowed,
              (val) => setState(() => isBachelorAllowed = val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounter(String label, int value, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            InkWell(
              onTap: value > 1 ? () => onChanged(value - 1) : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.remove,
                  size: 16,
                  color: Color(0xFF374151),
                ),
              ),
            ),
            SizedBox(
              width: 48,
              child: Text(
                value.toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            InkWell(
              onTap: () => onChanged(value + 1),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add,
                  size: 16,
                  color: Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSwitchItem(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: const Color(
            0xFFB9FBC0,
          ), // Light cyan/teal matching image
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFFE5E7EB),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What amenities do you offer?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select all that apply',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 32),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent:
                    88, // Fixed absolute height to prevent text clipping
              ),
              itemCount: availableAmenities.length,
              itemBuilder: (context, index) {
                final amenity = availableAmenities[index];
                final isSelected = selectedAmenities.contains(amenity['id']);

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedAmenities.remove(amenity['id']);
                      } else {
                        selectedAmenities.add(amenity['id']);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withOpacity(0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : const Color(0xFFE5E7EB),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          amenity['icon'],
                          color: const Color(0xFF1F2937),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                amenity['title'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1F2937),
                                  height: 1.2,
                                ),
                              ),
                              if (amenity['urdu'] != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  amenity['urdu'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),
            Text(
              'Custom Amenities (Optional)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: customAmenitiesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'e.g., Swimming pool, Garden, Rooftop',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF9CA3AF),
                ),
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep5() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add photos of your property',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload at least 5 high-quality photos',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 32),

            // Photo Tips Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5FF), // Light blue tint
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Photo Tips / تجاویز:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTipItem('Use daylight for better quality'),
                  const SizedBox(height: 8),
                  _buildTipItem('Show all rooms clearly'),
                  const SizedBox(height: 8),
                  _buildTipItem('Include exterior shots'),
                  const SizedBox(height: 8),
                  _buildTipItem('Keep rooms tidy and clean'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Uploaded Photos Grid
            if (uploadedPhotos.isNotEmpty) ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                ),
                itemCount: uploadedPhotos.length,
                itemBuilder: (context, index) {
                  final file = File(uploadedPhotos[index]);
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => FullScreenImageGallery(
                            images: uploadedPhotos,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(file),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                uploadedPhotos.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        if (index == 0)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Cover Photo',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),);
                },
              ),
              const SizedBox(height: 16),
            ],

            // Upload Button
            InkWell(
              onTap: _pickImages,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.file_upload_outlined,
                      size: 40,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Upload Photos',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${uploadedPhotos.length}/5 minimum • Click to browse',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Row(
      children: [
        const Icon(Icons.check, size: 14, color: Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF4B5563),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        24,
      ), // Adjusted for safe area and space
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (currentStep > 1) ...[
            Expanded(
              flex: 2, // Give back button less space
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      currentStep--;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chevron_left, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Back',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: 3, // Give submit button more space
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _canContinue()
                    ? () {
                        if (currentStep < totalSteps) {
                          setState(() {
                            currentStep++;
                          });
                        } else {
                          _submitApplication();
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentStep == totalSteps
                      ? const Color(0xFF006D44)
                      : AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: currentStep == totalSteps ? 4 : 0,
                  shadowColor: const Color(0xFF006D44).withOpacity(0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currentStep == totalSteps
                          ? 'Submit for Review'
                          : 'Continue',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      currentStep == totalSteps
                          ? Icons.rocket_launch_rounded
                          : Icons.chevron_right,
                      size: 20,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Photos',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppTheme.primaryColor,
              ),
              title: Text(
                'Choose from Gallery (Multiple)',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                Navigator.pop(context);
                final ImagePicker picker = ImagePicker();
                final List<XFile> pickedFiles = await picker.pickMultiImage(
                  imageQuality: 25,
                  maxWidth: 600,
                  maxHeight: 600,
                );
                if (pickedFiles.isNotEmpty) {
                  setState(() {
                    uploadedPhotos.addAll(pickedFiles.map((file) => file.path));
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppTheme.primaryColor,
              ),
              title: Text(
                'Take Photo (Camera)',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                Navigator.pop(context);
                final ImagePicker picker = ImagePicker();
                final XFile? pickedFile = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 25,
                  maxWidth: 600,
                  maxHeight: 600,
                );
                if (pickedFile != null) {
                  setState(() {
                    uploadedPhotos.add(pickedFile.path);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submitApplication() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
    );

    try {
      final double priceVal =
          double.tryParse(priceController.text.trim()) ?? 5000.0;
      final double cleanFeeVal =
          double.tryParse(cleaningFeeController.text.trim()) ?? 0.0;
      final int weeklyDiscountVal = showDiscounts
          ? (int.tryParse(weeklyDiscountController.text.trim()) ?? 0)
          : 0;
      final int monthlyDiscountVal = showDiscounts
          ? (int.tryParse(monthlyDiscountController.text.trim()) ?? 0)
          : 0;

      // Build friendly public location string (excluding house and street numbers for privacy & layout)
      final List<String> addressParts = [
        if (blockController.text.trim().isNotEmpty) blockController.text.trim(),
        if (areaController.text.trim().isNotEmpty) areaController.text.trim(),
        selectedCity ?? 'Sukkur',
        selectedProvince ?? 'Sindh',
      ];
      final String fullAddress = addressParts
          .where((part) => part.isNotEmpty)
          .join(', ');

      // Compile amenities list (quick + custom typed)
      final List<String> finalAmenities = List<String>.from(selectedAmenities);
      if (customAmenitiesController.text.trim().isNotEmpty) {
        final customList = customAmenitiesController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty);
        finalAmenities.addAll(customList);
      }

      // Upload local images to Firebase Storage
      final List<String> uploadedUrls = [];
      try {
        final storageRef = FirebaseStorage.instance.ref().child('properties');
        for (int i = 0; i < uploadedPhotos.length; i++) {
          final String localPath = uploadedPhotos[i];
          if (localPath.startsWith('http://') ||
              localPath.startsWith('https://')) {
            uploadedUrls.add(localPath);
            continue;
          }
          final File file = File(localPath);
          final String fileName =
              '${DateTime.now().millisecondsSinceEpoch}_step5_$i.jpg';
          final uploadTask = storageRef.child(fileName).putFile(file);
          final snapshot = await uploadTask;
          final downloadUrl = await snapshot.ref.getDownloadURL();
          uploadedUrls.add(downloadUrl);
        }
      } catch (e) {
        print(
          'DEBUG: Error uploading images to Firebase Storage: $e. Storing as Base64 in Firestore.',
        );
        uploadedUrls.clear();
        for (int i = 0; i < uploadedPhotos.length; i++) {
          final String localPath = uploadedPhotos[i];
          if (localPath.startsWith('http://') ||
              localPath.startsWith('https://') ||
              localPath.startsWith('data:image')) {
            uploadedUrls.add(localPath);
            continue;
          }
          try {
            final File file = File(localPath);
            final bytes = await file.readAsBytes();
            final base64Str = base64Encode(bytes);
            uploadedUrls.add('data:image/jpeg;base64,$base64Str');
          } catch (err) {
            print('Error encoding image to base64: $err');
          }
        }
        if (uploadedUrls.isEmpty) {
          uploadedUrls.add('https://images.unsplash.com/photo-1580587767526-cf3675a3e99a?q=80&w=800');
        }
      }

      final String mainImage = uploadedUrls.isNotEmpty
          ? uploadedUrls[0]
          : 'https://images.unsplash.com/photo-1580587767526-cf3675a3e99a?q=80&w=800';
      final List<String> gallery = uploadedUrls;

      // Create the new property
      final newProperty = Property(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: titleController.text,
        location: fullAddress,
        imageUrl: mainImage,
        galleryImages: gallery,
        price: priceVal,
        rating: 0.0,
        reviews: 0,
        category: selectedType ?? 'House',
        description: descController.text,
        hostName: 'Muhammad Haad',
        hostImageUrl: 'https://i.pravatar.cc/150?u=muhammad',
        guests: maxGuests,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        status: 'pending',
        noSmoking: noSmoking,
        noParties: noParties,
        petsAllowed: petsAllowed,
        checkInTime:
            '${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}',
        checkOutTime:
            '${checkOutTime.hour.toString().padLeft(2, '0')}:${checkOutTime.minute.toString().padLeft(2, '0')}',
        cancellationPolicy: selectedCancellationPolicy,
        quickRules: selectedQuickRules,
        addressHouse: houseController.text.trim(),
        addressStreet: streetController.text.trim(),
        addressBlock: blockController.text.trim(),
        addressArea: areaController.text.trim(),
        addressLandmark: landmarkController.text.trim(),
        cleaningFee: cleanFeeVal,
        weeklyDiscount: weeklyDiscountVal,
        monthlyDiscount: monthlyDiscountVal,
        amenities: finalAmenities,
        latitude: selectedLatitude,
        longitude: selectedLongitude,
      );

      // Add to provider (saves to Firestore)
      print('DEBUG: Submitting new property to Firebase Firestore:');
      print('DEBUG: Title: ${newProperty.title}');
      print('DEBUG: Location: ${newProperty.location}');
      print('DEBUG: Price: ${newProperty.price}');

      await ref.read(hostListingsProvider.notifier).addProperty(newProperty);
      print('DEBUG: Successfully saved property to Firebase Firestore!');

      // Dismiss loading indicator
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Show SnackBar Toast message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your property details have been submitted for admin approval.',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981), // Emerald green
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            contentPadding: EdgeInsets.zero,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 180,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF10B981),
                        size: 64,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Text(
                        'Listing Submitted!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your property has been sent to admin for approval. You can track its status in the "Listings" tab.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true).pop();
                            context.go('/listings');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F2937),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Go to Listings',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      // Dismiss loading indicator
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit listing: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildStep6() {
    final format = NumberFormat("#,##0", "en_US");
    final double basePrice =
        double.tryParse(priceController.text.trim()) ?? 0.0;
    final double cleaningFee =
        double.tryParse(cleaningFeeController.text.trim()) ?? 0.0;
    final double platformFee = (basePrice + cleaningFee) * 0.1;
    final double youWillReceive = (basePrice + cleaningFee) - platformFee;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor.withOpacity(0.05), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF3F4F6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.payments_rounded,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Pricing & Earnings',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1F2937),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Set your night rate and see your estimated earnings after platform fees.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          _buildPriceInputCard(
            'Price per Night',
            'رات کی قیمت',
            'e.g. 5000',
            Icons.nightlight_round,
            priceController,
          ),

          const SizedBox(height: 20),

          _buildPriceInputCard(
            'Cleaning Fee (Optional)',
            'صفائی کی فیس',
            'e.g. 1000',
            Icons.cleaning_services_rounded,
            cleaningFeeController,
          ),

          const SizedBox(height: 32),

          // Discounts Toggle & Section (Optional in Step 6)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discounts (Optional)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    'رعایتی قیمتیں (اختیاری)',
                    style: GoogleFonts.notoNastaliqUrdu(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
              Switch.adaptive(
                value: showDiscounts,
                activeColor: AppTheme.primaryColor,
                onChanged: (val) => setState(() => showDiscounts = val),
              ),
            ],
          ),

          if (showDiscounts) ...[
            const SizedBox(height: 20),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  _buildDiscountInput(
                    'Weekly Discount (7+ nights)',
                    '10',
                    weeklyDiscountController,
                  ),
                  const SizedBox(height: 20),
                  _buildDiscountInput(
                    'Monthly Discount (28+ nights)',
                    '20',
                    monthlyDiscountController,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Earnings Breakdown Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF3F4F6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Expected Earnings',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '10% Fee',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0369A1),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildEarningRow(
                  'Base Price',
                  'PKR ${format.format(basePrice)}',
                ),
                _buildEarningRow(
                  'Cleaning Fee',
                  'PKR ${format.format(cleaningFee)}',
                ),
                _buildEarningRow(
                  'Nesty Platform Fee',
                  '- PKR ${format.format(platformFee)}',
                  isNegative: true,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'You will receive:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Text(
                      'PKR ${format.format(youWillReceive)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildEarningRow(
    String label,
    String value, {
    bool isNegative = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isNegative ? Colors.redAccent : const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInputCard(
    String label,
    String urduLabel,
    String hint,
    IconData icon,
    TextEditingController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    urduLabel,
                    style: GoogleFonts.notoNastaliqUrdu(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            onChanged: (val) => setState(() {}),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PKR',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFD1D5DB),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 24,
                      width: 1.5,
                      color: const Color(0xFFF3F4F6),
                    ),
                  ],
                ),
              ),
              hintText: hint,
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                color: const Color(0xFFD1D5DB),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint, {
    String? prefixText,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            prefixText: prefixText,
            prefixStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF9CA3AF),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) {
            final isSelected = item == value;
            return DropdownMenuItem<String>(
              value: item,
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFF3F4F6)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFF1F2937),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check,
                        size: 18,
                        color: Color(0xFF1F2937),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: items.isEmpty ? null : onChanged,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
          isExpanded: true,
          dropdownColor: Colors.white,
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF9CA3AF),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            fillColor: items.isEmpty ? const Color(0xFFF9FAFB) : Colors.white,
            filled: true,
          ),
          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((String item) {
              return Text(
                item,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList();
          },
        ),
      ],
    );
  }

  Widget _buildStep7() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'House rules',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set clear expectations for guests',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 32),

            // Quick Add Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4), // Light green tint
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ':فوری اضافہ / Quick Add',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: quickRules.map((rule) {
                      final isSelected = selectedQuickRules.contains(rule);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected)
                              selectedQuickRules.remove(rule);
                            else
                              selectedQuickRules.add(rule);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : const Color(0xFF10B981),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            rule,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            _buildSwitchItemWithUrdu(
              'No Smoking / سگریٹ نوشی منع',
              '',
              noSmoking,
              (val) => setState(() => noSmoking = val),
            ),
            const SizedBox(height: 16),
            _buildSwitchItemWithUrdu(
              'No Parties / پارٹیز منع',
              '',
              noParties,
              (val) => setState(() => noParties = val),
            ),
            const SizedBox(height: 16),
            _buildSwitchItemWithUrdu(
              'Pets Allowed / پالتو جانور',
              '',
              petsAllowed,
              (val) => setState(() => petsAllowed = val),
            ),

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: _buildTimePicker(
                    'Check-in Time / آنے کا وقت',
                    checkInTime,
                    (t) => setState(() => checkInTime = t),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimePicker(
                    'Check-out Time / جانے کا وقت',
                    checkOutTime,
                    (t) => setState(() => checkOutTime = t),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildDropdown(
              label: 'Cancellation Policy / منسوخی پالیسی',
              hint: 'Select policy',
              value: selectedCancellationPolicy,
              items: [
                'Flexible',
                'Moderate - Full refund 5 days before',
                'Strict',
              ],
              onChanged: (val) =>
                  setState(() => selectedCancellationPolicy = val!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep8() {
    final format = NumberFormat("#,##0", "en_US");
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review & Submit',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure everything looks good',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 32),

            _buildReviewTextField(
              'Property Title / عنوان *',
              titleController,
              1,
            ),
            const SizedBox(height: 24),
            _buildReviewTextField(
              'Description / تفصیل *',
              descController,
              5,
              hint:
                  'Describe your property, its unique features, and what makes it special...',
            ),

            const SizedBox(height: 32),
            const Divider(color: Color(0xFFF3F4F6), thickness: 1),
            const SizedBox(height: 24),

            _buildReviewRow(
              'Property Type',
              selectedType?.toUpperCase() ?? 'HOUSE',
              icon: propertyTypes.firstWhere(
                (t) => t['id'] == selectedType,
                orElse: () => propertyTypes[0],
              )['icon'],
              onEdit: () => setState(() => currentStep = 1),
            ),
            _buildReviewRow(
              'Location',
              [
                if (houseController.text.trim().isNotEmpty)
                  houseController.text.trim(),
                if (areaController.text.trim().isNotEmpty)
                  areaController.text.trim(),
                selectedCity ?? 'Sukkur',
                selectedProvince ?? 'Sindh',
              ].join(', '),
              icon: Icons.location_on_outlined,
              onEdit: () => setState(() => currentStep = 2),
            ),
            _buildReviewRow(
              'Details',
              '$bedrooms bed • $bathrooms bath • $maxGuests guests',
              icon: Icons.king_bed_outlined,
              onEdit: () => setState(() => currentStep = 3),
            ),
            _buildReviewRow(
              'Amenities',
              '${selectedAmenities.length + (customAmenitiesController.text.trim().isNotEmpty ? customAmenitiesController.text.split(',').length : 0)} selected',
              icon: Icons.auto_awesome_outlined,
              onEdit: () => setState(() => currentStep = 4),
            ),
            _buildReviewRow(
              'Photos',
              '${uploadedPhotos.length} photos',
              icon: Icons.photo_library_outlined,
              onEdit: () => setState(() => currentStep = 5),
            ),
            _buildReviewRow(
              'Pricing',
              'PKR ${format.format(double.tryParse(priceController.text.trim()) ?? 5000.0)}/night',
              icon: Icons.payments_outlined,
              onEdit: () => setState(() => currentStep = 6),
            ),
            _buildReviewRow(
              'Rules',
              '${selectedQuickRules.length + (noSmoking ? 1 : 0) + (noParties ? 1 : 0) + (petsAllowed ? 1 : 0)} rules set',
              icon: Icons.rule_rounded,
              onEdit: () => setState(() => currentStep = 7),
            ),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your listing will be reviewed by our team within 24-48 hours. You\'ll be notified once it\'s approved.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF4B5563),
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItemWithUrdu(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1F2937),
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: const Color(0xFFB9FBC0),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFFE5E7EB),
        ),
      ],
    );
  }

  Widget _buildTimePicker(
    String label,
    TimeOfDay time,
    Function(TimeOfDay) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD1D5DB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time.format(context),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Icon(
                  Icons.access_time,
                  size: 18,
                  color: Color(0xFF6B7280),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscountInput(
    String label,
    String hint,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: (val) => setState(() {}),
          decoration: InputDecoration(
            suffixText: '%',
            suffixStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewTextField(
    String label,
    TextEditingController controller,
    int lines, {
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: lines,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF9CA3AF),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(
    String label,
    String value, {
    IconData? icon,
    VoidCallback? onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9CA3AF),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onEdit,
            child: Text(
              'Edit',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canContinue() {
    switch (currentStep) {
      case 1:
        return selectedType != null;
      case 2:
        return selectedProvince != null && selectedCity != null;
      case 3:
        return maxGuests > 0;
      case 4:
        return selectedAmenities.isNotEmpty;
      case 5:
        return uploadedPhotos.length >= 5;
      case 6:
        {
          final price = double.tryParse(priceController.text.trim());
          return price != null && price > 0;
        }
      case 8:
        return titleController.text.isNotEmpty &&
            descController.text.isNotEmpty;
      default:
        return true;
    }
  }
}
