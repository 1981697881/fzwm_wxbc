// To parse this JSON data, do
//     final authorizeEntity = authorizeEntityFromJson(jsonString);
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:fzwm_wxbc/http/api_response.dart';
import 'package:fzwm_wxbc/http/httpUtils.dart';
import 'package:fzwm_wxbc/server/api.dart';

AuthorizeEntity authorizeEntityFromJson(String str) => AuthorizeEntity.fromJson(json.decode(str));

String authorizeEntityToJson(AuthorizeEntity data) => json.encode(data.toJson());

class AuthorizeEntity {
  static Future<ApiResponse<AuthorizeEntity>> getAuthorize(Map<String, dynamic> map
      ) async {
    try {
      final response = await HttpUtils.post(API.AUTHORIZE_URL,data: map);
      final res = new Map<String, dynamic>.from(response);
      var data = AuthorizeEntity.fromJson(res);
      return ApiResponse.completed(data);
    } on DioError catch (e) {
      return ApiResponse.error(e.error);
    }
  }
  AuthorizeEntity({
    required this.code,
    this.msg,
    required this.success,
    required this.data,
  });

  int code;
  dynamic msg;
  bool success;
  Data data;

  factory AuthorizeEntity.fromJson(Map<String, dynamic> json) => AuthorizeEntity(
    code: json["code"],
    msg: json["msg"],
    success: json["success"],
    data: Data.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "code": code,
    "msg": msg,
    "success": success,
    "data": data.toJson(),
  };
}

class Data {
  Data({
    required this.fid,
    required this.fTargetKey,
    required this.fSrvEDate,
    required this.fCustName,
    required this.fAuthList,
    required this.fAuthSDate,
    required this.furl,
    required this.fCode,
    required this.fPrjName,
    required this.fPrjNo,
    required this.fSrvPhone,
    required this.fAuthEDate,
    required this.fMessage,
    required this.fPrjType,
    required this.fAppSecret,
    required this.fAppkey,
    required this.fSrvSDate,
    required this.fSupplier,
    required this.fAuthNums,
    required this.fStatus,
    required this.fBarCodeList,
  });

  int fid;
  int fAuthNums;
  String fTargetKey;
  String fSrvEDate;
  String fCustName;
  String fAuthList;
  String fAuthSDate;
  String furl;
  String fCode;
  String fPrjName;
  String fPrjNo;
  String fSrvPhone;
  String fAuthEDate;
  String fMessage;
  String fPrjType;
  String fAppSecret;
  String fAppkey;
  String fSrvSDate;
  String fSupplier;
  String fStatus;
  int fBarCodeList;

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    fid: json["FID"],
    fTargetKey: json["FTargetKey"],
    fSrvEDate: json["FSrvEDate"],
    fCustName: json["FCustName"],
    fAuthList: json["FAuthList"],
    fAuthSDate: json["FAuthSDate"],
    furl: json["FURL"],
    fCode: json["FCode"],
    fPrjName: json["FPrjName"],
    fPrjNo: json["FPrjNo"],
    fSrvPhone: json["FSrvPhone"],
    fAuthEDate: json["FAuthEDate"],
    fMessage: json["FMessage"],
    fPrjType: json["FPrjType"],
    fAppSecret: json["FAppSecret"],
    fAppkey: json["FAppkey"],
    fSrvSDate: json["FSrvSDate"],
    fSupplier: json["FSupplier"],
    fStatus: json["FStatus"],
    fAuthNums: json["FAuthNums"],
    fBarCodeList: json["FBarCodeList"],
  );

  Map<String, dynamic> toJson() => {
    "FID": fid,
    "FTargetKey": fTargetKey,
    "FSrvEDate": fSrvEDate,
    "FCustName": fCustName,
    "FAuthList": fAuthList,
    "FAuthSDate": fAuthSDate,
    "FURL": furl,
    "FCode": fCode,
    "FPrjName": fPrjName,
    "FPrjNo": fPrjNo,
    "FSrvPhone": fSrvPhone,
    "FAuthEDate": fAuthEDate,
    "FMessage": fMessage,
    "FPrjType": fPrjType,
    "FAppSecret": fAppSecret,
    "FAppkey": fAppkey,
    "FSrvSDate": fSrvSDate,
    "FSupplier": fSupplier,
    "FStatus": fStatus,
    "FAuthNums": fAuthNums,
    "FBarCodeList": fBarCodeList,
  };
}
