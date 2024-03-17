import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fzwm_wxbc/model/submit_entity.dart';
import 'package:fzwm_wxbc/utils/toast_util.dart';

class HandlerOrder {
  static Future<bool> orderHandler(BuildContext context,Map<String, dynamic> map, type, formid, fun,
      {String? title}) async {
    var subData = await fun;
    var res = jsonDecode(subData);
    if (res != null) {
      if (res['Result']['ResponseStatus']['IsSuccess']) {
        //判断反审
        if (type == 0) {
          orderDelete(context,map, title);
          return false;
        } else {
          return true;
        }
      } else {
        if(type==3){
          ToastUtil.errorDialog(context,
              res['Result']['ResponseStatus']['Errors'][0]['Message']);
        }else{
          orderDelete(context,
              map, res['Result']['ResponseStatus']['Errors'][0]['Message']);
        }
        return false;
      }
    }else{
      return false;
    }
  }
  // 订单删除
  // ignore: missing_return
  static void orderDelete(BuildContext context,Map<String, dynamic> map, title) async {
    if(title==null){
      title = "";
    }
    var subData = await SubmitEntity.delete(map);
    var res = jsonDecode(subData);
    if (res != null) {
      if (res['Result']['ResponseStatus']['IsSuccess']) {
        ToastUtil.errorDialog(context,
            title);
      } else {
        ToastUtil.errorDialog(context,
            "保存反馈："+title+"、删除反馈："+res['Result']['ResponseStatus']['Errors'][0]['Message']);
      }
    }
  }
}
