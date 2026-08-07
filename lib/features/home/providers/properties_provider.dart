import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/property.dart';

class AllPropertiesNotifier extends Notifier<List<Property>> {
  final _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _subscription;

  @override
  List<Property> build() {
    // On startup: clean bad test data & seed professional properties
    Future.microtask(() async {
      await _cleanAndSeedProperties();
    });

    _startRealtimeListener();

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return [];
  }

  /// Removes mock/dummy properties and bad test properties from Firestore on startup.
  Future<void> _cleanAndSeedProperties() async {
    try {
      final snapshot = await _db.collection('properties').get();

      // Delete any mock/dummy properties & bad test properties:
      for (final doc in snapshot.docs) {
        final id = doc.id;
        final data = doc.data();
        final String location = (data['location'] ?? '').toLowerCase();
        final String hostId = data['hostId'] ?? '';

        final bool isMockProp = id == '1' ||
            id == '2' ||
            id == '3' ||
            id == '4' ||
            id == '5' ||
            id == '6' ||
            hostId.startsWith('host_');

        final bool isBadTestProp =
            location.contains('fgf') ||
            location.contains('test');

        if (isMockProp || isBadTestProp) {
          try {
            await doc.reference.delete();
          } catch (_) {
            // Ignore if we don't have permission to delete
          }
        }
      }
    } catch (e) {
      print('Error during property cleanup: $e');
    }
  }

  void _startRealtimeListener() {
    _subscription?.cancel();
    _subscription = _db
        .collection('properties')
        .snapshots()
        .listen(
      (snapshot) {
        final list = snapshot.docs
            .map((doc) => Property.fromJson(doc.data(), doc.id))
            .where((p) {
              if (p.status != 'published') return false;
              final loc = p.location.toLowerCase();
              final isBad = loc.contains('fgf') || loc.contains('test');
              return !isBad;
            })
            .toList();
        // Sort: guest favorites first, then by rating descending
        list.sort((a, b) {
          if (a.isGuestFavorite && !b.isGuestFavorite) return -1;
          if (!a.isGuestFavorite && b.isGuestFavorite) return 1;
          return b.rating.compareTo(a.rating);
        });
        state = list;
      },
      onError: (e) {
        print('Error listening to all properties: $e');
        state = [];
      },
    );
  }

  void refresh() {
    _startRealtimeListener();
  }
}

final allPropertiesProvider =
    NotifierProvider<AllPropertiesNotifier, List<Property>>(() {
  return AllPropertiesNotifier();
});
