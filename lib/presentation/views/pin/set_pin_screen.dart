import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../viewmodels/pin/pin_cubit.dart';
import '../../viewmodels/pin/pin_state.dart';
import '../../widgets/numeric_keypad.dart';
import '../../widgets/pin_dots_indicator.dart';

class SetPinScreen extends StatefulWidget {
  final PinFlowMode flowMode;

  const SetPinScreen({
    super.key,
    this.flowMode = PinFlowMode.create,
  });

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PinCubit>().initFlow(widget.flowMode);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<PinCubit, PinState>(
      listener: (context, state) {
        if (state.isCompleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('App lock PIN set successfully!'),
              backgroundColor: AppColors.successGreen,
            ),
          );
          Navigator.of(context).pop();
        } else if (state.isLockedOut) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      },
      builder: (context, state) {
        String title = 'Create app lock PIN';
        String subtitle =
            'Choose a 6-digit PIN. You will need it each\ntime you reopen the app.';
        String stepText = 'Step 1 of 2 - you will confirm it next.';

        if (state.flowMode == PinFlowMode.change) {
          title = 'Change app lock PIN';
          if (state.step == 0) {
            stepText = 'Enter your current PIN to continue.';
          } else if (state.step == 1) {
            stepText = 'Step 1 of 2 - enter your new PIN.';
          } else {
            stepText = 'Step 2 of 2 - re-enter your new PIN to confirm.';
          }
        } else {
          if (state.step == 2) {
            stepText = 'Step 2 of 2 - re-enter your PIN to confirm.';
          }
        }

        return Scaffold(
          backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // 6 Pin Boxes Indicator
                        PinDotsIndicator(
                          pinLength: 6,
                          currentLength: state.currentInput.length,
                          hasError: state.hasError,
                        ),

                        const SizedBox(height: 20),

                        // Step Status or Error message
                        if (state.hasError && state.errorMessage != null)
                          Text(
                            state.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.errorRed,
                            ),
                          )
                        else
                          Text(
                            stepText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Custom On-Screen Keypad
                NumericKeypad(
                  onNumberPressed: (number) {
                    context.read<PinCubit>().appendDigit(number);
                  },
                  onBackspacePressed: () {
                    context.read<PinCubit>().deleteDigit();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
