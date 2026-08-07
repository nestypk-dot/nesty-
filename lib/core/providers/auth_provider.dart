import 'dart:io';
import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum AppRole { guest, host, admin }

class AuthState {
  final bool isAuthenticated;
  final bool isSubmitted;
  final bool isApproved;
  final AppRole role;
  final String? name;
  final String? email;
  final String? adminName;
  final String? phone;
  final String? photoUrl;
  final List<String> favorites;

  final bool bookingNotifs;
  final bool messageNotifs;
  final bool reviewNotifs;
  final bool promoNotifs;
  final bool showOnlineStatus;
  final bool showProfilePublicly;

  AuthState({
    required this.isAuthenticated,
    this.isSubmitted = false,
    this.isApproved = false,
    this.role = AppRole.guest,
    this.name,
    this.email,
    this.adminName,
    this.phone,
    this.photoUrl,
    this.favorites = const [],
    this.bookingNotifs = true,
    this.messageNotifs = true,
    this.reviewNotifs = true,
    this.promoNotifs = false,
    this.showOnlineStatus = true,
    this.showProfilePublicly = true,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isSubmitted,
    bool? isApproved,
    AppRole? role,
    String? name,
    String? email,
    String? adminName,
    String? phone,
    String? photoUrl,
    List<String>? favorites,
    bool? bookingNotifs,
    bool? messageNotifs,
    bool? reviewNotifs,
    bool? promoNotifs,
    bool? showOnlineStatus,
    bool? showProfilePublicly,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      isApproved: isApproved ?? this.isApproved,
      role: role ?? this.role,
      name: name ?? this.name,
      email: email ?? this.email,
      adminName: adminName ?? this.adminName,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      favorites: favorites ?? this.favorites,
      bookingNotifs: bookingNotifs ?? this.bookingNotifs,
      messageNotifs: messageNotifs ?? this.messageNotifs,
      reviewNotifs: reviewNotifs ?? this.reviewNotifs,
      promoNotifs: promoNotifs ?? this.promoNotifs,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showProfilePublicly: showProfilePublicly ?? this.showProfilePublicly,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn();

  @override
  AuthState build() {
    final user = _auth.currentUser;
    if (user != null) {
      _loadUserProfile(user.uid);
      // Mark user online on app start (fire and forget)
      _db.collection('users').doc(user.uid).set({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'photoUrl': user.photoURL ?? '',
      }, SetOptions(merge: true)).catchError((_) {});
      return AuthState(
        isAuthenticated: true,
        isApproved: false,
        isSubmitted: false,
        role: AppRole.guest,
        name: user.displayName ?? 'User',
        email: user.email ?? '',
        photoUrl: user.photoURL,
      );
    }
    return AuthState(
      isAuthenticated: false,
      isApproved: false,
      isSubmitted: false,
      role: AppRole.guest,
    );
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final hostProfileDoc = await _db
          .collection('host_profiles')
          .doc(uid)
          .get();
      final hostProfileData = hostProfileDoc.data();
      if (doc.exists) {
        final data = doc.data()!;
        final roleStr = data['role'] ?? 'guest';
        AppRole role = AppRole.guest;
        if (roleStr == 'host') role = AppRole.host;
        if (roleStr == 'admin') role = AppRole.admin;
        if (hostProfileData?['isSubmitted'] == true) role = AppRole.host;

        final hostProfile = hostProfileData?['profile'];
        final hostProfileName = hostProfile is Map<String, dynamic>
            ? hostProfile['fullName'] as String?
            : null;
        final hostProfilePhoto = hostProfile is Map<String, dynamic>
            ? hostProfile['profilePhotoUrl'] as String?
            : null;
        final hostContact = hostProfileData?['contact'];
        final hostPhone = hostContact is Map<String, dynamic>
            ? hostContact['primaryPhone'] as String?
            : null;

        final favorites = List<String>.from(data['favorites'] ?? []);
        final settings = data['settings'] as Map<String, dynamic>?;

        state = state.copyWith(
          name:
              hostProfileName ??
              data['name'] ??
              _auth.currentUser?.displayName ??
              'User',
          email: data['email'] ?? _auth.currentUser?.email ?? '',
          phone: hostPhone ?? data['phone'],
          photoUrl: hostProfilePhoto ?? data['photoUrl'] ?? _auth.currentUser?.photoURL,
          role: role,
          isSubmitted:
              hostProfileData?['isSubmitted'] ?? data['isSubmitted'] ?? false,
          isApproved:
              hostProfileData?['isApproved'] ?? data['isApproved'] ?? false,
          adminName:
              (hostProfileData?['isApproved'] ?? data['isApproved']) == true
              ? 'Admin'
              : null,
          favorites: favorites,
          bookingNotifs: settings?['bookingNotifs'] ?? true,
          messageNotifs: settings?['messageNotifs'] ?? true,
          reviewNotifs: settings?['reviewNotifs'] ?? true,
          promoNotifs: settings?['promoNotifs'] ?? false,
          showOnlineStatus: settings?['showOnlineStatus'] ?? true,
          showProfilePublicly: settings?['showProfilePublicly'] ?? true,
        );
      } else if (hostProfileData != null) {
        final profile = hostProfileData['profile'];
        final contact = hostProfileData['contact'];
        final favorites = List<String>.from(hostProfileData['favorites'] ?? []);
        final settings = hostProfileData['settings'] as Map<String, dynamic>?;

        state = state.copyWith(
          name: profile is Map<String, dynamic>
              ? profile['fullName'] as String?
              : _auth.currentUser?.displayName ?? 'User',
          email: hostProfileData['email'] ?? _auth.currentUser?.email ?? '',
          phone: contact is Map<String, dynamic>
              ? contact['primaryPhone'] as String?
              : null,
          photoUrl: profile is Map<String, dynamic>
              ? profile['profilePhotoUrl'] as String?
              : _auth.currentUser?.photoURL,
          role: hostProfileData['isSubmitted'] == true
              ? AppRole.host
              : AppRole.guest,
          isSubmitted: hostProfileData['isSubmitted'] ?? false,
          isApproved: hostProfileData['isApproved'] ?? false,
          adminName: hostProfileData['isApproved'] == true ? 'Admin' : null,
          favorites: favorites,
          bookingNotifs: settings?['bookingNotifs'] ?? true,
          messageNotifs: settings?['messageNotifs'] ?? true,
          reviewNotifs: settings?['reviewNotifs'] ?? true,
          promoNotifs: settings?['promoNotifs'] ?? false,
          showOnlineStatus: settings?['showOnlineStatus'] ?? true,
          showProfilePublicly: settings?['showProfilePublicly'] ?? true,
        );
      }
    } catch (_) {}
  }

  Future<void> refreshUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _loadUserProfile(user.uid);
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user;
    if (user != null) {
      // Mark user online + update photoUrl in Firestore
      await _db.collection('users').doc(user.uid).set({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'photoUrl': user.photoURL ?? '',
      }, SetOptions(merge: true));

      state = AuthState(
        isAuthenticated: true,
        name: user.displayName ?? 'User',
        email: user.email ?? '',
        role: AppRole.guest,
      );
      await _loadUserProfile(user.uid);
    }
  }

  /// Real Google Sign-In using google_sign_in package
  Future<void> loginWithGoogle() async {
    // Trigger the Google authentication flow
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // User cancelled the sign-in
      throw Exception('sign_in_canceled');
    }

    // Obtain the auth details from the request
    final googleAuth = await googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google credential
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      // Check if this user is new (first sign-in with Google)
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser) {
        // Save user data to Firestore for first-time Google sign-in
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': user.displayName ?? googleUser.displayName ?? 'User',
          'email': user.email ?? '',
          'phone': '',
          'location': 'Pakistan',
          'createdAt': FieldValue.serverTimestamp(),
          'role': 'guest',
          'isSubmitted': false,
          'isApproved': false,
          'signInMethod': 'google',
          'photoUrl': user.photoURL ?? '',
          'isOnline': true,
        });
      } else {
        // Update online status + photoUrl for returning users
        await _db.collection('users').doc(user.uid).set({
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
          'photoUrl': user.photoURL ?? '',
        }, SetOptions(merge: true));
      }

      state = AuthState(
        isAuthenticated: true,
        name: user.displayName ?? 'User',
        email: user.email ?? '',
        role: AppRole.guest,
        isApproved: false,
        isSubmitted: false,
      );

      await _loadUserProfile(user.uid);
    }
  }

  void login({bool approved = false}) {
    state = AuthState(
      isAuthenticated: true,
      isApproved: approved,
      name: 'Muhammad Haad',
      email: 'muhammad.haad96@gmail.com',
      adminName: 'Admin',
    );
  }

  Future<void> logout() async {
    // Mark user offline before signing out
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _db.collection('users').doc(user.uid).set({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
    state = AuthState(isAuthenticated: false);
  }

  void setRole(AppRole role) {
    state = state.copyWith(role: role);
  }

  Future<void> submitApplication({Map<String, dynamic>? onboardingData}) async {
    state = state.copyWith(isSubmitted: true, role: AppRole.host);
    final user = _auth.currentUser;
    if (user != null) {
      final Map<String, dynamic> updates = {
        'isSubmitted': true,
        'role': 'host',
        'onboardedAt': FieldValue.serverTimestamp(),
      };
      if (onboardingData != null) {
        updates.addAll(onboardingData);
      }
      await _db
          .collection('users')
          .doc(user.uid)
          .set(updates, SetOptions(merge: true));
    }
  }

  Future<void> approve() async {
    state = state.copyWith(
      isApproved: true,
      isSubmitted: true,
      adminName: 'Admin',
      role: AppRole.host,
    );
    final user = _auth.currentUser;
    if (user != null) {
      final batch = _db.batch();
      batch.set(_db.collection('users').doc(user.uid), {
        'isApproved': true,
        'isSubmitted': true,
        'role': 'host',
      }, SetOptions(merge: true));
      batch.set(_db.collection('host_profiles').doc(user.uid), {
        'isApproved': true,
        'isSubmitted': true,
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await batch.commit();
    }
  }

  void setAuthenticatedUser({
    required String name,
    required String email,
    required String phone,
  }) {
    state = AuthState(
      isAuthenticated: true,
      isApproved: false,
      isSubmitted: false,
      role: AppRole.guest,
      name: name,
      email: email,
      phone: phone,
    );
  }

  Future<void> toggleFavorite(String propertyId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final currentFavorites = List<String>.from(state.favorites);
    if (currentFavorites.contains(propertyId)) {
      currentFavorites.remove(propertyId);
    } else {
      currentFavorites.add(propertyId);
    }
    
    state = state.copyWith(favorites: currentFavorites);
    
    try {
      await _db.collection('users').doc(user.uid).set({
        'favorites': currentFavorites,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating favorites: $e');
    }
  }

  Future<void> updateProfilePhoto(String filePath) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final base64String = base64Encode(bytes);
    final dataUrl = 'data:image/jpeg;base64,$base64String';

    try {
      await user.updatePhotoURL(dataUrl);
    } catch (_) {}

    await _db.collection('users').doc(user.uid).set({
      'photoUrl': dataUrl,
    }, SetOptions(merge: true));

    final hostProfileRef = _db.collection('host_profiles').doc(user.uid);
    final hostProfileDoc = await hostProfileRef.get();
    if (hostProfileDoc.exists) {
      await hostProfileRef.set({
        'profile': {
          'profilePhotoUrl': dataUrl,
        }
      }, SetOptions(merge: true));
    }

    state = state.copyWith(photoUrl: dataUrl);
  }

  Future<void> updateUserSettings({
    bool? bookingNotifs,
    bool? messageNotifs,
    bool? reviewNotifs,
    bool? promoNotifs,
    bool? showOnlineStatus,
    bool? showProfilePublicly,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final Map<String, dynamic> updates = {};
    if (bookingNotifs != null) updates['settings.bookingNotifs'] = bookingNotifs;
    if (messageNotifs != null) updates['settings.messageNotifs'] = messageNotifs;
    if (reviewNotifs != null) updates['settings.reviewNotifs'] = reviewNotifs;
    if (promoNotifs != null) updates['settings.promoNotifs'] = promoNotifs;
    if (showOnlineStatus != null) {
      updates['settings.showOnlineStatus'] = showOnlineStatus;
      if (!showOnlineStatus) updates['isOnline'] = false;
    }
    if (showProfilePublicly != null) updates['settings.showProfilePublicly'] = showProfilePublicly;

    state = state.copyWith(
      bookingNotifs: bookingNotifs ?? state.bookingNotifs,
      messageNotifs: messageNotifs ?? state.messageNotifs,
      reviewNotifs: reviewNotifs ?? state.reviewNotifs,
      promoNotifs: promoNotifs ?? state.promoNotifs,
      showOnlineStatus: showOnlineStatus ?? state.showOnlineStatus,
      showProfilePublicly: showProfilePublicly ?? state.showProfilePublicly,
    );

    try {
      await _db.collection('users').doc(user.uid).update(updates);
    } catch (_) {
      await _db
          .collection('users')
          .doc(user.uid)
          .set(updates, SetOptions(merge: true));
    }
  }

  Future<void> updatePhoneNumber(String phone) async {
    final user = _auth.currentUser;
    if (user == null) return;

    state = state.copyWith(phone: phone);

    await _db.collection('users').doc(user.uid).set({
      'phone': phone,
    }, SetOptions(merge: true));

    final hostProfileRef = _db.collection('host_profiles').doc(user.uid);
    final hostProfileDoc = await hostProfileRef.get();
    if (hostProfileDoc.exists) {
      await hostProfileRef.set({
        'contact': {
          'primaryPhone': phone,
        }
      }, SetOptions(merge: true));
    }
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final String uid = user.uid;

    await _db.collection('users').doc(uid).delete();
    await _db.collection('host_profiles').doc(uid).delete();

    final properties = await _db
        .collection('properties')
        .where('hostId', isEqualTo: uid)
        .get();
    final batch = _db.batch();
    for (final doc in properties.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    await user.delete();
    state = AuthState(isAuthenticated: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final isSubmittedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isSubmitted;
});

final isApprovedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isApproved;
});

final roleProvider = Provider<AppRole>((ref) {
  return ref.watch(authProvider).role;
});
