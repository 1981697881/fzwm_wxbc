/// 全局配置
class Global {
  /// token
  static String accessToken = "";
  static bool retryEnable = true;
  static String acctID = "668023e3646f14";
  static String appID = "282887_3+fPTYsozmn479TF1e7Ay8/NUh4c6skL";
  static String appSec = "0eba0d99c8364d2cbb1b44e088e62cbd";
  static String userName = "����";
  static String lCID = "2052";
  static String serverUrl = "http://bj1-api.kingdee.com/galaxyapi/";
  /// 是否 release
  static bool get isRelease => bool.fromEnvironment("dart.vm.product");
}
