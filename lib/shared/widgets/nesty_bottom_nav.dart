import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/auth_provider.dart';
import 'nesty_image.dart';

class NestyBottomNav extends ConsumerWidget {
  final int currentIndex;
  
  const NestyBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleProvider);
    final bool isHost = role == AppRole.host;
    final authState = ref.watch(authProvider);
    final String? photoUrl = authState.photoUrl;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF00674F), // Signature premium pink/coral
      unselectedItemColor: Colors.black45,
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == currentIndex) return;
        
        if (isHost) {
          // Host mode navigation (5 tabs)
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/listings');
              break;
            case 2:
              context.go('/bookings');
              break;
            case 3:
              context.go('/inbox');
              break;
            case 4:
              context.go('/profile');
              break;
          }
        } else {
          // Guest mode navigation (5 tabs)
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/wishlists');
              break;
            case 2:
              context.go('/trips');
              break;
            case 3:
              context.go('/inbox');
              break;
            case 4:
              context.go('/profile');
              break;
          }
        }
      },
      selectedLabelStyle: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w900, 
        fontSize: 10,
        color: const Color(0xFF00674F),
      ),
      unselectedLabelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 10, 
        fontWeight: FontWeight.w700,
        color: Colors.black45,
      ),
      items: isHost ? _hostItems(photoUrl) : _guestItems(photoUrl),
    );
  }

  Widget _buildAvatarIcon(bool isActive, String? photoUrl) {
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? const Color(0xFF00674F) : Colors.black38,
          width: isActive ? 2.0 : 1.0,
        ),
      ),
      child: ClipOval(
        child: NestyImage(
          src: (photoUrl != null && photoUrl.isNotEmpty)
              ? photoUrl
              : 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?q=80&w=200',
          width: 20,
          height: 20,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _guestItems(String? photoUrl) {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.search_rounded), 
        activeIcon: Icon(Icons.search_rounded, color: Color(0xFF00674F)), 
        label: 'Explore',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.favorite_border_rounded), 
        activeIcon: Icon(Icons.favorite_rounded, color: Color(0xFF00674F)), 
        label: 'Wishlists',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.explore_outlined), 
        activeIcon: Icon(Icons.explore, color: Color(0xFF00674F)), 
        label: 'Trips',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline_rounded), 
        activeIcon: Icon(Icons.chat_bubble, color: Color(0xFF00674F)), 
        label: 'Inbox',
      ),
      BottomNavigationBarItem(
        icon: _buildAvatarIcon(false, photoUrl),
        activeIcon: _buildAvatarIcon(true, photoUrl),
        label: 'Profile',
      ),
    ];
  }

  List<BottomNavigationBarItem> _hostItems(String? photoUrl) {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.grid_view_outlined), 
        activeIcon: Icon(Icons.grid_view_rounded, color: Color(0xFF00674F)), 
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.list_alt_outlined), 
        activeIcon: Icon(Icons.list_alt_rounded, color: Color(0xFF00674F)), 
        label: 'Listings',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today_outlined), 
        activeIcon: Icon(Icons.calendar_today, color: Color(0xFF00674F)), 
        label: 'Bookings',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline_rounded), 
        activeIcon: Icon(Icons.chat_bubble, color: Color(0xFF00674F)), 
        label: 'Inbox',
      ),
      BottomNavigationBarItem(
        icon: _buildAvatarIcon(false, photoUrl),
        activeIcon: _buildAvatarIcon(true, photoUrl),
        label: 'Profile',
      ),
    ];
  }
}
