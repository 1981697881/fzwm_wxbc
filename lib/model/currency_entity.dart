import 'dart:convert';
import 'package:fzwm_wxbc/server/api.dart';
import 'package:dio/dio.dart';
import 'package:fzwm_wxbc/http/httpUtils.dart';
List<List<dynamic>> currencyEntityFromJson(String str) => List<List<dynamic>>.from(json.decode(str).map((x) => List<dynamic>.from(x.map((x) => x))));

String currencyEntityToJson(List<List<dynamic>> data) => json.encode(List<dynamic>.from(data.map((x) => List<dynamic>.from(x.map((x) => x)))));

class CurrencyEntity {
  static Future<String> polling(
      Map<String, dynamic> map) async {
    try {
      API api = new API();
      final response = await HttpUtils.post(await api.CURRENCY_URL(), data: map);
      return response;
    } on DioError catch (e) {
      return e.error;
    }
  }
}