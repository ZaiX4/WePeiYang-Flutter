// @dart = 2.12

import 'package:flutter/services.dart';

class LocalSetting {
  static const _channel = MethodChannel("com.twt.service/local_setting");

  static Future<void> changeBrightness(double brightness) async {
    await _channel.invokeMethod("changeWindowBrightness", {'brightness' : brightness});;
  }

  static Future<void> changeSecurity(bool enable) async {
    await _channel.invokeMethod("changeWindowSecure", {'isSecure' : enable});;
  }
}