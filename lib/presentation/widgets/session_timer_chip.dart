import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SessionTimerChip extends StatefulWidget {
  final DateTime sessionStartTime;
  final int totalDurationSeconds;

  const SessionTimerChip({
    super.key,
    required this.sessionStartTime,
    this.totalDurationSeconds = 60, // 1 minute expiry as mandated
  });

  @override
  State<SessionTimerChip> createState() => _SessionTimerChipState();
}

class _SessionTimerChipState extends State<SessionTimerChip> {
  Timer? _timer;
  int _secondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateRemaining();
    });
  }

  @override
  void didUpdateWidget(covariant SessionTimerChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionStartTime != widget.sessionStartTime) {
      _calculateRemaining();
    }
  }

  void _calculateRemaining() {
    final elapsed = DateTime.now().difference(widget.sessionStartTime).inSeconds;
    final remaining = widget.totalDurationSeconds - elapsed;
    if (mounted) {
      setState(() {
        _secondsRemaining = remaining > 0 ? remaining : 0;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.successGreenLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.successGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Session active · renews in ${_secondsRemaining}s',
            style: const TextStyle(
              color: AppColors.successGreen,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
