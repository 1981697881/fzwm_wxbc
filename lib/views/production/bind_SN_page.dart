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
import 'package:qrscan/qrscan.dart' as scanner;
class BindSNPage extends StatefulWidget {
  var FBillNo;

  BindSNPage({Key? key, @required this.FBillNo}) : super(key: key);

  @override
  _BindSNPageState createState() => _BindSNPageState(FBillNo);
}

class _BindSNPageState extends State<BindSNPage> {
  var _remarkContent = new TextEditingController();
  GlobalKey<TextWidgetState> textKey = GlobalKey();
  GlobalKey<PartRefreshWidgetState> globalKey = GlobalKey();

  final _textNumber = TextEditingController();
  var checkItem;
  String FBillNo = '';
  String FMoBillNo = '';
  String FSaleOrderNo = '';
  String FName = '';
  String FNumber = '';
  String FPcs = '';
  String FSn = '';
  String FDate = '';
  int FID = 0;
  var customerName;
  var customerNumber;
  var departmentName;
  var departmentNumber;
  var typeName;
  var typeNumber;
  var show = false;
  var isSubmit = false;
  var isScanWork = false;
  var checkData;
  var checkDataChild;
  var selectData = {
    DateMode.YMD: "",
  };
  var stockList = [];
  List<dynamic> stockListObj = [];
  var typeList = [];
  List<dynamic> typeListObj = [];
  var departmentList = [];
  List<dynamic> departmentListObj = [];
  var customerList = [];
  List<dynamic> customerListObj = [];
  List<dynamic> orderDate = [];
  List<dynamic> materialDate = [];
  List<dynamic> collarOrderDate = [];
  final divider = Divider(height: 1, indent: 20);
  final rightIcon = Icon(Icons.keyboard_arrow_right);
  final scanIcon = Icon(Icons.filter_center_focus);
  static const scannerPlugin =
      const EventChannel('com.shinow.pda_scanner/plugin');
  StreamSubscription? _subscription;
  var _code;
  var _FNumber;
  var fBillNo;
  var fBarCodeList;

  _BindSNPageState(FBillNo) {
    if (FBillNo != null) {
      this.fBillNo = FBillNo['value'];
      this.getOrderList();
    } else {
      this.fBillNo = '';
    }
  }

  @override
  void initState() {
    super.initState();
    DateTime dateTime = DateTime.now();
    var nowDate = "${dateTime.year}-${dateTime.month}-${dateTime.day}";
    selectData[DateMode.YMD] = nowDate;
    EasyLoading.dismiss();

    /// 开启监听
    if (_subscription == null) {
      _subscription = scannerPlugin
          .receiveBroadcastStream()
          .listen(_onEvent, onError: _onError);
    }
    /*getWorkShop();*/
    getStockList();
    /* getTypeList();*/
    getCustomer();
    getDepartmentList();
    FDate = formatDate(DateTime.now(), [
      yyyy,
      "-",
      mm,
      "-",
      dd,
    ]);
    selectData[DateMode.YMD] = formatDate(DateTime.now(), [
      yyyy,
      "-",
      mm,
      "-",
      dd,
    ]);
    /*_onEvent("247230329291267");*/
   /* _onEvent("34TI4lY5kQMeeeRftiNVZbNeM4@GyjUf9huSIkwn@km8QDmVaYtheQ==");
    Future.delayed(Duration(milliseconds: 5000), () {
      _onEvent(
          "68051080058-20230612-202306120021");
    });Future.delayed(Duration(milliseconds: 5000), () {
      _onEvent(
          "68051080058-20230612-202306120021");
    });*//*
    Future.delayed(Duration(milliseconds: 5000), () {
      _onEvent(
          "u+zeGAN0HjGjdsx84p4bdIrU++iby6ydDvEJ+Xb9Zn8AiFgOj@DPQg==");
    });*/
  }

  //获取部门
  getDepartmentList() async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    userMap['FormId'] = 'BD_Department';
    userMap['FilterString'] = "FUseOrgId.FNumber ='" + deptData[1] + "'";
    userMap['FieldKeys'] = 'FUseOrgId,FName,FNumber';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    departmentListObj = jsonDecode(res);
    departmentListObj.forEach((element) {
      departmentList.add(element[1]);
    });
  }

  //获取仓库
  getStockList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BD_STOCK';
    userMap['FieldKeys'] = 'FStockID,FName,FNumber,FIsOpenLocation';
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    userMap['FilterString'] = "FUseOrgId.FNumber ='" + deptData[1] + "'";
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    stockListObj = jsonDecode(res);
    stockListObj.forEach((element) {
      stockList.add(element[1]);
    });
  }

  //获取出库类别
  getTypeList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BOS_ASSISTANTDATA_DETAIL';
    userMap['FieldKeys'] = 'FId,FDataValue,FNumber';
    userMap['FilterString'] = "FId ='5fd716ed883534' and FForbidStatus='A'";
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    typeListObj = jsonDecode(res);
    typeListObj.forEach((element) {
      typeList.add(element[1]);
    });
  }

  //获取客户
  getCustomer() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BD_Customer';
    userMap['FieldKeys'] = 'FCUSTID,FName,FNumber';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    customerListObj = jsonDecode(res);
    customerListObj.forEach((element) {
      customerList.add(element[1]);
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
    Map<String, dynamic> userMap = Map();
    print(fBillNo);
    userMap['FilterString'] = "FRemainStockINQty>0 and FBillNo='$fBillNo'";
    userMap['FormId'] = 'PUR_PurchaseOrder';
    userMap['OrderString'] = 'FMaterialId.FNumber ASC';
    userMap['FieldKeys'] =
        'FBillNo,FSupplierId.FNumber,FSupplierId.FName,FDate,FDetailEntity_FEntryId,FMaterialId.FNumber,FMaterialId.FName,FMaterialId.FSpecification,FPurOrgId.FNumber,FPurOrgId.FName,FUnitId.FNumber,FUnitId.FName,FInStockQty,FSrcBillNo,FID';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    orderDate = [];
    orderDate = jsonDecode(order);
    FDate = formatDate(DateTime.now(), [
      yyyy,
      "-",
      mm,
      "-",
      dd,
    ]);
    selectData[DateMode.YMD] = formatDate(DateTime.now(), [
      yyyy,
      "-",
      mm,
      "-",
      dd,
    ]);
    if (orderDate.length > 0) {
      hobby = [];
      orderDate.forEach((value) {
        List arr = [];
        fNumber.add(value[5]);
        arr.add({
          "title": "物料名称",
          "name": "FMaterial",
          "isHide": false,
          "value": {
            "label": value[6] + "- (" + value[5] + ")",
            "value": value[5],
            "barcode": []
          }
        });
        arr.add({
          "title": "规格型号",
          "isHide": false,
          "name": "FMaterialIdFSpecification",
          "value": {"label": value[7], "value": value[7]}
        });
        arr.add({
          "title": "单位名称",
          "name": "FUnitId",
          "isHide": false,
          "value": {"label": value[11], "value": value[10]}
        });
        arr.add({
          "title": "出库数量",
          "name": "FRealQty",
          "isHide": false,
          "value": {"label": value[12], "value": value[12]}
        });
        arr.add({
          "title": "仓库",
          "name": "FStockID",
          "isHide": false,
          "value": {"label": "", "value": ""}
        });
        arr.add({
          "title": "批号",
          "name": "FLot",
          "isHide": false,
          "value": {"label": "", "value": ""}
        });
        arr.add({
          "title": "仓位",
          "name": "FStockLocID",
          "isHide": false,
          "value": {"label": "", "value": "", "hide": false}
        });
        arr.add({
          "title": "加工费",
          "name": "",
          "isHide": false,
          "value": {"label": "", "value": "0"}
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

  /// 数据确认弹窗
  Future<void> _showInventoryDialog(snData) async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("当时扫描条码已存在单据中，是否提取？ 注意！提取数据将清空当前列表。",
                style: TextStyle(fontSize: 14.0)),
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
                  this.hobby = [];
                  setState(() {
                    this.fBillNo = snData[0][1];
                    this.FNumber = snData[0][4];
                    this.FName = snData[0][5];
                    this.FPcs = snData[0][6];
                    this.FSn = snData[0][7];
                    this.FMoBillNo = snData[0][7];
                    this.FID = snData[0][0];
                    var number = 0;

                    if (number == 0) {
                      snData.forEach((value) {
                        List arr = [];
                        arr.add({
                          "title": "物料名称",
                          "name": "FMaterial",
                          "isHide": false,
                          "value": {
                            "label": value[14] + "- (" + value[13] + ")",
                            "value": value[13],
                            "barcode": [value[17]]
                          }
                        });
                        arr.add({
                          "title": "规格型号",
                          "isHide": false,
                          "name": "FMaterialIdFSpecification",
                          "value": {"label": value[15], "value": value[15]}
                        });
                        arr.add({
                          "title": "数量",
                          "name": "FRealQty",
                          "isHide": false,
                          "value": {"label": "1", "value": "1"}
                        });
                        arr.add({
                          "title": "批号",
                          "name": "FLot",
                          "isHide": false,
                          "value": {"label": value[16], "value": value[16]}
                        });
                        arr.add({
                          "title": "SN",
                          "name": "SN",
                          "isHide": false,
                          "value": {"label": value[17], "value": value[17]}
                        });
                        arr.add({
                          "title": "生产订单号",
                          "name": "",
                          "isHide": false,
                          "value": {"label": value[10], "value": value[10]}
                        });
                        hobby.add(arr);
                      });
                    }
                    setState(() {
                      EasyLoading.dismiss();
                      this._getHobby();
                    });
                  });
                },
              )
            ],
          );
        });
  }

  void _onEvent(event) async {
    EasyLoading.show(status: 'loading...');
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var deptData = sharedPreferences.getString('menuList');
    var menuList = new Map<dynamic, dynamic>.from(jsonDecode(deptData));
    fBarCodeList = menuList['FBarCodeList'];

    _code = event;
    if (event == "") {
      return;
    }
    if (fBarCodeList == 1) {
      if(event.split('-').length>2){
        Map<String, dynamic> userMap = Map();
        SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
        var menuData = sharedPreferences.getString('MenuPermissions');
        var deptData = jsonDecode(menuData)[0];
        userMap['FilterString'] = "F_UYEP_GYSTM='"+event.split('-')[0]+"' and FForbidStatus = 'A' and FUseOrgId.FNumber = '"+deptData[1]+"'";
        userMap['FormId'] = 'BD_MATERIAL';
        userMap['FieldKeys'] =
        'FMATERIALID,FName,FNumber,FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FIsBatchManage';/*,SubHeadEntity1.FStoreUnitID.FNumber*/
        Map<String, dynamic> dataMap = Map();
        dataMap['data'] = userMap;
        String order = await CurrencyEntity.polling(dataMap);
        var barcodeData = jsonDecode(order);
        if (barcodeData.length > 0) {
          Map<String, dynamic> snMapT = Map();
          snMapT['FilterString'] =
              "FEntryBarcodeEn='" + event + "' and FDocumentStatus in ('A','D')";
          snMapT['FormId'] = 'QDEP_PDA_SNBind';
          snMapT['FieldKeys'] =
          'FID,FBillNo,FDocumentStatus,FBindDate,FMATERIALID.FNUMBER,FMaterialName,FMaterialSpec,FMOBillNo,FEntity_FEntryId,FEntryBindDate,FEntryMoBillNo,FBindQty,FEntryMaterialID.FNUMBER,FEntryMaterialName,FEntryMaterialSpec,FEntryBatchNo,FEntrySN,FEntryBarcodeEn';
          Map<String, dynamic> datasnMapT = Map();
          datasnMapT['data'] = snMapT;
          String orderSnT = await CurrencyEntity.polling(datasnMapT);
          var snDataT = jsonDecode(orderSnT);
          if (snDataT.length > 0) {
            Map<String, dynamic> snMap = Map();
            snMap['FilterString'] =
                "FBillNo='" + snDataT[0][1] + "' and FDocumentStatus in ('A','D')";
            snMap['FormId'] = 'QDEP_PDA_SNBind';
            snMap['FieldKeys'] =
            'FID,FBillNo,FDocumentStatus,FBindDate,FMATERIALID.FNUMBER,FMaterialName,FMaterialSpec,FMOBillNo,FEntity_FEntryId,FEntryBindDate,FEntryMoBillNo,FBindQty,FEntryMaterialID.FNUMBER,FEntryMaterialName,FEntryMaterialSpec,FEntryBatchNo,FEntrySN,FEntryBarcodeEn';
            Map<String, dynamic> dataSnMap = Map();
            dataSnMap['data'] = snMap;
            String orderSn = await CurrencyEntity.polling(dataSnMap);
            var snData = jsonDecode(orderSn);
            if (snData.length > 0) {
              this.fBillNo = snData[0][1];
              this.FNumber = snData[0][4];
              this.FName = snData[0][5];
              this.FPcs = snData[0][4];
              this.FSn = snData[0][3];
              this.FMoBillNo = snData[0][7];
              this.FID = snData[0][0];
              var number = 0;
              for (var snItem in snData) {
                for (var element in hobby) {
                    if (element[0]['value']['barcode'].indexOf(snItem[17]) != -1) {
                      ToastUtil.showInfo('某一行数据已存在，将不读取该行');
                      number++;
                      break;
                    }
                }
              }
              if (number == 0) {
                snData.forEach((value) {
                  List arr = [];
                  arr.add({
                    "title": "物料名称",
                    "name": "FMaterial",
                    "isHide": false,
                    "value": {
                      "label": value[13] + "- (" + value[12] + ")",
                      "value": value[12],
                      "barcode": [value[17]]
                    }
                  });
                  arr.add({
                    "title": "规格型号",
                    "isHide": false,
                    "name": "FMaterialIdFSpecification",
                    "value": {"label": value[14], "value": value[14]}
                  });
                  arr.add({
                    "title": "数量",
                    "name": "FRealQty",
                    "isHide": false,
                    "value": {"label": "1", "value": "1"}
                  });
                  arr.add({
                    "title": "批号",
                    "name": "FLot",
                    "isHide": false,
                    "value": {"label": value[15], "value": value[15]}
                  });
                  arr.add({
                    "title": "SN",
                    "name": "SN",
                    "isHide": false,
                    "value": {"label": value[16], "value": value[16]}
                  });
                  arr.add({
                    "title": "生产订单号",
                    "name": "",
                    "isHide": false,
                    "value": {"label": value[10], "value": value[10]}
                  });
                  hobby.add(arr);
                });
              }
              setState(() {
                EasyLoading.dismiss();
                this._getHobby();
              });
            }
          }else {
            if(this.FNumber == ""){
              ToastUtil.showInfo('请先扫描半成品或成品');
              return;
            }
            var number = 0;
            for (var element in hobby) {
                if (element[0]['value']['barcode'].indexOf(event) != -1) {
                  ToastUtil.showInfo('该标签已扫描');
                  number++;
                  break;
                }
            }
            if (number == 0) {
              /*this.FNumber = barcodeData[0][2];
              this.FName = barcodeData[0][1];
              this.FPcs = barcodeData[0][3];
              this.FSn = event.split('-')[2];
              this.FID = 0;*/
              List arr = [];
              arr.add({
                "title": "物料名称",
                "name": "FMaterial",
                "isHide": false,
                "value": {
                  "label":
                  barcodeData[0][1] + "- (" + barcodeData[0][2] + ")",
                  "value": barcodeData[0][2],
                  "barcode": [event]
                }
              });
              arr.add({
                "title": "规格型号",
                "isHide": false,
                "name": "FMaterialIdFSpecification",
                "value": {
                  "label": barcodeData[0][3],
                  "value": barcodeData[0][3]
                }
              });
              arr.add({
                "title": "数量",
                "name": "FRealQty",
                "isHide": false,
                "value": {"label": "1", "value": "1"}
              });
              arr.add({
                "title": "批号",
                "name": "FLot",
                "isHide": false,
                "value": {
                  "label": event.split('-')[1],
                  "value": event.split('-')[1]
                }
              });
              arr.add({
                "title": "SN",
                "name": "SN",
                "isHide": false,
                "value": {
                  "label": event.split('-')[2],
                  "value": event.split('-')[2]
                }
              });
              arr.add({
                "title": "生产订单号",
                "name": "",
                "isHide": false,
                "value": {
                  "label": "",
                  "value": ""
                }
              });
              hobby.add(arr);
            }
            setState(() {
              this._getHobby();
              EasyLoading.dismiss();
            });
          }
        } else {
          ToastUtil.showInfo('条码不存在');
        }
      }else{
        if(event.length>15){
          Map<String, dynamic> barcodeMap = Map();
          barcodeMap['FilterString'] = "FBarCodeEn='" + event + "'";
          barcodeMap['FormId'] = 'QDEP_Cust_BarCodeList';
          barcodeMap['FieldKeys'] =
          'FID,FMATERIALID.FNUMBER,FBarCode,FSN,FSrcBillNo,FMaterialName,FMaterialSpec,FBatchNo';
          Map<String, dynamic> dataMap = Map();
          dataMap['data'] = barcodeMap;
          String order = await CurrencyEntity.polling(dataMap);
          var barcodeData = jsonDecode(order);
          if (barcodeData.length > 0) {
            if (barcodeData[0][4][0] == "W") {
              if (this.FNumber != "") {
                Map<String, dynamic> snMapT = Map();
                snMapT['FilterString'] =
                    "FEntryBarcodeEn='" + event + "' and FDocumentStatus in ('A','D')";
                snMapT['FormId'] = 'QDEP_PDA_SNBind';
                snMapT['FieldKeys'] =
                'FID,FBillNo,FDocumentStatus,FBindDate,FMATERIALID.FNUMBER,FMaterialName,FMaterialSpec,FMOBillNo,FEntity_FEntryId,FEntryBindDate,FEntryMoBillNo,FBindQty,FEntryMaterialID.FNUMBER,FEntryMaterialName,FEntryMaterialSpec,FEntryBatchNo,FEntrySN,FEntryBarcodeEn';
                Map<String, dynamic> datasnMapT = Map();
                datasnMapT['data'] = snMapT;
                String orderSnT = await CurrencyEntity.polling(datasnMapT);
                var snDataT = jsonDecode(orderSnT);
                if (snDataT.length > 0) {
                  Map<String, dynamic> snMap = Map();
                  snMap['FilterString'] =
                      "FBillNo='" + snDataT[0][1] + "' and FDocumentStatus in ('A','D')";
                  snMap['FormId'] = 'QDEP_PDA_SNBind';
                  snMap['FieldKeys'] =
                  'FID,FBillNo,FDocumentStatus,FBindDate,FMATERIALID.FNUMBER,FMaterialName,FMaterialSpec,FMOBillNo,FEntity_FEntryId,FEntryBindDate,FEntryMoBillNo,FBindQty,FEntryMaterialID.FNUMBER,FEntryMaterialName,FEntryMaterialSpec,FEntryBatchNo,FEntrySN,FEntryBarcodeEn';
                  Map<String, dynamic> dataSnMap = Map();
                  dataSnMap['data'] = snMap;
                  String orderSn = await CurrencyEntity.polling(dataSnMap);
                  var snData = jsonDecode(orderSn);
                  if (snData.length > 0 ) {
                    var number = 0;
                    for (var snItem in snData) {
                      for (var element in hobby) {
                        if (element[0]['value']['barcode'].indexOf(snItem[17]) != -1) {
                          ToastUtil.showInfo('某一行数据已存在，将不读取该行');
                          number++;
                          break;
                        }
                      }
                    }
                    if (number == 0) {
                      _showInventoryDialog(snData);
                    }
                  }
                } else {
                  var number = 0;
                  for (var element in hobby) {
                    if (element[0]['value']['barcode'].indexOf(event) != -1) {
                      ToastUtil.showInfo('该标签已扫描');
                      number++;
                      break;
                    }
                  }
                  if (number == 0) {
                    List arr = [];
                    arr.add({
                      "title": "物料名称",
                      "name": "FMaterial",
                      "isHide": false,
                      "value": {
                        "label":
                        barcodeData[0][5] + "- (" + barcodeData[0][1] + ")",
                        "value": barcodeData[0][1],
                        "barcode": [event]
                      }
                    });
                    arr.add({
                      "title": "规格型号",
                      "isHide": false,
                      "name": "FMaterialIdFSpecification",
                      "value": {
                        "label": barcodeData[0][6],
                        "value": barcodeData[0][6]
                      }
                    });
                    arr.add({
                      "title": "数量",
                      "name": "FRealQty",
                      "isHide": false,
                      "value": {"label": "1", "value": "1"}
                    });
                    arr.add({
                      "title": "批号",
                      "name": "FLot",
                      "isHide": false,
                      "value": {
                        "label": barcodeData[0][7],
                        "value": barcodeData[0][7]
                      }
                    });
                    arr.add({
                      "title": "SN",
                      "name": "SN",
                      "isHide": false,
                      "value": {
                        "label": barcodeData[0][3],
                        "value": barcodeData[0][3]
                      }
                    });
                    arr.add({
                      "title": "生产订单号",
                      "name": "",
                      "isHide": false,
                      "value": {
                        "label": barcodeData[0][4],
                        "value": barcodeData[0][4]
                      }
                    });
                    hobby.add(arr);
                  }
                  setState(() {
                    EasyLoading.dismiss();
                    this._getHobby();
                  });
                }
              } else {
                Map<String, dynamic> snMapT = Map();
                snMapT['FilterString'] =
                    "FEntryBarcodeEn='" + event + "' and FDocumentStatus in ('A','D')";
                snMapT['FormId'] = 'QDEP_PDA_SNBind';
                snMapT['FieldKeys'] =
                'FID,FBillNo,FDocumentStatus,FBindDate,FMATERIALID.FNUMBER,FMaterialName,FMaterialSpec,FMOBillNo,FEntity_FEntryId,FEntryBindDate,FEntryMoBillNo,FBindQty,FEntryMaterialID.FNUMBER,FEntryMaterialName,FEntryMaterialSpec,FEntryBatchNo,FEntrySN,FEntryBarcodeEn';
                Map<String, dynamic> datasnMapT = Map();
                datasnMapT['data'] = snMapT;
                String orderSnT = await CurrencyEntity.polling(datasnMapT);
                var snDataT = jsonDecode(orderSnT);
                if (snDataT.length > 0) {
                  Map<String, dynamic> snMap = Map();
                  snMap['FilterString'] =
                      "FBillNo='" + snDataT[0][1] + "' and FDocumentStatus in ('A','D')";
                  snMap['FormId'] = 'QDEP_PDA_SNBind';
                  snMap['FieldKeys'] =
                  'FID,FBillNo,FDocumentStatus,FBindDate,FMATERIALID.FNUMBER,FMaterialName,FMaterialSpec,FMOBillNo,FEntity_FEntryId,FEntryBindDate,FEntryMoBillNo,FBindQty,FEntryMaterialID.FNUMBER,FEntryMaterialName,FEntryMaterialSpec,FEntryBatchNo,FEntrySN,FEntryBarcodeEn';
                  Map<String, dynamic> dataSnMap = Map();
                  dataSnMap['data'] = snMap;
                  String orderSn = await CurrencyEntity.polling(dataSnMap);
                  var snData = jsonDecode(orderSn);
                  if (snData.length > 0) {
                    this.fBillNo = snData[0][1];
                    this.FNumber = snData[0][4];
                    this.FName = snData[0][5];
                    this.FPcs = snData[0][4];
                    this.FSn = snData[0][3];
                    this.FMoBillNo = snData[0][7];
                    this.FID = snData[0][0];
                    var number = 0;
                    for (var snItem in snData) {
                      for (var element in hobby) {
                        if (element[0]['value']['value'] == snItem[12]) {
                          if (element[0]['value']['barcode'].indexOf(snItem[17]) != -1) {
                            ToastUtil.showInfo('某一行数据已存在，将不读取该行');
                            number++;
                            break;
                          }
                        }
                      }
                    }
                    if (number == 0) {
                      snData.forEach((value) {
                        List arr = [];
                        arr.add({
                          "title": "物料名称",
                          "name": "FMaterial",
                          "isHide": false,
                          "value": {
                            "label": value[13] + "- (" + value[12] + ")",
                            "value": value[12],
                            "barcode": [value[17]]
                          }
                        });
                        arr.add({
                          "title": "规格型号",
                          "isHide": false,
                          "name": "FMaterialIdFSpecification",
                          "value": {"label": value[14], "value": value[14]}
                        });
                        arr.add({
                          "title": "数量",
                          "name": "FRealQty",
                          "isHide": false,
                          "value": {"label": "1", "value": "1"}
                        });
                        arr.add({
                          "title": "批号",
                          "name": "FLot",
                          "isHide": false,
                          "value": {"label": value[15], "value": value[15]}
                        });
                        arr.add({
                          "title": "SN",
                          "name": "SN",
                          "isHide": false,
                          "value": {"label": value[16], "value": value[16]}
                        });
                        arr.add({
                          "title": "生产订单号",
                          "name": "",
                          "isHide": false,
                          "value": {"label": value[10], "value": value[10]}
                        });
                        hobby.add(arr);
                      });
                    }
                    setState(() {
                      EasyLoading.dismiss();
                      this._getHobby();
                    });
                  }
                }else {
                  var number = 0;
                  for (var element in hobby) {
                    if (element[0]['value']['barcode'].indexOf(event) != -1) {
                      ToastUtil.showInfo('该标签已扫描');
                      number++;
                      break;
                    }
                  }
                  if (number == 0) {
                    this.FNumber = barcodeData[0][1];
                    this.FName = barcodeData[0][5];
                    this.FPcs = barcodeData[0][6];
                    this.FSn = barcodeData[0][7];
                    this.FMoBillNo = barcodeData[0][4];
                    this.FID = 0;
                    List arr = [];
                    arr.add({
                      "title": "物料名称",
                      "name": "FMaterial",
                      "isHide": false,
                      "value": {
                        "label":
                        barcodeData[0][5] + "- (" + barcodeData[0][1] + ")",
                        "value": barcodeData[0][1],
                        "barcode": [event]
                      }
                    });
                    arr.add({
                      "title": "规格型号",
                      "isHide": false,
                      "name": "FMaterialIdFSpecification",
                      "value": {
                        "label": barcodeData[0][6],
                        "value": barcodeData[0][6]
                      }
                    });
                    arr.add({
                      "title": "数量",
                      "name": "FRealQty",
                      "isHide": false,
                      "value": {"label": "1", "value": "1"}
                    });
                    arr.add({
                      "title": "批号",
                      "name": "FLot",
                      "isHide": false,
                      "value": {
                        "label": barcodeData[0][7],
                        "value": barcodeData[0][7]
                      }
                    });
                    arr.add({
                      "title": "SN",
                      "name": "SN",
                      "isHide": false,
                      "value": {
                        "label": barcodeData[0][3],
                        "value": barcodeData[0][3]
                      }
                    });
                    arr.add({
                      "title": "生产订单号",
                      "name": "",
                      "isHide": false,
                      "value": {
                        "label": barcodeData[0][4],
                        "value": barcodeData[0][4]
                      }
                    });
                    hobby.add(arr);
                  }
                  setState(() {
                    this._getHobby();
                    EasyLoading.dismiss();
                  });
                }
              }
            } else {
              ToastUtil.showInfo('请扫描半成品或成品');
            }
          } else {
            ToastUtil.showInfo('条码不在条码清单中');
          }
        }else{
          Map<String, dynamic> userMap = Map();
          SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
          var menuData = sharedPreferences.getString('MenuPermissions');
          var deptData = jsonDecode(menuData)[0];
          userMap['FilterString'] = "F_UYEP_GYSTM='"+event.substring(0,3)+"' and FForbidStatus = 'A' and FUseOrgId.FNumber = '"+deptData[1]+"'";
          userMap['FormId'] = 'BD_MATERIAL';
          userMap['FieldKeys'] =
          'FMATERIALID,FName,FNumber,FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FIsBatchManage';/*,SubHeadEntity1.FStoreUnitID.FNumber*/
          Map<String, dynamic> dataMap = Map();
          dataMap['data'] = userMap;
          String order = await CurrencyEntity.polling(dataMap);
          var barcodeData = jsonDecode(order);
          if (barcodeData.length > 0) {
            Map<String, dynamic> snMapT = Map();
            snMapT['FilterString'] =
                "FEntryBarcodeEn='" + event + "' and FDocumentStatus in ('A','D')";
            snMapT['FormId'] = 'QDEP_PDA_SNBind';
            snMapT['FieldKeys'] =
            'FID,FBillNo,FDocumentStatus,FBindDate,FMATERIALID.FNUMBER,FMaterialName,FMaterialSpec,FMOBillNo,FEntity_FEntryId,FEntryBindDate,FEntryMoBillNo,FBindQty,FEntryMaterialID.FNUMBER,FEntryMaterialName,FEntryMaterialSpec,FEntryBatchNo,FEntrySN,FEntryBarcodeEn';
            Map<String, dynamic> datasnMapT = Map();
            datasnMapT['data'] = snMapT;
            String orderSnT = await CurrencyEntity.polling(datasnMapT);
            var snDataT = jsonDecode(orderSnT);
            if (snDataT.length > 0) {
              Map<String, dynamic> snMap = Map();
              snMap['FilterString'] =
                  "FBillNo='" + snDataT[0][1] + "' and FDocumentStatus in ('A','D')";
              snMap['FormId'] = 'QDEP_PDA_SNBind';
              snMap['FieldKeys'] =
              'FID,FBillNo,FDocumentStatus,FBindDate,FMATERIALID.FNUMBER,FMaterialName,FMaterialSpec,FMOBillNo,FEntity_FEntryId,FEntryBindDate,FEntryMoBillNo,FBindQty,FEntryMaterialID.FNUMBER,FEntryMaterialName,FEntryMaterialSpec,FEntryBatchNo,FEntrySN,FEntryBarcodeEn';
              Map<String, dynamic> dataSnMap = Map();
              dataSnMap['data'] = snMap;
              String orderSn = await CurrencyEntity.polling(dataSnMap);
              var snData = jsonDecode(orderSn);
              if (snData.length > 0) {
                this.fBillNo = snData[0][1];
                this.FNumber = snData[0][4];
                this.FName = snData[0][5];
                this.FPcs = snData[0][4];
                this.FSn = snData[0][3];
                this.FMoBillNo = snData[0][7];
                this.FID = snData[0][0];
                var number = 0;
                for (var snItem in snData) {
                  for (var element in hobby) {
                    if (element[0]['value']['barcode'].indexOf(snItem[17]) != -1) {
                      ToastUtil.showInfo('某一行数据已存在，将不读取该行');
                      number++;
                      break;
                    }
                  }
                }
                if (number == 0) {
                  snData.forEach((value) {
                    List arr = [];
                    arr.add({
                      "title": "物料名称",
                      "name": "FMaterial",
                      "isHide": false,
                      "value": {
                        "label": value[13] + "- (" + value[12] + ")",
                        "value": value[12],
                        "barcode": [value[17]]
                      }
                    });
                    arr.add({
                      "title": "规格型号",
                      "isHide": false,
                      "name": "FMaterialIdFSpecification",
                      "value": {"label": value[14], "value": value[14]}
                    });
                    arr.add({
                      "title": "数量",
                      "name": "FRealQty",
                      "isHide": false,
                      "value": {"label": "1", "value": "1"}
                    });
                    arr.add({
                      "title": "批号",
                      "name": "FLot",
                      "isHide": false,
                      "value": {"label": value[15], "value": value[15]}
                    });
                    arr.add({
                      "title": "SN",
                      "name": "SN",
                      "isHide": false,
                      "value": {"label": value[16], "value": value[16]}
                    });
                    arr.add({
                      "title": "生产订单号",
                      "name": "",
                      "isHide": false,
                      "value": {"label": value[10], "value": value[10]}
                    });
                    hobby.add(arr);
                  });
                }
                setState(() {
                  EasyLoading.dismiss();
                  this._getHobby();
                });
              }
            }else {
              if(this.FNumber == ""){
                ToastUtil.showInfo('请先扫描半成品或成品');
                return;
              }
              var number = 0;
              for (var element in hobby) {
                if (element[0]['value']['barcode'].indexOf(event) != -1) {
                  ToastUtil.showInfo('该标签已扫描');
                  number++;
                  break;
                }
              }
              if (number == 0) {
                /*this.FNumber = barcodeData[0][2];
              this.FName = barcodeData[0][1];
              this.FPcs = barcodeData[0][3];
              this.FSn = event.split('-')[2];
              this.FID = 0;*/
                List arr = [];
                arr.add({
                  "title": "物料名称",
                  "name": "FMaterial",
                  "isHide": false,
                  "value": {
                    "label":
                    barcodeData[0][1] + "- (" + barcodeData[0][2] + ")",
                    "value": barcodeData[0][2],
                    "barcode": [event]
                  }
                });
                arr.add({
                  "title": "规格型号",
                  "isHide": false,
                  "name": "FMaterialIdFSpecification",
                  "value": {
                    "label": barcodeData[0][3],
                    "value": barcodeData[0][3]
                  }
                });
                arr.add({
                  "title": "数量",
                  "name": "FRealQty",
                  "isHide": false,
                  "value": {"label": "1", "value": "1"}
                });
                arr.add({
                  "title": "批号",
                  "name": "FLot",
                  "isHide": false,
                  "value": {
                    "label": event.substring(3,9),
                    "value": event.substring(3,9)
                  }
                });
                arr.add({
                  "title": "SN",
                  "name": "SN",
                  "isHide": false,
                  "value": {
                    "label": event.substring(9,15),
                    "value": event.substring(9,15)
                  }
                });
                arr.add({
                  "title": "生产订单号",
                  "name": "",
                  "isHide": false,
                  "value": {
                    "label": "",
                    "value": ""
                  }
                });
                hobby.add(arr);
              }
              setState(() {
                this._getHobby();
                EasyLoading.dismiss();
              });
            }
          } else {
            ToastUtil.showInfo('条码不存在');
          }
        }
      }
    } else {
      _code = event;
      this.getMaterialList("", _code, "");
      print("ChannelPage: $event");
    }
    print(12313);
    print(this.FMoBillNo);
  }

  void _onError(Object error) {
    setState(() {
      _code = "扫描异常";
    });
  }

  getMaterialList(barcodeData, code, fsn) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    var scanCode = code.split(";");
    userMap['FilterString'] = "FNumber='" +
        scanCode[0] +
        "' and FForbidStatus = 'A' and FUseOrgId.FNumber = '" +
        deptData[1] +
        "'";
    userMap['FormId'] = 'BD_MATERIAL';
    userMap['FieldKeys'] =
        'FMATERIALID,FName,FNumber,FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FIsBatchManage,FStockId.FName,FStockId.FNumber';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    materialDate = [];
    materialDate = jsonDecode(order);
    FDate = formatDate(DateTime.now(), [
      yyyy,
      "-",
      mm,
      "-",
      dd,
    ]);
    selectData[DateMode.YMD] = formatDate(DateTime.now(), [
      yyyy,
      "-",
      mm,
      "-",
      dd,
    ]);
    if (materialDate.length > 0) {
      var number = 0;
      var barCodeScan;
      if (fBarCodeList == 1) {
        barCodeScan = barcodeData[0];
        barCodeScan[4] = barCodeScan[4].toString();
      } else {
        barCodeScan = scanCode;
      }
      var barcodeNum = scanCode[3];
      for (var element in hobby) {
        var residue = 0.0;
        //判断是否启用批号
        if (element[5]['isHide']) {
          //不启用
          if (element[0]['value']['value'] == scanCode[0] &&
              element[4]['value']['value'] == barCodeScan[7]) {
            if (element[0]['value']['barcode'].indexOf(code) == -1) {
              //判断是否可重复扫码
              if (scanCode.length > 4) {
                element[0]['value']['barcode'].add(code);
              }
              //判断条码数量
              if ((double.parse(element[3]['value']['value']) +
                          double.parse(barcodeNum)) >
                      0 &&
                  double.parse(barcodeNum) > 0) {
                //判断条码是否重复
                if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                  element[3]['value']['value'] =
                      (double.parse(element[3]['value']['value']) +
                          double.parse(barcodeNum))
                          .toString();
                  element[3]['value']['label'] = element[3]['value']['value'];
                  var item =
                      barCodeScan[0].toString() + "-" + barcodeNum + "-" + fsn;
                  element[8]['value']['label'] = barcodeNum.toString();
                  element[8]['value']['value'] = barcodeNum.toString();
                  element[0]['value']['kingDeeCode'].add(item);
                  element[0]['value']['scanCode'].add(code);
                  barcodeNum =
                      (double.parse(barcodeNum) - double.parse(barcodeNum))
                          .toString();
                }
                number++;
                break;
              }
            } else {
              ToastUtil.showInfo('该标签已扫描');
              number++;
              break;
            }
          }
        } else {
          //启用批号
          print(element[0]['value']['value']);
          print(scanCode[0]);
          print(element[4]['value']['value']);
          print(barCodeScan[6]);
          if (element[0]['value']['value'] == scanCode[0] &&
              element[4]['value']['value'] == barCodeScan[7]) {
            if (element[0]['value']['barcode'].indexOf(code) == -1) {
              if (element[5]['value']['value'] == scanCode[1]) {
                //判断是否可重复扫码
                if (scanCode.length > 4) {
                  element[0]['value']['barcode'].add(code);
                }
                //判断条码数量
                if ((double.parse(element[3]['value']['value']) +
                            double.parse(barcodeNum)) >
                        0 &&
                    double.parse(barcodeNum) > 0) {
                  //判断条码是否重复
                  if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                    element[3]['value']['value'] =
                      (double.parse(element[3]['value']['value']) +
                          double.parse(barcodeNum))
                          .toString();
                  element[3]['value']['label'] = element[3]['value']['value'];
                    var item = barCodeScan[0].toString() +
                        "-" +
                        barcodeNum +
                        "-" +
                        fsn;
                    element[8]['value']['label'] = barcodeNum.toString();
                    element[8]['value']['value'] = barcodeNum.toString();
                    element[0]['value']['kingDeeCode'].add(item);
                    element[0]['value']['scanCode'].add(code);
                    barcodeNum =
                        (double.parse(barcodeNum) - double.parse(barcodeNum))
                            .toString();
                  }
                }
                number++;
                break;
              } else {
                if (element[5]['value']['value'] == "") {
                  //判断是否可重复扫码
                  if (scanCode.length > 4) {
                    element[0]['value']['barcode'].add(code);
                  }
                  element[5]['value']['label'] = scanCode[1];
                  element[5]['value']['value'] = scanCode[1];
                  //判断条码数量
                  if ((double.parse(element[3]['value']['value']) +
                              double.parse(barcodeNum)) >
                          0 &&
                      double.parse(barcodeNum) > 0) {
                    //判断条码是否重复
                    if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                      element[3]['value']['label'] =
                          (double.parse(element[3]['value']['value']) +
                                  double.parse(barcodeNum))
                              .toString();
                      element[3]['value']['value'] =
                          element[3]['value']['label'];
                      var item = barCodeScan[0].toString() +
                          "-" +
                          barcodeNum +
                          "-" +
                          fsn;
                      element[8]['value']['label'] = barcodeNum.toString();
                      element[8]['value']['value'] = barcodeNum.toString();
                      element[0]['value']['kingDeeCode'].add(item);
                      element[0]['value']['scanCode'].add(code);
                      barcodeNum =
                          (double.parse(barcodeNum) - double.parse(barcodeNum))
                              .toString();
                    }
                  }
                  number++;
                  break;
                }
              }
            } else {
              ToastUtil.showInfo('该标签已扫描');
              number++;
              break;
            }
          }
        }
      }
      if (number == 0 && this.fBillNo == "") {
        materialDate.forEach((value) {
          List arr = [];
          arr.add({
            "title": "物料名称",
            "name": "FMaterial",
            "isHide": false,
            "value": {
              "label": value[1] + "- (" + value[2] + ")",
              "value": value[2],
              "barcode": [code],
              "kingDeeCode": [
                barCodeScan[0].toString() + "-" + scanCode[3] + "-" + fsn
              ],
              "scanCode": [barCodeScan[0].toString() + "-" + scanCode[3]]
            }
          });
          arr.add({
            "title": "规格型号",
            "isHide": false,
            "name": "FMaterialIdFSpecification",
            "value": {"label": value[3], "value": value[3]}
          });
          arr.add({
            "title": "单位名称",
            "name": "FUnitId",
            "isHide": false,
            "value": {"label": value[4], "value": value[5]}
          });
          arr.add({
            "title": "出库数量",
            "name": "FRealQty",
            "isHide": true,
            "value": {
              "label": scanCode[3].toString(),
              "value": scanCode[3].toString()
            }
          });
          arr.add({
            "title": "仓库",
            "name": "FStockID",
            "isHide": true,
            "value": {"label": '', "value": ''}
          });
          arr.add({
            "title": "批号",
            "name": "FLot",
            "isHide": value[6] != true,
            "value": {
              "label": value[6] ? (scanCode.length > 1 ? scanCode[1] : '') : '',
              "value": value[6] ? (scanCode.length > 1 ? scanCode[1] : '') : ''
            }
          });
          arr.add({
            "title": "仓位",
            "name": "FStockLocID",
            "isHide": true,
            "value": {"label": "", "value": "", "hide": false}
          });
          arr.add({
            "title": "操作",
            "name": "",
            "isHide": false,
            "value": {"label": "", "value": ""}
          });
          arr.add({
            "title": "最后扫描数量",
            "name": "FLastQty",
            "isHide": true,
            "value": {
              "label": scanCode[3].toString(),
              "value": scanCode[3].toString()
            }
          });
          arr.add({
            "title": "SN",
            "name": "SN",
            "isHide": false,
            "value": {"label": fsn, "value": fsn}
          });
          hobby.add(arr);
        });
      }
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

  Widget _item(title, var data, selectData, hobby, {String? label, var stock}) {
    if (selectData == null) {
      selectData = "";
    }
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: ListTile(
            title: Text(title),
            onTap: () => data.length > 0
                ? _onClickItem(data, selectData, hobby,
                    label: label, stock: stock)
                : {ToastUtil.showInfo('无数据')},
            trailing: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              MyText(selectData.toString() == "" ? '暂无' : selectData.toString(),
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
              PartRefreshWidget(globalKey, () {
                //2、使用 创建一个widget
                return MyText(
                    (PicketUtil.strEmpty(selectData[model])
                        ? '暂无'
                        : selectData[model])!,
                    color: Colors.grey,
                    rightpadding: 18);
              }),
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
              selectData[model] = formatDate(
                  DateFormat('yyyy-MM-dd')
                      .parse('${p.year}-${p.month}-${p.day}'),
                  [
                    yyyy,
                    "-",
                    mm,
                    "-",
                    dd,
                  ]);
              FDate = formatDate(
                  DateFormat('yyyy-MM-dd')
                      .parse('${p.year}-${p.month}-${p.day}'),
                  [
                    yyyy,
                    "-",
                    mm,
                    "-",
                    dd,
                  ]);
              break;
          }
        });
      },
      // onChanged: (p) => print(p),
    );
  }

  void _onClickItem(var data, var selectData, hobby,
      {String? label, var stock}) {
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
          if (hobby == 'customer') {
            customerName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                customerNumber = customerListObj[elementIndex][2];
              }
              elementIndex++;
            });
          } else if (hobby == 'department') {
            departmentName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                departmentNumber = departmentListObj[elementIndex][2];
              }
              elementIndex++;
            });
          } else if (hobby == 'type') {
            typeName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                typeNumber = typeListObj[elementIndex][2];
              }
              elementIndex++;
            });
          } else {
            setState(() {
              setState(() {
                hobby['value']['label'] = p;
              });
              ;
            });
            print(hobby['value']['label']);
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                hobby['value']['value'] = stockListObj[elementIndex][2];
                stock[6]['value']['hide'] = stockListObj[elementIndex][3];
              }
              elementIndex++;
            });
          }
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
          /*if (j == 3 || j ==5) {
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
                        IconButton(
                          icon: new Icon(Icons.filter_center_focus),
                          tooltip: '点击扫描',
                          onPressed: () {
                            this._textNumber.text =
                                this.hobby[i][j]["value"]["label"].toString();
                            this._FNumber =
                                this.hobby[i][j]["value"]["label"].toString();
                            checkItem = 'FNumber';
                            this.show = false;
                            checkData = i;
                            checkDataChild = j;
                            scanDialog();
                            print(this.hobby[i][j]["value"]["label"]);
                            if (this.hobby[i][j]["value"]["label"] != 0) {
                              this._textNumber.value = _textNumber.value.copyWith(
                                text:
                                this.hobby[i][j]["value"]["label"].toString(),
                              );
                            }
                          },
                        ),
                      ])),
                ),
                divider,
              ]),
            );
          } else if (j == 4) {
            comList.add(
              _item('仓库:', stockList, this.hobby[i][j]['value']['label'],
                  this.hobby[i][j],stock:this.hobby[i]),
            );
          } else*/
          if (j == 7) {
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
          } else if (j == 8) {
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
                                this._textNumber.text = this
                                    .hobby[i][j]["value"]["label"]
                                    .toString();
                                this._FNumber = this
                                    .hobby[i][j]["value"]["label"]
                                    .toString();
                                checkItem = 'FLastQty';
                                this.show = false;
                                checkData = i;
                                checkDataChild = j;
                                scanDialog();
                                print(this.hobby[i][j]["value"]["label"]);
                                if (this.hobby[i][j]["value"]["label"] != 0) {
                                  this._textNumber.value =
                                      _textNumber.value.copyWith(
                                    text: this
                                        .hobby[i][j]["value"]["label"]
                                        .toString(),
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
              Visibility(
                maintainSize: false,
                maintainState: false,
                maintainAnimation: false,
                visible: this.hobby[i][j]["value"]["hide"],
                child: Column(children: [
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
                                  this._textNumber.text = this
                                      .hobby[i][j]["value"]["label"]
                                      .toString();
                                  this._FNumber = this
                                      .hobby[i][j]["value"]["label"]
                                      .toString();
                                  checkItem = 'FNumber';
                                  this.show = false;
                                  checkData = i;
                                  checkDataChild = j;
                                  scanDialog();
                                  print(this.hobby[i][j]["value"]["label"]);
                                  if (this.hobby[i][j]["value"]["label"] != 0) {
                                    this._textNumber.value =
                                        _textNumber.value.copyWith(
                                      text: this
                                          .hobby[i][j]["value"]["label"]
                                          .toString(),
                                    );
                                  }
                                },
                              ),
                            ])),
                  ),
                  divider,
                ]),
              ),
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
                            if (checkItem == "FLastQty") {
                              if (this
                                      .hobby[checkData][0]['value']
                                          ['kingDeeCode']
                                      .length >
                                  0) {
                                var kingDeeCode = this
                                    .hobby[checkData][0]['value']['kingDeeCode']
                                        [this
                                                .hobby[checkData][0]['value']
                                                    ['kingDeeCode']
                                                .length -
                                            1]
                                    .split("-");
                                var realQty = 0.0;
                                this
                                    .hobby[checkData][0]['value']['kingDeeCode']
                                    .forEach((item) {
                                  var qty = item.split("-")[1];
                                  realQty += double.parse(qty);
                                });
                                realQty = realQty -
                                    double.parse(this.hobby[checkData][10]
                                        ["value"]["label"]);
                                realQty = realQty + double.parse(_FNumber);
                                this.hobby[checkData][3]["value"]["value"] =
                                    realQty.toString();
                                this.hobby[checkData][3]["value"]["label"] =
                                    realQty.toString();
                                this.hobby[checkData][checkDataChild]["value"]
                                    ["label"] = _FNumber;
                                this.hobby[checkData][checkDataChild]['value']
                                    ["value"] = _FNumber;
                                this.hobby[checkData][0]['value']['kingDeeCode']
                                    [this
                                            .hobby[checkData][0]['value']
                                                ['kingDeeCode']
                                            .length -
                                        1] = kingDeeCode[0] + "-" + _FNumber;
                              } else {
                                ToastUtil.showInfo('无条码信息，输入失败');
                              }
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
      dataMap['formid'] = 'QDEP_PDA_SNBind';
      Map<String, dynamic> orderMap = Map();
      orderMap['NeedUpDataFields'] = ['FEntity'];
      orderMap['NeedReturnFields'] = ['FEntity'];
      orderMap['IsDeleteEntry'] = true;
      Map<String, dynamic> Model = Map();
      Model['FID'] = this.FID;
      Model['FBindDate'] = FDate;
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      var menuData = sharedPreferences.getString('MenuPermissions');
      var deptData = jsonDecode(menuData)[0];
      Model['FMATERIALID'] = {"FNUMBER": this.FNumber};
      Model['FPickOrgId'] = {"FNumber": deptData[1]};
      /* Model['FMaterialName'] = this.FName;
      Model['FMaterialSpec'] = this.FPcs;*/
      Model['FMOBillNo'] = this.FMoBillNo;
      var FEntity = [];
      var hobbyIndex = 0;
      this.hobby.forEach((element) {
        Map<String, dynamic> FEntityItem = Map();
        FEntityItem['FEntryBindDate'] = FDate;
        FEntityItem['FEntryMoBillNo'] = this.FMoBillNo/*element[5]['value']['value']*/;
        FEntityItem['FBindQty'] = element[2]['value']['value'];
        FEntityItem['FEntryMaterialID'] = {
          "FNUMBER": element[0]['value']['value']
        };
        /*FEntityItem['FEntryMaterialSpec'] = element[1]['value']['value'];*/
        FEntityItem['FEntryBatchNo'] = element[3]['value']['value'];
        FEntityItem['FEntrySN'] = element[4]['value']['value'];
        FEntityItem['FEntryBarcodeEn'] = element[0]['value']['barcode'][0];
        FEntity.add(FEntityItem);
        hobbyIndex++;
      });
      if (FEntity.length == 0) {
        this.isSubmit = false;
        ToastUtil.showInfo('请扫描数据后再提交');
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
          "formid": "QDEP_PDA_SNBind",
          "data": {
            'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
          }
        };
        setState(() {
          this.hobby = [];
          this.orderDate = [];
          this.materialDate = [];
          this.FBillNo = '';
          ToastUtil.showInfo('提交成功');
          /*Navigator.of(context).pop("refresh");*/
        });
        /*//提交
        HandlerOrder.orderHandler(
            context,
            submitMap,
            1,
            "QDEP_PDA_SNBind",
            SubmitEntity.submit(submitMap))
            .then((submitResult) {
          if (submitResult) {
            //审核
            HandlerOrder.orderHandler(
                context,
                submitMap,
                1,
                "QDEP_PDA_SNBind",
                SubmitEntity.audit(submitMap))
                .then((auditResult) async{
              if (auditResult) {
                print(auditResult);
                //提交清空页面
                setState(() {
                  this.hobby = [];
                  this.orderDate = [];
                  this.materialDate = [];
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
                    "QDEP_PDA_SNBind",
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
        });*/
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
//扫码函数,最简单的那种
  Future scan() async {
    String cameraScanResult = await scanner.scan(); //通过扫码获取二维码中的数据
    getScan(cameraScanResult); //将获取到的参数通过HTTP请求发送到服务器
    print(cameraScanResult); //在控制台打印
  }

//用于验证数据(也可以在控制台直接打印，但模拟器体验不好)
  void getScan(String scan) async {
    _onEvent(scan);
  }
  @override
  Widget build(BuildContext context) {
    return FlutterEasyLoading(
      child: Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: scan,
            tooltip: 'Increment',
            child: Icon(Icons.filter_center_focus),
          ),
          appBar: AppBar(
            title: Text("SN绑定"),
            centerTitle: true,
            leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                }),
          ),
          body: Column(
            children: <Widget>[
              Expanded(
                child: ListView(children: <Widget>[
                  /*Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text("单号：$fBillNo"),
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
                          title: Text("物料：$FName($FNumber)"),
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
                          title: Text("规格型号：$FPcs"),
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
                          title: Text("生产订单号：$FSn"),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  _dateItem('绑定日期：', DateMode.YMD),*/
                  /* _item('客户:', this.customerList, this.customerName,
                      'customer'),
                  _item('部门', this.departmentList, this.departmentName,
                      'department'),*/
                  /*_item('类别', this.typeList, this.typeName,
                      'type'),*/
                  /*Column(
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
