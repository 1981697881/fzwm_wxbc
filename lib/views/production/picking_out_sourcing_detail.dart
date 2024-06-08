import 'dart:convert';
import 'package:fzwm_wxbc/components/my_text.dart';
import 'package:fzwm_wxbc/model/currency_entity.dart';
import 'package:fzwm_wxbc/model/submit_entity.dart';
import 'package:fzwm_wxbc/utils/refresh_widget.dart';
import 'package:fzwm_wxbc/utils/text.dart';
import 'package:fzwm_wxbc/utils/toast_util.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qrscan/qrscan.dart' as scanner;

final String _fontFamily = Platform.isWindows ? "Roboto" : "";

class PickingOutSourcingDetail extends StatefulWidget {
  var FBillNo;
  var FSeq;
  var FEntryId;
  var FID;
  var FProdOrder;
  var FBarcode;

  PickingOutSourcingDetail(
      {Key ?key,
        @required this.FBillNo,
        @required this.FSeq,
        @required this.FEntryId,
        @required this.FID,
        @required this.FBarcode,
        @required this.FProdOrder})
      : super(key: key);

  @override
  _PickingOutSourcingDetailState createState() =>
      _PickingOutSourcingDetailState(FBillNo, FSeq, FEntryId, FID, FProdOrder,FBarcode);
}
class _PickingOutSourcingDetailState extends State<PickingOutSourcingDetail> {
  GlobalKey<TextWidgetState> textKey = GlobalKey();
  GlobalKey<TextWidgetState> FBillNoKey = GlobalKey();
  GlobalKey<TextWidgetState> FSaleOrderNoKey = GlobalKey();
  GlobalKey<PartRefreshWidgetState> globalKey = GlobalKey();
  GlobalKey<PartRefreshWidgetState> FSubOrgIdKey = GlobalKey();

  final _textNumber = TextEditingController();
  var checkItem;
  var FBillNo = '';
  var FSaleOrderNo = '';
  var FName = '';
  var FNumber = '';
  var FDate = '';
  var FStockOrgId = '';
  var FSubOrgId = '';
  var show = false;
  var isSubmit = false;
  var isScanWork = false;
  var checkData;
  var checkDataChild;
  var fBarCodeList;
  var selectData = {
    DateMode.YMD: "",
  };
  var stockList = [];
  List<dynamic> stockListObj = [];
  var selectStock = "";
  Map<String, dynamic> selectStockMap = Map();
  List<dynamic> orderDate = [];
  List<dynamic> collarOrderDate = [];
  List<dynamic> materialDate = [];
  final divider = Divider(height: 1, indent: 20);
  final rightIcon = Icon(Icons.keyboard_arrow_right);
  final scanIcon = Icon(Icons.filter_center_focus);
  static const scannerPlugin =
  const EventChannel('com.shinow.pda_scanner/plugin');
  StreamSubscription ?_subscription;
  var _code;
  var _FNumber;
  var FSeq;
  var fBillNo;
  var fEntryId;
  var fid;
  var FProdOrder;
  var FBarcode;
  var fOrgID;

  _PickingOutSourcingDetailState(fBillNo, FSeq, fEntryId, fid, FProdOrder,FBarcode) {
    this.fBillNo = fBillNo['value'];
    this.FSeq = FSeq['value'];
    this.fEntryId = fEntryId['value'];
    this.fid = fid['value'];
    this.FProdOrder = FProdOrder['value'];
    this.FBarcode = FBarcode;
    this.getOrderList();
  }

  @override
  void initState() {
    super.initState();
    DateTime dateTime = DateTime.now();
    var nowDate = "${dateTime.year}-${dateTime.month}-${dateTime.day}";
    selectData[DateMode.YMD] = nowDate;
    /// 开启监听
    if (_subscription == null) {
      _subscription = scannerPlugin
          .receiveBroadcastStream()
          .listen(_onEvent, onError: _onError);
    }
    getWorkShop();
    getStockList();
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

  //获取仓库
  getStockList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BD_STOCK';
    userMap['FieldKeys'] = 'FStockID,FName,FNumber,FIsOpenLocation';
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    if(fOrgID == null){
      this.fOrgID = deptData[1];
    }
    userMap['FilterString'] = "FForbidStatus = 'A'";// and FUseOrgId.FNumber ='"+fOrgID+"'
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    stockListObj = jsonDecode(res);
    var fStockIds = jsonDecode(sharedPreferences.getString('FStockIds')).split(',');
    if(jsonDecode(sharedPreferences.getString('FStockIds')) != ''){
      fStockIds.forEach((item){
        stockListObj.forEach((element) {
          if(element[0].toString() == item){
            stockList.add(element[1]);
          }
        });
      });
    }else{
      stockListObj.forEach((element) {
        stockList.add(element[1]);
      });
    }
  }

  // 查询数据集合
  List hobby = [];
  List fNumber = [];
  //获取订单信息
  getOrderList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FilterString'] =
    "FSubReqBillNO='$fBillNo' and FSubReqEntrySeq = '$FSeq'";
    userMap['FormId'] = 'SUB_PPBOM';
    userMap['OrderString'] = 'FMaterialId.FNumber ASC';
    userMap['FieldKeys'] =
    'FBillNo,FSubOrgId.FNumber,FSubOrgId.FName,FSubReqBillNO,FSubReqEntrySeq,FEntity_FEntryId,FEntity_FSeq,FMaterialID2.FNumber,FMaterialID2.FName,FMaterialID2.FSpecification,FUnitID.FNumber,FUnitID.FName,FNoPickedQty,FID';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    orderDate = [];
    orderDate = jsonDecode(order);
    DateTime dateTime = DateTime.now();
    FDate =
    "${dateTime.year}-${dateTime.month}-${dateTime.day} ${dateTime.hour}:${dateTime.minute}:${dateTime.second}";
    hobby = [];
    if (orderDate.length > 0) {
      FStockOrgId = orderDate[0][1].toString();
      FSubOrgId = orderDate[0][1].toString();
      this.fOrgID = orderDate[0][1];
      orderDate.forEach((value) {
        fNumber.add(value[7]);
        List arr = [];
        arr.add({
          "title": "物料编码",
          "name": "FMaterialId",
          "isHide": false,
          "value": {
            "label": value[8] + "- (" + value[7] + ")",
            "value": value[7],
            "barcode": [],
            "kingDeeCode": [],
            "scanCode": []
          }
        });
        arr.add({
          "title": "规格型号",
          "isHide": true,
          "name": "FMaterialIdFSpecification",
          "value": {"label": value[9], "value": value[9]}
        });
        arr.add({
          "title": "单位名称",
          "name": "FUnitId",
          "isHide": false,
          "value": {"label": value[11], "value": value[10]}
        });
        arr.add({
          "title": "领料数量",
          "name": "FBaseQty",
          "isHide": false,
          "value": {"label": "0", "value": "0"}
        });
        arr.add({
          "title": "仓库",
          "name": "FStockId",
          "isHide": false,
          "value": {"label": "", "value": ""}
        });
        arr.add({
          "title": "批号",
          "name": "",
          "isHide": false,
          "value": {"label": "", "value": ""}
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
          "isHide": true,
          "value": {"label": "", "value": ""}
        });
        arr.add({
          "title": "库存单位",
          "name": "",
          "isHide": true,
          "value": {"label":"", "value": ""}
        });
        arr.add({
          "title": "用量",
          "name": "FSubOrgId",
          "isHide": false,
          "value": {"label": value[12], "value": value[12]}
        });
        arr.add({
          "title": "最后扫描数量",
          "name": "FLastQty",
          "isHide": false,
          "value": {"label": "0", "value": "0"}
        });
        hobby.add(arr);
      });
      setState(() {
        EasyLoading.dismiss();
        this._getHobby();
      });
      getStockList();
    } else {
      setState(() {
        EasyLoading.dismiss();
        this._getHobby();
      });
      ToastUtil.showInfo('无数据');
      getStockList();
    }
    /*_onEvent("F.30.5300111;20230618;;1;WGRK23060404;21");
    _onEvent("F.19.3310013;20230618;;1;WGRK23060405;10");*/
    /*_onEvent("rS4GuhddcEFEvSmlcNFjAivre7CCpUswnKQnOEY84ZaZ2PTOStw@X5EK5QB7mp3W");
    _onEvent("+jMm0lf+AcNa9wQEoM+AfooanM4bL4d4swxgkvIXh9qwJ1MjtmIX4A==");*/
  }

  void _onEvent(event) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var deptData = sharedPreferences.getString('menuList');
    var menuList = new Map<dynamic, dynamic>.from(jsonDecode(deptData));
    fBarCodeList = menuList['FBarCodeList'];
    if(event == ""){
      return;
    }
    if (fBarCodeList == 1) {
      if(event.split('-').length>2){
        getMaterialListT(event,event.split('-')[2]);
      }else{
        if(event.length>15){
          Map<String, dynamic> barcodeMap = Map();
          barcodeMap['FilterString'] = "FBarCodeEn='" + event + "'";
          barcodeMap['FormId'] = 'QDEP_Cust_BarCodeList';
          barcodeMap['FieldKeys'] =
          'FID,FInQtyTotal,FOutQtyTotal,FEntity_FEntryId,FRemainQty,FBarCodeQty,FStockID.FName,FStockID.FNumber,FMATERIALID.FNUMBER,FOwnerID.FNumber,FBarCode,FSN,FPackageSpec';
          Map<String, dynamic> dataMap = Map();
          dataMap['data'] = barcodeMap;
          String order = await CurrencyEntity.polling(dataMap);
          var barcodeData = jsonDecode(order);
          if (barcodeData.length > 0) {
            if (barcodeData[0][4] > 0) {
            var msg = "";
            var orderIndex = 0;
            print(fNumber);
            for (var value in orderDate) {
              print( value[7]);
              print( barcodeData[0][8]);
              if(value[7] == barcodeData[0][8]){
                msg = "";
                if(fNumber.lastIndexOf(barcodeData[0][8])  == orderIndex){
                  break;
                }
              }else{
                msg = '条码不在单据物料中';
              }
              orderIndex++;
            };
            if(msg ==  ""){
              _code = event;
              this.getMaterialList(barcodeData, barcodeData[0][10], barcodeData[0][11]);
              print("ChannelPage: $event");
            }else{
              ToastUtil.showInfo(msg);
            }
            } else {
              ToastUtil.showInfo('该条码已出库或没入库，数量为零');
            }
          } else {
            ToastUtil.showInfo('条码不在条码清单中');
          }
        }else{
          getMaterialListTH(event,event.substring(9,15));
        }
      }
    } else {
      _code = event;
      this.getMaterialList("", _code, '');
      print("ChannelPage: $event");
    }
    print("ChannelPage: $event");
  }
  getMaterialList(barcodeData, code, fsn) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    var scanCode = code.split(";");
    userMap['FilterString'] = "FNumber='" +scanCode[0] +
        "' and FForbidStatus = 'A' and FUseOrgId.FNumber = " +
        deptData[1];
    userMap['FormId'] = 'BD_MATERIAL';
    userMap['FieldKeys'] =
    'FMATERIALID,F_UUAC_Text,FNumber,FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FIsBatchManage,FStockId.FName,FStockId.FNumber';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    materialDate = [];
    materialDate = jsonDecode(order);
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
          //不启用 && element[4]['value']['value'] == barCodeScan[6]
          if (element[0]['value']['value'] == scanCode[0] ) {
            if (element[0]['value']['barcode'].indexOf(code) == -1) {
              //判断是否可重复扫码
              if (scanCode.length > 4) {
                element[0]['value']['barcode'].add(code);
              }
              if (scanCode[5] == "N") {
                if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                  element[3]['value']['value'] =
                      (double.parse(element[3]['value']['value']) +
                          double.parse(barcodeNum))
                          .toString();
                  element[3]['value']['label'] = element[3]['value']['value'];
                  var item = barCodeScan[0].toString() + "-" + barcodeNum + "-" + fsn;
                  element[0]['value']['kingDeeCode'].add(item);
                  element[0]['value']['scanCode'].add(code);
                  element[10]['value']['label'] = barcodeNum.toString();
                  element[10]['value']['value'] = barcodeNum.toString();
                  barcodeNum =
                      (double.parse(barcodeNum) - double.parse(barcodeNum))
                          .toString();
                }
                break;
              }

              //判断条码数量
              if ((double.parse(element[3]['value']['value']) +
                  double.parse(barcodeNum)) >
                  0 &&
                  double.parse(barcodeNum) > 0) {
                //判断物料是否重复 首个下标是否对应末尾下标
                /*if (fNumber.indexOf(element[0]['value']['value']) ==
                    fNumber.lastIndexOf(element[0]['value']['value'])) {
                  if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                    element[3]['value']['value'] =
                      (double.parse(element[3]['value']['value']) +
                          double.parse(barcodeNum))
                          .toString();
                  element[3]['value']['label'] = element[3]['value']['value'];
                    var item = barCodeScan[0].toString() + "-" + barcodeNum + "-" + fsn;
                    element[0]['value']['kingDeeCode'].add(item);
                    element[0]['value']['scanCode'].add(code);
                    element[10]['value']['label'] = barcodeNum.toString();
                    element[10]['value']['value'] = barcodeNum.toString();
                    barcodeNum =
                        (double.parse(barcodeNum) - double.parse(barcodeNum))
                            .toString();
                    print(2);
                    print(element[0]['value']['kingDeeCode']);
                  }
                } else {*/
                  //判断扫描数量是否大于单据数量
                  if (double.parse(element[3]['value']['value']) >=
                      element[9]['value']['label']) {
                    continue;
                  } else {
                    //判断二维码数量是否大于单据数量
                    if ((double.parse(element[3]['value']['value']) +
                        double.parse(barcodeNum)) >=
                        element[9]['value']['label']) {
                      //判断条码是否重复
                      if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                        var item = barCodeScan[0].toString() +
                            "-" +
                            (element[9]['value']['label'] -
                                double.parse(element[3]['value']['value']))
                                .toString() + "-" + fsn;
                        element[10]['value']['label'] = (element[9]['value']
                        ['label'] -
                            double.parse(element[3]['value']['value']))
                            .toString();
                        element[10]['value']['value'] = (element[9]['value']
                        ['label'] -
                            double.parse(element[3]['value']['value']))
                            .toString();
                        barcodeNum = (double.parse(barcodeNum) -
                            (element[9]['value']['label'] -
                                double.parse(element[3]['value']['value'])))
                            .toString();
                        element[3]['value']['label'] = (double.parse(
                            element[3]['value']['label']) +
                            (element[9]['value']['label'] -
                                double.parse(element[3]['value']['value'])))
                            .toString();
                        element[3]['value']['value'] =
                        element[3]['value']['label'];
                        residue = element[9]['value']['label'] -
                            double.parse(element[3]['value']['value']);
                        element[0]['value']['kingDeeCode'].add(item);
                        element[0]['value']['scanCode'].add(code);
                        print(1);
                        print(element[0]['value']['kingDeeCode']);
                      }
                    } else {
                      //数量不超出
                      //判断条码是否重复
                      if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                        element[3]['value']['label'] =
                            (double.parse(element[3]['value']['value']) +
                                double.parse(barcodeNum))
                                .toString();
                        element[3]['value']['value'] =
                        element[3]['value']['label'];
                        var item = barCodeScan[0].toString() + "-" + barcodeNum + "-" + fsn;
                        element[10]['value']['label'] = barcodeNum.toString();
                        element[10]['value']['value'] = barcodeNum.toString();
                        element[0]['value']['kingDeeCode'].add(item);
                        element[0]['value']['scanCode'].add(code);
                        barcodeNum = (double.parse(barcodeNum) -
                            double.parse(barcodeNum))
                            .toString();
                        print(2);
                        print(element[0]['value']['kingDeeCode']);
                      }
                    }
                  }
                //}
              }
            } else {
              ToastUtil.showInfo('该标签已扫描');
              break;
            }
          }
        } else {

          //启用批号 &&  element[4]['value']['value'] == barCodeScan[6]
          if (element[0]['value']['value'] == scanCode[0] ) {
            if (element[0]['value']['barcode'].indexOf(code) == -1) {
              //判断是否可重复扫码
              if (scanCode.length > 4) {
                element[0]['value']['barcode'].add(code);
              }
              if (scanCode[5] == "N") {
                if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                  if(element[5]['value']['value'] == "") {
                    element[5]['value']['label'] = scanCode[1];
                    element[5]['value']['value'] = scanCode[1];
                  }
                  element[3]['value']['value'] =
                      (double.parse(element[3]['value']['value']) +
                          double.parse(barcodeNum))
                          .toString();
                  element[3]['value']['label'] = element[3]['value']['value'];
                  var item = barCodeScan[0].toString() + "-" + barcodeNum + "-" + fsn;
                  element[0]['value']['kingDeeCode'].add(item);
                  element[0]['value']['scanCode'].add(code);
                  element[10]['value']['label'] = barcodeNum.toString();
                  element[10]['value']['value'] = barcodeNum.toString();
                  barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum))
                      .toString();
                }
                break;
              }
              if (element[5]['value']['value'] == scanCode[1]) {

                //判断条码数量
                if ((double.parse(element[3]['value']['value']) +
                    double.parse(barcodeNum)) >
                    0 &&
                    double.parse(barcodeNum) > 0) {
                  //判断物料是否重复 首个下标是否对应末尾下标
                  /*if (fNumber.indexOf(element[0]['value']['value']) ==
                      fNumber.lastIndexOf(element[0]['value']['value'])) {
                    if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                      element[3]['value']['label'] =
                          (double.parse(element[3]['value']['value']) +
                              double.parse(barcodeNum))
                              .toString();
                      element[3]['value']['value'] =
                      element[3]['value']['label'];
                      var item = barCodeScan[0].toString() + "-" + barcodeNum + "-" + fsn;
                      element[10]['value']['label'] = barcodeNum.toString();
                      element[10]['value']['value'] = barcodeNum.toString();
                      element[0]['value']['kingDeeCode'].add(item);
                      element[0]['value']['scanCode'].add(code);
                      barcodeNum =
                          (double.parse(barcodeNum) - double.parse(barcodeNum))
                              .toString();
                    }
                  } else {*/
                    //判断扫描数量是否大于单据数量
                    if (double.parse(element[3]['value']['value']) >=
                        element[9]['value']['label']) {
                      continue;
                    } else {
                      //判断二维码数量是否大于单据数量
                      if ((double.parse(element[3]['value']['value']) +
                          double.parse(barcodeNum)) >=
                          element[9]['value']['label']) {
                        //判断条码是否重复
                        if (element[0]['value']['scanCode'].indexOf(code) ==
                            -1) {
                          var item = barCodeScan[0].toString() +
                              "-" +
                              (element[9]['value']['label'] -
                                  double.parse(
                                      element[3]['value']['label']))
                                  .toString() + "-" + fsn;
                          element[10]['value']['label'] = (element[9]['value']
                          ['label'] -
                              double.parse(element[3]['value']['value']))
                              .toString();
                          element[10]['value']['value'] = (element[9]['value']
                          ['label'] -
                              double.parse(element[3]['value']['value']))
                              .toString();
                          barcodeNum = (double.parse(barcodeNum) -
                              (element[9]['value']['label'] -
                                  double.parse(
                                      element[3]['value']['label'])))
                              .toString();
                          element[3]['value']['label'] =
                              (double.parse(element[3]['value']['value']) +
                                  (element[9]['value']['label'] -
                                      double.parse(
                                          element[3]['value']['label'])))
                                  .toString();
                          element[3]['value']['value'] =
                          element[3]['value']['label'];
                          residue = element[9]['value']['label'] -
                              double.parse(element[3]['value']['value']);
                          element[0]['value']['kingDeeCode'].add(item);
                          element[0]['value']['scanCode'].add(code);
                          print(1);
                          print(element[0]['value']['kingDeeCode']);
                        }
                      } else {
                        //数量不超出
                        //判断条码是否重复
                        if (element[0]['value']['scanCode'].indexOf(code) ==
                            -1) {
                          element[3]['value']['label'] =
                              (double.parse(element[3]['value']['value']) +
                                  double.parse(barcodeNum))
                                  .toString();
                          element[3]['value']['value'] =
                          element[3]['value']['label'];
                          var item =
                              barCodeScan[0].toString() + "-" + barcodeNum + "-" + fsn;
                          element[10]['value']['label'] = barcodeNum.toString();
                          element[10]['value']['value'] = barcodeNum.toString();
                          element[0]['value']['kingDeeCode'].add(item);
                          element[0]['value']['scanCode'].add(code);
                          barcodeNum = (double.parse(barcodeNum) -
                              double.parse(barcodeNum))
                              .toString();
                          print(2);
                          print(element[0]['value']['kingDeeCode']);
                        }
                      }
                    }
                  //}
                }
              } else {
                if (element[5]['value']['value'] == "") {
                  element[5]['value']['label'] = scanCode[1];
                  element[5]['value']['value'] = scanCode[1];
                  //判断条码数量
                  if ((double.parse(element[3]['value']['value']) +
                      double.parse(barcodeNum)) >
                      0 &&
                      double.parse(barcodeNum) > 0) {
                    //判断物料是否重复 首个下标是否对应末尾下标
                    /*if (fNumber.indexOf(element[0]['value']['value']) ==
                        fNumber.lastIndexOf(element[0]['value']['value'])) {
                      if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                        element[3]['value']['label'] =
                            (double.parse(element[3]['value']['value']) +
                                double.parse(barcodeNum))
                                .toString();
                        element[3]['value']['value'] =
                        element[3]['value']['label'];
                        var item = barCodeScan[0].toString() + "-" + barcodeNum + "-" + fsn;
                        element[10]['value']['label'] = barcodeNum.toString();
                        element[10]['value']['value'] = barcodeNum.toString();
                        element[0]['value']['kingDeeCode'].add(item);
                        element[0]['value']['scanCode'].add(code);
                        barcodeNum = (double.parse(barcodeNum) -
                            double.parse(barcodeNum))
                            .toString();
                        print(2);
                        print(element[0]['value']['kingDeeCode']);
                      }
                    } else {*/
                      //判断扫描数量是否大于单据数量
                      if (double.parse(element[3]['value']['value']) >=
                          element[9]['value']['label']) {
                        continue;
                      } else {
                        //判断二维码数量是否大于单据数量
                        if ((double.parse(element[3]['value']['value']) +
                            double.parse(barcodeNum)) >=
                            element[9]['value']['label']) {
                          //判断条码是否重复
                          if (element[0]['value']['scanCode'].indexOf(code) ==
                              -1) {
                            var item = barCodeScan[0].toString() +
                                "-" +
                                (element[9]['value']['label'] -
                                    double.parse(
                                        element[3]['value']['label']))
                                    .toString() + "-" + fsn;
                            element[10]['value']['label'] = (element[9]['value']
                            ['label'] -
                                double.parse(element[3]['value']['value']))
                                .toString();
                            element[10]['value']['value'] = (element[9]['value']
                            ['label'] -
                                double.parse(element[3]['value']['value']))
                                .toString();
                            barcodeNum = (double.parse(barcodeNum) -
                                (element[9]['value']['label'] -
                                    double.parse(
                                        element[3]['value']['label'])))
                                .toString();
                            element[3]['value']['label'] =
                                (double.parse(element[3]['value']['value']) +
                                    (element[9]['value']['label'] -
                                        double.parse(
                                            element[3]['value']['label'])))
                                    .toString();
                            element[3]['value']['value'] =
                            element[3]['value']['label'];
                            residue = element[9]['value']['label'] -
                                double.parse(element[3]['value']['value']);
                            element[0]['value']['kingDeeCode'].add(item);
                            element[0]['value']['scanCode'].add(code);
                            print(1);
                            print(element[0]['value']['kingDeeCode']);
                          }
                        } else {
                          //数量不超出
                          //判断条码是否重复
                          if (element[0]['value']['scanCode'].indexOf(code) ==
                              -1) {
                            element[3]['value']['label'] =
                                (double.parse(element[3]['value']['value']) +
                                    double.parse(barcodeNum))
                                    .toString();
                            element[3]['value']['value'] =
                            element[3]['value']['label'];
                            var item =
                                barCodeScan[0].toString() + "-" + barcodeNum + "-" + fsn;
                            element[10]['value']['label'] =
                                barcodeNum.toString();
                            element[10]['value']['value'] =
                                barcodeNum.toString();
                            element[0]['value']['kingDeeCode'].add(item);
                            element[0]['value']['scanCode'].add(code);
                            barcodeNum = (double.parse(barcodeNum) -
                                double.parse(barcodeNum))
                                .toString();
                            print(2);
                            print(element[0]['value']['kingDeeCode']);
                          }
                        }
                      }
                    //}
                  }
                }
              }
            } else {
              ToastUtil.showInfo('该标签已扫描');
              break;
            }
          }
        }
      }
      if (number == 0 && this.fBillNo == "") {
        materialDate.forEach((value) {
          List arr = [];
          arr.add({
            "title": "物料子码",
            "name": "FMaterialId",
            "isHide": false,
            "value": {"label": value[1], "value": value[2], "barcode": []}
          });
          arr.add({
            "title": "生产车间",
            "name": "FWorkShopID",
            "isHide": false,
            "value": {"label": "", "value": ""}
          });
          arr.add({
            "title": "预测批号",
            "name": "",
            "isHide": value[6] != true,
            "value": {
              "label": value[6] ? (scanCode.length > 1 ? scanCode[1] : '') : '',
              "value": value[6] ? (scanCode.length > 1 ? scanCode[1] : '') : ''
            }
          });
          arr.add({
            "title": "需生产数量",
            "name": "FQty",
            "isHide": false,
            "value": {"label": "0", "value": "0"}
          });
          arr.add({
            "title": "良品数量",
            "name": "goodProductNumber",
            "isHide": false,
            "value": {"label": "0", "value": "0"}
          });
          arr.add({
            "title": "良品仓库",
            "name": "goodProductStock",
            "isHide": false,
            "value": {"label": "", "value": ""}
          });
          arr.add({
            "title": "不合格数量",
            "name": "rejectsNumber",
            "isHide": false,
            "value": {"label": "0", "value": "0"}
          });
          arr.add({
            "title": "不合格仓库",
            "name": "rejectsStock",
            "isHide": false,
            "value": {"label": "", "value": ""}
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
  getMaterialListT(code, fsn) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];

    userMap['FilterString'] = "F_UYEP_GYSTM='"+code.split('-')[0]+"' and FForbidStatus = 'A' and FUseOrgId.FNumber = '"+deptData[1]+"'";
    userMap['FormId'] = 'BD_MATERIAL';
    userMap['FieldKeys'] =
    'FMATERIALID,FName,FNumber,FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FIsBatchManage';/*,SubHeadEntity1.FStoreUnitID.FNumber*/
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    materialDate = [];
    materialDate = jsonDecode(order);
    var scanCode = [materialDate[0][2],code.split("-")[1],"","","","N"];
    if (materialDate.length > 0) {
      var msg = "";
      var orderIndex = 0;
      for (var value in orderDate) {
        if(value[7] == materialDate[0][2]){
          msg = "";
          if(fNumber.lastIndexOf(materialDate[0][2])  == orderIndex){
            break;
          }
        }else{
          msg = '条码不在单据物料中';
        }
        orderIndex++;
      };
      if(msg !=  ""){
        ToastUtil.showInfo(msg);
        return;
      }
      var number = 0;
      var barcodeNum = '1';
      for (var element in hobby) {
        var residue = 0.0;
        //判断是否启用批号
        if(element[5]['isHide']){//不启用
          if(element[0]['value']['value'] == scanCode[0]){
            if(element[0]['value']['barcode'].indexOf(code) == -1){
              if(scanCode.length>4) {
                element[0]['value']['barcode'].add(code);
              }
              if(scanCode[5] == "N" ){
                if(element[0]['value']['scanCode'].indexOf(code) == -1){
                  element[3]['value']['value']=(double.parse(element[3]['value']['value'])+double.parse(barcodeNum)).toString();
                    element[3]['value']['label']=element[3]['value']['value'];
                  element[0]['value']['scanCode'].add(code);
                  element[0]['value']['kingDeeCode'].add(fsn);
                  element[10]['value']['label'] = barcodeNum.toString();
                  element[10]['value']['value'] = barcodeNum.toString();
                  barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                }
                break;
              }
              //判断扫描数量是否大于单据数量
              if(double.parse(element[3]['value']['value']) >= element[9]['value']['rateValue']) {
                continue;
              }else {
                //判断条码数量
                if((double.parse(element[3]['value']['value'])+double.parse(barcodeNum)) > 0 && double.parse(barcodeNum)>0){
                  if((double.parse(element[3]['value']['value'])+double.parse(barcodeNum)) >= element[9]['value']['rateValue']){
                    //判断条码是否重复
                    if(element[0]['value']['scanCode'].indexOf(code) == -1){
                      element[10]['value']['label'] =(element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toString();
                      element[10]['value']['value'] = (element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toString();
                      barcodeNum = (double.parse(barcodeNum) - (element[9]['value']['rateValue'] - double.parse(element[3]['value']['value']))).toString();
                      element[3]['value']['label']=(double.parse(element[3]['value']['value'])+(element[9]['value']['rateValue'] - double.parse(element[3]['value']['value']))).toString();
                      element[3]['value']['value']=element[3]['value']['label'];
                      residue = element[9]['value']['rateValue'] - double.parse(element[3]['value']['value']);
                      element[0]['value']['scanCode'].add(code);
                      element[0]['value']['kingDeeCode'].add(fsn);
                    }
                  }else{//数量不超出
                    //判断条码是否重复
                    if(element[0]['value']['scanCode'].indexOf(code) == -1){
                      element[3]['value']['value']=(double.parse(element[3]['value']['value'])+double.parse(barcodeNum)).toString();
                    element[3]['value']['label']=element[3]['value']['value'];
                      element[10]['value']['label'] =barcodeNum.toString();
                      element[10]['value']['value'] = barcodeNum.toString();
                      element[0]['value']['scanCode'].add(code);
                      element[0]['value']['kingDeeCode'].add(fsn);
                      barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                    }
                  }
                }
              }
            }else{
              ToastUtil.showInfo('该标签已扫描');
              break;
            }
          }
        }else{
          //启用批号
          if(element[0]['value']['value'] == scanCode[0]){
            if(element[0]['value']['barcode'].indexOf(code) == -1){
              if(scanCode.length>4) {
                element[0]['value']['barcode'].add(code);
              }
              if(scanCode[5] == "N" ){
                if(element[0]['value']['scanCode'].indexOf(code) == -1){
                  if(element[5]['value']['value'] == "") {
                    element[5]['value']['label'] = scanCode[1];
                    element[5]['value']['value'] = scanCode[1];
                  }
                  element[3]['value']['value']=(double.parse(element[3]['value']['value'])+double.parse(barcodeNum)).toString();
                    element[3]['value']['label']=element[3]['value']['value'];
                  element[0]['value']['scanCode'].add(code);
                  element[0]['value']['kingDeeCode'].add(fsn);
                  element[10]['value']['label'] = barcodeNum.toString();
                  element[10]['value']['value'] = barcodeNum.toString();
                  barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                }
                break;
              }
              if(element[5]['value']['value'] == scanCode[1]){
                //判断扫描数量是否大于单据数量
                if(double.parse(element[3]['value']['value']) >= element[9]['value']['rateValue']) {
                  continue;
                }else {
                  //判断条码数量
                  if((double.parse(element[3]['value']['value'])+double.parse(barcodeNum)) > 0 && double.parse(barcodeNum)>0){
                    if((double.parse(element[3]['value']['value'])+double.parse(barcodeNum)) >= element[9]['value']['rateValue']){
                      //判断条码是否重复
                      if(element[0]['value']['scanCode'].indexOf(code) == -1){
                        element[10]['value']['label'] =(element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toString();
                        element[10]['value']['value'] = (element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toString();
                        barcodeNum = (double.parse(barcodeNum) - (element[9]['value']['rateValue'] - double.parse(element[3]['value']['value']))).toString();
                        element[3]['value']['label']=(double.parse(element[3]['value']['value'])+(element[9]['value']['rateValue'] - double.parse(element[3]['value']['value']))).toString();
                        element[3]['value']['value']=element[3]['value']['label'];
                        residue = element[9]['value']['rateValue'] - double.parse(element[3]['value']['value']);
                        element[0]['value']['scanCode'].add(code);
                        element[0]['value']['kingDeeCode'].add(fsn);
                      }
                    }else{//数量不超出
                      //判断条码是否重复
                      if(element[0]['value']['scanCode'].indexOf(code) == -1){
                        element[3]['value']['value']=(double.parse(element[3]['value']['value'])+double.parse(barcodeNum)).toString();
                    element[3]['value']['label']=element[3]['value']['value'];
                        element[10]['value']['label'] =barcodeNum.toString();
                        element[10]['value']['value'] = barcodeNum.toString();
                        element[0]['value']['scanCode'].add(code);
                        element[0]['value']['kingDeeCode'].add(fsn);
                        barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                      }
                    }
                  }
                }
              }else{
                if(element[5]['value']['value'] == ""){
                  element[5]['value']['label'] = scanCode[1];
                  element[5]['value']['value'] = scanCode[1];
                  //判断扫描数量是否大于单据数量
                  if(double.parse(element[3]['value']['value']) >= element[9]['value']['rateValue']) {
                    continue;
                  }else {
                    //判断条码数量
                    if((double.parse(element[3]['value']['value'])+double.parse(barcodeNum)) > 0 && double.parse(barcodeNum)>0){
                      if((double.parse(element[3]['value']['value'])+double.parse(barcodeNum)) >= element[9]['value']['rateValue']){
                        //判断条码是否重复
                        if(element[0]['value']['scanCode'].indexOf(code) == -1){
                          element[10]['value']['label'] =(element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toString();
                          element[10]['value']['value'] = (element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toString();
                          barcodeNum = (double.parse(barcodeNum) - (element[9]['value']['rateValue'] - double.parse(element[3]['value']['value']))).toString();
                          element[3]['value']['label']=(double.parse(element[3]['value']['value'])+(element[9]['value']['rateValue'] - double.parse(element[3]['value']['value']))).toString();
                          element[3]['value']['value']=element[3]['value']['label'];
                          residue = element[9]['value']['rateValue'] - double.parse(element[3]['value']['value']);
                          element[0]['value']['scanCode'].add(code);
                          element[0]['value']['kingDeeCode'].add(fsn);
                        }
                      }else{//数量不超出
                        //判断条码是否重复
                        if(element[0]['value']['scanCode'].indexOf(code) == -1){
                          element[3]['value']['value']=(double.parse(element[3]['value']['value'])+double.parse(barcodeNum)).toString();
                    element[3]['value']['label']=element[3]['value']['value'];
                          element[10]['value']['label'] =barcodeNum.toString();
                          element[10]['value']['value'] = barcodeNum.toString();
                          element[0]['value']['scanCode'].add(code);
                          element[0]['value']['kingDeeCode'].add(fsn);
                          barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                        }
                      }
                    }
                  }
                }
              }
            }else{
              ToastUtil.showInfo('该标签已扫描');
              break;
            }
          }
        }
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
  getMaterialListTH(code, fsn) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];

    userMap['FilterString'] = "F_UYEP_GYSTM='"+code.substring(0,3)+"' and FForbidStatus = 'A' and FUseOrgId.FNumber = '"+deptData[1]+"'";
    userMap['FormId'] = 'BD_MATERIAL';
    userMap['FieldKeys'] =
    'FMATERIALID,FName,FNumber,FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FIsBatchManage';/*,SubHeadEntity1.FStoreUnitID.FNumber*/
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    materialDate = [];
    materialDate = jsonDecode(order);
    var scanCode = [materialDate[0][2],code.substring(3,9),"","","","N"];
    if (materialDate.length > 0) {
      var msg = "";
      var orderIndex = 0;
      for (var value in orderDate) {
        if(value[7] == materialDate[0][2]){
          msg = "";
          if(fNumber.lastIndexOf(materialDate[0][2])  == orderIndex){
            break;
          }
        }else{
          msg = '条码不在单据物料中';
        }
        orderIndex++;
      };
      if(msg !=  ""){
        ToastUtil.showInfo(msg);
        return;
      }
      var number = 0;
      var barcodeNum = '1';
      for (var element in hobby) {
        var residue = 0.0;
        //判断是否启用批号
        if(element[5]['isHide']){//不启用
          if(element[0]['value']['value'] == scanCode[0]){
            if(element[0]['value']['barcode'].indexOf(code) == -1){
              if(scanCode.length>4) {
                element[0]['value']['barcode'].add(code);
              }
              if(scanCode[5] == "N" ){
                if(element[0]['value']['scanCode'].indexOf(code) == -1){
                  element[3]['value']['value']=(double.parse(element[3]['value']['value'])+double.parse(barcodeNum)).toString();
                    element[3]['value']['label']=element[3]['value']['value'];
                  element[0]['value']['scanCode'].add(code);
                  element[0]['value']['kingDeeCode'].add(fsn);
                  element[10]['value']['label'] = barcodeNum.toString();
                  element[10]['value']['value'] = barcodeNum.toString();
                  barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                }
                break;
              }
              //判断扫描数量是否大于单据数量
              if(double.parse(element[3]['value']['value']) >= element[9]['value']['rateValue']) {
                continue;
              }else {
                //判断条码数量
                if((double.parse(element[3]['value']['value'])+double.parse(barcodeNum)) > 0 && double.parse(barcodeNum)>0){
                  if((double.parse(element[3]['value']['value'])+double.parse(barcodeNum)) >= element[9]['value']['rateValue']){
                    //判断条码是否重复
                    if(element[0]['value']['scanCode'].indexOf(code) == -1){
                      element[10]['value']['label'] =(element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toString();
                      element[10]['value']['value'] = (element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toString();
                      barcodeNum = (double.parse(barcodeNum) - (element[9]['value']['rateValue'] - double.parse(element[3]['value']['value']))).toString();
                      element[3]['value']['label']=(double.parse(element[3]['value']['value'])+(element[9]['value']['rateValue'] - double.parse(element[3]['value']['value']))).toString();
                      element[3]['value']['value']=element[3]['value']['label'];
                      residue = element[9]['value']['rateValue'] - double.parse(element[3]['value']['value']);
                      element[0]['value']['scanCode'].add(code);
                      element[0]['value']['kingDeeCode'].add(fsn);
                    }
                  }else{//数量不超出
                    //判断条码是否重复
                    if(element[0]['value']['scanCode'].indexOf(code) == -1){
                      element[3]['value']['value']=(double.parse(element[3]['value']['value'])+double.parse(barcodeNum)).toString();
                    element[3]['value']['label']=element[3]['value']['value'];
                      element[10]['value']['label'] =barcodeNum.toString();
                      element[10]['value']['value'] = barcodeNum.toString();
                      element[0]['value']['scanCode'].add(code);
                      element[0]['value']['kingDeeCode'].add(fsn);
                      barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                    }
                  }
                }
              }
            }else{
              ToastUtil.showInfo('该标签已扫描');
              break;
            }
          }
        }else{
          //启用批号
          if(element[0]['value']['value'] == scanCode[0]){
            if(element[0]['value']['barcode'].indexOf(code) == -1){
              if(scanCode.length>4) {
                element[0]['value']['barcode'].add(code);
              }
              if(scanCode[5] == "N" ){
                if(element[0]['value']['scanCode'].indexOf(code) == -1){
                  if(element[5]['value']['value'] == "") {
                    element[5]['value']['label'] = scanCode[1];
                    element[5]['value']['value'] = scanCode[1];
                  }
                  element[3]['value']['value']=(double.parse(element[3]['value']['value'])+double.parse(barcodeNum)).toString();
                    element[3]['value']['label']=element[3]['value']['value'];
                  element[0]['value']['scanCode'].add(code);
                  element[0]['value']['kingDeeCode'].add(fsn);
                  element[10]['value']['label'] = barcodeNum.toString();
                  element[10]['value']['value'] = barcodeNum.toString();
                  barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                }
                break;
              }
              if(element[5]['value']['value'] == scanCode[1]){
                //判断扫描数量是否大于单据数量
                if(double.parse(element[3]['value']['value']) >= element[9]['value']['rateValue']) {
                  continue;
                }else {
                  //判断条码数量
                  if((double.parse(element[3]['value']['value'])+double.parse(barcodeNum)) > 0 && double.parse(barcodeNum)>0){
                    if((double.parse(element[3]['value']['value'])+double.parse(barcodeNum)) >= element[9]['value']['rateValue']){
                      //判断条码是否重复
                      if(element[0]['value']['scanCode'].indexOf(code) == -1){
                        element[10]['value']['label'] =(element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toString();
                        element[10]['value']['value'] = (element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toString();
                        barcodeNum = (double.parse(barcodeNum) - (element[9]['value']['rateValue'] - double.parse(element[3]['value']['value']))).toString();
                        element[3]['value']['label']=(double.parse(element[3]['value']['value'])+(element[9]['value']['rateValue'] - double.parse(element[3]['value']['value']))).toString();
                        element[3]['value']['value']=element[3]['value']['label'];
                        residue = element[9]['value']['rateValue'] - double.parse(element[3]['value']['value']);
                        element[0]['value']['scanCode'].add(code);
                        element[0]['value']['kingDeeCode'].add(fsn);
                      }
                    }else{//数量不超出
                      //判断条码是否重复
                      if(element[0]['value']['scanCode'].indexOf(code) == -1){
                        element[3]['value']['value']=(double.parse(element[3]['value']['value'])+double.parse(barcodeNum)).toString();
                    element[3]['value']['label']=element[3]['value']['value'];
                        element[10]['value']['label'] =barcodeNum.toString();
                        element[10]['value']['value'] = barcodeNum.toString();
                        element[0]['value']['scanCode'].add(code);
                        element[0]['value']['kingDeeCode'].add(fsn);
                        barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                      }
                    }
                  }
                }
              }else{
                if(element[5]['value']['value'] == ""){
                  element[5]['value']['label'] = scanCode[1];
                  element[5]['value']['value'] = scanCode[1];
                  //判断扫描数量是否大于单据数量
                  if(double.parse(element[3]['value']['value']) >= element[9]['value']['rateValue']) {
                    continue;
                  }else {
                    //判断条码数量
                    if((double.parse(element[3]['value']['value'])+double.parse(barcodeNum)) > 0 && double.parse(barcodeNum)>0){
                      if((double.parse(element[3]['value']['value'])+double.parse(barcodeNum)) >= element[9]['value']['rateValue']){
                        //判断条码是否重复
                        if(element[0]['value']['scanCode'].indexOf(code) == -1){
                          element[10]['value']['label'] =(element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toString();
                          element[10]['value']['value'] = (element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toString();
                          barcodeNum = (double.parse(barcodeNum) - (element[9]['value']['rateValue'] - double.parse(element[3]['value']['value']))).toString();
                          element[3]['value']['label']=(double.parse(element[3]['value']['value'])+(element[9]['value']['rateValue'] - double.parse(element[3]['value']['value']))).toString();
                          element[3]['value']['value']=element[3]['value']['label'];
                          residue = element[9]['value']['rateValue'] - double.parse(element[3]['value']['value']);
                          element[0]['value']['scanCode'].add(code);
                          element[0]['value']['kingDeeCode'].add(fsn);
                        }
                      }else{//数量不超出
                        //判断条码是否重复
                        if(element[0]['value']['scanCode'].indexOf(code) == -1){
                          element[3]['value']['value']=(double.parse(element[3]['value']['value'])+double.parse(barcodeNum)).toString();
                    element[3]['value']['label']=element[3]['value']['value'];
                          element[10]['value']['label'] =barcodeNum.toString();
                          element[10]['value']['value'] = barcodeNum.toString();
                          element[0]['value']['scanCode'].add(code);
                          element[0]['value']['kingDeeCode'].add(fsn);
                          barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                        }
                      }
                    }
                  }
                }
              }
            }else{
              ToastUtil.showInfo('该标签已扫描');
              break;
            }
          }
        }
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
  void _onError(Object error) {
    setState(() {
      _code = "扫描异常";
    });
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
        setState(() async {
          switch (model) {
            case DateMode.YMD:
              Map<String, dynamic> userMap = Map();
              selectData[model] = '${p.year}-${p.month}-${p.day}';
              FDate = '${p.year}-${p.month}-${p.day}';
              await getOrderList();
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
          hobby['value']['label'] = p;
        });
        var ele;
        for(var i = 0;i<data.length;i++){
          if (data[i] == p) {
            hobby['value']['value'] = stockListObj[i][2];
            break;
          }
        }
      },
    );
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
  List<Widget> _getHobby() {
    List<Widget> tempList = [];
    for (int i = 0; i < this.hobby.length; i++) {
      List<Widget> comList = [];
      for (int j = 0; j < this.hobby[i].length; j++) {
        if (!this.hobby[i][j]['isHide']) {
          if (j == 5) {
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
                              icon: new Icon(Icons.mode_edit),
                              tooltip: '输入数量',
                              padding: EdgeInsets.only(left: 30),
                              onPressed: () {
                                this._textNumber.text =
                                    this.hobby[i][j]["value"]["label"].toString();
                                this._FNumber =
                                    this.hobby[i][j]["value"]["label"].toString();
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
          } else
          if (j == 4) {
            comList.add(
              _item('仓库:', stockList, this.hobby[i][j]['value']['label'],
                  this.hobby[i][j],
                  stock: this.hobby[i]),
            );
          }else {
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
          /* }*/
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

  //修改状态
  alterStatus(dataMap) async {
    var status = await SubmitEntity.alterStatus(dataMap);
    print(status);
    if (status != null) {
      var res = jsonDecode(status);
      print(res);
      if (res != null) {
        return res;
      }
    }
  }

  /*this.hobby = [];
          this.orderDate = [];
          this.FBillNo = '';
          this.FSaleOrderNo = '';
          ToastUtil.showInfo('提交成功');*/

  // 领料后操作
  handlerStatus() async {
    //修改为开工状态
    Map<String, dynamic> dataMap = Map();
    var numbers = [];
    dataMap['formid'] = 'PRD_MO';
    dataMap['opNumber'] = 'toStart';
    Map<String, dynamic> entityMap = Map();
    entityMap['Id'] = fid;
    entityMap['EntryIds'] = fEntryId;
    numbers.add(entityMap);
    dataMap['data'] = {'PkEntryIds': numbers};
    var startRes = await this.alterStatus(dataMap);
    print(startRes);
    if (startRes['Result']['ResponseStatus']['IsSuccess']) {
      var serialNum = FProdOrder.truncate();
      for(var i = serialNum;i<=4;i++){
        //查询生产订单
        Map<String, dynamic> userMap = Map();
        userMap['FilterString'] = "FSaleOrderNo='$FBarcode' and FProdOrder >= " + (serialNum).toString() + " and FProdOrder <" + (serialNum + 1).toString();
        userMap['FormId'] = "PRD_MO";
        userMap['FieldKeys'] =
        'FBillNo,FTreeEntity_FEntryId,FID,FProdOrder,FTreeEntity_FSeq';
        Map<String, dynamic> proMoDataMap = Map();
        proMoDataMap['data'] = userMap;
        String order = await CurrencyEntity.polling(proMoDataMap);
        var orderRes = jsonDecode(order);
        if(orderRes.length > 0){
          break;
        }
      }
      //查询生产订单
      Map<String, dynamic> userMap = Map();
      userMap['FilterString'] = "FSaleOrderNo='$FBarcode' and FProdOrder >= " + (serialNum+1).toString() + " and FProdOrder <" + (serialNum + 2).toString();
      userMap['FormId'] = "PRD_MO";
      userMap['FieldKeys'] =
      'FBillNo,FTreeEntity_FEntryId,FID,FProdOrder,FTreeEntity_FSeq';
      Map<String, dynamic> proMoDataMap = Map();
      proMoDataMap['data'] = userMap;
      String order = await CurrencyEntity.polling(proMoDataMap);
      var orderRes = jsonDecode(order);
      if(orderRes.length > 0){
        orderRes.forEach((element) async {
          //查询用料清单
          Map<String, dynamic> materialsMap = Map();
          var FMOEntrySeq = element[4];
          var FMOBillNo = element[0];
          materialsMap['FilterString'] = "FMOBillNO=" +
              FMOBillNo.toString() +
              " and FMOEntrySeq = " +
              FMOEntrySeq.toString();
          materialsMap['FormId'] = 'SUB_PPBOM';
          materialsMap['FieldKeys'] =
          'FID';
          Map<String, dynamic> materialsDataMap = Map();
          materialsDataMap['data'] = materialsMap;
          String materialsMapOrder =
          await CurrencyEntity.polling(materialsDataMap);
          //修改用料清单为审核状态
          Map<String, dynamic> auditDataMap = Map();
          auditDataMap = {
            "formid": "SUB_PPBOM",
            "data": {'Ids': materialsMapOrder[0][0]}
          };
          await SubmitEntity.submit(auditDataMap);
          var auditRes = await SubmitEntity.audit(auditDataMap);
          //修改为下达状态
          Map<String, dynamic> releaseDataMap = Map();
          var releaseNumbers = [];
          releaseDataMap['formid'] = 'PRD_MO';
          releaseDataMap['opNumber'] = 'ToRelease';
          Map<String, dynamic> releaseEntityMap = Map();
          releaseEntityMap['Id'] = element[2];
          releaseEntityMap['EntryIds'] = element[1];
          releaseNumbers.add(releaseEntityMap);
          releaseDataMap['data'] = {'PkEntryIds': releaseNumbers};
          var releaseRes = await this.alterStatus(releaseDataMap);
          if (releaseRes['Result']['ResponseStatus']['IsSuccess']) {
            this.hobby = [];
            this.orderDate = [];
            this.FBillNo = '';
            ToastUtil.showInfo('提交成功');
            Navigator.of(context).pop("refresh");
          } else {
            setState(() {
              ToastUtil.showInfo(releaseRes['Result']['ResponseStatus']
              ['Errors'][0]['Message']);
            });
          }
        });
      }else{
        this.hobby = [];
        this.orderDate = [];
        this.FBillNo = '';
        ToastUtil.showInfo('提交成功');
        Navigator.of(context).pop("refresh");
      }
    } else {
      setState(() {
        this.isSubmit = false;
        ToastUtil.errorDialog(context,
            startRes['Result']['ResponseStatus']['Errors'][0]['Message']);
      });

    }
  }
  //删除
  deleteOrder(Map<String, dynamic> map,title) async {
    var subData = await SubmitEntity.delete(map);
    print(subData);
    if (subData != null) {
      var res = jsonDecode(subData);
      if (res != null) {
        if (res['Result']['ResponseStatus']['IsSuccess']) {
          /* this.hobby = [];
          this.orderDate = [];
          this.FBillNo = '';
          ToastUtil.showInfo('提交成功');
          Navigator.of(context).pop("refresh");*/
          setState(() {
            this.isSubmit = false;
            ToastUtil.errorDialog(context,
                title);
          });
        } else {
          setState(() {
            this.isSubmit = false;
            ToastUtil.errorDialog(context,
                res['Result']['ResponseStatus']['Errors'][0]['Message']);
          });
        }
      }
    }
  }
  //反审核
  unAuditOrder(Map<String, dynamic> map,title) async {
    var subData = await SubmitEntity.unAudit(map);
    print(subData);
    if (subData != null) {
      var res = jsonDecode(subData);
      if (res != null) {
        if (res['Result']['ResponseStatus']['IsSuccess']) {
          //提交清空页面
          Map<String, dynamic> deleteMap = Map();
          deleteMap = {
            "formid": "SUB_PickMtrl",
            "data": {
              'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
            }
          };
          deleteOrder(deleteMap,title);
        } else {
          setState(() {
            this.isSubmit = false;
            ToastUtil.errorDialog(context,
                res['Result']['ResponseStatus']['Errors'][0]['Message']);
          });
        }
      }
    }
  }
  //审核
  auditOrder(Map<String, dynamic> auditMap) async {
    var subData = await SubmitEntity.audit(auditMap);
    print(subData);
    if (subData != null) {
      var res = jsonDecode(subData);
      if (res != null) {
        if (res['Result']['ResponseStatus']['IsSuccess']) {
          var errorMsg = "";
          if (fBarCodeList == 1) {
            for (int i = 0; i < this.hobby.length; i++) {
              if (this.hobby[i][3]['value']['value'] != '0') {
                var kingDeeCode = this.hobby[i][0]['value']['kingDeeCode'];
                for (int j = 0; j < kingDeeCode.length; j++) {
                  Map<String, dynamic> dataCodeMap = Map();
                  dataCodeMap['formid'] = 'QDEP_Cust_BarCodeList';
                  Map<String, dynamic> orderCodeMap = Map();
                  orderCodeMap['NeedReturnFields'] = [];
                  orderCodeMap['IsDeleteEntry'] = false;
                  Map<String, dynamic> codeModel = Map();
                  var itemCode = kingDeeCode[j].split("-");
                  codeModel['FID'] = itemCode[0];
                  Map<String, dynamic> codeFEntityItem = Map();
                  codeFEntityItem['FBillDate'] = FDate;
                  codeFEntityItem['FOutQty'] = itemCode[1];
                  codeFEntityItem['FEntryBillNo'] = orderDate[i][0];
                  codeFEntityItem['FEntryStockID'] = {
                    "FNUMBER": this.hobby[i][4]['value']['value']
                  };
                  var codeFEntity = [codeFEntityItem];
                  codeModel['FEntity'] = codeFEntity;
                  orderCodeMap['Model'] = codeModel;
                  dataCodeMap['data'] = orderCodeMap;
                  print(dataCodeMap);
                  String codeRes = await SubmitEntity.save(dataCodeMap);
                  var barcodeRes = jsonDecode(codeRes);
                  if (!barcodeRes['Result']['ResponseStatus']['IsSuccess']) {
                    errorMsg += "错误反馈：" +
                        itemCode[1] +
                        ":" +
                        barcodeRes['Result']['ResponseStatus']['Errors'][0]
                        ['Message'];
                  }
                  print(codeRes);
                }
              }
            }
          }
          if (errorMsg != "") {
            ToastUtil.errorDialog(context, errorMsg);
          }
          //提交清空页面
          /*handlerStatus();*/
          this.hobby = [];
          this.orderDate = [];
          this.FBillNo = '';
          ToastUtil.showInfo('提交成功');
          Navigator.of(context).pop("refresh");
        } else {
          unAuditOrder(auditMap,res['Result']['ResponseStatus']['Errors'][0]['Message']);
          /*setState(() {
            this.isSubmit = false;
            ToastUtil.errorDialog(context,
                res['Result']['ResponseStatus']['Errors'][0]['Message']);
          });*/
        }
      }
    }
  }

  //提交
  submitOrder(Map<String, dynamic> submitMap) async {
    var subData = await SubmitEntity.submit(submitMap);
    print(subData);
    if (subData != null) {
      var res = jsonDecode(subData);
      if (res != null) {
        if (res['Result']['ResponseStatus']['IsSuccess']) {
          //提交清空页面
          Map<String, dynamic> auditMap = Map();
          auditMap = {
            "formid": "SUB_PickMtrl",
            "data": {
              'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
            }
          };
          auditOrder(auditMap);
        } else {
          setState(() {
            this.isSubmit = false;
            ToastUtil.errorDialog(context,
                res['Result']['ResponseStatus']['Errors'][0]['Message']);
          });
        }
      }
    }
  }

  //保存
  saveOrder() async {
    Map<String, dynamic> dataMap = Map();
    dataMap['formid'] = 'SUB_PickMtrl';
    Map<String, dynamic> orderMap = Map();
    orderMap['NeedUpDataFields'] = ['FEntity','FSerialSubEntity','FSerialNo'];
    orderMap['NeedReturnFields'] = ['FEntity','FSerialSubEntity','FSerialNo'];
    orderMap['IsDeleteEntry'] = true;
    Map<String, dynamic> Model = Map();
    Model['FID'] = collarOrderDate[0][0];
    var orderData = [];
    var orderDataList = [];
    for(var item in collarOrderDate){
      if(orderData.indexOf(item[3]) == -1){
        orderData.add(item[3]);
        orderDataList.add(item);
      }
    }
    var FEntity = [];
    var hobbyIndex = 0;
    for(var element in this.hobby){
      for(var collarOrder in orderDataList){
        if(collarOrder[3] == element[0]['value']['value']){
          if (element[3]['value']['value'] != '0') {
            print(orderData.indexOf(element[0]['value']['value']));
            Map<String, dynamic> FEntityItem = Map();
            FEntityItem['FActualQty'] = element[3]['value']['value'];
            FEntityItem['FEntryID'] = collarOrder[1];
            /* FEntityItem['FUnitId'] = {"FNumber": element[2]['value']['value']};*/
            /* FEntityItem['FStockId'] = {
          "FNumber": fBillNo.substring(0, 2) == "FO"
              ? 'XBC001'
              : collarOrderDate[hobbyIndex][2]
        };*/
            //FEntityItem['FStockStatusId'] = {"FNumber": "KCZT01_SYS"};
            FEntityItem['FStockId'] = {
              "FNumber": element[4]['value']['value']
            };
            FEntityItem['FLot'] = {
              "FNumber": element[5]['value']['value']
            };
            var fSerialSub = [];
            var kingDeeCode = element[0]['value']['kingDeeCode'];
            for (int subj = 0; subj < kingDeeCode.length; subj++) {
              Map<String, dynamic> subObj = Map();
              if(kingDeeCode[subj].split("-").length>2){
                var itemCode = kingDeeCode[subj].split("-");
                if(itemCode.length>2){
                  if(itemCode.length > 3){
                    subObj['FSerialNo'] = itemCode[2]+'-'+itemCode[3];
                  }else{
                    subObj['FSerialNo'] = itemCode[2];
                  }
                }
              }else{
                subObj['FSerialNo'] = kingDeeCode[subj];
              }
              fSerialSub.add(subObj);
            }
            FEntityItem['FSerialSubEntity'] = fSerialSub;
            FEntity.add(FEntityItem);
          }
          }
        }
      hobbyIndex++;
    };
    if(FEntity.length==0){
      this.isSubmit = false;
      ToastUtil.showInfo('请输入数量和录入仓库');
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
        "formid": "SUB_PickMtrl",
        "data": {
          'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
        }
      };
      submitOrder(submitMap);
    } else {
      Map<String, dynamic> deleteMap = Map();
      deleteMap = {
        "formid": "SUB_PickMtrl",
        "data": {
          'Ids': collarOrderDate[0][0]
        }
      };
      deleteOrder(deleteMap,res['Result']['ResponseStatus']['Errors'][0]['Message']+':(该物料无库存或库存状态不可用！)');
      /* setState(() {
        this.isSubmit = false;
        ToastUtil.errorDialog(context,
            res['Result']['ResponseStatus']['Errors'][0]['Message']);
      });*/
    }
  }

  pushDown() async {
    if (this.hobby.length > 0) {
      setState(() {
        this.isSubmit = true;
      });
      //下推
      Map<String, dynamic> pushMap = Map();
      pushMap['Ids'] = orderDate[0][13];
      pushMap['RuleId'] = "SUB_PPBOM_Pick";
      pushMap['TargetFormId'] = "SUB_PickMtrl";
      print(pushMap);
      var downData =
      await SubmitEntity.pushDown({"formid": "SUB_PPBOM", "data": pushMap});
      print(downData);
      var res = jsonDecode(downData);
      //判断成功
      if (res['Result']['ResponseStatus']['IsSuccess']) {
        //查询生产领料
        var entitysNumber = res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id'];
        Map<String, dynamic> OrderMap = Map();
        OrderMap['FormId'] = 'SUB_PickMtrl';
        OrderMap['FilterString'] = "FID='$entitysNumber'";
        OrderMap['FieldKeys'] =
        'FID,FEntity_FEntryId,FStockId.FNumber,FMaterialId.FNumber';
        String order = await CurrencyEntity.polling({'data': OrderMap});
        var resData = jsonDecode(order);
        collarOrderDate = resData;
        saveOrder();
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
                  pushDown();
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
            title: Text("委外领料"),
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
                          title: Text("单据编号：$fBillNo"),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  /* Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text("日期：$FDate"),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  _item('仓库:', stockList, selectStock),*/
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
                        color: this.isSubmit?Colors.grey:Theme.of(context).primaryColor,
                        textColor: Colors.white,
                        onPressed: () async=> this.isSubmit ? null : _showSumbitDialog(),
                        /*onPressed: () async {
                          if (this.hobby.length > 0) {
                            setState(() {
                              this.isSubmit = true;
                            });
                            pushDown();
                          } else {
                            ToastUtil.showInfo('无提交数据');
                          }
                        },*/
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
