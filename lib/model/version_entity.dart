import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fzwm_wxbc/http/api_response.dart';
import 'package:fzwm_wxbc/http/httpUtils.dart';
import 'package:fzwm_wxbc/server/api.dart';

VersionEntity versionEntityFromJson(String str) => VersionEntity.fromJson(json.decode(str));

String versionEntityToJson(VersionEntity data) => json.encode(data.toJson());

class VersionEntity {
  static Future<ApiResponse<VersionEntity>> getVersion(
      ) async {
    try {
      final response = await HttpUtils.post(API.VERSION_URL);
      final res = new Map<String, dynamic>.from(response);
      var data = VersionEntity.fromJson(res);
      return ApiResponse.completed(data);
    } on DioError catch (e) {
      return ApiResponse.error(e.error);
    }
  }
  VersionEntity({
    required this.code,
    required this.message,
    required this.data,
  });

  int code;
  String message;
  Data data;

  factory VersionEntity.fromJson(Map<String, dynamic> json) => VersionEntity(
    code: json["code"],
    message: json["message"],
    data: Data.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "code": code,
    "message": message,
    "data": data.toJson(),
  };
}

class Data {
  Data({
    required this.buildBuildVersion,
    required this.forceUpdateVersion,
    required this.forceUpdateVersionNo,
    required this.needForceUpdate,
    required this.downloadUrl,
    required this.buildHaveNewVersion,
    required this.buildVersionNo,
    required this.buildVersion,
    required this.buildUpdateDescription,
    required this.appKey,
    required this.buildKey,
    required this.buildName,
    required this.buildIcon,
    required this.buildFileKey,
    required this.buildFileSize,
  });

  String buildBuildVersion;
  String forceUpdateVersion;
  String forceUpdateVersionNo;
  bool needForceUpdate;
  String downloadUrl;
  bool buildHaveNewVersion;
  String buildVersionNo;
  String buildVersion;
  String buildUpdateDescription;
  String appKey;
  String buildKey;
  String buildName;
  String buildIcon;
  String buildFileKey;
  String buildFileSize;

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    buildBuildVersion: json["buildBuildVersion"],
    forceUpdateVersion: json["forceUpdateVersion"],
    forceUpdateVersionNo: json["forceUpdateVersionNo"],
    needForceUpdate: json["needForceUpdate"],
    downloadUrl: json["downloadURL"],
    buildHaveNewVersion: json["buildHaveNewVersion"],
    buildVersionNo: json["buildVersionNo"],
    buildVersion: json["buildVersion"],
    buildUpdateDescription: json["buildUpdateDescription"],
    appKey: json["appKey"],
    buildKey: json["buildKey"],
    buildName: json["buildName"],
    buildIcon: json["buildIcon"],
    buildFileKey: json["buildFileKey"],
    buildFileSize: json["buildFileSize"],
  );

  Map<String, dynamic> toJson() => {
    "buildBuildVersion": buildBuildVersion,
    "forceUpdateVersion": forceUpdateVersion,
    "forceUpdateVersionNo": forceUpdateVersionNo,
    "needForceUpdate": needForceUpdate,
    "downloadURL": downloadUrl,
    "buildHaveNewVersion": buildHaveNewVersion,
    "buildVersionNo": buildVersionNo,
    "buildVersion": buildVersion,
    "buildUpdateDescription": buildUpdateDescription,
    "appKey": appKey,
    "buildKey": buildKey,
    "buildName": buildName,
    "buildIcon": buildIcon,
    "buildFileKey": buildFileKey,
    "buildFileSize": buildFileSize,
  };
}
