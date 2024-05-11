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

class PickingDetail extends StatefulWidget {
  var FBillNo;
  var FSeq;
  var FEntryId;
  var FID;
  var FProdOrder;
  var FBarcode;
  var FMemoItem;

  PickingDetail(
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
  _PickingDetailState createState() => _PickingDetailState(
      FBillNo, FSeq, FEntryId, FID, FProdOrder, FBarcode, FMemoItem);
}

class _PickingDetailState extends State<PickingDetail> {
  GlobalKey<TextWidgetState> textKey = GlobalKey();
  GlobalKey<TextWidgetState> FBillNoKey = GlobalKey();
  GlobalKey<TextWidgetState> FSaleOrderNoKey = GlobalKey();
  GlobalKey<PartRefreshWidgetState> globalKey = GlobalKey();
  GlobalKey<PartRefreshWidgetState> FPrdOrgIdKey = GlobalKey();

  final _textNumber = TextEditingController();
  var checkItem;
  var FBillNo = '';
  var FSaleOrderNo = '';
  var FName = '';
  var FNumber = '';
  var FDate = '';
  var FStockOrgId = '';
  var FPrdOrgId = '';
  var show = false;
  var isSubmit = false;
  var isSubmitT = false;
  var isScanWork = false;
  var checkData;
  var checkDataChild;
  var fBarCodeList;
  var selectData = {
    DateMode.YMD: "",
  };
  var stockList = [];
  List<dynamic> stockListObj = [];
  var fotList = [];
  List<dynamic> fotListObj = [];
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
  StreamSubscription? _subscription;
  var _code;
  var _FNumber;
  var FSeq;
  var fBillNo;
  var fEntryId;
  var fid;
  var FProdOrder;
  var FMemoItem;
  var FBarcode;
  var fOrgID;

  _PickingDetailState(
      fBillNo, FSeq, fEntryId, fid, FProdOrder, FBarcode, FMemoItem) {
    this.fBillNo = fBillNo['value'];
    this.FSeq = FSeq['value'];
    this.fEntryId = fEntryId['value'];
    this.fid = fid['value'];
    this.FProdOrder = FProdOrder['value'];
    this.FBarcode = FBarcode;
    this.FMemoItem = FMemoItem['value'];
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
    if (fOrgID == null) {
      this.fOrgID = deptData[1];
    }
    userMap['FilterString'] =
        "FForbidStatus = 'A'  and FUseOrgId.FNumber ='" + fOrgID + "'";
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    stockListObj = jsonDecode(res);
    stockListObj.forEach((element) {
      stockList.add(element[1]);
    });
  }

  // 查询数据集合
  List hobby = [];
  List fNumber = [];

  //获取订单信息
  getOrderList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FilterString'] =
        "FNoPickedQty>0 and FMOBillNO='$fBillNo' and FMOEntrySeq = '$FSeq'";
    userMap['FormId'] = 'PRD_PPBOM';
    userMap['OrderString'] = 'FMaterialId.FNumber ASC';
    userMap['FieldKeys'] =
        'FBillNo,FPrdOrgId.FNumber,FPrdOrgId.FName,FMOBillNO,FMOEntrySeq,FEntity_FEntryId,FEntity_FSeq,FMaterialID2.FNumber,FMaterialID2.FName,FMaterialID2.FSpecification,FUnitID2.FNumber,FUnitID2.FName,FNoPickedQty,FID,FLot.FNumber,FMaterialID2.FIsBatchManage';
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
      FPrdOrgId = orderDate[0][1].toString();
      this.fOrgID = orderDate[0][1];
      //下推
      Map<String, dynamic> pushMap = Map();
      pushMap['Ids'] = orderDate[0][13];
      pushMap['RuleId'] = "PRD_PPBOM2PICKMTRL_NORMAL";
      var entryId = [];
      var hobbyIndex = 0;
      this.hobby.forEach((element) {
        if (element[3]['value']['value'] != '0') {
          entryId.add(orderDate[hobbyIndex][5]);
        }
        hobbyIndex++;
      });
      pushMap['EntryIds'] = entryId;
      pushMap['TargetFormId'] = "PRD_PickMtrl";
      print(pushMap);
      var datass = pushMap.toString();
      var downData =
      await SubmitEntity.pushDown({"formid": "PRD_PPBOM", "data": pushMap});
      print(downData);
      var res = jsonDecode(downData);
      //判断成功
      if (res['Result']['ResponseStatus']['IsSuccess']) {
        //查询生产领料
        var entitysNumber =
        res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id'];
        Map<String, dynamic> OrderMap = Map();
        OrderMap['FormId'] = 'PRD_PickMtrl';
        OrderMap['FilterString'] =
        "FID='$entitysNumber' ";//and FLot.FNumber != ''
        OrderMap['FieldKeys'] =
        'FBillNo,FPrdOrgId.FNumber,FPrdOrgId.FName,FMOBillNO,FMOEntrySeq,FEntity_FEntryId,FEntity_FSeq,FMaterialId.FNumber,FMaterialId.FName,FMaterialId.FSpecification,FUnitID.FNumber,FUnitID.FName,FAppQty,FLot.FNumber,FID,FMaterialId.FIsBatchManage,FAUXPROPID.FF100002.FNumber,FOwnerId.FNumber,FParentOwnerId.FNumber,FBaseUnitId.FNumber,FStockUnitId.FNumber,FOwnerTypeId,FParentOwnerTypeId,FKeeperTypeId,FKeeperId.FNumber,FParentMaterialId.FNumber,FMoEntryId,FPPBomEntryId,FEntryWorkShopId.FNumber';
        String order = await CurrencyEntity.polling({'data': OrderMap});
        this.getOrderListT(order);
      } else {
        setState(() {
          this.isSubmitT = false;
          if(res['Result']['ResponseStatus']['Errors'][0]['Message']=="分录实体“明细”是必填项"){
            ToastUtil.errorDialog(context, "默认发料仓库异常");
          }else{
            ToastUtil.errorDialog(
                context, res['Result']['ResponseStatus']['Errors'][0]['Message']);
          }
        });
      }
      /*FStockOrgId = orderDate[0][1].toString();
      FPrdOrgId = orderDate[0][1].toString();
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
          "value": {"label": "", "value": ""}
        });
        arr.add({
          "title": "未领数量",
          "name": "FPrdOrgId",
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
      });*/
      setState(() {
        EasyLoading.dismiss();
        this._getHobby();
      });
    } else {
      setState(() {
        EasyLoading.dismiss();
        this._getHobby();
      });
      ToastUtil.showInfo('已领料');
    }
    getStockList();
    /* _onEvent("247230329291267");*/
  }
  getOrderListT(order) async {
    orderDate = [];
    orderDate = jsonDecode(order);
    hobby = [];
    if (orderDate.length > 0) {
      for (var value in orderDate) {
      //orderDate.forEach((value) {
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
          "title": "包装规格",
          "isHide": true,
          "name": "FMaterialIdFSpecification",
          "value": {"label": value[16]==null?"":value[16], "value": value[16]==null?"":value[16]}
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
        /*Map<String, dynamic> inventoryMap = Map();
        inventoryMap['FormId'] = 'STK_Inventory';
        inventoryMap['FilterString'] = "FMaterialId.FNumber='" + value[2] + "' and FBaseQty >0";
        inventoryMap['Limit'] = '50';
        inventoryMap['OrderString'] = 'FLot.FNumber DESC, FProduceDate DESC';
        inventoryMap['FieldKeys'] =
        'FMaterialId.FNumber,F_UUAC_BaseProperty,FMaterialId.FSpecification,FStockId.FName,FBaseQty,FLot.FNumber,FAuxPropId.FF100002.FNumber';
        Map<String, dynamic> inventoryDataMap = Map();
        inventoryDataMap['data'] = inventoryMap;
        String res = await CurrencyEntity.polling(inventoryDataMap);
        var stocks = jsonDecode(res);
        if (stocks.length > 0) {
          arr.add({
            "title": "批号",
            "name": "FLot",
            "isHide": value[15] != true,
            "value": {"label": value[13], "value": value[13],"fLotList": stocks}
          });
        }else{
          arr.add({
            "title": "批号",
            "name": "FLot",
            "isHide": value[15] != true,
            "value": {"label": value[13], "value": value[13],"fLotList": []}
          });
        }*/
        arr.add({
          "title": "批号",
          "name": "",
          "isHide": true,
          "value": {"label": value[13], "value": value[13]}
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
          "value": {"label": "", "value": ""}
        });
        arr.add({
          "title": "用量",
          "name": "FPrdOrgId",
          "isHide": false,
          "value": {"label": value[12], "value": value[12]}
        });
        arr.add({
          "title": "最后扫描数量",
          "name": "FLastQty",
          "isHide": false,
          "value": {"label": "0", "value": "0"}
        });
        arr.add({
          "title": "包装数量",
          "name": "",
          "isHide": false,
          "value": {"label": "", "value": ""}
        });
        arr.add({
          "title": "包数",
          "name": "",
          "isHide": false,
          "value": {"label": "", "value": ""}
        });
        arr.add({
          "title": "明细",
          "name": "",
          "isHide": false,
          "value": {"label": "", "value": "", "itemList": []}
        });
        hobby.add(arr);
      };
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
    /* _onEvent("247230329291267");*/
  }

  void _onEvent(event) async {
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
      'FID,FInQtyTotal,FOutQtyTotal,FEntity_FEntryId,FRemainQty,FBarCodeQty,FStockID.FName,FStockID.FNumber,FMATERIALID.FNUMBER,FOwnerID.FNumber,FBarCode,FSN,FBatchNo,FPackageSpec';
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
            print(value[7]);
            print(barcodeData[0][8]);
            if (value[7] == barcodeData[0][8]) {
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
            /*Map<String, dynamic> stockMap = Map();
            stockMap['FilterString'] = "FMaterialId.FNumber='" + barcodeData[0][8]+
                "' and FBaseQty >0 and FLot.FNumber= '"+barcodeData[0][12]+"'"; *//**//*
            stockMap['FormId'] = 'STK_Inventory';
            stockMap['Limit'] = '1';
            stockMap['OrderString'] = 'FLot.FNumber DESC, FProduceDate DESC';
            stockMap['FieldKeys'] =
            'FAuxPropId.FF100002.FNumber';
            Map<String, dynamic> dataStockMap = Map();
            dataStockMap['data'] = stockMap;
            String stockOrder = await CurrencyEntity.polling(dataStockMap);*/
            this.getMaterialList(
                barcodeData, barcodeData[0][10], barcodeData[0][11],barcodeData[0][13]);//jsonDecode(stockOrder)[0][0]
            print("ChannelPage: $event");
          } else {
            ToastUtil.showInfo(msg);
          }
        } else {
          ToastUtil.showInfo('该条码已出库或没入库，数量为零');
        }
      } else {
        ToastUtil.showInfo('条码不在条码清单中');
      }
    } else {
      _code = event;
      this.getMaterialList("", _code, '', '');
      print("ChannelPage: $event");
    }
    print("ChannelPage: $event");
  }

  getMaterialList(barcodeData, code, fsn,fAuxPropId) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    var scanCode = code.split(";");
    userMap['FilterString'] = "FNumber='" +
        scanCode[0] +
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
          if (element[0]['value']['value'] == scanCode[0]) {
            if (element[0]['value']['barcode'].indexOf(code) == -1) {
              //判断是否可重复扫码
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
                  //仓库
                  element[4]['value']['label'] = barcodeData[0][6].toString();
                  element[4]['value']['value'] = barcodeData[0][7].toString();
                  var childList = fAuxPropId == null?  scanCode[1].toString() +"-"+ element[10]['value']['value'] :scanCode[1].toString() +"-"+ element[10]['value']['value']+"-"+fAuxPropId;
                  element[13]['value']['itemList'].add(childList);
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
                /*if (fNumber.indexOf(element[0]['value']['value']) ==
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
                    //仓库
                    element[4]['value']['label'] = barcodeData[0][6].toString();
                    element[4]['value']['value'] = barcodeData[0][7].toString();
                    barcodeNum =
                        (double.parse(barcodeNum) - double.parse(barcodeNum))
                            .toString();
                    print(2);
                    print(element[0]['value']['kingDeeCode']);
                  }
                } else {*/
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
                        //仓库
                        element[4]['value']['label'] = barcodeData[0][6].toString();
                        element[4]['value']['value'] = barcodeData[0][7].toString();
                        print(1);
                        var childList = fAuxPropId == null?  scanCode[1].toString() +"-"+ element[10]['value']['value'] :scanCode[1].toString() +"-"+ element[10]['value']['value']+"-"+fAuxPropId;
                        element[13]['value']['itemList'].add(childList);
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
                        //仓库
                        element[4]['value']['label'] = barcodeData[0][6].toString();
                        element[4]['value']['value'] = barcodeData[0][7].toString();
                        barcodeNum = (double.parse(barcodeNum) -
                                double.parse(barcodeNum))
                            .toString();
                        print(2);
                        var childList = fAuxPropId == null?  scanCode[1].toString() +"-"+ element[10]['value']['value'] :scanCode[1].toString() +"-"+ element[10]['value']['value']+"-"+fAuxPropId;
                        element[13]['value']['itemList'].add(childList);
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
          if (element[0]['value']['value'] == scanCode[0]) {
            if (element[0]['value']['barcode'].indexOf(code) == -1) {
              //判断是否可重复扫码
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
                  //仓库
                  element[4]['value']['label'] = barcodeData[0][6].toString();
                  element[4]['value']['value'] = barcodeData[0][7].toString();
                  barcodeNum =
                      (double.parse(barcodeNum) - double.parse(barcodeNum))
                          .toString();
                }
                break;
              }
              if (element[5]['value']['value'] == scanCode[1]) {
                //判断条码数量
                if ((double.parse(element[3]['value']['label']) + double.parse(barcodeNum)) > 0 && double.parse(barcodeNum) > 0) {
                  //判断物料是否重复 首个下标是否对应末尾下标
                  /*if (fNumber.indexOf(element[0]['value']['value']) == fNumber.lastIndexOf(element[0]['value']['value'])) {
                    if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                      element[3]['value']['label'] = (double.parse(element[3]['value']['label']) + double.parse(barcodeNum)).toString();
                      element[3]['value']['value'] = element[3]['value']['label'];
                      var item = barCodeScan[0].toString() +
                          "-" +
                          barcodeNum +
                          "-" +
                          fsn;
                      element[10]['value']['label'] = barcodeNum.toString();
                      element[10]['value']['value'] = barcodeNum.toString();
                      //仓库
                      element[4]['value']['label'] = barcodeData[0][6].toString();
                      element[4]['value']['value'] = barcodeData[0][7].toString();
                      element[0]['value']['kingDeeCode'].add(item);
                      element[0]['value']['scanCode'].add(code);
                      barcodeNum =
                          (double.parse(barcodeNum) - double.parse(barcodeNum))
                              .toString();
                      print(2);
                      print(element[0]['value']['kingDeeCode']);
                    }
                  } else {*/
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
                          //仓库
                          element[4]['value']['label'] = barcodeData[0][6].toString();
                          element[4]['value']['value'] = barcodeData[0][7].toString();
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
                          //仓库
                          element[4]['value']['label'] = barcodeData[0][6].toString();
                          element[4]['value']['value'] = barcodeData[0][7].toString();
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
                  if ((double.parse(element[3]['value']['label']) +
                              double.parse(barcodeNum)) >
                          0 &&
                      double.parse(barcodeNum) > 0) {
                    //判断物料是否重复 首个下标是否对应末尾下标
                    /*if (fNumber.indexOf(element[0]['value']['value']) ==
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
                        //仓库
                        element[4]['value']['label'] = barcodeData[0][6].toString();
                        element[4]['value']['value'] = barcodeData[0][7].toString();
                        barcodeNum = (double.parse(barcodeNum) -
                                double.parse(barcodeNum))
                            .toString();
                        print(2);
                        print(element[0]['value']['kingDeeCode']);
                      }
                    } else {*/
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
                            //仓库
                            element[4]['value']['label'] = barcodeData[0][6].toString();
                            element[4]['value']['value'] = barcodeData[0][7].toString();
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
                            //仓库
                            element[4]['value']['label'] = barcodeData[0][6].toString();
                            element[4]['value']['value'] = barcodeData[0][7].toString();
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

    userMap['FilterString'] = "F_UYEP_GYSTM='" +
        code.split('-')[0] +
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
    var scanCode = [materialDate[0][2], code.split("-")[1], "", "", "", "N"];
    if (materialDate.length > 0) {
      var msg = "";
      var orderIndex = 0;
      for (var value in orderDate) {
        if (value[7] == materialDate[0][2]) {
          msg = "";
          if (fNumber.lastIndexOf(materialDate[0][2]) == orderIndex) {
            break;
          }
        } else {
          msg = '条码不在单据物料中';
        }
        orderIndex++;
      }
      ;
      if (msg != "") {
        ToastUtil.showInfo(msg);
        return;
      }
      var number = 0;
      var barcodeNum = '1';
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
                  element[0]['value']['scanCode'].add(code);
                  element[0]['value']['kingDeeCode'].add(fsn);
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
                      element[0]['value']['scanCode'].add(code);
                      element[0]['value']['kingDeeCode'].add(fsn);
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
                      element[10]['value']['label'] = barcodeNum.toString();
                      element[10]['value']['value'] = barcodeNum.toString();
                      element[0]['value']['scanCode'].add(code);
                      element[0]['value']['kingDeeCode'].add(fsn);
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
                  element[0]['value']['scanCode'].add(code);
                  element[0]['value']['kingDeeCode'].add(fsn);
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
                        element[0]['value']['scanCode'].add(code);
                        element[0]['value']['kingDeeCode'].add(fsn);
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
                        element[10]['value']['label'] = barcodeNum.toString();
                        element[10]['value']['value'] = barcodeNum.toString();
                        element[0]['value']['scanCode'].add(code);
                        element[0]['value']['kingDeeCode'].add(fsn);
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
                          element[0]['value']['scanCode'].add(code);
                          element[0]['value']['kingDeeCode'].add(fsn);
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
                          element[10]['value']['label'] = barcodeNum.toString();
                          element[10]['value']['value'] = barcodeNum.toString();
                          element[0]['value']['scanCode'].add(code);
                          element[0]['value']['kingDeeCode'].add(fsn);
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

    userMap['FilterString'] = "F_UYEP_GYSTM='" +
        code.substring(0, 3) +
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
    var scanCode = [materialDate[0][2], code.substring(3, 9), "", "", "", "N"];
    if (materialDate.length > 0) {
      var msg = "";
      var orderIndex = 0;
      for (var value in orderDate) {
        if (value[7] == materialDate[0][2]) {
          msg = "";
          if (fNumber.lastIndexOf(materialDate[0][2]) == orderIndex) {
            break;
          }
        } else {
          msg = '条码不在单据物料中';
        }
        orderIndex++;
      }
      ;
      if (msg != "") {
        ToastUtil.showInfo(msg);
        return;
      }
      var number = 0;
      var barcodeNum = '1';
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
                  element[0]['value']['scanCode'].add(code);
                  element[0]['value']['kingDeeCode'].add(fsn);
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
                      element[0]['value']['scanCode'].add(code);
                      element[0]['value']['kingDeeCode'].add(fsn);
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
                      element[10]['value']['label'] = barcodeNum.toString();
                      element[10]['value']['value'] = barcodeNum.toString();
                      element[0]['value']['scanCode'].add(code);
                      element[0]['value']['kingDeeCode'].add(fsn);
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
                  element[0]['value']['scanCode'].add(code);
                  element[0]['value']['kingDeeCode'].add(fsn);
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
                        element[0]['value']['scanCode'].add(code);
                        element[0]['value']['kingDeeCode'].add(fsn);
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
                        element[10]['value']['label'] = barcodeNum.toString();
                        element[10]['value']['value'] = barcodeNum.toString();
                        element[0]['value']['scanCode'].add(code);
                        element[0]['value']['kingDeeCode'].add(fsn);
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
                          element[0]['value']['scanCode'].add(code);
                          element[0]['value']['kingDeeCode'].add(fsn);
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
                          element[10]['value']['label'] = barcodeNum.toString();
                          element[10]['value']['value'] = barcodeNum.toString();
                          element[0]['value']['scanCode'].add(code);
                          element[0]['value']['kingDeeCode'].add(fsn);
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
        for (var i = 0; i < data.length; i++) {
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
                            if(checkItem=="bagNum"){
                              if(this.hobby[checkData][3]['value'] != '0'){
                                var realQty = 0.0;
                                realQty = double.parse(this.hobby[checkData][3]["value"]["label"]) / double.parse(_FNumber);
                                this.hobby[checkData][12]["value"]["value"] = realQty.toString();
                                this.hobby[checkData][12]["value"]["label"] = realQty.toString();
                                this.hobby[checkData][checkDataChild]["value"]
                                ["label"] = _FNumber;
                                this.hobby[checkData][checkDataChild]['value']
                                ["value"] = _FNumber;
                              }else{
                                ToastUtil.showInfo('请输入领料数量');
                              }
                            }
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
  Future<List<int>?> _showModalBottomSheet(
      BuildContext context, List<dynamic> options, Map<dynamic,dynamic> dataItem) async {
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
                topLeft: const Radius.circular(10.0),
                topRight: const Radius.circular(10.0),
              ),
            ),
            height: MediaQuery.of(context).size.height / 2.0,
            child: Column(children: [
              Expanded(
                child: ListView.builder(
                  itemBuilder: (BuildContext context, int index) {
                    return Column(
                      children: <Widget>[
                        ListTile(
                          title: Text('批号:'+options[index][5]+';包装规格:'+options[index][6]),//+';仓库:'+options[index][3]+';数量:'+options[index][4].toString()+';包装规格:'+options[index][6]
                          onTap: () {
                            setState(() {
                              dataItem['value'] = options[index][5];
                              dataItem['label'] = options[index][5];
                            });
                            print(options[index]);
                            // Do something
                            Navigator.pop(context);
                          },
                        ),
                        Divider(height: 1.0),
                      ],
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
  List<Widget> _getHobby() {
    List<Widget> tempList = [];
    for (int i = 0; i < this.hobby.length; i++) {
      List<Widget> comList = [];
      for (int j = 0; j < this.hobby[i].length; j++) {
        if (!this.hobby[i][j]['isHide']) {
          /*if (j == 5) {
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
                                this._textNumber.text = this
                                    .hobby[i][j]["value"]["label"]
                                    .toString();
                                this._FNumber = this
                                    .hobby[i][j]["value"]["label"]
                                    .toString();
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
          } else*/ if (j == 4) {
            comList.add(
              _item('仓库:', stockList, this.hobby[i][j]['value']['label'],
                  this.hobby[i][j],
                  stock: this.hobby[i]),
            );
          } else if ( j == 11) {
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
                            checkItem = 'bagNum';
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
          }else if ( j == 13) {
            var itemList = this.hobby[i][j]["value"]['itemList'];
            List<Widget> listTitle = [];
            var listTitleNum = 1;
            for(var dataItem in itemList){
              listTitle.add(
                ListTile(
                  title: Text(listTitleNum.toString() +
                      '：' +
                      dataItem),
                  trailing:
                  Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                    /* MyText(orderDate[i][j],
                        color: Colors.grey, rightpadding: 18),*/
                  ]),
                ),
              );
              listTitleNum++;
            }
            comList.add(
              Column(children: [
                ExpansionTile(
                  title: Text('明细'),
                  children: listTitle,
                ),
                divider,
              ]),
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
      for (var i = serialNum; i <= 4; i++) {
        //查询生产订单
        Map<String, dynamic> userMap = Map();
        userMap['FilterString'] =
            "FSaleOrderNo='$FBarcode' and FProdOrder >= " +
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
          break;
        }
      }
      //查询生产订单
      Map<String, dynamic> userMap = Map();
      userMap['FilterString'] = "FSaleOrderNo='$FBarcode' and FProdOrder >= " +
          (serialNum + 1).toString() +
          " and FProdOrder <" +
          (serialNum + 2).toString();
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
  deleteOrder(Map<String, dynamic> map, title,{var type = 0}) async {
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
          if(type == 1){
            setState(() {
              EasyLoading.dismiss();
            });

          }else{
            setState(() {
              this.isSubmit = false;
              ToastUtil.errorDialog(context, title);
            });
          }
        } else {
          if(type == 1){
            setState(() {
              EasyLoading.dismiss();
              ToastUtil.errorDialog(context,
                  res['Result']['ResponseStatus']['Errors'][0]['Message']);
            });

          }else{
            setState(() {
              this.isSubmit = false;
              ToastUtil.errorDialog(context,
                  res['Result']['ResponseStatus']['Errors'][0]['Message']);
            });
          }
        }
      }
    }
  }

  //反审核
  unAuditOrder(Map<String, dynamic> map, title) async {
    var subData = await SubmitEntity.unAudit(map);
    print(subData);
    if (subData != null) {
      var res = jsonDecode(subData);
      if (res != null) {
        if (res['Result']['ResponseStatus']['IsSuccess']) {
          //提交清空页面
          Map<String, dynamic> deleteMap = Map();
          deleteMap = {
            "formid": "PRD_PickMtrl",
            "data": {
              'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
            }
          };
          setState(() {
            this.isSubmit = false;
            ToastUtil.errorDialog(context, title);
          });
          //deleteOrder(deleteMap, title);

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
          /*var errorMsg = "";
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
          }*/
          //提交清空页面
          /*handlerStatus();*/
          this.hobby = [];
          this.orderDate = [];
          this.FBillNo = '';
          ToastUtil.showInfo('提交成功');
          Navigator.of(context).pop("refresh");
        } else {
          unAuditOrder(auditMap,
              res['Result']['ResponseStatus']['Errors'][0]['Message']);
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
            "formid": "PRD_PickMtrl",
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
    dataMap['formid'] = 'PRD_PickMtrl';
    Map<String, dynamic> orderMap = Map();
    orderMap['NeedUpDataFields'] = [
      'FEntity',
      'FSerialSubEntity',
      'FSerialNo',
      'FSNQty'
    ];
    orderMap['NeedReturnFields'] = ['FEntity', 'FSerialSubEntity', 'FSerialNo'];
    orderMap['IsDeleteEntry'] = true;
    Map<String, dynamic> Model = Map();
    Model['FID'] = orderDate[0][14];
    Model['F_UYEP_TEXT'] = "PDA-";
   /* var orderData = [];
    var orderDataList = [];
    for (var item in collarOrderDate) {
      if (orderData.indexOf(item[3]) == -1) {
        orderData.add(item[3]);
        orderDataList.add(item);
      }
    }
    print(orderData);*/
    var FEntity = [];
    var hobbyIndex = 0;
    for (var element in this.hobby) {
  /*    for (var collarOrder in orderDataList) {
        if (collarOrder[3] == element[0]['value']['value']) {*/
          if (element[3]['value']['value'] != '0') {
            var itemList = element[13]['value']['itemList'];
            var itemNumber = 1;
            for (var childItem in itemList) {
              Map<String, dynamic> FEntityItem = Map();
              if(itemNumber == 1){
                FEntityItem['FEntryID'] = orderDate[hobbyIndex][5];
              }else{
                //FEntityItem['FEntryID'] = 0;
                FEntityItem['FParentMaterialId'] = {"FNumber": orderDate[hobbyIndex][25]};
                FEntityItem['FEntryWorkShopId'] = {"FNumber": orderDate[hobbyIndex][28]};
                FEntityItem['FMoEntryId'] = orderDate[hobbyIndex][26];
                FEntityItem['FPPBomEntryId'] = orderDate[hobbyIndex][27];
                FEntityItem['FMaterialId'] = {"FNumber": element[0]['value']['value']};
                FEntityItem['FOwnerId'] = {"FNumber": orderDate[hobbyIndex][17]};
                FEntityItem['FParentOwnerId'] = {"FNumber": orderDate[hobbyIndex][18]};
                FEntityItem['FUnitID'] = {"FNumber": orderDate[hobbyIndex][10]};
                FEntityItem['FBaseUnitId'] = {"FNumber": orderDate[hobbyIndex][19]};
                FEntityItem['FStockUnitId'] = {"FNumber": orderDate[hobbyIndex][20]};
                FEntityItem['FStockStatusId'] = {"FNumber": "KCZT01_SYS"};
                FEntityItem['FOwnerTypeId'] = orderDate[hobbyIndex][21];
                FEntityItem['FMoBillNo'] =  orderDate[hobbyIndex][3];
                FEntityItem['FKeeperTypeId'] = orderDate[hobbyIndex][23];
                FEntityItem['FParentOwnerTypeId'] = orderDate[hobbyIndex][22];
                FEntityItem['FKeeperId'] = {"FNumber": orderDate[hobbyIndex][24]};
              }
              var childDetail = childItem.split('-');
              FEntityItem['FActualQty'] = childDetail[1];
              FEntityItem['FSNQty'] = childDetail[1];
              FEntityItem['FStockId'] = {"FNumber": element[4]['value']['value']};
              FEntityItem['FLot'] = {"FNumber": childDetail[0]};
              FEntityItem['FAuxPropId'] = {
                "FAUXPROPID__FF100002": {"FNumber": childDetail[2]}
              };
              FEntity.add(FEntityItem);
              itemNumber++;
            } /*
            Map<String, dynamic> FEntityItem = Map();
            FEntityItem['FEntryID'] = orderDate[hobbyIndex][5];
            FEntityItem['FActualQty'] = element[3]['value']['value'];
            FEntityItem['FSNQty'] = element[3]['value']['value'];

            FEntityItem['FStockId'] = {"FNumber": element[4]['value']['value']};
            FEntityItem['FLot'] = {"FNumber": element[5]['value']['value']};
            FEntityItem['FAuxPropId'] = {
              "FAUXPROPID__FF100002": {"FNumber": element[1]['value']['value']}
            };
           var fSerialSub = [];
            var kingDeeCode = element[0]['value']['kingDeeCode'];
            for (int subj = 0; subj < kingDeeCode.length; subj++) {
              Map<String, dynamic> subObj = Map();
              if (kingDeeCode[subj].split("-").length > 2) {
                var itemCode = kingDeeCode[subj].split("-");
                if(itemCode.length>2){
                  if(itemCode.length > 3){
                    subObj['FSerialNo'] = itemCode[2]+'-'+itemCode[3];
                  }else{
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

            */

          }
       /* }*/
      /*}*/
      hobbyIndex++;
    };
    if (FEntity.length == 0) {
      this.isSubmit = false;
      ToastUtil.showInfo('请输入数量和录入仓库');
      return;
    }
    Model['FEntity'] = FEntity;
    orderMap['Model'] = Model;
    dataMap['data'] = orderMap;
    var dataParams = jsonEncode(dataMap);
    String order = await SubmitEntity.save(dataMap);
    var res = jsonDecode(order);
    print(res);
    if (res['Result']['ResponseStatus']['IsSuccess']) {
      Map<String, dynamic> submitMap = Map();
      submitMap = {
        "formid": "PRD_PickMtrl",
        "data": {
          'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
        }
      };
      submitOrder(submitMap);
    } else {
      /*Map<String, dynamic> deleteMap = Map();
      deleteMap = {
        "formid": "PRD_PickMtrl",
        "data": {'Ids': collarOrderDate[0][0]}
      };
      deleteOrder(
          deleteMap,
          res['Result']['ResponseStatus']['Errors'][0]['Message'] +
              ':(该物料无库存或库存状态不可用！)');*/
       setState(() {
        this.isSubmit = false;
        ToastUtil.errorDialog(context,
            res['Result']['ResponseStatus']['Errors'][0]['Message']);
      });
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
      pushMap['RuleId'] = "PDA_PRD_PPBOM2PICKMTRL_NORMAL";
      var entryId = [];
      var hobbyIndex = 0;
      this.hobby.forEach((element) {
        if (element[3]['value']['value'] != '0') {
          entryId.add(orderDate[hobbyIndex][5]);
        }
        hobbyIndex++;
      });
      pushMap['EntryIds'] = entryId;
      pushMap['TargetFormId'] = "PRD_PickMtrl";
      print(pushMap);
      var datass = jsonEncode(pushMap);
      var downData =
          await SubmitEntity.pushDown({"formid": "PRD_PPBOM", "data": pushMap});
      print(downData);
      var res = jsonDecode(downData);
      //判断成功
      if (res['Result']['ResponseStatus']['IsSuccess']) {
        //查询生产领料
        var entitysNumber =
            res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id'];
        Map<String, dynamic> OrderMap = Map();
        OrderMap['FormId'] = 'PRD_PickMtrl';
        OrderMap['FilterString'] =
            "FID='$entitysNumber' and FLot.FNumber != ''";
        OrderMap['FieldKeys'] =
            'FID,FEntity_FEntryId,FStockId.FNumber,FMaterialId.FNumber';
        String order = await CurrencyEntity.polling({'data': OrderMap});
        var resData = jsonDecode(order);
        collarOrderDate = resData;
        saveOrder();
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
            title: Text("领料"),
            centerTitle: true,
            leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () async {
                  if(this.fBillNo != null && this.hobby.length>0){
                    Map<String, dynamic> deleteMap = Map();
                    deleteMap = {
                      "formid": 'PRD_PickMtrl',
                      "data": {
                        'Ids': orderDate[0][14]
                      }
                    };
                    EasyLoading.show(status: '删除下推单据...');
                    await deleteOrder(deleteMap, '删除', type: 1);
                    Navigator.of(context).pop("refresh");
                  }else{
                    Navigator.of(context).pop("refresh");
                  }
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
                  Column(
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
                  /* _item('仓库:', stockList, selectStock),*/
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
              ),
            ],
          )),
    );
  }
}
