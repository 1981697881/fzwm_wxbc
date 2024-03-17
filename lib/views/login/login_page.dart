import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:fzwm_wxbc/model/authorize_entity.dart';
import 'package:fzwm_wxbc/model/currency_entity.dart';
import 'package:fzwm_wxbc/model/login_entity.dart';
import 'package:fzwm_wxbc/http/api_response.dart';
import 'package:fzwm_wxbc/views/index/index_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fzwm_wxbc/utils/toast_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:qrscan/qrscan.dart' as scanner;
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //焦点
  FocusNode _focusNodeUserName = new FocusNode();
  FocusNode _focusNodePassWord = new FocusNode();
  var urlContent = new TextEditingController();
  var acctidContent = new TextEditingController();
  var lcidContent = new TextEditingController();
  var usernameContent = new TextEditingController();
  var passwordContent = new TextEditingController();
  static const scannerPlugin =
  const EventChannel('com.shinow.pda_scanner/plugin');
   StreamSubscription ?_subscription;
  var _code;
  //用户名输入框控制器，此控制器可以监听用户名输入框操作
  TextEditingController _userNameController = new TextEditingController();

  //表单状态
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late SharedPreferences sharedPreferences;
  var _password = ''; //用户名
  var _username = ''; //密码
  var message = ''; //密码
  var _isShowPwd = false; //是否显示密码
  var _isShowClear = false; //是否显示输入框尾部的清除按钮

  @override
  void initState() {
    // TODO: implement initState
    //设置焦点监听
    _focusNodeUserName.addListener(_focusNodeListener);
    _focusNodePassWord.addListener(_focusNodeListener);
    //监听用户名框的输入改变
    _userNameController.addListener(() {
      print(_userNameController.text);

      // 监听文本框输入变化，当有内容的时候，显示尾部清除按钮，否则不显示
      if (_userNameController.text.length > 0) {
        _isShowClear = true;
      } else {
        _isShowClear = false;
      }
      EasyLoading.dismiss();
     setState(() {});
    });
    super.initState();
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
  }

  _load() async {
    sharedPreferences = await SharedPreferences.getInstance();
    urlContent.text = sharedPreferences.getString('url');
    acctidContent.text = sharedPreferences.getString('acctId');
    usernameContent.text = sharedPreferences.getString('username');
    passwordContent.text = sharedPreferences.getString('password');
    /*lcidContent.text = sharedPreferences.getString('lcid');*/
  }
  void _onEvent(event) async {
    /*  setState(() {*/
    _code = event;
    var content = _code.split(',');
    urlContent.text = content[0];
    acctidContent.text = content[1];
    usernameContent.text = content[2];
    passwordContent.text = content[3];
    /*});}*/
  }

  void _onError(Object error) {
    setState(() {
      _code = "扫描异常";
    });
  }
  @override
  void dispose() {
    // TODO: implement dispose
    // 移除焦点监听
    _focusNodeUserName.removeListener(_focusNodeListener);
    _focusNodePassWord.removeListener(_focusNodeListener);
    _userNameController.dispose();
    super.dispose();

    /// 取消监听
    if (_subscription != null) {
      _subscription!.cancel();
    }
  }

  // 监听焦点
  Future<Null> _focusNodeListener() async {
    if (_focusNodeUserName.hasFocus) {
      print("用户名框获取焦点");
      // 取消密码框的焦点状态
      _focusNodePassWord.unfocus();
    }
    if (_focusNodePassWord.hasFocus) {
      print("密码框获取焦点");
      // 取消用户名框焦点状态
      _focusNodeUserName.unfocus();
    }
  }

  /**
   * 验证用户名
   */
  String? validateUserName(value) {
    // 正则匹配手机号
    /*RegExp exp = RegExp(r'^((13[0-9])|(14[0-9])|(15[0-9])|(16[0-9])|(17[0-9])|(18[0-9])|(19[0-9]))\d{8}$');*/
    if (value.isEmpty) {
      return '用户名不能为空!';
    } else if (value.trim().length < 3 || value.trim().length > 10) {
      return '请输入用户名';
    }
    return null;
  }
  /**
   * 验证密码
   */
  String? validatePassWord(value) {
    if (value.isEmpty) {
      return '密码不能为空';
    } else if (value.trim().length < 6 || value.trim().length > 18) {
      return '密码长度不正确';
    }
    return null;
  }
  //扫码函数,最简单的那种
  Future scan() async {
    String cameraScanResult = await scanner.scan(); //通过扫码获取二维码中的数据
    getScan(cameraScanResult); //将获取到的参数通过HTTP请求发送到服务器
    print(cameraScanResult); //在控制台打印
  }

//用于验证数据(也可以在控制台直接打印，但模拟器体验不好)
  void getScan(String scan) async {
    _code = scan;
    var content = _code.split(',');
    urlContent.text = content[0];
    acctidContent.text = content[1];
    usernameContent.text = content[2];
    passwordContent.text = content[3];
  }
  void _pushSaved() async {
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) {
          return new Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: scan,
              tooltip: 'Increment',
              child: Icon(Icons.filter_center_focus),
            ),
            appBar: new AppBar(
              title: new Text('系统参数'),
              centerTitle: true,
            ),
            body: Column(
              children: [
                Expanded(
                  child: new ListView(children: <Widget>[
                    ListTile(
                      title: TextField(
                        //最多输入行数
                        maxLines: 1,
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: "地址：",
                          //给文本框加边框
                          border: OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              // 清空输入框内容
                              urlContent.clear();
                            },
                          )
                        ),
                        controller: this.urlContent,
                        //改变回调
                        onChanged: (value) {
                          setState(() {
    urlContent.value = TextEditingValue(
    text: value,
    selection: TextSelection.fromPosition(TextPosition(
    affinity: TextAffinity.downstream,
    offset: value.length)));
    });
                        }
                      ),
                    ),
                    Divider(
                      height: 10.0,
                      indent: 0.0,
                      color: Colors.grey,
                    ),
                    ListTile(
                      title: TextField(
                        //最多输入行数
                        maxLines: 1,
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: "ACCTID：",
                          //给文本框加边框
                          border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                // 清空输入框内容
                                acctidContent.clear();
                              },
                            )
                        ),
                        controller: this.acctidContent,
                        //改变回调
                        onChanged: (value) {
                          setState(() {
                            acctidContent.value = TextEditingValue(
                                text: value,
                                selection: TextSelection.fromPosition(TextPosition(
                                    affinity: TextAffinity.downstream,
                                    offset: value.length)));
                          });
                        },
                      ),
                    ),
                   /* Divider(
                      height: 10.0,
                      indent: 0.0,
                      color: Colors.grey,
                    ),
                    ListTile(
                      title: TextField(
                        //最多输入行数
                        maxLines: 1,
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: "LCID：",
                          //给文本框加边框
                          border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                // 清空输入框内容
                                lcidContent.clear();
                              },
                            )
                        ),
                        controller: this.lcidContent,
                        //改变回调
                        onChanged: (value) {
                          setState(() {
                            lcidContent.value = TextEditingValue(
                                text: value,
                                selection: TextSelection.fromPosition(TextPosition(
                                    affinity: TextAffinity.downstream,
                                    offset: value.length)));
                          });
                        }
                        },
                      ),
                    ),*/
                    Divider(
                      height: 10.0,
                      indent: 0.0,
                      color: Colors.grey,
                    ),ListTile(
                      title: TextField(
                        //最多输入行数
                        maxLines: 1,
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: "账号：",
                          //给文本框加边框
                          border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                // 清空输入框内容
                                usernameContent.clear();
                              },
                            )
                        ),
                        controller: this.usernameContent,
                        //改变回调
                        onChanged: (value) {
                          setState(() {
                              usernameContent.value = TextEditingValue(
                                text: value,
                                selection: TextSelection.fromPosition(TextPosition(
                                    affinity: TextAffinity.downstream,
                                    offset: value.length)));
                          });
                        },
                      ),
                    ),
                    Divider(
                      height: 10.0,
                      indent: 0.0,
                      color: Colors.grey,
                    ),ListTile(
                      title: TextField(
                        //最多输入行数
                        maxLines: 1,
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: "密码：",
                          //给文本框加边框
                          border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                // 清空输入框内容
                                passwordContent.clear();
                              },
                            )
                        ),
                        obscureText: false,
                        controller: this.passwordContent,
                        //改变回调
                        onChanged: (value) {
                          setState(() {
                            passwordContent.value = TextEditingValue(
                                text: value,
                                selection: TextSelection.fromPosition(TextPosition(
                                    affinity: TextAffinity.downstream,
                                    offset: value.length)));
                          });
                        },
                      ),
                    ),
                    Divider(
                      height: 10.0,
                      indent: 0.0,
                      color: Colors.grey,
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 28.0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: RaisedButton(
                          padding: EdgeInsets.all(15.0),
                          child: Text("保存"),
                          color: Theme.of(context).primaryColor,
                          textColor: Colors.white,
                          onPressed: () async {
                            if(this.acctidContent.text != '' && this.urlContent.text != ''&& this.passwordContent.text != ''&& this.usernameContent.text != ''){
                              sharedPreferences.setString('url', this.urlContent.text);
                              sharedPreferences.setString('acctId', this.acctidContent.text);
                              /*sharedPreferences.setString('lcid', this.lcidContent.text);*/
                              sharedPreferences.setString('username', this.usernameContent.text);
                              sharedPreferences.setString('password', this.passwordContent.text);
                              ToastUtil.showInfo('保存成功');
                              Navigator.of(context).pop();
                            }else{
                              ToastUtil.showInfo('参数不能为空');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
  //AlertDialog
  Future showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("提示"),
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
  @override
  Widget build(BuildContext context) {
    ScreenUtil.instance = ScreenUtil(width: 750, height: 1334)..init(context);
    print(ScreenUtil().scaleHeight);
    // logo 图片区域
    Widget logoImageArea = new Container(
      alignment: Alignment.topCenter,
      // 设置图片为圆形
      child: ClipOval(
        child: Image.asset(
          "assets/images/icon.png",
          height: 100,
          width: 100,
          fit: BoxFit.cover,
        ),
      ),
    );

    //输入文本框区域
    Widget inputTextArea = new Container(
      margin: EdgeInsets.only(left: 20, right: 20),
      decoration: new BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          color: Colors.white),
      child: new Form(
        key: _formKey,
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new TextFormField(
              controller: _userNameController,
              focusNode: _focusNodeUserName,
              //设置键盘类型
              /* keyboardType: TextInputType.number,*/
              decoration: InputDecoration(
                labelText: "用户名",
                hintText: "请输入用户名",
                prefixIcon: Icon(Icons.person),
                //尾部添加清除按钮
                suffixIcon: (_isShowClear)
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          // 清空输入框内容
                          _userNameController.clear();
                        },
                      )
                    : null,
              ),
              //验证用户名
              validator: validateUserName,
              //保存数据
              onSaved: (value) {
                _username = value!;
              },
            ),
            new TextFormField(
              focusNode: _focusNodePassWord,
              decoration: InputDecoration(
                  labelText: "密码",
                  hintText: "请输入密码",
                  prefixIcon: Icon(Icons.lock),
                  // 是否显示密码
                  suffixIcon: IconButton(
                    icon: Icon(
                        (_isShowPwd) ? Icons.visibility : Icons.visibility_off),
                    // 点击改变显示或隐藏密码
                    onPressed: () {
                      setState(() {
                        _isShowPwd = !_isShowPwd;
                      });
                    },
                  )),
              obscureText: !_isShowPwd,
              //密码验证
              validator: validatePassWord,
              //保存数据
              onSaved: (value) {
                _password = value!;
              },
            )
          ],
        ),
      ),
    );
    // 登录按钮区域
    Widget loginButtonArea = new Container(
      margin: EdgeInsets.only(left: 20, right: 20),
      height: 45.0,
      child: new RaisedButton(
        color: Colors.blue[300],
        child: Text(
          "登录",
          style: TextStyle(fontSize: 18.0, color: Colors.white),
        ),
        // 设置按钮圆角
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        onPressed: () async {
          //点击登录按钮，解除焦点，回收键盘
          _focusNodePassWord.unfocus();
          _focusNodeUserName.unfocus();
          if (_formKey.currentState!.validate()) {
            //只有输入通过验证，才会执行这里
            _formKey.currentState!.save();
            if(this.acctidContent.text != '' && this.urlContent.text != '' && this.passwordContent.text != '' && this.usernameContent.text != ''){
              Map<String, dynamic> map = Map();
              map['username'] = sharedPreferences.getString('username');
              map['acctID'] =  sharedPreferences.getString('acctId');
              map['lcid'] =  "2052";
              map['password'] = sharedPreferences.getString('password');
              ApiResponse<LoginEntity> entity = await LoginEntity.login(map);
              if (entity.data!.loginResultType == 1) {
                //  print("登录成功");
                Map<String, dynamic> userMap = Map();
                userMap['FormId'] = 'BD_Empinfo';
                userMap['FilterString'] =
                "FStaffNumber='$_username' and FPwd='$_password'";
                userMap['FieldKeys'] =
                'FStaffNumber,FUseOrgId.FNumber,FForbidStatus,FAuthCode,FPDASCRK,FPDASCRKS,FPDASCLL,FPDASCLLS,FPDAXSCK,FPDAXSCKS,FPDAXSTH,FPDAXSTHS,FPDACGRK,FPDACGRKS,FPDAPD,FPDAPDS,FPDAQTRK,FPDAQTRKS,FPDAQTCK,FPDAQTCKS,FPDAGXPG,FPDAGXPGS,FPDAGXHB,FPDAGXHBS,FPDASJ,FPDAXJ,FPDAKCCX'; /*FWorkShopID.FNumber,FWorkShopID.FName*/
                Map<String, dynamic> dataMap = Map();
                dataMap['data'] = userMap;
                String UserEntity = await CurrencyEntity.polling(dataMap);
                var resUser = jsonDecode(UserEntity);
                if (resUser.length > 0) {
                  if (resUser[0][2] == 'A') {
                    /*sharedPreferences.setString('FWorkShopNumber', resUser[0][2]);
                  sharedPreferences.setString('FWorkShopName', resUser[0][3]);*/
                    Map<String, dynamic> authorMap = Map();
                    authorMap['auth'] = resUser[0][3];
                    ApiResponse<AuthorizeEntity> author = await AuthorizeEntity.getAuthorize(authorMap);
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
                        sharedPreferences.setString('FStaffNumber', _username);
                        sharedPreferences.setString('FPwd', _password);
                        sharedPreferences.setString('MenuPermissions', UserEntity);
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
                        ToastUtil.showInfo('无授予权限或者授权数量超过限定，请检查!');
                      }
                    }else{
                      ToastUtil.errorDialog(context,author.data!.data.fMessage);
                    }
                  } else {
                    if (!resUser[0][0]['Result']['ResponseStatus']['IsSuccess']) {
                      ToastUtil.showInfo(resUser[0][0]['Result']['ResponseStatus']
                      ['Errors'][0]['Message']);
                    } else {
                      ToastUtil.showInfo('该账号无登录权限');
                    }
                  }
                } else {
                  ToastUtil.showInfo('用户名或密码错误');
                }
              } else {
                ToastUtil.showInfo(entity.data!.message);
              }
            }else{
              ToastUtil.showInfo('请配置登录信息,在登录页右上角,点击设置按钮进行配置');
            }
            //todo 登录操作
            print("$_username + $_password");
          }
        },
      ),
    );

    return FlutterEasyLoading(
      child: MaterialApp(
        title: 'Flutter EasyLoading',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: new Text('登录'),
            centerTitle: true,
            actions: <Widget>[
              new IconButton(
                  icon: new Icon(Icons.settings), onPressed: _pushSaved),
            ],
          ),
          // 外层添加一个手势，用于点击空白部分，回收键盘
          body: new GestureDetector(
            onTap: () {
              // 点击空白区域，回收键盘
              print("点击了空白区域");
              _focusNodePassWord.unfocus();
              _focusNodeUserName.unfocus();
            },
            child: new ListView(
              children: <Widget>[
                new SizedBox(
                  height: ScreenUtil().setHeight(80),
                ),
                logoImageArea,
                new SizedBox(
                  height: ScreenUtil().setHeight(70),
                ),
                inputTextArea,
                new SizedBox(
                  height: ScreenUtil().setHeight(80),
                ),
                loginButtonArea,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
