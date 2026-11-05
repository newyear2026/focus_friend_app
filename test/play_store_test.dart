import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/play_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('focus_friend/store');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('opens each curated listing with only its package ID', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    for (final package in [
      'com.dayround.app',
      'com.sobra.app.sobra_app',
      'com.randomfocus.app',
      'com.casewen.multi_calc',
    ]) {
      expect(await openPlayListing(package), isTrue);
      expect(calls.last.method, 'openListing');
      expect(calls.last.arguments, {'packageName': package});
    }
    expect(calls, hasLength(4));
  });

  test(
    'rejects other packages and URL injection without calling Android',
    () async {
      var calls = 0;
      messenger.setMockMethodCallHandler(channel, (_) async {
        calls++;
        return true;
      });
      for (final package in [
        '',
        'dev.jaewook.deskmate',
        'com.dayround.app.attacker',
        'com.dayround.app&referrer=tracking',
        'https://play.google.com/store/apps/details?id=com.dayround.app',
        'com.dayround.app ',
        'COM.DAYROUND.APP',
      ]) {
        expect(await openPlayListing(package), isFalse);
      }
      expect(calls, 0);
    },
  );

  test('unsuccessful and malformed native replies return false', () async {
    for (final reply in <Object?>[
      false,
      null,
      'true',
      1,
      {'opened': true},
    ]) {
      messenger.setMockMethodCallHandler(channel, (_) async => reply);
      expect(await openPlayListing('com.dayround.app'), isFalse);
    }
  });

  test('native errors return false for localized UI recovery', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'ACTIVITY_UNAVAILABLE');
    });
    expect(await openPlayListing('com.randomfocus.app'), isFalse);
  });

  test('an unavailable plugin returns false instead of throwing', () async {
    messenger.setMockMethodCallHandler(channel, null);
    expect(await openPlayListing('com.casewen.multi_calc'), isFalse);
  });

  test('other platforms do not attempt the Android channel', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (_) async {
      calls++;
      return true;
    });
    for (final platform in [
      TargetPlatform.iOS,
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.fuchsia,
    ]) {
      debugDefaultTargetPlatformOverride = platform;
      expect(await openPlayListing('com.sobra.app.sobra_app'), isFalse);
    }
    expect(calls, 0);
  });
}
