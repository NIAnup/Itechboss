enum PinVerificationResult {
  success,
  incorrect,
  lockedOut,
}

abstract class PinRepository {
  Future<bool> isPinSet();
  Future<void> savePin(String pin);
  Future<PinVerificationResult> verifyPin(String pin);
  Future<int> getRemainingAttempts();
  Future<void> clearPin();
  Future<void> resetAttempts();
}
