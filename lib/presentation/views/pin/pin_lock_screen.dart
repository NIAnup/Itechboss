import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/encrypted_file_datasource.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../viewmodels/pin/pin_cubit.dart';
import '../../viewmodels/pin/pin_state.dart';
import '../../widgets/numeric_keypad.dart';
import '../../widgets/pin_dots_indicator.dart';

class PinLockScreen extends StatefulWidget {
  final VoidCallback? onUnlocked;

  const PinLockScreen({
    super.key,
    this.onUnlocked,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _firstName = 'User';

  @override
  void initState() {
    super.initState();
    context.read<PinCubit>().initFlow(PinFlowMode.unlock);
    _loadUserGreeting();
  }

  Future<void> _loadUserGreeting() async {
    final cached = await context.read<EncryptedFileDataSource>().readProfileCache();
    if (cached != null && cached.user.firstName.isNotEmpty && mounted) {
      setState(() {
        _firstName = cached.user.firstName;
      });
    }
  }

  Future<void> _onLogoutInstead() async {
    await context.read<AuthRepository>().logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false, // Prevent back navigation while locked
      child: BlocConsumer<PinCubit, PinState>(
        listener: (context, state) {
          if (state.isUnlocked) {
            if (widget.onUnlocked != null) {
              widget.onUnlocked!();
            } else {
              Navigator.of(context).pushReplacementNamed('/profile');
            }
          } else if (state.isLockedOut) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('3 failed PIN attempts. Forced logout initiated.'),
                backgroundColor: AppColors.errorRed,
              ),
            );
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 48),
                          // Top Lock Icon Container
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F9FF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE0F2FE),
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.lock_outline,
                              size: 32,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Title
                          Text(
                            'Enter your PIN',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Greeting
                          Text(
                            'Welcome back, $_firstName',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 36),

                          // 6 PIN Dots Indicator
                          PinDotsIndicator(
                            pinLength: 6,
                            currentLength: state.currentInput.length,
                            hasError: state.hasError,
                          ),

                          const SizedBox(height: 18),

                          // Error / Remaining Attempts text
                          if (state.hasError && state.errorMessage != null)
                            Text(
                              state.errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.errorRed,
                              ),
                            )
                          else
                            const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),

                  // Custom Numeric Keypad
                  NumericKeypad(
                    onNumberPressed: (number) {
                      context.read<PinCubit>().appendDigit(number);
                    },
                    onBackspacePressed: () {
                      context.read<PinCubit>().deleteDigit();
                    },
                  ),

                  const SizedBox(height: 12),

                  // Logout Instead Button
                  TextButton(
                    onPressed: _onLogoutInstead,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0369A1),
                    ),
                    child: const Text(
                      'Log out instead',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
