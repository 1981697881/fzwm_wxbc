import 'package:shared_preferences/shared_preferences.dart';

class API {
  Future<String> LOGIN_URL() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString('url') + '/galaxyapi/Kingdee.BOS.WebApi.ServicesStub.AuthService.ValidateUser.common.kdsvc';
  }
 /* String LOGIN_URL() {
    return sharedPreferences.getString('url') + '/galaxyapi/Kingdee.BOS.WebApi.ServicesStub.AuthService.ValidateUser.common.kdsvc';
  }*/
//通用查询
  Future<String> CURRENCY_URL() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString('url') + '/galaxyapi/Kingdee.BOS.WebApi.ServicesStub.DynamicFormService.ExecuteBillQuery.common.kdsvc';
  }

  //提交
  Future<String> SAVE_URL() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString('url') + '/galaxyapi/Kingdee.BOS.WebApi.ServicesStub.DynamicFormService.Save.common.kdsvc';
  }

  //保存
  Future<String> SUBMIT_URL() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString('url') + '/galaxyapi/Kingdee.BOS.WebApi.ServicesStub.DynamicFormService.Submit.common.kdsvc';
  }

//下推
  Future<String> DOWN_URL() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString('url') + '/galaxyapi/Kingdee.BOS.WebApi.ServicesStub.DynamicFormService.Push.common.kdsvc';
  }

//审核
  Future<String> AUDIT_URL() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString('url') + '/galaxyapi/Kingdee.BOS.WebApi.ServicesStub.DynamicFormService.Audit.common.kdsvc';
  }

//反审核
  Future<String> UNAUDIT_URL() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString('url') + '/galaxyapi/Kingdee.BOS.WebApi.ServicesStub.DynamicFormService.UnAudit.common.kdsvc';
  }

//删除
  Future<String> DELETE_URL() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString('url') + '/galaxyapi/Kingdee.BOS.WebApi.ServicesStub.DynamicFormService.Delete.common.kdsvc';
  }

//修改状态
  Future<String> STATUS_URL() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString('url') + '/galaxyapi/Kingdee.BOS.WebApi.ServicesStub.DynamicFormService.ExcuteOperation.common.kdsvc';
  }

  /* static const String LOGIN_URL = API_PREFIX + '/Kingdee.BOS.WebApi.ServicesStub.AuthService.ValidateUser.common.kdsvc';
  //通用查询
  static const String CURRENCY_URL = API_PREFIX + '/Kingdee.BOS.WebApi.ServicesStub.DynamicFormService.ExecuteBillQuery.common.kdsvc';
  //提交
  static const String SAVE_URL = API_PREFIX + '/Kingdee.BOS.WebApi.ServicesStub.DynamicFormService.Save.common.kdsvc';
  //保存
  static const String SUBMIT_URL = API_PREFIX + '/Kingdee.BOS.WebApi.ServicesStub.DynamicFormService.Submit.common.kdsvc';
  //下推
  static const String DOWN_URL = API_PREFIX + '/Kingdee.BOS.WebApi.ServicesStub.DynamicFormService.Push.common.kdsvc';
  //审核
  static const String AUDIT_URL = API_PREFIX + '/Kingdee.BOS.WebApi.ServicesStub.DynamicFormService.Audit.common.kdsvc';
  //反审核
  static const String UNAUDIT_URL = API_PREFIX + '/Kingdee.BOS.WebApi.ServicesStub.DynamicFormService.UnAudit.common.kdsvc';
  //删除
  static const String DELETE_URL = API_PREFIX + '/Kingdee.BOS.WebApi.ServicesStub.DynamicFormService.Delete.common.kdsvc';
  //修改状态
  static const String STATUS_URL = API_PREFIX + '/Kingdee.BOS.WebApi.ServicesStub.DynamicFormService.ExcuteOperation.common.kdsvc';*/
  //版本查询
  static const String VERSION_URL =
      'https://www.pgyer.com/apiv2/app/check?_api_key=dd6926b00c3c3f22a0ee4204f8aaad88&appKey=ef0c698e399e901fae15cd8f6970ae53';
  //授权查询 authorize
  static const String AUTHORIZE_URL =
      'http://auth.gzfzdev.com:50022/web/auth/findAuthMessage';
}
