import 'dart:convert';
import 'dart:ui';
import 'package:date_format/date_format.dart';
import 'package:decimal/decimal.dart';
import 'package:fzwm_wxbc/model/currency_entity.dart';
import 'package:fzwm_wxbc/model/submit_entity.dart';
import 'package:fzwm_wxbc/utils/handler_order.dart';
import 'package:fzwm_wxbc/utils/refresh_widget.dart';
import 'package:fzwm_wxbc/utils/text.dart';
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
import 'package:qrscan/qrscan.dart' as scanner;
import 'package:shared_preferences/shared_preferences.dart';

final String _fontFamily = Platform.isWindows ? "Roboto" : "";

class AllocationDetail extends StatefulWidget {
  var FBillNo;

  AllocationDetail({Key? key, @required this.FBillNo}) : super(key: key);

  @override
  _RetrievalDetailState createState() => _RetrievalDetailState(FBillNo);
}

class _RetrievalDetailState extends State<AllocationDetail> {
  var _remarkContent = new TextEditingController();
  GlobalKey<PartRefreshWidgetState> globalKey = GlobalKey();
  GlobalKey<TextWidgetState> textKey = GlobalKey();
  final _textNumber = TextEditingController();
  var checkItem;
  String FBillNo = '';
  String keyWord = '';
  String FName = '';
  String FNumber = '';
  String FDate = '';
  var isSubmit = false;
  var show = false;
  var isScanWork = false;
  var checkData;
  var fOrgID;
  var checkDataChild;
  var selectData = {
    DateMode.YMD: '',
  };
  var organizationsName;
  var organizationsNumber;
  var fBarCodeList;
  var stockList = [];
  List<dynamic> stockListObj = [];
  var organizationsList = [];
  List<dynamic> organizationsListObj = [];
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
  var fBillNo;
  var organizationsName1;
  var organizationsNumber1;
  var organizationsName2;
  var organizationsNumber2;
  final controller = TextEditingController();
  _RetrievalDetailState(FBillNo) {
    if (FBillNo != null) {
      this.fBillNo = FBillNo['value'];
      this.getOrderList("");
      isScanWork = true;
    } else {
      isScanWork = false;
      this.fBillNo = '';
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
      //getStockList();
      getOrganizationsList();
    }
  }

  @override
  void initState() {
    super.initState();
    // 开启监听
    if (_subscription == null) {
      _subscription = scannerPlugin
          .receiveBroadcastStream()
          .listen(_onEvent, onError: _onError);
    }
    /*getWorkShop();*/
   //_onEvent("11041;202406183舜恩/骊骅;2024-06-18;1350;,1437050913;2");
    _onEvent("13095;20190618考科;2019-06-18;1;,1006124995;2");
    //_onEvent("13125;20240905安德/本溪黑马;2024-09-05;25;,1730336671;2");
    EasyLoading.dismiss();
  }

  //获取仓库
  getStockList() async {
    stockList = [];
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BD_STOCK';
    userMap['FieldKeys'] = 'FStockID,FName,FNumber,FIsOpenLocation';
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    if (fOrgID == null) {
      this.fOrgID = deptData[1];
    }
    if(this.organizationsNumber2 != null){
      userMap['FilterString'] = "FForbidStatus = 'A' and FDocumentStatus = 'C' and FUseOrgId.FNumber="+this.organizationsNumber2.toString();
    }else{
      userMap['FilterString'] = "FForbidStatus = 'A' and FDocumentStatus = 'C'";
    }
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    stockListObj = jsonDecode(res);
    var fStockIds = jsonDecode(sharedPreferences.getString('FStockIds')).split(',');
    stockListObj.forEach((element) {
      stockList.add(element[1]);
    });
    /*if(jsonDecode(sharedPreferences.getString('FStockIds')) != ''){
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
    }*/
    print(stockList);
  }

  //获取组织
  getOrganizationsList() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      this.organizationsNumber1 = sharedPreferences.getString('tissue');
      this.organizationsName1 = sharedPreferences.getString('tissueName');
    });
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'ORG_Organizations';
    userMap['FieldKeys'] = 'FForbidStatus,FName,FNumber,FDocumentStatus';
    userMap['FilterString'] = "FForbidStatus = 'A' and FDocumentStatus = 'C'";
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    organizationsListObj = jsonDecode(res);
    organizationsListObj.forEach((element) {
      organizationsList.add(element[1]);
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
  getInventoryList() async{
    Map<String, dynamic> userMap = Map();
    if(this.keyWord != '' && this.organizationsNumber1 != null){
      userMap['FilterString'] =
          "FMaterialId.FNumber='"+this.keyWord+"' and FBaseQty >0 and FStockOrgId.FNumber="+this.organizationsNumber1.toString();
    }else{
      if(this.keyWord == ""){
        ToastUtil.showInfo('请输入查询信息');
        return;
      }
      if(this.organizationsNumber1 == null){
        ToastUtil.showInfo('请选择调出货主');
        return;
      }
    }
    userMap['FormId'] = 'STK_Inventory';
    userMap['FieldKeys'] =
    'FStockOrgId.FNumber,FStockId.FNumber';
    Map<String, dynamic> stockMap = Map();
    stockMap['data'] = userMap;
    String stockRes = await CurrencyEntity.polling(stockMap);
    var stockFlex = jsonDecode(stockRes);
    String order = "";
    if (stockFlex.length > 0) {
      List stockFlexRes = [];
      for(var item in stockFlex){
        Map<String, dynamic> stockMap = Map();
        stockMap['FormId'] = 'BD_STOCK';
        stockMap['FieldKeys'] =
        'FStockID,FName,FNumber,FIsOpenLocation';
        stockMap['FilterString'] = "FNumber = '" +
            item[1] +
            "' and FUseOrgId.FNumber = '" +
            item[0] +
            "'";
        Map<String, dynamic> stockDataMap = Map();
        stockDataMap['data'] = stockMap;
        String res = await CurrencyEntity.polling(stockDataMap);
        if (jsonDecode(res).length > 0) {
          stockFlexRes.addAll(jsonDecode(res));
        }
      }
      print(stockFlexRes);
      List stockData = [];
      for(var item in stockFlexRes){
        if(item[4] != null){
          userMap['FieldKeys'] ='FMaterialId.FNumber,FMaterialId.FName,FMaterialId.FSpecification,FStockId.FName,FStockId.FNumber,FStockLocId.'+item[4] +'.FName,FBaseUnitId.FNumber,FBaseUnitId.FName,FBaseQty,FLot.FNumber,FOwnerId.FNumber,FMaterialId.FIsBatchManage,FProduceDate,FExpiryDate,FMaterialId.FIsKFPeriod,FID';
          Map<String, dynamic> dataMap = Map();
          dataMap['data'] = userMap;
          order = await CurrencyEntity.polling(dataMap);
          var orderRes = jsonDecode(order);
          if (orderRes.length > 0) {
            for(var flexItem in orderRes){
              flexItem.add(item[4]);
            }
            stockData.addAll(orderRes);
          }
        }
      }
      setState(() {
        EasyLoading.dismiss();
      });
      if(stockData.length>0){
        await _showMultiChoiceModalBottomSheet(context, stockData);
      }else{
        ToastUtil.showInfo('无库存数量');
      }
    } else {
      setState(() {
        EasyLoading.dismiss();
      });
      ToastUtil.showInfo('无数据');
    }
  }
  getOrderList(data) async {
    EasyLoading.show(status: 'loading...');
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
    if (data.length > 0) {
      this.fOrgID = data[0][10];
      hobby = [];
      data.forEach((value) {
        List arr = [];
        arr.add({
          "title": "物料名称",
          "name": "FMaterial",
          "isHide": false,
          "value": {
            "label": value[1] + "- (" + value[0] + ")",
            "value": value[0],
            "fid": value[16],
            "barcode": []
          }
        });
        arr.add({
          "title": "规格型号",
          "name": "FMaterialIdFSpecification",
          "isHide": true,
          "value": {"label": value[2], "value": value[2]}
        });
        arr.add({
          "title": "单位名称",
          "name": "FUnitId",
          "isHide": false,
          "value": {"label": value[7], "value": value[6]}
        });
        arr.add({
          "title": "调拨数量",
          "name": "FBaseQty",
          "isHide": false,
          "value": {"label": "", "value": "0"}
        });
        arr.add({
          "title": "申请数量",
          "name": "FRemainOutQty",
          "isHide": true,
          "value": {"label": "", "value": "0"}
        });
        arr.add({
          "title": "批号",
          "name": "FLot",
          "isHide": value[11] != true,
          "value": {"label": value[9], "value": value[9]}
        });
        arr.add({
          "title": "调出仓库",
          "name": "FStockId",
          "isHide": false,
          "value": {"label": value[3], "value": value[4], 'dimension': value[16]}
        });
        arr.add({
          "title": "调出仓位",
          "name": "FStockLocID",
          "isHide": false,
          "value": {"label": value[5], "value": value[5]}
        });
        arr.add({
          "title": "调入仓库",
          "name": "FStockId",
          "isHide": false,
          "value": {"label": "", "value": ""}
        });
        arr.add({
          "title": "调入仓位",
          "name": "FStockLocID",
          "isHide": false,
          "value": {"label": "", "value": ""}
        });
        arr.add({
          "title": "最后扫描数量",
          "name": "FLastQty",
          "isHide": true,
          "value": {"label": "0", "value": "0"}
        });
        arr.add({
          "title": "生产日期",
          "name": "FProduceDate",
          "isHide": value[14] != true,
          "value": {
            "label": value[12] == null ? '' : value[12].substring(0, 10),
            "value": value[12] == null ? '' : value[12].substring(0, 10)
          }
        });
        arr.add({
          "title": "有效期至",
          "name": "FExpiryDate",
          "isHide": value[14] != true,
          "value": {
            "label": value[13] == null ? '' : value[13].substring(0, 10),
            "value": value[13] == null ? '' : value[13].substring(0, 10)
          }
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
    if (checkItem == 'FLoc') {
      _FNumber = event.trim();
      this._textNumber.value = _textNumber.value.copyWith(
        text: event.trim(),
      );
    } else {
      SharedPreferences sharedPreferences =
      await SharedPreferences.getInstance();
      var deptData = sharedPreferences.getString('menuList');
      var menuList = new Map<dynamic, dynamic>.from(jsonDecode(deptData));
      fBarCodeList = menuList['FBarCodeList'];
      if (event == "") {
        return;
      }
      if (fBarCodeList == 1) {
        Map<String, dynamic> barcodeMap = Map();
        barcodeMap['FilterString'] = "FBarCodeEn='" + event.trim() + "'";
        barcodeMap['FormId'] = 'QDEP_Cust_BarCodeList';
        barcodeMap['FieldKeys'] =
        'FID,FInQtyTotal,FOutQtyTotal,FEntity_FEntryId,FRemainQty,FBarCodeQty,FStockID.FNumber,FBatchNo,FMATERIALID.FNUMBER,FOwnerID.FNumber,FBarCode,FSN,FProduceDate,FExpiryDate,FBatchNo,FStockOrgID.FNumber,FPackageSpec,FStockLocIDH,FStockID.FIsOpenLocation';
        Map<String, dynamic> dataMap = Map();
        dataMap['data'] = barcodeMap;
        String order = await CurrencyEntity.polling(dataMap);
        var barcodeData = jsonDecode(order);
        if (barcodeData.length > 0) {
          var msg = "";
          var orderIndex = 0;
          print(fNumber);
          for (var value in orderDate) {
            print(value[7]);
            print(barcodeData[0][8]);
            if (value[5] == barcodeData[0][8]) {
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
            this.fOrgID = barcodeData[0][15];
            this.getMaterialList(
                barcodeData,
                barcodeData[0][10],
                barcodeData[0][11],
                barcodeData[0][12].substring(0, 10),
                barcodeData[0][13].substring(0, 10),
                barcodeData[0][14],
                barcodeData[0][17],
                barcodeData[0][18]);
            print("ChannelPage: $event");
          } else {
            ToastUtil.showInfo(msg);
          }
        } else {
          ToastUtil.showInfo('条码不在条码清单中');
        }
      } else {
        _code = event;
        this.getMaterialList("", _code, '', '', '', '', '', false);
        print("ChannelPage: $event");
      }
    }
    checkItem = '';
    print("ChannelPage: $event");
  }

  void _onError(Object error) {
    setState(() {
      _code = "扫描异常";
    });
  }

  getMaterialList(barcodeData, code, fsn, fProduceDate, fExpiryDate, fBatchNo, fLoc, fIsOpenLocation) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    var scanCode = _code.split(";");
    Map<String, dynamic> stockMap = Map();
    stockMap['FormId'] = 'BD_STOCK';
    stockMap['FieldKeys'] =
    'FStockID,FName,FNumber,FIsOpenLocation,FFlexNumber';
    stockMap['FilterString'] = "FNumber = '" +
        barcodeData[0][6].split('/')[0] +
        "' and FUseOrgId.FNumber = '" +
        barcodeData[0][15] +
        "'";
    Map<String, dynamic> stockDataMap = Map();
    stockDataMap['data'] = stockMap;
    String res = await CurrencyEntity.polling(stockDataMap);
    var stocks = jsonDecode(res);
    if (stocks.length > 0) {
      if (stocks[0][4] != null && barcodeData[0][17] != 0 ) {
        var position = barcodeData[0][17].split(".");
        userMap['FilterString'] = "FMaterialId.FNumber='" +
            barcodeData[0][8] +
            "' and FStockID.FNumber='" +
            barcodeData[0][6].split('/')[0] +
            "' and FStockLocId." +
            stocks[0][4] +
            ".FNumber = '" +
            position[0] +
            "' and FStockLocId." +
            stocks[1][4] +
            ".FNumber = '" +
            position[1] +
            "' and FStockLocId." +
            stocks[2][4] +
            ".FNumber = '" +
            position[2] +
            "' and FStockLocId." +
            stocks[3][4] +
            ".FNumber = '" +
            position[3] +
            "' and FLot.FNumber = '" +
            fBatchNo +
            "' and FBaseQty > 0";
      }else{
        userMap['FilterString'] = "FMaterialId.FNumber='" +
            barcodeData[0][8] +
            "' and FStockID.FNumber='" +
            barcodeData[0][6].split('/')[0] +
            /*"' and FUseOrgId.FNumber = '" +
            deptData[1] +*/
            "' and FLot.FNumber = '" +
            fBatchNo +
            "' and FBaseQty > 0";
      }
    } else {
      userMap['FilterString'] = "FMaterialId.FNumber='" +
          barcodeData[0][8] +
          "' and FStockID.FNumber='" +
          barcodeData[0][6].split('/')[0] +
          /*"' and FUseOrgId.FNumber = '" +
          deptData[1] +*/
          "' and FLot.FNumber = '" +
          fBatchNo +
          "' and FBaseQty > 0";
    }
    userMap['FormId'] = 'STK_Inventory';
    userMap['FieldKeys'] =
        'FMATERIALID.FName,FMATERIALID.FNumber,FMATERIALID.FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FMATERIALID.FIsBatchManage,FLot.FNumber,FStockID.FNumber,FStockID.FName,FStockLocID,FStockLocID,FBaseQty,FProduceDate,FExpiryDate,FMATERIALID.FIsKFPeriod,FAuxPropId.FF100002.FNumber,FStockID.FIsOpenLocation';
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
      var barcodeNum = barCodeScan[4];
      var residue = double.parse(barCodeScan[4]);
      var hobbyIndex = 0;
      var errorTitle = "";
      for (var element in hobby) {
        var residue = 0.0;
        //判断是否启用批号
        if (element[5]['isHide']) {
          //不启用
          if (element[0]['value']['value'] == barcodeData[0][8]) {
            if (element[0]['value']['barcode'].indexOf(code) == -1) {
              //判断是否启用保质期
              if (!element[11]['isHide']) {
                print(element[11]['value']['value'] != fProduceDate &&
                    element[12]['value']['value'] != fExpiryDate);
                if (element[11]['value']['value'] == fProduceDate &&
                    element[12]['value']['value'] == fExpiryDate) {
                  errorTitle = "";
                } else {
                  errorTitle = "保质期不一致";
                  continue;
                }
              }
              //判断是否启用仓位
              if (element[9]['value']['hide']) {
                if (element[9]['value']['label'] == fLoc) {
                  errorTitle = "";
                } else {
                  errorTitle = "仓位不一致";
                  continue;
                }
              }
              if (scanCode[5] == "N") {
                if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                  element[3]['value']['value'] =
                      (double.parse(element[3]['value']['value']) +
                          double.parse(barcodeNum))
                          .toString();
                  element[3]['value']['label'] = element[3]['value']['value'];
                  var item = barCodeScan[0].toString() + "-" + barcodeNum;
                  element[0]['value']['kingDeeCode'].add(item);
                  element[0]['value']['scanCode'].add(code);
                  element[10]['value']['label'] = barcodeNum.toString();
                  element[10]['value']['value'] = barcodeNum.toString();
                  barcodeNum =
                      (double.parse(barcodeNum) - double.parse(barcodeNum))
                          .toString();
                  number++;
                }
                //判断是否可重复扫码
                if (scanCode.length > 4) {
                  element[0]['value']['barcode'].add(code);
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
                    var item = barCodeScan[0].toString() + "-" + barcodeNum;
                    element[0]['value']['kingDeeCode'].add(item);
                    element[0]['value']['scanCode'].add(code);
                    element[10]['value']['label'] = barcodeNum.toString();
                    element[10]['value']['value'] = barcodeNum.toString();
                    barcodeNum =
                        (double.parse(barcodeNum) - double.parse(barcodeNum))
                            .toString();
                    number++;
                    print(2);
                    print(element[0]['value']['kingDeeCode']);
                  }
                } else {*/
                  if (this.isScanWork) {
                    //判断扫描数量是否大于单据数量
                    if (double.parse(element[3]['value']['value']) >=
                        element[4]['value']['label']) {
                      continue;
                    } else {
                      //判断二维码数量是否大于单据数量
                      if ((double.parse(element[3]['value']['value']) +
                          double.parse(barcodeNum)) >=
                          element[4]['value']['label']) {
                        //判断条码是否重复
                        if (element[0]['value']['scanCode'].indexOf(code) ==
                            -1) {
                          var item = barCodeScan[0].toString() +
                              "-" +
                              (element[4]['value']['label'] -
                                  double.parse(
                                      element[3]['value']['label']))
                                  .toString();
                          element[10]['value']['label'] = (element[9]['value']
                          ['label'] -
                              double.parse(element[3]['value']['value']))
                              .toString();
                          element[10]['value']['value'] = (element[9]['value']
                          ['label'] -
                              double.parse(element[3]['value']['value']))
                              .toString();
                          barcodeNum = (double.parse(barcodeNum) -
                              (element[4]['value']['label'] -
                                  double.parse(
                                      element[3]['value']['label'])))
                              .toString();
                          element[3]['value']['label'] =
                              (double.parse(element[3]['value']['value']) +
                                  (element[4]['value']['label'] -
                                      double.parse(
                                          element[3]['value']['label'])))
                                  .toString();
                          element[3]['value']['value'] =
                          element[3]['value']['label'];
                          residue = element[4]['value']['label'] -
                              double.parse(element[3]['value']['value']);
                          element[0]['value']['kingDeeCode'].add(item);
                          element[0]['value']['scanCode'].add(code);
                          number++;
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
                              barCodeScan[0].toString() + "-" + barcodeNum;
                          element[10]['value']['label'] = barcodeNum.toString();
                          element[10]['value']['value'] = barcodeNum.toString();
                          element[0]['value']['kingDeeCode'].add(item);
                          element[0]['value']['scanCode'].add(code);
                          barcodeNum = (double.parse(barcodeNum) -
                              double.parse(barcodeNum))
                              .toString();
                          number++;
                          print(2);
                          print(element[0]['value']['kingDeeCode']);
                        }
                      }
                    }
                  } else {
                    //判断条码是否重复
                    if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                      element[3]['value']['label'] =
                          (double.parse(element[3]['value']['value']) +
                              double.parse(barcodeNum))
                              .toString();
                      element[3]['value']['value'] =
                      element[3]['value']['label'];
                      var item = barCodeScan[0].toString() + "-" + barcodeNum;
                      element[10]['value']['label'] = barcodeNum.toString();
                      element[10]['value']['value'] = barcodeNum.toString();
                      element[0]['value']['kingDeeCode'].add(item);
                      element[0]['value']['scanCode'].add(code);
                      barcodeNum =
                          (double.parse(barcodeNum) - double.parse(barcodeNum))
                              .toString();
                      number++;
                      print(2);
                      print(element[0]['value']['kingDeeCode']);
                    }
                  }
                //}
              }
              //判断是否可重复扫码
              if (scanCode.length > 4) {
                element[0]['value']['barcode'].add(code);
              }
            } else {
              ToastUtil.showInfo('该标签已扫描');
              break;
            }
          }
        } else {
          if (element[0]['value']['value'] == barcodeData[0][8]) {
            if (element[0]['value']['barcode'].indexOf(code) == -1) {
              //判断是否启用保质期
              if (!element[11]['isHide']) {
                print(element[11]['value']['value'] != fProduceDate &&
                    element[12]['value']['value'] != fExpiryDate);
                if (element[11]['value']['value'] == fProduceDate &&
                    element[12]['value']['value'] == fExpiryDate) {
                  errorTitle = "";
                } else {
                  errorTitle = "保质期不一致";
                  continue;
                }
              }
              //判断是否启用仓位
              if (element[9]['value']['hide']) {
                if (element[9]['value']['label'] == fLoc) {
                  errorTitle = "";
                } else {
                  errorTitle = "仓位不一致";
                  continue;
                }
              }
              //启用批号
              if (scanCode[5] == "N") {
                if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                  if (element[5]['value']['value'] == "") {
                    element[5]['value']['label'] = fBatchNo;
                    element[5]['value']['value'] = fBatchNo;
                  }
                  element[3]['value']['value'] =
                      (double.parse(element[3]['value']['value']) +
                          double.parse(barcodeNum))
                          .toString();
                  element[3]['value']['label'] = element[3]['value']['value'];
                  var item = barCodeScan[0].toString() + "-" + barcodeNum;
                  element[0]['value']['kingDeeCode'].add(item);
                  element[0]['value']['scanCode'].add(code);
                  element[10]['value']['label'] = barcodeNum.toString();
                  element[10]['value']['value'] = barcodeNum.toString();
                  barcodeNum =
                      (double.parse(barcodeNum) - double.parse(barcodeNum))
                          .toString();
                  number++;
                }
                //判断是否可重复扫码
                if (scanCode.length > 4) {
                  element[0]['value']['barcode'].add(code);
                }
                break;
              }
              if (element[5]['value']['value'] == fBatchNo) {
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
                      var item = barCodeScan[0].toString() + "-" + barcodeNum;
                      element[10]['value']['label'] = barcodeNum.toString();
                      element[10]['value']['value'] = barcodeNum.toString();
                      element[0]['value']['kingDeeCode'].add(item);
                      element[0]['value']['scanCode'].add(code);
                      barcodeNum =
                          (double.parse(barcodeNum) - double.parse(barcodeNum))
                              .toString();
                      number++;
                      print(2);
                      print(element[0]['value']['kingDeeCode']);
                    }
                  } else {*/
                    if (this.isScanWork) {
                      //判断扫描数量是否大于单据数量
                      if (double.parse(element[3]['value']['value']) >=
                          element[4]['value']['label']) {
                        continue;
                      } else {
                        //判断二维码数量是否大于单据数量
                        if ((double.parse(element[3]['value']['value']) +
                            double.parse(barcodeNum)) >=
                            element[4]['value']['label']) {
                          //判断条码是否重复
                          if (element[0]['value']['scanCode'].indexOf(code) ==
                              -1) {
                            var item = barCodeScan[0].toString() +
                                "-" +
                                (element[4]['value']['label'] -
                                    double.parse(
                                        element[3]['value']['label']))
                                    .toString();
                            element[10]['value']['label'] = (element[9]['value']
                            ['label'] -
                                double.parse(element[3]['value']['value']))
                                .toString();
                            element[10]['value']['value'] = (element[9]['value']
                            ['label'] -
                                double.parse(element[3]['value']['value']))
                                .toString();
                            barcodeNum = (double.parse(barcodeNum) -
                                (element[4]['value']['label'] -
                                    double.parse(
                                        element[3]['value']['label'])))
                                .toString();
                            element[3]['value']['label'] =
                                (double.parse(element[3]['value']['value']) +
                                    (element[4]['value']['label'] -
                                        double.parse(
                                            element[3]['value']['label'])))
                                    .toString();
                            element[3]['value']['value'] =
                            element[3]['value']['label'];
                            residue = element[4]['value']['label'] -
                                double.parse(element[3]['value']['value']);
                            element[0]['value']['kingDeeCode'].add(item);
                            element[0]['value']['scanCode'].add(code);
                            number++;
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
                                barCodeScan[0].toString() + "-" + barcodeNum;
                            element[0]['value']['kingDeeCode'].add(item);
                            element[0]['value']['scanCode'].add(code);
                            barcodeNum = (double.parse(barcodeNum) -
                                double.parse(barcodeNum))
                                .toString();
                            number++;
                            print(2);
                            print(element[0]['value']['kingDeeCode']);
                          }
                        }
                      }
                    } else {
                      //判断条码是否重复
                      if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                        element[3]['value']['label'] =
                            (double.parse(element[3]['value']['value']) +
                                double.parse(barcodeNum))
                                .toString();
                        element[3]['value']['value'] =
                        element[3]['value']['label'];
                        var item = barCodeScan[0].toString() + "-" + barcodeNum;
                        element[10]['value']['label'] = barcodeNum.toString();
                        element[10]['value']['value'] = barcodeNum.toString();
                        element[0]['value']['kingDeeCode'].add(item);
                        element[0]['value']['scanCode'].add(code);
                        barcodeNum = (double.parse(barcodeNum) -
                            double.parse(barcodeNum))
                            .toString();
                        number++;
                        print(2);
                        print(element[0]['value']['kingDeeCode']);
                      }
                    }
                  //}
                }
                //判断是否可重复扫码
                if (scanCode.length > 4) {
                  element[0]['value']['barcode'].add(code);
                }
              } else {
                if (element[5]['value']['value'] == "") {
                  element[5]['value']['label'] = fBatchNo;
                  element[5]['value']['value'] = fBatchNo;
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
                        var item = barCodeScan[0].toString() + "-" + barcodeNum;
                        element[10]['value']['label'] = barcodeNum.toString();
                        element[10]['value']['value'] = barcodeNum.toString();
                        element[0]['value']['kingDeeCode'].add(item);
                        element[0]['value']['scanCode'].add(code);
                        barcodeNum = (double.parse(barcodeNum) -
                            double.parse(barcodeNum))
                            .toString();
                        number++;
                        print(2);
                        print(element[0]['value']['kingDeeCode']);
                      }
                    } else {*/
                      if (this.isScanWork) {
                        //判断扫描数量是否大于单据数量
                        if (double.parse(element[3]['value']['value']) >=
                            element[4]['value']['label']) {
                          continue;
                        } else {
                          //判断二维码数量是否大于单据数量
                          if ((double.parse(element[3]['value']['value']) +
                              double.parse(barcodeNum)) >=
                              element[4]['value']['label']) {
                            //判断条码是否重复
                            if (element[0]['value']['scanCode'].indexOf(code) ==
                                -1) {
                              var item = barCodeScan[0].toString() +
                                  "-" +
                                  (element[4]['value']['label'] -
                                      double.parse(
                                          element[3]['value']['label']))
                                      .toString();
                              element[10]['value']['label'] = (element[9]
                              ['value']['label'] -
                                  double.parse(
                                      element[3]['value']['label']))
                                  .toString();
                              element[10]['value']['value'] = (element[9]
                              ['value']['label'] -
                                  double.parse(
                                      element[3]['value']['label']))
                                  .toString();
                              barcodeNum = (double.parse(barcodeNum) -
                                  (element[4]['value']['label'] -
                                      double.parse(
                                          element[3]['value']['label'])))
                                  .toString();
                              element[3]['value']['label'] =
                                  (double.parse(element[3]['value']['value']) +
                                      (element[4]['value']['label'] -
                                          double.parse(element[3]['value']
                                          ['label'])))
                                      .toString();
                              element[3]['value']['value'] =
                              element[3]['value']['label'];
                              residue = element[4]['value']['label'] -
                                  double.parse(element[3]['value']['value']);
                              element[0]['value']['kingDeeCode'].add(item);
                              element[0]['value']['scanCode'].add(code);
                              number++;
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
                                  barCodeScan[0].toString() + "-" + barcodeNum;
                              element[10]['value']['label'] =
                                  barcodeNum.toString();
                              element[10]['value']['value'] =
                                  barcodeNum.toString();
                              element[0]['value']['kingDeeCode'].add(item);
                              element[0]['value']['scanCode'].add(code);
                              barcodeNum = (double.parse(barcodeNum) -
                                  double.parse(barcodeNum))
                                  .toString();
                              number++;
                              print(2);
                              print(element[0]['value']['kingDeeCode']);
                            }
                          }
                        }
                      } else {
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
                              barCodeScan[0].toString() + "-" + barcodeNum;
                          element[10]['value']['label'] = barcodeNum.toString();
                          element[10]['value']['value'] = barcodeNum.toString();
                          element[0]['value']['kingDeeCode'].add(item);
                          element[0]['value']['scanCode'].add(code);
                          barcodeNum = (double.parse(barcodeNum) -
                              double.parse(barcodeNum))
                              .toString();
                          number++;
                          print(2);
                          print(element[0]['value']['kingDeeCode']);
                        }
                      }
                    //}
                  }
                  //判断是否可重复扫码
                  if (scanCode.length > 4) {
                    element[0]['value']['barcode'].add(code);
                  }
                }
              }
            } else {
              number++;
              ToastUtil.showInfo('该标签已扫描');
              break;
            }
          }
        }
      }
      setState(() {
        EasyLoading.dismiss();
      });
      if (number == 0 && this.fBillNo == "") {
        for (var value in materialDate) {
          List arr = [];
          arr.add({
            "title": "物料名称",
            "name": "FMaterial",
            "isHide": false,
            "value": {
              "label": value[0] + "- (" + value[1] + ")",
              "value": value[1],
              "barcode": [_code],
              "kingDeeCode": [barCodeScan[0].toString()+"-"+barCodeScan[4]+"-"+fsn],"scanCode": [barCodeScan[0].toString()+"-"+barCodeScan[4]],
              "codeList": []
            }
          });
          arr.add({
            "title": "包装规格",
            "isHide": false,
            "name": "FMaterialIdFSpecification",
            "value": {"label": barcodeData[0][16], "value": barcodeData[0][16]}
          });
          arr.add({
            "title": "单位名称",
            "name": "FUnitId",
            "isHide": false,
            "value": {"label": value[3], "value": value[4]}
          });
          arr.add({
            "title": "移库数量",
            "name": "FRemainOutQty",
            "isHide": false,
            "value": {"label": barcodeNum, "value": barcodeNum}
          });
          arr.add({
            "title": "申请数量",
            "name": "FRealQty",
            "isHide": true,
            "value": {"label": "", "value": "0"}
          });
          arr.add({
            "title": "批号",
            "name": "FLot",
            "isHide": value[5] != true,
            "value": {"label": value[6], "value": value[6]}
          });
          arr.add({
            "title": "移出仓库",
            "name": "FStockID",
            "isHide": false,
            "value": {"label": value[8], "value": value[7], 'dimension': ""}
          });
          arr.add({
            "title": "移出仓位",
            "name": "FStockLocID",
            "isHide": false,
            "value": {"label": value[9], "value": value[10], "hide": value[16]}
          });
          arr.add({
            "title": "移入仓库",
            "name": "FStockID",
            "isHide": false,
            "value": {"label": "", "value": "", "dimension": stocks[0][4]}
          });
          arr.add({
            "title": "移入仓位",
            "name": "FStockLocID",
            "isHide": false,
            "value": {"label": "", "value": "", "hide": false}
          });
          arr.add({
            "title": "最后扫描数量",
            "name": "FLastQty",
            "isHide": false,
            "value": {
              "label": barcodeNum.toString(),
              "value": barcodeNum.toString(),"remainder": "0","representativeQuantity": barCodeScan[4].toString()
            }
          });
          arr.add({
            "title": "生产日期",
            "name": "FProduceDate",
            "isHide": value[14] != true,
            "value": {
              "label": value[12] == null ? '' : value[12].substring(0, 10),
              "value": value[12] == null ? '' : value[12].substring(0, 10)
            }
          });
          arr.add({
            "title": "有效期至",
            "name": "FExpiryDate",
            "isHide": value[14] != true,
            "value": {
              "label": value[13] == null ? '' : value[13].substring(0, 10),
              "value": value[13] == null ? '' : value[13].substring(0, 10)
            }
          });
          arr.add({
            "title": "操作",
            "name": "",
            "isHide": false,
            "value": {"label": "", "value": ""}
          });
          hobby.add(arr);
        };
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
          if (hobby == 'organizations1') {
            organizationsName1 = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                organizationsNumber1 = organizationsListObj[elementIndex][2];
              }
              elementIndex++;
            });
            print(1);
            print(organizationsNumber1);
          } else if (hobby == 'organizations2') {
            organizationsName2 = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                organizationsNumber2 = organizationsListObj[elementIndex][2];
              }
              elementIndex++;
            });
            this.getStockList();
            print(2);
            print(organizationsNumber2);
          } else {
            setState(() {
              hobby['value']['label'] = p;
            });
            var elementIndex = 0;
            print(data);
            data.forEach((element) {
              if (element == p) {
                hobby['value']['value'] = stockListObj[elementIndex][2];
                stock[9]['value']['hide'] = stockListObj[elementIndex][3];
                //hobby['value']['dimension'] = stockListObj[elementIndex][4];
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
         /* if (j == 3) {
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
          } else*/ if (j == 8) {
            comList.add(
              _item('调入仓库:', stockList, this.hobby[i][j]['value']['label'],
                  this.hobby[i][j],
                  stock: this.hobby[i]),
            );
          }else if (j == 10) {
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
                            checkItem = 'FLastQty';
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
          }else if (j == 9) {
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
                                  checkItem = 'FLoc';
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
          }else if (j == 7) {
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
                        ),
                  ),
                  divider,
                ]),
              ),
            );
          } else if (j == 13) {
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
                            new MaterialButton(
                              color: Colors.red,
                              textColor: Colors.white,
                              child: new Text('删除'),
                              onPressed: () {
                                this.hobby.removeAt(i);
                                setState(() {});
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
        SizedBox(height: 6, width: 320, child: ColoredBox(color: Colors.grey)),
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
                              keyboardType: TextInputType.text,
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
                              if(double.parse(_FNumber) <= double.parse(this.hobby[checkData][checkDataChild]["value"]['representativeQuantity'])){
                                if (this.hobby[checkData][0]['value']['kingDeeCode'].length > 0) {
                                  var kingDeeCode = this.hobby[checkData][0]['value']['kingDeeCode'][this.hobby[checkData][0]['value']['kingDeeCode'].length - 1].split("-");
                                  var realQty = 0.0;
                                  this.hobby[checkData][0]['value']['kingDeeCode'].forEach((item) {
                                    var qty = item.split("-")[1];
                                    realQty += double.parse(qty);
                                  });
                                  realQty = realQty - double.parse(this.hobby[checkData][10]
                                  ["value"]["label"]);
                                  realQty = realQty + double.parse(_FNumber);
                                  this.hobby[checkData][10]["value"]["remainder"] = (Decimal.parse(this.hobby[checkData][10]["value"]["representativeQuantity"]) - Decimal.parse(_FNumber)).toString();
                                  this.hobby[checkData][3]["value"]["value"] = realQty.toString();
                                  this.hobby[checkData][3]["value"]["label"] = realQty.toString();
                                  this.hobby[checkData][checkDataChild]["value"]["label"] = _FNumber;
                                  this.hobby[checkData][checkDataChild]['value']["value"] = _FNumber;
                                  this.hobby[checkData][0]['value']['kingDeeCode'][this.hobby[checkData][0]['value']['kingDeeCode'].length - 1] = kingDeeCode[0] + "-" + _FNumber + "-" + kingDeeCode[2];
                                } else {
                                  ToastUtil.showInfo('无条码信息，输入失败');
                                }
                              }else{
                                ToastUtil.showInfo('输入数量大于条码可用数量');
                              }
                            }else{
                              this.hobby[checkData][checkDataChild]["value"]
                              ["label"] = _FNumber;
                              this.hobby[checkData][checkDataChild]['value']
                              ["value"] = _FNumber;
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

  Widget _getModalSheetHeaderWithConfirm(String title,
      {required Function onCancel, required Function onConfirm}) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              onCancel();
            },
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
              ),
            ),
          ),
          IconButton(
              icon: Icon(
                Icons.check,
                color: Colors.blue,
              ),
              onPressed: () {
                onConfirm();
              }),
        ],
      ),
    );
  }

  Future<List<int>?> _showMultiChoiceModalBottomSheet(
      BuildContext context, List<dynamic> options) async {
    List selected = [];
    var selectList = this.hobby;
    for (var select in selectList) {
      for(var item in options){
        if (select[0]['fid'] == item[15]) {
          selected.add(item);
        } else {
          selected.remove(item);
        }
      }
    }
    print(options);
    print(selected);
    return showModalBottomSheet<List<int>?>(
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context1, setState) {
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20.0),
                topRight: const Radius.circular(20.0),
              ),
            ),
            height: MediaQuery.of(context).size.height / 2.0,
            child: Column(children: [
              _getModalSheetHeaderWithConfirm(
                '商品选择',
                onCancel: () {
                  Navigator.of(context).pop();
                },
                onConfirm: () {
                  var itemList = [];
                  for (var select in selectList) {
                    for(var item in selected){
                      print(select[0]['fid'] == item[15]);
                      if (select[0]['fid'] != item[15]) {
                        itemList.add(item);
                      }
                    }
                  }
                  if(selectList.length == 0){
                    this.getOrderList(selected);
                  }else{
                    this.getOrderList(itemList);
                  }
                  Navigator.of(context).pop();
                },
              ),
              Divider(height: 1.0),
              Expanded(
                child: ListView.builder(
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      trailing: Icon(
                          selected.contains(options[index])
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: Theme.of(context).primaryColor),
                      title: Text(options[index][1]+';仓库：'+options[index][3]+';仓位：'+(options[index][5]==null?'无':options[index][5])),
                      onTap: () {
                        setState(() {
                          if (selected.contains(options[index])) {
                            selected.remove(options[index]);
                          } else {
                            var number = 0;
                            for (var element in hobby) {
                              if (element[0]['fid'] == options[index][15]) {
                                number++;
                              }
                            }
                            if(number==0){
                              selected.add(options[index]);
                            }else{
                              ToastUtil.showInfo('商品已存在');
                            }
                          }
                          print(selected);
                        });
                      },
                    );
                  },
                  itemCount: options.length,
                ),
              ),
            ]),
          );
        });
      },
    );
  }

  //保存
  saveOrder() async {
    if (this.hobby.length > 0) {
      setState(() {
        this.isSubmit = true;
      });
      Map<String, dynamic> dataMap = Map();
      dataMap['formid'] = 'STK_TransferDirect';
      Map<String, dynamic> orderMap = Map();
      orderMap['NeedReturnFields'] = ['FBillNo'];
      orderMap['IsDeleteEntry'] = true;
      Map<String, dynamic> Model = Map();
      Model['FID'] = 0;
      Model['F_UUAC_Combo_fg2'] = "1";
      Model['FBillTypeID'] = {"FNUMBER": "ZJDB01_SYS"};
      Model['FDate'] = FDate;
      //获取登录信息
      SharedPreferences sharedPreferences =
      await SharedPreferences.getInstance();
      var menuData = sharedPreferences.getString('MenuPermissions');
      var deptData = jsonDecode(menuData)[0];
      //判断有源单 无源单
      if (this.isScanWork) {
        Model['FStockOutOrgId'] = {"FNumber": orderDate[0][8].toString()};
        Model['FStockOrgId'] = {"FNumber": orderDate[0][8].toString()};
      } else {
        Model['FStockOutOrgId'] = {"FNumber": this.organizationsNumber1};
        Model['FStockOrgId'] = {"FNumber": this.organizationsNumber2};
      }
      Model['FOwnerTypeIdHead'] = "BD_OwnerOrg";
      if(organizationsNumber1 == organizationsNumber2){
        Model['FTransferBizType'] = "InnerOrgTransfer";
      }else{
        Model['FTransferBizType'] = "OverOrgTransfer";
      }
      Model['FOwnerTypeOutIdHead'] = "BD_OwnerOrg";
      Model['FTransferDirect'] = "GENERAL";
      Model['FBizType'] = "GENERAL";
      Model['FOwnerOutIdHead'] = {"FNumber": this.organizationsNumber1};
      Model['FOwnerIdHead'] = {"FNumber": this.organizationsNumber2};
      var FEntity = [];
      var hobbyIndex = 0;
      print(materialDate);
      for (var element in this.hobby) {
        if (element[3]['value']['value'] != '0' && element[3]['value']['value'] != '' && element[7]['value']['value'] != '') {
          Map<String, dynamic> FEntityItem = Map();

          /*FEntityItem['FReturnType'] = 1;*/
          FEntityItem['FOwnerTypeId'] = "BD_OwnerOrg";
          FEntityItem['FOwnerId'] = {"FNumber": this.organizationsNumber2};
          FEntityItem['FOwnerTypeOutId'] = "BD_OwnerOrg";
          FEntityItem['FOwnerOutId'] = {"FNumber": this.organizationsNumber1};
          FEntityItem['FKeeperTypeId'] = "BD_KeeperOrg";
          FEntityItem['FKeeperId'] = {"FNumber": this.organizationsNumber2};

          FEntityItem['FMaterialId'] = {
            "FNumber": element[0]['value']['value']
          };
          FEntityItem['FKeeperTypeOutId'] = "BD_KeeperOrg";
          FEntityItem['FKeeperOutId'] = {"FNumber": this.organizationsNumber1};
          FEntityItem['FUnitID'] = {"FNumber": element[2]['value']['value']};
          FEntityItem['FBaseUnitId'] = {
            "FNumber": element[2]['value']['value']
          };
          FEntityItem['FSrcStockId'] = {
            "FNumber": element[6]['value']['value']
          };
          if (element[7]['value']['hide']) {
            Map<String, dynamic> stockMap = Map();
            stockMap['FormId'] = 'BD_STOCK';
            stockMap['FieldKeys'] =
            'FFlexNumber';
            stockMap['FilterString'] = "FNumber = '" +
                element[6]['value']['value'] +
                "'";
            Map<String, dynamic> stockDataMap = Map();
            stockDataMap['data'] = stockMap;
            String res = await CurrencyEntity.polling(stockDataMap);
            var stockRes = jsonDecode(res);
            if (stockRes.length > 0) {
              var postionList = element[7]['value']['value'].split(".");
              FEntityItem['FSrcStockLocId'] = {};
              var positonIndex = 0;
              for(var dimension in postionList){
                FEntityItem['FSrcStockLocId']["FSRCSTOCKLOCID__" + stockRes[positonIndex][0]] = {
                  "FNumber": dimension
                };
                positonIndex++;
              }
            }
          }
          FEntityItem['FDestStockId'] = {
            "FNumber": element[8]['value']['value']
          };
          if (element[9]['value']['hide']) {
            Map<String, dynamic> stockMap = Map();
            stockMap['FormId'] = 'BD_STOCK';
            stockMap['FieldKeys'] =
            'FFlexNumber';
            stockMap['FilterString'] = "FNumber = '" +
                element[8]['value']['value'] +
                "'";
            Map<String, dynamic> stockDataMap = Map();
            stockDataMap['data'] = stockMap;
            String res = await CurrencyEntity.polling(stockDataMap);
            var stockRes = jsonDecode(res);
            if (stockRes.length > 0) {
              var postionList = element[9]['value']['value'].split(".");
              FEntityItem['FDestStockLocId'] = {};
              var positonIndex = 0;
              for(var dimension in postionList){
                FEntityItem['FDestStockLocId']["FDESTSTOCKLOCID__" + stockRes[positonIndex][0]] = {
                  "FNumber": dimension
                };
                positonIndex++;
              }
            }
          }
          FEntityItem['FAuxPropID'] = {
            "FAUXPROPID__FF100002": {"FNumber": element[1]['value']['value']}
          };
          FEntityItem['FLot'] = {"FNumber": element[5]['value']['value']};
          FEntityItem['FDestLot'] = {"FNumber": element[5]['value']['value']};
          FEntityItem['FQty'] = element[3]['value']['value'];
          FEntityItem['FBaseQty'] = element[3]['value']['value'];
          FEntityItem['FProduceDate'] = element[11]['value']['value'];
          FEntityItem['FExpiryDate'] = element[12]['value']['value'];
          /*FEntityItem['FEntity_Link'] = [
            {
              "FEntity_Link_FRuleId": "DeliveryNotice-OutStock",
              "FEntity_Link_FSTableName": "T_STK_TRANSFERAPPLYENTRY",
              "FEntity_Link_FSBillId": orderDate[hobbyIndex][15],
              "FEntity_Link_FSId": orderDate[hobbyIndex][4],
              "FEntity_Link_FSALBASEQTY": element[8]['value']['value']
            }
          ];*/
          FEntity.add(FEntityItem);
        }
        hobbyIndex++;
      };
      if (FEntity.length == 0) {
        this.isSubmit = false;
        ToastUtil.showInfo('请输入数量,仓库');
        return;
      }
      Model['FBillEntry'] = FEntity;
      orderMap['Model'] = Model;
      dataMap['data'] = orderMap;
      print(jsonEncode(dataMap));
      var saveData = jsonEncode(dataMap);
      String order = await SubmitEntity.save(dataMap);
      var res = jsonDecode(order);
      print(res);
      if (res['Result']['ResponseStatus']['IsSuccess']) {
        var returnData = res['Result']['NeedReturnData'];
        Map<String, dynamic> submitMap = Map();
        submitMap = {
          "formid": "STK_TransferDirect",
          "data": {
            'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
          }
        };
        //提交
        HandlerOrder.orderHandler(context, submitMap, 1, "STK_TransferDirect",
            SubmitEntity.submit(submitMap))
            .then((submitResult) async{
          if (submitResult) {
            //审核
            /*HandlerOrder.orderHandler(context, submitMap, 1,
                "STK_TransferDirect", SubmitEntity.audit(submitMap))
                .then((auditResult) async {
              if (auditResult) {*/
                var errorMsg = "";
                if (fBarCodeList == 1) {
                  for (int i = 0; i < this.hobby.length; i++) {
                    if (this.hobby[i][3]['value']['value'] != '0') {
                      var kingDeeCode =
                      this.hobby[i][0]['value']['kingDeeCode'];
                      for (int j = 0; j < kingDeeCode.length; j++) {
                        Map<String, dynamic> dataCodeMap = Map();
                        dataCodeMap['formid'] = 'QDEP_Cust_BarCodeList';
                        Map<String, dynamic> orderCodeMap = Map();
                        orderCodeMap['NeedReturnFields'] = [];
                        orderCodeMap['IsDeleteEntry'] = false;
                        Map<String, dynamic> codeModel = Map();
                        var itemCode = kingDeeCode[j].split("-");
                        codeModel['FID'] = itemCode[0];
                        for (var j = 0; j < 2; j++) {
                          if (j == 0) {
                            /*codeModel['FLastCheckTime'] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);*/
                            Map<String, dynamic> codeFEntityItem = Map();
                            codeFEntityItem['FBillDate'] = FDate;
                            codeFEntityItem['FOutQty'] = itemCode[1];
                            codeFEntityItem['FEntryBillNo'] = returnData[0]['FBillNo'];
                            codeFEntityItem['FEntryStockID'] = {
                              "FNUMBER": this.hobby[i][6]['value']['value']
                            };
                            if (this.hobby[i][7]['value']['hide']) {
                              Map<String, dynamic> stockMap = Map();
                              stockMap['FormId'] = 'BD_STOCK';
                              stockMap['FieldKeys'] =
                              'FFlexNumber';
                              stockMap['FilterString'] = "FNumber = '" +
                                  this.hobby[i][6]['value']['value'] +
                                  "'";
                              Map<String, dynamic> stockDataMap = Map();
                              stockDataMap['data'] = stockMap;
                              String res = await CurrencyEntity.polling(stockDataMap);
                              var stockRes = jsonDecode(res);
                              if (stockRes.length > 0) {
                                var postionList = this.hobby[i][7]['value']['value'].split(".");
                                codeFEntityItem['FStockLocID'] = {};
                                var positonIndex = 0;
                                for(var dimension in postionList){
                                  codeFEntityItem['FStockLocID']["FSTOCKLOCID__" + stockRes[positonIndex][0]] = {
                                    "FNumber": dimension
                                  };
                                  positonIndex++;
                                }
                              }
                            }

                            var codeFEntity = [codeFEntityItem];
                            codeModel['FEntity'] = codeFEntity;
                            orderCodeMap['Model'] = codeModel;
                            dataCodeMap['data'] = orderCodeMap;
                            print(dataCodeMap);
                            String codeRes =
                            await SubmitEntity.save(dataCodeMap);
                            var barcodeRes = jsonDecode(codeRes);
                            if (!barcodeRes['Result']['ResponseStatus']
                            ['IsSuccess']) {
                              errorMsg += "错误反馈：" +
                                  itemCode[1] +
                                  ":" +
                                  barcodeRes['Result']['ResponseStatus']
                                  ['Errors'][0]['Message'];
                            }
                            print(codeRes);
                          } else {
                            codeModel['FOwnerID'] = {
                              "FNUMBER": this.organizationsNumber2
                            };
                            codeModel['FStockOrgID'] = {
                              "FNUMBER": this.organizationsNumber2
                            };
                            codeModel['FStockID'] = {
                              "FNUMBER": this.hobby[i][8]['value']['value']
                            };
                            /*codeModel['FLastCheckTime'] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);*/
                            Map<String, dynamic> codeFEntityItem = Map();
                            codeFEntityItem['FBillDate'] = FDate;
                            codeFEntityItem['FInQty'] = itemCode[1];
                            codeFEntityItem['FEntryBillNo'] = returnData[0]['FBillNo'];
                            //codeFEntityItem['FEntryBillNo'] = orderDate[i][0];
                            codeFEntityItem['FEntryStockID'] = {
                              "FNUMBER": this.hobby[i][8]['value']['value']
                            };
                            if (this.hobby[i][9]['value']['hide']) {
                              Map<String, dynamic> stockMap = Map();
                              stockMap['FormId'] = 'BD_STOCK';
                              stockMap['FieldKeys'] =
                              'FFlexNumber';
                              stockMap['FilterString'] = "FNumber = '" +
                                  this.hobby[i][8]['value']['value'] +
                                  "'";
                              Map<String, dynamic> stockDataMap = Map();
                              stockDataMap['data'] = stockMap;
                              String res = await CurrencyEntity.polling(stockDataMap);
                              var stockRes = jsonDecode(res);
                              if (stockRes.length > 0) {
                                var postionList = this.hobby[i][9]['value']['value'].split(".");
                                codeModel['FStockLocIDH'] = {};
                                codeFEntityItem['FStockLocID'] = {};
                                var positonIndex = 0;
                                for(var dimension in postionList){
                                  codeModel['FStockLocIDH']["FSTOCKLOCIDH__" + stockRes[positonIndex][0]] = {
                                    "FNumber": dimension
                                  };
                                  codeFEntityItem['FStockLocID']["FSTOCKLOCID__" + stockRes[positonIndex][0]] = {
                                    "FNumber": dimension
                                  };
                                  positonIndex++;
                                }
                              }
                            }
                            var codeFEntity = [codeFEntityItem];
                            codeModel['FEntity'] = codeFEntity;
                            orderCodeMap['Model'] = codeModel;
                            dataCodeMap['data'] = orderCodeMap;
                            print(dataCodeMap);
                            var paramsvalve=jsonEncode(dataCodeMap);
                            String codeRes =
                            await SubmitEntity.save(dataCodeMap);
                            var barcodeRes = jsonDecode(codeRes);
                            if (!barcodeRes['Result']['ResponseStatus']
                            ['IsSuccess']) {
                              errorMsg += "错误反馈：" +
                                  itemCode[1] +
                                  ":" +
                                  barcodeRes['Result']['ResponseStatus']
                                  ['Errors'][0]['Message'];
                            }
                            print(codeRes);
                          }
                        }
                      }
                    }
                  }
                }
                if (errorMsg != "") {
                  ToastUtil.errorDialog(context, errorMsg);
                  this.isSubmit = false;
                }
                //提交清空页面
                setState(() {
                  this.hobby = [];
                  this.orderDate = [];
                  this.FBillNo = '';
                  ToastUtil.showInfo('提交成功');
                  Navigator.of(context).pop("refresh");
                });
              /*} else {
                //失败后反审
                HandlerOrder.orderHandler(context, submitMap, 0,
                    "STK_TransferDirect", SubmitEntity.unAudit(submitMap))
                    .then((unAuditResult) {
                  if (unAuditResult) {
                    this.isSubmit = false;
                  } else {
                    this.isSubmit = false;
                  }
                });
              }
            });*/
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

  double hc_ScreenWidth() {
    return window.physicalSize.width / window.devicePixelRatio;
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
            title: Text("移库"),
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
                  /*Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text("单号：$FBillNo"),
                        ),
                      ),
                      divider,
                    ],
                  ),*/
                  /*Container(
                    height: 52.0,
                    child: new Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Row(children: [
                        Card(
                          child: new Container(
                              width: hc_ScreenWidth() - 80,
                              child: Row(
                                crossAxisAlignment:
                                CrossAxisAlignment.center,
                                children: <Widget>[
                                  SizedBox(
                                    width: 6.0,
                                  ),
                                  Icon(
                                    Icons.search,
                                    color: Colors.grey,
                                  ),
                                  Expanded(
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: TextField(
                                        controller: this.controller,
                                        decoration: new InputDecoration(
                                            contentPadding:
                                            EdgeInsets.only(
                                                bottom: 12.0),
                                            hintText: '物料编码',
                                            border: InputBorder.none),
                                        onSubmitted: (value) {
                                          setState(() {
                                            this.keyWord = value;
                                            this.getInventoryList();
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  new IconButton(
                                    icon: new Icon(Icons.cancel),
                                    color: Colors.grey,
                                    iconSize: 18.0,
                                    onPressed: () {
                                      this.controller.clear();
                                    },
                                  ),
                                ],
                              )),
                        ),
                        new SizedBox(
                          width: 60.0,
                          height: 40.0,
                          child: new RaisedButton(
                            color: Colors.lightBlueAccent,
                            child: new Text('搜索',style: TextStyle(fontSize: 14.0, color: Colors.white)),
                            onPressed: (){
                              setState(() {
                                this.keyWord = this.controller.text;
                                this.getInventoryList();
                              });
                            },
                          ),
                        ),
                      ]),
                    ),
                  ),*/
                  _dateItem('日期：', DateMode.YMD),
                  /*_item('调出组织', this.organizationsList, this.organizationsName1,
                      'organizations1'),*/
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text("调出组织：$organizationsName1"),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  _item('调入组织', this.organizationsList, this.organizationsName2,
                      'organizations2'),
                  Column(
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
                                    selection: TextSelection.fromPosition(
                                        TextPosition(
                                            affinity: TextAffinity.downstream,
                                            offset: value.length)));
                              });
                            },
                          ),
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
