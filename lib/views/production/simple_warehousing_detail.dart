import 'dart:convert';
import 'package:date_format/date_format.dart';
import 'package:fzwm_wxbc/model/currency_entity.dart';
import 'package:fzwm_wxbc/model/submit_entity.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fzwm_wxbc/components/my_text.dart';
import 'package:qrscan/qrscan.dart' as scanner;
final String _fontFamily = Platform.isWindows ? "Roboto" : "";

class SimpleWarehousingDetail extends StatefulWidget {
  var FBillNo;
  var FSeq;
  var FEntryId;
  var FID;
  var FProdOrder;
  var FBarcode;
  var FMemoItem;

  SimpleWarehousingDetail(
      {Key? key,
        @required this.FBillNo,
        @required this.FSeq,
        @required this.FEntryId,
        @required this.FID,
        @required this.FBarcode,
        @required this.FProdOrder,
        @required this.FMemoItem})
      : super(key: key);

  @override
  _SimpleWarehousingDetailState createState() => _SimpleWarehousingDetailState(
      FBillNo, FSeq, FEntryId, FID, FProdOrder, FBarcode, FMemoItem);
}

class _SimpleWarehousingDetailState extends State<SimpleWarehousingDetail> {
  GlobalKey<TextWidgetState> textKey = GlobalKey();
  GlobalKey<TextWidgetState> FBillNoKey = GlobalKey();
  GlobalKey<TextWidgetState> FSaleOrderNoKey = GlobalKey();
  GlobalKey<PartRefreshWidgetState> globalKey = GlobalKey();
  GlobalKey<PartRefreshWidgetState> FPrdOrgIdKey = GlobalKey();

  final _textNumber = TextEditingController();
  var checkItem;
  String FBillNo = '';
  String FSaleOrderNo = '';
  String FName = '';
  String FNumber = '';
  String FDate = '';
  var show = false;
  var isScanWork = false;
  var isSubmit = false;
  var checkData;
  var fOrgID;
  var checkDataChild;
  var isTurnoff;

  //仓库
  var stockList = [];
  List<dynamic> stockListObj = [];
  var selectData = {
    DateMode.YMDHMS: '',
  };
  List<dynamic> orderDate = [];
  List<dynamic> materialDate = [];
  final divider = Divider(height: 1, indent: 20);
  final rightIcon = Icon(Icons.keyboard_arrow_right);
  final scanIcon = Icon(Icons.filter_center_focus);
  static const scannerPlugin =
  const EventChannel('com.shinow.pda_scanner/plugin');
  StreamSubscription? _subscription;
  var _code;
  var _FNumber;
  var FSeq;
  var fBillNo;
  var fEntryId;
  var fid;
  var FProdOrder;
  var FBarcode;
  var FMemoItem;
  var fBarCodeList;

  _SimpleWarehousingDetailState(fBillNo, FSeq, fEntryId, fid, FProdOrder, FBarcode, FMemoItem) {
    if (fBillNo != null) {
      this.FBillNo = fBillNo['value'];
      this.FSeq = FSeq['value'];
      this.fEntryId = fEntryId['value'];
      this.fid = fid['value'];
      this.FProdOrder = FProdOrder['value'];
      this.FMemoItem = FMemoItem['value'];
      this.FBarcode = FBarcode;
      this.getOrderList();
      isScanWork = true;
    } else {
      isScanWork = false;
      this.fBillNo = '';
      this.FMemoItem = '';
      getStockList();
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
    /* getWorkShop();*/
  }

  //获取仓库
  getStockList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BD_STOCK';
    userMap['FieldKeys'] = 'FStockID,FName,FNumber,FIsOpenLocation';
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    if (fOrgID == null) {
      this.fOrgID = deptData[1];
    }
    userMap['FilterString'] =
        "FForbidStatus = 'A' and FUseOrgId.FNumber ='" + fOrgID + "'";
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    stockListObj = jsonDecode(res);
    stockListObj.forEach((element) {
      stockList.add(element[1]);
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
    if (FBillNo != '') {
      Map<String, dynamic> userMap = Map();
      userMap['FilterString'] =
      "FBillNo='$FBillNo' and FNoStockInQty>0 and FStatus in (4)";
      userMap['FormId'] = 'PRD_MO';
      userMap['OrderString'] = 'FMaterialId.FNumber ASC';
      userMap['FieldKeys'] =
      'FBillNo,FPrdOrgId.FNumber,FPrdOrgId.FName,FDate,FSaleOrderNo,FTreeEntity_FEntryId,FMaterialId.FNumber,FMaterialId.FName,FMaterialId.FSpecification,FWorkShopID.FNumber,FWorkShopID.FName,FUnitId.FNumber,FUnitId.FName,FQty,FPlanStartDate,FPlanFinishDate,FSrcBillNo,FNoStockInQty,FID,FStatus,FStockId.FNumber,FStockId.FName,FRequestOrgId.FNumber,FMaterialId.FIsBatchManage';
      Map<String, dynamic> dataMap = Map();
      dataMap['data'] = userMap;
      String order = await CurrencyEntity.polling(dataMap);
      orderDate = [];
      orderDate = jsonDecode(order);
      if (orderDate.length > 0) {
        FDate = orderDate[0][3].substring(0, 10);
        selectData[DateMode.YMDHMS] = orderDate[0][3].substring(0, 10);
        FSaleOrderNo = orderDate[0][4];
        //globalKey.currentState!.update();
        this.fOrgID = orderDate[0][1];
        /*FBillNoKey.currentState.onPressed(orderDate[0][0]);
    FSaleOrderNoKey.currentState.onPressed(orderDate[0][4]);*/
        hobby = [];
        orderDate.forEach((value) {
          List arr = [];
          fNumber.add(value[6]);
          arr.add({
            "title": "物料子码",
            "name": "FMaterialId",
            "isHide": false,
            "value": {
              "label": value[6] + "- (" + value[7] + ")",
              "value": value[6],
              "barcode": [],
              "kingDeeCode": [],
              "scanCode": []
            }
          });
          arr.add({
            "title": "规格型号",
            "isHide": false,
            "name": "FMaterialIdFSpecification",
            "value": {"label": value[8], "value": value[8]}
          });
          arr.add({
            "title": "单位名称",
            "name": "FUnitId",
            "isHide": false,
            "value": {"label": value[12], "value": value[11]}
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
            "title": "批号",
            "name": "FLot",
            "isHide": value[23] != true,
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
          arr.add({
            "title": "工时",
            "name": "FStdManHour",
            "isHide": false,
            "value": {"label": "0", "value": "0"}
          });
          arr.add({
            "title": "需生产数量",
            "name": "FQty",
            "isHide": false,
            "value": {"label": value[13], "value": value[13]}
          });
          arr.add({
            "title": "最后扫描数量",
            "name": "FLastQty",
            "isHide": false,
            "value": {"label": "0", "value": "0"}
          });
          hobby.add(arr);
        });
        checkItem = '';
        /*hobby[1][3]["value"]["value"] = "18";
        hobby[1][3]["value"]["label"] = "18";*/
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
      getStockList();
    } else {
      EasyLoading.dismiss();
      _code = '';
      textKey.currentState!.onPressed(_code);
      if (FNumber == '') {
        checkItem = 'FPrdOrgId';
        ToastUtil.showInfo('请扫描生产车间');
      } else if (FBillNo == '') {
        checkItem = 'FBillNo';
        ToastUtil.showInfo('请扫描生产单号');
      }
      getStockList();
      scanDialog();
    }
    /* _onEvent("u+zeGAN0HjGOOOh3LfNGcSst+0RCbFmsR1G63psT2kLVkcuIIRcQDSTcpqu63ZW7");
    _onEvent("u+zeGAN0HjGOOOh3LfNGcSst+0RCbFmsR1G63psT2kLVkcuIIRcQDXt3X7AnjnOD");*/
  }

  void _onEvent(event) async {
    _code = event;
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var deptData = sharedPreferences.getString('menuList');
    var menuList = new Map<dynamic, dynamic>.from(jsonDecode(deptData));
    fBarCodeList = menuList['FBarCodeList'];
    if (event == "") {
      return;
    }
    if (fBarCodeList == 1) {
      Map<String, dynamic> barcodeMap = Map();
      barcodeMap['FilterString'] = "FBarCodeEn='" + event + "'";
      barcodeMap['FormId'] = 'QDEP_Cust_BarCodeList';
      barcodeMap['FieldKeys'] =
      'FID,FInQtyTotal,FOutQtyTotal,FEntity_FEntryId,FRemainQty,FBarCodeQty,FStockID.FName,FStockID.FNumber,FMATERIALID.FNUMBER,FOwnerID.FNumber,FBarCode,FSN';
      Map<String, dynamic> dataMap = Map();
      dataMap['data'] = barcodeMap;
      String order = await CurrencyEntity.polling(dataMap);
      var barcodeData = jsonDecode(order);
      if (barcodeData.length > 0) {
        var msg = "";
        var orderIndex = 0;
        for (var value in orderDate) {
          if (value[6] == barcodeData[0][8]) {
            msg = "";
            if (fNumber.lastIndexOf(barcodeData[0][8]) == orderIndex) {
              break;
            }
          } else {
            msg = '条码不在单据物料中';
          }
          orderIndex++;
        }
        ;
        if (msg == "") {
          _code = event;
          Map<String, dynamic> serialMap = Map();
          serialMap['FormId'] = 'BD_SerialMainFile';
          serialMap['FieldKeys'] = 'FStockStatus';
          serialMap['FilterString'] = "FNumber = '" + barcodeData[0][11] + "' and FMaterialID.FNumber = '" + barcodeData[0][8] + "'";
          Map<String, dynamic> serialDataMap = Map();
          serialDataMap['data'] = serialMap;
          String serialRes = await CurrencyEntity.polling(serialDataMap);
          var serialJson = jsonDecode(serialRes);
          if (serialJson.length > 0 && serialJson[0][0]=="1") {
            ToastUtil.showInfo('该序列号已入库');
          }else{
            this.getMaterialList(
                barcodeData, barcodeData[0][10], barcodeData[0][11]);
          }
        } else {
          ToastUtil.showInfo(msg);
        }
      } else {
        ToastUtil.showInfo('条码不在条码清单中');
      }
    } else {
      _code = event;
      this.getMaterialList("", _code, '');
      print("ChannelPage: $event");
    }
  }

  getMaterialList(barcodeData, code, fsn) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    var scanCode = code.split(";");
    userMap['FilterString'] = "FNumber='" +
        barcodeData[0][8] +
        "' and FForbidStatus = 'A' and FUseOrgId.FNumber = '" +
        deptData[1] +
        "'";
    userMap['FormId'] = 'BD_MATERIAL';
    userMap['FieldKeys'] =
    'FMATERIALID,FName,FNumber,FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FIsBatchManage'; /*,SubHeadEntity1.FStoreUnitID.FNumber*/
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
      var barCodeScan;
      if (fBarCodeList == 1) {
        barCodeScan = barcodeData[0];
        barCodeScan[4] = barCodeScan[4].toString();
      } else {
        barCodeScan = scanCode;
      }
      var barcodeNum = scanCode[3];
      var residue = double.parse(scanCode[3]);
      var hobbyIndex = 0;
      var number = 0;
      for (var element in hobby) {
        var residue = 0.0;
        //判断是否启用批号
        if (element[5]['isHide']) {
          //不启用
          if (element[0]['value']['value'] == scanCode[0]) {
            if (element[0]['value']['barcode'].indexOf(code) == -1) {
              if (scanCode.length > 4) {
                element[0]['value']['barcode'].add(code);
              }
              if (scanCode[5] == "N") {
                if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                  element[3]['value']['label'] =
                      (double.parse(element[3]['value']['label']) +
                          double.parse(barcodeNum))
                          .toString();
                  element[3]['value']['value'] = element[3]['value']['label'];
                  var item =
                      barCodeScan[0].toString() + "-" + barcodeNum + "-" + fsn;
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
              if ((double.parse(element[3]['value']['label']) +
                  double.parse(barcodeNum)) >
                  0 &&
                  double.parse(barcodeNum) > 0) {
                //判断物料是否重复 首个下标是否对应末尾下标
                if (fNumber.indexOf(element[0]['value']['value']) ==
                    fNumber.lastIndexOf(element[0]['value']['value'])) {
                  if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                    element[3]['value']['label'] =
                        (double.parse(element[3]['value']['label']) +
                            double.parse(barcodeNum))
                            .toString();
                    element[3]['value']['value'] = element[3]['value']['label'];
                    var item = barCodeScan[0].toString() +
                        "-" +
                        barcodeNum +
                        "-" +
                        fsn;
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
                } else {
                  //判断扫描数量是否大于单据数量
                  if (double.parse(element[3]['value']['label']) >=
                      element[9]['value']['label']) {
                    continue;
                  } else {
                    //判断二维码数量是否大于单据数量
                    if ((double.parse(element[3]['value']['label']) +
                        double.parse(barcodeNum)) >=
                        element[9]['value']['label']) {
                      //判断条码是否重复
                      if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                        var item = barCodeScan[0].toString() +
                            "-" +
                            (element[9]['value']['label'] -
                                double.parse(element[3]['value']['label']))
                                .toString() +
                            "-" +
                            fsn;
                        element[10]['value']['label'] = (element[9]['value']
                        ['label'] -
                            double.parse(element[3]['value']['label']))
                            .toString();
                        element[10]['value']['value'] = (element[9]['value']
                        ['label'] -
                            double.parse(element[3]['value']['label']))
                            .toString();
                        barcodeNum = (double.parse(barcodeNum) -
                            (element[9]['value']['label'] -
                                double.parse(element[3]['value']['label'])))
                            .toString();
                        element[3]['value']['label'] = (double.parse(
                            element[3]['value']['label']) +
                            (element[9]['value']['label'] -
                                double.parse(element[3]['value']['label'])))
                            .toString();
                        element[3]['value']['value'] =
                        element[3]['value']['label'];
                        residue = element[9]['value']['label'] -
                            double.parse(element[3]['value']['label']);
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
                            (double.parse(element[3]['value']['label']) +
                                double.parse(barcodeNum))
                                .toString();
                        element[3]['value']['value'] =
                        element[3]['value']['label'];
                        var item = barCodeScan[0].toString() +
                            "-" +
                            barcodeNum +
                            "-" +
                            fsn;
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
                }
              }
            } else {
              ToastUtil.showInfo('该标签已扫描');
              break;
            }
          }
        } else {
          if (element[0]['value']['value'] == scanCode[0]) {
            if (element[0]['value']['barcode'].indexOf(code) == -1) {
              if (scanCode.length > 4) {
                element[0]['value']['barcode'].add(code);
              }
              //启用批号
              if (scanCode[5] == "N") {
                if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                  if (element[5]['value']['value'] == "") {
                    element[5]['value']['label'] = scanCode[1];
                    element[5]['value']['value'] = scanCode[1];
                  }
                  element[3]['value']['label'] =
                      (double.parse(element[3]['value']['label']) +
                          double.parse(barcodeNum))
                          .toString();
                  element[3]['value']['value'] = element[3]['value']['label'];
                  var item =
                      barCodeScan[0].toString() + "-" + barcodeNum + "-" + fsn;
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
              if (element[5]['value']['value'] == scanCode[1]) {
                //判断条码数量
                if ((double.parse(element[3]['value']['label']) +
                    double.parse(barcodeNum)) >
                    0 &&
                    double.parse(barcodeNum) > 0) {
                  //判断物料是否重复 首个下标是否对应末尾下标
                  if (fNumber.indexOf(element[0]['value']['value']) ==
                      fNumber.lastIndexOf(element[0]['value']['value'])) {
                    if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                      element[3]['value']['label'] =
                          (double.parse(element[3]['value']['label']) +
                              double.parse(barcodeNum))
                              .toString();
                      element[3]['value']['value'] =
                      element[3]['value']['label'];
                      var item = barCodeScan[0].toString() +
                          "-" +
                          barcodeNum +
                          "-" +
                          fsn;
                      element[10]['value']['label'] = barcodeNum.toString();
                      element[10]['value']['value'] = barcodeNum.toString();
                      element[0]['value']['kingDeeCode'].add(item);
                      element[0]['value']['scanCode'].add(code);
                      barcodeNum =
                          (double.parse(barcodeNum) - double.parse(barcodeNum))
                              .toString();
                      print(2);
                      print(element[0]['value']['kingDeeCode']);
                    }
                  } else {
                    //判断扫描数量是否大于单据数量
                    if (double.parse(element[3]['value']['label']) >=
                        element[9]['value']['label']) {
                      continue;
                    } else {
                      //判断二维码数量是否大于单据数量
                      if ((double.parse(element[3]['value']['label']) +
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
                                  .toString() +
                              "-" +
                              fsn;
                          element[10]['value']['label'] = (element[9]['value']
                          ['label'] -
                              double.parse(element[3]['value']['label']))
                              .toString();
                          element[10]['value']['value'] = (element[9]['value']
                          ['label'] -
                              double.parse(element[3]['value']['label']))
                              .toString();
                          barcodeNum = (double.parse(barcodeNum) -
                              (element[9]['value']['label'] -
                                  double.parse(
                                      element[3]['value']['label'])))
                              .toString();
                          element[3]['value']['label'] =
                              (double.parse(element[3]['value']['label']) +
                                  (element[9]['value']['label'] -
                                      double.parse(
                                          element[3]['value']['label'])))
                                  .toString();
                          element[3]['value']['value'] =
                          element[3]['value']['label'];
                          residue = element[9]['value']['label'] -
                              double.parse(element[3]['value']['label']);
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
                              (double.parse(element[3]['value']['label']) +
                                  double.parse(barcodeNum))
                                  .toString();
                          element[3]['value']['value'] =
                          element[3]['value']['label'];
                          var item = barCodeScan[0].toString() +
                              "-" +
                              barcodeNum +
                              "-" +
                              fsn;
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
                  }
                }
              } else {
                if (element[5]['value']['value'] == "") {
                  element[5]['value']['label'] = scanCode[1];
                  element[5]['value']['value'] = scanCode[1];
                  //判断条码数量
                  if ((double.parse(element[3]['value']['label']) +
                      double.parse(barcodeNum)) >
                      0 &&
                      double.parse(barcodeNum) > 0) {
                    //判断物料是否重复 首个下标是否对应末尾下标
                    if (fNumber.indexOf(element[0]['value']['value']) ==
                        fNumber.lastIndexOf(element[0]['value']['value'])) {
                      if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                        element[3]['value']['label'] =
                            (double.parse(element[3]['value']['label']) +
                                double.parse(barcodeNum))
                                .toString();
                        element[3]['value']['value'] =
                        element[3]['value']['label'];
                        var item = barCodeScan[0].toString() +
                            "-" +
                            barcodeNum +
                            "-" +
                            fsn;
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
                    } else {
                      //判断扫描数量是否大于单据数量
                      if (double.parse(element[3]['value']['label']) >=
                          element[9]['value']['label']) {
                        continue;
                      } else {
                        //判断二维码数量是否大于单据数量
                        if ((double.parse(element[3]['value']['label']) +
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
                                    .toString() +
                                "-" +
                                fsn;
                            element[10]['value']['label'] = (element[9]['value']
                            ['label'] -
                                double.parse(element[3]['value']['label']))
                                .toString();
                            element[10]['value']['value'] = (element[9]['value']
                            ['label'] -
                                double.parse(element[3]['value']['label']))
                                .toString();
                            barcodeNum = (double.parse(barcodeNum) -
                                (element[9]['value']['label'] -
                                    double.parse(
                                        element[3]['value']['label'])))
                                .toString();
                            element[3]['value']['label'] =
                                (double.parse(element[3]['value']['label']) +
                                    (element[9]['value']['label'] -
                                        double.parse(
                                            element[3]['value']['label'])))
                                    .toString();
                            element[3]['value']['value'] =
                            element[3]['value']['label'];
                            residue = element[9]['value']['label'] -
                                double.parse(element[3]['value']['label']);
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
                                (double.parse(element[3]['value']['label']) +
                                    double.parse(barcodeNum))
                                    .toString();
                            element[3]['value']['value'] =
                            element[3]['value']['label'];
                            var item = barCodeScan[0].toString() +
                                "-" +
                                barcodeNum +
                                "-" +
                                fsn;
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
                    }
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
            "value": {
              "value": value[2],
              "label": value[2] + "- (" + value[1] + ")",
              "barcode": [],
              "kingDeeCode": [],
              "scanCode": []
            }
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
      print(hobbyIndex);
      print(residue);
      setState(() {
        EasyLoading.dismiss();
      });
    } else {
      setState(() {
        EasyLoading.dismiss();
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
            case DateMode.YMDHMS:
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
          if (hobby == 'isTurnoff') {
            setState(() {
              print(p);
              this.isTurnoff = p;
            });
          } else {
            setState(() {
              this.isSubmit = false;
              hobby['value']['label'] = p;
            });
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                hobby['value']['value'] = stockListObj[elementIndex][2];
                /*stock[6]['value']['hide'] = stockListObj[elementIndex][3];*/
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
          if (j == 6) {
            /*j == 4 || */
            /*comList.add(
            _item(this.hobby[j]["title"], ['PHP', 'JAVA', 'C++', 'Dart', 'Python', 'Go'],
                this.hobby[j]["value"]),
          );*/
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
            );
          } else if (j == 4) {
            comList.add(
              _item('良品仓库:', stockList, this.hobby[i][j]['value']['label'],
                  this.hobby[i][j],
                  stock: this.hobby[i]),
            );
          } else if (j == 7) {
            comList.add(
              _item('不良品仓库:', stockList, this.hobby[i][j]['value']['label'],
                  this.hobby[i][j],
                  stock: this.hobby[i]),
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
                                checkItem = 'FStdManHour';
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
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('扫描',
                        style: TextStyle(
                            fontSize: 16, decoration: TextDecoration.none)),
                  ),
                  if (!show)
                    Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Card(
                            child: Column(children: <Widget>[
                              TextField(
                                style: TextStyle(color: Colors.black87),
                                keyboardType: TextInputType.number,
                                controller: this._textNumber,
                                decoration: InputDecoration(hintText: "输入或者扫描数量"),
                                onChanged: (value) {
                                  setState(() {
                                    this._FNumber = value;
                                  });
                                },
                              ),
                            ]))),
                  if (show)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: TextWidget(textKey, ''),
                    ),
                  Padding(
                    padding: EdgeInsets.only(top: 15, bottom: 8),
                    child: FlatButton(
                        color: Colors.grey[100],
                        onPressed: () {
                          // 关闭 Dialog
                          Navigator.pop(context);
                          if (checkItem == 'FNumber') {
                            setState(() {
                              this.hobby[checkData][checkDataChild]["value"]
                              ["label"] = _FNumber;
                              this.hobby[checkData][checkDataChild]['value']
                              ["value"] = _FNumber;
                            });
                          } else if (checkItem == 'FStdManHour') {
                            setState(() {
                              this.hobby[checkData][checkDataChild]["value"]
                              ["label"] = _FNumber;
                              this.hobby[checkData][checkDataChild]['value']
                              ["value"] = _FNumber;
                            });
                          }
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

//删除
  deleteOrder(Map<String, dynamic> map, msg) async {
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
            ToastUtil.errorDialog(context, msg);
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
  unAuditOrder(Map<String, dynamic> map, msg) async {
    var subData = await SubmitEntity.unAudit(map);
    print(subData);
    if (subData != null) {
      var res = jsonDecode(subData);
      if (res != null) {
        if (res['Result']['ResponseStatus']['IsSuccess']) {
          //提交清空页面
          Map<String, dynamic> deleteMap = Map();
          deleteMap = {
            "formid": "PRD_MORPT",
            "data": {
              'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
            }
          };
          deleteOrder(deleteMap, msg);
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

// 入库后操作
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
      for (var i = serialNum; i <= 4; i++) {
        //查询生产订单
        Map<String, dynamic> userMap = Map();
        userMap['FilterString'] =
            "FSaleOrderNo='$FBarcode' and FStatus in (2) and FProdOrder >= " +
                (i).toString() +
                " and FProdOrder <" +
                (i + 1).toString();
        userMap['FormId'] = "PRD_MO";
        userMap['FieldKeys'] =
        'FBillNo,FTreeEntity_FEntryId,FID,FProdOrder,FTreeEntity_FSeq';
        Map<String, dynamic> proMoDataMap = Map();
        proMoDataMap['data'] = userMap;
        String order = await CurrencyEntity.polling(proMoDataMap);
        var orderRes = jsonDecode(order);
        serialNum = i;
        //判断同级
        if (orderRes.length > 0) {
          break;
        }
      }
      //查询生产订单
      Map<String, dynamic> userMap = Map();
      userMap['FilterString'] = "FSaleOrderNo='$FBarcode' and FProdOrder >= " +
          (serialNum).toString() +
          " and FProdOrder <" +
          (serialNum + 1).toString();
      userMap['FormId'] = "PRD_MO";
      userMap['FieldKeys'] =
      'FBillNo,FTreeEntity_FEntryId,FID,FProdOrder,FTreeEntity_FSeq';
      Map<String, dynamic> proMoDataMap = Map();
      proMoDataMap['data'] = userMap;
      String order = await CurrencyEntity.polling(proMoDataMap);
      var orderRes = jsonDecode(order);
      if (orderRes.length > 0) {
        orderRes.forEach((element) async {
          //查询用料清单
          Map<String, dynamic> materialsMap = Map();
          var FMOEntrySeq = element[4];
          var FMOBillNo = element[0];
          materialsMap['FilterString'] = "FMOBillNO=" +
              FMOBillNo.toString() +
              " and FMOEntrySeq = " +
              FMOEntrySeq.toString();
          materialsMap['FormId'] = 'PRD_PPBOM';
          materialsMap['FieldKeys'] = 'FID';
          Map<String, dynamic> materialsDataMap = Map();
          materialsDataMap['data'] = materialsMap;
          String materialsMapOrder =
          await CurrencyEntity.polling(materialsDataMap);
          //修改用料清单为审核状态
          Map<String, dynamic> auditDataMap = Map();
          auditDataMap = {
            "formid": "PRD_PPBOM",
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
            var errorMsg = "";
            if (fBarCodeList == 1) {
              for (int i = 0; i < this.hobby.length; i++) {
                if (this.hobby[i][3]['value']['value'] != '0' &&
                    this.hobby[i][4]['value']['value'] != '') {
                  var kingDeeCode = this.hobby[i][0]['value']['kingDeeCode'];
                  for (int j = 0; j < kingDeeCode.length; j++) {
                    Map<String, dynamic> dataCodeMap = Map();
                    dataCodeMap['formid'] = 'QDEP_Cust_BarCodeList';
                    Map<String, dynamic> orderCodeMap = Map();
                    orderCodeMap['NeedUpDataFields'] = ['FEntity',"FHrWorkTime","FFinishQty","FQuaQty",'FSerialSubEntity','FSerialNo'];
                    orderCodeMap['NeedReturnFields'] = [];
                    orderCodeMap['IsDeleteEntry'] = false;
                    Map<String, dynamic> codeModel = Map();
                    var itemCode = kingDeeCode[j].split("-");
                    codeModel['FID'] = itemCode[0];
                    codeModel['FOwnerID'] = {"FNUMBER": orderDate[i][21]};
                    codeModel['FStockOrgID'] = {"FNUMBER": orderDate[i][8]};
                    codeModel['FStockID'] = {
                      "FNUMBER": this.hobby[i][4]['value']['value']
                    };
                    /*codeModel['FLastCheckTime'] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);*/
                    Map<String, dynamic> codeFEntityItem = Map();
                    codeFEntityItem['FBillDate'] = FDate;
                    codeFEntityItem['FInQty'] = itemCode[1];
                    codeFEntityItem['FEntryBillNo'] = orderDate[i][0];
                    codeFEntityItem['FEntryStockID'] = {
                      "FNUMBER": this.hobby[i][4]['value']['value']
                    };
                    var codeFEntity = [codeFEntityItem];
                    codeModel['FEntity'] = codeFEntity;
                    orderCodeMap['Model'] = codeModel;
                    dataCodeMap['data'] = orderCodeMap;
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
      } else {
        var errorMsg = "";
        if (fBarCodeList == 1) {
          for (int i = 0; i < this.hobby.length; i++) {
            if (this.hobby[i][6]['value']['value'] != '0' &&
                this.hobby[i][7]['value']['value'] != '') {
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
                codeModel['FOwnerID'] = {"FNUMBER": orderDate[i][21]};
                codeModel['FStockOrgID'] = {"FNUMBER": orderDate[i][8]};
                codeModel['FStockID'] = {
                  "FNUMBER": this.hobby[i][4]['value']['value']
                };
                /*codeModel['FLastCheckTime'] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);*/
                Map<String, dynamic> codeFEntityItem = Map();
                codeFEntityItem['FBillDate'] = FDate;
                codeFEntityItem['FInQty'] = itemCode[1];
                codeFEntityItem['FEntryBillNo'] = orderDate[i][0];
                codeFEntityItem['FEntryStockID'] = {
                  "FNUMBER": this.hobby[i][4]['value']['value']
                };
                var codeFEntity = [codeFEntityItem];
                codeModel['FEntity'] = codeFEntity;
                orderCodeMap['Model'] = codeModel;
                dataCodeMap['data'] = orderCodeMap;
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

//审核
  auditOrder(Map<String, dynamic> auditMap, index, bool type) async {
    //获取登录信息
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    /*if (this.isTurnoff == "成品") {
      if (type) {
        if (index == 1) {
          var errorMsg = "";
          if (fBarCodeList == 1) {
            for (int i = 0; i < this.hobby.length; i++) {
              if (this.hobby[i][3]['value']['value'] != '0' &&
                  this.hobby[i][4]['value']['value'] != '') {
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
                  codeModel['FOwnerID'] = {"FNUMBER": deptData[1]};
                  codeModel['FStockOrgID'] = {"FNUMBER": deptData[1]};
                  codeModel['FStockID'] = {
                    "FNUMBER": this.hobby[i][4]['value']['value']
                  };
                  *//*codeModel['FLastCheckTime'] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);*//*
                  Map<String, dynamic> codeFEntityItem = Map();
                  codeFEntityItem['FBillDate'] = FDate;
                  codeFEntityItem['FInQty'] = itemCode[1];
                  codeFEntityItem['FEntryBillNo'] = orderDate[i][0];
                  codeFEntityItem['FEntryStockID'] = {
                    "FNUMBER": this.hobby[i][4]['value']['value']
                  };
                  var codeFEntity = [codeFEntityItem];
                  codeModel['FEntity'] = codeFEntity;
                  orderCodeMap['Model'] = codeModel;
                  dataCodeMap['data'] = orderCodeMap;
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
          *//*this.handlerStatus();*//*
          setState(() {
            this.hobby = [];
            this.orderDate = [];
            this.FBillNo = '';
            this.FSaleOrderNo = '';
          });
          ToastUtil.showInfo('提交成功');
          Navigator.of(context).pop("refresh");
        }
      } else {
        var errorMsg = "";
        if (fBarCodeList == 1) {
          for (int i = 0; i < this.hobby.length; i++) {
            if (this.hobby[i][3]['value']['value'] != '0' &&
                this.hobby[i][4]['value']['value'] != '') {
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
                codeModel['FOwnerID'] = {"FNUMBER": deptData[1]};
                codeModel['FStockOrgID'] = {"FNUMBER": deptData[1]};
                codeModel['FStockID'] = {
                  "FNUMBER": this.hobby[i][4]['value']['value']
                };
                *//*codeModel['FLastCheckTime'] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);*//*
                Map<String, dynamic> codeFEntityItem = Map();
                codeFEntityItem['FBillDate'] = FDate;
                codeFEntityItem['FInQty'] = itemCode[1];
                codeFEntityItem['FEntryBillNo'] = orderDate[i][0];
                codeFEntityItem['FEntryStockID'] = {
                  "FNUMBER": this.hobby[i][4]['value']['value']
                };
                var codeFEntity = [codeFEntityItem];
                codeModel['FEntity'] = codeFEntity;
                orderCodeMap['Model'] = codeModel;
                dataCodeMap['data'] = orderCodeMap;
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


        *//*this.handlerStatus();*//*
        setState(() {
          this.hobby = [];
          this.orderDate = [];
          this.FBillNo = '';
          this.FSaleOrderNo = '';
        });
        ToastUtil.showInfo('提交成功');
        Navigator.of(context).pop("refresh");
      }
    } else {*/
    await SubmitEntity.submit(auditMap);
    var subData = await SubmitEntity.audit(auditMap);
    var res = jsonDecode(subData);
    if (res != null) {
      if (res['Result']['ResponseStatus']['IsSuccess']) {
        if (type) {
          if (index == 1) {
            var errorMsg = "";
            if (fBarCodeList == 1) {
              for (int i = 0; i < this.hobby.length; i++) {
                if (this.hobby[i][3]['value']['value'] != '0' &&
                    this.hobby[i][4]['value']['value'] != '') {
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
                    codeModel['FOwnerID'] = {"FNUMBER": deptData[1]};
                    codeModel['FStockOrgID'] = {"FNUMBER": deptData[1]};
                    codeModel['FStockID'] = {
                      "FNUMBER": this.hobby[i][4]['value']['value']
                    };
                    /*codeModel['FLastCheckTime'] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);*/
                    Map<String, dynamic> codeFEntityItem = Map();
                    codeFEntityItem['FBillDate'] = FDate;
                    codeFEntityItem['FInQty'] = itemCode[1];
                    codeFEntityItem['FEntryBillNo'] = orderDate[i][0];
                    codeFEntityItem['FEntryStockID'] = {
                      "FNUMBER": this.hobby[i][4]['value']['value']
                    };
                    var codeFEntity = [codeFEntityItem];
                    codeModel['FEntity'] = codeFEntity;
                    orderCodeMap['Model'] = codeModel;
                    dataCodeMap['data'] = orderCodeMap;
                    String codeRes = await SubmitEntity.save(dataCodeMap);
                    var barcodeRes = jsonDecode(codeRes);
                    if (!barcodeRes['Result']['ResponseStatus']
                    ['IsSuccess']) {
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

            Map<String, dynamic> inStockMap = Map();
            inStockMap['FilterString'] = "FSrcBillNo='"+res['Result']['ResponseStatus']['SuccessEntitys'][0]['Number']+"'";
            inStockMap['FormId'] = 'PRD_INSTOCK';
            inStockMap['FieldKeys'] =
            'FID';
            Map<String, dynamic> inStockDataMap = Map();
            inStockDataMap['data'] = inStockMap;
            String inStockMapOrder = await CurrencyEntity.polling(inStockDataMap);
            var inStockOrderRes = jsonDecode(inStockMapOrder);
            if (inStockOrderRes.length>0) {
              Map<String, dynamic> submitMap = Map();
              submitMap = {
                "formid": "PRD_INSTOCK",
                "data": {
                  'Ids': inStockOrderRes[0][0]
                }
              };
              var submitData = await SubmitEntity.submit(submitMap);
              await SubmitEntity.audit(submitMap);
              var resSubmit = jsonDecode(submitData);
              if (resSubmit['Result']['ResponseStatus']['IsSuccess']) {
                ToastUtil.showInfo('提交入库成功');
              }
            }
            /*this.handlerStatus();*/
            setState(() {
              this.hobby = [];
              this.orderDate = [];
              this.FBillNo = '';
              this.FSaleOrderNo = '';
            });
            ToastUtil.showInfo('提交成功');
            Navigator.of(context).pop("refresh");
          }
        } else {
          var errorMsg = "";
          if (fBarCodeList == 1) {
            for (int i = 0; i < this.hobby.length; i++) {
              if (this.hobby[i][3]['value']['value'] != '0' &&
                  this.hobby[i][4]['value']['value'] != '') {
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
                  codeModel['FOwnerID'] = {"FNUMBER": deptData[1]};
                  codeModel['FStockOrgID'] = {"FNUMBER": deptData[1]};
                  codeModel['FStockID'] = {
                    "FNUMBER": this.hobby[i][4]['value']['value']
                  };
                  /*codeModel['FLastCheckTime'] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);*/
                  Map<String, dynamic> codeFEntityItem = Map();
                  codeFEntityItem['FBillDate'] = FDate;
                  codeFEntityItem['FInQty'] = itemCode[1];
                  codeFEntityItem['FEntryBillNo'] = orderDate[i][0];
                  codeFEntityItem['FEntryStockID'] = {
                    "FNUMBER": this.hobby[i][4]['value']['value']
                  };
                  var codeFEntity = [codeFEntityItem];
                  codeModel['FEntity'] = codeFEntity;
                  orderCodeMap['Model'] = codeModel;
                  dataCodeMap['data'] = orderCodeMap;
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
          Map<String, dynamic> inStockMap = Map();
          inStockMap['FilterString'] = "FSrcBillNo='"+res['Result']['ResponseStatus']['SuccessEntitys'][0]['Number']+"'";
          inStockMap['FormId'] = 'PRD_INSTOCK';
          inStockMap['FieldKeys'] =
          'FID';
          Map<String, dynamic> inStockDataMap = Map();
          inStockDataMap['data'] = inStockMap;
          String inStockMapOrder = await CurrencyEntity.polling(inStockDataMap);
          var inStockOrderRes = jsonDecode(inStockMapOrder);
          if (inStockOrderRes.length>0) {
            Map<String, dynamic> submitMap = Map();
            submitMap = {
              "formid": "PRD_INSTOCK",
              "data": {
                'Ids': inStockOrderRes[0][0]
              }
            };
            var submitData = await SubmitEntity.submit(submitMap);
            await SubmitEntity.audit(submitMap);
            var resSubmit = jsonDecode(submitData);
            if (resSubmit['Result']['ResponseStatus']['IsSuccess']) {
              ToastUtil.showInfo('提交入库成功');
            }
          }
          /*this.handlerStatus();*/
          setState(() {
            this.hobby = [];
            this.orderDate = [];
            this.FBillNo = '';
            this.FSaleOrderNo = '';
          });
          ToastUtil.showInfo('提交成功');
          Navigator.of(context).pop("refresh");
        }
        //提交清空页面
      } else {
        unAuditOrder(auditMap,
            res['Result']['ResponseStatus']['Errors'][0]['Message']);
        /*setState(() {
            ToastUtil.errorDialog(context,
                res['Result']['ResponseStatus']['Errors'][0]['Message']);
          });*/
      }
    }
    /*}*/
  }

  pushDown(val, type) async {
    //下推
    Map<String, dynamic> pushMap = Map();
    pushMap['EntryIds'] = val;
    pushMap['RuleId'] = "PRD_MO2MORPT";
    pushMap['TargetFormId'] = "PRD_MORPT";
    pushMap['IsEnableDefaultRule'] = "false";
    pushMap['IsDraftWhenSaveFail'] = "false";
    print(pushMap);
    var downData =
    await SubmitEntity.pushDown({"formid": "PRD_MO", "data": pushMap});
    print(downData);
    var res = jsonDecode(downData);
    //判断成功
    if (res['Result']['ResponseStatus']['IsSuccess']) {
      //查询入库单
      var entitysNumber =
      res['Result']['ResponseStatus']['SuccessEntitys'][0]['Number'];
      Map<String, dynamic> inOrderMap = Map();
      inOrderMap['FormId'] = 'PRD_MORPT';
      inOrderMap['FilterString'] = "FBillNo='$entitysNumber'";
      inOrderMap['FieldKeys'] =
      'FEntity_FEntryId,FMaterialId.FNumber,FMaterialId.FName,FUnitId.FNumber,FMoBillNo';
      String order = await CurrencyEntity.polling({'data': inOrderMap});
      print(order);
      var resData = jsonDecode(order);
      //组装数据
      Map<String, dynamic> dataMap = Map();
      dataMap['data'] = inOrderMap;
      Map<String, dynamic> orderMap = Map();
      orderMap['NeedUpDataFields'] = ['FEntity',"FHrWorkTime","FFinishQty","FQuaQty",'FSerialSubEntity','FSerialNo'];
      orderMap['NeedReturnFields'] = ['FEntity','FSerialSubEntity','FSerialNo'];
      orderMap['IsDeleteEntry'] = true;
      Map<String, dynamic> Model = Map();
      Model['FID'] = res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id'];
      // ignore: non_constant_identifier_names
      var FEntity = [];
      for (int entity = 0; entity < resData.length; entity++) {
        for (int element = 0; element < this.hobby.length; element++) {
          if (resData[entity][1].toString() == this.hobby[element][0]['value']['value'].toString()) {
            if (this.hobby[element][3]['value']['value'] != '0') {
              // ignore: non_constant_identifier_names
              //判断不良品还是良品
              Map<String, dynamic> FEntityItem = Map();
              FEntityItem['FEntryID'] = resData[entity][0];
              FEntityItem['FReportType'] = {"FNumber": "HBLX01_SYS"};
              FEntityItem['FInStockType'] = '1';
              /*FEntityItem['FWorkshipId'] = {"FNumber": "BM00018"};*/
              FEntityItem['FFinishQty'] =
              this.hobby[element][3]['value']['value'];
              FEntityItem['FQuaQty'] = this.hobby[element][3]['value']['value'];

              FEntityItem['FStockId'] = {
                "FNumber": this.hobby[element][4]['value']['value']
              };
              FEntityItem['FLot'] = {
                "FNumber": this.hobby[element][5]['value']['value']
              };
              var fSerialSub = [];
              var kingDeeCode = this.hobby[element][0]['value']['kingDeeCode'];
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
                    /* Map<String, dynamic> serialNoMap = Map();
                  serialNoMap['FormId'] = 'PRD_MORPT';
                  serialNoMap['FilterString'] = "FSerialSubEntity.FSerialNo='"+itemCode[2]+"'";
                  serialNoMap['FieldKeys'] =
                  'FDetailID,FSerialNo';
                  String serialNoData = await CurrencyEntity.polling({'data': serialNoMap});
                  var resSerialNoData = jsonDecode(order);*/
                  }
                }else{
                  subObj['FSerialNo'] = kingDeeCode[subj];
                }
                fSerialSub.add(subObj);
              }
              FEntityItem['FSerialSubEntity'] = fSerialSub;
              FEntityItem['FHrWorkTime'] =
              this.hobby[element][8]['value']['value'];
              FEntity.add(FEntityItem);
            }
          }
        }
      }
      /*for (int entity = 0; entity < resData.length; entity++) {
        for (int element = 0; element < this.hobby.length; element++) {
          if (resData[entity][1].toString() == this.hobby[element][0]['value']['value'].toString()) {
            // ignore: non_constant_identifier_names
            //判断不良品还是良品
            if (type == "defective") {
              Map<String, dynamic> FEntityItem = Map();
              FEntityItem['FEntryID'] = resData[entity][0];
              FEntityItem['FStockStatusId'] = {"FNumber": "KCZT01_SYS"};
              FEntityItem['FInStockType'] = '1';
              FEntityItem['FStdManHour'] = this.hobby[element][8]['value']['value'];
              FEntityItem['FRealQty'] =
                  this.hobby[element][3]['value']['value'];
              FEntityItem['FStockId'] = {
                "FNumber": this.hobby[element][4]['value']['value']
              };
              FEntity.add(FEntityItem);
            } else {
              Map<String, dynamic> FEntityItem = Map();
              FEntityItem['FInStockType'] = '2';
              FEntityItem['FStockStatusId'] = {"FNumber": "KCZT01_SYS"};
              FEntityItem['FEntryID'] = resData[entity][0];
              FEntityItem['FStdManHour'] = this.hobby[element][8]['value']['value'];
              FEntityItem['FRealQty'] =
                  this.hobby[element][6]['value']['value'];
              FEntityItem['FStockId'] = {
                "FNumber": this.hobby[element][7]['value']['value']
              };
              FEntity.add(FEntityItem);
            }
          }
        }
      }*/
      Model['FEntity'] = FEntity;
      orderMap['Model'] = Model;
      dataMap = {"formid": "PRD_MORPT", "data": orderMap, "isBool": true};
      print(jsonEncode(dataMap));
      //返回保存参数
      return dataMap;
    } else {
      Map<String, dynamic> errorMap = Map();
      errorMap = {
        "msg": res['Result']['ResponseStatus']['Errors'][0]['Message'],
        "isBool": false
      };
      return errorMap;
    }
  }

//保存
  submitOder() async {
    /*if(this.isTurnoff==null){
      ToastUtil.showInfo('请选择类型');
      return;
    }*/
    if (this.hobby.length > 0) {
      setState(() {
        this.isSubmit = true;
      });
      var gsNumber = 0;
      var scNumber = 0;
      this.hobby.forEach((element) {
        if(double.parse(element[3]['value']['value']) > 0){
          if(element[8]['value']['value'] == "0" || element[8]['value']['value'] == null){
            gsNumber++;
          }
          if(element[9]['value']['label'] > double.parse(element[3]['value']['label'])){
            scNumber++;
          }
        }
      });
      if(gsNumber != 0){
        ToastUtil.showInfo('请输入工时');
        this.isSubmit = false;
        return;
      }
      /*if(scNumber != 0){
        ToastUtil.showInfo('入库数量需等于订单数量');
        return;
      }*/

      var EntryIds1 = '';
      var EntryIds2 = '';
      //分两次读取良品，不良品数据
      for (var i = 0; i < 2; i++) {
        var hobbyIndex = 0;
        this.hobby.forEach((element) {
          if (i == 0) {
            if (element[3]['value']['value'] is String) {
              if (double.parse(element[3]['value']['value']) > 0) {
                if (EntryIds1 == '') {
                  EntryIds1 = orderDate[hobbyIndex][5].toString();
                } else {
                  EntryIds1 =
                      EntryIds1 + ',' + orderDate[hobbyIndex][5].toString();
                }
              }
            } else {
              if (element[3]['value']['value'] > 0) {
                if (EntryIds1 == '') {
                  EntryIds1 = orderDate[hobbyIndex][5].toString();
                } else {
                  EntryIds1 =
                      EntryIds1 + ',' + orderDate[hobbyIndex][5].toString();
                }
              }
            }
          } else {
            if (element[6]['value']['value'] is String) {
              if (double.parse(element[6]['value']['value']) > 0) {
                if (EntryIds2 == '') {
                  EntryIds2 = orderDate[hobbyIndex][5].toString();
                } else {
                  EntryIds2 =
                      EntryIds2 + ',' + orderDate[hobbyIndex][5].toString();
                }
              }
            } else {
              if (element[6]['value']['value'] > 0) {
                if (EntryIds2 == '') {
                  EntryIds2 = orderDate[hobbyIndex][5].toString();
                } else {
                  EntryIds2 =
                      EntryIds2 + ',' + orderDate[hobbyIndex][5].toString();
                }
              }
            }
          }
          hobbyIndex++;
        });
      }
      //判断是否填写数量
      if (EntryIds1 == '' && EntryIds2 == '') {
        this.isSubmit = false;
        ToastUtil.showInfo('无提交数据');
      } else {
        var checkList = [];
        //循环下推单据
        for (var i = 0; i < 2; i++) {
          if (EntryIds1 != '' && i == 0) {
            checkList.add(EntryIds1);
            print(EntryIds1);
            var resCheck = await this.pushDown(EntryIds1, 'defective');
            var dataList = jsonEncode(resCheck);
            if (resCheck['isBool'] != false) {
              var subData = await SubmitEntity.save(resCheck);
              var res = jsonDecode(subData);
              if (res != null) {
                if (res['Result']['ResponseStatus']['IsSuccess']) {
                  //提交清空页面
                  Map<String, dynamic> auditMap = Map();
                  auditMap = {
                    "formid": "PRD_MORPT",
                    "data": {
                      'Ids': res['Result']['ResponseStatus']['SuccessEntitys']
                      [0]['Id']
                    }
                  };
                  await auditOrder(auditMap, i, EntryIds2 != '');
                } else {
                  /* setState(() {
                    this.isSubmit = false;
                    ToastUtil.errorDialog(context, res['Result']['ResponseStatus']['Errors'][0]['Message']);
                  });*/
                  Map<String, dynamic> deleteMap = Map();
                  deleteMap = {
                    "formid": "PRD_MORPT",
                    "data": {'Ids': resCheck['data']["Model"]["FID"]}
                  };
                  deleteOrder(deleteMap,
                      res['Result']['ResponseStatus']['Errors'][0]['Message']);
                }
              }
            } else {
              setState(() {
                this.isSubmit = false;
                ToastUtil.errorDialog(context, resCheck['msg']);
              });
              break;
            }
          } else if (EntryIds2 != '' && i == 1) {
            checkList.add(EntryIds2);
            var resCheck = await this.pushDown(EntryIds2, 'nonDefective');
            if (resCheck['isBool'] != false) {
              setState(() {
                this.isSubmit = false;
              });
              var subData = await SubmitEntity.save(resCheck);
              print(subData);
              var res = jsonDecode(subData);
              if (res != null) {
                if (res['Result']['ResponseStatus']['IsSuccess']) {
                  //提交清空页面
                  Map<String, dynamic> auditMap = Map();
                  auditMap = {
                    "formid": "PRD_MORPT",
                    "data": {
                      'Ids': res['Result']['ResponseStatus']['SuccessEntitys']
                      [0]['Id']
                    }
                  };
                  await auditOrder(auditMap, i, EntryIds1 != '');
                } else {
                  Map<String, dynamic> deleteMap = Map();
                  deleteMap = {
                    "formid": "PRD_MORPT",
                    "data": {'Ids': resCheck['data']["Model"]["FID"]}
                  };
                  deleteOrder(deleteMap,
                      res['Result']['ResponseStatus']['Errors'][0]['Message']);
                }
              }
            } else {
              setState(() {
                this.isSubmit = false;
                ToastUtil.errorDialog(context, resCheck['msg']);
              });
              break;
            }
          }
        }
      }
    } else {
      setState(() {
        this.isSubmit = false;
        ToastUtil.showInfo('无提交数据');
      });

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
                  submitOder();
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
            title: Text("简单入库"),
            centerTitle: true,
            leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop("refresh");
                }),
            /*actions: <Widget>[
              new IconButton(
                  icon: new Icon(Icons.settings), onPressed: _pushSaved),
            ],*/
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
                          /* title: TextWidget(FBillNoKey, '生产订单：'),*/
                          title: Text("单号：$FBillNo"),
                          /*trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                IconButton(
                                  icon: new Icon(Icons.filter_center_focus),
                                  tooltip: '点击扫描',
                                  onPressed: () {
                                    checkItem = 'FBillNo';
                                    this.show = true;
                                    scanDialog();
                                  },
                                ),
                              ]),*/
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
                          title: Text("来源单号：$FSaleOrderNo"),
                          *//*title: TextWidget(FSaleOrderNoKey, '来源单号：'),*//*
                          trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                MyText('',
                                    color: Colors.grey, rightpadding: 18),
                              ]),
                        ),
                      ),
                      divider,
                    ],
                  ),*/Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text("备注：$FMemoItem"),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  /* _dateItem('生产日期：', DateMode.YMDHMS),
                  _item('类型:', ['成品', '半成品', '原材料工厂'], this.isTurnoff, 'isTurnoff'),*/
                  // _item('Laber', [123, 23,235,3,14545,15,123163,18548,9646,1313], 235, label: 'kg')
                  /*Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: PartRefreshWidget(FPrdOrgIdKey, () {
                            //2、使用 创建一个widget
                            return Text('生产车间：$FName');
                          }),
                          trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                if (!isScanWork)
                                  IconButton(
                                    icon: new Icon(Icons.filter_center_focus),
                                    tooltip: '点击扫描',
                                    onPressed: () {
                                      checkItem = 'FPrdOrgId';
                                      this.show = true;
                                      scanDialog();
                                    },
                                  ),
                              ]),
                        ),
                      ),
                      divider,
                    ],
                  ),*/
                  /*Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text('生产详细信息：'),
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
                        /*onPressed: () async {
                          if(this.hobby.length>0){
                            setState(() {
                              this.isSubmit = true;
                            });
                            submitOder();
                           */ /* Map<String, dynamic> dataMap = Map();
                            var numbers = [];
                            dataMap['formid'] = 'PRD_MO';
                            dataMap['opNumber'] = 'toStart';
                            var hobbyIndex = 0;
                            this.hobby.forEach((list) {
                              Map<String, dynamic> entityMap = Map();
                              entityMap['Id'] = orderDate[hobbyIndex][18];
                              entityMap['EntryIds'] = orderDate[hobbyIndex][5];
                              numbers.add(entityMap);
                               hobbyIndex++;
                            });
                            dataMap['data'] = {'PkEntryIds':numbers};
                            var status = await SubmitEntity.alterStatus(dataMap);
                            print(status);
                            if(status != null){
                              var res = jsonDecode(status);
                              print(res);
                              if(res != null){
                                if(res['Result']['ResponseStatus']['IsSuccess']){
                                  submitOder();
                                }else{
                                  ToastUtil.showInfo(res['Result']['ResponseStatus']['Errors'][0]['Message']);
                                }
                              }
                            }*/ /*
                          }else{
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
