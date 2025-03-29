import 'dart:async';
import 'package:agora_poc/controllers/auth_controller.dart';
import 'package:agora_poc/home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
class OTPVerificationScreen extends StatefulWidget {
  final String email;

  const OTPVerificationScreen({super.key, required this.email});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  int _resendSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() {
          _resendSeconds--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  String _getOtpCode() {
    return _controllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyOtp() async {
    final otpCode = _getOtpCode();

    if (otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete 6-digit code')),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await authService.verifyOTP(widget.email, otpCode);

      if (success) {
        if (!mounted) return;

        // Clear all previous routes and go to home
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false, // Remove all previous routes
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid verification code')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Verification failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    if (_resendSeconds > 0) return;

    setState(() {
      _isResending = true;
    });

    try {
      // In a real app, you would call a resend OTP API
      // For demo, just wait and show a success message
      await Future.delayed(const Duration(seconds: 1));

      // Reset the input fields
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'A new verification code has been sent to ${widget.email}',
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );

      // Restart the timer
      _startResendTimer();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to resend code: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Verification'), elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top spacing
              const SizedBox(height: 20),

              // Icon
              Icon(
                Icons.verified_user_rounded,
                size: 70,
                color: theme.colorScheme.primary,
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'OTP Verification',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                'Please enter the 6-digit code sent to',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Email
              Text(
                widget.email,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children:
                    List.generate(
                      6,
                      (index) => SizedBox(
                        width: 45,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            }
                          },
                        ),
                      ),
                    ).toList(),
              ),

              const SizedBox(height: 40),

              // Verify Button
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                        : const Text('Verify & Proceed'),
              ),

              const SizedBox(height: 24),

              // Resend Option
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Didn\'t receive the code?',
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed:
                        _resendSeconds == 0 && !_isResending
                            ? _resendCode
                            : null,
                    child:
                        _isResending
                            ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Text(
                              _resendSeconds > 0
                                  ? 'Resend in $_resendSeconds s'
                                  : 'Resend Code',
                              style: TextStyle(
                                color:
                                    _resendSeconds > 0
                                        ? theme.colorScheme.primary.withOpacity(
                                          0.5,
                                        )
                                        : theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ],
              ),

              const Spacer(),

              // Demo hint
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Demo App Note',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'For this demo, use code "123456" to verify. In a real app, this would be sent to your email or phone.',
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
