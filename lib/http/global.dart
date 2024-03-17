/// 全局配置
class Global {
  /// token
  static String accessToken = "";
  static bool retryEnable = true;
  static String acctID = "1679746250007654400";
  static String appID = "271755_7/cuR9Cp3MDeReVE050r7xTEUgTUXqKo";
  static String appSec = "56f9937cdc6542f3bb9115fa1ba26ed4";
  static String userName = "����";
  static String lCID = "2052";
  static String serverUrl = "http://bj1-api.kingdee.com/galaxyapi/";
  /// 是否 release
  static bool get isRelease => bool.fromEnvironment("dart.vm.product");
}
