import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/time_formatter.dart';

class OfflineBanner extends StatelessWidget {
  final DateTime lastSyncedAt;

  const OfflineBanner({
    super.key,
    required this.lastSyncedAt,
  });

  @override
  Widget build(BuildContext context) {
    final relativeTime = TimeFormatter.formatRelativeTime(lastSyncedAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.warningAmberLight,
        border: Border(
          left: BorderSide(
            color: AppColors.warningAmberBorder,
            width: 4,
          ),
        ),
      ),
      child: Text(
        'Offline — showing the copy saved on this device. Last synced $relativeTime.',
        style: const TextStyle(
          color: Color(0xFF92400E),
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
      ),
    );
  }
}
