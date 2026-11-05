import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _storeChannel = MethodChannel('focus_friend/store');
const _recommendedPackages = {
  'com.dayround.app',
  'com.sobra.app.sobra_app',
  'com.randomfocus.app',
  'com.casewen.multi_calc',
};

/// Opens a recommended app's listing in Google Play, with a web fallback.
///
/// This only opens the listing; installation remains the user's choice.
/// A false result lets the caller offer localized, retryable feedback.
Future<bool> openPlayListing(String packageName) async {
  if (kIsWeb ||
      defaultTargetPlatform != TargetPlatform.android ||
      !_recommendedPackages.contains(packageName)) {
    return false;
  }
  try {
    return await _storeChannel.invokeMethod<Object?>('openListing', {
          'packageName': packageName,
        }) ==
        true;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  }
}
