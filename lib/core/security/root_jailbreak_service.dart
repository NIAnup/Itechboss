import 'package:flutter/foundation.dart';
import 'package:safe_device/safe_device.dart';

class RootJailbreakService {
  /// Checks if the device is rooted or jailbroken
  Future<bool> isDeviceCompromised() async {
    // In debug mode or desktop/web platforms, allow execution
    if (kDebugMode ||
        (!kIsWeb &&
            defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return false;
    }

    try {
      final bool isJailbroken = await SafeDevice.isJailBroken;
      final bool isDevelopmentMode = await SafeDevice.isDevelopmentModeEnable;
      return isJailbroken || isDevelopmentMode;
    } catch (e) {
      return false;
    }
  }
}
