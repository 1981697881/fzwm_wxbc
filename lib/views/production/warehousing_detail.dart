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
import 'package:intl/intl.dart';
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
  var storehouseName;
  var storehouseNumber;
  var showPosition = false;
  var storingLocationName;
  var storingLocationNumber;
  var checkData;
  var fOrgID;
  var checkDataChild;
  var isTurnoff;
//包装规格
  var bagList = [];
  var hobbyItem = [];
  List<dynamic> bagListObj = [];
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
  final controller = TextEditingController();
  List<TextEditingController> _textNumber2 = [];
  _WarehousingDetailState(fBillNo) {
    this.FBillNo = fBillNo['value'];
    this.getOrderPush();
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
    getBagList();
    /* getWorkShop();*/
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
        "FForbidStatus = 'A' and FDocumentStatus = 'C' and FUseOrgId.FNumber ='" + fOrgID + "'";//
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
    super.dispose();
    /// 取消监听
    if (_subscription != null) {
      _subscription!.cancel();
    }
  }

  // 查询数据集合
  List hobby = [];
  List fNumber = [];
  getOrderPush() async{
      await getStockList();
      Map<String, dynamic> userMap = Map();
      userMap['FilterString'] = "FBillNo='$FBillNo'";
      userMap['FormId'] = 'PRD_MORPT';
      userMap['OrderString'] = 'FMaterialId.FNumber ASC';
      userMap['FieldKeys'] =
      'FEntity_FEntryId,FID';
      Map<String, dynamic> dataMap = Map();
      dataMap['data'] = userMap;
      String pushOrder = await CurrencyEntity.polling(dataMap);
      orderDate = [];
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
      var pushData = jsonDecode(pushOrder);
      if (pushData.length > 0) {
        var resAlter = await this.alterOrder(pushData);
        if(!resAlter['isBool']){
          setState(() {
            ToastUtil.errorDialog(context, resAlter['msg']);
            this.isSubmit = false;
          });
          return;
        };
        var EntryIds = '';
        var hobbyIndex = 0;
        pushData.forEach((element) {
          if (EntryIds == '') {
            EntryIds = pushData[hobbyIndex][0].toString();
          } else {
            EntryIds = EntryIds + ',' + pushData[hobbyIndex][0].toString();
          }
          hobbyIndex++;
        });
        //下推
        Map<String, dynamic> pushMap = Map();
        /*pushMap['EntryIds'] = EntryIds;*/
        pushMap['Ids'] = jsonDecode(pushOrder)[0][1];
        pushMap['RuleId'] = "PRD_MORPT2INSTOCK";
        pushMap['TargetFormId'] = "PRD_INSTOCK";
        pushMap['IsEnableDefaultRule'] = "false";
        pushMap['IsDraftWhenSaveFail'] = "true";
        var datass = pushMap.toString();
        var downData =
        await SubmitEntity.pushDown({"formid": "PRD_MORPT", "data": pushMap});
        print(downData);
        var res = jsonDecode(downData);
        //判断成功
        if (res['Result']['ResponseStatus']['IsSuccess']) {
          //查询生产入库
          var entitysNumber =
          res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id'];
          this.getOrderList(res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']);
        } else {
          setState(() {
              ToastUtil.errorDialog(
                  context, res['Result']['ResponseStatus']['Errors'][0]['Message']);
          });
        }
      } else {
        ToastUtil.showInfo('无数据');
      }
  }

  getOrderList(fid) async {
      Map<String, dynamic> userMap = Map();
      userMap['FilterString'] = "FID='$fid'";
        userMap['FormId'] = 'PRD_INSTOCK';
      userMap['OrderString'] = 'FMaterialId.FNumber ASC';
      userMap['FieldKeys'] =
          'FBillNo,FPrdOrgId.FNumber,FPrdOrgId.FName,FDate,FMoBillNo,FEntity_FEntryId,FMaterialId.FNumber,FMaterialId.FName,FMaterialId.FSpecification,FWorkShopId1.FNumber,FWorkShopId1.FName,FUnitId.FNumber,FUnitId.FName,FMustQty,FProduceDate,FExpiryDate,FSrcBillNo,FRealQty,FID,FDocumentStatus,FStockId.FNumber,FStockId.FName,FStockOrgId.FNumber,FMaterialId.FIsBatchManage,FAuxPropId.FF100002.FNumber,FMaterialId.FIsKFPeriod,FMoEntryId,FStockUnitId.FNumber,FOwnerId.FNumber,FBaseUnitId.FNumber,FOwnerTypeId,FMoBillNo,FKeeperTypeId,FKeeperId.FNumber,FStockStatusId.FNumber,FMoId,FMoEntrySeq,FEntity_FSeq,FBFLowId,FSrcInterId,FSrcEntryId,FSrcEntrySeq,FShiftGroupId.FNumber';
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
      print(selectData[DateMode.YMD].toString());
      orderDate = jsonDecode(order);
      if (orderDate.length > 0) {
        this.FSaleOrderNo = orderDate[0][0];
        for(var value in orderDate){
          fNumber.add(value[5]);
          List arr = [];
          arr.add({
            "title": "物料名称",
            "name": "FMaterial",
            "FEntryID": value[5],
            "FID": value[18],
            "FMoEntryId": value[26],
            "FStockUnitId": value[27],
            "FWorkShopId1": value[9],
            "FOwnerId": value[28],
            "FBaseUnitId": value[29],
            "FOwnerTypeId": value[30],
            "FMoBillNo": value[31],
            "FKeeperTypeId": value[32],
            "FKeeperId": value[33],
            "FIsKFPeriod": value[25],
            "FMoId": value[35],
            "FMoEntrySeq": value[36],
            "FEntity_FSeq": value[37],
            "FBFLowId": value[38],
            "FSrcInterId": value[39],
            "FSrcEntryId": value[40],
            "FSrcEntrySeq": value[41],
            "FShiftGroupId": value[42],
            "parseEntryID": -1,
            "isHide": false,
            "value": {
              "label": value[7] + "- (" + value[6] + ")",
              "value": value[6],
              "barcode": [],
              "surplus": value[13],
              "kingDeeCode": [],
              "scanCode": []
            }
          });
          arr.add({
            "title": "包装规格",
            "isHide": false,
            "name": "FMaterialIdFSpecification",
            "value": {"label": "", "value": ""}
            //"value": {"label": value[24]==null?"":value[24], "value": value[24]==null?"":value[24]}
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
            "value": {"label": "", "value": "0"}
          });
           Map<String, dynamic> inventoryMap = Map();
          inventoryMap['FormId'] = 'QDEP_Cust_BarCodeList';
          inventoryMap['FilterString'] = "FMATERIALID.FNUMBER='" + value[6] + "' and FEntryBillNo like '%ZJDB%' and FStockLocNumber != '' and FInQty>0 and FEntryStockID.FNumber='WXBC01'";
          inventoryMap['OrderString'] = 'FBillDate DESC';
          inventoryMap['FieldKeys'] =
          'FEntryStockID.FName,FEntryStockID.FNumber,FPackageSpec,FProduceDate,FExpiryDate,FStockLocNumber,FEntryStockID.FIsOpenLocation,FBillDate,FBarCode';
          Map<String, dynamic> inventoryDataMap = Map();
          inventoryDataMap['data'] = inventoryMap;
          String res = await CurrencyEntity.polling(inventoryDataMap);
          var stocks = jsonDecode(res);
          if (stocks.length > 0) {
            arr.add({
              "title": "仓库",
              "name": "FStockID",
              "isHide": false,
              "value": {"label": "", "value": "","sellLabel": stocks[0][0], "sellValue": stocks[0][1]}
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
              "value": {"label": "", "value": "", "hide": stocks[0][6], "sellLabel": stocks[0][5], "sellValue": stocks[0][5]}
            });
          }else{
            arr.add({
              "title": "仓库",
              "name": "FStockID",
              "isHide": false,
              "value": {"label": "", "value": "","sellLabel": "", "sellValue": ""}
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
              "value": {"label": "", "value": "", "hide": false,"sellLabel": "", "sellValue": ""}
            });
          }
          arr.add({
            "title": "操作",
            "name": "",
            "isHide": false,
            "value": {"label": "", "value": ""}
          });
          arr.add({
            "title": "生产日期",
            "name": "",
            "isHide": !value[25],
            "value": {"label": "", "value": ""} //selectData[DateMode.YMD].toString()
          });
          arr.add({
            "title": "应收数量",
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
      //_onEvent("31052;AQ50422102N1南;2025-04-22;1000;MO003135,1535233400;3");
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
    if(checkItem == "position" || checkItem == 'HPoc'){
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
          barcodeMap['FilterString'] = "FPackageNo='" + event + "'";
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
          barcodeMap['OrderString'] = 'FBillDate ASC';
          barcodeMap['FormId'] = 'QDEP_Cust_BarCodeList';
          barcodeMap['FieldKeys'] =
          'FID,FInQtyTotal,FOutQtyTotal,FEntity_FEntryId,FRemainQty,FBarCodeQty,FStockID.FName,FStockID.FNumber,FMATERIALID.FNUMBER,FOwnerID.FNumber,FBarCode,FSN,FPackageSpec,FProduceDate,FExpiryDate,FStockLocNumberH,FStockID.FIsOpenLocation';
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
                  barcodeData, barcodeData[0][10], barcodeData[0][11], barcodeData[0][13].substring(0, 10), barcodeData[0][14].substring(0, 10), barcodeData[0][15].trim(),barcodeData[0][16]);
            } else {
              ToastUtil.showInfo(msg);
            }
          } else {
            ToastUtil.showInfo('条码不在条码清单中');
          }
        }
      } else {
        _code = event;
        this.getMaterialList("", _code, "", "", "", "",false);
        print("ChannelPage: $event");
      }
    }
  }

  getMaterialList(barcodeData, code, fsn, fProduceDate, fExpiryDate, fLoc,fIsOpenLocation) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var tissue = sharedPreferences.getString('tissue');
    var scanCode = code.split(";");
    //重置
    this.storehouseName = '';
    this.storehouseNumber = '';
    this.showPosition = false;
    this.storingLocationName = '';
    this.storingLocationNumber = '';
    if(fIsOpenLocation && fLoc != ''){
      this.storehouseName = barcodeData[0][6] == null? '':barcodeData[0][6];
      this.storehouseNumber = barcodeData[0][7] == null? '':barcodeData[0][7];
      this.showPosition = fIsOpenLocation;
      this.storingLocationName = fLoc;
      this.storingLocationNumber = fLoc;
    }
    userMap['FilterString'] = "FNumber='" +
        scanCode[0] +
        "' and FForbidStatus = 'A' and FUseOrgId.FNumber = '" +
        tissue +
        "'";
    userMap['FormId'] = 'BD_MATERIAL';
    userMap['FieldKeys'] =
        'FMATERIALID,FName,FNumber,FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FIsBatchManage,FIsKFPeriod'; /*F_UUAC_Text,SubHeadEntity1.FStoreUnitID.FNumber*/
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
      var barCodeScan = [];
      if (fBarCodeList == 1) {
        barCodeScan = barcodeData[0];
        barCodeScan[5] = barCodeScan[5].toString();
      } else {
        barCodeScan = scanCode;
      }
      var barcodeNum = scanCode[3];
      var barcodeQuantity = scanCode[3];
      var residue = double.parse(scanCode[3]);
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
        print(entryIndex);
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
                    element[4]['value']['label'] = this.storehouseName == null? "":this.storehouseName;
                    element[4]['value']['value'] =this.storehouseNumber == null? "":this.storehouseNumber;
                  }
                  if(this.showPosition){
                    element[6]['value']['hide'] = this.showPosition;
                    if (element[6]['value']['value'] == "") {
                      element[6]['value']['label'] = this.storingLocationName == null? "":this.storingLocationName;
                      element[6]['value']['value'] =this.storingLocationNumber == null? "":this.storingLocationNumber;
                    }
                  }
                  if (element[1]['value']['value'] == "") {
                    element[1]['value']['label'] = barcodeData[0][12] == null? "":barcodeData[0][12];
                    element[1]['value']['value'] =barcodeData[0][12] == null? "":barcodeData[0][12];
                  }
                  if (element[8]['value']['value'] == "") {
                    element[8]['value']['label'] = fProduceDate == null? "":fProduceDate;
                    element[8]['value']['value'] =fProduceDate == null? "":fProduceDate;
                  }

                  //判断是否启用保质期
                  if (!element[8]['isHide']) {
                    if (element[8]['value']['value'] == fProduceDate) {
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
                  //判断仓库
                  if (element[4]['value']['value'] == storehouseNumber) {
                    errorTitle = "";
                  } else {
                    errorTitle = "仓库不一致";
                    surplus = hobby[entryIndex][0]['value']['surplus'];
                    parseEntryID = hobby[entryIndex][0]['FEntryID'];
                    fIsKFPeriod = hobby[entryIndex][0]['FIsKFPeriod'];
                    insertIndex = hobbyIndex;
                    continue;
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
                  if (element[1]['value']['label'] == barcodeData[0][12]) {
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
                  barcodeNum =
                      (double.parse(barcodeNum) - double.parse(barcodeNum))
                          .toString();
                }
                number++;
                break;
              }
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
                      element[4]['value']['label'] = this.storehouseName == null? "":this.storehouseName;
                      element[4]['value']['value'] =this.storehouseNumber == null? "":this.storehouseNumber;
                    }
                    if(this.showPosition){
                      element[6]['value']['hide'] = this.showPosition;
                      if (element[6]['value']['value'] == "") {
                        element[6]['value']['label'] = this.storingLocationName == null? "":this.storingLocationName;
                        element[6]['value']['value'] =this.storingLocationNumber == null? "":this.storingLocationNumber;
                      }
                    }
                    if (element[1]['value']['value'] == "") {
                      element[1]['value']['label'] = barcodeData[0][12] == null? "":barcodeData[0][12];
                      element[1]['value']['value'] =barcodeData[0][12] == null? "":barcodeData[0][12];
                    }
                    if (element[8]['value']['value'] == "") {
                      element[8]['value']['label'] = fProduceDate == null? "":fProduceDate;
                      element[8]['value']['value'] =fProduceDate == null? "":fProduceDate;
                    }

                    //判断是否启用保质期
                    if (!element[8]['isHide']) {
                      if (element[8]['value']['value'] == fProduceDate) {
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
                    //判断仓库
                    if (element[4]['value']['value'] == storehouseNumber) {
                      errorTitle = "";
                    } else {
                      errorTitle = "仓库不一致";
                      surplus = hobby[entryIndex][0]['value']['surplus'];
                      parseEntryID = hobby[entryIndex][0]['FEntryID'];
                      fIsKFPeriod = hobby[entryIndex][0]['FIsKFPeriod'];
                      insertIndex = hobbyIndex;
                      continue;
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
                    if (element[1]['value']['label'] == barcodeData[0][12]) {
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
                      residue = (residue * 100 -
                              double.parse(element[10]['value']['value']) *
                                  100) /
                          100;
                      element[0]['value']['surplus'] =
                          (hobby[entryIndex][9]['value']['value'] * 100 -
                                  double.parse(element[3]['value']['value']) *
                                      100) /
                              100;
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
                      element[3]['value']['label'] =
                          (double.parse(element[3]['value']['value']) +
                              residue)
                              .toString();
                      element[3]['value']['value'] =
                      element[3]['value']['label'];
                      residue = 0.0;
                      hobby[entryIndex][0]['value']['surplus'] =
                          (hobby[entryIndex][9]['value']['value'] * 100 -
                              double.parse(element[3]['value']['value']) *
                                  100) /
                              100;
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

                      element[3]['value']['label'] = (hobby[entryIndex][0]['value']['surplus'] +
                          double.parse(element[3]['value']['value']))
                          .toString();
                      element[3]['value']['value'] =
                      element[3]['value']['label'];
                      residue = (residue * 100 -
                          double.parse(element[10]['value']['value']) *
                              100) /
                          100;
                      hobby[entryIndex][0]['value']['surplus'] =
                          (hobby[entryIndex][9]['value']['value'] * 100 -
                              double.parse(element[3]['value']['value']) *
                                  100) /
                              100;
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
                    element[4]['value']['label'] = this.storehouseName == null? "":this.storehouseName;
                    element[4]['value']['value'] =this.storehouseNumber == null? "":this.storehouseNumber;
                  }
                  if(this.showPosition){
                    element[6]['value']['hide'] = this.showPosition;
                    if (element[6]['value']['value'] == "") {
                      element[6]['value']['label'] = this.storingLocationName == null? "":this.storingLocationName;
                      element[6]['value']['value'] =this.storingLocationNumber == null? "":this.storingLocationNumber;
                    }
                  }
                  if (element[1]['value']['value'] == "") {
                    element[1]['value']['label'] = barcodeData[0][12] == null? "":barcodeData[0][12];
                    element[1]['value']['value'] =barcodeData[0][12] == null? "":barcodeData[0][12];
                  }

                  if (element[5]['value']['value'] == "") {
                    element[5]['value']['label'] = scanCode[1];
                    element[5]['value']['value'] = scanCode[1];
                  }
                  if (element[8]['value']['value'] == "") {
                    element[8]['value']['label'] = fProduceDate == null? "":fProduceDate;
                    element[8]['value']['value'] =fProduceDate == null? "":fProduceDate;
                  }

                  //判断是否启用保质期
                  if (!element[8]['isHide']) {
                    if (element[8]['value']['value'] == fProduceDate) {
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
                  //判断仓库
                  if (element[4]['value']['value'] == storehouseNumber) {
                    errorTitle = "";
                  } else {
                    errorTitle = "仓库不一致";
                    surplus = hobby[entryIndex][0]['value']['surplus'];
                    parseEntryID = hobby[entryIndex][0]['FEntryID'];
                    fIsKFPeriod = hobby[entryIndex][0]['FIsKFPeriod'];
                    insertIndex = hobbyIndex;
                    continue;
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
                  if (element[1]['value']['label'] == barcodeData[0][12]) {
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
                  barcodeNum =
                      (double.parse(barcodeNum) - double.parse(barcodeNum))
                          .toString();
                }
                number++;
                break;
              }
              if (element[5]['value']['value'] == scanCode[1]) {
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

                      if (element[1]['value']['value'] == "") {
                        element[1]['value']['label'] = barcodeData[0][12] == null? "":barcodeData[0][12];
                        element[1]['value']['value'] =barcodeData[0][12] == null? "":barcodeData[0][12];
                      }
                      if (element[8]['value']['value'] == "") {
                        element[8]['value']['label'] = fProduceDate == null? "":fProduceDate;
                        element[8]['value']['value'] =fProduceDate == null? "":fProduceDate;
                      }
                      if (element[4]['value']['value'] == "") {
                        element[4]['value']['label'] = this.storehouseName == null? "":this.storehouseName;
                        element[4]['value']['value'] =this.storehouseNumber == null? "":this.storehouseNumber;
                      }
                      if(this.showPosition){
                        element[6]['value']['hide'] = this.showPosition;
                        if (element[6]['value']['value'] == "") {
                          element[6]['value']['label'] = this.storingLocationName == null? "":this.storingLocationName;
                          element[6]['value']['value'] =this.storingLocationNumber == null? "":this.storingLocationNumber;
                        }
                      }
                      //判断是否启用保质期
                      if (!element[8]['isHide']) {
                        if (element[8]['value']['value'] == fProduceDate) {
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
                      //判断仓库
                      if (element[4]['value']['value'] == storehouseNumber) {
                        errorTitle = "";
                      } else {
                        errorTitle = "仓库不一致";
                        surplus = hobby[entryIndex][0]['value']['surplus'];
                        parseEntryID = hobby[entryIndex][0]['FEntryID'];
                        fIsKFPeriod = hobby[entryIndex][0]['FIsKFPeriod'];
                        insertIndex = hobbyIndex;
                        continue;
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
                      if (element[1]['value']['label'] == barcodeData[0][12]) {
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
                        residue = (residue * 100 -
                                double.parse(element[10]['value']['value']) *
                                    100) /
                            100;
                        element[0]['value']['surplus'] =
                            (hobby[entryIndex][9]['value']['value'] * 100 -
                                    double.parse(element[3]['value']['value']) *
                                        100) /
                                100;
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
                        element[3]['value']['label'] =
                            (double.parse(element[3]['value']['value']) +
                                residue)
                                .toString();
                        element[3]['value']['value'] =
                        element[3]['value']['label'];
                        residue = 0.0;
                        hobby[entryIndex][0]['value']['surplus'] = (hobby[entryIndex][9]['value']
                        ['value'] *
                            100 -
                            double.parse(element[3]['value']['value']) *
                                100) /
                            100;
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
                        element[3]['value']['label'] = (hobby[entryIndex][0]['value']['surplus'] +
                            double.parse(element[3]['value']['value']))
                            .toString();
                        element[3]['value']['value'] =
                        element[3]['value']['label'];
                        residue = (residue * 100 -
                            double.parse(element[10]['value']['value']) *
                                100) /
                            100;
                        hobby[entryIndex][0]['value']['surplus'] = (hobby[entryIndex][9]['value']
                        ['value'] *
                            100 -
                            double.parse(element[3]['value']['value']) *
                                100) /
                            100;
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
                          element[4]['value']['label'] = this.storehouseName == null? "":this.storehouseName;
                          element[4]['value']['value'] =this.storehouseNumber == null? "":this.storehouseNumber;
                        }
                        if(this.showPosition){
                          element[6]['value']['hide'] = this.showPosition;
                          if (element[6]['value']['value'] == "") {
                            element[6]['value']['label'] = this.storingLocationName == null? "":this.storingLocationName;
                            element[6]['value']['value'] =this.storingLocationNumber == null? "":this.storingLocationNumber;
                          }
                        }
                        if (element[1]['value']['value'] == "") {
                          element[1]['value']['label'] = barcodeData[0][12] == null? "":barcodeData[0][12];
                          element[1]['value']['value'] =barcodeData[0][12] == null? "":barcodeData[0][12];
                        }
                        if (element[8]['value']['value'] == "") {
                          element[8]['value']['label'] = fProduceDate == null? "":fProduceDate;
                          element[8]['value']['value'] =fProduceDate == null? "":fProduceDate;
                        }

                        //判断是否启用保质期
                        if (!element[8]['isHide']) {
                          print(element[8]['value']['value']);
                          print(fProduceDate);
                          if (element[8]['value']['value'] == fProduceDate) {
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
                        //判断仓库
                        if (element[4]['value']['value'] == storehouseNumber) {
                          errorTitle = "";
                        } else {
                          surplus = hobby[entryIndex][0]['value']['surplus'];
                          parseEntryID = hobby[entryIndex][0]['FEntryID'];
                          fIsKFPeriod = hobby[entryIndex][0]['FIsKFPeriod'];
                          insertIndex = hobbyIndex;
                          errorTitle = "仓库不一致";
                          continue;
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
                        if (element[1]['value']['label'] == barcodeData[0][12]) {
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
                          residue = (residue * 100 -
                                  double.parse(element[10]['value']['value']) *
                                      100) /
                              100;
                          element[0]['value']['surplus'] = (hobby[entryIndex][9]['value']
                                          ['value'] *
                                      100 -
                                  double.parse(element[3]['value']['value']) *
                                      100) /
                              100;
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
                          element[3]['value']['label'] =
                              (double.parse(element[3]['value']['value']) +
                                  residue)
                                  .toString();
                          element[3]['value']['value'] =
                          element[3]['value']['label'];
                          residue = 0.0;
                          hobby[entryIndex][0]['value']['surplus'] = (hobby[entryIndex][9]
                          ['value']['value'] *
                              100 -
                              double.parse(element[3]['value']['value']) *
                                  100) /
                              100;
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

                          element[3]['value']['label'] = (hobby[entryIndex][0]['value']['surplus'] +
                              double.parse(element[3]['value']['value']))
                              .toString();
                          element[3]['value']['value'] =
                          element[3]['value']['label'];
                          residue = (residue * 100 -
                              double.parse(
                                  element[10]['value']['value']) *
                                  100) /
                              100;
                          hobby[entryIndex][0]['value']['surplus'] = (hobby[entryIndex][9]
                          ['value']['value'] *
                              100 -
                              double.parse(element[3]['value']['value']) *
                                  100) /
                              100;
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
      if (number == 0) {
        if(surplus == 0 && this.hobby.length == 1){
          surplus = hobby[0][0]['value']['surplus'];
        }
        var inserNum = 0.0;
        print("剩余");
        print(surplus);
        print(barCodeScan[5]);
        if(double.parse(barCodeScan[5]) >= surplus && this.fBillNo!=''){
          inserNum = surplus;
        }else{
          inserNum = double.parse(barCodeScan[5]);
        }
        print(inserNum);
        if(inserNum == 0){
          ToastUtil.showInfo('该物料数量已达上限');
          return;
        }
        for (var value in materialDate) {
          if(this.hobbyItem.indexWhere((v)=> v['number'] == (value[2]+'-'+parseEntryID.toString())) != -1){
            var parentIndex = this.hobbyItem[this.hobbyItem.indexWhere((v)=> v['number'] == (value[2]+'-'+parseEntryID.toString()))]['index'];
            hobby[parentIndex][0]['value']['surplus'] = (surplus - inserNum >0?surplus - inserNum:0);
          }
          List arr = [];
          arr.add({
            "title": "物料名称",
            "name": "FMaterial",
            "FEntryID": 0,
            "parseEntryID": parseEntryID,
            "FIsKFPeriod": fIsKFPeriod,
            "isHide": false,
            "value": {
              "label": value[1] + "- (" + value[2] + ")",
              "value": value[2],
              "surplus": surplus,
              "barcode": [code],
              "kingDeeCode": [barCodeScan[0].toString()+"-"+inserNum.toString()+"-"+fsn],
              "scanCode": [barCodeScan[0].toString()+"-"+inserNum.toString()]
            }
          });
          arr.add({
            "title": "包装规格",
            "isHide": false,
            "name": "FMaterialIdFSpecification",
            "value": {"label": barcodeData[0][12], "value": barcodeData[0][12]}
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
            "value": {"label": inserNum.toString(), "value": inserNum.toString()}
          });
          arr.add({
            "title": "仓库",
            "name": "FStockID",
            "isHide": false,
            "value": {"label": this.storehouseName == null? "":this.storehouseName, "value": this.storehouseNumber == null? "":this.storehouseNumber,"sellLabel": "", "sellValue": ""}
          });
          arr.add({
            "title": "批号",
            "name": "FLot",
            "isHide": value[6] != true,
            "value": {
              "label": value[6]?(scanCode.length>1?scanCode[1]:''):'',
              "value": value[6]?(scanCode.length>1?scanCode[1]:''):''
            }
          });
          arr.add({
            "title": "仓位",
            "name": "FStockLocID",
            "isHide": false,
            "value": {"label": this.storingLocationName == null? "":this.storingLocationName, "value": this.storingLocationNumber == null? "":this.storingLocationNumber, "hide": showPosition,"sellLabel": "", "sellValue": ""}
          });
          arr.add({
            "title": "操作",
            "name": "",
            "isHide": false,
            "value": {"label": "", "value": ""}
          });
          arr.add({
            "title": "生产日期",
            "name": "",
            "isHide": !fIsKFPeriod,
            "value": {"label": fProduceDate == ""?selectData[DateMode.YMD].toString():fProduceDate, "value": fProduceDate == ""?selectData[DateMode.YMD].toString():fProduceDate}
          });
          arr.add({
            "title": "应收数量",
            "name": "",
            "isHide": false,
            "value": {"label": surplus, "value": surplus}
          });
          arr.add({
            "title": "最后扫描数量",
            "name": "FLastQty",
            "isHide": false,
            "value": {
              "label": inserNum.toString(),
              "value": inserNum.toString()
            }
          });
          hobby.insert(insertIndex, arr);
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
        setState(()  {
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
  Widget _dateChildItem(title, model, hobby) {
    GlobalKey<PartRefreshWidgetState> globalKey = GlobalKey();
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: ListTile(
            title: Text(title),
            onTap: () {
              _onDateChildClickItem(model,hobby);
            },
            trailing: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              PartRefreshWidget(globalKey, () {
                //2、使用 创建一个widget
                return MyText(
                    (hobby['value']['value'] == ""
                        ? selectData[model]
                        : formatDate(
                        DateFormat('yyyy-MM-dd')
                            .parse(hobby['value']['label']),
                        [
                          yyyy,
                          "-",
                          mm,
                          "-",
                          dd,
                        ]))!,
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
  void _onDateChildClickItem(model,hobby) {
    Pickers.showDatePicker(
      context,
      mode: model,
      suffix: Suffix.normal(),
      // selectDate: PDuration(month: 2),
      minDate: PDuration(year: 2020, month: 2, day: 10),
      maxDate: PDuration(second: 22),
      selectDate: (hobby['value']['label'] == '' || hobby['value']['label'] == null
          ? PDuration.parse(DateTime.now())
          : PDuration.parse(DateTime.parse(hobby['value']['label']))),
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
          }else if (hobby == 'storehouse') {
            storehouseName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                storehouseNumber = stockListObj[elementIndex][2];
                showPosition = stockListObj[elementIndex][3];
                this.storingLocationName = "";
                this.storingLocationNumber = "";
                for(var hItem in this.hobby){
                  if(hItem[4]['value']['value'] == ""){
                    hItem[4]['value']['label'] = storehouseName;
                    hItem[4]['value']['value'] = storehouseNumber;
                    hItem[6]['value']['hide'] = showPosition;
                  }
                }
              }
              elementIndex++;
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
                stock[6]['value']['hide'] = stockListObj[elementIndex][3];
                stock[6]['value']['value'] = "";
                stock[6]['value']['label'] = "";
                //hobby['value']['dimension'] = stockListObj[elementIndex][4];
              }
              elementIndex++;
            });
          }
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
    /*var selectList = this.hobby;
    for (var select in selectList) {
      for(var item in options){
        if (select[1]['value']['value'] == item[1]) {
          selected.add(item);
        } else {
          selected.remove(item);
        }
      }
    }*/
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
      _textNumber2.add(TextEditingController());
      List<Widget> comList = [];
      for (int j = 0; j < this.hobby[i].length; j++) {
        if (!this.hobby[i][j]['isHide']) {
          if (j==5) {/*j == 3 ||*/
            comList.add(
              Column(children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                      title: Text(this.hobby[i][j]["title"]),
                      trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            SizedBox(
                              width: 150,  // 设置固定宽度
                              child: TextField(
                                  controller: _textNumber2[i], // 文本控制器
                                  decoration: InputDecoration(
                                    hintText: '请输入',
                                    contentPadding: EdgeInsets.all(0),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      this.hobby[i][j]["value"]["label"] = value;
                                      this.hobby[i][j]['value']["value"] = value;
                                    });
                                  }
                              ),
                            ),
                          ])),
                ),
                divider,
              ]),
            );
            if(this._textNumber2[i].text == null || this._textNumber2[i].text == ''){
              this._textNumber2[i].text = this.hobby[i][j]["value"]["label"];
            }
          } else if (j == 1) {
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
        } else if (j == 4) {
            var item = this.hobby[i][j]["value"]["sellLabel"] ==''?'':"("+this.hobby[i][j]["value"]["sellLabel"]+")";
            comList.add(
              _item('仓库:'+item, stockList, this.hobby[i][j]['value']['label'],
                  this.hobby[i][j],
                  stock: this.hobby[i]),
            );
          } else if (j == 6) {
            var item = this.hobby[i][j]["value"]["sellValue"] ==''?'':"("+this.hobby[i][j]["value"]["sellValue"]+")";
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
                        title: Text(this.hobby[i][j]["title"] + item +
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
                                  checkItem = 'position';
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
                            Visibility(
                              visible: false,//this.hobby[i][9]["value"]['value'] != double.parse(this.hobby[i][3]["value"]["value"])
                              child: new FlatButton(
                                color: Colors.blue,
                                textColor: Colors.white,
                                child: new Text('复制行'),
                                onPressed: () {
                                  setState(() {
                                    if(this.hobby[i][3]["value"]["value"] != "0"){
                                      if(double.parse(this.hobby[i][3]["value"]["value"]) < this.hobby[i][9]["value"]['rateValue']){
                                        var orderDataItem = List.from(this.orderDate);
                                        this.orderDate.insert(i, orderDataItem[i]);
                                        //this.fNumber = [];
                                        var childItemNumber = 0;
                                        for(var value in orderDate){
                                          //fNumber.add(value[5]);
                                          if(childItemNumber == i){
                                            List arr = [];
                                            arr.add({
                                              "title": "物料名称",
                                              "name": "FMaterial",
                                              "FEntryID": 0,
                                              "FID": value[18],
                                              "FMoEntryId": value[26],
                                              "FStockUnitId": value[27],
                                              "FWorkShopId1": value[9],
                                              "FOwnerId": value[28],
                                              "FBaseUnitId": value[29],
                                              "FOwnerTypeId": value[30],
                                              "FMoBillNo": value[31],
                                              "FKeeperTypeId": value[32],
                                              "FKeeperId": value[33],
                                              "FIsKFPeriod": value[25],
                                              "parseEntryID": value[5],
                                              "FMoId": value[35],
                                              "FMoEntrySeq": value[36],
                                              "FEntity_FSeq": value[37],
                                              "FBFLowId": value[38],
                                              "isHide": false,
                                              "value": {
                                                "label": value[7] + "- (" + value[6] + ")",
                                                "value": value[6],
                                                "barcode": [],
                                                "surplus": value[13],
                                                "kingDeeCode": [],
                                                "scanCode": []
                                              }
                                            });
                                            arr.add({
                                              "title": "包装规格",
                                              "isHide": false,
                                              "name": "FMaterialIdFSpecification",
                                              "value": {"label": "", "value": ""}
                                              //"value": {"label": value[24]==null?"":value[24], "value": value[24]==null?"":value[24]}
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
                                              "value": {"label": "", "value": "0"}
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
                                              "title": "生产日期",
                                              "name": "",
                                              "isHide": !value[25],
                                              "value": {"label": selectData[DateMode.YMD].toString(), "value": selectData[DateMode.YMD].toString()}
                                            });
                                            arr.add({
                                              "title": "应收数量",
                                              "name": "",
                                              "isHide": false,
                                              "value": {
                                                "label": this.hobby[i][9]["value"]['rateValue'] - double.parse(this.hobby[i][3]["value"]["value"]),
                                                "value": this.hobby[i][9]["value"]['rateValue'] - double.parse(this.hobby[i][3]["value"]["value"]),
                                                "rateValue": this.hobby[i][9]["value"]['rateValue'] - double.parse(this.hobby[i][3]["value"]["value"])
                                              } /*+value[12]*0.1*/
                                            });
                                            arr.add({
                                              "title": "最后扫描数量",
                                              "name": "FLastQty",
                                              "isHide": false,
                                              "value": {"label": "0", "value": "0"}
                                            });
                                            this.hobby[i][9]["value"]['label']=double.parse(this.hobby[i][3]["value"]["value"]);
                                            this.hobby[i][9]["value"]['value']=double.parse(this.hobby[i][3]["value"]["value"]);
                                            this.hobby[i][9]["value"]['rateValue']=double.parse(this.hobby[i][3]["value"]["value"]);
                                            hobby.insert(i, arr);
                                            break;
                                          }
                                          childItemNumber++;
                                        }
                                        this._getHobby();
                                      }else{
                                        ToastUtil.showInfo('当前分录数量已达上限，不可增加行');
                                      }
                                    }else{
                                      ToastUtil.showInfo('为了避免总入库数量统计错误，请先录入当前分录数量再增加行');
                                    }
                                  });
                                },
                              )
                            ),
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
          } /*else if (j == 8) {
            comList.add(
              _dateChildItem('生产日期：', DateMode.YMD, this.hobby[i][j]),
            );
          }*/ else {
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
                            keyboardType: checkItem == "HPoc"?TextInputType.text:(this.hobby[checkData][checkDataChild]["title"]=="批号"? TextInputType.text: TextInputType.number),
                            /*inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                            ],*/
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
                          }else if (checkItem == 'position') {
                            setState(() {
                              this.hobby[checkData][checkDataChild]["value"]
                              ["label"] = _FNumber;
                              this.hobby[checkData][checkDataChild]['value']
                              ["value"] = _FNumber;
                            });
                          }else if(checkItem == "HPoc"){
                            setState(() {
                              this.storingLocationName = _FNumber;
                              this.storingLocationNumber = _FNumber;
                              for(var hItem in this.hobby){
                                if(hItem[6]['value']['hide'] &&  hItem[6]['value']['value'] == ""){
                                  hItem[6]['value']['label'] = storingLocationName;
                                  hItem[6]['value']['value'] = storingLocationNumber;
                                }
                              }
                            });
                          }
                          checkItem = '';
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
  deleteOrder(Map<String, dynamic> map, msg,{var type = 0}) async {
    var subData = await SubmitEntity.delete(map);
    print(subData);
    if (subData != null) {
      var res = jsonDecode(subData);
      if (res != null) {
        if (res['Result']['ResponseStatus']['IsSuccess']) {
          if(type == 1){
            setState(() {
              EasyLoading.dismiss();
            });

          }else{
            setState(() {
              this.isSubmit = false;
              ToastUtil.errorDialog(context, msg);
            });
          }
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
                  codeModel['FPackageSpec'] = this.hobby[i][1]['value']['value'];
                  Map<String, dynamic> codeFEntityItem = Map();
                  codeFEntityItem['FEntryStockID'] = {
                    "FNUMBER": this.hobby[i][4]['value']['value']
                  };
                  if (this.hobby[i][6]['value']['hide']) {
                    codeModel['FStockLocNumberH'] = this.hobby[i][6]['value']['value'];
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
                  codeFEntityItem['FBillDate'] = FDate;
                  codeFEntityItem['FInQty'] = itemCode[1];
                  codeFEntityItem['FEntryBillNo'] = orderDate[0][0];

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

        setState(() {
            this.hobby = [];
            this.orderDate = [];
            this.printData = {};
            this.FBillNo = '';
            this.FSaleOrderNo = '';
          });
          ToastUtil.showInfo('提交成功');
          Navigator.of(context).pop("refresh");
        //提交清空页面
      } else {
        unAuditOrder(
            auditMap, res['Result']['ResponseStatus']['Errors'][0]['Message']);
      }
    }
  }
  //修改汇报单
  alterOrder(pushData) async {
    Map<String, dynamic> dataMap = Map();
    dataMap['formid'] = 'PRD_MORPT';
    Map<String, dynamic> orderMap = Map();
    orderMap['NeedReturnFields'] = [];
    orderMap['IsDeleteEntry'] = false;
    Map<String, dynamic> Model = Map();
    Model['FID'] = pushData[0][1];
    var FEntity = [];
    for (int element = 0; element < pushData.length; element++) {
          // ignore: non_constant_identifier_names
          Map<String, dynamic> FEntityItem = Map();
          FEntityItem['FEntryID'] = pushData[element][0];
          FEntityItem['FStockId'] = {
            "FNumber": stockListObj[0][2]
          };
          FEntity.add(FEntityItem);
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
    var resAlter = await this.alterOrder(orderDate);
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
      Model['F_UUAC_Combo_uky'] = "1";
      Model['FDate'] = FDate;
      // ignore: non_constant_identifier_names
      var FEntity = [];
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
      for (int entity = 0; entity < resData.length; entity++) {
        for (int element = 0; element < this.hobby.length; element++) {
          if (resData[entity][1].toString() == this.hobby[element][0]['value']['value'].toString()) {
            if (this.hobby[element][3]['value']['value'] != '0') {
              // ignore: non_constant_identifier_names
              Map<String, dynamic> FEntityItem = Map();
              FEntityItem['FEntryID'] = resData[entity][0];
              FEntityItem['FInStockType'] = '1';
              FEntityItem['FRealQty'] = this.hobby[element][3]['value']['value'];
              FEntityItem['FProduceDate'] = this.hobby[element][8]['value']['value'];
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

/*//保存
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
  }*/
  //提交
  submitOrder(Map<String, dynamic> submitMap) async {
    //获取登录信息
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var tissue = sharedPreferences.getString('tissue');
    var subData = await SubmitEntity.submit(submitMap);
    print(subData);
    if (subData != null) {
      var res = jsonDecode(subData);
      if (res != null) {
        if (res['Result']['ResponseStatus']['IsSuccess']) {
          var errorMsg = "";
          if (fBarCodeList == 1) {
            print(this.hobby.length);
            for (int i = 0; i < this.hobby.length; i++) {
              if (this.hobby[i][3]['value']['value'] != '0' &&
                  (this.hobby[i][4]['value']['value'] != '' || this.hobby[i][4]['value']['sellValue'] != '')) {
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
                  codeModel['FStockID'] = {"FNUMBER": this.hobby[i][4]['value']['value']};
                  Map<String, dynamic> codeFEntityItem = Map();
                  if(this.hobby[i][4]['value']['value'] == ""){
                    codeFEntityItem['FEntryStockID'] = {
                      "FNUMBER": this.hobby[i][4]['value']['sellValue']
                    };
                  }else{
                    codeFEntityItem['FEntryStockID'] = {
                      "FNUMBER": this.hobby[i][4]['value']['value']
                    };
                  }

                  codeModel['FPackageSpec'] = this.hobby[i][1]['value']['value'];
                  if (this.hobby[i][6]['value']['hide']) {
                    var positionNumber;
                    if(this.hobby[i][6]['value']['value'] == ""){
                      positionNumber = this.hobby[i][6]['value']['sellValue'];
                    }else{
                      positionNumber = this.hobby[i][6]['value']['value'];
                    }
                    codeModel['FStockLocNumberH'] = positionNumber;
                    codeFEntityItem['FStockLocNumber'] = positionNumber;
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
                      var postionList = positionNumber.split(".");
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
                  codeFEntityItem['FBillDate'] = FDate;
                  codeFEntityItem['FInQty'] = itemCode[1];
                  codeFEntityItem['FEntryBillNo'] = orderDate[0][0];
                  var codeFEntity = [codeFEntityItem];
                  codeModel['FEntity'] = codeFEntity;
                  orderCodeMap['Model'] = codeModel;
                  dataCodeMap['data'] = orderCodeMap;
                  var saveData = jsonEncode(dataCodeMap);
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
          setState(() {
            this.hobby = [];
            this.orderDate = [];
            this.printData = {};
            this.FBillNo = '';
            this.FSaleOrderNo = '';
          });
          ToastUtil.showInfo('提交成功');
          Navigator.of(context).pop("refresh");
          //提交清空页面
         /* Map<String, dynamic> auditMap = Map();
          auditMap = {
            "formid": "PRD_INSTOCK",
            "data": {
              'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
            }
          };
          auditOrder(auditMap);*/
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
    dataMap['formid'] = 'PRD_INSTOCK';
    Map<String, dynamic> orderMap = Map();
    orderMap['NeedUpDataFields'] = [
      'FEntity',
      'FSerialSubEntity',
      'FSerialNo'
    ];
    orderMap['NeedReturnFields'] = ['FEntity', 'FSerialSubEntity', 'FSerialNo'];
    orderMap['IsDeleteEntry'] = false;
    Map<String, dynamic> Model = Map();
    Model['FID'] = orderDate[0][18];
    Model['F_UUAC_Combo_uky'] = "1";
    Model['FDate'] = FDate;

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
    var res;
    for (var element in this.hobby) {
      if (element[3]['value']['value'] != '0' && element[3]['value']['value'] != '' &&
          (element[4]['value']['value'] != '' || element[4]['value']['sellValue'] != '')) {
        var FEntity = [];
        Map<String, dynamic> FEntityItem = Map();
        FEntityItem['FEntryID'] = element[0]['FEntryID'];
        var entryIndex;
        if(element[0]['FEntryID'] == 0){
          entryIndex = this.hobbyItem[this.hobbyItem.indexWhere((v)=> v['number'] == (element[0]['value']['value']+'-'+element[0]['parseEntryID'].toString()))]['index'];
          FEntityItem['FIsNew'] = false;
          FEntityItem['FISBACKFLUSH'] = true;
          FEntityItem['FIsFinished'] = false;
          FEntityItem['FMoBillNo'] = this.hobby[entryIndex][0]['FMoBillNo'];
          FEntityItem['FMoId'] = this.hobby[entryIndex][0]['FMoId'];
          FEntityItem['FMOMAINENTRYID'] = this.hobby[entryIndex][0]['FMoEntryId'];
          FEntityItem['FMoEntrySeq'] = this.hobby[entryIndex][0]['FMoEntrySeq'];
          FEntityItem['FMoEntryId'] = this.hobby[entryIndex][0]['FMoEntryId'];

          FEntityItem['FSrcBillType'] = "PRD_MORPT";
          FEntityItem['FProductType'] = "1";
          FEntityItem['FSrcBillNo'] = this.FBillNo;

          FEntityItem['FSrcInterId'] = this.hobby[entryIndex][0]['FSrcInterId'];
          FEntityItem['FSrcEntrySeq'] = this.hobby[entryIndex][0]['FSrcEntrySeq'];
          FEntityItem['FSrcEntryId'] = this.hobby[entryIndex][0]['FSrcEntryId'];


          FEntityItem['FMaterialId'] = {"FNumber": element[0]['value']['value']};
          FEntityItem['FUnitID'] = {"FNumber": element[2]['value']['value']};
          FEntityItem['FStockUnitId'] = {"FNumber": this.hobby[entryIndex][0]['FStockUnitId']};
          FEntityItem['FWorkShopId1'] = {"FNumber": this.hobby[entryIndex][0]['FWorkShopId1']};
          /*FEntityItem['FStockStatusId'] = {"FNumber": "KCZT01_SYS"};*/
          FEntityItem['FOwnerId'] = {"FNumber": this.hobby[entryIndex][0]['FOwnerId']};
          FEntityItem['FBaseUnitId'] = {"FNumber": this.hobby[entryIndex][0]['FBaseUnitId']};
          FEntityItem['FOwnerTypeId'] = this.hobby[entryIndex][0]['FOwnerTypeId'];
          FEntityItem['FKeeperTypeId'] = this.hobby[entryIndex][0]['FKeeperTypeId'];
          FEntityItem['FKeeperId'] = {"FNumber": this.hobby[entryIndex][0]['FKeeperId']};
          FEntityItem['FShiftGroupId'] = {"FNumber": this.hobby[entryIndex][0]['FShiftGroupId']};
          FEntityItem['FEntity_Link'] = [
            {
              "FEntity_Link_FRuleId": "PRD_MORPT2INSTOCK",
              "FEntity_Link_FSTableName": "T_PRD_MORPTENTRY",
              "FEntity_Link_FFlowId": this.hobby[entryIndex][0]['FBFLowId'],
              "FEntity_Link_FFlowLineId": "5",
              "FEntity_Link_FSBillId": this.hobby[entryIndex][0]['FSrcInterId'],
              "FEntity_Link_FSId": this.hobby[entryIndex][0]['FSrcEntryId'],
              "FEntity_Link_FBasePrdRealQty": element[3]['value']['value']
            }
          ];
          FEntityItem['FBFLowId'] = {"FID": this.hobby[entryIndex][0]['FBFLowId']};
        }
        //FEntityItem['FInStockType'] = '1';
        FEntityItem['FBasePrdRealQty'] = element[3]['value']['value'];
        FEntityItem['FRealQty'] = element[3]['value']['value'];
        FEntityItem['FMustQty'] = element[3]['value']['value'];
        if(element[0]['FIsKFPeriod']){
          FEntityItem['FProduceDate'] = element[8]['value']['value'];
        }
        if(element[4]['value']['value'] == ""){
          FEntityItem['FStockId'] = {"FNumber": element[4]['value']['sellValue']};
        }else{
          FEntityItem['FStockId'] = {"FNumber": element[4]['value']['value']};
        }
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
          String resWar = await CurrencyEntity.polling(stockDataMap);
          var stockRes = jsonDecode(resWar);
          if (stockRes.length > 0) {
            var postionList = element[6]['value']['value'] == '' ? element[6]['value']['sellValue'].split(".") : element[6]['value']['value'].split(".");
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
        if (FEntity.length == 0) {
          this.isSubmit = false;
          ToastUtil.showInfo('请输入数量和仓库');
          break;
        }
        Model['FEntity'] = FEntity;
        orderMap['Model'] = Model;
        dataMap['data'] = orderMap;
        var dataParams = jsonEncode(dataMap);
        String order = await SubmitEntity.save(dataMap);
        res = jsonDecode(order);
      }
      hobbyIndex++;
    };
    if (res['Result']['ResponseStatus']['IsSuccess']) {
      Map<String, dynamic> submitMap = Map();
      submitMap = {
        "formid": "PRD_INSTOCK",
        "data": {
          'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
        }
      };
      await submitOrder(submitMap);
    } else {
      setState(() {
        this.isSubmit = false;
        ToastUtil.errorDialog(context,
            res['Result']['ResponseStatus']['Errors'][0]['Message']);
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
                  //submitOder();
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
            title: Text("入库"),
            centerTitle: true,
            leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () async {
                  if(this.FSaleOrderNo != null && this.hobby.length>0){
                    Map<String, dynamic> deleteMap = Map();
                    deleteMap = {
                      "formid": 'PRD_INSTOCK',
                      "data": {
                        'Ids': orderDate[0][18]
                      }
                    };
                    EasyLoading.show(status: '删除下推单据...');
                    await deleteOrder(deleteMap, '删除', type: 1);
                    Navigator.of(context).pop("refresh");
                  }else{
                    Navigator.of(context).pop("refresh");
                  }
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
                          title: Text("入库单号：$FSaleOrderNo"),
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
                  _item('入库仓库', this.stockList, this.storehouseName,
                      'storehouse'),
                  Visibility(
                    maintainSize: false,
                    maintainState: false,
                    maintainAnimation: false,
                    visible: showPosition,
                    child: Column(children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                            title: Text('调入仓位：' +
                                this.storingLocationName.toString()),
                            trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  IconButton(
                                    icon: new Icon(Icons.filter_center_focus),
                                    tooltip: '点击扫描',
                                    onPressed: () {
                                      this._textNumber.text = this
                                          .storingLocationName
                                          .toString();
                                      this._FNumber = this
                                          .storingLocationName
                                          .toString();
                                      checkItem = 'HPoc';
                                      this.show = false;
                                      scanDialog();
                                      if (this.storingLocationName != "") {
                                        this._textNumber.value =
                                            _textNumber.value.copyWith(
                                              text: this
                                                  .storingLocationName
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
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text('入库详细信息：'),
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
