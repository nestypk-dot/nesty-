import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../features/chat/presentation/incoming_call_listener.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/otp_verification_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/search/presentation/filter_screen.dart';
import '../../features/search/presentation/search_results_screen.dart';
import '../../features/search/presentation/map_view_screen.dart';
import '../../features/home/presentation/property_detail_screen.dart';
import '../../features/home/presentation/host_profile_screen.dart';
import '../../features/host/presentation/add_property_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/chat/presentation/inbox_screen.dart';
import '../../features/chat/presentation/media_viewer_screen.dart';
import '../../features/chat/presentation/call_screen.dart';
import '../../features/home/presentation/reviews_screen.dart';
import '../../features/home/presentation/date_selection_screen.dart';
import '../../features/home/presentation/guest_selection_screen.dart';
import '../../features/booking/presentation/booking_flow_screen.dart';
import '../../features/booking/presentation/booking_confirmation_screen.dart';
import '../../features/booking/presentation/booking_receipt_screen.dart';
import '../../features/trips/presentation/trips_screen.dart';
import '../../features/trips/presentation/trip_details_screen.dart';
import '../../features/home/domain/property.dart';
import '../../features/trips/domain/booking.dart';
import '../../features/host_dashboard/presentation/my_listings_screen.dart';
import '../../features/profile/presentation/my_profile_screen.dart';
import '../../features/host/presentation/host_settings_screen.dart';
import '../../features/host_onboarding/presentation/host_onboarding_screen.dart';
import '../../features/profile/presentation/wishlists_screen.dart';
import '../../features/profile/presentation/switching_hosting_screen.dart';
import '../../features/profile/presentation/switching_guest_screen.dart';
import '../../features/profile/presentation/connections_screen.dart';
import '../../features/host_dashboard/presentation/host_bookings_screen.dart';
import '../../features/host_dashboard/presentation/edit_listing_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/profile/presentation/complaints_screen.dart';
import '../../features/profile/presentation/help_center_screen.dart';
import '../../features/profile/presentation/privacy_policy_screen.dart';
import '../../features/profile/presentation/terms_of_service_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/admin_host_detail_screen.dart';
import '../../features/admin/presentation/admin_property_detail_screen.dart';





// Placeholder screens - In a real app, these would be in features/
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Welcome to $title')),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return IncomingCallListener(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final role = extra['role'] as String? ?? 'guest';
          return LoginScreen(role: role);
        },
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final role = extra['role'] as String? ?? 'guest';
          return SignupScreen(role: role);
        },
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return OtpVerificationScreen(
            name: extra['name'] ?? '',
            email: extra['email'] ?? '',
            phone: extra['phone'] ?? '',
            password: extra['password'] ?? '',
            role: extra['role'] ?? 'guest',
          );
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/search-results',
        builder: (context, state) {
          final category = state.uri.queryParameters['category'];
          return SearchResultsScreen(category: category);
        },
      ),
      GoRoute(
        path: '/filters',
        builder: (context, state) => const FilterScreen(),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const MapViewScreen(),
      ),
      GoRoute(
        path: '/property/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PropertyDetailScreen(propertyId: id);
        },
      ),
      GoRoute(
        path: '/booking',
        builder: (context, state) => const PlaceholderScreen(title: 'Booking'),
      ),
      GoRoute(
        path: '/trips',
        builder: (context, state) {
          final tabIndex = int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
          return TripsScreen(initialTab: tabIndex);
        },
      ),
      GoRoute(
        path: '/inbox',
        builder: (context, state) => const InboxScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          return ChatScreen(
            peerId: extras['peerId'] ?? '',
            peerName: extras['peerName'] ?? (extras['hostName'] ?? 'Host'),
            peerImageUrl: extras['peerImageUrl'] ?? (extras['hostImageUrl'] ?? ''),
            conversationId: extras['conversationId'],
          );
        },
      ),
      GoRoute(
        path: '/media-viewer',
        builder: (context, state) {
          final imageUrl = state.extra as String;
          return MediaViewerScreen(imageUrl: imageUrl);
        },
      ),
      GoRoute(
        path: '/call',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return CallScreen(
            callId: extras['callId'] as String,
            isCaller: extras['isCaller'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const MyProfileScreen(),
      ),
      GoRoute(
        path: '/host-settings',
        builder: (context, state) => const HostSettingsScreen(),
      ),

      GoRoute(
        path: '/add-property',
        builder: (context, state) => const AddPropertyScreen(),
      ),
      GoRoute(
        path: '/reviews/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extras = state.extra as Map<String, dynamic>?;
          return ReviewsScreen(
            propertyId: id,
            averageRating: (extras?['rating'] ?? 5.0).toDouble(),
            totalReviews: (extras?['reviews'] ?? 0).toInt(),
          );
        },
      ),
      GoRoute(
        path: '/host/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return HostProfileScreen(propertyId: id);
        },
      ),
      GoRoute(
        path: '/date-selection',
        builder: (context, state) => const DateSelectionScreen(),
      ),
      GoRoute(
        path: '/select-guests',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>?;
          return GuestSelectionScreen(
            initialAdults: extras?['adults'] ?? 1,
            initialChildren: extras?['children'] ?? 0,
            initialInfants: extras?['infants'] ?? 0,
            initialPets: extras?['pets'] ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/booking-summary',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return BookingFlowScreen(
            property: extras['property'] as Property,
            initialStartDate: extras['startDate'] as DateTime?,
            initialEndDate: extras['endDate'] as DateTime?,
          );
        },
      ),
      GoRoute(
        path: '/booking-confirmation',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return BookingConfirmationScreen(
            property: extras['property'] as Property,
            startDate: extras['startDate'] as DateTime,
            endDate: extras['endDate'] as DateTime,
            totalGuests: extras['totalGuests'] as int? ?? 1,
            totalCost: extras['totalCost'] as int,
          );
        },
      ),
      GoRoute(
        path: '/trip-details',
        builder: (context, state) {
          final booking = state.extra as Booking;
          return TripDetailsScreen(booking: booking);
        },
      ),
      GoRoute(
        path: '/booking-receipt',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return BookingReceiptScreen(
            property: extras['property'] as Property,
            startDate: extras['startDate'] as DateTime,
            endDate: extras['endDate'] as DateTime,
            totalGuests: extras['totalGuests'] as int? ?? 1,
            totalCost: extras['totalCost'] as int,
          );
        },
      ),
      GoRoute(
        path: '/become-host',
        builder: (context, state) => const HostOnboardingScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/host/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AdminHostDetailScreen(userId: id);
        },
      ),
      GoRoute(
        path: '/admin/property/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AdminPropertyDetailScreen(propertyId: id);
        },
      ),
      GoRoute(
        path: '/listings',
        builder: (context, state) => const MyListingsScreen(),
      ),
      GoRoute(
        path: '/wishlists',
        builder: (context, state) => const WishlistsScreen(),
      ),
      GoRoute(
        path: '/switching-hosting',
        builder: (context, state) => const SwitchingHostingScreen(),
      ),
      GoRoute(
        path: '/switching-guest',
        builder: (context, state) => const SwitchingGuestScreen(),
      ),
      GoRoute(
        path: '/connections',
        builder: (context, state) => const ConnectionsScreen(),
      ),
      GoRoute(
        path: '/bookings',
        builder: (context, state) => const HostBookingsScreen(),
      ),
      GoRoute(
        path: '/edit-listing',
        builder: (context, state) {
          final property = state.extra as Property;
          return EditListingScreen(property: property);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/complaints',
        builder: (context, state) => const ComplaintsScreen(),
      ),
      GoRoute(
        path: '/help-center',
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms-of-service',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
        ],
      ),
    ],
  );
});
