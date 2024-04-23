/// 全局配置
class Global {
  /// token
  static String accessToken = "";
  static bool retryEnable = true;
  static String acctID = "1679743996173322240";
  static String appID = "276231_T1aBX+hFUMhU0f1P7Z2D4yTu2MwV3qmG";
  static String appSec = "d7673a64a2e648cf8faa6b5912aedc1d";
  static String userName = "����";
  static String lCID = "2052";
  static String serverUrl = "http://bj1-api.kingdee.com/galaxyapi/";
  /// 是否 release
  static bool get isRelease => bool.fromEnvironment("dart.vm.product");
}
