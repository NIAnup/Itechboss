import 'package:equatable/equatable.dart';

enum PinFlowMode { create, change, unlock }

class PinState extends Equatable {
  final PinFlowMode flowMode;
  final int step; // 1: enter new PIN, 2: confirm new PIN (or 0: verify old PIN for change)
  final String currentInput;
  final String firstPinInput;
  final bool hasError;
  final String? errorMessage;
  final int remainingAttempts;
  final bool isCompleted;
  final bool isUnlocked;
  final bool isLockedOut;

  const PinState({
    this.flowMode = PinFlowMode.create,
    this.step = 1,
    this.currentInput = '',
    this.firstPinInput = '',
    this.hasError = false,
    this.errorMessage,
    this.remainingAttempts = 3,
    this.isCompleted = false,
    this.isUnlocked = false,
    this.isLockedOut = false,
  });

  PinState copyWith({
    PinFlowMode? flowMode,
    int? step,
    String? currentInput,
    String? firstPinInput,
    bool? hasError,
    String? errorMessage,
    int? remainingAttempts,
    bool? isCompleted,
    bool? isUnlocked,
    bool? isLockedOut,
  }) {
    return PinState(
      flowMode: flowMode ?? this.flowMode,
      step: step ?? this.step,
      currentInput: currentInput ?? this.currentInput,
      firstPinInput: firstPinInput ?? this.firstPinInput,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage,
      remainingAttempts: remainingAttempts ?? this.remainingAttempts,
      isCompleted: isCompleted ?? this.isCompleted,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isLockedOut: isLockedOut ?? this.isLockedOut,
    );
  }

  @override
  List<Object?> get props => [
        flowMode,
        step,
        currentInput,
        firstPinInput,
        hasError,
        errorMessage,
        remainingAttempts,
        isCompleted,
        isUnlocked,
        isLockedOut,
      ];
}
