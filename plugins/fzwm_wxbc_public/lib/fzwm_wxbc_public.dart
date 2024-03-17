
import 'dart:async';

import 'package:flutter/services.dart';

class FzwmWxbcPublic {
  static const MethodChannel _channel =
  const MethodChannel('fzwm_wxbc_public');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
  static Future<String> arouseAbc(val) async {
    final arouseAbcResult = await _channel.invokeMethod<String>('arouseAbc',val);
    return arouseAbcResult;
  }
}
