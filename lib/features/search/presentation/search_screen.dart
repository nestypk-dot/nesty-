import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/nesty_bottom_nav.dart';
import '../../../core/theme/app_theme.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  int _expandedSection = 0; // 0: Where, 1: Check-in, 2: Check-out, 3: Who
  String _location = '';
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _guests = 1;
  String _layoutType = 'medium'; // 'small', 'medium', 'list'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Softer background like Airbnb
      body: SafeArea(
        child: Column(
          children: [
            // Redesigned Attractive Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close_rounded, size: 22, color: Colors.black87),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Premium Filter Bar (Horizontal Capsule Style)
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        children: [
                          _buildFilterModule(
                            icon: Icons.location_on_rounded,
                            label: _location.isEmpty ? 'Search...' : _location,
                            urduLabel: 'تلاش کریں',
                            isSelected: _expandedSection == 0,
                            onTap: () => setState(() => _expandedSection = 0),
                          ),
                          _buildFilterModule(
                            icon: Icons.calendar_today_rounded,
                            label: _checkIn == null ? 'Check-in' : '${_checkIn!.day}/${_checkIn!.month}',
                            isSelected: _expandedSection == 1,
                            onTap: () => setState(() => _expandedSection = 1),
                          ),
                          _buildFilterModule(
                            icon: Icons.calendar_month_rounded,
                            label: _checkOut == null ? 'Check-out' : '${_checkOut!.day}/${_checkOut!.month}',
                            isSelected: _expandedSection == 2,
                            onTap: () => setState(() => _expandedSection = 2),
                          ),
                          _buildFilterModule(
                            icon: Icons.group_rounded,
                            label: '$_guests',
                            isSelected: _expandedSection == 3,
                            onTap: () => setState(() => _expandedSection = 3),
                          ),
                          _buildFilterModule(
                            icon: Icons.tune_rounded,
                            label: 'Filters',
                            onTap: () => context.push('/filters'),
                          ),
                          const SizedBox(width: 8),
                          // Premium Layout Toggles in a group
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildLayoutIcon(Icons.grid_view_rounded, 'small'),
                                const SizedBox(width: 4),
                                _buildLayoutIcon(Icons.view_agenda_rounded, 'medium'),
                                const SizedBox(width: 4),
                                _buildLayoutIcon(Icons.format_list_bulleted_rounded, 'list'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16), // Extra space to prevent cropping
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Where to?
                    _buildSearchSection(
                      index: 0,
                      title: 'Where to?',
                      value: _location.isEmpty ? 'Search destinations' : _location,
                      isExpanded: _expandedSection == 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            onChanged: (val) => setState(() => _location = val),
                            decoration: InputDecoration(
                              hintText: 'Search destinations',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Recent searches',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          _buildRecentSearches(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Section 2: When?
                    _buildSearchSection(
                      index: 1, // Either 1 or 2 will expand this
                      title: 'When?',
                      value: (_checkIn == null || _checkOut == null) ? 'Add dates' : 'Selected dates',
                      isExpanded: _expandedSection == 1 || _expandedSection == 2,
                      onForceExpand: (idx) => setState(() => _expandedSection = 1),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateInput(
                                  'Check-in',
                                  _checkIn == null ? 'Add date' : '${_checkIn!.day}/${_checkIn!.month}',
                                  isSelected: _expandedSection == 1,
                                  onTap: () async {
                                    setState(() => _expandedSection = 1);
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (date != null) setState(() => _checkIn = date);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDateInput(
                                  'Check-out',
                                  _checkOut == null ? 'Add date' : '${_checkOut!.day}/${_checkOut!.month}',
                                  isSelected: _expandedSection == 2,
                                  onTap: () async {
                                    setState(() => _expandedSection = 2);
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _checkIn?.add(const Duration(days: 1)) ?? DateTime.now().add(const Duration(days: 1)),
                                      firstDate: _checkIn ?? DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (date != null) setState(() => _checkOut = date);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _buildDateQuickAction('I\'m flexible'),
                              const SizedBox(width: 8),
                              _buildDateQuickAction('Specific dates'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Section 3: Who?
                    _buildSearchSection(
                      index: 3,
                      title: 'Who?',
                      value: '$_guests guests',
                      isExpanded: _expandedSection == 3,
                      child: Column(
                        children: [
                          _buildGuestRow('Adults', 'Ages 13 or above'),
                          const Divider(height: 24),
                          _buildGuestRow('Children', 'Ages 2–12'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _location = '';
                        _guests = 1;
                        _checkIn = null;
                        _checkOut = null;
                      });
                    },
                    child: const Text(
                      'Clear all',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      context.push('/search-results');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      minimumSize: Size.zero, // Override global theme infinite width
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: Theme.of(context).primaryColor.withOpacity(0.4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.search, size: 20),
                        SizedBox(width: 8),
                        Text('Search', style: TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const NestyBottomNav(currentIndex: 1),
    );
  }

  Widget _buildSearchSection({
    required int index,
    required String title,
    required String value,
    required bool isExpanded,
    required Widget child,
    Function(int)? onForceExpand,
  }) {
    return GestureDetector(
      onTap: () => onForceExpand != null ? onForceExpand(index) : setState(() => _expandedSection = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            if (isExpanded)
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: isExpanded ? 26 : 15,
                    fontWeight: isExpanded ? FontWeight.w900 : FontWeight.w600,
                    color: isExpanded ? Colors.black : Colors.grey.shade500,
                  ),
                ),
                if (!isExpanded)
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 20),
              child,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGuestRow(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              subtitle,
              style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Row(
          children: [
            _buildGuestButton(Icons.remove_rounded, () {
              if (_guests > 1) setState(() => _guests--);
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                '$_guests',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black),
              ),
            ),
            _buildGuestButton(Icons.add_rounded, () => setState(() => _guests++)),
          ],
        ),
      ],
    );
  }

  Widget _buildGuestButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
        ),
        child: Icon(icon, size: 18, color: AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildRecentSearches() {
    final recent = [
      {'title': 'Bali, Indonesia', 'icon': Icons.history},
      {'title': 'Zurich, Switzerland', 'icon': Icons.history},
    ];

    return Wrap(
      spacing: 8,
      children: recent.map((item) {
        return IntrinsicWidth(
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item['icon'] as IconData, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  item['title'] as String,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFilterModule({
    required IconData icon,
    required String label,
    String? urduLabel,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppTheme.primaryColor,
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
                if (urduLabel != null)
                  Text(
                    urduLabel,
                    style: GoogleFonts.outfit(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white.withOpacity(0.8) : Colors.black45,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutIcon(IconData icon, String type) {
    bool isSelected = _layoutType == type;
    return GestureDetector(
      onTap: () => setState(() => _layoutType = type),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? AppTheme.primaryColor : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildDateInput(String title, String value, {bool isSelected = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const Icon(Icons.calendar_month, size: 16, color: AppTheme.primaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateQuickAction(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
