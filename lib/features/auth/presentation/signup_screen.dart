import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/otp_service.dart';

class SignupScreen extends ConsumerStatefulWidget {
  final String role; // 'guest' or 'host'
  const SignupScreen({super.key, this.role = 'guest'});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();

      // Check if email already exists in Firestore
      final emailQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      if (emailQuery.docs.isNotEmpty) {
        _showError('Email is already registered / یہ ای میل پہلے سے رجسٹرڈ ہے');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Check if phone number already exists in Firestore
      final phoneQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .get();
      if (phoneQuery.docs.isNotEmpty) {
        _showError('Phone number is already registered / یہ فون نمبر پہلے سے رجسٹرڈ ہے');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final deliveryResult = await OtpService.sendOtp(email);

      if (mounted) {
        if (deliveryResult == 'smtp_sent') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'OTP sent to your email successfully / او ٹی پی ای میل پر بھیج دیا گیا ہے',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppTheme.primaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );

          context.push(
            '/otp',
            extra: {
              'name': _nameController.text.trim(),
              'email': email,
              'phone': _phoneController.text.trim(),
              'password': _passwordController.text,
              'role': widget.role,
            },
          );
        } else if (deliveryResult == 'smtp_not_configured') {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('SMTP Setup Required / او ٹی پی سیٹ اپ ضروری ہے'),
              content: Text(
                'Gmail SMTP is currently not configured.\n\n'
                'Please set your Gmail Address and App Password in:\n'
                'lib/core/services/otp_service.dart\n\n'
                'For testing, you can proceed using the test code:\n'
                'Test OTP Code: ${OtpService.currentOtp}\n\n'
                'ٹیسٹ کوڈ کے ساتھ آگے بڑھیں: ${OtpService.currentOtp}'
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push(
                      '/otp',
                      extra: {
                        'name': _nameController.text.trim(),
                        'email': email,
                        'phone': _phoneController.text.trim(),
                        'password': _passwordController.text,
                        'role': widget.role,
                      },
                    );
                  },
                  child: const Text('Proceed / آگے بڑھیں'),
                ),
              ],
            ),
          );
        } else {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('OTP Delivery Failed / او ٹی پی بھیجنے میں خرابی'),
              content: const Text(
                'Failed to deliver OTP email. Please check:\n'
                '1. Your internet connection.\n'
                '2. Your SMTP settings (Gmail & App Password) in otp_service.dart.\n\n'
                'براہ کرم اپنا انٹرنیٹ کنکشن اور ای میل سیٹنگز چیک کریں۔'
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                  child: const Text('OK / ٹھیک ہے'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      _showError('An unexpected error occurred: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Background accents for continuity
          Positioned(
            top: -100,
            right: -80,
            child: CircleAvatar(
              radius: 140,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.04),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: AppTheme.accentColor.withOpacity(0.03),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.topLeft,
                    child: InkWell(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/login');
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 6.0),
                          child: Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary, size: 18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Welcome Section
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Create an account',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join our marketplace today',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Signup Form in a clean layout
                  Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'Enter your full name',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Full Name is required / نام ضروری ہے';
                            }
                            if (value.trim().length < 3) {
                              return 'Name must be at least 3 characters / نام کم از کم 3 حروف کا ہونا چاہیے';
                            }
                            if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
                              return 'Name must contain only letters / نام میں صرف حروف ہونے چاہئیں';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required / ای میل ضروری ہے';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                              return 'Please enter a valid email address / درست ای میل درج کریں';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            hintText: 'Enter your phone number',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Phone Number is required / فون نمبر ضروری ہے';
                            }
                            final phone = value.trim();
                            final pakPhoneRegex = RegExp(r'^((\+92)?(92)?(0)?)(3\d{9})$');
                            if (!pakPhoneRegex.hasMatch(phone)) {
                              return 'Please enter a valid Pakistani mobile number / درست فون نمبر درج کریں';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Create a password',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: AppTheme.textSecondary.withOpacity(0.6),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required / پاس ورڈ ضروری ہے';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters / پاس ورڈ کم از کم 8 حروف کا ہونا چاہیے';
                            }
                            if (!RegExp(r'[A-Z]').hasMatch(value)) {
                              return 'Must contain at least 1 uppercase letter / کم از کم ایک بڑا حرف ہونا چاہیے';
                            }
                            if (!RegExp(r'[a-z]').hasMatch(value)) {
                              return 'Must contain at least 1 lowercase letter / کم از کم ایک چھوٹا حرف ہونا چاہیے';
                            }
                            if (!RegExp(r'[0-9]').hasMatch(value)) {
                              return 'Must contain at least 1 number / کم از کم ایک ہندسہ ہونا چاہیے';
                            }
                            if (!RegExp(r'[!@#\$&*~%]').hasMatch(value)) {
                              return 'Must contain at least 1 special character (!@#\$&*~%)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignup,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text('Sign Up'),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Link to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account?',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      TextButton(
                        onPressed: () {
                          context.pushReplacement('/login', extra: {'role': widget.role});
                        },
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Privacy Context
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.5),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
