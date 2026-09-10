import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/pin_repository.dart';
import 'pin_state.dart';

class PinCubit extends Cubit<PinState> {
  final PinRepository _pinRepository;
  bool _isProcessing = false;

  PinCubit(this._pinRepository) : super(const PinState());

  Future<void> initFlow(PinFlowMode mode) async {
    _isProcessing = false;
    final remaining = await _pinRepository.getRemainingAttempts();
    emit(PinState(
      flowMode: mode,
      step: mode == PinFlowMode.change ? 0 : 1,
      currentInput: '',
      firstPinInput: '',
      hasError: false,
      errorMessage: null,
      remainingAttempts: remaining,
      isCompleted: false,
      isUnlocked: false,
      isLockedOut: false,
    ));
  }

  void appendDigit(String digit) {
    if (state.currentInput.length >= 6 || state.isLockedOut || _isProcessing) return;

    final newInput = state.currentInput + digit;
    emit(state.copyWith(
      currentInput: newInput,
      hasError: false,
      errorMessage: null,
    ));

    if (newInput.length == 6) {
      _isProcessing = true;
      _processCompleteInput(newInput).then((_) {
        _isProcessing = false;
      });
    }
  }

  void deleteDigit() {
    if (state.currentInput.isEmpty || state.isLockedOut || _isProcessing) return;

    final newInput = state.currentInput.substring(0, state.currentInput.length - 1);
    emit(state.copyWith(
      currentInput: newInput,
      hasError: false,
      errorMessage: null,
    ));
  }

  Future<void> _processCompleteInput(String input) async {
    // Smooth delay so the 6th filled dot is rendered before transitioning
    await Future.delayed(const Duration(milliseconds: 150));

    if (state.flowMode == PinFlowMode.unlock) {
      final result = await _pinRepository.verifyPin(input);
      if (result == PinVerificationResult.success) {
        emit(state.copyWith(isUnlocked: true));
      } else if (result == PinVerificationResult.lockedOut) {
        emit(state.copyWith(
          currentInput: '',
          hasError: true,
          isLockedOut: true,
          remainingAttempts: 0,
          errorMessage: 'Too many incorrect attempts. Session terminated.',
        ));
      } else {
        final remaining = await _pinRepository.getRemainingAttempts();
        final attemptsText = remaining == 1 ? '1 attempt left' : '$remaining attempts left';
        emit(state.copyWith(
          currentInput: '',
          hasError: true,
          remainingAttempts: remaining,
          errorMessage: 'Incorrect PIN — $attemptsText',
        ));
      }
    } else if (state.flowMode == PinFlowMode.change && state.step == 0) {
      // Verifying old PIN
      final result = await _pinRepository.verifyPin(input);
      if (result == PinVerificationResult.success) {
        emit(state.copyWith(
          step: 1,
          currentInput: '',
          firstPinInput: '',
          hasError: false,
          errorMessage: null,
        ));
      } else if (result == PinVerificationResult.lockedOut) {
        emit(state.copyWith(
          currentInput: '',
          hasError: true,
          isLockedOut: true,
          remainingAttempts: 0,
          errorMessage: 'Too many incorrect attempts. Session terminated.',
        ));
      } else {
        final remaining = await _pinRepository.getRemainingAttempts();
        emit(state.copyWith(
          currentInput: '',
          hasError: true,
          remainingAttempts: remaining,
          errorMessage: 'Incorrect current PIN. Try again.',
        ));
      }
    } else if (state.step == 1) {
      // Step 1: Record first PIN entry and proceed to Step 2 confirmation
      emit(state.copyWith(
        step: 2,
        firstPinInput: input,
        currentInput: '',
        hasError: false,
        errorMessage: null,
      ));
    } else if (state.step == 2) {
      // Step 2: Confirm PIN
      if (input == state.firstPinInput) {
        await _pinRepository.savePin(input);
        emit(state.copyWith(isCompleted: true));
      } else {
        emit(state.copyWith(
          step: 1,
          firstPinInput: '',
          currentInput: '',
          hasError: true,
          errorMessage: 'PINs do not match. Try again.',
        ));
      }
    }
  }

  Future<void> removePin() async {
    await _pinRepository.clearPin();
  }
}
