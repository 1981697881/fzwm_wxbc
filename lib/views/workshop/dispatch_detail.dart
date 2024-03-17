import 'dart:convert';
import 'package:date_format/date_format.dart';
import 'package:fzwm_wxbc/model/currency_entity.dart';
import 'package:fzwm_wxbc/model/submit_entity.dart';
import 'package:fzwm_wxbc/utils/handler_order.dart';
import 'package:fzwm_wxbc/utils/refresh_widget.dart';
import 'package:fzwm_wxbc/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_pickers/pickers.dart';
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

class DispatchDetail extends StatefulWidget {
  var FBillNo;

  DispatchDetail({Key ?key, @required this.FBillNo}) : super(key: key);

  @override
  _DispatchDetailState createState() => _DispatchDetailState(FBillNo);
}

class _DispatchDetailState extends State<DispatchDetail> {
  var _remarkContent = new TextEditingController();
  GlobalKey<PartRefreshWidgetState> globalDateKey = GlobalKey();

  /*GlobalKey<TextWidgetState> textKey = GlobalKey();*/
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

  //已派工数量
  var fBaseQty;

  //未派工数量
  var fRemainOutQty;
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
  var departmentList = [];
  List<dynamic> departmentListObj = [];
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
  _DispatchDetailState(FBillNo) {
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
    /// 开启监听
    if (_subscription == null) {
      _subscription = scannerPlugin
          .receiveBroadcastStream()
          .listen(_onEvent, onError: _onError);
    }
    EasyLoading.dismiss();
   /* getWorkShop();*/
    getDepartmentList();
  }
  //获取部门
  getDepartmentList() async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    userMap['FormId'] = 'BD_Department';
    userMap['FieldKeys'] = 'FUseOrgId,FName,FNumber';
    userMap['FilterString'] = "FUseOrgId.FNumber ='"+deptData[1]+"'";
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    departmentListObj = jsonDecode(res);
    departmentListObj.forEach((element) {
      departmentList.add(element[1]);
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
    userMap['FilterString'] = "fBillNo='$fBillNo'";
    userMap['FormId'] = 'k9917093a9fd147b7a68c76f6780b8593';
    userMap['OrderString'] = 'FMaterialId.FNumber ASC';
    userMap['FieldKeys'] =
        'FBillNo,FCreateOrgId.FNumber,FCreateOrgId.FName,FDate,FEntity_FEntryId,FMaterialId.FNumber,FMaterialId.FName,FMaterialId.FSpecification,FOrderNo,FProcessName,FPlanQty,FPlanStarDate,FPlanEndDate,FID,FQty,FOrderQty,FUnOrderQty,FProcessID.FNumber,FProcessID.FDataValue,FProcessNo,FKDNo1.FNumber,FOrderEntryID,FProcessNote,FProcessMulti,FProcessTypeID,FKDNo';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    orderDate = [];
    orderDate = jsonDecode(order);
    DateTime dateTime = DateTime.now();
    FDate = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    if (orderDate.length > 0) {
      this.FBillNo = orderDate[0][0];
      //产品名称
      fMaterialName = orderDate[0][6];
      //产品编码
      fMaterialNumber = orderDate[0][5];
      /*//工艺路线
      fProcessName = orderDate[0][9];
      //流程卡号
      fOrderNo = orderDate[0][8];
      //已派工数量
      fBaseQty = orderDate[0][15];
      //未派工数量
      fRemainOutQty = orderDate[0][16];
      fProcessID = orderDate[0][17];
      fProcessIDFDataValue = orderDate[0][18];
      //工序号
      fProcessNo = orderDate[0][19];*/
      hobby = [];
      orderDate.forEach((value) {
        List arr = [];
        arr.add({
          "title": "工艺路线",
          "name": "fProcessName",
          "isHide": false,
          "value": {"label": value[9], "value": value[9]}
        });
        arr.add({
          "title": "流程卡号",
          "name": "fOrderNo",
          "isHide": false,
          "value": {"label": value[8], "value": value[8]}
        });
        arr.add({
          "title": "产品名称",
          "name": "fMaterialName",
          "isHide": false,
          "value": {"label": value[6], "value": value[5]}
        });
        arr.add({
          "title": "工序",
          "name": "",
          "isHide": false,
          "value": {"label": value[18], "value": value[17]}
        });
        arr.add({
          "title": "已派工数量",
          "name": "",
          "isHide": false,
          "value": {"label": value[15], "value": value[15]}
        });
        arr.add({
          "title": "未派工数量",
          "isHide": false,
          "name": "",
          "value": {"label": value[16], "value": value[16]}
        });
        arr.add({
          "title": "开工日期",
          "name": "",
          "isHide": false,
          "value": {"label": formatDate(DateTime.now(), [
            yyyy,
            "-",
            mm,
            "-",
            dd,
          ]), "value": formatDate(DateTime.now(), [
            yyyy,
            "-",
            mm,
            "-",
            dd,
          ])}
        });
        arr.add({
          "title": "部门",
          "name": "",
          "isHide": false,
          "value": {"label": "", "value": ""}
        });
        arr.add({
          "title": "派工量",
          "name": "",
          "isHide": false,
          "value": {"label": "0", "value": "0"}
        });
        arr.add({
          "title": "操作",
          "name": "",
          "isHide": false,
          "value": {"label": "", "value": ""}
        });
        hobby.add(arr);
      });
      setState(() {
        EasyLoading.dismiss();
        this._getHobby();
      });
    } else {
      setState(() {
        EasyLoading.dismiss();
        this._getHobby();
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

  Widget _dateItem(title, model,selectData, hobby) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: ListTile(
            title: Text(title),
            onTap: () {
              _onDateClickItem(model,hobby);
            },
            trailing: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                //2、使用 创建一个widget
            MyText(
                PicketUtil.strEmpty(selectData)
                    ? '暂无'
                    : selectData,
                    color: Colors.grey,
                    rightpadding: 18),
              rightIcon
            ]),
          ),
        ),
        divider,
      ],
    );
  }

  void _onDateClickItem(model,hobby) {
    Pickers.showDatePicker(
      context,
      mode: model,
      suffix: Suffix.normal(),
      // selectDate: PDuration(month: 2),
      minDate: PDuration(year: 2020, month: 2, day: 10),
      maxDate: PDuration(second: 22),
      selectDate: (hobby['value']['value'] == '' || hobby['value']['value'] == null
          ? PDuration(year: 2021, month: 2, day: 10)
          : PDuration.parse(DateTime.parse(hobby['value']['value']))),
      // minDate: PDuration(hour: 12, minute: 38, second: 3),
      // maxDate: PDuration(hour: 12, minute: 40, second: 36),
      onConfirm: (p) {
        print('longer >>> 返回数据：$p');
        setState(() {
          hobby['value']['label'] = formatDate(
              DateFormat('yyyy-MM-dd')
                  .parse('${p.year}-${p.month}-${p.day}'),
              [
                yyyy,
                "-",
                mm,
                "-",
                dd,
              ]);
          hobby['value']['value'] = formatDate(
              DateFormat('yyyy-MM-dd')
                  .parse('${p.year}-${p.month}-${p.day}'),
              [
                yyyy,
                "-",
                mm,
                "-",
                dd,
              ]);
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
          setState(() {
          hobby['value']['label'] = p;
        });
          var elementIndex = 0;
          departmentList.forEach((element) {
            if (element == p) {
              hobby['value']['value'] = departmentListObj[elementIndex][2];
            }
            elementIndex++;
          });
          print(hobby);
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
          if (j == 8) {
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
          } else if (j == 6) {
            comList.add(
              _dateItem('开工日期：', DateMode.YMD,this.hobby[i][j]['value']['label'], this.hobby[i][j]),
            );
          }else if (j == 7) {
            comList.add(
              _item(
                  '部门:', departmentList, this.hobby[i][j]['value']['label'], this.hobby[i][j]),
            );
          }else if (j == 9) {
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
                            new FlatButton(
                              color: Colors.red,
                              textColor: Colors.white,
                              child: new Text('删除'),
                              onPressed: () {
                                this.hobby.removeAt(i);
                                setState(() {});
                              },
                            )
                          ])),
                ),
                divider,
              ]),
            );
          } else {
            comList.add(
              Column(children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                    title: Text(this.hobby[i][j]["title"] +
                        '：' +
                        this.hobby[i][j]["value"]["label"].toString()),
                    trailing:
                        Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                      /* MyText(orderDate[i][j],
                        color: Colors.grey, rightpadding: 18),*/
                    ]),
                  ),
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
                            this.hobby[checkData][checkDataChild]["value"]
                                ["label"] = _FNumber;
                            this.hobby[checkData][checkDataChild]['value']
                                ["value"] = _FNumber;
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
      //获取登录信息
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      var menuData = sharedPreferences.getString('MenuPermissions');
      var deptData = jsonDecode(menuData)[0];
      Map<String, dynamic> dataMap = Map();
      dataMap['formid'] = 'kb7752aa5c53c4c9ea2f02a290942ac61';
      Map<String, dynamic> orderMap = Map();
      orderMap['NeedReturnFields'] = [];
      orderMap['IsDeleteEntry'] = false;
      Map<String, dynamic> Model = Map();
      Model['FID'] = 0;
      Model['FDate'] = FDate;
      Model['FCreateOrgId'] = {"FNumber": deptData[1]};
      Model['F_ora_Assistant'] = {
        "FNumber": orderDate[0][20]
      };
      var FEntity = [];
      var hobbyIndex = 0;
      NumberFormat formatter = NumberFormat("00");
      this.hobby.forEach((element) {
        if (element[8]['value']['value'] != '0' &&
            element[7]['value']['value'] != '') {
          Map<String, dynamic> FEntityItem = Map();
          FEntityItem['FMaterialId'] = {
            "FNUMBER": fMaterialNumber
          };
          FEntityItem['FDeptID'] = {
            "FNUMBER": element[7]['value']['value']
          };
          FEntityItem['FProcessID'] = {
            "FNumber": element[3]['value']['value']
          };
          /*FEntityItem['FReturnType'] = 1;*/
          FEntityItem['FOrderQty'] = element[8]['value']['value'];
          FEntityItem['FUnOrderQty'] = element[5]['value']['value'];
          FEntityItem['FPlanStarDate'] = element[6]['value']['value'];
          FEntityItem['FPlanEndDate'] = element[6]['value']['value'];
          FEntityItem['FPlanSDate'] = element[6]['value']['value'];
          FEntityItem['FPlanEDate'] = element[6]['value']['value'];
          FEntityItem['FProcessLine'] = element[0]['value']['value'];
          FEntityItem['FOrderNo'] = element[1]['value']['value'];
          FEntityItem['FProcessNote'] = orderDate[hobbyIndex][22];
          FEntityItem['FProcessMulti'] = orderDate[hobbyIndex][23];
          FEntityItem['FProcessTypeID'] = {
            "FNumber": orderDate[hobbyIndex][24]
          };
          FEntityItem['FKDNo'] = orderDate[hobbyIndex][25];
          FEntityItem['FKDNo1'] = {
            "FNumber": orderDate[hobbyIndex][20]
          };
          FEntityItem['FOrderEntryID'] = orderDate[hobbyIndex][21];
          FEntityItem['FPONumber'] = element[1]['value']['value']+'-'+formatter.format(int.parse(orderDate[hobbyIndex][21]));
          FEntityItem['FProcessNo'] = orderDate[hobbyIndex][19];
          FEntity.add(FEntityItem);
        }
        hobbyIndex++;
      });
      if (FEntity.length == 0) {
        this.isSubmit = false;
        ToastUtil.showInfo('请输入数量和部门');
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
          "formid": "kb7752aa5c53c4c9ea2f02a290942ac61",
          "data": {
            'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
          }
        };
        //提交
        HandlerOrder.orderHandler(
                context,
                submitMap,
                1,
                "kb7752aa5c53c4c9ea2f02a290942ac61",
                SubmitEntity.submit(submitMap))
            .then((submitResult) {
          if (submitResult) {
            //审核
            HandlerOrder.orderHandler(
                    context,
                    submitMap,
                    1,
                    "kb7752aa5c53c4c9ea2f02a290942ac61",
                    SubmitEntity.audit(submitMap))
                .then((auditResult) {
              if (auditResult) {
                //提交清空页面
                setState(() {
                  this.hobby = [];
                  this.orderDate = [];
                  this.FBillNo = '';
                  ToastUtil.showInfo('提交成功');
                  Navigator.of(context).pop("refresh");
                });
              } else {
                //失败后反审
                HandlerOrder.orderHandler(
                        context,
                        submitMap,
                        0,
                        "kb7752aa5c53c4c9ea2f02a290942ac61",
                        SubmitEntity.unAudit(submitMap))
                    .then((unAuditResult) {
                  if (unAuditResult) {
                    this.isSubmit = false;
                  }else{
                    this.isSubmit = false;
                  }
                });
              }
            });
          } else {
            this.isSubmit = false;
          }
        });
      } else {
        setState(() {
          this.isSubmit = false;
          ToastUtil.errorDialog(
              context, res['Result']['ResponseStatus']['Errors'][0]['Message']);
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
            title: Text("工序派工"),
            centerTitle: true,
            leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop("refresh");
                }),
          ),
          body: Column(
            children: <Widget>[
              Expanded(
                child: ListView(children: <Widget>[
                 /* Column(
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
                          title: Text("已派工数量：$fBaseQty"),
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
                          *//* title: TextWidget(FBillNoKey, '生产订单：'),*//*
                          title: Text("未派工数量：$fRemainOutQty"),
                        ),
                      ),
                      divider,
                    ],
                  ),*/
                  /*_dateItem('开工日期：', DateMode.YMD),*/
                  /* Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: TextField(
                            //最多输入行数
                            maxLines: 1,
                            decoration: InputDecoration(
                              hintText: "备注",
                              //给文本框加边框
                              border: OutlineInputBorder(),
                            ),
                            controller: this._remarkContent,
                            //改变回调
                            onChanged: (value) {
                              setState(() {
                                _remarkContent.value = TextEditingValue(
                                  text: value,
                                  selection: TextSelection.fromPosition(TextPosition(
                                      affinity: TextAffinity.downstream,
                                      offset: value.length)));
                              });
                            },
                          ),
                        ),
                      ),
                      divider,
                    ],
                  ),*/
                  Column(
                    children: this._getHobby(),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Row(
                  children: <Widget>[
                    /*Expanded(
                      child: RaisedButton(
                        padding: EdgeInsets.all(15.0),
                        child: Text("增加行"),
                        color: Colors.orange,
                        textColor: Colors.white,
                        onPressed: () async {
                          List arr = [];
                          arr.add({
                            "title": "部门",
                            "name": "FPlanStarDate",
                            "isHide": false,
                            "value": {"label": "", "value": ""}
                          });
                          arr.add({
                            "title": "派工量",
                            "name": "FPlanEndDate",
                            "isHide": false,
                            "value": {"label": "0", "value": "0"}
                          });
                          hobby.add(arr);
                          setState(() {
                            this._getHobby();
                          });
                        },
                      ),
                    ),*/
                    Expanded(
                      child: RaisedButton(
                        padding: EdgeInsets.all(15.0),
                        child: Text("保存"),
                        color: this.isSubmit
                            ? Colors.grey
                            : Theme.of(context).primaryColor,
                        textColor: Colors.white,
                        onPressed: () async =>
                            this.isSubmit ? null : _showSumbitDialog(),
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
