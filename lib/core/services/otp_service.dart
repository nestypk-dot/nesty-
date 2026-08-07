import 'dart:math';
import 'package:email_otp/email_otp.dart';

class OtpService {
  static String? _currentOtp;
  static bool _lastDeliverySucceeded = false;

  // -------------------------------------------------------------
  // SMTP CONFIGURATION (Gmail SMTP Settings)
  // -------------------------------------------------------------
  static const String smtpHost = 'smtp.gmail.com';
  static const int smtpPort = 587;
  
  // TODO: Replace with your actual Gmail address (e.g. nesty.app@gmail.com)
  static const String smtpUsername = 'YOUR_GMAIL_ADDRESS';
  
  // TODO: Replace with your 16-digit Gmail App Password (not regular password)
  static const String smtpPassword = 'YOUR_GMAIL_APP_PASSWORD';

  /// Check if SMTP email delivery is configured.
  static bool get isSmtpConfigured =>
      smtpUsername.isNotEmpty &&
      smtpUsername != 'YOUR_GMAIL_ADDRESS' &&
      smtpPassword.isNotEmpty &&
      smtpPassword != 'YOUR_GMAIL_APP_PASSWORD';

  /// Generates and sends a 4-digit verification OTP to the user's email.
  /// Returns 'smtp_sent', 'smtp_not_configured', or 'failed'.
  static Future<String> sendOtp(String email) async {
    _lastDeliverySucceeded = false;
    
    // Generate a secure 4-digit numeric OTP
    final random = Random();
    _currentOtp = (1000 + random.nextInt(9000)).toString();

    // Log the OTP clearly for developer/test access
    print('=========================================');
    print('NESTY VERIFICATION OTP FOR $email: $_currentOtp');
    print('=========================================');

    // 1. Attempt SMTP if credentials are configured
    if (isSmtpConfigured) {
      try {
        EmailOTP.config(
          appName: 'Nesty',
          otpType: OTPType.numeric,
          emailTheme: EmailTheme.v1,
        );
        EmailOTP.setSMTP(
          host: smtpHost,
          emailPort: smtpPort == 465 ? EmailPort.port465 : EmailPort.port587,
          secureType: smtpPort == 465 ? SecureType.ssl : SecureType.tls,
          username: smtpUsername,
          password: smtpPassword,
        );
        final sent = await EmailOTP.sendOTP(email: email);
        if (sent) {
          _lastDeliverySucceeded = true;
          return 'smtp_sent';
        }
      } catch (e) {
        print('SMTP Email delivery failed: $e');
        return 'failed';
      }
    } else {
      return 'smtp_not_configured';
    }

    return 'failed';
  }

  /// Verifies the entered OTP against the generated one.
  static bool verifyOtp(String otp) {
    if (_currentOtp == null) return false;
    return _currentOtp == otp.trim();
  }

  /// Get the current active OTP.
  static String? get currentOtp => _currentOtp;

  /// Whether SMTP successfully sent the last OTP.
  static bool get lastDeliverySucceeded => _lastDeliverySucceeded;
}
