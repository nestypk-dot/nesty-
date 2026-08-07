import 'package:cloud_firestore/cloud_firestore.dart';

class HostProfile {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String primaryPhone;
  final List<String> verifiedNumbers;
  final String? profilePhotoUrl;
  final String? selfieUrl;
  final String cnicNumber;
  final String? cnicFrontUrl;
  final String? cnicBackUrl;
  final String houseAddress;
  final String houseNumber;
  final String? fardMalkiatUrl;
  final List<String> propertyPhotoUrls;
  final String payoutMethod;
  final String? bankName;
  final String accountHolder;
  final String accountNumber;
  final String status;
  final bool isSubmitted;
  final bool isApproved;
  final int completedSteps;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  
  // Legal Documents
  final String? policeCertificateUrl;
  final String? verificationCertificateUrl;
  final String? rejectionReason;

  // Settings & Rules Fields
  final List<String> languages;
  final String contactPreference;
  final String aboutHost;
  final String checkInTime;
  final String checkOutTime;
  final bool smokingAllowed;
  final bool petsAllowed;
  final bool eventsAllowed;
  final bool familyFriendly;
  final bool bachelorAllowed;
  final String cancellationPolicy;
  final String customRules;

  // Guest Requirements Fields
  final bool idRequired;
  final bool photoRequired;
  final bool messageRequired;
  final bool phoneRequired;
  final bool manualApproval;

  // Messaging Settings Fields
  final bool autoReplyEnabled;
  final String bookingConfirmationMessage;
  final String preCheckInMessage;

  // Notification Preferences Fields
  final bool notifyBookingRequests;
  final bool notifyBookingConfirmations;
  final bool notifyMessages;
  final bool notifyPayouts;
  final bool notifyReviews;
  final bool notifyEmail;
  final bool notifySMS;

  const HostProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.primaryPhone,
    required this.verifiedNumbers,
    this.profilePhotoUrl,
    this.selfieUrl,
    required this.cnicNumber,
    this.cnicFrontUrl,
    this.cnicBackUrl,
    required this.houseAddress,
    required this.houseNumber,
    this.fardMalkiatUrl,
    required this.propertyPhotoUrls,
    required this.payoutMethod,
    this.bankName,
    required this.accountHolder,
    required this.accountNumber,
    required this.status,
    required this.isSubmitted,
    required this.isApproved,
    required this.completedSteps,
    this.createdAt,
    this.updatedAt,
    this.submittedAt,
    this.approvedAt,
    this.policeCertificateUrl,
    this.verificationCertificateUrl,
    this.rejectionReason,
    this.languages = const ['English', 'Urdu'],
    this.contactPreference = 'In-app messaging only',
    this.aboutHost = '',
    this.checkInTime = '02:00 PM',
    this.checkOutTime = '11:00 AM',
    this.smokingAllowed = false,
    this.petsAllowed = false,
    this.eventsAllowed = false,
    this.familyFriendly = true,
    this.bachelorAllowed = false,
    this.cancellationPolicy = 'Flexible',
    this.customRules = '',
    this.idRequired = true,
    this.photoRequired = false,
    this.messageRequired = true,
    this.phoneRequired = true,
    this.manualApproval = false,
    this.autoReplyEnabled = false,
    this.bookingConfirmationMessage = 'Thank you for booking! We\'re excited to host you...',
    this.preCheckInMessage = 'Looking forward to your arrival tomorrow! Here are the check-in details...',
    this.notifyBookingRequests = true,
    this.notifyBookingConfirmations = true,
    this.notifyMessages = true,
    this.notifyPayouts = true,
    this.notifyReviews = true,
    this.notifyEmail = true,
    this.notifySMS = false,
  });

  bool get isDraft => status == HostProfileStatus.draft;
  bool get isPendingReview => status == HostProfileStatus.pendingReview;
  bool get isRejected => status == HostProfileStatus.rejected;

  factory HostProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final profile = _asMap(data['profile']);
    final contact = _asMap(data['contact']);
    final identity = _asMap(data['identity']);
    final propertyVerification = _asMap(data['propertyVerification']);
    final payout = _asMap(data['payout']);
    final rules = _asMap(data['rules']);
    final guests = _asMap(data['guests'] ?? data['guestRequirements']);
    final messaging = _asMap(data['messaging']);
    final alerts = _asMap(data['alerts'] ?? data['notifications']);

    return HostProfile(
      id: snapshot.id,
      userId: data['userId'] ?? data['uid'] ?? snapshot.id,
      fullName: profile['fullName'] ?? data['fullName'] ?? '',
      email: data['email'] ?? '',
      primaryPhone: contact['primaryPhone'] ?? data['phoneNumber'] ?? '',
      verifiedNumbers: _asStringList(contact['verifiedNumbers']),
      profilePhotoUrl: _sanitizeImageUrl(profile['profilePhotoUrl']),
      selfieUrl: _sanitizeImageUrl(profile['selfieUrl']),
      cnicNumber: identity['cnicNumber'] ?? data['cnicNumber'] ?? '',
      cnicFrontUrl: _sanitizeImageUrl(identity['cnicFrontUrl']),
      cnicBackUrl: _sanitizeImageUrl(identity['cnicBackUrl']),
      houseAddress:
          propertyVerification['houseAddress'] ?? data['houseAddress'] ?? '',
      houseNumber:
          propertyVerification['houseNumber'] ?? data['houseNumber'] ?? '',
      fardMalkiatUrl: _sanitizeImageUrl(propertyVerification['fardMalkiatUrl']),
      propertyPhotoUrls: _asSanitizedStringList(
        propertyVerification['propertyPhotoUrls'],
      ),
      payoutMethod: payout['method'] ?? data['payoutMethod'] ?? 'Bank',
      bankName: payout['bankName'] ?? data['bankName'],
      accountHolder: payout['accountHolder'] ?? data['accountHolder'] ?? '',
      accountNumber: payout['accountNumber'] ?? data['accountNumber'] ?? '',
      status: data['status'] ?? HostProfileStatus.notStarted,
      isSubmitted: data['isSubmitted'] ?? false,
      isApproved: data['isApproved'] ?? false,
      completedSteps: (data['completedSteps'] as num?)?.toInt() ?? 0,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
      submittedAt: _readDate(data['submittedAt']),
      approvedAt: _readDate(data['approvedAt']),
      policeCertificateUrl: _sanitizeImageUrl(identity['policeCertificateUrl'] ?? data['policeCertificateUrl']),
      verificationCertificateUrl: _sanitizeImageUrl(identity['verificationCertificateUrl'] ?? data['verificationCertificateUrl']),
      rejectionReason: data['rejectionReason'] ?? '',
      languages: _asStringList(profile['languages']),
      contactPreference: profile['contactPreference'] ?? 'In-app messaging only',
      aboutHost: profile['aboutHost'] ?? '',
      checkInTime: rules['checkInTime'] ?? '02:00 PM',
      checkOutTime: rules['checkOutTime'] ?? '11:00 AM',
      smokingAllowed: rules['smokingAllowed'] ?? false,
      petsAllowed: rules['petsAllowed'] ?? false,
      eventsAllowed: rules['eventsAllowed'] ?? false,
      familyFriendly: rules['familyFriendly'] ?? true,
      bachelorAllowed: rules['bachelorAllowed'] ?? false,
      cancellationPolicy: rules['cancellationPolicy'] ?? 'Flexible',
      customRules: rules['customRules'] ?? '',
      idRequired: guests['idRequired'] ?? true,
      photoRequired: guests['photoRequired'] ?? false,
      messageRequired: guests['messageRequired'] ?? true,
      phoneRequired: guests['phoneRequired'] ?? true,
      manualApproval: guests['manualApproval'] ?? false,
      autoReplyEnabled: messaging['autoReplyEnabled'] ?? false,
      bookingConfirmationMessage: messaging['bookingConfirmationMessage'] ?? 'Thank you for booking! We\'re excited to host you...',
      preCheckInMessage: messaging['preCheckInMessage'] ?? 'Looking forward to your arrival tomorrow! Here are the check-in details...',
      notifyBookingRequests: alerts['notifyBookingRequests'] ?? true,
      notifyBookingConfirmations: alerts['notifyBookingConfirmations'] ?? true,
      notifyMessages: alerts['notifyMessages'] ?? true,
      notifyPayouts: alerts['notifyPayouts'] ?? true,
      notifyReviews: alerts['notifyReviews'] ?? true,
      notifyEmail: alerts['notifyEmail'] ?? true,
      notifySMS: alerts['notifySMS'] ?? false,
    );
  }

  static String? _sanitizeImageUrl(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    final str = value.trim();
    if (str.contains('[truncated]') || str.contains('[base64_truncated]')) {
      return null;
    }
    return str;
  }

  static List<String> _asSanitizedStringList(Object? value) {
    if (value is Iterable) {
      return value
          .whereType<String>()
          .map((s) => _sanitizeImageUrl(s))
          .whereType<String>()
          .toList();
    }
    return const [];
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return const {};
  }

  static List<String> _asStringList(Object? value) {
    if (value is Iterable) {
      return value.whereType<String>().toList();
    }
    return const [];
  }

  static DateTime? _readDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class HostProfileStatus {
  static const notStarted = 'not_started';
  static const draft = 'draft';
  static const pendingReview = 'pending_review';
  static const approved = 'approved';
  static const rejected = 'rejected';
}

class HostProfileDraft {
  final String fullName;
  final String email;
  final String primaryPhone;
  final List<String> verifiedNumbers;
  final String? profilePhotoUrl;
  final String? selfieUrl;
  final String cnicNumber;
  final String? cnicFrontUrl;
  final String? cnicBackUrl;
  final String houseAddress;
  final String houseNumber;
  final String? fardMalkiatUrl;
  final List<String> propertyPhotoUrls;
  final String payoutMethod;
  final String? bankName;
  final String accountHolder;
  final String accountNumber;
  final String aboutHost;
  final String? policeCertificateUrl;
  final String? verificationCertificateUrl;

  const HostProfileDraft({
    required this.fullName,
    required this.email,
    required this.primaryPhone,
    required this.verifiedNumbers,
    required this.profilePhotoUrl,
    required this.selfieUrl,
    required this.cnicNumber,
    required this.cnicFrontUrl,
    required this.cnicBackUrl,
    required this.houseAddress,
    required this.houseNumber,
    required this.fardMalkiatUrl,
    required this.propertyPhotoUrls,
    required this.payoutMethod,
    required this.bankName,
    required this.accountHolder,
    required this.accountNumber,
    required this.aboutHost,
    this.policeCertificateUrl,
    this.verificationCertificateUrl,
  });

  Map<String, dynamic> toFirestore({
    required String userId,
    required String email,
  }) {
    return {
      'userId': userId,
      'uid': userId,
      'email': email,
      'status': HostProfileStatus.pendingReview,
      'isSubmitted': true,
      'isApproved': false,
      'completedSteps': 8,
      'profile': {
        'fullName': fullName,
        'profilePhotoUrl': profilePhotoUrl,
        'selfieUrl': selfieUrl,
        'aboutHost': aboutHost,
      },
      'contact': {
        'primaryPhone': primaryPhone,
        'verifiedNumbers': verifiedNumbers,
      },
      'identity': {
        'cnicNumber': cnicNumber,
        'cnicFrontUrl': cnicFrontUrl,
        'cnicBackUrl': cnicBackUrl,
        'cnicFrontUploaded': cnicFrontUrl != null,
        'cnicBackUploaded': cnicBackUrl != null,
        'policeCertificateUrl': policeCertificateUrl,
        'verificationCertificateUrl': verificationCertificateUrl,
        'policeCertificateUploaded': policeCertificateUrl != null,
        'verificationCertificateUploaded': verificationCertificateUrl != null,
      },
      'propertyVerification': {
        'houseAddress': houseAddress,
        'houseNumber': houseNumber,
        'fardMalkiatUrl': fardMalkiatUrl,
        'fardMalkiatUploaded': fardMalkiatUrl != null,
        'propertyPhotoUrls': propertyPhotoUrls,
        'propertyPhotosCount': propertyPhotoUrls.length,
      },
      'payout': {
        'method': payoutMethod,
        'bankName': bankName,
        'accountHolder': accountHolder,
        'accountNumber': accountNumber,
      },
    };
  }
}
