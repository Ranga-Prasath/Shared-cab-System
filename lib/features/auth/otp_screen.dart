// -- Shared Cab System --
// OTP Verification Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_cab/core/constants/app_constants.dart';
import 'package:shared_cab/core/router/app_routes.dart';
import 'package:shared_cab/core/theme/app_colors.dart';
import 'package:shared_cab/core/utils/security_utils.dart';
import 'package:shared_cab/providers/app_providers.dart';
import 'package:shared_cab/data/mock/mock_data.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isVerifying = false;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;
  String? _errorText;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all 4 digits entered
    if (_isVerifying) return;
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 4) {
      _verifyOtp(otp);
    }
  }

  Future<void> _verifyOtp(String otp) async {
    if (_isVerifying) return;
    final lock = _lockedUntil;
    if (lock != null && DateTime.now().isBefore(lock)) {
      final seconds = lock.difference(DateTime.now()).inSeconds.clamp(1, 999);
      setState(
        () => _errorText = 'Too many attempts. Try again in ${seconds}s',
      );
      return;
    }

    if (!SecurityUtils.isValidOtpFormat(otp)) {
      setState(() => _errorText = 'Enter a valid 4-digit OTP');
      return;
    }

    setState(() => _isVerifying = true);

    // Simulate verification delay
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    if (otp != AppConstants.demoOtp) {
      _failedAttempts += 1;
      if (_failedAttempts >= AppConstants.maxOtpAttempts) {
        _lockedUntil = DateTime.now().add(
          const Duration(seconds: AppConstants.otpLockDurationSeconds),
        );
        _failedAttempts = 0;
      }
      setState(() {
        _isVerifying = false;
        _errorText = 'Incorrect OTP. Please try again.';
      });
      return;
    }

    _failedAttempts = 0;
    _lockedUntil = null;
    setLoggedIn(ref, MockData.demoUser);
    context.goNamed(AppRoutes.homeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.goNamed(AppRoutes.loginName),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              const Icon(
                Icons.message_rounded,
                size: 48,
                color: AppColors.primary,
              ).animate().fadeIn().scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1, 1),
                curve: Curves.elasticOut,
              ),

              const SizedBox(height: 24),

              Text(
                'Verify your number',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 8),

              Text(
                'We sent a 4-digit code to\n${widget.phoneNumber}',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 40),

              // OTP input boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: TextFormField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: Theme.of(context).textTheme.headlineSmall,
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) => _onDigitEntered(index, value),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: (400 + index * 100).ms)
                      .slideY(begin: 0.5, end: 0);
                }),
              ),

              const SizedBox(height: 32),
              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorText!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),

              if (_isVerifying)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 12),
                      Text('Verifying...'),
                    ],
                  ),
                ).animate().fadeIn(),

              const Spacer(),

              // Demo hint
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.info),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Demo Mode: Use OTP ${AppConstants.demoOtp}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}
