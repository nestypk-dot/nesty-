import 'package:flutter_test/flutter_test.dart';
import 'package:nesty/features/host_onboarding/domain/host_profile.dart';

void main() {
  test('host profile draft serializes the Firebase review document', () {
    const draft = HostProfileDraft(
      fullName: 'Muhammad Haad',
      email: 'haad@example.com',
      primaryPhone: '+92 300 1234567',
      verifiedNumbers: ['+92 300 1234567'],
      profilePhotoUrl: 'https://storage.test/profile.jpg',
      selfieUrl: 'https://storage.test/selfie.jpg',
      cnicNumber: '35202-1234567-1',
      cnicFrontUrl: 'https://storage.test/cnic-front.jpg',
      cnicBackUrl: 'https://storage.test/cnic-back.jpg',
      houseAddress: 'Street 1, Lahore',
      houseNumber: 'House 10',
      fardMalkiatUrl: 'https://storage.test/fard.jpg',
      propertyPhotoUrls: [
        'https://storage.test/property-1.jpg',
        'https://storage.test/property-2.jpg',
        'https://storage.test/property-3.jpg',
        'https://storage.test/property-4.jpg',
        'https://storage.test/property-5.jpg',
      ],
      payoutMethod: 'Bank',
      bankName: 'HBL',
      accountHolder: 'Muhammad Haad',
      accountNumber: 'PK00HABB0000000000000000',
      aboutHost: 'A verified professional host with over 5 years of experience.',
      policeCertificateUrl: 'https://storage.test/police.jpg',
      verificationCertificateUrl: 'https://storage.test/verification.jpg',
    );

    final data = draft.toFirestore(
      userId: 'user-123',
      email: 'firebase@example.com',
    );

    expect(data['uid'], 'user-123');
    expect(data['email'], 'firebase@example.com');
    expect(data['status'], HostProfileStatus.pendingReview);
    expect(data['isSubmitted'], isTrue);
    expect(data['completedSteps'], 8);

    final profile = data['profile'] as Map<String, dynamic>;
    expect(profile['fullName'], 'Muhammad Haad');
    expect(profile['profilePhotoUrl'], 'https://storage.test/profile.jpg');
    expect(profile['aboutHost'], 'A verified professional host with over 5 years of experience.');

    final contact = data['contact'] as Map<String, dynamic>;
    expect(contact['primaryPhone'], '+92 300 1234567');
    expect(contact['verifiedNumbers'], ['+92 300 1234567']);

    final propertyVerification =
        data['propertyVerification'] as Map<String, dynamic>;
    expect(propertyVerification['fardMalkiatUploaded'], isTrue);
    expect(propertyVerification['propertyPhotosCount'], 5);

    final payout = data['payout'] as Map<String, dynamic>;
    expect(payout['method'], 'Bank');
    expect(payout['bankName'], 'HBL');
  });
}
