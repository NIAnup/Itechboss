import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PinDotsIndicator extends StatefulWidget {
  final int pinLength;
  final int currentLength;
  final bool hasError;

  const PinDotsIndicator({
    super.key,
    this.pinLength = 6,
    required this.currentLength,
    this.hasError = false,
  });

  @override
  State<PinDotsIndicator> createState() => _PinDotsIndicatorState();
}

class _PinDotsIndicatorState extends State<PinDotsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(covariant PinDotsIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && (!oldWidget.hasError || widget.currentLength == 0)) {
      _shakeController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.pinLength, (index) {
          final isFilled = index < widget.currentLength;
          final isFocused = index == widget.currentLength;

          Color borderColor;
          if (widget.hasError) {
            borderColor = AppColors.errorRed;
          } else if (isFilled) {
            borderColor = isDark ? Colors.white : AppColors.primaryNavy;
          } else if (isFocused) {
            borderColor = isDark ? AppColors.textSecondaryDark : AppColors.primaryNavy;
          } else {
            borderColor = isDark ? AppColors.cardBorderDark : AppColors.pinBoxBorder;
          }

          return Container(
            width: 44,
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: isFilled || isFocused || widget.hasError ? 1.8 : 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: isFilled
                ? Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: widget.hasError
                          ? AppColors.errorRed
                          : (isDark ? Colors.white : AppColors.primaryNavy),
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          );
        }),
      ),
    );
  }
}
