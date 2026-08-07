import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../host_onboarding/domain/host_profile.dart';
import '../../home/domain/property.dart';
import '../../host_onboarding/data/host_profile_repository.dart';
import '../../host/providers/listings_provider.dart';

// Watches host profiles that are pending review
final pendingHostsProvider = StreamProvider<List<HostProfile>>((ref) {
  final db = FirebaseFirestore.instance;
  return db
      .collection('host_profiles')
      .where('status', isEqualTo: HostProfileStatus.pendingReview)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => HostProfile.fromFirestore(doc))
        .toList();
  });
});

// Watches properties that are pending review
final pendingPropertiesProvider = StreamProvider<List<Property>>((ref) {
  final db = FirebaseFirestore.instance;
  return db
      .collection('properties')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => Property.fromJson(doc.data(), doc.id))
        .toList();
  });
});

class AdminController {
  final Ref _ref;
  final _db = FirebaseFirestore.instance;

  AdminController(this._ref);

  Future<void> approveHost(String hostId) async {
    await _ref.read(hostProfileRepositoryProvider).approveHost(hostId);
  }

  Future<void> rejectHost(String hostId, String reason) async {
    await _ref.read(hostProfileRepositoryProvider).rejectHost(hostId, reason);
  }

  Future<void> approveProperty(String propertyId) async {
    await _ref.read(hostListingsProvider.notifier).approveProperty(propertyId);
  }

  Future<void> rejectProperty(String propertyId, String reason) async {
    await _db.collection('properties').doc(propertyId).update({
      'status': 'rejected',
      'rejectionReason': reason,
    });
    // Local optimistic update will be synced via snapshot stream
  }
}

final adminControllerProvider = Provider<AdminController>((ref) {
  return AdminController(ref);
});
