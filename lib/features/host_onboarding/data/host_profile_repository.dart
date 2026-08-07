import 'dart:io';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/host_profile.dart';

class HostProfileRepository {
  HostProfileRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('host_profiles');

  Stream<HostProfile?> watchCurrentProfile() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<HostProfile?>.value(null);
      }

      return _profiles.doc(user.uid).snapshots().map((snapshot) {
        try {
          if (!snapshot.exists) return null;
          return HostProfile.fromFirestore(snapshot);
        } catch (e) {
          print('Error parsing HostProfile from snapshot: $e');
          return null;
        }
      }).handleError((error) {
        print('Error watching HostProfile stream: $error');
      });
    });
  }

  Future<HostProfile?> fetchCurrentProfile() async {
    try {
      final user = _requireUser();
      final snapshot = await _profiles.doc(user.uid).get();
      if (!snapshot.exists) return null;
      return HostProfile.fromFirestore(snapshot);
    } catch (e) {
      print('Error fetching HostProfile from Firebase: $e');
      return null;
    }
  }

  Future<String> uploadOnboardingFile({
    required XFile file,
    required String folder,
  }) async {
    final user = _requireUser();
    final bytes = await file.readAsBytes();
    final extension = _extensionFor(file.name);
    final mimeType = file.mimeType ?? _contentTypeFor(extension);
    final safeFileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(RegExp(r'[^\w\.\-]'), '_')}';

    try {
      final storageRef = _storage
          .ref()
          .child('onboarding')
          .child(user.uid)
          .child(folder)
          .child(safeFileName);

      final metadata = SettableMetadata(contentType: mimeType);
      UploadTask uploadTask;
      final fileObj = File(file.path);
      if (fileObj.existsSync()) {
        uploadTask = storageRef.putFile(fileObj, metadata);
      } else {
        uploadTask = storageRef.putData(bytes, metadata);
      }
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Warning: Firebase Storage upload failed for $folder ($e). Using local fallback.');
      final localFile = File(file.path);
      if (localFile.existsSync()) {
        return file.path;
      }
      if (bytes.length <= 400000) {
        final base64String = base64Encode(bytes);
        return 'data:$mimeType;base64,$base64String';
      }
      throw Exception('Failed to upload image to Firebase Storage ($e). Please check your internet connection.');
    }
  }

  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      forceResendingToken: forceResendingToken,
    );
  }

  Future<void> confirmPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await verifyPhoneCredential(credential);
  }

  Future<void> verifyPhoneCredential(PhoneAuthCredential credential) async {
    final tempAppName = 'TempPhoneVerifier_${DateTime.now().millisecondsSinceEpoch}';
    final tempApp = await Firebase.initializeApp(
      name: tempAppName,
      options: Firebase.app().options,
    );
    final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
    try {
      await tempAuth.signInWithCredential(credential);
    } finally {
      await tempAuth.signOut();
      await tempApp.delete();
    }
  }

  Future<void> saveVerifiedPhoneNumbers(List<String> verifiedNumbers) async {
    final user = _requireUser();
    final email = user.email ?? '';
    final profileRef = _profiles.doc(user.uid);
    final userRef = _firestore.collection('users').doc(user.uid);
    final existing = await profileRef.get();
    final existingData = existing.data() ?? const <String, dynamic>{};
    final primaryPhone = verifiedNumbers.isNotEmpty
        ? verifiedNumbers.first
        : '';
    final completedSteps =
        ((existingData['completedSteps'] as num?)?.toInt() ?? 0) < 2
        ? 2
        : (existingData['completedSteps'] as num).toInt();
    final now = FieldValue.serverTimestamp();

    final batch = _firestore.batch();
    batch.set(profileRef, {
      'userId': user.uid,
      'uid': user.uid,
      'email': email,
      'status': existingData['status'] ?? HostProfileStatus.draft,
      'isSubmitted': existingData['isSubmitted'] ?? false,
      'isApproved': existingData['isApproved'] ?? false,
      'completedSteps': completedSteps,
      'contact': {
        'primaryPhone': primaryPhone,
        'verifiedNumbers': verifiedNumbers,
        'verifiedCount': verifiedNumbers.length,
      },
      'updatedAt': now,
      if (!existing.exists) 'createdAt': now,
    }, SetOptions(merge: true));
    batch.set(userRef, {
      'uid': user.uid,
      'email': email,
      'phone': primaryPhone,
      'verifiedPhoneNumbers': verifiedNumbers,
      'updatedAt': now,
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> updateHostSettings({
    String? fullName,
    String? aboutHost,
    List<String>? languages,
    String? contactPreference,
    String? checkInTime,
    String? checkOutTime,
    bool? smokingAllowed,
    bool? petsAllowed,
    bool? eventsAllowed,
    bool? familyFriendly,
    bool? bachelorAllowed,
    String? cancellationPolicy,
    String? customRules,
    bool? idRequired,
    bool? photoRequired,
    bool? messageRequired,
    bool? phoneRequired,
    bool? manualApproval,
    bool? autoReplyEnabled,
    String? bookingConfirmationMessage,
    String? preCheckInMessage,
    bool? notifyBookingRequests,
    bool? notifyBookingConfirmations,
    bool? notifyMessages,
    bool? notifyPayouts,
    bool? notifyReviews,
    bool? notifyEmail,
    bool? notifySMS,
  }) async {
    final user = _requireUser();
    final profileRef = _profiles.doc(user.uid);
    final userRef = _firestore.collection('users').doc(user.uid);
    final now = FieldValue.serverTimestamp();

    final updates = <String, dynamic>{
      'updatedAt': now,
    };

    if (fullName != null) {
      updates['profile.fullName'] = fullName;
    }
    if (aboutHost != null) {
      updates['profile.aboutHost'] = aboutHost;
    }
    if (languages != null) {
      updates['profile.languages'] = languages;
    }
    if (contactPreference != null) {
      updates['profile.contactPreference'] = contactPreference;
    }
    if (checkInTime != null) {
      updates['rules.checkInTime'] = checkInTime;
    }
    if (checkOutTime != null) {
      updates['rules.checkOutTime'] = checkOutTime;
    }
    if (smokingAllowed != null) {
      updates['rules.smokingAllowed'] = smokingAllowed;
    }
    if (petsAllowed != null) {
      updates['rules.petsAllowed'] = petsAllowed;
    }
    if (eventsAllowed != null) {
      updates['rules.eventsAllowed'] = eventsAllowed;
    }
    if (familyFriendly != null) {
      updates['rules.familyFriendly'] = familyFriendly;
    }
    if (bachelorAllowed != null) {
      updates['rules.bachelorAllowed'] = bachelorAllowed;
    }
    if (cancellationPolicy != null) {
      updates['rules.cancellationPolicy'] = cancellationPolicy;
    }
    if (customRules != null) {
      updates['rules.customRules'] = customRules;
    }
    if (idRequired != null) {
      updates['guests.idRequired'] = idRequired;
    }
    if (photoRequired != null) {
      updates['guests.photoRequired'] = photoRequired;
    }
    if (messageRequired != null) {
      updates['guests.messageRequired'] = messageRequired;
    }
    if (phoneRequired != null) {
      updates['guests.phoneRequired'] = phoneRequired;
    }
    if (manualApproval != null) {
      updates['guests.manualApproval'] = manualApproval;
    }
    if (autoReplyEnabled != null) {
      updates['messaging.autoReplyEnabled'] = autoReplyEnabled;
    }
    if (bookingConfirmationMessage != null) {
      updates['messaging.bookingConfirmationMessage'] = bookingConfirmationMessage;
    }
    if (preCheckInMessage != null) {
      updates['messaging.preCheckInMessage'] = preCheckInMessage;
    }
    if (notifyBookingRequests != null) {
      updates['alerts.notifyBookingRequests'] = notifyBookingRequests;
    }
    if (notifyBookingConfirmations != null) {
      updates['alerts.notifyBookingConfirmations'] = notifyBookingConfirmations;
    }
    if (notifyMessages != null) {
      updates['alerts.notifyMessages'] = notifyMessages;
    }
    if (notifyPayouts != null) {
      updates['alerts.notifyPayouts'] = notifyPayouts;
    }
    if (notifyReviews != null) {
      updates['alerts.notifyReviews'] = notifyReviews;
    }
    if (notifyEmail != null) {
      updates['alerts.notifyEmail'] = notifyEmail;
    }
    if (notifySMS != null) {
      updates['alerts.notifySMS'] = notifySMS;
    }

    final batch = _firestore.batch();
    batch.set(profileRef, updates, SetOptions(merge: true));
    if (fullName != null) {
      batch.set(userRef, {
        'name': fullName,
        'updatedAt': now,
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Map<String, dynamic> _sanitizeFirestoreData(Map<String, dynamic> rawMap) {
    final Map<String, dynamic> cleaned = {};

    rawMap.forEach((key, value) {
      if (value == null) {
        cleaned[key] = null;
      } else if (value is Map<String, dynamic>) {
        cleaned[key] = _sanitizeFirestoreData(value);
      } else if (value is Map) {
        cleaned[key] = _sanitizeFirestoreData(Map<String, dynamic>.from(value));
      } else if (value is List) {
        cleaned[key] = value
            .map((item) {
              if (item is Map<String, dynamic>) {
                return _sanitizeFirestoreData(item);
              } else if (item is Map) {
                return _sanitizeFirestoreData(Map<String, dynamic>.from(item));
              } else if (item is String) {
                if (item.contains('[truncated]') || item.contains('[base64_truncated]')) {
                  return null;
                }
              }
              return item;
            })
            .where((item) => item != null)
            .toList();
      } else if (value is String) {
        if (value.contains('[truncated]') || value.contains('[base64_truncated]')) {
          cleaned[key] = null;
        } else {
          cleaned[key] = value;
        }
      } else {
        cleaned[key] = value;
      }
    });

    return cleaned;
  }

  Future<void> saveDraft({
    required HostProfileDraft draft,
    required int completedSteps,
  }) async {
    try {
      final user = _requireUser();
      final email = user.email ?? draft.email;
      final profileRef = _profiles.doc(user.uid);
      final existing = await profileRef.get();
      final now = FieldValue.serverTimestamp();

      final data = draft.toFirestore(userId: user.uid, email: email)
        ..addAll({
          'status': HostProfileStatus.draft,
          'isSubmitted': false,
          'isApproved': false,
          'completedSteps': completedSteps.clamp(0, 8),
          'updatedAt': now,
          if (!existing.exists) 'createdAt': now,
        });

      final sanitizedData = _sanitizeFirestoreData(data);
      await profileRef.set(sanitizedData, SetOptions(merge: true));
    } catch (e) {
      print('Warning: Background draft save encountered non-fatal Firestore issue: $e');
    }
  }

  Future<void> submitApplication(HostProfileDraft draft) async {
    final user = _requireUser();
    final email = user.email ?? draft.email;
    final profileRef = _profiles.doc(user.uid);
    final userRef = _firestore.collection('users').doc(user.uid);
    final existing = await profileRef.get();
    final now = FieldValue.serverTimestamp();

    final profileData = draft.toFirestore(userId: user.uid, email: email)
      ..addAll({
        'status': HostProfileStatus.pendingReview,
        'isSubmitted': true,
        'isApproved': false,
        'completedSteps': 8,
        'submittedAt': now,
        'updatedAt': now,
        if (!existing.exists) 'createdAt': now,
      });

    final userData = {
      'uid': user.uid,
      'name': draft.fullName,
      'email': email,
      'phone': draft.primaryPhone,
      'photoUrl': draft.profilePhotoUrl ?? user.photoURL ?? '',
      'role': 'host',
      'hostProfileId': user.uid,
      'hostApplicationStatus': HostProfileStatus.pendingReview,
      'isSubmitted': true,
      'isApproved': false,
      'onboardedAt': now,
      'updatedAt': now,
    };

    final sanitizedProfileData = _sanitizeFirestoreData(profileData);
    final sanitizedUserData = _sanitizeFirestoreData(userData);

    final batch = _firestore.batch();
    batch.set(profileRef, sanitizedProfileData, SetOptions(merge: true));
    batch.set(userRef, sanitizedUserData, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> approveHost(String userId) async {
    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch();
    
    batch.set(_profiles.doc(userId), {
      'status': HostProfileStatus.approved,
      'isApproved': true,
      'isSubmitted': true,
      'approvedAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
    
    batch.set(_firestore.collection('users').doc(userId), {
      'role': 'host',
      'isApproved': true,
      'isSubmitted': true,
      'hostApplicationStatus': HostProfileStatus.approved,
      'updatedAt': now,
    }, SetOptions(merge: true));
    
    await batch.commit();
  }

  Future<void> rejectHost(String userId, String reason) async {
    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch();
    
    batch.set(_profiles.doc(userId), {
      'status': HostProfileStatus.rejected,
      'isApproved': false,
      'isSubmitted': false, // Let them submit again
      'rejectionReason': reason,
      'updatedAt': now,
    }, SetOptions(merge: true));
    
    batch.set(_firestore.collection('users').doc(userId), {
      'isApproved': false,
      'isSubmitted': false, // Let them submit again
      'hostApplicationStatus': HostProfileStatus.rejected,
      'updatedAt': now,
    }, SetOptions(merge: true));
    
    await batch.commit();
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in before creating a host profile.');
    }
    return user;
  }

  String _extensionFor(String name) {
    final index = name.lastIndexOf('.');
    if (index == -1 || index == name.length - 1) {
      return '.jpg';
    }
    return name.substring(index).toLowerCase();
  }

  String _contentTypeFor(String extension) {
    switch (extension) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'image/jpeg';
    }
  }
}

final hostProfileRepositoryProvider = Provider<HostProfileRepository>((ref) {
  return HostProfileRepository();
});

final currentHostProfileProvider = StreamProvider.autoDispose<HostProfile?>((
  ref,
) {
  return ref.watch(hostProfileRepositoryProvider).watchCurrentProfile();
});
