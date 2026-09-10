import 'package:flutter/foundation.dart';

class ScreenPrivacyService {
  /// Enables anti-screenshot and screen privacy protection
  /// Native Android is enforced directly via FLAG_SECURE on the Window in MainActivity.kt
  Future<void> enableProtection() async {
    debugPrint('Screen privacy protection active (FLAG_SECURE)');
  }

  /// Disables protection if needed
  Future<void> disableProtection() async {
    debugPrint('Screen privacy protection disabled');
  }
}
