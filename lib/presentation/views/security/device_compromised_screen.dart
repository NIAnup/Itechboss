import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class DeviceCompromisedScreen extends StatelessWidget {
  const DeviceCompromisedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.errorRed, width: 2),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.gpp_bad_outlined,
                  size: 44,
                  color: AppColors.errorRed,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Security Alert',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'VAULT cannot run on this device because a root or jailbreak environment was detected.\n\nTo safeguard your encrypted credentials and personal data, access has been restricted.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  color: AppColors.textSecondaryDark,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
