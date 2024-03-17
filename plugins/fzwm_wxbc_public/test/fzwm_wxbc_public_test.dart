import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/fzwm_wxbc_public.dart';

void main() {
  const MethodChannel channel = MethodChannel('fzwm_wxbc_public');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await FzwmWxbcPublic.platformVersion, '42');
  });
}
