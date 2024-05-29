import 'dart:convert';
import 'package:date_format/date_format.dart';
import 'package:fzwm_wxbc/model/currency_entity.dart';
import 'package:fzwm_wxbc/model/submit_entity.dart';
import 'package:fzwm_wxbc/utils/refresh_widget.dart';
import 'package:fzwm_wxbc/utils/text.dart';
import 'package:fzwm_wxbc/utils/toast_util.dart';
import 'package:fzwm_wxbc/views/index/print_page.dart';
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

class WarehousingDetail extends StatefulWidget {
  var FBillNo;

  WarehousingDetail({Key? key, @required this.FBillNo}) : super(key: key);

  @override
  _WarehousingDetailState createState() => _WarehousingDetailState(FBillNo);
}

class _WarehousingDetailState extends State<WarehousingDetail> {
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
  Map<String, dynamic> printData = {};
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

  _WarehousingDetailState(fBillNo) {
    this.FBillNo = fBillNo['value'];
    this.getOrderList();
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
    var tissue = sharedPreferences.getString('tissue');
    if (fOrgID == null) {
      this.fOrgID = tissue;
    }
    userMap['FilterString'] =
        "FForbidStatus = 'A' and FUseOrgId.FNumber ='" + fOrgID + "'";//
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
      userMap['FilterString'] = "FBillNo='$FBillNo'";
      userMap['FormId'] = 'PRD_MORPT';
      userMap['OrderString'] = 'FMaterialId.FNumber ASC';
      userMap['FieldKeys'] =
          'FBillNo,FPrdOrgId.FNumber,FPrdOrgId.FName,FDate,FMoBillNo,FEntity_FEntryId,FMaterialId.FNumber,FMaterialId.FName,FMaterialId.FSpecification,FWorkshipId.FNumber,FWorkshipId.FName,FUnitId.FNumber,FUnitId.FName,FFinishQty,FProduceDate,FExpiryDate,FSrcBillNo,FInspectQty,FID,FDocumentStatus,FStockId.FNumber,FStockId.FName,FStockInOrgId.FNumber,FMaterialId.FIsBatchManage,FAuxPropId.FF100002.FNumber';
      Map<String, dynamic> dataMap = Map();
      dataMap['data'] = userMap;
      String order = await CurrencyEntity.polling(dataMap);
      orderDate = [];
      printData = {};
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
      orderDate = jsonDecode(order);
      if (orderDate.length > 0) {
        orderDate.forEach((value) {
          fNumber.add(value[5]);
          List arr = [];
          arr.add({
            "title": "物料名称",
            "name": "FMaterial",
            "isHide": false,
            "value": {
              "label": value[7] + "- (" + value[6] + ")",
              "value": value[6],
              "barcode": [],
              "kingDeeCode": [],
              "scanCode": []
            }
          });
          arr.add({
            "title": "包装规格",
            "isHide": false,
            "name": "FMaterialIdFSpecification",
            "value": {"label": value[24]==null?"":value[24], "value": value[24]==null?"":value[24]}
          });
          arr.add({
            "title": "单位名称",
            "name": "FUnitId",
            "isHide": false,
            "value": {"label": value[12], "value": value[11]}
          });
          arr.add({
            "title": "入库数量",
            "name": "FRealQty",
            "isHide": false,
            /*value[12]*/
            "value": {"label": "0", "value": "0"}
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
            "isHide": value[23] != true,
            "value": {"label": "", "value": ""}
          });
          arr.add({
            "title": "仓位",
            "name": "FStockLocID",
            "isHide": false,
            "value": {"label": "", "value": "", "hide": false}
          });
          arr.add({
            "title": "操作",
            "name": "",
            "isHide": false,
            "value": {"label": "", "value": ""}
          });
          arr.add({
            "title": "库存单位",
            "name": "",
            "isHide": true,
            "value": {"label": value[18], "value": value[18]}
          });
          arr.add({
            "title": "检验数量",
            "name": "",
            "isHide": false,
            "value": {
              "label": value[13],
              "value": value[13],
              "rateValue": value[13]
            } /*+value[12]*0.1*/
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
          'FID,FInQtyTotal,FOutQtyTotal,FEntity_FEntryId,FRemainQty,FBarCodeQty,FStockID.FName,FStockID.FNumber,FMATERIALID.FNUMBER,FOwnerID.FNumber,FBarCode,FSN,FPackageSpec';
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
          this.getMaterialList(
              barcodeData, barcodeData[0][10], barcodeData[0][11], barcodeData[0][12]);
        } else {
          ToastUtil.showInfo(msg);
        }
      } else {
        ToastUtil.showInfo('条码不在条码清单中');
      }
    } else {
      _code = event;
      this.getMaterialList("", _code, '', '');
      print("ChannelPage: $event");
    }
  }

  getMaterialList(barcodeData, code, fsn,fAuxPropId) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var tissue = sharedPreferences.getString('tissue');
    var scanCode = code.split(";");
    userMap['FilterString'] = "FNumber='" +
        scanCode[0] +
        "' and FForbidStatus = 'A' and FUseOrgId.FNumber = '" +
        tissue +
        "'";
    userMap['FormId'] = 'BD_MATERIAL';
    userMap['FieldKeys'] =
        'FMATERIALID,F_UUAC_Text,FNumber,FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FIsBatchManage'; /*,SubHeadEntity1.FStoreUnitID.FNumber*/
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
              //判断扫描数量是否大于单据数量
              if (double.parse(element[3]['value']['label']) >=
                  element[9]['value']['rateValue']) {
                continue;
              } else {
                //判断条码数量
                if ((double.parse(element[3]['value']['label']) +
                            double.parse(barcodeNum)) >
                        0 &&
                    double.parse(barcodeNum) > 0) {
                  if ((double.parse(element[3]['value']['label']) +
                          double.parse(barcodeNum)) >=
                      element[9]['value']['rateValue']) {
                    //判断条码是否重复
                    if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                      var item = barCodeScan[0].toString() +
                          "-" +
                          (element[9]['value']['rateValue'] -
                                  double.parse(element[3]['value']['label']))
                              .toStringAsFixed(2)
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
                              (element[9]['value']['rateValue'] -
                                  double.parse(element[3]['value']['label'])))
                          .toString();
                      element[3]['value']['label'] = (double.parse(
                                  element[3]['value']['label']) +
                              (element[9]['value']['rateValue'] -
                                  double.parse(element[3]['value']['label'])))
                          .toString();
                      element[3]['value']['value'] =
                          element[3]['value']['label'];
                      residue = element[9]['value']['rateValue'] -
                          double.parse(element[3]['value']['label']);
                      element[0]['value']['kingDeeCode'].add(item);
                      element[0]['value']['scanCode'].add(code);
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
                      barcodeNum =
                          (double.parse(barcodeNum) - double.parse(barcodeNum))
                              .toString();
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
          //启用批号
          if (element[0]['value']['value'] == scanCode[0]) {
            if (element[0]['value']['barcode'].indexOf(code) == -1) {
              if (scanCode.length > 4) {
                element[0]['value']['barcode'].add(code);
              }
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
                //判断扫描数量是否大于单据数量
                if (double.parse(element[3]['value']['label']) >=
                    element[9]['value']['rateValue']) {
                  continue;
                } else {
                  //判断条码数量
                  if ((double.parse(element[3]['value']['label']) +
                              double.parse(barcodeNum)) >
                          0 &&
                      double.parse(barcodeNum) > 0) {
                    if ((double.parse(element[3]['value']['label']) +
                            double.parse(barcodeNum)) >=
                        element[9]['value']['rateValue']) {
                      //判断条码是否重复
                      if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                        var item = barCodeScan[0].toString() +
                            "-" +
                            (element[9]['value']['rateValue'] -
                                    double.parse(element[3]['value']['label']))
                                .toStringAsFixed(2)
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
                                (element[9]['value']['rateValue'] -
                                    double.parse(element[3]['value']['label'])))
                            .toString();
                        element[3]['value']['label'] = (double.parse(
                                    element[3]['value']['label']) +
                                (element[9]['value']['rateValue'] -
                                    double.parse(element[3]['value']['label'])))
                            .toString();
                        element[3]['value']['value'] =
                            element[3]['value']['label'];
                        residue = element[9]['value']['rateValue'] -
                            double.parse(element[3]['value']['label']);
                        element[0]['value']['kingDeeCode'].add(item);
                        element[0]['value']['scanCode'].add(code);
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
                      }
                    }
                  }
                }
              } else {
                if (element[5]['value']['value'] == "") {
                  element[5]['value']['label'] = scanCode[1];
                  element[5]['value']['value'] = scanCode[1];
                  //判断扫描数量是否大于单据数量
                  if (double.parse(element[3]['value']['label']) >=
                      element[9]['value']['rateValue']) {
                    continue;
                  } else {
                    //判断条码数量
                    if ((double.parse(element[3]['value']['label']) +
                                double.parse(barcodeNum)) >
                            0 &&
                        double.parse(barcodeNum) > 0) {
                      if ((double.parse(element[3]['value']['label']) +
                              double.parse(barcodeNum)) >=
                          element[9]['value']['rateValue']) {
                        //判断条码是否重复
                        if (element[0]['value']['scanCode'].indexOf(code) ==
                            -1) {
                          var item = barCodeScan[0].toString() +
                              "-" +
                              (element[9]['value']['rateValue'] -
                                      double.parse(
                                          element[3]['value']['label']))
                                  .toStringAsFixed(2)
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
                                  (element[9]['value']['rateValue'] -
                                      double.parse(
                                          element[3]['value']['label'])))
                              .toString();
                          element[3]['value']['label'] =
                              (double.parse(element[3]['value']['label']) +
                                      (element[9]['value']['rateValue'] -
                                          double.parse(
                                              element[3]['value']['label'])))
                                  .toString();
                          element[3]['value']['value'] =
                              element[3]['value']['label'];
                          residue = element[9]['value']['rateValue'] -
                              double.parse(element[3]['value']['label']);
                          element[0]['value']['kingDeeCode'].add(item);
                          element[0]['value']['scanCode'].add(code);
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
            "title": "物料名称",
            "name": "FMaterial",
            "isHide": false,
            "value": {
              "label": value[1] + "- (" + value[2] + ")",
              "value": value[2],
              "barcode": [code],
              "kingDeeCode": [],
              "scanCode": []
            }
          });
          arr.add({
            "title": "规格型号",
            "isHide": true,
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
            "title": "入库数量",
            "name": "FRealQty",
            "isHide": false,
            /*value[12]*/
            "value": {"label": "0", "value": "0"}
          });
          arr.add({
            "title": "仓库",
            "name": "FStockID",
            "isHide": false,
            "value": {"label": value[17], "value": value[16]}
          });
          arr.add({
            "title": "批号",
            "name": "FLot",
            "isHide": value[6] != true,
            "value": {
              "label": value[6] ? scanCode[1] : '',
              "value": value[6] ? scanCode[1] : ''
            }
          });
          arr.add({
            "title": "仓位",
            "name": "FStockLocID",
            "isHide": false,
            "value": {"label": "", "value": "", "hide": false}
          });
          arr.add({
            "title": "操作",
            "name": "",
            "isHide": false,
            "value": {"label": "", "value": ""}
          });
          arr.add({
            "title": "库存单位",
            "name": "",
            "isHide": true,
            "value": {"label": value[18], "value": value[18]}
          });
          arr.add({
            "title": "检验数量",
            "name": "",
            "isHide": false,
            "value": {
              "label": value[12],
              "value": value[12],
              "rateValue": value[12]
            } /*+value[12]*0.1*/
          });
          arr.add({
            "title": "最后扫描数量",
            "name": "FLastQty",
            "isHide": false,
            "value": {"label": "0", "value": "0"}
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
          if (j == 1) {
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
          } else
          if (j == 4) {
            comList.add(
              _item('仓库:', stockList, this.hobby[i][j]['value']['label'],
                  this.hobby[i][j],
                  stock: this.hobby[i]),
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
          } else if (j == 7) {
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
                            keyboardType: TextInputType.text,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                            ],
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
            "formid": "PRD_INSTOCK",
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

//审核
  auditOrder(Map<String, dynamic> auditMap) async {
    //获取登录信息
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var tissue = sharedPreferences.getString('tissue');
    await SubmitEntity.submit(auditMap);
    var subData = await SubmitEntity.audit(auditMap);
    var res = jsonDecode(subData);
    if (res != null) {
      if (res['Result']['ResponseStatus']['IsSuccess']) {
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
                  codeModel['FOwnerID'] = {"FNUMBER": tissue};
                  codeModel['FStockOrgID'] = {"FNUMBER": tissue};
                  codeModel['FStockID'] = {
                    "FNUMBER": this.hobby[i][4]['value']['value']
                  };
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

        /*Map<String, dynamic> inStockMap = Map();
        inStockMap['FilterString'] = "FSrcBillNo='" +
            res['Result']['ResponseStatus']['SuccessEntitys'][0]['Number'] +
            "'";
        inStockMap['FormId'] = 'PRD_INSTOCK';
        inStockMap['NeedReturnFields'] = [
          'FEntity',
          'FExpiryDate',
          'FMaterialName',
          'FProduceDate',
          'FInStockType'
        ];
        inStockMap['FieldKeys'] = 'FID';
        Map<String, dynamic> inStockDataMap = Map();
        inStockDataMap['data'] = inStockMap;
        String inStockMapOrder = await CurrencyEntity.polling(inStockDataMap);
        var inStockOrderRes = jsonDecode(inStockMapOrder);
        if (inStockOrderRes.length > 0) {
          Map<String, dynamic> submitMap = Map();
          submitMap = {
            "formid": "PRD_INSTOCK",
            "data": {'Ids': inStockOrderRes[0][0]}
          };
          var submitData = await SubmitEntity.submit(submitMap);
          await SubmitEntity.audit(submitMap);
          var resSubmit = jsonDecode(submitData);
          if (resSubmit['Result']['ResponseStatus']['IsSuccess']) {
            var returnData = res['Result']['NeedReturnData'];
            _showPrintDialog(context);
            for (var p = 0;
                p < printData['data']['Model']['FInStockEntry'].length;
                p++) {
              printData['data']['Model']['FEntity'][p]['FExpiryDate'] =
                  returnData[0]['FEntity'][p]['FExpiryDate'];
              printData['data']['Model']['FEntity'][p]['FProduceDate'] =
                  returnData[0]['FEntity'][p]['FProduceDate'];
              printData['data']['Model']['FEntity'][p]['FMaterialName'] =
                  returnData[0]['FEntity'][p]['FMaterialName'];
              printData['data']['Model']['FEntity'][p]['FBillNo'] =
                  returnData[0]['FBillNo'];
            }
            printData['type'] = "PRD_INSTOCK";
            printData['FInStockType'] = returnData[0]['FEntity'];
            ToastUtil.showInfo('提交入库成功');
          }
        }*/
        //打印确认

        /*setState(() {
            this.hobby = [];
            this.orderDate = [];
            this.printData = {};
            this.FBillNo = '';
            this.FSaleOrderNo = '';
          });
          ToastUtil.showInfo('提交成功');
          Navigator.of(context).pop("refresh");*/
        //提交清空页面
      } else {
        unAuditOrder(
            auditMap, res['Result']['ResponseStatus']['Errors'][0]['Message']);
      }
    }
  }
  //修改汇报单
  alterOrder() async {
    Map<String, dynamic> dataMap = Map();
    dataMap['formid'] = 'PRD_MORPT';
    Map<String, dynamic> orderMap = Map();
    orderMap['NeedReturnFields'] = [];
    orderMap['IsDeleteEntry'] = false;
    Map<String, dynamic> Model = Map();
    Model['FID'] = orderDate[0][18];
    var FEntity = [];
    for (int element = 0; element < this.hobby.length; element++) {
        if (this.hobby[element][3]['value']['value'] != '0') {
          // ignore: non_constant_identifier_names
          Map<String, dynamic> FEntityItem = Map();
          FEntityItem['FEntryID'] = orderDate[element][5];
          FEntityItem['FStockId'] = {
            "FNumber": this.hobby[element][4]['value']['value']
          };
          FEntity.add(FEntityItem);
        }
      }
    Model['FEntity'] = FEntity;
    orderMap['Model'] = Model;
    dataMap['data'] = orderMap;
    var saveData = jsonEncode(dataMap);
    String orderRes = await SubmitEntity.save(dataMap);
    var res = jsonDecode(orderRes);
    //判断成功
    if (res['Result']['ResponseStatus']['IsSuccess']) {
      Map<String, dynamic> dataMap = Map();
      dataMap = {
        "id": res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id'],
        "isBool": true
      };
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
  pushDown(val, type) async {
    var resAlter = await this.alterOrder();
    if(!resAlter['isBool']){
      setState(() {
        ToastUtil.errorDialog(context, resAlter['msg']);
        this.isSubmit = false;
      });
      return;
    };
    //下推
    Map<String, dynamic> pushMap = Map();
    pushMap['EntryIds'] = val;
    pushMap['RuleId'] = "PRD_MORPT2INSTOCK";
    pushMap['TargetFormId'] = "PRD_INSTOCK";
    pushMap['IsEnableDefaultRule'] = "false";
    pushMap['IsDraftWhenSaveFail'] = "false";
    print(pushMap);
    var downData =
        await SubmitEntity.pushDown({"formid": "PRD_MORPT", "data": pushMap});
    print(downData);
    var res = jsonDecode(downData);
    //判断成功
    if (res['Result']['ResponseStatus']['IsSuccess']) {
      //查询入库单
      var entitysNumber =
          res['Result']['ResponseStatus']['SuccessEntitys'][0]['Number'];
      Map<String, dynamic> inOrderMap = Map();
      inOrderMap['FormId'] = 'PRD_INSTOCK';
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
      orderMap['NeedUpDataFields'] = [
        'FEntity',
        "FFinishQty",
        "FQuaQty",
        'FSerialSubEntity',
        'FSerialNo'
      ];
      orderMap['NeedReturnFields'] = [
        'FEntity',
        'FSerialSubEntity',
        'FSerialNo'
      ];
      orderMap['IsDeleteEntry'] = true;
      Map<String, dynamic> Model = Map();
      Model['FID'] = res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id'];
      // ignore: non_constant_identifier_names
      var FEntity = [];
      for (int entity = 0; entity < resData.length; entity++) {
        for (int element = 0; element < this.hobby.length; element++) {
          if (resData[entity][1].toString() ==
              this.hobby[element][0]['value']['value'].toString()) {
            if (this.hobby[element][3]['value']['value'] != '0') {
              // ignore: non_constant_identifier_names
              Map<String, dynamic> FEntityItem = Map();
              FEntityItem['FEntryID'] = resData[entity][0];
              FEntityItem['FInStockType'] = '1';
              FEntityItem['FRealQty'] = this.hobby[element][3]['value']['value'];
              FEntityItem['FStockId'] = {
                "FNumber": this.hobby[element][4]['value']['value']
              };
                FEntityItem['FAuxPropId'] = {
                  "FAUXPROPID__FF100002": {"FNumber": this.hobby[element][1]['value']['value']}
                };
              FEntityItem['FLot'] = {
                "FNumber": this.hobby[element][5]['value']['value']
              };
              var fSerialSub = [];
              var kingDeeCode = this.hobby[element][0]['value']['kingDeeCode'];
              for (int subj = 0; subj < kingDeeCode.length; subj++) {
                Map<String, dynamic> subObj = Map();
                if (kingDeeCode[subj].split("-").length > 2) {
                  var itemCode = kingDeeCode[subj].split("-");
                  if (itemCode.length > 2) {
                    if (itemCode.length > 3) {
                      subObj['FSerialNo'] = itemCode[2] + '-' + itemCode[3];
                    } else {
                      subObj['FSerialNo'] = itemCode[2];
                    }
                  }
                } else {
                  subObj['FSerialNo'] = kingDeeCode[subj];
                }
                fSerialSub.add(subObj);
              }
              FEntityItem['FSerialSubEntity'] = fSerialSub;
              FEntity.add(FEntityItem);
            }
          }
        }
      }
      Model['FEntity'] = FEntity;
      orderMap['Model'] = Model;
      dataMap = {"formid": "PRD_INSTOCK", "data": orderMap, "isBool": true};
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
    if (this.hobby.length > 0) {
      setState(() {
        this.isSubmit = true;
      });
      var scNumber = 0;
      this.hobby.forEach((element) {
        if (double.parse(element[3]['value']['value']) > 0) {
          scNumber++;
        }
      });
      if (scNumber == 0) {
        ToastUtil.showInfo('请录入数量');
        return;
      }
      var EntryIds = '';
      //分两次读取良品，不良品数据
      var hobbyIndex = 0;
      this.hobby.forEach((element) {
        if (double.parse(element[3]['value']['value']) > 0) {
          if (EntryIds == '') {
            EntryIds = orderDate[hobbyIndex][5].toString();
          } else {
            EntryIds = EntryIds + ',' + orderDate[hobbyIndex][5].toString();
          }
        }
        hobbyIndex++;
      });
      //判断是否填写数量
      if (EntryIds == '') {
        this.isSubmit = false;
        ToastUtil.showInfo('无提交数据');
      } else {
        var resCheck = await this.pushDown(EntryIds, 'nonDefective');
        this.printData = resCheck;
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
                "formid": "PRD_INSTOCK",
                "data": {
                  'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]
                      ['Id']
                }
              };
              await auditOrder(auditMap);
            } else {
              Map<String, dynamic> deleteMap = Map();
              deleteMap = {
                "formid": "PRD_INSTOCK",
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
        }
      }
    } else {
      setState(() {
        this.isSubmit = false;
        ToastUtil.showInfo('无提交数据');
      });
    }
  }

  /// 打印确认
  Future<void> _showPrintDialog(cont) async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("是否打印"),
            actions: <Widget>[
              new FlatButton(
                child: new Text('不了'),
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    this.hobby = [];
                    this.orderDate = [];
                    this.printData = {};
                    this.FBillNo = '';
                    ToastUtil.showInfo('提交成功');
                    Navigator.of(cont).pop("refresh");
                  });
                },
              ),
              new FlatButton(
                child: new Text('打印'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return PrintPage(data: printData
                            // 路由参数
                            );
                      },
                    ),
                  ).then((data) {});
                },
              )
            ],
          );
        });
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
            title: Text("入库"),
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
                          title: Text("汇报单号：$FBillNo"),
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
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text("来源单号：$FSaleOrderNo"),
                          /*title: TextWidget(FSaleOrderNoKey, '来源单号：'),*/
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
                  ),
                  /*Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text("备注：$FMemoItem"),
                        ),
                      ),
                      divider,
                    ],
                  ),*/
                  _dateItem('日期：', DateMode.YMD),
                  /*  _item('类型:', ['成品', '半成品', '原材料工厂'], this.isTurnoff, 'isTurnoff'),*/
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
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text('汇报详细信息：'),
                        ),
                      ),
                      divider,
                    ],
                  ),
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
