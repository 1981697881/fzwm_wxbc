/*
import 'dart:async';

import 'package:bluetooth_thermal_printer/bluetooth_thermal_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:gbk2utf8/gbk2utf8.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  bool connected = false;
  List availableBluetoothDevices = [];

  Future<void> getBluetooth() async {
    final List? bluetooths = await BluetoothThermalPrinter.getBluetooths;
    print("Print $bluetooths");
    setState(() {
      availableBluetoothDevices = bluetooths!;
    });
  }

  Future<void> setConnect(String mac) async {
    final String? result = await BluetoothThermalPrinter.connect(mac);
    print("state conneected $result");
    if (result == "true") {
      setState(() {
        connected = true;
      });
    }
  }

  Future<void> printTicket() async {
    String? isConnected = await BluetoothThermalPrinter.connectionStatus;
    if (isConnected == "true") {
      List<int> bytes = await getTicket();
      final result = await BluetoothThermalPrinter.writeBytes(bytes);
      print("Print $result");
    } else {
      //Hadnle Not Connected Senario
    }
  }

  Future<void> printGraphics() async {
    String? isConnected = await BluetoothThermalPrinter.connectionStatus;
    if (isConnected == "true") {
      List<int> bytes = await getGraphicsTicket();
      print(bytes);
      final result = await BluetoothThermalPrinter.writeBytes(bytes);
      print("Print $result");
    } else {
      //Hadnle Not Connected Senario
    }
  }

  Future<List<int>> getGraphicsTicket() async {
    var  println = 'SIZE 100.0 mm,73.0 mm\r\n' +
        'GAP 2 mm\r\n' +
        'CLS\r\n' +
        'BOX 5, 5, 800, 550, 3\r\n' +
        'BAR 140, 100, 460, 1\r\n' +
        'BAR 140, 180, 460, 1\r\n' +
        'BAR 140, 260, 460, 1\r\n' +
        'BAR 220, 340, 380, 1\r\n' +
        'BAR 190, 420, 410, 1\r\n' +
        'BAR 140, 500, 460, 1\r\n' +
        'TEXT 10,50,"TSS24.BF2",0,2,2,"品名:"\r\n' +
        'TEXT 10,130,"TSS24.BF2",0,2,2,"批号:"\r\n' +
        'TEXT 10,210,"TSS24.BF2",0,2,2,"净重:"\r\n' +
        'TEXT 10,290,"TSS24.BF2",0,2,2,"到货日期:"\r\n' +
        'TEXT 10,370,"TSS24.BF2",0,2,2,"有效期:"\r\n' +
        'TEXT 10,450,"TSS24.BF2",0,2,2,"备注:"\r\n' +
        'TEXT 150,50,"TSS24.BF2",0,2,2,"品名:"\r\n' +
        'TEXT 150,130,"TSS24.BF2",0,2,2,"批号:"\r\n' +
        'TEXT 150,210,"TSS24.BF2",0,2,2,"净重:"\r\n' +
        'TEXT 230,290,"TSS24.BF2",0,2,2,"到货日期:"\r\n' +
        'TEXT 200,370,"TSS24.BF2",0,2,2,"有效期:"\r\n' +
        'TEXT 150,450,"TSS24.BF2",0,2,2,"备注:"\r\n' +
        'QRCODE 610,180,M,8,A,0,"gxpg202203170002"\r\n' +
        'PRINT 1,1\r\n';
    return gbk.encode(println);

  }

  Future<List<int>> getTicket() async {
    List<int> bytes = [];
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    bytes += generator.text("Demo Shop",
        styles: PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
        linesAfter: 1);
    bytes += generator.text(
        "18th Main Road, 2nd Phase, J. P. Nagar, Bengaluru, Karnataka 560078",
        styles: PosStyles(align: PosAlign.center));
    bytes += generator.text('Tel: +919591708470',
        styles: PosStyles(align: PosAlign.center));
    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(
          text: 'No',
          width: 1,
          styles: PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(
          text: 'Item',
          width: 5,
          styles: PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(
          text: 'Price',
          width: 2,
          styles: PosStyles(align: PosAlign.center, bold: true)),
      PosColumn(
          text: 'Qty',
          width: 2,
          styles: PosStyles(align: PosAlign.center, bold: true)),
      PosColumn(
          text: 'Total',
          width: 2,
          styles: PosStyles(align: PosAlign.right, bold: true)),
    ]);

    bytes += generator.row([
      PosColumn(text: "1", width: 1),
      PosColumn(
          text: "Tea",
          width: 5,
          styles: PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: "10",
          width: 2,
          styles: PosStyles(
            align: PosAlign.center,
          )),
      PosColumn(text: "1", width: 2, styles: PosStyles(align: PosAlign.center)),
      PosColumn(text: "10", width: 2, styles: PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: "2", width: 1),
      PosColumn(
          text: "Sada Dosa",
          width: 5,
          styles: PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: "30",
          width: 2,
          styles: PosStyles(
            align: PosAlign.center,
          )),
      PosColumn(text: "1", width: 2, styles: PosStyles(align: PosAlign.center)),
      PosColumn(text: "30", width: 2, styles: PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: "3", width: 1),
      PosColumn(
          text: "Masala Dosa",
          width: 5,
          styles: PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: "50",
          width: 2,
          styles: PosStyles(
            align: PosAlign.center,
          )),
      PosColumn(text: "1", width: 2, styles: PosStyles(align: PosAlign.center)),
      PosColumn(text: "50", width: 2, styles: PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: "4", width: 1),
      PosColumn(
          text: "Rova Dosa",
          width: 5,
          styles: PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: "70",
          width: 2,
          styles: PosStyles(
            align: PosAlign.center,
          )),
      PosColumn(text: "1", width: 2, styles: PosStyles(align: PosAlign.center)),
      PosColumn(text: "70", width: 2, styles: PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(
          text: 'TOTAL',
          width: 6,
          styles: PosStyles(
            align: PosAlign.left,
            height: PosTextSize.size4,
            width: PosTextSize.size4,
          )),
      PosColumn(
          text: "160",
          width: 6,
          styles: PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size4,
            width: PosTextSize.size4,
          )),
    ]);

    bytes += generator.hr(ch: '=', linesAfter: 1);

    // ticket.feed(2);
    bytes += generator.text('Thank you!',
        styles: PosStyles(align: PosAlign.center, bold: true));

    bytes += generator.text("26-11-2020 15:22:45",
        styles: PosStyles(align: PosAlign.center), linesAfter: 1);

    bytes += generator.text(
        'Note: Goods once sold will not be taken back or exchanged.',
        styles: PosStyles(align: PosAlign.center, bold: false));
    bytes += generator.cut();
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Bluetooth Thermal Printer Demo'),
        ),
        body: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Search Paired Bluetooth"),
              TextButton(
                onPressed: () {
                  this.getBluetooth();
                },
                child: Text("Search"),
              ),
              Container(
                height: 150,
                child: ListView.builder(
                  itemCount: availableBluetoothDevices.length > 0
                      ? availableBluetoothDevices.length
                      : 0,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () {
                        String select = availableBluetoothDevices[index];
                        List list = select.split("#");
                        // String name = list[0];
                        String mac = list[1];
                        this.setConnect(mac);
                      },
                      title: Text('${availableBluetoothDevices[index]}'),
                      subtitle: Text("Click to connect"),
                    );
                  },
                ),
              ),
              SizedBox(
                height: 30,
              ),
              TextButton(
                onPressed: connected ? this.printGraphics : null,
                child: Text("Print"),
              ),
              TextButton(
                onPressed: connected ? this.printTicket : null,
                child: Text("Print Ticket"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:crypto/crypto.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fzwm_wxbc/model/login_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fzwm_wxbc/views/login/login_page.dart';
import 'package:fzwm_wxbc/views/index/index_page.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'http/httpUtils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fzwm_wxbc/utils/toast_util.dart';
import 'package:fzwm_wxbc/server/api.dart';
import 'package:fzwm_wxbc/http/api_response.dart';
import 'model/authorize_entity.dart';
import 'model/currency_entity.dart';

import 'package:flutter_downloader/flutter_downloader.dart';
const Color _primaryColor = Colors.blue;

void main(List<String> args) async {
  HttpUtils.init(
    baseUrl: "https://gzlcsign.ik3cloud.com",
  );
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(
      debug: true
  );
  runApp(MyApp());
  if (Platform.isAndroid) {
    SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    );
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  }
}

class MyApp extends StatelessWidget {
  //不显示 debug标签

// This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //不显示 debug标签
      debugShowCheckedModeBanner: false,
      //当前运行环境配置
      locale: Locale("zh","CH"),
      //程序支持的语言环境配置
      supportedLocales: [Locale("zh","CH")],
      //Material 风格代理配置
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: ThemeData(
        primaryColor: _primaryColor,
        // primaryTextTheme: ThemeData.dark().primaryTextTheme,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: _primaryColor,
        ),
        appBarTheme: AppBarTheme(
          // appBar背景色
          // color: Colors.white,
          // 浅色背景，深色字体
          brightness: Brightness.light,
          // appBar文字主题
          // textTheme: TextTheme(
          //   headline6: TextStyle(color: Colors.black),
          // ),
        ),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State {
  var _getaname = "";
  var _getpsw = "";
  var username = "";
  var password = "";
  var message = "";
  var isLogin = true;

  @override
  void initState() {
    super.initState();
    int count = 0;
    const period = const Duration(seconds: 1);
    print('currentTime=' + DateTime.now().toString());
    Timer.periodic(period, (timer) {
      //到时回调
      print('afterTimer=' + DateTime.now().toString());
      count++;
      if (count >= 3) {
        //取消定时器，避免无限回调
        timer.cancel();
        /*timer = null;*/
        toLoing();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
  /**
   * 验证用户名
   */
  bool validateUserName(value) {
    // 正则匹配手机号
    /*RegExp exp = RegExp(r'^((13[0-9])|(14[0-9])|(15[0-9])|(16[0-9])|(17[0-9])|(18[0-9])|(19[0-9]))\d{8}$');*/
    if (value == null) {
      return false;
    } else if (value.trim().length < 3 || value.trim().length > 16) {
      return false;
    }
    return true;
  }
  /**
   * 验证密码
   */
  bool validatePassWord(value) {
    if (value == null) {
      return false;
    } else if (value.trim().length < 6 || value.trim().length > 18) {
      return false;
    }
    return true;
  }
  //AlertDialog
  Future showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("温馨提示"),
          content: Text("$message"),
          actions: <Widget>[
            FlatButton(
              child: Text("确定"),
              onPressed: () {
                //关闭对话框并返回true
                Navigator.of(context).pop();
                ToastUtil.showInfo('登录成功');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return IndexPage();
                    },
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
  void toLoing() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    _getaname = sharedPreferences.getString('username');
    _getpsw = sharedPreferences.getString('password');
    username = sharedPreferences.getString('FStaffNumber');
    password = sharedPreferences.getString('FPwd');
    if (validateUserName(_getaname) &&
        validatePassWord(_getpsw) &&
        validateUserName(username) &&
        validatePassWord(password) && isLogin) {
      Map<String, dynamic> map = Map();
      map['username'] = _getaname;
      map['acctID'] =  sharedPreferences.getString('acctId');
      map['lcid'] =  "2052";
      map['password'] = _getpsw;
      try{
        ApiResponse<LoginEntity> entity = await LoginEntity.login(map);
        print(entity.data!.loginResultType);
        if (entity.data!.loginResultType == 1) {
          Map<String, dynamic> userMap = Map();
          userMap['FormId'] = 'BD_Empinfo';
          userMap['FilterString'] =
          "FStaffNumber='$username' and FPwd='$password'";
          userMap['FieldKeys'] = 'FStaffNumber,FUseOrgId.FNumber,FForbidStatus,FAuthCode,FPDASCRK,FPDASCRKS,FPDASCLL,FPDASCLLS,FPDAXSCK,FPDAXSCKS,FPDAXSTH,FPDAXSTHS,FPDACGRK,FPDACGRKS,FPDAPD,FPDAPDS,FPDAQTRK,FPDAQTRKS,FPDAQTCK,FPDAQTCKS,FPDAGXPG,FPDAGXPGS,FPDAGXHB,FPDAGXHBS,FPDASJ,FPDAXJ,FPDAKCCX,FStockIds';
          Map<String, dynamic> dataMap = Map();
          dataMap['data'] = userMap;
          String UserEntity = await CurrencyEntity.polling(dataMap);
          var resUser =jsonDecode(UserEntity);
          print(resUser);
          if (resUser.length > 0) {
            if (resUser[0][2] == 'A') {
              /* sharedPreferences.setString('FWorkShopNumber', resUser[0][2]);
            sharedPreferences.setString('FWorkShopName', resUser[0][3]);*/
              //  print("登录成功");
              Map<String, dynamic> authorMap = Map();
              authorMap['auth'] = resUser[0][3];
              ApiResponse<AuthorizeEntity> author =
              await AuthorizeEntity.getAuthorize(authorMap);
              if (author.data!.data.fStatus == "0") {
                Map<String, dynamic> empMap = Map();
                empMap['FormId'] = 'BD_Empinfo';
                empMap['FilterString'] =
                    "FAuthCode='"+resUser[0][3]+"'";
                empMap['FieldKeys'] =
                'FStaffNumber,FUseOrgId.FNumber,FForbidStatus,FAuthCode';
                Map<String, dynamic> empDataMap = Map();
                empDataMap['data'] = empMap;
                String EmpEntity = await CurrencyEntity.polling(empDataMap);
                var resEmp = jsonDecode(EmpEntity);
                if(author.data!.data.fAuthNums >= resEmp.length && resEmp.length > 0){
                  sharedPreferences.setString('menuList', jsonEncode(author.data!.data));
                  sharedPreferences.setString('MenuPermissions', UserEntity);
                  sharedPreferences.setString('FStockIds', jsonEncode(resUser[0][27]));
                  if(author.data!.data.fMessage == null){
                    ToastUtil.showInfo('登录成功');
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return IndexPage();
                        },
                      ),
                    );
                  }else{
                    this.message = author.data!.data.fMessage;
                    showExitDialog();
                  }
                }else{
                  ToastUtil.showInfo('该账号无授予权限或者授权数量超过限定，请检查！');
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return LoginPage();
                      },
                    ),
                  );
                }
              }else{
                ToastUtil.errorDialog(context,
                    author.data!.data.fMessage);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return LoginPage();
                    },
                  ),
                );
              }
            } else {
              ToastUtil.showInfo('该账号无登录权限');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return LoginPage();
                  },
                ),
              );
            }
          }else{
            ToastUtil.showInfo('该账号无登录权限');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return LoginPage();
                },
              ),
            );
          }
        } else {
          ToastUtil.showInfo('登录失败，重新登录');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                return LoginPage();
              },
            ),
          );
        }
      }catch (e, stack){
        ToastUtil.showInfo('登录失败，重新登录');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              return LoginPage();
            },
          ),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return LoginPage();
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/images/splash.png"),
                fit: BoxFit.fill)));
    /* child: Image.network("https://i.postimg.cc/nh1TyksR/12133.png"),
       child:Image.network("https://i.postimg.cc/J4rL1ZpB/splash.png"),*/
  }
}

