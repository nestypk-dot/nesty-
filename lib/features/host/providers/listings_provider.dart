import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../home/domain/property.dart';
import '../../home/providers/properties_provider.dart';
import '../../../core/providers/auth_provider.dart';

class HostListingsNotifier extends Notifier<List<Property>> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  StreamSubscription<QuerySnapshot>? _subscription;

  @override
  List<Property> build() {
    ref.watch(authProvider);
    // Start real-time listener when notifier is built
    _startRealtimeListener();
    // Cancel subscription when provider is disposed
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return [];
  }

  void _startRealtimeListener() {
    _subscription?.cancel();
    final user = _auth.currentUser;
    final String hostId = user?.uid ?? 'mock_host_id';

    _subscription = _db
        .collection('properties')
        .where('hostId', isEqualTo: hostId)
        .snapshots()
        .listen(
      (snapshot) {
        final listings = snapshot.docs
            .map((doc) => Property.fromJson(doc.data(), doc.id))
            .toList();
        // Sort by newest first (using id which is a timestamp)
        listings.sort((a, b) => b.id.compareTo(a.id));
        state = listings;
      },
      onError: (e) {
        print('Error in real-time host listings stream: $e');
      },
    );
  }

  /// Call this to force a re-subscription (e.g. after auth change)
  Future<void> loadListings() async {
    _startRealtimeListener();
  }

  Future<void> addProperty(Property property) async {
    final user = _auth.currentUser;
    final String hostId = user?.uid ?? 'mock_host_id';
    final String hostName = user?.displayName ?? 'Muhammad Haad';

    final propertyWithHost = property.copyWith(
      hostId: hostId,
      hostName: hostName,
      hostImageUrl: user?.photoURL ?? property.hostImageUrl,
      hostReviews: 0,
      hostRating: 0.0,
      hostExperienceYears: 1,
      hostJoinedYear: DateTime.now().year,
      hostBio: 'Nesty Host since ${DateTime.now().year}',
    );

    // Optimistic update — add to local state immediately so UI feels instant
    state = [propertyWithHost, ...state];

    // Persist to Firestore (real-time listener will also update state)
    await _db
        .collection('properties')
        .doc(propertyWithHost.id)
        .set(propertyWithHost.toJson());
  }

  Future<void> approveProperty(String id) async {
    await _db
        .collection('properties')
        .doc(id)
        .update({'status': 'published'});
    // Local optimistic update (stream will sync too)
    state = [
      for (final p in state)
        if (p.id == id) p.copyWith(status: 'published') else p,
    ];
    // Refresh the guest properties lists immediately
    ref.read(allPropertiesProvider.notifier).refresh();
  }

  Future<void> updateProperty(Property updated) async {
    await _db
        .collection('properties')
        .doc(updated.id)
        .update(updated.toJson());
    state = [
      for (final p in state) if (p.id == updated.id) updated else p,
    ];
    ref.read(allPropertiesProvider.notifier).refresh();
  }

  Future<void> removeProperty(String id) async {
    await _db.collection('properties').doc(id).delete();
    state = state.where((p) => p.id != id).toList();
    ref.read(allPropertiesProvider.notifier).refresh();
  }
}

final hostListingsProvider =
    NotifierProvider<HostListingsNotifier, List<Property>>(() {
  return HostListingsNotifier();
});
