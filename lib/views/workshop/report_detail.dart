import 'dart:convert';
import 'package:date_format/date_format.dart';
import 'package:fzwm_wxbc/model/currency_entity.dart';
import 'package:fzwm_wxbc/model/submit_entity.dart';
import 'package:fzwm_wxbc/utils/handler_order.dart';
import 'package:fzwm_wxbc/utils/refresh_widget.dart';
import 'package:fzwm_wxbc/utils/text.dart';
import 'package:fzwm_wxbc/utils/toast_util.dart';
import 'package:fzwm_wxbc/views/login/login_page.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_pickers/pickers.dart';
import 'package:flutter_pickers/more_pickers/init_data.dart';
import 'package:flutter_pickers/style/default_style.dart';
import 'package:flutter_pickers/time_picker/model/date_mode.dart';
import 'package:flutter_pickers/time_picker/model/pduration.dart';
import 'package:flutter_pickers/time_picker/model/suffix.dart';
import 'dart:io';
import 'package:flutter_pickers/utils/check.dart';
import 'package:flutter/cupertino.dart';
import 'package:fzwm_wxbc/components/my_text.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

final String _fontFamily = Platform.isWindows ? "Roboto" : "";

class ReportDetail extends StatefulWidget {
  var FBillNo;

  ReportDetail({Key ?key, @required this.FBillNo}) : super(key: key);

  @override
  _ReportDetailState createState() => _ReportDetailState(FBillNo);
}

class _ReportDetailState extends State<ReportDetail> {
  var _remarkContent = new TextEditingController();
  GlobalKey<PartRefreshWidgetState> globalKey = GlobalKey();
  GlobalKey<TextWidgetState> textKey = GlobalKey();
  final _textNumber = TextEditingController();
  var checkItem;
  String FBillNo = '';
  String FName = '';
  String FNumber = '';
  String FDate = '';
  //产品名称
  var fMaterialName;
  //产品编码
  var fMaterialNumber;
  //工艺路线
  var fProcessName;
  //流程卡号
  var fOrderNo;
  //派工数量
  var fOrderQty;
  //汇报数量
  var fSubmitQty;
  //未汇报数量
  var fUnSubmitQty;
  //工序号
  var fProcessNo;
  //工序
  var fProcessID;
  var fProcessIDFDataValue;
  var isSubmit = false;
  var show = false;
  var isScanWork = false;
  var checkData;
  var checkDataChild;
  var selectData = {
    DateMode.YMD: '',
  };
  var stockList = [];
  List<dynamic> stockListObj = [];
  var empList = [];
  List<dynamic> empListObj = [];
  List<dynamic> orderDate = [];
  final divider = Divider(height: 1, indent: 20);
  final rightIcon = Icon(Icons.keyboard_arrow_right);
  final scanIcon = Icon(Icons.filter_center_focus);
  static const scannerPlugin =
  const EventChannel('com.shinow.pda_scanner/plugin');
   StreamSubscription ?_subscription;
  var _code;
  var _FNumber;
  var fBillNo;

  _ReportDetailState(FBillNo) {
    if (FBillNo != null) {
      this.fBillNo = FBillNo['value'];
      this.getOrderList();
    }else{
      this.fBillNo = '';
    }
  }

  @override
  void initState() {
    super.initState();
    EasyLoading.dismiss();
    /// 开启监听
    if (_subscription == null) {
      _subscription = scannerPlugin
          .receiveBroadcastStream()
          .listen(_onEvent, onError: _onError);
    }
    getEmpList();
    getStockList();
  }

  //获取仓库
  getStockList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BD_STOCK';
    userMap['FieldKeys'] = 'FStockID,FName,FNumber,FIsOpenLocation';
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    userMap['FilterString'] = "FForbidStatus = 'A' and FUseOrgId.FNumber ='"+deptData[1]+"'";
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    stockListObj = jsonDecode(res);
    stockListObj.forEach((element) {
      stockList.add(element[1]);
    });
  }
  //获取职员
  getEmpList() async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    userMap['FormId'] = 'BD_Empinfo';
    userMap['FilterString'] =
    "FForbidStatus='A' and FUseOrgId.FNumber ='"+deptData[1]+"'";
    userMap['FieldKeys'] = 'FUseOrgId.FNumber,FName,FNumber,FForbidStatus';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    empListObj = jsonDecode(res);
    empListObj.forEach((element) {
      empList.add(element[1]);
    });
  }

  void getWorkShop() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      if (sharedPreferences.getString('FWorkShopName') != null) {
        FName = sharedPreferences.getString('FWorkShopName');
        FNumber = sharedPreferences.getString('FWorkShopNumber');
        isScanWork = true;
      } else {
        isScanWork = false;
      }
    });
  }

  @override
  void dispose() {
    this._textNumber.dispose();
    super.dispose();

    /// 取消监听
    if (_subscription != null) {
      _subscription!.cancel();
    }
  }

  // 查询数据集合
  List hobby = [];
  List fNumber = [];
  getOrderList() async {
    EasyLoading.show(status: 'loading...');
    Map<String, dynamic> userMap = Map();
    print(fBillNo);
    userMap['FilterString'] = "fBillNo='$fBillNo'";
    userMap['FormId'] = 'kb7752aa5c53c4c9ea2f02a290942ac61';
    userMap['OrderString'] = 'FMaterialId.FNumber ASC';
    userMap['FieldKeys'] =
    'FBillNo,FCreateOrgId.FNumber,FCreateOrgId.FName,FDate,FEntity_FEntryId,FMaterialId.FNumber,FMaterialId.FName,FMaterialId.FSpecification,FOrderNo,FProcessLine,FOrderQty,FPlanStarDate,FPlanEndDate,FID,FQty,FSubmitQty,FUnSubmitQty,FProcessID.FNumber,FProcessID.FDataValue,FProcessNo,FKDNo,FPONumber,FLineName,FProcessNote,FProcessMulti,F_ora_BaseProperty1,FOrderEntryID,FDeptID.FNumber,FKDNo1.FNumber,FPONumber';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    orderDate = [];
    orderDate = jsonDecode(order);
    DateTime dateTime = DateTime.now();
    FDate = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    selectData[DateMode.YMD] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    if (orderDate.length > 0) {
      this.FBillNo = orderDate[0][0];
      //产品名称
      fMaterialName = orderDate[0][6];
      //产品编码
      fMaterialNumber = orderDate[0][5];
      //工艺路线
      fProcessName = orderDate[0][9];
      //流程卡号
      fOrderNo = orderDate[0][8];
      //派工数量
      fOrderQty = orderDate[0][10];
      //汇报数量
      fSubmitQty = orderDate[0][15];
      //未汇报数量
      fUnSubmitQty = orderDate[0][16];
      fProcessID = orderDate[0][17];
      fProcessIDFDataValue = orderDate[0][18];
      //工序号
      fProcessNo = orderDate[0][19];
      hobby = [];
      setState(() {
       /* this._getHobby();*/
        EasyLoading.dismiss();
      });
    } else {
      setState(() {
        EasyLoading.dismiss();
      });
      ToastUtil.showInfo('无数据');
    }
  }

  void _onEvent(event) async {
    /*  setState(() {*/
    _code = event;
    print("ChannelPage: $event");
    /*});*/
  }

  void _onError(Object error) {
    setState(() {
      _code = "扫描异常";
    });
  }

  Widget _item(title, var data, selectData, hobby, {String ?label,var stock}) {
    if (selectData == null) {
      selectData = "";
    }
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: ListTile(
            title: Text(title),
            onTap: () => data.length>0?_onClickItem(data, selectData, hobby, label: label,stock: stock):{ToastUtil.showInfo('无数据')},
            trailing: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              MyText(selectData.toString()=="" ? '暂无':selectData.toString(),
                  color: Colors.grey, rightpadding: 18),
              rightIcon
            ]),
          ),
        ),
        divider,
      ],
    );
  }

  Widget _dateItem(title, model) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: ListTile(
            title: Text(title),
            onTap: () {
              _onDateClickItem(model);
            },
            trailing: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              /*PartRefreshWidget(globalKey, () {*/
                //2、使用 创建一个widget
                /*return*/ MyText(
                    (PicketUtil.strEmpty(selectData[model])
                        ? '暂无'
                        : selectData[model])!,
                    color: Colors.grey,
                    rightpadding: 18),
              /*}),*/
              rightIcon
            ]),
          ),
        ),
        divider,
      ],
    );
  }

  void _onDateClickItem(model) {
    Pickers.showDatePicker(
      context,
      mode: model,
      suffix: Suffix.normal(),
      // selectDate: PDuration(month: 2),
      minDate: PDuration(year: 2020, month: 2, day: 10),
      maxDate: PDuration(second: 22),
      selectDate: (FDate == '' || FDate == null
          ? PDuration(year: 2021, month: 2, day: 10)
          : PDuration.parse(DateTime.parse(FDate))),
      // minDate: PDuration(hour: 12, minute: 38, second: 3),
      // maxDate: PDuration(hour: 12, minute: 40, second: 36),
      onConfirm: (p) {
        print('longer >>> 返回数据：$p');
        setState(() {
          switch (model) {
            case DateMode.YMD:
              selectData[model] = formatDate(DateFormat('yyyy-MM-dd').parse('${p.year}-${p.month}-${p.day}'), [yyyy, "-", mm, "-", dd,]);
              FDate = formatDate(DateFormat('yyyy-MM-dd').parse('${p.year}-${p.month}-${p.day}'), [yyyy, "-", mm, "-", dd,]);
              break;
          }
        });
      },
      // onChanged: (p) => print(p),
    );
  }

  void _onClickItem(var data, var selectData, hobby, {String ?label,var stock}) {
    Pickers.showSinglePicker(
      context,
      data: data,
      selectData: selectData,
      pickerStyle: DefaultPickerStyle(),
      suffix: label,
      onConfirm: (p) {
        print('longer >>> 返回数据：$p');
        print('longer >>> 返回数据类型：${p.runtimeType}');
        setState(() {
          hobby['value']['label'] = p;
        });;
        var elementIndex = 0;
        data.forEach((element) {
          if (element == p) {
            hobby['value']['value'] = empListObj[elementIndex][2];
          }
          elementIndex++;
        });
      },
    );
  }

  List<Widget> _getHobby() {
    List<Widget> tempList = [];
    for (int i = 0; i < this.hobby.length; i++) {
      List<Widget> comList = [];
      for (int j = 0; j < this.hobby[i].length; j++) {
        if (!this.hobby[i][j]['isHide']) {
          if (j == 2) {
            comList.add(
              _item('人员:', empList, this.hobby[i][j]['value']['label'],
                  this.hobby[i][j],stock:this.hobby[i]),
            );
          }else{
            comList.add(
              Column(children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                      title: Text(this.hobby[i][j]["title"] +
                          '：' +
                          this.hobby[i][j]["value"]["label"].toString()),
                      trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: new Icon(Icons.filter_center_focus),
                              tooltip: '点击扫描',
                              onPressed: () {
                                this._textNumber.text =
                                this.hobby[i][j]["value"]["label"];
                                this._FNumber =
                                this.hobby[i][j]["value"]["label"];
                                checkData = i;
                                checkDataChild = j;
                                scanDialog();
                                if (this.hobby[i][j]["value"]["label"] != 0) {
                                  this._textNumber.value =
                                      _textNumber.value.copyWith(
                                        text: this.hobby[i][j]["value"]["label"],
                                      );
                                }
                              },
                            ),
                          ])),
                ),
                divider,
              ]),
            );
          }
        }
      }
      tempList.add(
        SizedBox(height: 10),
      );
      tempList.add(
        Column(
          children: comList,
        ),
      );
    }
    return tempList;
  }

  //调出弹窗 扫码
  void scanDialog() {
    showDialog<Widget>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              alignment: Alignment.center,
              color: Colors.white,
              child: Column(
                children: <Widget>[
                  /*  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('输入数量',
                        style: TextStyle(
                            fontSize: 16, decoration: TextDecoration.none)),
                  ),*/
                  Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Card(
                          child: Column(children: <Widget>[
                            TextField(
                              style: TextStyle(color: Colors.black87),
                              keyboardType: TextInputType.number,
                              controller: this._textNumber,
                              decoration: InputDecoration(hintText: "输入"),
                              onChanged: (value) {
                                setState(() {
                                  this._FNumber = value;
                                });
                              },
                            ),
                          ]))),
                  Padding(
                    padding: EdgeInsets.only(top: 15, bottom: 8),
                    child: FlatButton(
                        color: Colors.grey[100],
                        onPressed: () {
                          // 关闭 Dialog
                          Navigator.pop(context);
                          setState(() {
                            print((double.parse(_FNumber)+double.parse(this.hobby[checkData][checkDataChild==0?1:0]["value"]["label"])));
                            if((double.parse(_FNumber)+double.parse(this.hobby[checkData][checkDataChild==0?1:0]["value"]["label"])) <= this.fOrderQty){
                              this.hobby[checkData][checkDataChild]["value"]
                              ["label"] = _FNumber;
                              this.hobby[checkData][checkDataChild]['value']
                              ["value"] = _FNumber;
                            }else{
                              ToastUtil.showInfo('汇报数量不能大于派工数量');
                            }
                          });
                        },
                        child: Text(
                          '确定',
                        )),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    ).then((val) {
      print(val);
    });
  }


  //保存
  saveOrder() async {
    if (this.hobby.length > 0) {
      setState(() {
        this.isSubmit = true;
      });
      Map<String, dynamic> dataMap = Map();
      dataMap['formid'] = 'k8c99135d8f0b4925a36527567b0cf632';
      Map<String, dynamic> orderMap = Map();
      orderMap['NeedReturnFields'] = [];
      orderMap['IsDeleteEntry'] = false;
      Map<String, dynamic> Model = Map();
      Model['FID'] = 0;
      Model['FDate'] = FDate;
      Model['FCreateOrgId'] = {"FNumber": orderDate[0][1].toString()};
      Model['FMaterialId'] = {
        "FNumber": fMaterialNumber
      };
      Model['FProcessID'] = {
        "FNumber": fProcessID
      };
      Model['FKDNo'] = orderDate[0][25];
      Model['FOrderNo'] = orderDate[0][29];
      Model['F_ora_Text1'] = fOrderNo;
      Model['FProcessName'] = fProcessName;
      Model['FPlanStarDate'] = orderDate[0][11];
      Model['FPONumber'] = orderDate[0][21];
      Model['FLineName'] = orderDate[0][22];
      Model['FProcessNo'] = fProcessNo;
      Model['FProcessNote'] = orderDate[0][23];
      Model['FProcessMulti'] = orderDate[0][24];
      Model['FDeptID'] = {
        "FNUMBER": orderDate[0][27]
      };Model['FKDNo1'] = {
        "FNumber": orderDate[0][28]
      };
      var FEntity = [];
      var hobbyIndex = 0;
      this.hobby.forEach((element) {
        if (element[0]['value']['value'] != '0' ||
            element[1]['value']['value'] != '0') {
          Map<String, dynamic> FEntityItem = Map();
          /*FEntityItem['FMaterialId'] = {
            "FNumber": fMaterialNumber
          };
          FEntityItem['FProcessID'] = {
            "FNumber": fProcessID
          };*/
          FEntityItem['FOKQTY'] = element[0]['value']['value'];
          FEntityItem['FBadQty'] = element[1]['value']['value'];
          FEntityItem['FEmpID'] = {
            "FSTAFFNUMBER": element[2]['value']['value']
          };
          /* FEntityItem['FKDNo'] = orderDate[0][25];
          FEntityItem['FProcessName'] = fProcessName;
          FEntityItem['FPONumber'] = orderDate[0][21];
          FEntityItem['FLineName'] = orderDate[0][22];
          FEntityItem['FProcessNo'] = fProcessNo;
          FEntityItem['FProcessNote'] = orderDate[0][23];
          FEntityItem['FProcessMulti'] = orderDate[0][24];*/
          FEntity.add(FEntityItem);
        }
        hobbyIndex++;
      });
      if(FEntity.length==0){
        this.isSubmit = false;
        ToastUtil.showInfo('请输入数量');
        return;
      }
      Model['FEntity'] = FEntity;
      orderMap['Model'] = Model;
      dataMap['data'] = orderMap;
      print(jsonEncode(dataMap));
      String order = await SubmitEntity.save(dataMap);
      var res = jsonDecode(order);
      print(res);
      if (res['Result']['ResponseStatus']['IsSuccess']) {
        Map<String, dynamic> submitMap = Map();
        submitMap = {
          "formid": "k8c99135d8f0b4925a36527567b0cf632",
          "data": {
            'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
          }
        };
        //提交
        HandlerOrder.orderHandler(context,submitMap,1,"k8c99135d8f0b4925a36527567b0cf632",SubmitEntity.submit(submitMap)).then((submitResult) {
          if(submitResult){
            //审核
            HandlerOrder.orderHandler(context,submitMap,1,"k8c99135d8f0b4925a36527567b0cf632",SubmitEntity.audit(submitMap)).then((auditResult) {
              if(auditResult){
                //提交清空页面
                setState(() {
                  this.hobby = [];
                  this.orderDate = [];
                  this.FBillNo = '';
                  ToastUtil.showInfo('提交成功');
                  Navigator.of(context).pop("refresh");
                });
              }else{
                //失败后反审
                HandlerOrder.orderHandler(context,submitMap,0,"k8c99135d8f0b4925a36527567b0cf632",SubmitEntity.unAudit(submitMap)).then((unAuditResult) {
                  if(unAuditResult){
                    this.isSubmit = false;
                  }else{
                    this.isSubmit = false;
                  }
                });
              }
            });
          }else{
            this.isSubmit = false;
          }
        });
      } else {
        setState(() {
          this.isSubmit = false;
          ToastUtil.errorDialog(context,
              res['Result']['ResponseStatus']['Errors'][0]['Message']);
        });
      }
    } else {
      ToastUtil.showInfo('无提交数据');
    }
  }
  /// 确认提交提示对话框
  Future<void> _showSumbitDialog() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("是否提交"),
            actions: <Widget>[
              new FlatButton(
                child: new Text('不了'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              new FlatButton(
                child: new Text('确定'),
                onPressed: () {
                  Navigator.of(context).pop();
                  saveOrder();
                },
              )
            ],
          );
        });
  }
  @override
  Widget build(BuildContext context) {
    return FlutterEasyLoading(
      child: Scaffold(
          appBar: AppBar(
            title: Text("工序汇报"),
            centerTitle: true,
            leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: (){
              Navigator.of(context).pop("refresh");
            }),
          ),
          body: Column(
            children: <Widget>[
              Expanded(
                child: ListView(children: <Widget>[
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text("工艺路线：$fProcessName"),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text("流程卡号：$fOrderNo"),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text("产品名称：$fMaterialName"),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text("产品编码：$fMaterialNumber"),
                        ),
                      ),
                      divider,
                    ],
                  ), Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text("工序：$fProcessIDFDataValue"),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text("派工数量：$fOrderQty"),
                        ),
                      ),
                      divider,
                    ],
                  ), Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text("汇报数量：$fSubmitQty"),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          /* title: TextWidget(FBillNoKey, '生产订单：'),*/
                          title: Text("未汇报数量：$fUnSubmitQty"),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  _dateItem('日期：', DateMode.YMD),

                  Column(
                    children: this._getHobby(),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: RaisedButton(
                        padding: EdgeInsets.all(15.0),
                        child: Text("增加行"),
                        color: Colors.orange,
                        textColor: Colors.white,
                        onPressed: () async {
                          List arr = [];
                          arr.add({
                            "title": "合格数量",
                            "name": "FOKQTY",
                            "isHide": false,
                            "value": {"label": "0", "value": "0"}
                          });
                          arr.add({
                            "title": "不合格数量",
                            "name": "FBadQty",
                            "isHide": false,
                            "value": {"label": "0", "value": "0"}
                          });arr.add({
                            "title": "人员",
                            "name": "",
                            "isHide": false,
                            "value": {"label": "", "value": ""}
                          });
                          hobby.add(arr);
                          setState(() {
                            this._getHobby();
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RaisedButton(
                        padding: EdgeInsets.all(15.0),
                        child: Text("保存"),
                        color: this.isSubmit?Colors.grey:Theme.of(context).primaryColor,
                        textColor: Colors.white,
                        onPressed: () async=> this.isSubmit ? null : _showSumbitDialog(),
                      ),
                    ),
                  ],
                ),
              )
            ],
          )),
    );
  }
}
