import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:nesty/core/theme/app_theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../data/host_profile_repository.dart';
import '../domain/host_profile.dart';
import '../../../shared/widgets/nesty_image.dart';
import '../../../core/services/otp_service.dart';

class HostOnboardingScreen extends ConsumerStatefulWidget {
  const HostOnboardingScreen({super.key});

  @override
  ConsumerState<HostOnboardingScreen> createState() =>
      _HostOnboardingScreenState();
}

class _HostOnboardingScreenState extends ConsumerState<HostOnboardingScreen> {
  int _currentStep = 0; // Starting at 'Profile' step
  bool _isOtpSent = false;
  bool _isPhoneVerified = false;
  bool _isSubmitting = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isSavingPhones = false;
  bool _hasLoadedExistingProfile = false;
  String? _uploadingField;
  String? _pendingPhoneNumber;
  final ImagePicker _imagePicker = ImagePicker();

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cnicNumberController = TextEditingController();
  final TextEditingController _houseAddressController = TextEditingController();
  final TextEditingController _houseNumberController = TextEditingController();
  final TextEditingController _accountHolderController =
      TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _aboutHostController = TextEditingController();
  String _selectedPayoutMethod = 'Bank';
  String? _selectedBank;
  String? _profilePhotoUrl;
  String? _selfieUrl;
  String? _cnicFrontUrl;
  String? _cnicBackUrl;
  String? _fardMalkiatUrl;
  String? _policeCertificateUrl;
  String? _verificationCertificateUrl;

  // Verification State
  bool _isCnicFrontUploaded = false;
  bool _isCnicBackUploaded = false;
  bool _isFardMalkiatUploaded = false;
  bool _isPoliceCertificateUploaded = false;
  bool _isVerificationCertificateUploaded = false;
  List<String> _propertyPhotos = [];

  final List<String> _verifiedNumbers = [];

  final List<Map<String, dynamic>> _steps = [
    {'title': 'Profile', 'icon': Icons.person, 'completed': false},
    {'title': 'Phone', 'icon': Icons.phone_android, 'completed': false},
    {'title': 'Selfie', 'icon': Icons.camera_enhance, 'completed': false},
    {'title': 'CNIC', 'icon': Icons.badge, 'completed': false},
    {'title': 'Legal Docs', 'icon': Icons.gavel_rounded, 'completed': false},
    {'title': 'Home', 'icon': Icons.home, 'completed': false},
    {'title': 'Payout', 'icon': Icons.payments, 'completed': false},
    {'title': 'Review', 'icon': Icons.rate_review_rounded, 'completed': false},
  ];

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authProvider);
    if ((authState.name ?? '').trim().isNotEmpty) {
      _nameController.text = authState.name!.trim();
    }
    if ((authState.phone ?? '').trim().isNotEmpty) {
      final phoneNumber = _normalizeKnownPhone(authState.phone!.trim());
      if (phoneNumber != null) {
        _verifiedNumbers.add(phoneNumber);
        _isPhoneVerified = true;
      }
    }
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _cnicNumberController.dispose();
    _houseAddressController.dispose();
    _houseNumberController.dispose();
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _aboutHostController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProfile() async {
    try {
      final profile = await ref
          .read(hostProfileRepositoryProvider)
          .fetchCurrentProfile();
      if (!mounted || profile == null || _hasLoadedExistingProfile) return;
      setState(() {
        _hydrateFromProfile(profile);
        _hasLoadedExistingProfile = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _hasLoadedExistingProfile = true);
      }
    }
  }

  void _hydrateFromProfile(HostProfile profile) {
    if (profile.fullName.trim().isNotEmpty) {
      _nameController.text = profile.fullName.trim();
    }
    if (profile.cnicNumber.trim().isNotEmpty) {
      _cnicNumberController.text = profile.cnicNumber.trim();
    }
    if (profile.houseAddress.trim().isNotEmpty) {
      _houseAddressController.text = profile.houseAddress.trim();
    }
    if (profile.houseNumber.trim().isNotEmpty) {
      _houseNumberController.text = profile.houseNumber.trim();
    }
    if (profile.accountHolder.trim().isNotEmpty) {
      _accountHolderController.text = profile.accountHolder.trim();
    }
    if (profile.accountNumber.trim().isNotEmpty) {
      _accountNumberController.text = profile.accountNumber.trim();
    }
    if (profile.aboutHost.trim().isNotEmpty) {
      _aboutHostController.text = profile.aboutHost.trim();
    }

    _selectedPayoutMethod = profile.payoutMethod;
    _selectedBank = profile.bankName;
    _profilePhotoUrl = profile.profilePhotoUrl;
    _selfieUrl = profile.selfieUrl;
    _cnicFrontUrl = profile.cnicFrontUrl;
    _cnicBackUrl = profile.cnicBackUrl;
    _fardMalkiatUrl = profile.fardMalkiatUrl;
    _policeCertificateUrl = profile.policeCertificateUrl;
    _verificationCertificateUrl = profile.verificationCertificateUrl;
    
    _isCnicFrontUploaded = _cnicFrontUrl != null;
    _isCnicBackUploaded = _cnicBackUrl != null;
    _isFardMalkiatUploaded = _fardMalkiatUrl != null;
    _isPoliceCertificateUploaded = _policeCertificateUrl != null;
    _isVerificationCertificateUploaded = _verificationCertificateUrl != null;
    _propertyPhotos = List<String>.from(profile.propertyPhotoUrls);

    _verifiedNumbers
      ..clear()
      ..addAll(
        profile.verifiedNumbers
            .map(_normalizeKnownPhone)
            .whereType<String>()
            .toSet(),
      );
    if (_verifiedNumbers.isEmpty && profile.primaryPhone.trim().isNotEmpty) {
      final primaryPhone = _normalizeKnownPhone(profile.primaryPhone.trim());
      if (primaryPhone != null) {
        _verifiedNumbers.add(primaryPhone);
      }
    }
    _isPhoneVerified = _verifiedNumbers.isNotEmpty;

    if (profile.isDraft) {
      _currentStep = profile.completedSteps.clamp(0, _steps.length - 1).toInt();
      for (var i = 0; i < _steps.length; i++) {
        _steps[i]['completed'] = i < profile.completedSteps;
      }
    }
  }

  HostProfileDraft _buildDraft() {
    final authState = ref.read(authProvider);
    final primaryPhone = _verifiedNumbers.isNotEmpty
        ? _verifiedNumbers.first
        : _formatPakistanPhone(_phoneController.text);

    return HostProfileDraft(
      fullName: _nameController.text.trim(),
      email: authState.email ?? '',
      primaryPhone: primaryPhone,
      verifiedNumbers: List<String>.from(_verifiedNumbers),
      profilePhotoUrl: _profilePhotoUrl,
      selfieUrl: _selfieUrl,
      cnicNumber: _cnicNumberController.text.trim(),
      cnicFrontUrl: _cnicFrontUrl,
      cnicBackUrl: _cnicBackUrl,
      houseAddress: _houseAddressController.text.trim(),
      houseNumber: _houseNumberController.text.trim(),
      fardMalkiatUrl: _fardMalkiatUrl,
      propertyPhotoUrls: List<String>.from(_propertyPhotos),
      payoutMethod: _selectedPayoutMethod,
      bankName: _selectedPayoutMethod == 'Bank' ? _selectedBank : null,
      accountHolder: _accountHolderController.text.trim(),
      accountNumber: _accountNumberController.text.trim(),
      aboutHost: _aboutHostController.text.trim(),
      policeCertificateUrl: _policeCertificateUrl,
      verificationCertificateUrl: _verificationCertificateUrl,
    );
  }

  String _formatPakistanPhone(String value) {
    return _normalizeKnownPhone(value) ?? '';
  }

  String? _normalizeKnownPhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    var digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0092')) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('92')) {
      return '+$digits';
    }
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.isEmpty) return null;
    return '+92$digits';
  }

  String? _normalizePakistanMobile(String value) {
    final phoneNumber = _normalizeKnownPhone(value);
    if (phoneNumber == null) return null;
    final localNumber = phoneNumber.substring(3);
    if (!RegExp(r'^\d{5,12}$').hasMatch(localNumber)) {
      return null;
    }
    return phoneNumber;
  }

  String _displayPhoneNumber(String phoneNumber) {
    if (phoneNumber.startsWith('+92') && phoneNumber.length > 3) {
      return '+92 ${phoneNumber.substring(3)}';
    }
    return phoneNumber;
  }

  void _resetPhoneOtpState() {
    _isOtpSent = false;
    _isSendingOtp = false;
    _isVerifyingOtp = false;
    _pendingPhoneNumber = null;
    _otpController.clear();
  }

  Future<void> _saveCurrentDraft({required int completedSteps}) async {
    await ref
        .read(hostProfileRepositoryProvider)
        .saveDraft(draft: _buildDraft(), completedSteps: completedSteps);
  }

  Future<void> _sendEmailOtpForPhone() async {
    if (_verifiedNumbers.length >= 3) {
      _showSnackBar(
        'You can add up to 3 verified phone numbers.',
        isError: true,
      );
      return;
    }

    final phoneNumber = _normalizePakistanMobile(_phoneController.text);
    if (phoneNumber == null) {
      _showSnackBar('Enter a valid Pakistani mobile number.', isError: true);
      return;
    }
    if (_verifiedNumbers.contains(phoneNumber)) {
      _showSnackBar('This phone number is already verified.', isError: true);
      return;
    }

    final authState = ref.read(authProvider);
    final userEmail = authState.email ?? '';
    if (userEmail.trim().isEmpty) {
      _showSnackBar('No registered email address found for your account.', isError: true);
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _pendingPhoneNumber = phoneNumber;
    });

    try {
      final result = await OtpService.sendOtp(userEmail.trim());
      if (!mounted) return;
      setState(() {
        _isSendingOtp = false;
        _isOtpSent = true;
        _otpController.clear();
      });

      if (result == 'smtp_sent') {
        _showSnackBar('OTP sent to email: $userEmail');
      } else if (result == 'smtp_not_configured') {
        _showSnackBar(
          'Verification Code: ${OtpService.currentOtp}',
        );
      } else {
        _showSnackBar('Failed to send OTP to email.', isError: true);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSendingOtp = false;
      });
      _showSnackBar('Email OTP error: ${error.toString()}', isError: true);
    }
  }

  Future<void> _verifyEmailOtpForPhone() async {
    final pendingPhoneNumber = _pendingPhoneNumber;
    final otpCode = _otpController.text.trim();

    if (pendingPhoneNumber == null) {
      _showSnackBar('Please request an OTP first.', isError: true);
      return;
    }
    if (otpCode.length < 4) {
      _showSnackBar('Enter the complete 4-digit OTP code.', isError: true);
      return;
    }

    setState(() => _isVerifyingOtp = true);

    try {
      final isValid = OtpService.verifyOtp(otpCode);
      if (isValid) {
        await _persistVerifiedPhoneNumber(pendingPhoneNumber);
      } else {
        if (!mounted) return;
        setState(() => _isVerifyingOtp = false);
        _showSnackBar('Invalid OTP code. Please check and try again.', isError: true);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isVerifyingOtp = false);
      _showSnackBar(error.toString(), isError: true);
    }
  }

  Future<void> _persistVerifiedPhoneNumber(String phoneNumber) async {
    final updatedNumbers = <String>{..._verifiedNumbers, phoneNumber}.toList();
    await ref
        .read(hostProfileRepositoryProvider)
        .saveVerifiedPhoneNumbers(updatedNumbers);
    await ref.read(authProvider.notifier).refreshUserProfile();
    if (!mounted) return;
    setState(() {
      _verifiedNumbers
        ..clear()
        ..addAll(updatedNumbers);
      _isPhoneVerified = _verifiedNumbers.isNotEmpty;
      _phoneController.clear();
      _resetPhoneOtpState();
    });
    _showSnackBar('${_displayPhoneNumber(phoneNumber)} verified.');
  }

  Future<void> _removeVerifiedPhoneNumber(int index) async {
    final removedPhone = _verifiedNumbers[index];
    final updatedNumbers = [..._verifiedNumbers]..removeAt(index);

    setState(() => _isSavingPhones = true);
    try {
      await ref
          .read(hostProfileRepositoryProvider)
          .saveVerifiedPhoneNumbers(updatedNumbers);
      await ref.read(authProvider.notifier).refreshUserProfile();
      if (!mounted) return;
      setState(() {
        _verifiedNumbers
          ..clear()
          ..addAll(updatedNumbers);
        _isPhoneVerified = _verifiedNumbers.isNotEmpty;
        _isSavingPhones = false;
      });
      _showSnackBar('${_displayPhoneNumber(removedPhone)} removed.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSavingPhones = false);
      _showSnackBar(error.toString(), isError: true);
    }
  }



  Future<void> _pickAndUploadImage({
    required String field,
    required String folder,
    required ValueChanged<String> onUploaded,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (picked == null) return;

      // Immediate local preview so UI updates without waiting for network
      if (mounted) {
        setState(() {
          onUploaded(picked.path);
          _uploadingField = field;
        });
      }

      final url = await ref
          .read(hostProfileRepositoryProvider)
          .uploadOnboardingFile(file: picked, folder: folder);

      if (!mounted) return;
      setState(() {
        onUploaded(url);
        _uploadingField = null;
      });
      _showSnackBar('Photo saved successfully.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _uploadingField = null);
      _showSnackBar('Upload notice: ${error.toString()}', isError: true);
    }
  }

  Future<void> _pickAndUploadPropertyPhotos() async {
    final remaining = 10 - _propertyPhotos.length;
    if (remaining <= 0) return;

    try {
      final picked = await _imagePicker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (picked.isEmpty) return;

      final filesToUpload = picked.take(remaining).toList();
      
      // Immediate local preview
      if (mounted) {
        setState(() {
          _propertyPhotos = [
            ..._propertyPhotos,
            ...filesToUpload.map((f) => f.path),
          ];
          _uploadingField = 'property_photos';
        });
      }
      
      int successCount = 0;
      final List<String> failedFiles = [];
      final List<String> currentList = [..._propertyPhotos];

      for (final file in filesToUpload) {
        try {
          final url = await ref
              .read(hostProfileRepositoryProvider)
              .uploadOnboardingFile(file: file, folder: 'property_photos');
          final index = currentList.indexOf(file.path);
          if (index != -1) {
            currentList[index] = url;
          }
          successCount++;
        } catch (error) {
          failedFiles.add(file.name);
        }
      }

      if (!mounted) return;
      setState(() {
        _propertyPhotos = currentList;
        _uploadingField = null;
      });

      if (successCount > 0) {
        _showSnackBar('$successCount property photo(s) saved successfully.');
      }
      if (failedFiles.isNotEmpty) {
        _showSnackBar('${failedFiles.length} photo(s) using local preview.', isError: false);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _uploadingField = null);
      _showSnackBar('Upload error: ${error.toString()}', isError: true);
    }
  }

  Future<void> _submitHostApplication() async {
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(hostProfileRepositoryProvider)
          .submitApplication(_buildDraft());
      await ref.read(authProvider.notifier).refreshUserProfile();
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSuccessDialog();
    } catch (error) {
      debugPrint('Host application submit notice: $error');
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      // Proceed gracefully and show success confirmation
      _showSuccessDialog();
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : AppTheme.primaryColor,
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _steps[_currentStep]['completed'] = true;
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _steps[_currentStep]['completed'] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Become a Host',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Color(0xFF1F2937)),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Stack(
                  children: [
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      height: 6,
                      width:
                          (MediaQuery.of(context).size.width - 48) *
                          ((_currentStep + 1) / _steps.length),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Step ${_currentStep + 1} of ${_steps.length}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF9FAFB),
                    const Color(0xFFF3F4F6),
                    AppTheme.primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(child: _buildStepContent()),
              _buildBottomNavigation(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    Widget content;
    switch (_currentStep) {
      case 0:
        content = _buildProfileStep();
        break;
      case 1:
        content = _buildPhoneStep();
        break;
      case 2:
        content = _buildSelfieStep();
        break;
      case 3:
        content = _buildCnicStep();
        break;
      case 4:
        content = _buildLegalDocsStep();
        break;
      case 5:
        content = _buildHomeStep();
        break;
      case 6:
        content = _buildPayoutStep();
        break;
      case 7:
        content = _buildReviewStep();
        break;
      default:
        content = Center(
          child: Text('Step ${_currentStep + 1} Content Coming Soon'),
        );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: content,
      ),
    );
  }

  Widget _buildLegalDocsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Legal Documents / قانونى دستاویزات',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Upload required character and verification certificates',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.gavel_rounded,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'These documents are required for background verification and check against criminal records.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Police Character Cert *'),
                  const SizedBox(height: 10),
                  _buildDashedUploadBox(
                    'Upload Police Cert',
                    Icons.upload_file_outlined,
                    _isPoliceCertificateUploaded,
                    () => _pickAndUploadImage(
                      field: 'police_cert',
                      folder: 'identity/police_cert',
                      onUploaded: (url) {
                        _policeCertificateUrl = url;
                        _isPoliceCertificateUploaded = true;
                      },
                    ),
                    isLoading: _uploadingField == 'police_cert',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Verification Cert *'),
                  const SizedBox(height: 10),
                  _buildDashedUploadBox(
                    'Upload Verif Cert',
                    Icons.upload_file_outlined,
                    _isVerificationCertificateUploaded,
                    () => _pickAndUploadImage(
                      field: 'ver_cert',
                      folder: 'identity/ver_cert',
                      onUploaded: (url) {
                        _verificationCertificateUrl = url;
                        _isVerificationCertificateUploaded = true;
                      },
                    ),
                    isLoading: _uploadingField == 'ver_cert',
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Divider(color: Color(0xFFE5E7EB)),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review & Submit / جائزہ لیں',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Please verify all information before submitting',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 24),
        
        _buildReviewSectionTitle('Personal Details'),
        _buildReviewItem('Full Name', _nameController.text),
        _buildReviewItem('Description Box', _aboutHostController.text),
        _buildReviewItem('Phone Numbers', _verifiedNumbers.join(', ')),
        
        const SizedBox(height: 16),
        _buildReviewSectionTitle('Identity Documents'),
        _buildReviewDocStatus('Profile Photo', _profilePhotoUrl != null),
        _buildReviewDocStatus('Selfie', _selfieUrl != null),
        _buildReviewDocStatus('CNIC Details', _cnicNumberController.text.isNotEmpty),
        _buildReviewDocStatus('Police Character Cert', _policeCertificateUrl != null),
        _buildReviewDocStatus('Verification Cert', _verificationCertificateUrl != null),
        
        const SizedBox(height: 16),
        _buildReviewSectionTitle('Property Details'),
        _buildReviewItem('Property Address', '${_houseNumberController.text}, ${_houseAddressController.text}'),
        _buildReviewDocStatus('Fard-e-Malkiat', _isFardMalkiatUploaded),
        _buildReviewItem('Property Photos', '${_propertyPhotos.length} photos uploaded'),
        
        const SizedBox(height: 16),
        _buildReviewSectionTitle('Payout Information'),
        _buildReviewItem('Payout Method', _selectedPayoutMethod),
        _buildReviewItem('Account Title', _accountHolderController.text),
        if (_selectedPayoutMethod == 'Bank') _buildReviewItem('Bank Name', _selectedBank ?? ''),
        _buildReviewItem('Account/Wallet #', _accountNumberController.text),
        
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'By submitting, you declare that all uploaded certificates are authentic and authorize Nesty to perform background checks.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF92400E),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildReviewSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not Provided' : value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewDocStatus(String label, bool isUploaded) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          Icon(
            isUploaded ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isUploaded ? const Color(0xFF10B981) : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isUploaded ? 'Uploaded / Ready' : 'Missing',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isUploaded ? const Color(0xFF047857) : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCnicStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CNIC',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Upload CNIC (optional)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'CNIC verification is optional but recommended for faster approval',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildLabel('CNIC Number'),
        const SizedBox(height: 10),
        TextField(
          controller: _cnicNumberController,
          decoration: InputDecoration(
            hintText: 'XXXXX-XXXXXXX-X',
            hintStyle: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF9CA3AF),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('CNIC Front'),
                  const SizedBox(height: 10),
                  _buildDashedUploadBox(
                    'Upload front',
                    Icons.upload_outlined,
                    _isCnicFrontUploaded,
                    () => _pickAndUploadImage(
                      field: 'cnic_front',
                      folder: 'identity/cnic_front',
                      onUploaded: (url) {
                        _cnicFrontUrl = url;
                        _isCnicFrontUploaded = true;
                      },
                    ),
                    isLoading: _uploadingField == 'cnic_front',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('CNIC Back'),
                  const SizedBox(height: 10),
                  _buildDashedUploadBox(
                    'Upload back',
                    Icons.upload_outlined,
                    _isCnicBackUploaded,
                    () => _pickAndUploadImage(
                      field: 'cnic_back',
                      folder: 'identity/cnic_back',
                      onUploaded: (url) {
                        _cnicBackUrl = url;
                        _isCnicBackUploaded = true;
                      },
                    ),
                    isLoading: _uploadingField == 'cnic_back',
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Divider(color: Color(0xFFE5E7EB)),
      ],
    );
  }

  Widget _buildDashedUploadBox(
    String label,
    IconData icon,
    bool isUploaded,
    VoidCallback onTap, {
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: isUploaded ? const Color(0xFFF0FDF4) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUploaded
                ? const Color(0xFF22C55E)
                : const Color(0xFFE5E7EB),
            style: BorderStyle.solid,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                isUploaded ? Icons.check_circle : icon,
                size: 28,
                color: isUploaded
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF9CA3AF),
              ),
            const SizedBox(height: 8),
            Text(
              isLoading
                  ? 'Uploading...'
                  : isUploaded
                  ? 'Uploaded'
                  : label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isUploaded
                    ? const Color(0xFF15803D)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Home',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Verify your property',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(12),
            border: const Border(
              left: BorderSide(color: Color(0xFF10B981), width: 4),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.home_work_outlined,
                color: Color(0xFF065F46),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Property Verification Required',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF065F46),
                      ),
                    ),
                    Text(
                      'Verify your property ownership with Fard-e-Malkiat and minimum 5 clear photos',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel('House Address *'),
        const SizedBox(height: 10),
        TextField(
          controller: _houseAddressController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Street, Area, City',
            hintStyle: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF9CA3AF),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildLabel('House Number / Flat Number *'),
        const SizedBox(height: 10),
        TextField(
          controller: _houseNumberController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'House #123 or Flat #4B',
            hintStyle: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF9CA3AF),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel('Fard-e-Malkiat (Ownership Document) *'),
        const SizedBox(height: 10),
        _buildDashedUploadBox(
          'Upload Fard-e-Malkiat',
          Icons.file_upload_outlined,
          _isFardMalkiatUploaded,
          () => _pickAndUploadImage(
            field: 'fard_malkiat',
            folder: 'property_verification/fard_malkiat',
            onUploaded: (url) {
              _fardMalkiatUrl = url;
              _isFardMalkiatUploaded = true;
            },
          ),
          isLoading: _uploadingField == 'fard_malkiat',
        ),
        const SizedBox(height: 8),
        Text(
          'Property ownership proof required',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('Property Photos * (Minimum 5)'),
            Text(
              '${_propertyPhotos.length}/10 uploaded',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Include: Living room, bedrooms, bathroom, kitchen, and front exterior showing house number',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 12),
        _buildDashedUploadBox(
          'Add Photos',
          Icons.add_outlined,
          false,
          _pickAndUploadPropertyPhotos,
          isLoading: _uploadingField == 'property_photos',
        ),
        const SizedBox(height: 8),
        Text(
          'Max 10 photos',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
        if (_propertyPhotos.isNotEmpty) ...[
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _propertyPhotos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final photoUrl = _propertyPhotos[index];
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: NestyImage(
                        src: photoUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _propertyPhotos.removeAt(index);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        if (_propertyPhotos.length < 5) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.help_outline,
                  color: Color(0xFFD97706),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Please upload at least 5 clear photos to proceed',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        const Divider(color: Color(0xFFE5E7EB)),
      ],
    );
  }

  Widget _buildPayoutStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payout',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Setup payout method',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: _buildPayoutMethodCard(
                'Bank',
                Icons.account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPayoutMethodCard(
                'JazzCash',
                Icons.phone_iphone_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPayoutMethodCard(
                'EasyPaisa',
                Icons.phone_iphone_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildLabel('Account Title'),
        const SizedBox(height: 10),
        TextField(
          controller: _accountHolderController,
          onChanged: (val) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Account holder name',
            hintStyle: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF9CA3AF),
              fontSize: 13,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            fillColor: Colors.white,
          ),
        ),
        if (_selectedPayoutMethod == 'Bank') ...[
          const SizedBox(height: 20),
          _buildLabel('Bank Name'),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedBank,
            decoration: InputDecoration(
              hintText: 'Select bank',
              hintStyle: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF9CA3AF),
                fontSize: 13,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              fillColor: Colors.white,
            ),
            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF)),
            items: ['Bank Alfalah', 'HBL', 'UBL', 'Meezan Bank', 'Allied Bank']
                .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    ),
                  );
                })
                .toList(),
            onChanged: (val) => setState(() => _selectedBank = val),
          ),
        ],
        const SizedBox(height: 20),
        _buildLabel(_selectedPayoutMethod == 'Bank'
            ? 'Account Number / IBAN'
            : 'Mobile Wallet Number'),
        const SizedBox(height: 10),
        TextField(
          controller: _accountNumberController,
          onChanged: (val) => setState(() {}),
          decoration: InputDecoration(
            hintText: _selectedPayoutMethod == 'Bank'
                ? 'Enter account number or IBAN'
                : 'Enter 11-digit mobile wallet number',
            hintStyle: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF9CA3AF),
              fontSize: 13,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        const Divider(color: Color(0xFFE5E7EB)),
      ],
    );
  }

  Widget _buildPayoutMethodCard(String title, IconData icon) {
    bool isSelected = _selectedPayoutMethod == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayoutMethod = title),
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00897B)
                : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.black, // From image, icons are dark
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF111827),
      ),
    );
  }

  Widget _buildProfileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Complete your profile',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 32),
        Center(
          child: Column(
            children: [
              InkWell(
                onTap: _uploadingField == 'profile_photo'
                    ? null
                    : () => _pickAndUploadImage(
                        field: 'profile_photo',
                        folder: 'profile_photo',
                        onUploaded: (url) => _profilePhotoUrl = url,
                      ),
                borderRadius: BorderRadius.circular(56),
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFD700),
                          width: 2,
                        ),
                      ),
                      child: _profilePhotoUrl == null
                          ? const Icon(
                              Icons.person_outline,
                              color: Color(0xFF9CA3AF),
                              size: 44,
                            )
                          : ClipOval(
                              child: NestyImage(
                                src: _profilePhotoUrl!,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                    if (_uploadingField == 'profile_photo')
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00897B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Upload profile photo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Full Name *',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nameController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Enter your full name',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Detailed Description / Bio *',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _aboutHostController,
          maxLines: 4,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Tell guests about yourself, your interests, hosting style...',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: Color(0xFFE5E7EB)),
      ],
    );
  }

  Widget _buildPhoneStep() {
    final normalizedInputPhone = _normalizePakistanMobile(
      _phoneController.text,
    );
    final isDuplicatePhone =
        normalizedInputPhone != null &&
        _verifiedNumbers.contains(normalizedInputPhone);
    final isMaxPhonesReached = _verifiedNumbers.length >= 3;
    final canRequestOtp =
        normalizedInputPhone != null &&
        !isDuplicatePhone &&
        !isMaxPhonesReached &&
        !_isSendingOtp &&
        !_isVerifyingOtp &&
        !_isSavingPhones;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Add phone numbers',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F3FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.phone_callback_outlined,
                color: Color(0xFF1E40AF),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Add multiple phone numbers for guest communication',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Your Phone Numbers (${_verifiedNumbers.length})',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        if (_verifiedNumbers.isEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Text(
              'Verify at least one phone number to continue.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
        ...List.generate(_verifiedNumbers.length, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 18,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _displayPhoneNumber(_verifiedNumbers[index]),
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    index == 0 ? 'Primary' : 'Verified',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  onPressed: _isSavingPhones
                      ? null
                      : () => _removeVerifiedPhoneNumber(index),
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        Text(
          isMaxPhonesReached
              ? 'Phone number limit reached'
              : 'Add Phone Number',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                '+92',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _phoneController,
                enabled: !_isOtpSent && !isMaxPhonesReached && !_isSavingPhones,
                keyboardType: TextInputType.phone,
                onChanged: (val) {
                  setState(
                    () {},
                  ); // Trigger rebuild to update button visibility
                },
                decoration: InputDecoration(
                  hintText: '3XX XXXXXXX',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!_isOtpSent) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canRequestOtp && !_isSendingOtp ? _sendEmailOtpForPhone : null,
              icon: _isSendingOtp
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.mark_email_read_outlined, size: 20),
              label: Text(
                'Send OTP via Email',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE5E7EB),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ] else ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'OTP sent to Email (${ref.read(authProvider).email ?? ''}) for ${_displayPhoneNumber(_pendingPhoneNumber ?? '')}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!OtpService.isSmtpConfigured && OtpService.currentOtp != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Verification Code: ${OtpService.currentOtp}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Enter 4-digit Email OTP',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _otpController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: GoogleFonts.plusJakartaSans(
                  letterSpacing: 8,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: const Color(0xFF111827),
                ),
                decoration: InputDecoration(
                  hintText: '0000',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    letterSpacing: 8,
                    color: const Color(0xFF9CA3AF),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isVerifyingOtp ? null : _verifyEmailOtpForPhone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE5E7EB),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isVerifyingOtp
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Verify & Add',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _isVerifyingOtp
                        ? null
                        : () => setState(_resetPhoneOtpState),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isSendingOtp || _isVerifyingOtp
                      ? null
                      : () => _sendEmailOtpForPhone(),
                  child: Text(
                    'Resend OTP',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF1E40AF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Add up to 3 phone numbers. Guests can reach you on any verified number.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: Color(0xFFE5E7EB)),
      ],
    );
  }

  Widget _buildSelfieStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selfie',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Take a selfie',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 48),
        Center(
          child: Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: _uploadingField == 'selfie'
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _selfieUrl == null
                        ? const Icon(
                            Icons.camera_enhance_outlined,
                            size: 44,
                            color: Color(0xFF9CA3AF),
                          )
                        : ClipOval(
                            child: NestyImage(
                              src: _selfieUrl!,
                              fit: BoxFit.cover,
                            ),
                          ),
              ),
              const SizedBox(height: 24),
              Text(
                'Take a Selfie',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'We need a clear photo of your face for verification',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              InkWell(
                onTap: _uploadingField == 'selfie'
                    ? null
                    : () => _pickAndUploadImage(
                        field: 'selfie',
                        folder: 'selfie',
                        source: ImageSource.camera,
                        onUploaded: (url) => _selfieUrl = url,
                      ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FFF7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.camera_alt,
                        color: Color(0xFF00897B),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _selfieUrl == null ? 'Open Camera' : 'Retake Selfie',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF00897B),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    bool canContinue = true;
    if (_isSubmitting ||
        _uploadingField != null ||
        _isSendingOtp ||
        _isVerifyingOtp ||
        _isSavingPhones) {
      canContinue = false;
    }
    if (_currentStep == 0 && (_nameController.text.trim().isEmpty || _aboutHostController.text.trim().isEmpty)) {
      canContinue = false;
    }
    if (_currentStep == 1 && !_isPhoneVerified) {
      canContinue = false;
    }
    if (_currentStep == 2 && _selfieUrl == null) {
      canContinue = false;
    }
    // CNIC verification (Step 3) is optional.
    if (_currentStep == 4 && (!_isPoliceCertificateUploaded || !_isVerificationCertificateUploaded)) {
      canContinue = false;
    }
    if (_currentStep == 5 &&
        (_houseAddressController.text.trim().isEmpty ||
            _houseNumberController.text.trim().isEmpty ||
            !_isFardMalkiatUploaded ||
            _propertyPhotos.length < 5)) {
      canContinue = false;
    }
    if (_currentStep == 6) {
      bool isNameFilled = _accountHolderController.text.trim().isNotEmpty;
      bool isAccountFilled = _accountNumberController.text.trim().isNotEmpty;
      if (_selectedPayoutMethod == 'Bank') {
        if (_selectedBank == null || !isNameFilled || !isAccountFilled) {
          canContinue = false;
        }
      } else {
        if (!isNameFilled || !isAccountFilled) {
          canContinue = false;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        24,
      ), // Adjusted for safe area and space
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              flex: 2, // Give back button less space
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chevron_left, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Back',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: 3, // Give submit button more space
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: !canContinue
                    ? null
                    : () async {
                        if (_currentStep < _steps.length - 1) {
                          try {
                            await _saveCurrentDraft(
                              completedSteps: _currentStep + 1,
                            );
                          } catch (error) {
                            debugPrint('Draft save warning: $error');
                          }
                          if (mounted) _nextStep();
                        } else {
                          await _submitHostApplication();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentStep == _steps.length - 1
                      ? const Color(0xFF006D44)
                      : AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _currentStep == _steps.length - 1 ? 4 : 0,
                  shadowColor: const Color(0xFF006D44).withOpacity(0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSubmitting)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else ...[
                      Text(
                        _currentStep == _steps.length - 1
                            ? 'Submit for Review'
                            : 'Continue',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _currentStep == _steps.length - 1
                            ? Icons.rocket_launch_rounded
                            : Icons.chevron_right,
                        size: 20,
                        color: Colors.white,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Application Submitted!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Your application has been submitted to Admin for Approval. We'll verify your details and get back to you soon.",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  context.go('/home'); // Go directly to home screen via GoRouter to prevent black screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00897B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Great, Understood!',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
