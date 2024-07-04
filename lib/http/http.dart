import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:sprintf/sprintf.dart';
import 'proxy.dart';
import 'package:fzwm_wxbc_public/fzwm_wxbc_public.dart';

import 'cache.dart';
import 'error_interceptor.dart';
import 'global.dart';
import 'dart:convert' as convert;
class Http {
  ///超时时间
  static const int CONNECT_TIMEOUT = 30000;
  static const int RECEIVE_TIMEOUT = 30000;

  static Http _instance = Http._internal();
  factory Http() => _instance;

  late Dio dio;
  CancelToken _cancelToken = new CancelToken();

  Http._internal() {
   /* if (dio == null) {*/
      // BaseOptions、Options、RequestOptions 都可以配置参数，优先级别依次递增，且可以根据优先级别覆盖参数
      BaseOptions options = new BaseOptions(
        connectTimeout: CONNECT_TIMEOUT,

        // 响应流上前后两次接受到数据的间隔，单位为毫秒。
        receiveTimeout: RECEIVE_TIMEOUT,

        // Http请求头.
        headers: {

        },
      );

      dio = new Dio(options);
      // Cookie管理
      CookieJar cookieJar = CookieJar();
      dio.interceptors.add(CookieManager(cookieJar));
      // 加内存缓存

      // 添加error拦截器
      dio.interceptors
          .add(ErrorInterceptor());

      // 在调试模式下需要抓包调试，所以我们使用代理，并禁用HTTPS证书校验
      if (PROXY_ENABLE) {
        (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
            (client) {
          client.findProxy = (uri) {
            return "PROXY $PROXY_IP:$PROXY_PORT";
          };
          //代理工具会提供一个抓包的自签名证书，会通不过证书校验，所以我们禁用证书校验
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
        };
      }
    /*}*/
  }

  ///初始化公共属性
  ///
  /// [baseUrl] 地址前缀
  /// [connectTimeout] 连接超时赶时间
  /// [receiveTimeout] 接收超时赶时间
  /// [interceptors] 基础拦截器
  void init(
      {String ?baseUrl,
        int ?connectTimeout,
        int ?receiveTimeout,
        List<Interceptor> ?interceptors}) {
    dio.options = dio.options.merge(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
    );
    if (interceptors != null && interceptors.isNotEmpty) {
      dio.interceptors..addAll(interceptors);
    }
  }
  /// 设置headers
  void setHeaders(Map<String, dynamic> map) {
    dio.options.headers.addAll(map);
  }

  /*
   * 取消请求
   *
   * 同一个cancel token 可以用于多个请求，当一个cancel token取消时，所有使用该cancel token的请求都会被取消。
   * 所以参数可选
   */
  void cancelRequests({CancelToken ?token}) {
    token ?? _cancelToken.cancel("cancelled");
  }
  /// restful get 操作
  Future get(
      String path, {
        Map<String, dynamic> ?params,
        Options ?options,
        CancelToken ?cancelToken,
        bool refresh = false,
        bool noCache = !CACHE_ENABLE,
        String ?cacheKey,
        bool cacheDisk = false,
      }) async {
    Options requestOptions = options ?? Options();
    requestOptions = requestOptions.merge(extra: {
      "refresh": refresh,
      "noCache": noCache,
      "cacheKey": cacheKey,
      "cacheDisk": cacheDisk,
    });
    Map<String, dynamic> _authorization = getAuthorizationHeader();
    if (_authorization != null) {
      requestOptions = requestOptions.merge(headers: _authorization);
    }
    Response response;
    response = await dio.get(path,
        queryParameters: params,
        options: requestOptions,
        cancelToken: cancelToken ?? _cancelToken);
    return response.data;
  }

  /// restful post 操作
  Future post(
      String path, {
        Map<String, dynamic> ?params,
        data,
        Options ?options,
        CancelToken ?cancelToken,
      }) async {
    Options requestOptions = options ?? Options();
    /*Map<String, dynamic> kdWebApiHeader = await getKdWebApiHeader(path);
    if (kdWebApiHeader != null) {
      requestOptions = requestOptions.merge(headers: kdWebApiHeader);
    }*/
    var response = await dio.post(path,
        data: data,
        queryParameters: params,
        options: requestOptions,
        cancelToken: cancelToken ?? _cancelToken);
    return response.data;
  }
  /// restful dblPost 操作
  Future dblPost(
      String path1, String path2, {
        Map<String, dynamic> ?params,
        data1,
        data2,
        Options ?options,
        CancelToken ?cancelToken,
      }) async {
    Options requestOptions = options ?? Options();
    Map<String, dynamic> _authorization = getAuthorizationHeader();
    /* if (_authorization != null) {
      requestOptions = requestOptions.merge(headers: _authorization);
    }*/
    var response = await Future.wait([dio.post(path1,
        data: data1,
        queryParameters: params,
        options: requestOptions,
        cancelToken: cancelToken ?? _cancelToken), dio.post(path2,
        data: data2,
        queryParameters: params,
        options: requestOptions,
        cancelToken: cancelToken ?? _cancelToken)]);
    return response;
  }

  /// restful put 操作
  Future put(
      String path, {
        data,
        Map<String, dynamic> ?params,
        Options ?options,
        CancelToken ?cancelToken,
      }) async {
    Options requestOptions = options ?? Options();

    Map<String, dynamic> _authorization = getAuthorizationHeader();
    if (_authorization != null) {
      requestOptions = requestOptions.merge(headers: _authorization);
    }
    var response = await dio.put(path,
        data: data,
        queryParameters: params,
        options: requestOptions,
        cancelToken: cancelToken ?? _cancelToken);
    return response.data;
  }

  /// restful patch 操作
  Future patch(
      String path, {
        data,
        Map<String, dynamic> ?params,
        Options ?options,
        CancelToken ?cancelToken,
      }) async {
    Options requestOptions = options ?? Options();
    Map<String, dynamic> _authorization = getAuthorizationHeader();
    if (_authorization != null) {
      requestOptions = requestOptions.merge(headers: _authorization);
    }
    var response = await dio.patch(path,
        data: data,
        queryParameters: params,
        options: requestOptions,
        cancelToken: cancelToken ?? _cancelToken);
    return response.data;
  }

  /// restful delete 操作
  Future delete(
      String path, {
        data,
        Map<String, dynamic> ?params,
        Options ?options,
        CancelToken ?cancelToken,
      }) async {
    Options requestOptions = options ?? Options();

    Map<String, dynamic> _authorization = getAuthorizationHeader();
    if (_authorization != null) {
      requestOptions = requestOptions.merge(headers: _authorization);
    }
    var response = await dio.delete(path,
        data: data,
        queryParameters: params,
        options: requestOptions,
        cancelToken: cancelToken ?? _cancelToken);
    return response.data;
  }

  /// restful post form 表单提交操作
  Future postForm(
      String path, {
        Map<String, dynamic> ?params,
        Options ?options,
        CancelToken ?cancelToken,
      }) async {
    Options requestOptions = options ?? Options();
    Map<String, dynamic> _authorization = getAuthorizationHeader();
    if (_authorization != null) {
      requestOptions = requestOptions.merge(headers: _authorization);
    }
    var response = await dio.post(path,
        data: FormData.fromMap(params),
        options: requestOptions,
        cancelToken: cancelToken ?? _cancelToken);
    return response.data;
  }
  /// 读取本地配置
  Map<String, dynamic> getAuthorizationHeader() {
    var headers;
    String accessToken = Global.accessToken;
    if (accessToken != null) {
      headers = {"Authorization": 'Bearer $accessToken'};
    }
    return headers;
  }
  /// 读取公有云表头配置
  Future<Map<String, dynamic>> getKdWebApiHeader(url) async{
    Map<String, dynamic> headers = Map();
    var date = DateTime.now();
    var apigwSec = "";
    String acctID = Global.acctID;
    String appID = Global.appID;
    String appSec = Global.appSec;
    String userName = Global.userName;
    String lCID = Global.lCID;
    String serverUrl = Global.serverUrl;
    String context = sprintf("POST\n%s\n\nx-api-nonce:%s\nx-api-timestamp:%s\n", [Uri.encodeComponent(url.replaceAll('https://bj1-api.kingdee.com','')), date.millisecondsSinceEpoch,date.millisecondsSinceEpoch]);
    if(appID.split('_').length>1){
      var buffer = convert.base64Decode(appID.split('_')[1]);
      String seckey = "0054f397c6234378b09ca7d3e5debce7";
      var pwd = [];
      pwd = utf8.encode(seckey);
      for(int i = 0; i < buffer.length; ++i) {
        buffer[i] ^= pwd[i];
      }

      apigwSec = convert.base64Encode(buffer);
    }
    String data = sprintf("%s,%s,%s,%s", [acctID, userName,lCID,null]);
    if (appID != null) {
      headers['X-Api-ClientID'] = appID.split('_')[0];
      headers['content-type'] = 'application/json';
      headers['X-Api-Auth-Version'] = '2.0';
      headers['x-api-timestamp'] = date.millisecondsSinceEpoch;
      headers['x-api-nonce'] = date.millisecondsSinceEpoch;
      headers['x-api-signheaders'] = 'X-Api-TimeStamp,X-Api-Nonce';
      headers['X-Api-Signature'] = await FzwmWxbcPublic.arouseAbc({"content": context,"key": apigwSec});
      headers['X-Kd-Appkey'] = appID;
      headers['X-Kd-Appdata'] = convert.base64Encode(utf8.encode(data));
      headers['X-Kd-Signature'] =await FzwmWxbcPublic.arouseAbc({"content": appID+data,"key": appSec});
    }
    return headers;
  }
}


