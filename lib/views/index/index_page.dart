import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_pickers/pickers.dart';
import 'package:flutter_pickers/style/default_style.dart';
import 'package:fzwm_wxbc/components/my_text.dart';
import 'package:fzwm_wxbc/http/api_response.dart';
import 'package:fzwm_wxbc/model/currency_entity.dart';
import 'package:fzwm_wxbc/model/version_entity.dart';
import 'package:fzwm_wxbc/utils/SqfLiteQueueDataOffline.dart';
import 'package:fzwm_wxbc/utils/SqfLiteQueueDataRepertoire.dart';
import 'package:fzwm_wxbc/utils/SqfLiteQueueDataScheme.dart';
import 'package:fzwm_wxbc/utils/toast_util.dart';
import 'package:fzwm_wxbc/views/login/login_page.dart';
import 'package:fzwm_wxbc/views/stock/stock_page.dart';
import 'package:package_info/package_info.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import 'about_page.dart';
import 'middle_layer_page.dart';

class IndexPage extends StatefulWidget {
  IndexPage({
    Key ?key,
  }) : super(key: key);

  @override
  _IndexPageState createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  //自动更新字段
  String serviceVersionCode = '';
  String downloadUrl = '';
  String buildVersion = '';
  String buildUpdateDescription = '';
  late ProgressDialog pr;
  String apkName = 'fzwm_wxbc.apk';
  String appPath = '';
  var organizationsName;
  var organizationsNumber;
  var organizationsList = [];
  List<dynamic> organizationsListObj = [];
  var _code;
  final divider = Divider(height: 1, indent: 20);
  ReceivePort _port = ReceivePort();
  late SharedPreferences sharedPreferences;
  final rightIcon = Icon(Icons.keyboard_arrow_right);
  static const scannerPlugin = const EventChannel('com.shinow.pda_scanner/plugin');
  StreamSubscription ?_subscription;

  @override
  void initState() {
    super.initState();
    this.getOrganizationsList();
    /// 开启监听
    if (_subscription == null) {
      _subscription = scannerPlugin
          .receiveBroadcastStream()
          .listen(_onEvent, onError: _onError);
    }
    Future.delayed(
        Duration.zero,
        () => setState(() {
              _load();
            }));

    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen(_updateDownLoadInfo);
    FlutterDownloader.registerCallback(_downLoadCallback);
    afterFirstLayout(context);
  }
  @override
  void dispose() {
    super.dispose();

    /// 取消监听
    if (_subscription != null) {
      _subscription!.cancel();
    }
  }
  @override
  void afterFirstLayout(BuildContext context) {
    // 如果是android，则执行热更新
    if (Platform.isAndroid) {
      _getNewVersionAPP(context);
    }
  }
  getOrganizationsList() async {

    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'ORG_Organizations';
    userMap['FieldKeys'] = 'FForbidStatus,FName,FNumber';
    userMap['FilterString'] = "FForbidStatus = 'A'";
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    organizationsListObj = jsonDecode(res);
    organizationsListObj.forEach((element) {
      organizationsList.add(element[1]);
    });

    var tissue = sharedPreferences.getString('tissue');
    var tissueName = sharedPreferences.getString('tissueName');
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    if(tissue != null){
      setState(() {
        this.organizationsNumber = tissue;
        this.organizationsName = tissueName;
      });
    }else if(deptData[1] != null){
      for (var data in organizationsListObj) {
        if(data[2] == deptData[1]){
          setState(() {
            this.organizationsName = data[1];
          });
        }
      }
      this.organizationsNumber = deptData[1];
      sharedPreferences.setString('tissue', organizationsNumber);
      sharedPreferences.setString('tissueName', organizationsName);
    }
  }
  _initState() {
    /// 开启监听
    _subscription = scannerPlugin
        .receiveBroadcastStream()
        .listen(_onEvent, onError: _onError);
  }
  void _onEvent(event) async {
    _code = event;
    if(event == ""){
      return;
    }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return StockPage(
                keyword: event
              // 路由参数
            );
          },
        ),
      ).then((data) {
        //延时500毫秒执行
        Future.delayed(
            const Duration(milliseconds: 500),
                () {
              setState(() {
                //延时更新状态
                this._initState();
              });
            });
      });
  }

  void _onError(Object error) {
    setState(() {
      _code = "扫描异常";
    });
  }
  _load() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }
  /// 执行版本更新的网络请求
  _getNewVersionAPP(context) async {
    ApiResponse<VersionEntity> entity = await VersionEntity.getVersion();
    serviceVersionCode = entity.data!.data.buildVersionNo;
    buildVersion = entity.data!.data.buildVersion;
    buildUpdateDescription = entity.data!.data.buildUpdateDescription;
    downloadUrl = entity.data!.data.downloadUrl;
    _checkVersionCode();
  }
  /// 检查当前版本是否为最新，若不是，则更新
  void _checkVersionCode() {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      var currentVersionCode = packageInfo.buildNumber;
      if (int.parse(serviceVersionCode) > int.parse(currentVersionCode)) {
        _showNewVersionAppDialog();
      }
    });
  }
  /// 版本更新提示对话框
  Future<void> _showNewVersionAppDialog() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Row(
              children: <Widget>[
                new Padding(
                    padding: const EdgeInsets.fromLTRB(30.0, 0.0, 10.0, 0.0),
                    child: new Text("发现新版本"))
              ],
            ),
            content:
                new Text(buildUpdateDescription + "（" + buildVersion + ")"),
            actions: <Widget>[
              new FlatButton(
                child: new Text('下次再说'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              new FlatButton(
                child: new Text('立即更新'),
                onPressed: () {
                  _doUpdate(context);
                },
              )
            ],
          );
        });
  }
  /// 执行更新操作
  _doUpdate(BuildContext context) async {
    Navigator.pop(context);
    _executeDownload(context);
  }
  /// 下载最新apk包
  Future<void> _executeDownload(BuildContext context) async {
    pr = new ProgressDialog(
      context,
      type: ProgressDialogType.Download,
      isDismissible: true,
      showLogs: true,
    );
    pr.style(message: '准备下载...');
    if (!pr.isShowing()) {
      pr.show();
    }
    final path = await _apkLocalPath;
    await FlutterDownloader.enqueue(
        url: downloadUrl,
        savedDir: path,
        fileName: apkName,
        showNotification: true,
        openFileFromNotification: true);
  }
  /// 下载进度回调函数
  static void _downLoadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }
  /// 更新下载进度框
  _updateDownLoadInfo(dynamic data) {
    DownloadTaskStatus status = data[1];
    int progress = data[2];
    if (status == DownloadTaskStatus.running) {
      pr.update(
          progress: double.parse(progress.toString()), message: "下载中，请稍后…");
    }
    if (status == DownloadTaskStatus.failed) {
      if (pr.isShowing()) {
        pr.hide();
      }
    }

    if (status == DownloadTaskStatus.complete) {
      if (pr.isShowing()) {
        pr.hide();
      }
      _installApk();
    }
  }
  /// 安装apk
  Future<Null> _installApk() async {
    await OpenFile.open(appPath + '/' + apkName);
  }
  /// 获取apk存储位置
  Future<String> get _apkLocalPath async {
    final directory = await getExternalStorageDirectory();
    String path = directory.path + Platform.pathSeparator + 'Download';
    final savedDir = Directory(path);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      await savedDir.create();
    }
    this.setState(() {
      appPath = path;
    });
    return path;
  }
  double hc_ScreenWidth() {
    return window.physicalSize.width / window.devicePixelRatio;
  }
/*一个渐变颜色的正方形集合*/
  List<Widget> Boxs(List<Map<String, dynamic>> menu) =>
      List.generate(menu.length, (index) {
        return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => menu[index]['router']),
              ).then((data) {
                //延时500毫秒执行
                Future.delayed(
                    const Duration(milliseconds: 500),
                        () {
                      setState(() {
                        //延时更新状态
                        this._initState();
                      });
                    });
              });
            },
            child: Container(
                width: hc_ScreenWidth()/4,
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        offset: Offset(0.0, 15.0), //阴影xy轴偏移量
                        blurRadius: 15.0, //阴影模糊程度
                        spreadRadius: 1.0 //阴影扩散程度
                    )
                  ],
                  borderRadius: BorderRadius.all(
                    //圆角
                    Radius.circular(10.0),
                  ),
                  gradient: LinearGradient(colors: [
                    Colors.lightBlueAccent,
                    Colors.blue,
                    Colors.blueAccent
                  ]),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: menu[index]['color'],
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Icon(
                        menu[index]['icon'],
                        size: (IconTheme.of(context).size!) - 6,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(
                      height: 5.0,
                    ),
                    Text(
                      menu[index]['text'],
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                )));
      });

  // tabs 容器
  Widget buildAppBarTabs() {
    var deptData = sharedPreferences.getString('menuList');
    var menuList = new Map<dynamic, dynamic>.from(jsonDecode(deptData));
    var fAuthList = menuList['FAuthList'].split(",");
    var menu = <Map<String, dynamic>>[];
    for (var i in fAuthList) {
      switch (i) {
        case "1":
          var obj = {
            "icon": Icons.loupe,
            "text": "生产管理",
            "id": 1,
            "color": Colors.pink.withOpacity(0.7),
            "router": MiddleLayerPage(menuId: 1, menuTitle: "生产管理")
          };
          menu.add(obj);
          break;
        case "2":
          var obj = {
            "icon": Icons.local_shipping,
            "text": "销售管理",
            "id": 2,
            "color": Colors.pink.withOpacity(0.7),
            "router": MiddleLayerPage(menuId: 2, menuTitle: "销售管理")
          };
          menu.add(obj);
          break;
        case "3":
          var obj = {
            "icon": Icons.web,
            "text": "库存管理",
            "id": 3,
            "color": Colors.pink.withOpacity(0.7),
            "router": MiddleLayerPage(menuId: 3, menuTitle: "库存管理")
          };
          menu.add(obj);
          break;
        case "5":
          var obj = {
            "icon": Icons.shopping_cart,
            "text": "采购管理",
            "id": 5,
            "color": Colors.pink.withOpacity(0.7),
            "router": MiddleLayerPage(menuId: 5, menuTitle: "采购管理")
          };
          menu.add(obj);
          break;
          case "6":
          var obj = {
            "icon": Icons.ballot,
            "text": "委外管理",
            "id": 6,
            "color": Colors.pink.withOpacity(0.7),
            "router": MiddleLayerPage(menuId: 6, menuTitle: "委外管理")
          };
          menu.add(obj);
          break;
      }
    };
    return Wrap(
        spacing: 24, //主轴上子控件的间距
        runSpacing: 20, //交叉轴上子控件之间的间距
        children: Boxs(
            menu)
        );
  }

  void _pushSaved() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version; //版本号
    String buildNumber = packageInfo.buildNumber; //版本构建号
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) {
      return StatefulBuilder(builder: (context1, setState) {
        return new Scaffold(
          appBar: new AppBar(
            title: new Text('系统设置'),
            centerTitle: true,
          ),

          body: new ListView(padding: EdgeInsets.all(10), children: <Widget>[
            ListTile(
              leading: Icon(Icons.search),
              title: Text('版本信息（$version）'),
              onTap: () async {
                afterFirstLayout(context);
              },
            ),
            Divider(
              height: 10.0,
              indent: 0.0,
              color: Colors.grey,
            ),
            ListTile(
              leading: Icon(Icons.help),
              title: Text('关于'),
              onTap: () async {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return AboutPage();
                    },
                  ),
                );
              },
            ),
            Divider(
              height: 10.0,
              indent: 0.0,
              color: Colors.grey,
            ),

            ListTile(
              leading: Icon(Icons.settings),
              title: Text('退出登录'),
              onTap: () async {
                print("点击退出登录");
                SharedPreferences prefs =
                await SharedPreferences.getInstance();
                /*prefs.clear();*/
                if (await SqfLiteQueueDataOffline.isTableExits("offline_Inventory") == true) {
                    SqfLiteQueueDataOffline.deleteDataTable();
                  }
                  if (await SqfLiteQueueDataOffline.isTableExits("offline_Inventory_cache") == true) {
                    SqfLiteQueueDataOffline.deleteTDataTable();
                  }
                  if (await SqfLiteQueueDataRepertoire.isTableExits("barcode_list") == true) {
                    SqfLiteQueueDataRepertoire.deleteDataTable();
                  }
                  if (await SqfLiteQueueDataScheme.isTableExits("scheme_Inventory") == true) {
                    SqfLiteQueueDataScheme.deleteDataTable();
                  }
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return LoginPage();
                    },
                  ),
                );
              },
            ),
            Divider(
              height: 10.0,
              indent: 0.0,
              color: Colors.grey,
            ),
          ]),
        );
      });
        },
      ),
    );
  }
  List<Widget> _getDrawer() {
    List<Widget> tempList = [];
    for (var data in organizationsListObj) {
      List<Widget> comList = [];
      comList.add(
        Column(children: [
          Container(
            color: Colors.white,
            child: ListTile(
                title: Text(data[1] +
                    '：' +
                    data[2]),
                onTap: () {
                  // Update the state of the app
                  // ...
                  // Then close the drawer
                  setState(() {
                    organizationsName = data[1];
                    organizationsNumber = data[2];
                  });
                  sharedPreferences.setString('tissue', data[2]);
                  sharedPreferences.setString('tissueName', data[1]);
                  Navigator.pop(context);
                },
                ),
          ),
          divider,
        ]),
      );
      tempList.add(
        Column(
          children: comList,
        ),
      );
    }
    return tempList;
  }
  @override
  Widget build(BuildContext context) {
    return FlutterEasyLoading(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: new Text('主页'),
          centerTitle: true,
          actions: <Widget>[
            new IconButton(icon: new Icon(Icons.settings), onPressed: _pushSaved),
          ],
        ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // 打开抽屉
              _scaffoldKey.currentState!.openEndDrawer();
            },
            child: Icon(Icons.menu),
          ),
          endDrawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: Text(
                    organizationsName.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
                Column(
                  children: this._getDrawer(),
                ),
              ],
            ),
          ),
        body: Container(
          width: double.infinity,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.white,
                margin: EdgeInsets.only(bottom: 10.0),
                padding: EdgeInsets.symmetric(
                  // 同appBar的titleSpacing一致
                  horizontal: NavigationToolbar.kMiddleSpacing,
                  vertical: 20.0,
                ),
                child: buildAppBarTabs(),
              ),
            ],
          ),
        ),
    ),
    );
  }
}

