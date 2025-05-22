import 'dart:convert';
import 'package:decimal/decimal.dart';
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
  //包装规格
  var bagList = [];
  List<dynamic> bagListObj = [];
  var stockList = [];
  var hobbyItem = [];
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
  final controller = TextEditingController();
  List<TextEditingController> _textNumber2 = [];
  List<TextEditingController> _textNumber3 = [];
  List<FocusNode> focusNodes = [];
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
    getBagList();
    /* getWorkShop();*/
  }
  void _setupListener(int index) {
    focusNodes[index].addListener(() {
      if (!focusNodes[index].hasFocus) { // 检查是否失去焦点
        print(_textNumber3[index].text[_textNumber3[index].text.length - 1]==".");
        if(_textNumber3[index].text[_textNumber3[index].text.length - 1]=="."){
          _textNumber3[index].text = _textNumber3[index].text + "0";
        }
      }
    });
  }
  //获取包装规格
  getBagList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BOS_ASSISTANTDATA_DETAIL';
    userMap['FieldKeys'] = 'FNumber,FDataValue,FId';
    userMap['FilterString'] = [{"Left":"(","FieldName":"FId","Compare":"67","Value":"64746193a3e99b","Right":")","Logic":"0"}];
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    bagListObj = jsonDecode(res);
    bagListObj.forEach((element) {
      bagList.add(element[1]);
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
    // 释放所有 Controller 和 FocusNode
    for (var controller in _textNumber2) {
      controller.dispose();
    }
    for (var controller in _textNumber3) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();

    /// 取消监听
    if (_subscription != null) {
      _subscription!.cancel();
    }
  }
  //获取仓库
  getStockList() async {
    stockListObj = [];
    stockList = [];
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BD_STOCK';
    userMap['FieldKeys'] = 'FStockID,FName,FNumber,FIsOpenLocation';
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var tissue = sharedPreferences.getString('tissue');
    if (fOrgID == null) {
      this.fOrgID = tissue;
    }
    userMap['FilterString'] =
        "FForbidStatus = 'A' and FDocumentStatus = 'C' and FUseOrgId.FNumber ='" + fOrgID + "'";
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    var initial = jsonDecode(res);
    var fStockIds = jsonDecode(sharedPreferences.getString('FStockIds')).split(',');
    if(jsonDecode(sharedPreferences.getString('FStockIds')) != ''){
      fStockIds.forEach((item){
        if(initial.indexWhere((v)=> v[0].toString() == item) != -1){
          stockList.add(initial[initial.indexWhere((v)=> v[0].toString() == item)][1]);
          stockListObj.add(initial[initial.indexWhere((v)=> v[0].toString() == item)]);
        }
      });
    }else{
      initial.forEach((element) {
        stockList.add(element[1]);
      });
      stockListObj = initial;
    }
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
        'FBillNo,FPrdOrgId.FNumber,FPrdOrgId.FName,FMOBillNO,FMOEntrySeq,FEntity_FEntryId,FEntity_FSeq,FMaterialID2.FNumber,FMaterialID2.FName,FMaterialID2.FSpecification,FUnitID2.FNumber,FUnitID2.FName,FNoPickedQty,FID,FLot.FNumber,FMaterialID2.FIsBatchManage,FMustQty,FPickedQty';
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
        'FBillNo,FPrdOrgId.FNumber,FPrdOrgId.FName,FMOBillNO,FMOEntrySeq,FEntity_FEntryId,FEntity_FSeq,FMaterialId.FNumber,FMaterialId.FName,FMaterialId.FSpecification,FUnitID.FNumber,FUnitID.FName,FAppQty,FLot.FNumber,FID,FMaterialId.FIsBatchManage,FAUXPROPID.FF100002.FNumber,FOwnerId.FNumber,FParentOwnerId.FNumber,FBaseUnitId.FNumber,FStockUnitId.FNumber,FOwnerTypeId,FParentOwnerTypeId,FKeeperTypeId,FKeeperId.FNumber,FParentMaterialId.FNumber,FMoEntryId,FPPBomEntryId,FEntryWorkShopId.FNumber,FMaterialId.FIsKFPeriod,FEntrySrcInterId';
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
     /*_onEvent("11180;2420WKW415星火/维特尔;2024-05-13;200;CGRK02491,1124323795;2");*/
  }
  getOrderListT(order) async {
    orderDate = [];
    orderDate = jsonDecode(order);
    hobby = [];
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var fStockIds = jsonDecode(sharedPreferences.getString('FStockIds'));
    print(fStockIds);
    if (orderDate.length > 0) {
      for (var value in orderDate) {
      //orderDate.forEach((value) {
        fNumber.add(value[7]);
        List arr = [];
        arr.add({
          "title": "物料编码",
          "name": "FMaterialId",
          "FEntryID": value[5],
          "FParentMaterialId": value[25],
          "FEntryWorkShopId": value[28],
          "FIsKFPeriod": value[29],
          "FMoEntryId": value[26],
          "FPPBomEntryId": value[27],
          "FOwnerId": value[17],
          "FParentOwnerId": value[18],
          "FUnitID": value[10],
          "FBaseUnitId": value[19],
          "FStockUnitId": value[20],
          "FOwnerTypeId": value[21],
          "FMoBillNo": value[3],
          "FKeeperTypeId": value[23],
          "FParentOwnerTypeId": value[22],
          "FKeeperId": value[24],
          "FEntrySrcInterId": value[25],
          "parseEntryID": -1,
          "isHide": false,
          "value": {
            "label": value[8] + "- (" + value[7] + ")",
            "value": value[7],
            "barcode": [],
            "surplus": value[12],
            "kingDeeCode": [],
            "scanCode": []
          }
        });
        arr.add({
          "title": "包装规格",
          "isHide": false,
          "name": "FMaterialIdFSpecification",
          "value": {"label": "", "value": ""}
          //"value": {"label": value[16]==null?"":value[16], "value": value[16]==null?"":value[16]}
        });
        arr.add({
          "title": "单位名称",
          "name": "FUnitId",
          "isHide": false,
          "value": {"label": value[11], "value": value[10]}
        });
        /*Map<String, dynamic> inventoryMap = Map();
        inventoryMap['FormId'] = 'STK_Inventory';
        if(fStockIds != '' && fStockIds != null){
          inventoryMap['FilterString'] = "FMaterialId.FNumber='" + value[7] + "' and FStockId in(" + fStockIds + ") and FBaseQty >0";// and FStockIds
        }else{
          inventoryMap['FilterString'] = "FMaterialId.FNumber='" + value[7] + "' and FBaseQty >0";// and FStockIds
        }
        inventoryMap['Limit'] = '20';
        inventoryMap['OrderString'] = 'FLot.FNumber DESC, FProduceDate DESC';
        inventoryMap['FieldKeys'] =
        'FMaterialId.FNumber,F_UUAC_BaseProperty,FMaterialId.FSpecification,FStockId.FNumber,FBaseQty,FLot.FNumber,FAuxPropId.FF100002.FNumber,FStockId.FName';
        Map<String, dynamic> inventoryDataMap = Map();
        inventoryDataMap['data'] = inventoryMap;
        String res = await CurrencyEntity.polling(inventoryDataMap);
        var stocks = jsonDecode(res);
        if (stocks.length > 0) {
          arr.add({
            "title": "领料数量",
            "name": "FBaseQty",
            "isHide": false,
            "value": {"label": "0", "value": "0" , "stocks": stocks}
          });

        }else{
          arr.add({
            "title": "领料数量",
            "name": "FBaseQty",
            "isHide": false,
            "value": {"label": "0", "value": "0" , "stocks": []}
          });
        }*/
        arr.add({
          "title": "领料数量",
          "name": "FBaseQty",
          "isHide": false,
          "value": {"label": "0", "value": "0" , "stocks": []}
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
          "isHide": value[15] != true,
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
          "value": {"label": "0", "value": "0","remainder": "0","representativeQuantity": "0"}
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
          "isHide": true,
          "value": {"label": "", "value": "", "itemList": []}
        });
        arr.add({
          "title": "生产日期",
          "name": "FProduceDate",
          "isHide": !value[29],
          "value": {
            "label": '',
            "value": ''
          }
        });
        arr.add({
          "title": "有效期至",
          "name": "FExpiryDate",
          "isHide": !value[29],
          "value": {
            "label": '',
            "value": ''
          }
        });
        hobby.add(arr);
      };
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
   /* _onEvent("21096;AQ40621210N1二仓;2024-06-21;150;,1634386736;2");
    _onEvent("21096;AQ40621210N1二仓;2024-06-21;198;,1711487255;2");*/
    /*_onEvent("13012;24031301鑫灏/展化;2024-03-13;235;,2121490693;4");
     _onEvent("13012;20231213科曼斯/龙翔;2023-12-13;10;,2123054921;4");
    _onEvent("11057;24C2493261遂悦/巴斯夫;2024-03-29;731;,2124408211;2");
    _onEvent("11057;20240326遂悦/巴斯夫;2024-03-26;1000;,2124246395;2");*/
  }

  void _onEvent(event) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var deptData = sharedPreferences.getString('menuList');
    var menuList = new Map<dynamic, dynamic>.from(jsonDecode(deptData));
    fBarCodeList = menuList['FBarCodeList'];
    if (event == "") {
      return;
    }
    if(checkItem == "position"){
      setState(() {
        this._FNumber = event;
        this._textNumber.text = event;
      });
    }else{
      if (fBarCodeList == 1) {
        var barcodeList = [];
        if(event.split(';').length>1){
          barcodeList = [[event]];
        }else{
          Map<String, dynamic> barcodeMap = Map();
          barcodeMap['FilterString'] = "FPackageNo='" + event + "' and FBarCodeEn!='" + event + "'";
          barcodeMap['FormId'] = 'QDEP_Cust_BarCodeList';
          barcodeMap['FieldKeys'] =
          'FBarCodeEn';
          Map<String, dynamic> dataMap = Map();
          dataMap['data'] = barcodeMap;
          String order = await CurrencyEntity.polling(dataMap);
          var barcodeData = jsonDecode(order);
          if (barcodeData.length > 0) {
            barcodeList = barcodeData;
          } else {
            barcodeList = [[event]];
          }
        }
        for(var item in barcodeList){
          Map<String, dynamic> barcodeMap = Map();
          barcodeMap['FilterString'] = "FBarCodeEn='" + item[0] + "'";
          barcodeMap['FormId'] = 'QDEP_Cust_BarCodeList';
          barcodeMap['FieldKeys'] =
          'FID,FInQtyTotal,FOutQtyTotal,FEntity_FEntryId,FRemainQty,FBarCodeQty,FStockID.FName,FStockID.FNumber,FMATERIALID.FNUMBER,FOwnerID.FNumber,FBarCode,FSN,FBatchNo,FPackageSpec,FProduceDate,FExpiryDate,FStockLocNumberH,FStockID.FIsOpenLocation';
          Map<String, dynamic> dataMap = Map();
          dataMap['data'] = barcodeMap;
          String order = await CurrencyEntity.polling(dataMap);
          var barcodeData = jsonDecode(order);
          if (barcodeData.length > 0) {
            if (barcodeData[0][4] > 0) {
              var msg = "";
              var orderIndex = 0;
              for (var value in orderDate) {
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
                    barcodeData, barcodeData[0][10], barcodeData[0][11],barcodeData[0][13], barcodeData[0][14].substring(0, 10), barcodeData[0][15].substring(0, 10), barcodeData[0][16].trim(), barcodeData[0][17]);//jsonDecode(stockOrder)[0][0]
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
        }
      } else {
        _code = event;
        this.getMaterialList("", _code, '', '', '', '', '', false);
        print("ChannelPage: $event");
      }
    }
    print("ChannelPage: $event");
  }

  getMaterialList(barcodeData, code, fsn,fAuxPropId, fProduceDate, fExpiryDate, fLoc,fIsOpenLocation) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var tissue = sharedPreferences.getString('tissue');
    var scanCode = code.split(";");
    userMap['FilterString'] = "FNumber='" +
        scanCode[0] +
        "' and FForbidStatus = 'A' and FUseOrgId.FNumber = " +
        tissue;
    userMap['FormId'] = 'BD_MATERIAL';
    userMap['FieldKeys'] =
        'FMATERIALID,FName,FNumber,FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FIsBatchManage,FStockId.FName,FStockId.FNumber,FIsKFPeriod';
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
      var barcodeQuantity = barCodeScan[4];
      var residue = double.parse(barCodeScan[4]);
      var hobbyIndex = 0;
      var insertIndex = 0;
      var surplus = 0.0;
      var parseEntryID = -1;
      var fIsKFPeriod = materialDate[0][7];
      this.hobbyItem = [];
      for(var i = 0;i<this.hobby.length;i++){
        if(this.hobbyItem.length==0){
          Map<String, dynamic> hobbyMap = Map();
          hobbyMap['number'] = this.hobby[i][0]['value']['value']+"-"+this.hobby[i][0]['FEntryID'].toString();
          hobbyMap['index'] = i;
          this.hobbyItem.add(hobbyMap);
        }else if(this.hobby[i][0]['FEntryID'] != 0){
          Map<String, dynamic> hobbyMap = Map();
          hobbyMap['number'] = this.hobby[i][0]['value']['value']+"-"+this.hobby[i][0]['FEntryID'].toString();
          hobbyMap['index'] = i;
          this.hobbyItem.add(hobbyMap);
        }
      }
      var errorTitle = "";
      for (var element in hobby) {
        var entryIndex;
        if(this.fBillNo == ''){
          entryIndex = hobbyIndex;
        }else{
          if(element[0]['FEntryID'] == 0){
            entryIndex = this.hobbyItem[this.hobbyItem.indexWhere((v)=> v['number'] == (element[0]['value']['value']+'-'+element[0]['parseEntryID'].toString()))]['index'];
          }else{
            entryIndex = this.hobbyItem[this.hobbyItem.indexWhere((v)=> v['number'] == (element[0]['value']['value']+'-'+element[0]['FEntryID'].toString()))]['index'];
          }
        }

        hobbyIndex++;
        //判断是否启用批号
        if (element[5]['isHide']) {
          //不启用  && element[4]['value']['value'] == barCodeScan[6]
          if (element[0]['value']['value'] == scanCode[0]) {
            if (element[0]['value']['barcode'].indexOf(code) == -1) {
              if (scanCode.length > 4) {
                element[0]['value']['barcode'].add(code);
              }
              if (scanCode[5] == "N") {
                if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                  if (element[4]['value']['value'] == "") {
                    element[4]['value']['label'] = barcodeData[0][6] == null? "":barcodeData[0][6];
                    element[4]['value']['value'] = barcodeData[0][7] == null? "":barcodeData[0][7];
                  }
                  if (element[1]['value']['value'] == "") {
                    element[1]['value']['label'] = fAuxPropId == null? "":fAuxPropId;
                    element[1]['value']['value'] =fAuxPropId == null? "":fAuxPropId;
                  }
                  if (element[14]['value']['value'] == "") {
                    element[14]['value']['label'] = fProduceDate == null? "":fProduceDate;
                    element[14]['value']['value'] =fProduceDate == null? "":fProduceDate;
                    element[15]['value']['label'] =fExpiryDate == null? "":fExpiryDate;
                    element[15]['value']['value'] =fExpiryDate == null? "":fExpiryDate;
                  }
                  if(fIsOpenLocation){
                    element[6]['value']['hide'] = fIsOpenLocation;
                    if (element[6]['value']['value'] == "") {
                      element[6]['value']['label'] = fLoc == null? "":fLoc;
                      element[6]['value']['value'] =fLoc == null? "":fLoc;
                    }
                  }
                  //判断是否启用保质期
                  if (!element[14]['isHide']) {
                    if (element[14]['value']['value'] == fProduceDate &&
                        element[15]['value']['value'] == fExpiryDate) {
                      errorTitle = "";
                    } else {
                      errorTitle = "保质期不一致";
                      surplus = hobby[entryIndex][0]['value']['surplus'];
                      parseEntryID = hobby[entryIndex][0]['FEntryID'];
                      fIsKFPeriod = hobby[entryIndex][0]['FIsKFPeriod'];
                      insertIndex = hobbyIndex;
                      continue;
                    }
                  }
                  //判断是否启用仓位
                  if (element[6]['value']['hide']) {
                    if (element[6]['value']['label'] == fLoc) {
                      errorTitle = "";
                    } else {
                      errorTitle = "仓位不一致";
                      surplus = hobby[entryIndex][0]['value']['surplus'];
                      parseEntryID = hobby[entryIndex][0]['FEntryID'];
                      fIsKFPeriod = hobby[entryIndex][0]['FIsKFPeriod'];
                      insertIndex = hobbyIndex;
                      continue;
                    }
                  }
                  //判断包装规格
                  if (element[1]['value']['label'] == fAuxPropId) {
                    errorTitle = "";
                  } else {
                    errorTitle = "包装规格不一致";
                    surplus = hobby[entryIndex][0]['value']['surplus'];
                    parseEntryID = hobby[entryIndex][0]['FEntryID'];
                    fIsKFPeriod = hobby[entryIndex][0]['FIsKFPeriod'];
                    insertIndex = hobbyIndex;
                    continue;
                  }
                  element[3]['value']['value'] =
                      (double.parse(element[3]['value']['value']) +
                          double.parse(barcodeNum))
                          .toString();
                  element[3]['value']['label'] = element[3]['value']['value'];
                  var item =
                      barCodeScan[0].toString() + "-" + barcodeNum + "-" + fsn;
                  element[0]['value']['kingDeeCode'].add(item);
                  element[0]['value']['scanCode'].add(code);
                  element[10]['value']['label'] = barcodeNum.toString();
                  element[10]['value']['value'] = barcodeNum.toString();
                  element[10]['value']['remainder'] = "0";
                  element[10]['value']['representativeQuantity'] = barcodeQuantity;
                  barcodeNum =
                      (double.parse(barcodeNum) - double.parse(barcodeNum))
                          .toString();
                }
                number++;
                break;
              }

              print(this.hobbyItem);
              print(entryIndex);
              print(element[0]['value']['value']);
              print(element[0]['FEntryID']);
              //判断扫描数量是否大于单据数量
              if (double.parse(element[3]['value']['value']) >=
                  hobby[entryIndex][9]['value']['label']) {
                continue;
              } else {
                //判断条码数量
                if ((double.parse(element[3]['value']['value']) + residue) >
                    0 &&
                    residue > 0) {
                  //判断条码是否重复
                  if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                    if (element[4]['value']['value'] == "") {
                      element[4]['value']['label'] = barcodeData[0][6] == null? "":barcodeData[0][6];
                      element[4]['value']['value'] = barcodeData[0][7] == null? "":barcodeData[0][7];
                    }
                    if (element[1]['value']['value'] == "") {
                      element[1]['value']['label'] = fAuxPropId == null? "":fAuxPropId;
                      element[1]['value']['value'] =fAuxPropId == null? "":fAuxPropId;
                    }
                    if (element[14]['value']['value'] == "") {
                      element[14]['value']['label'] = fProduceDate == null? "":fProduceDate;
                      element[14]['value']['value'] =fProduceDate == null? "":fProduceDate;
                      element[15]['value']['label'] =fExpiryDate == null? "":fExpiryDate;
                      element[15]['value']['value'] =fExpiryDate == null? "":fExpiryDate;
                    }
                    if(fIsOpenLocation){
                      element[6]['value']['hide'] = fIsOpenLocation;
                      if (element[6]['value']['value'] == "") {
                        element[6]['value']['label'] = fLoc == null? "":fLoc;
                        element[6]['value']['value'] =fLoc == null? "":fLoc;
                      }
                    }
                    //判断是否启用保质期
                    if (!element[14]['isHide']) {
                      if (element[14]['value']['value'] == fProduceDate &&
                          element[15]['value']['value'] == fExpiryDate) {
                        errorTitle = "";
                      } else {
                        errorTitle = "保质期不一致";
                        surplus = hobby[entryIndex][0]['value']['surplus'];
                        parseEntryID = hobby[entryIndex][0]['FEntryID'];
                        fIsKFPeriod = hobby[entryIndex][0]['FIsKFPeriod'];
                        insertIndex = hobbyIndex;
                        continue;
                      }
                    }
                    //判断是否启用仓位
                    if (element[6]['value']['hide']) {
                      if (element[6]['value']['label'] == fLoc) {
                        errorTitle = "";
                      } else {
                        errorTitle = "仓位不一致";
                        surplus = hobby[entryIndex][0]['value']['surplus'];
                        parseEntryID = hobby[entryIndex][0]['FEntryID'];
                        fIsKFPeriod = hobby[entryIndex][0]['FIsKFPeriod'];
                        insertIndex = hobbyIndex;
                        continue;
                      }
                    }
                    //判断包装规格
                    if (element[1]['value']['label'] == fAuxPropId) {
                      errorTitle = "";
                    } else {
                      errorTitle = "包装规格不一致";
                      surplus = hobby[entryIndex][0]['value']['surplus'];
                      parseEntryID = hobby[entryIndex][0]['FEntryID'];
                      fIsKFPeriod = hobby[entryIndex][0]['FIsKFPeriod'];
                      insertIndex = hobbyIndex;
                      continue;
                    }
                    //判断末尾
                    /*if (fNumber.lastIndexOf(
                            element[0]['value']['value'].toString()) ==
                        (hobbyIndex - 1)) {
                      var item = barCodeScan[0].toString() +
                          "-" +
                          residue.toString() +
                          "-" +
                          fsn;
                      element[10]['value']['label'] = residue.toString();
                      element[10]['value']['value'] = residue.toString();
                      element[3]['value']['label'] =
                          (double.parse(element[3]['value']['value']) + residue)
                              .toString();
                      element[3]['value']['value'] =
                          element[3]['value']['label'];
                      residue = (residue * 1000 -
                              double.parse(element[10]['value']['value']) *
                                  1000) /
                          1000;
                      element[0]['value']['surplus'] =
                          (element[9]['value']['value'] * 1000 -
                                  double.parse(element[3]['value']['value']) *
                                      1000) /
                              1000;
                      element[0]['value']['kingDeeCode'].add(item);
                      element[0]['value']['scanCode'].add(code);
                    } else {*/
                    //判断剩余数量是否大于扫码数量
                    if (hobby[entryIndex][0]['value']['surplus'] >= residue) {
                      var item = barCodeScan[0].toString() +
                          "-" +
                          residue.toString() +
                          "-" +
                          fsn;
                      element[10]['value']['label'] = residue.toString();
                      element[10]['value']['value'] = residue.toString();
                      element[10]['value']['remainder'] = "0";
                      element[10]['value']['representativeQuantity'] = barcodeQuantity;
                      element[3]['value']['label'] =
                          (double.parse(element[3]['value']['value']) +
                              residue)
                              .toString();
                      element[3]['value']['value'] =
                      element[3]['value']['label'];
                      residue = 0.0;
                      hobby[entryIndex][0]['value']['surplus'] =
                          (hobby[entryIndex][9]['value']['value'] * 1000 -
                              double.parse(element[3]['value']['value']) *
                                  1000) /
                              1000;
                      element[0]['value']['kingDeeCode'].add(item);
                      element[0]['value']['scanCode'].add(code);
                      number++;
                      break;
                    } else {
                      var item = barCodeScan[0].toString() +
                          "-" +
                          hobby[entryIndex][0]['value']['surplus'].toString() +
                          "-" +
                          fsn;
                      element[10]['value']['label'] =
                          hobby[entryIndex][0]['value']['surplus'].toString();
                      element[10]['value']['value'] =
                          hobby[entryIndex][0]['value']['surplus'].toString();

                      element[3]['value']['label'] = (hobby[entryIndex][0]['value']
                      ['surplus'] +
                          double.parse(element[3]['value']['value']))
                          .toString();
                      element[3]['value']['value'] =
                      element[3]['value']['label'];
                      residue = (residue * 1000 -
                          double.parse(element[10]['value']['value']) *
                              1000) /
                          1000;
                      hobby[entryIndex][0]['value']['surplus'] =
                          (hobby[entryIndex][9]['value']['value'] * 1000 -
                              double.parse(element[3]['value']['value']) *
                                  1000) /
                              1000;
                      element[10]['value']['remainder'] = residue.toString();
                      element[10]['value']['representativeQuantity'] = barcodeQuantity;
                      element[0]['value']['kingDeeCode'].add(item);
                      element[0]['value']['scanCode'].add(code);
                      number++;
                    }
                    // }
                  }
                }
              }
            } else {
              ToastUtil.showInfo('该标签已扫描');
              number++;
              break;
            }
            surplus = hobby[entryIndex][0]['value']['surplus'];
            parseEntryID = hobby[entryIndex][0]['FEntryID'];
            fIsKFPeriod = hobby[entryIndex][0]['FIsKFPeriod'];
            insertIndex = hobbyIndex;
          }
        } else {
          //启用批号 && element[4]['value']['value'] == barCodeScan[6]
          if (element[0]['value']['value'] == scanCode[0]) {
            if (element[0]['value']['barcode'].indexOf(code) == -1) {
              if (scanCode.length > 4) {
                element[0]['value']['barcode'].add(code);
              }

              if (scanCode[5] == "N") {
                if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                  if (element[4]['value']['value'] == "") {
                    element[4]['value']['label'] = barcodeData[0][6] == null? "":barcodeData[0][6];
                    element[4]['value']['value'] = barcodeData[0][7] == null? "":barcodeData[0][7];
                  }
                  if (element[1]['value']['value'] == "") {
                    element[1]['value']['label'] = fAuxPropId == null? "":fAuxPropId;
                    element[1]['value']['value'] =fAuxPropId == null? "":fAuxPropId;
                  }
                  if (element[14]['value']['value'] == "") {
                    element[14]['value']['label'] = fProduceDate == null? "":fProduceDate;
                    element[14]['value']['value'] =fProduceDate == null? "":fProduceDate;
                    element[15]['value']['label'] =fExpiryDate == null? "":fExpiryDate;
                    element[15]['value']['value'] =fExpiryDate == null? "":fExpiryDate;
                  }
                  if (element[5]['value']['value'] == "") {
                    element[5]['value']['label'] = scanCode[1];
                    element[5]['value']['value'] = scanCode[1];
                  }
                  if(fIsOpenLocation){
                    element[6]['value']['hide'] = fIsOpenLocation;
                    if (element[6]['value']['value'] == "") {
                      element[6]['value']['label'] = fLoc == null? "":fLoc;
                      element[6]['value']['value'] =fLoc == null? "":fLoc;
                    }
                  }
                  //判断是否启用保质期
                  if (!element[14]['isHide']) {
                    if (element[14]['value']['value'] == fProduceDate &&
                        element[15]['value']['value'] == fExpiryDate) {
                      errorTitle = "";
                    } else {
                      errorTitle = "保质期不一致";
                      surplus = hobby[entryIndex][0]['value']['surplus'];
                      parseEntryID = hobby[entryIndex][0]['FEntryID'];
                      fIsKFPeriod = hobby[entryIndex][0]['FIsKFPeriod'];
                      insertIndex = hobbyIndex;
                      continue;
                    }
                  }
                  //判断是否启用仓位
                  if (element[6]['value']['hide']) {
                    if (element[6]['value']['label'] == fLoc) {
                      errorTitle = "";
                    } else {
                      errorTitle = "仓位不一致";
                      surplus = hobby[entryIndex][0]['value']['surplus'];
                      parseEntryID = hobby[entryIndex][0]['FEntryID'];
                      fIsKFPeriod = hobby[entryIndex][0]['FIsKFPeriod'];
                      insertIndex = hobbyIndex;
                      continue;
                    }
                  }
                  //判断包装规格
                  if (element[1]['value']['label'] == fAuxPropId) {
                    errorTitle = "";
                  } else {
                    errorTitle = "包装规格不一致";
                    surplus = hobby[entryIndex][0]['value']['surplus'];
                    parseEntryID = hobby[entryIndex][0]['FEntryID'];
                    fIsKFPeriod = hobby[entryIndex][0]['FIsKFPeriod'];
                    insertIndex = hobbyIndex;
                    continue;
                  }
                  element[3]['value']['value'] =
                      (double.parse(element[3]['value']['value']) +
                          double.parse(barcodeNum))
                          .toString();
                  element[3]['value']['label'] = element[3]['value']['value'];
                  var item =
                      barCodeScan[0].toString() + "-" + barcodeNum + "-" + fsn;
                  element[0]['value']['kingDeeCode'].add(item);
                  element[0]['value']['scanCode'].add(code);
                  element[10]['value']['label'] = barcodeNum.toString();
                  element[10]['value']['value'] = barcodeNum.toString();
                  element[10]['value']['remainder'] = "0";
                  element[10]['value']['representativeQuantity'] = barcodeQuantity;
                  barcodeNum =
                      (double.parse(barcodeNum) - double.parse(barcodeNum))
                          .toString();
                }
                number++;
                break;
              }
              if (element[5]['value']['value'] == scanCode[1]) {


                print(this.hobbyItem);
                print(entryIndex);
                print(element[0]['value']['value']);
                print(element[0]['FEntryID']);
                //判断扫描数量是否大于单据数量
                if (double.parse(element[3]['value']['value']) >=
                    hobby[entryIndex][9]['value']['label']) {
                  continue;
                } else {
                  //判断条码数量
                  if ((double.parse(element[3]['value']['value']) + residue) >
                      0 &&
                      residue > 0) {
                    //判断条码是否重复
                    if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                      if (element[4]['value']['value'] == "") {
                        element[4]['value']['label'] = barcodeData[0][6] == null? "":barcodeData[0][6];
                        element[4]['value']['value'] = barcodeData[0][7] == null? "":barcodeData[0][7];
                      }
                      if (element[1]['value']['value'] == "") {
                        element[1]['value']['label'] = fAuxPropId == null? "":fAuxPropId;
                        element[1]['value']['value'] =fAuxPropId == null? "":fAuxPropId;
                      }
                      if (element[14]['value']['value'] == "") {
                        element[14]['value']['label'] = fProduceDate == null? "":fProduceDate;
                        element[14]['value']['value'] =fProduceDate == null? "":fProduceDate;
                        element[15]['value']['label'] =fExpiryDate == null? "":fExpiryDate;
                        element[15]['value']['value'] =fExpiryDate == null? "":fExpiryDate;
                      }
                      if(fIsOpenLocation){
                        element[6]['value']['hide'] = fIsOpenLocation;
                        if (element[6]['value']['value'] == "") {
                          element[6]['value']['label'] = fLoc == null? "":fLoc;
                          element[6]['value']['value'] =fLoc == null? "":fLoc;
                        }
                      }
                      //判断是否启用保质期
                      if (!element[14]['isHide']) {
                        if (element[14]['value']['value'] == fProduceDate &&
                            element[15]['value']['value'] == fExpiryDate) {
                          errorTitle = "";
                        } else {
                          errorTitle = "保质期不一致";
                          surplus = hobby[entryIndex][0]['value']['surplus'];
                          parseEntryID = hobby[entryIndex][0]['FEntryID'];
                          fIsKFPeriod = hobby[entryIndex][0]['FIsKFPeriod'];
                          insertIndex = hobbyIndex;
                          continue;
                        }
                      }
                      //判断是否启用仓位
                      if (element[6]['value']['hide']) {
                        if (element[6]['value']['label'] == fLoc) {
                          errorTitle = "";
                        } else {
                          errorTitle = "仓位不一致";
                          surplus = hobby[entryIndex][0]['value']['surplus'];
                          parseEntryID = hobby[entryIndex][0]['FEntryID'];
                          fIsKFPeriod = hobby[entryIndex][0]['FIsKFPeriod'];
                          insertIndex = hobbyIndex;
                          continue;
                        }
                      }
                      //判断包装规格
                      if (element[1]['value']['label'] == fAuxPropId) {
                        errorTitle = "";
                      } else {
                        errorTitle = "包装规格不一致";
                        surplus = hobby[entryIndex][0]['value']['surplus'];
                        parseEntryID = hobby[entryIndex][0]['FEntryID'];
                        fIsKFPeriod = hobby[entryIndex][0]['FIsKFPeriod'];
                        insertIndex = hobbyIndex;
                        continue;
                      }
                      //判断末尾
                      /*if (fNumber.lastIndexOf(
                              element[0]['value']['value'].toString()) ==
                          (hobbyIndex - 1)) {
                        var item = barCodeScan[0].toString() +
                            "-" +
                            residue.toString() +
                            "-" +
                            fsn;
                        element[10]['value']['label'] = residue.toString();
                        element[10]['value']['value'] = residue.toString();
                        element[3]['value']['label'] =
                            (double.parse(element[3]['value']['value']) +
                                    residue)
                                .toString();
                        element[3]['value']['value'] =
                            element[3]['value']['label'];
                        residue = (residue * 1000 -
                                double.parse(element[10]['value']['value']) *
                                    1000) /
                            1000;
                        element[0]['value']['surplus'] =
                            (element[9]['value']['value'] * 1000 -
                                    double.parse(element[3]['value']['value']) *
                                        1000) /
                                1000;
                        ;
                        element[0]['value']['kingDeeCode'].add(item);
                        element[0]['value']['scanCode'].add(code);
                      } else {*/
                      //判断剩余数量是否大于扫码数量
                      if (hobby[entryIndex][0]['value']['surplus'] >= residue) {
                        var item = barCodeScan[0].toString() +
                            "-" +
                            residue.toString() +
                            "-" +
                            fsn;
                        element[10]['value']['label'] = residue.toString();
                        element[10]['value']['value'] = residue.toString();
                        element[10]['value']['remainder'] = "0";
                        element[10]['value']['representativeQuantity'] = barcodeQuantity;
                        element[3]['value']['label'] =
                            (double.parse(element[3]['value']['value']) +
                                residue)
                                .toString();
                        element[3]['value']['value'] =
                        element[3]['value']['label'];
                        residue = 0.0;
                        hobby[entryIndex][0]['value']['surplus'] = (hobby[entryIndex][9]['value']
                        ['value'] *
                            1000 -
                            double.parse(element[3]['value']['value']) *
                                1000) /
                            1000;
                        element[0]['value']['kingDeeCode'].add(item);
                        element[0]['value']['scanCode'].add(code);
                        number++;
                        break;
                      } else {
                        var item = barCodeScan[0].toString() +
                            "-" +
                            hobby[entryIndex][0]['value']['surplus'].toString() +
                            "-" +
                            fsn;
                        element[10]['value']['label'] =
                            hobby[entryIndex][0]['value']['surplus'].toString();
                        element[10]['value']['value'] =
                            hobby[entryIndex][0]['value']['surplus'].toString();
                        element[3]['value']['label'] = (element[0]['value']
                        ['surplus'] +
                            double.parse(element[3]['value']['value']))
                            .toString();
                        element[3]['value']['value'] =
                        element[3]['value']['label'];
                        residue = (residue * 1000 -
                            double.parse(element[10]['value']['value']) *
                                1000) /
                            1000;
                        hobby[entryIndex][0]['value']['surplus'] = (hobby[entryIndex][9]['value']
                        ['value'] *
                            1000 -
                            double.parse(element[3]['value']['value']) *
                                1000) /
                            1000;
                        element[10]['value']['remainder'] = residue.toString();
                        element[10]['value']['representativeQuantity'] = barcodeQuantity;
                        element[0]['value']['kingDeeCode'].add(item);
                        element[0]['value']['scanCode'].add(code);
                        number++;
                      }
                      //}
                    }
                  }
                }
              } else {
                if (element[5]['value']['value'] == "") {
                  element[5]['value']['label'] = scanCode[1];
                  element[5]['value']['value'] = scanCode[1];

                  print(this.hobbyItem);
                  print(entryIndex);
                  print(element[0]['value']['value']);
                  print(element[0]['FEntryID']);
                  //判断扫描数量是否大于单据数量
                  if (double.parse(element[3]['value']['value']) >=
                      hobby[entryIndex][9]['value']['label']) {
                    continue;
                  } else {
                    //判断条码数量
                    if ((double.parse(element[3]['value']['value']) + residue) >
                        0 &&
                        residue > 0) {
                      //判断条码是否重复
                      if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                        if (element[4]['value']['value'] == "") {
                          element[4]['value']['label'] = barcodeData[0][6] == null? "":barcodeData[0][6];
                          element[4]['value']['value'] = barcodeData[0][7] == null? "":barcodeData[0][7];
                        }
                        if (element[1]['value']['value'] == "") {
                          element[1]['value']['label'] = fAuxPropId == null? "":fAuxPropId;
                          element[1]['value']['value'] =fAuxPropId == null? "":fAuxPropId;
                        }
                        if (element[14]['value']['value'] == "") {
                          element[14]['value']['label'] = fProduceDate == null? "":fProduceDate;
                          element[14]['value']['value'] =fProduceDate == null? "":fProduceDate;
                          element[15]['value']['label'] =fExpiryDate == null? "":fExpiryDate;
                          element[15]['value']['value'] =fExpiryDate == null? "":fExpiryDate;
                        }
                        if(fIsOpenLocation){
                          element[6]['value']['hide'] = fIsOpenLocation;
                          if (element[6]['value']['value'] == "") {
                            element[6]['value']['label'] = fLoc == null? "":fLoc;
                            element[6]['value']['value'] =fLoc == null? "":fLoc;
                          }
                        }
                        //判断是否启用保质期
                        if (!element[14]['isHide']) {
                          if (element[14]['value']['value'] == fProduceDate &&
                              element[15]['value']['value'] == fExpiryDate) {
                            errorTitle = "";
                          } else {
                            errorTitle = "保质期不一致";
                            surplus = hobby[entryIndex][0]['value']['surplus'];
                            parseEntryID = hobby[entryIndex][0]['FEntryID'];
                            fIsKFPeriod = hobby[entryIndex][0]['FIsKFPeriod'];
                            insertIndex = hobbyIndex;
                            continue;
                          }
                        }
                        //判断是否启用仓位
                        if (element[6]['value']['hide']) {
                          if (element[6]['value']['label'] == fLoc) {
                            errorTitle = "";
                          } else {
                            errorTitle = "仓位不一致";
                            surplus = hobby[entryIndex][0]['value']['surplus'];
                            parseEntryID = hobby[entryIndex][0]['FEntryID'];
                            fIsKFPeriod = hobby[entryIndex][0]['FIsKFPeriod'];
                            insertIndex = hobbyIndex;
                            continue;
                          }
                        }
                        //判断包装规格
                        if (element[1]['value']['label'] == fAuxPropId) {
                          errorTitle = "";
                        } else {
                          errorTitle = "包装规格不一致";
                          surplus = hobby[entryIndex][0]['value']['surplus'];
                          parseEntryID = hobby[entryIndex][0]['FEntryID'];
                          fIsKFPeriod = hobby[entryIndex][0]['FIsKFPeriod'];
                          insertIndex = hobbyIndex;
                          continue;
                        }
                        //判断末尾
                        /* if (fNumber.lastIndexOf(
                                element[0]['value']['value'].toString()) ==
                            (hobbyIndex - 1)) {
                          var item = barCodeScan[0].toString() +
                              "-" +
                              residue.toString() +
                              "-" +
                              fsn;
                          element[10]['value']['label'] = residue.toString();
                          element[10]['value']['value'] = residue.toString();
                          element[3]['value']['label'] =
                              (double.parse(element[3]['value']['value']) +
                                      residue)
                                  .toString();
                          element[3]['value']['value'] =
                              element[3]['value']['label'];
                          residue = (residue * 1000 -
                                  double.parse(element[10]['value']['value']) *
                                      1000) /
                              1000;
                          element[0]['value']['surplus'] = (element[9]['value']
                                          ['value'] *
                                      1000 -
                                  double.parse(element[3]['value']['value']) *
                                      1000) /
                              1000;
                          ;
                          element[0]['value']['kingDeeCode'].add(item);
                          element[0]['value']['scanCode'].add(code);
                        } else {*/
                        //判断剩余数量是否大于扫码数量
                        if (hobby[entryIndex][0]['value']['surplus'] >= residue) {
                          var item = barCodeScan[0].toString() +
                              "-" +
                              residue.toString() +
                              "-" +
                              fsn;
                          element[10]['value']['label'] = residue.toString();
                          element[10]['value']['value'] = residue.toString();
                          element[10]['value']['remainder'] = "0";
                          element[10]['value']['representativeQuantity'] = barcodeQuantity;
                          element[3]['value']['label'] =
                              (double.parse(element[3]['value']['value']) +
                                  residue)
                                  .toString();
                          element[3]['value']['value'] =
                          element[3]['value']['label'];
                          residue = 0.0;
                          hobby[entryIndex][0]['value']['surplus'] = (hobby[entryIndex][9]
                          ['value']['value'] *
                              1000 -
                              double.parse(element[3]['value']['value']) *
                                  1000) /
                              1000;
                          element[0]['value']['kingDeeCode'].add(item);
                          element[0]['value']['scanCode'].add(code);
                          number++;
                          break;
                        } else {
                          var item = barCodeScan[0].toString() +
                              "-" +
                              hobby[entryIndex][0]['value']['surplus'].toString() +
                              "-" +
                              fsn;
                          element[10]['value']['label'] =
                              hobby[entryIndex][0]['value']['surplus'].toString();
                          element[10]['value']['value'] =
                              hobby[entryIndex][0]['value']['surplus'].toString();

                          element[3]['value']['label'] = (element[0]['value']
                          ['surplus'] +
                              double.parse(element[3]['value']['value']))
                              .toString();
                          element[3]['value']['value'] =
                          element[3]['value']['label'];
                          residue = (residue * 1000 -
                              double.parse(
                                  element[10]['value']['value']) *
                                  1000) /
                              1000;
                          hobby[entryIndex][0]['value']['surplus'] = (hobby[entryIndex][9]
                          ['value']['value'] *
                              1000 -
                              double.parse(element[3]['value']['value']) *
                                  1000) /
                              1000;
                          element[10]['value']['remainder'] = residue.toString();
                          element[10]['value']['representativeQuantity'] = barcodeQuantity;
                          element[0]['value']['kingDeeCode'].add(item);
                          element[0]['value']['scanCode'].add(code);
                          number++;
                        }
                        //}
                      }
                    }
                  }
                }
              }
            } else {
              ToastUtil.showInfo('该标签已扫描');
              number++;
              break;
            }
            surplus = hobby[entryIndex][0]['value']['surplus'];
            parseEntryID = hobby[entryIndex][0]['FEntryID'];
            fIsKFPeriod = hobby[entryIndex][0]['FIsKFPeriod'];
            insertIndex = hobbyIndex;
          }
        }
      }
      if (number == 0 ) {
        var inserNum = 0.0;
        print("剩余");
        print(surplus);


        if(double.parse(barCodeScan[4]) >= surplus && this.fBillNo!=''){
          inserNum = surplus;
        }else{
          inserNum = double.parse(barCodeScan[4]);
        }

        if(inserNum == 0){
          ToastUtil.showInfo('该物料领料数量已达上限');
          return;
        }
        materialDate.forEach((value) {
          if(this.hobbyItem.indexWhere((v)=> v['number'] == (value[2]+'-'+parseEntryID.toString())) != -1){
            var parentIndex = this.hobbyItem[this.hobbyItem.indexWhere((v)=> v['number'] == (value[2]+'-'+parseEntryID.toString()))]['index'];
            hobby[parentIndex][0]['value']['surplus'] = (surplus - inserNum >0?surplus - inserNum:0);
          }
          List arr = [];
          arr.add({
            "title": "物料编码",
            "name": "FMaterialId",
            "FEntryID": 0,
            "parseEntryID": parseEntryID,
            "FIsKFPeriod": fIsKFPeriod,
            "isHide": false,
            "value": {
              "surplus": surplus,
              "label": value[1] + "- (" + value[2] + ")",
              "value": value[2],
              "barcode": [code],
              "kingDeeCode": [barCodeScan[0].toString()+"-"+inserNum.toString()+"-"+fsn],
              "scanCode": [barCodeScan[0].toString()+"-"+inserNum.toString()]
            }
          });
          arr.add({
            "title": "包装规格",
            "isHide": false,
            "name": "FMaterialIdFSpecification",
            "value": {"label": fAuxPropId, "value": fAuxPropId}
          });
          arr.add({
            "title": "单位名称",
            "name": "FUnitId",
            "isHide": false,
            "value": {"label": value[4], "value": value[5]}
          });
          arr.add({
            "title": "领料数量",
            "name": "FBaseQty",
            "isHide": false,
            "value": {"label": inserNum.toString(), "value": inserNum.toString() , "stocks": []}
          });
          arr.add({
            "title": "仓库",
            "name": "FStockId",
            "isHide": false,
            "value": {"label": barcodeData[0][6], "value": barcodeData[0][7]}
          });
          arr.add({
            "title": "批号",
            "isHide": value[6] != true,
            "value": {"label": value[6]?(scanCode.length>1?scanCode[1]:''):'', "value": value[6]?(scanCode.length>1?scanCode[1]:''):''}
          });
          arr.add({
            "title": "仓位",
            "name": "FStockLocID",
            "isHide": false,
            "value": {"label": fLoc, "value": fLoc, "hide": fIsOpenLocation}
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
            "value": {"label": "", "value": ""}
          });
          arr.add({
            "title": "用量",
            "name": "FPrdOrgId",
            "isHide": false,
            "value": {"label": surplus, "value": surplus}
          });
          arr.add({
            "title": "最后扫描数量",
            "name": "FLastQty",
            "isHide": false,
            "value": {
              "label": inserNum.toString(),
              "value": inserNum.toString(),"remainder": ((double.parse(barCodeScan[4])*1000 - inserNum*1000)/1000).toString(),"representativeQuantity": barCodeScan[4]
            }
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
            "isHide": true,
            "value": {"label": "", "value": "", "itemList": []}
          });
          arr.add({
            "title": "生产日期",
            "name": "FProduceDate",
            "isHide": !fIsKFPeriod,
            "value": {
              "label": fProduceDate,
              "value": fProduceDate
            }
          });
          arr.add({
            "title": "有效期至",
            "name": "FExpiryDate",
            "isHide": !fIsKFPeriod,
            "value": {
              "label": fExpiryDate,
              "value": fExpiryDate
            }
          });
          hobby.insert(insertIndex, arr);
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
        setState(()  {
          switch (model) {
            case DateMode.YMD:
              selectData[model] = '${p.year}-${p.month}-${p.day}';
              FDate = '${p.year}-${p.month}-${p.day}';
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

            setState(() {
              hobby['value']['label'] = p;
            });
            var elementIndex = 0;
            data.forEach((element) {
              print(element);
              if (element == p) {
                hobby['value']['value'] = stockListObj[elementIndex][2];
                stock[6]['value']['hide'] = stockListObj[elementIndex][3];
                stock[6]['value']['value'] = "";
                stock[6]['value']['label'] = "";
                //hobby['value']['dimension'] = stockListObj[elementIndex][4];
              }
              elementIndex++;
            });
        });
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
                                this.hobby[checkData][12]["value"]["value"] = (realQty.ceil()).toString();
                                this.hobby[checkData][12]["value"]["label"] = (realQty.ceil()).toString();
                                this.hobby[checkData][checkDataChild]["value"]
                                ["label"] = _FNumber;
                                this.hobby[checkData][checkDataChild]['value']
                                ["value"] = _FNumber;
                              }else{
                                ToastUtil.showInfo('请输入出库数量');
                              }
                            }else if (checkItem == "FLastQty") {
                              if(double.parse(_FNumber) <= this.hobby[checkData][9]["value"]['value']){
                                if(double.parse(_FNumber) <= double.parse(this.hobby[checkData][checkDataChild]["value"]['representativeQuantity'])){
                                  if (this.hobby[checkData][0]['value']['kingDeeCode'].length > 0) {
                                    var kingDeeCode = this.hobby[checkData][0]['value']['kingDeeCode'][this.hobby[checkData][0]['value']['kingDeeCode'].length - 1].split("-");
                                    var realQty = 0.0;
                                    this.hobby[checkData][0]['value']['kingDeeCode'].forEach((item) {
                                      var qty = item.split("-")[1];
                                      realQty += double.parse(qty);
                                    });
                                    realQty = (realQty * 1000 - double.parse(this.hobby[checkData][10]["value"]["label"]) * 1000) / 1000;
                                    realQty = (realQty * 1000 + double.parse(_FNumber) * 1000) / 1000;
                                    this.hobby[checkData][10]["value"]["remainder"] = (Decimal.parse(this.hobby[checkData][10]["value"]["representativeQuantity"]) - Decimal.parse(_FNumber)).toString();
                                    this.hobby[checkData][3]["value"]["value"] = realQty.toString();
                                    this.hobby[checkData][3]["value"]["label"] = realQty.toString();
                                    if(this.fBillNo!="") {
                                      var entryIndex;
                                      if (this.hobby[checkData][0]['FEntryID'] ==
                                          0) {
                                        entryIndex =
                                        this.hobbyItem[this.hobbyItem.indexWhere((
                                            v) => v['number'] == (this
                                            .hobby[checkData][0]['value']['value'] +
                                            '-' + this
                                            .hobby[checkData][0]['parseEntryID']
                                            .toString()))]['index'];
                                      } else {
                                        entryIndex =
                                        this.hobbyItem[this.hobbyItem.indexWhere((
                                            v) => v['number'] == (this
                                            .hobby[checkData][0]['value']['value'] +
                                            '-' +
                                            this.hobby[checkData][0]['FEntryID']
                                                .toString()))]['index'];
                                      }
                                      hobby[entryIndex][0]['value']['surplus'] = (hobby[entryIndex][9]['value']['value'] * 1000 - double.parse(this.hobby[checkData][3]['value']['value']) * 1000) / 1000;
                                    }
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
                                ToastUtil.showInfo('输入数量大于可用数量');
                              }

                            }else{
                              this.hobby[checkData][checkDataChild]["value"]
                              ["label"] = _FNumber;
                              this.hobby[checkData][checkDataChild]['value']
                              ["value"] = _FNumber;
                            }
                            checkItem = '';
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
  //调出弹窗 扫码
  void inNumDialog(childList, val, index, stockId) {
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
                    child: Text('输入数量(可用数量为'+val.toString()+')',
                        style: TextStyle(
                            fontSize: 16, decoration: TextDecoration.none)),
                  ),
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

                          setState(() {
                            /*dataItem[3]['value']['value'] = options[index][5];
                            dataItem[3]['value']['label'] = options[index][5];
                            dataItem[13]['value']['itemList'].add(childList);*/
                            print(_FNumber);
                            print(_FNumber is String);
                            if(_FNumber != '0' && _FNumber != ''&& _FNumber != null){
                              if(double.parse(_FNumber) <= double.parse(val)){
                                this.hobby[checkData][checkDataChild]["value"]
                                ["label"] = (Decimal.parse(this.hobby[checkData][checkDataChild]["value"]
                                ["label"]) + Decimal.parse(_FNumber)).toString();
                                this.hobby[checkData][checkDataChild]['value']
                                ["value"] = this.hobby[checkData][checkDataChild]["value"]
                                ["label"] ;
                                childList = childList +"-"+ _FNumber;
                                this.hobby[checkData][13]['value']
                                ["itemList"].add(childList);
                                this.hobby[checkData][4]['value']
                                ["value"] = stockId;
                                this.hobby[checkData][checkDataChild]["value"]
                                ["stocks"][index][4] = Decimal.parse(val) - Decimal.parse(_FNumber);/*(double.parse(val) - double.parse(_FNumber)).toString();*/
                                Navigator.pop(context);
                              }else{
                                ToastUtil.showInfo('输入数量大于库存数量');
                              }
                            }else{
                              ToastUtil.showInfo('请输入数量');
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
  Future<List<int>?> _showModalBottomSheet(
      BuildContext context, List<dynamic> options, List<dynamic> dataItem) async {
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
                          title: Text('批号:'+options[index][5]+';包装规格:'+(options[index][6]==null?'':options[index][6])+';数量:'+options[index][4].toString()+';仓库:'+options[index][3]+(options[index][11]?(options[index][7]+'.'+options[index][8]+'.'+options[index][9]+'.'+options[index][10]):'')),//+';仓库:'+options[index][3]+';数量:'+options[index][4].toString()+';包装规格:'+options[index][6]
                          onTap: () {
                            /*setState(() {
                              print(dataItem);
                              var childList = options[index][6] == null?  options[index][5].toString() +"-无":options[index][5].toString() +"-"+ options[index][6].toString();
                              Navigator.pop(context);
                              inNumDialog(childList, options[index][4].toString(),index,options[index][3]);
                            });
                            print(options[index]);*/
                            // Do something

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
  setClickData(Map<dynamic,dynamic> dataItem, val) async{
    setState(() {
      dataItem['value']['value'] = val;
      dataItem['value']['label'] = val;
    });
  }
  Future<List<int>?> _showMultiChoiceModalBottomSheet(
      BuildContext context, List<dynamic> options, Map<dynamic,dynamic> dataItem) async {
    List selected = [];
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
              Row(
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
                      padding: EdgeInsets.only(top: 10.0,left: 10.0),
                      alignment: Alignment.center,
                      child: TextField(
                        controller: this.controller,
                        decoration: new InputDecoration(
                            contentPadding:
                            EdgeInsets.only(
                                bottom: 12.0),
                            hintText: '输入关键字',
                            border: InputBorder.none),
                        onSubmitted: (value){
                          options = [];
                          for(var element in this.bagListObj){
                            options.add(element[1]);
                          }
                          setState(() {
                            options = options.where((item) => item.toString().replaceAll('kg', '') == value).toList();
                            //options = options.where((item) => item.contains(value)).toList()..sort((a,b)=> double.parse(a.toString().replaceAll('kg', '')).compareTo(double.parse(b.toString().replaceAll('kg', ''))));
                          });
                        },
                        // onChanged: onSearchTextChanged,
                      ),
                    ),
                  ),
                ],
              ),

              Divider(height: 1.0),
              Expanded(
                child: ListView.builder(
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      title: new Row(children: <Widget>[Text(options[index],
                      )
                      ], mainAxisAlignment: MainAxisAlignment.center,),
                      onTap: () async{
                        await this.setClickData(dataItem, options[index]);
                        Navigator.of(context).pop();
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
  List<Widget> _getHobby() {
    List<Widget> tempList = [];
    for (int i = 0; i < this.hobby.length; i++) {
      List<Widget> comList = [];
      _textNumber2.add(TextEditingController());
      _textNumber3.add(TextEditingController());
      focusNodes.add(FocusNode());
      // 可选：添加监听（需注意内存管理）
      _setupListener(i);
      for (int j = 0; j < this.hobby[i].length; j++) {
        if (!this.hobby[i][j]['isHide']) {
          if (j == 0) {
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
                              icon: new Icon(Icons.search),
                              tooltip: '查看',
                              padding: EdgeInsets.only(left: 30),
                              onPressed: () async{
                                  Map<String, dynamic> inventoryMap = Map();
                                  inventoryMap['FormId'] = 'STK_Inventory';
                                  inventoryMap['FilterString'] = "FMaterialId.FNumber='" + this.hobby[i][j]["value"]["value"] + "' and FBaseQty >0";
                                  inventoryMap['Limit'] = '50';
                                  inventoryMap['OrderString'] = 'FLot.FNumber DESC, FProduceDate DESC';
                                  inventoryMap['FieldKeys'] =
                                  'FMaterialId.FNumber,F_UUAC_BaseProperty,FMaterialId.FSpecification,FStockId.FName,FBaseQty,FLot.FNumber,FAuxPropId.FF100002.FNumber,FStockLocId.FF100018.FNumber,FStockLocId.FF100019.FNumber,FStockLocId.FF100020.FNumber,FStockLocId.FF100021.FNumber,FStockID.FIsOpenLocation';
                                  Map<String, dynamic> inventoryDataMap = Map();
                                  inventoryDataMap['data'] = inventoryMap;
                                  String res = await CurrencyEntity.polling(inventoryDataMap);
                                  var stocks = jsonDecode(res);
                                  if (stocks.length > 0) {
                                    await _showModalBottomSheet(
                                        context, stocks,this.hobby[i]);
                                    checkData = i;
                                    checkDataChild = j;
                                    _FNumber = '0';
                                    this._textNumber.value =
                                        _textNumber.value.copyWith(
                                          text: '0',
                                        );
                                  }else{
                                    ToastUtil.showInfo('无库存');
                                  }
                              },
                            ),
                          ])),
                ),
                divider,
              ]),
            );
          } else if (j == 10) {
            comList.add(
              Column(children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                      title: Text(this.hobby[i][j]["title"] +
                          '：'+'剩余('+this.hobby[i][j]["value"]["remainder"].toString()+')'),
                      trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            SizedBox(
                              width: 100,  // 设置固定宽度
                              child: TextField(
                                controller: _textNumber3[i], // 文本控制器
                                focusNode: focusNodes[i],
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  if(value == '' || value == '.'){
                                    value = "0";
                                    this._textNumber3[i].text = "0";
                                  }else if(value[0]=="0" && value.length>1){
                                    if(value[value.length - 1]!="."){
                                      value = value.substring(1);
                                      this._textNumber3[i].text = value.substring(1);
                                    }
                                  }
                                  if(value[value.length - 1]!="."){
                                    if(double.parse(value) <= double.parse(this.hobby[i][j]["value"]['representativeQuantity'])){
                                      if(double.parse(value) <= this.hobby[i][9]["value"]['value']){
                                        if (this.hobby[i][0]['value']['kingDeeCode'].length > 0) {
                                          var kingDeeCode = this.hobby[i][0]['value']['kingDeeCode'][this.hobby[i][0]['value']['kingDeeCode'].length - 1].split("-");
                                          var realQty = 0.0;
                                          this.hobby[i][0]['value']['kingDeeCode'].forEach((item) {
                                            var qty = item.split("-")[1];
                                            realQty += double.parse(qty);
                                          });
                                          realQty = (realQty * 100 - double.parse(this.hobby[i][10]["value"]["label"]) * 100) / 100;
                                          realQty = (realQty * 100 + double.parse(value) * 100) / 100;
                                          this.hobby[i][10]["value"]["remainder"] = (Decimal.parse(this.hobby[i][10]["value"]["representativeQuantity"]) - Decimal.parse(value)).toString();
                                          this.hobby[i][3]["value"]["value"] = realQty.toString();
                                          this.hobby[i][3]["value"]["label"] = realQty.toString();
                                          if(this.fBillNo!=""){
                                            var entryIndex;
                                            if(this.hobby[i][0]['FEntryID'] == 0){
                                              entryIndex = this.hobbyItem[this.hobbyItem.indexWhere((v)=> v['number'] == (this.hobby[i][0]['value']['value']+'-'+this.hobby[i][0]['parseEntryID'].toString()))]['index'];
                                            }else{
                                              entryIndex = this.hobbyItem[this.hobbyItem.indexWhere((v)=> v['number'] == (this.hobby[i][0]['value']['value']+'-'+this.hobby[i][0]['FEntryID'].toString()))]['index'];
                                            }
                                            hobby[entryIndex][0]['value']['surplus'] = (hobby[entryIndex][9]['value']['value'] * 100 - double.parse(this.hobby[i][3]['value']['value']) * 100) / 100;
                                          }
                                          this.hobby[i][j]["value"]["label"] = value;
                                          this.hobby[i][j]['value']["value"] = value;
                                          this.hobby[i][0]['value']['kingDeeCode'][this.hobby[i][0]['value']['kingDeeCode'].length - 1] = kingDeeCode[0] + "-" + value + "-" + kingDeeCode[2];
                                        } else {
                                          ToastUtil.showInfo('无条码信息，输入失败');
                                        }
                                      }else{
                                        this._textNumber3[i].text = this.hobby[i][j]["value"]["value"];
                                        ToastUtil.showInfo('输入数量大于可用数量');
                                      }
                                    }else{
                                      this._textNumber3[i].text = this.hobby[i][j]["value"]["value"];
                                      ToastUtil.showInfo('输入数量大于条码可用数量');
                                    }
                                  }
                                  setState(() {

                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: '请输入',
                                  contentPadding: EdgeInsets.all(0),
                                ),
                              ),
                            ),
                          ])),
                ),
                divider,
              ]),
            );
            if(this._textNumber3[i].text == null || this._textNumber3[i].text == ''){
              this._textNumber3[i].text = this.hobby[i][j]["value"]["label"];
            }
          }else /*if (j == 10) {
            comList.add(
              Column(children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                      title: Text(this.hobby[i][j]["title"] +
                          '：' +
                          this.hobby[i][j]["value"]["label"].toString()+'剩余('+this.hobby[i][j]["value"]["remainder"].toString()+')'),
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
          }else*/ if (j == 4) {
            comList.add(
              _item('仓库:', stockList, this.hobby[i][j]['value']['label'],
                  this.hobby[i][j],
                  stock: this.hobby[i]),
            );
          }else if (j == 1) {
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
                              icon: new Icon(Icons.chevron_right),
                              onPressed: () {
                                this.controller.clear();
                                this.bagList = [];
                                for(var element in this.bagListObj){
                                  this.bagList.add(element[1]);
                                }
                                _showMultiChoiceModalBottomSheet(context, this.bagList,  this.hobby[i][j]);
                              },
                            ),
                          ])),
                ),
                divider,
              ]),
            );
          } else if ( j == 11) {
            comList.add(
              Column(children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                      title: Text(this.hobby[i][j]["title"]),
                      trailing:
                      Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                        SizedBox(
                          width: 100,  // 设置固定宽度
                          child: TextField(

                            controller: _textNumber2[i], // 文本控制器
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              if(value == ''){
                                this._textNumber2[i].text = "0";
                                value = "0";
                                this._textNumber2[i].selection = TextSelection(baseOffset: 0, extentOffset: this._textNumber2[i].text.length);
                              }
                              setState(() {
                                if(this.hobby[i][3]['value']['value'] != '0'){
                                  var realQty = 0.0;
                                  realQty = double.parse(this.hobby[i][3]["value"]["label"]) / double.parse(value);
                                  this.hobby[i][12]["value"]["value"] = (realQty.ceil()).toString();
                                  this.hobby[i][12]["value"]["label"] = (realQty.ceil()).toString();
                                  this.hobby[i][j]["value"]
                                  ["label"] = value;
                                  this.hobby[i][j]['value']
                                  ["value"] = value;
                                }else{
                                  this._textNumber2[i].text = this.hobby[i][j]["value"]["value"];
                                  ToastUtil.showInfo('请输入出库数量');
                                }
                              });
                            },
                            decoration: InputDecoration(
                              hintText: '请输入',
                              contentPadding: EdgeInsets.all(0),
                            ),
                          ),
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
          }else if (j == 7) {
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
                  codeFEntityItem['FEntryStockID'] = {
                    "FNUMBER": this.hobby[i][4]['value']['value']
                  };
                  if (this.hobby[i][6]['value']['hide']) {
                    codeFEntityItem['FStockLocNumber'] = this.hobby[i][6]['value']['value'];
                    Map<String, dynamic> stockMap = Map();
                    stockMap['FormId'] = 'BD_STOCK';
                    stockMap['FieldKeys'] =
                    'FFlexNumber';
                    stockMap['FilterString'] = "FNumber = '" +
                        this.hobby[i][4]['value']['value'] +
                        "'";
                    Map<String, dynamic> stockDataMap = Map();
                    stockDataMap['data'] = stockMap;
                    String res = await CurrencyEntity.polling(stockDataMap);
                    var stockRes = jsonDecode(res);
                    if (stockRes.length > 0) {
                      var postionList = this.hobby[i][6]['value']['value'].split(".");
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
                  codeFEntityItem['FBillDate'] = FDate;
                  codeFEntityItem['FOutQty'] = itemCode[1];
                  codeFEntityItem['FEntryBillNo'] = orderDate[0][0];

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
          //auditOrder(auditMap);
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
                  codeFEntityItem['FEntryBillNo'] = orderDate[0][0];
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
    Model['F_UUAC_Combo_ca9'] = "1";
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
    this.hobbyItem = [];
    for(var i = 0;i<this.hobby.length;i++){
      if(this.hobbyItem.length==0){
        Map<String, dynamic> hobbyMap = Map();
        hobbyMap['number'] = this.hobby[i][0]['value']['value']+"-"+this.hobby[i][0]['FEntryID'].toString();
        hobbyMap['index'] = i;
        this.hobbyItem.add(hobbyMap);
      }else if(this.hobby[i][0]['FEntryID'] != 0){
        Map<String, dynamic> hobbyMap = Map();
        hobbyMap['number'] = this.hobby[i][0]['value']['value']+"-"+this.hobby[i][0]['FEntryID'].toString();
        hobbyMap['index'] = i;
        this.hobbyItem.add(hobbyMap);
      }
    }
    for (var element in this.hobby) {
  /*    for (var collarOrder in orderDataList) {
        if (collarOrder[3] == element[0]['value']['value']) {*/
          if (element[3]['value']['value'] != '0' && element[3]['value']['value'] != '' &&
              element[4]['value']['value'] != '') {
            /*var itemList = element[13]['value']['itemList'];
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
              FEntityItem['FActualQty'] = childDetail[2];
              FEntityItem['FSNQty'] = childDetail[2];
              FEntityItem['F_UUAC_Qty_ca9'] = element[12]['value']['value'];
              FEntityItem['FStockId'] = {"FNumber": element[4]['value']['value']};
              FEntityItem['FLot'] = {"FNumber": childDetail[0]};
              if(childDetail[1] !="无"){
                FEntityItem['FAuxPropId'] = {
                  "FAUXPROPID__FF100002": {"FNumber": childDetail[1]}
                };
              }
              FEntity.add(FEntityItem);
              itemNumber++;
            }*/
            Map<String, dynamic> FEntityItem = Map();
            var entryIndex;

            if(element[0]['FEntryID'] == 0){
              entryIndex = this.hobbyItem[this.hobbyItem.indexWhere((v)=> v['number'] == (element[0]['value']['value']+'-'+element[0]['parseEntryID'].toString()))]['index'];
              print(this.hobbyItem);
              print(element[0]['value']['value']);
              print(element[0]['parseEntryID']);
              print(entryIndex);
              FEntityItem['FParentMaterialId'] = {"FNumber": this.hobby[entryIndex][0]['FParentMaterialId']};
              FEntityItem['FEntryWorkShopId'] = {"FNumber": this.hobby[entryIndex][0]['FEntryWorkShopId']};
              FEntityItem['FMoEntryId'] = this.hobby[entryIndex][0]['FMoEntryId'];
              FEntityItem['FPPBomEntryId'] = this.hobby[entryIndex][0]['FPPBomEntryId'];
              FEntityItem['FMaterialId'] = {"FNumber": element[0]['value']['value']};
              FEntityItem['FOwnerId'] = {"FNumber": this.hobby[entryIndex][0]['FOwnerId']};
              FEntityItem['FParentOwnerId'] = {"FNumber": this.hobby[entryIndex][0]['FParentOwnerId']};
              FEntityItem['FUnitID'] = {"FNumber": this.hobby[entryIndex][0]['FUnitID']};
              FEntityItem['FBaseUnitId'] = {"FNumber": this.hobby[entryIndex][0]['FBaseUnitId']};
              FEntityItem['FStockUnitId'] = {"FNumber": this.hobby[entryIndex][0]['FStockUnitId']};
              FEntityItem['FOwnerTypeId'] = this.hobby[entryIndex][0]['FOwnerTypeId'];
              FEntityItem['FMoBillNo'] =  this.hobby[entryIndex][0]['FMoBillNo'];
              FEntityItem['FKeeperTypeId'] = this.hobby[entryIndex][0]['FKeeperTypeId'];
              FEntityItem['FParentOwnerTypeId'] = this.hobby[entryIndex][0]['FParentOwnerTypeId'];
              FEntityItem['FKeeperId'] = {"FNumber": this.hobby[entryIndex][0]['FKeeperId']};
              FEntityItem['FEntity_Link'] = [
                {
                  "FEntity_Link_FRuleId": "PRD_IssueMtr2PickMtrl",
                  "FEntity_Link_FSTableName": "T_PRD_PPBOMENTRY",
                  "FEntity_Link_FSBillId": this.hobby[entryIndex][0]['FEntrySrcInterId'],
                  "FEntity_Link_FSId": this.hobby[entryIndex][0]['FPPBomEntryId'],
                  "FEntity_Link_FBaseActualQty": element[3]['value']['value']
                }
              ];
            }
            FEntityItem['FEntryID'] = element[0]['FEntryID'];
            FEntityItem['FActualQty'] = element[3]['value']['value'];
            if(element[0]['FIsKFPeriod']){
              FEntityItem['FProduceDate'] = element[14]['value']['value'];
              FEntityItem['FExpiryDate'] = element[15]['value']['value'];
            }
            FEntityItem['FSNQty'] = element[3]['value']['value'];
            FEntityItem['FStockId'] = {"FNumber": element[4]['value']['value']};
            if (element[6]['value']['hide']) {
              Map<String, dynamic> stockMap = Map();
              stockMap['FormId'] = 'BD_STOCK';
              stockMap['FieldKeys'] =
              'FFlexNumber';
              stockMap['FilterString'] = "FNumber = '" +
                  element[4]['value']['value'] +
                  "'";
              Map<String, dynamic> stockDataMap = Map();
              stockDataMap['data'] = stockMap;
              String res = await CurrencyEntity.polling(stockDataMap);
              var stockRes = jsonDecode(res);
              if (stockRes.length > 0) {
                var postionList = element[6]['value']['value'].split(".");
                FEntityItem['FStockLocId'] = {};
                var positonIndex = 0;
                for(var dimension in postionList){
                  FEntityItem['FStockLocId']["FSTOCKLOCID__" + stockRes[positonIndex][0]] = {
                    "FNumber": dimension
                  };
                  positonIndex++;
                }
              }
            }
            FEntityItem['FStockStatusId'] = {"FNumber": "KCZT01_SYS"};
            FEntityItem['FLot'] = {"FNumber": element[5]['value']['value']};
            FEntityItem['FAuxPropId'] = {
              "FAUXPROPID__FF100002": {"FNumber": element[1]['value']['value']}
            };
            FEntityItem['F_UUAC_Qty_ca9'] = element[12]['value']['value'];
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
          }
       /* }*/
      /*}*/
      hobbyIndex++;
    };
    if (FEntity.length == 0) {
      this.isSubmit = false;
      ToastUtil.showInfo('请输入数量和包数');
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
