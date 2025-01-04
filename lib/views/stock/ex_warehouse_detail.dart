import 'dart:convert';
import 'package:date_format/date_format.dart';
import 'package:decimal/decimal.dart';
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
class ExWarehouseDetail extends StatefulWidget {
  var FBillNo;

  ExWarehouseDetail({Key ?key, @required this.FBillNo}) : super(key: key);

  @override
  _ExWarehouseDetailState createState() => _ExWarehouseDetailState(FBillNo);
}

class _ExWarehouseDetailState extends State<ExWarehouseDetail> {
  var _remarkContent = new TextEditingController();
  var _deptContent = new TextEditingController();
  GlobalKey<TextWidgetState> textKey = GlobalKey();
  GlobalKey<PartRefreshWidgetState> globalKey = GlobalKey();

  final _textNumber = TextEditingController();
  var checkItem;
  String FBillNo = '';
  String FSaleOrderNo = '';
  String FName = '';
  String FNumber = '';
  String FDate = '';
  var customerName;
  var customerNumber;
  var statusTypeName = '可用';
  var statusTypeNumber = 'KCZT01_SYS';
  var departmentName;
  var departmentNumber;
  var outboundTypeName;
  var outboundTypeNumber;
  var organizationsName;
  var organizationsNumber;
  var typeName;
  var typeNumber;
  var show = false;
  var _checked = false;
  var isSubmit = false;
  var isScanWork = false;
  var checkData;
  var checkDataChild;
  var selectData = {
    DateMode.YMD: "",
  };
  //包装规格
  var bagList = [];
  var hobbyItem = [];
  List<dynamic> bagListObj = [];
  var stockList = [];
  List<dynamic> stockListObj = [];
  var typeList = [];
  List<dynamic> typeListObj = [];
  var departmentList = [];
  List<dynamic> departmentListObj = [];
  var customerList = [];
  List<dynamic> customerListObj = [];
  var organizationsList = [];
  List<dynamic> organizationsListObj = [];
  var outboundTypeList = ['五金出库','样品出库','损耗出库','研发出库','污水处理出库','生产/辅材领用','保密材料出库','研发领用1','称量差异','盘亏出库','报废出库','废品出售','其他出库'];
  List<dynamic> outboundTypeListObj = [['01','五金出库'],['02','样品出库'],['03','损耗出库'],['04','研发出库'],['05','污水处理出库'],['06','生产/辅材领用'],['07','保密材料出库'],['08','研发领用1'],['09','称量差异'],['10','盘亏出库'],['11','报废出库'],['12','废品出售'],['13','其他出库']];
  var statusTypeList = [];
  List<dynamic> statusTypeListObj = [];
  List<dynamic> orderDate = [];
  List<dynamic> materialDate = [];
  List<dynamic> collarOrderDate = [];
  final divider = Divider(height: 1, indent: 20);
  final rightIcon = Icon(Icons.keyboard_arrow_right);
  final scanIcon = Icon(Icons.filter_center_focus);
  static const scannerPlugin =
  const EventChannel('com.shinow.pda_scanner/plugin');
   StreamSubscription ?_subscription;
  var _code;
  var _FNumber;
  String cusName = "";
  var fBillNo;
  var fBarCodeList;
  final controller = TextEditingController();
  _ExWarehouseDetailState(FBillNo) {
    if (FBillNo != null) {
      this.fBillNo = FBillNo['value'];
      this.getOrderList();
      isScanWork = true;
    }else{
      this.fBillNo = '';
      isScanWork = false;
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
   /* getTypeList();*/
    //getOrganizationsList();
    getBagList();
    getCustomer();
    getStockList();
    getDepartmentList();
    getStatusTypeList();

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
  }//获取库存状态
  getStatusTypeList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BD_StockStatus';
    userMap['FieldKeys'] = 'FNumber,FName,FStockStatusId';
    userMap['FilterString'] = "FDocumentStatus = 'C'";
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    statusTypeListObj = jsonDecode(res);
    statusTypeListObj.forEach((element) {
      statusTypeList.add(element[1]);
    });
  }
  //获取部门
  getDepartmentList() async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var tissue = sharedPreferences.getString('tissue');
    userMap['FormId'] = 'BD_Department';
    userMap['FilterString'] = "FUseOrgId.FNumber ='"+tissue+"'";
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
    var tissue = sharedPreferences.getString('tissue');
    userMap['FilterString'] = "FForbidStatus = 'A' and FDocumentStatus = 'C' and FUseOrgId.FNumber ='"+tissue+"'";
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
  //获取组织
  getOrganizationsList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'ORG_Organizations';
    userMap['FieldKeys'] = 'FForbidStatus,FName,FNumber';
    userMap['FilterString'] = "FForbidStatus = 'A'";
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
  getOrderList() async {
    Map<String, dynamic> userMap = Map();
    print(fBillNo);
    userMap['FilterString'] = "FBillNo='$fBillNo'";
    userMap['FormId'] = 'STK_OutStockApply';
    userMap['OrderString'] = 'FMaterialId.FNumber ASC';
    userMap['FieldKeys'] =
    'FBillNo,FStockOrgId.FNumber,FStockOrgId.FName,FDate,FEntity_FEntryId,FMaterialId.FNumber,FMaterialId.FName,FMaterialId.FSpecification,FCustId.FNumber,FCustId.FName,FUnitId.FNumber,FUnitId.FName,FQty,FNote,FID,FAuxPropId.FF100002.FNumber,FMaterialId.FIsBatchManage,FStockID.FIsOpenLocation,FTotalSecQty,FMaterialId.FIsKFPeriod';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    orderDate = [];
    orderDate = jsonDecode(order);
    FDate = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    selectData[DateMode.YMD] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    if (orderDate.length > 0) {
      this.cusName = orderDate[0][9] == null?"":orderDate[0][9];
      hobby = [];
      for(var value in orderDate){
        List arr = [];
        fNumber.add(value[5]);
        arr.add({
          "title": "物料名称",
          "name": "FMaterial",
          "FEntryId": value[4],
          "FID": value[14],
          "FIsKFPeriod": value[19],
          "parseEntryID": -1,
          "isHide": false,
          "value": {
            "label": value[6] + "- (" + value[5] + ")",
            "value": value[5],
            "barcode": [],
            "kingDeeCode": [],
            "surplus": value[12] - value[18],
            "scanCode": []
          }
        });
        arr.add({
          "title": "包装规格",
          "isHide": false,
          "name": "FMaterialIdFSpecification",
          "value": {"label": "", "value": ""}
          //"value": {"label": value[15] == null?"":value[15], "value": value[15] == null?"":value[15]}
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
          "value": {"label": "", "value": "0"}
        });
        arr.add({
          "title": "仓库",
          "name": "FStockID",
          "isHide": false,
          "value": {"label": "", "value": ""}
        });
       /* Map<String, dynamic> inventoryMap = Map();
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
            "isHide": value[16] != true,
            "value": {"label": "", "value": "","fLotList": stocks}
          });
        }else{
          arr.add({
            "title": "批号",
            "name": "FLot",
            "isHide": value[16] != true,
            "value": {"label": "", "value": ""}
          });
        }*/
        arr.add({
          "title": "批号",
          "name": "FLot",
          "isHide": value[16] != true,
          "value": {"label": "", "value": ""}
        });
        arr.add({
          "title": "仓位",
          "name": "FStockLocID",
          "isHide": false,
          "value": {"label": "", "value": "","hide": false}//value[17]
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
          "value": {"label": value[11], "value": value[10]}
        });
        arr.add({
          "title": "申请数量",
          "name": "",
          "isHide": false,
          "value": {"label": value[12] - value[18], "value": value[12] - value[18]}
        });
        arr.add({
          "title": "最后扫描数量",
          "name": "FLastQty",
          "isHide": false,
          "value": {"label": "0", "value": "0", "remainder": "0", "representativeQuantity": "0"}
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
          "title": "生产日期",
          "name": "FProduceDate",
          "isHide": !value[19],
          "value": {
            "label": '',
            "value": ''
          }
        });
        arr.add({
          "title": "有效期至",
          "name": "FExpiryDate",
          "isHide": !value[19],
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
    /*_onEvent("11051;JX202410009远大/远大;2024-10-08;249;CGRK03470,1110462771;21");
    _onEvent("11051;JX202410009远大/远大;2024-10-08;249;CGRK03470,1110462742;20");
    _onEvent("11051;JX202410009远大/远大;2024-10-08;249;CGRK03470,1110462624;16");
    _onEvent("11051;JX202410009远大/远大;2024-10-08;249;CGRK03470,1110462654;17");*/

  }

  void _onEvent(event) async {
    /*if ( (organizationsNumber == null || organizationsNumber == "")) {
      ToastUtil.showInfo('请选择对应组织，获取仓库');
      return;
    }*/
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var deptData = sharedPreferences.getString('menuList');
    var menuList = new Map<dynamic, dynamic>.from(jsonDecode(deptData));
    fBarCodeList = menuList['FBarCodeList'];
    if(event == ""){
      return;
    }
    if(checkItem == "position"){
      setState(() {
        this._FNumber = event;
        this._textNumber.text = event;
      });
    }else{
      if(fBarCodeList == 1){
        Map<String, dynamic> barcodeMap = Map();
        barcodeMap['FilterString'] = "FBarCodeEn='"+event+"'";
        barcodeMap['FormId'] = 'QDEP_Cust_BarCodeList';
        barcodeMap['FieldKeys'] =
        'FID,FInQtyTotal,FOutQtyTotal,FEntity_FEntryId,FRemainQty,FBarCodeQty,FStockID.FName,FStockID.FNumber,FMATERIALID.FNUMBER,FOwnerID.FNumber,FBarCode,FSN,FPackageSpec,FProduceDate,FExpiryDate,FStockLocNumberH,FStockID.FIsOpenLocation';
        Map<String, dynamic> dataMap = Map();
        dataMap['data'] = barcodeMap;
        String order = await CurrencyEntity.polling(dataMap);
        var barcodeData = jsonDecode(order);
        if (barcodeData.length>0) {
          print(barcodeData);
          if(barcodeData[0][4]>0){
            _code = event;
            this.getMaterialList(barcodeData,barcodeData[0][10], barcodeData[0][11], barcodeData[0][12], barcodeData[0][13].substring(0, 10), barcodeData[0][14].substring(0, 10), barcodeData[0][15], barcodeData[0][16]);
            print("ChannelPage: $event");
          }else{
            ToastUtil.showInfo('该条码已出库或没入库，数量为零');
          }
        }else{
          ToastUtil.showInfo('条码不在条码清单中');
        }
      }else{
        _code = event;
        this.getMaterialList("",_code,"","","","","",false);
        print("ChannelPage: $event");
      }
    }

  }

  void _onError(Object error) {
    setState(() {
      _code = "扫描异常";
    });
  }
  getMaterialList(barcodeData,code, fsn,fAuxPropId, fProduceDate, fExpiryDate, fLoc,fIsOpenLocation) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var tissue = sharedPreferences.getString('tissue');
    var scanCode = code.split(";");
    userMap['FilterString'] = "FNumber='" + scanCode[0] + "' and FForbidStatus = 'A' and FUseOrgId.FNumber = '"+tissue+"'";
    userMap['FormId'] = 'BD_MATERIAL';
    userMap['FieldKeys'] =
    'FMATERIALID,FName,FNumber,FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FIsBatchManage,FIsKFPeriod';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    materialDate = [];
    materialDate = jsonDecode(order);
    FDate = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    selectData[DateMode.YMD] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    if (materialDate.length > 0) {
      var number = 0;
      var barCodeScan = [];
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
                    element[4]['value']['label'] = barcodeData[0][6] == null? "":barcodeData[0][6];
                    element[4]['value']['value'] = barcodeData[0][7] == null? "":barcodeData[0][7];
                  }
                  if (element[1]['value']['value'] == "") {
                    element[1]['value']['label'] = barcodeData[0][12] == null? "":barcodeData[0][12];
                    element[1]['value']['value'] =barcodeData[0][12] == null? "":barcodeData[0][12];
                  }
                  if (element[13]['value']['value'] == "") {
                    element[13]['value']['label'] = fProduceDate == null? "":fProduceDate;
                    element[13]['value']['value'] =fProduceDate == null? "":fProduceDate;
                    element[14]['value']['label'] =fExpiryDate == null? "":fExpiryDate;
                    element[14]['value']['value'] =fExpiryDate == null? "":fExpiryDate;
                  }
                  if(fIsOpenLocation){
                    element[6]['value']['hide'] = fIsOpenLocation;
                    if (element[6]['value']['value'] == "") {
                      element[6]['value']['label'] = fLoc == null? "":fLoc;
                      element[6]['value']['value'] =fLoc == null? "":fLoc;
                    }
                  }
                  //判断是否启用保质期
                  if (!element[13]['isHide']) {
                    if (element[13]['value']['value'] == fProduceDate &&
                        element[14]['value']['value'] == fExpiryDate) {
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
                  element[10]['value']['remainder'] = "0";
                  element[10]['value']['representativeQuantity'] = barcodeQuantity;
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
                      element[4]['value']['label'] = barcodeData[0][6] == null? "":barcodeData[0][6];
                      element[4]['value']['value'] = barcodeData[0][7] == null? "":barcodeData[0][7];
                    }
                    if (element[1]['value']['value'] == "") {
                      element[1]['value']['label'] = barcodeData[0][12] == null? "":barcodeData[0][12];
                      element[1]['value']['value'] =barcodeData[0][12] == null? "":barcodeData[0][12];
                    }
                    if (element[13]['value']['value'] == "") {
                      element[13]['value']['label'] = fProduceDate == null? "":fProduceDate;
                      element[13]['value']['value'] =fProduceDate == null? "":fProduceDate;
                      element[14]['value']['label'] =fExpiryDate == null? "":fExpiryDate;
                      element[14]['value']['value'] =fExpiryDate == null? "":fExpiryDate;
                    }
                    if(fIsOpenLocation){
                      element[6]['value']['hide'] = fIsOpenLocation;
                      if (element[6]['value']['value'] == "") {
                        element[6]['value']['label'] = fLoc == null? "":fLoc;
                        element[6]['value']['value'] =fLoc == null? "":fLoc;
                      }
                    }
                    //判断是否启用保质期
                    if (!element[13]['isHide']) {
                      if (element[13]['value']['value'] == fProduceDate &&
                          element[14]['value']['value'] == fExpiryDate) {
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
                    element[1]['value']['label'] = barcodeData[0][12] == null? "":barcodeData[0][12];
                    element[1]['value']['value'] =barcodeData[0][12] == null? "":barcodeData[0][12];
                  }
                  if (element[13]['value']['value'] == "") {
                    element[13]['value']['label'] = fProduceDate == null? "":fProduceDate;
                    element[13]['value']['value'] =fProduceDate == null? "":fProduceDate;
                    element[14]['value']['label'] =fExpiryDate == null? "":fExpiryDate;
                    element[14]['value']['value'] =fExpiryDate == null? "":fExpiryDate;
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
                  if (!element[13]['isHide']) {
                    if (element[13]['value']['value'] == fProduceDate &&
                        element[14]['value']['value'] == fExpiryDate) {
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
                        element[1]['value']['label'] = barcodeData[0][12] == null? "":barcodeData[0][12];
                        element[1]['value']['value'] =barcodeData[0][12] == null? "":barcodeData[0][12];
                      }
                      if (element[13]['value']['value'] == "") {
                        element[13]['value']['label'] = fProduceDate == null? "":fProduceDate;
                        element[13]['value']['value'] =fProduceDate == null? "":fProduceDate;
                        element[14]['value']['label'] =fExpiryDate == null? "":fExpiryDate;
                        element[14]['value']['value'] =fExpiryDate == null? "":fExpiryDate;
                      }
                      if(fIsOpenLocation){
                        element[6]['value']['hide'] = fIsOpenLocation;
                        if (element[6]['value']['value'] == "") {
                          element[6]['value']['label'] = fLoc == null? "":fLoc;
                          element[6]['value']['value'] =fLoc == null? "":fLoc;
                        }
                      }
                      //判断是否启用保质期
                      if (!element[13]['isHide']) {
                        if (element[13]['value']['value'] == fProduceDate &&
                            element[14]['value']['value'] == fExpiryDate) {
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
                          element[1]['value']['label'] = barcodeData[0][12] == null? "":barcodeData[0][12];
                          element[1]['value']['value'] =barcodeData[0][12] == null? "":barcodeData[0][12];
                        }
                        if (element[13]['value']['value'] == "") {
                          element[13]['value']['label'] = fProduceDate == null? "":fProduceDate;
                          element[13]['value']['value'] =fProduceDate == null? "":fProduceDate;
                          element[14]['value']['label'] =fExpiryDate == null? "":fExpiryDate;
                          element[14]['value']['value'] =fExpiryDate == null? "":fExpiryDate;
                        }
                        if(fIsOpenLocation){
                          element[6]['value']['hide'] = fIsOpenLocation;
                          if (element[6]['value']['value'] == "") {
                            element[6]['value']['label'] = fLoc == null? "":fLoc;
                            element[6]['value']['value'] =fLoc == null? "":fLoc;
                          }
                        }
                        //判断是否启用保质期
                        if (!element[13]['isHide']) {
                          if (element[13]['value']['value'] == fProduceDate &&
                              element[14]['value']['value'] == fExpiryDate) {
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
      if(number == 0){
        var inserNum = 0.0;
        print("剩余");
        print(surplus);
        print(barCodeScan[4]);
        if(double.parse(barCodeScan[4]) >= surplus && this.fBillNo!=''){
          inserNum = surplus;
        }else{
          inserNum = double.parse(barCodeScan[4]);
        }
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
              "barcode": [code],
              "surplus": surplus,
              "kingDeeCode": [barCodeScan[0].toString()+"-"+barCodeScan[4]+"-"+fsn],
              "scanCode": [barCodeScan[0].toString()+"-"+barCodeScan[4]]}
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
            "title": "出库数量",
            "name": "FRealQty",
            "isHide": false,
            "value": {"label": inserNum.toString(), "value": inserNum.toString()}
          });
          arr.add({
            "title": "仓库",
            "name": "FStockID",
            "isHide": false,
            "value": {"label": barcodeData[0][6], "value": barcodeData[0][7]}
          });
          arr.add({
            "title": "批号",
            "name": "FLot",
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
            "value": {"label": value[4], "value": value[5]}
          });
          arr.add({
            "title": "申请数量",
            "name": "",
            "isHide": false,
            "value": {"label": inserNum, "value": inserNum}
          });
          arr.add({
            "title": "最后扫描数量",
            "name": "FLastQty",
            "isHide": false,
            "value": {
              "label": inserNum.toString(),
              "value": inserNum.toString(),"remainder": (double.parse(barCodeScan[4]) - inserNum).toString(),"representativeQuantity": barCodeScan[4]
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
          if(hobby  == 'customer'){
            customerName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                customerNumber = customerListObj[elementIndex][2];
              }
              elementIndex++;
            });
          } else if (hobby == 'organizations') {
            organizationsName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                organizationsNumber = organizationsListObj[elementIndex][2];
              }
              elementIndex++;
            });

            getDepartmentList();
          }else if(hobby  == 'department'){
            departmentName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                departmentNumber = departmentListObj[elementIndex][2];
              }
              elementIndex++;
            });
            //_onEvent("13095;20190618考科;2019-06-18;1;,1006124995;2");
          }else if(hobby == 'outboundType'){
            outboundTypeName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                outboundTypeNumber = outboundTypeListObj[elementIndex][0];
              }
              elementIndex++;
            });

          }else if(hobby == 'type'){
            typeName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                typeNumber = typeListObj[elementIndex][2];
              }
              elementIndex++;
            });
          }else if(hobby == 'statusType'){
            statusTypeName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                statusTypeNumber = statusTypeListObj[elementIndex][0];
              }
              elementIndex++;
            });
          }else{
            setState(() {
              hobby['value']['label'] = p;
            });
            print(hobby['value']['label']);
            /*if(p.contains("不合格")){
              this.statusTypeName = '不良';
              this.statusTypeNumber = 'KCZT08_SYS';
            }else{
              this.statusTypeName = '可用';
              this.statusTypeNumber = 'KCZT01_SYS';
            }*/
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
                      trailing:
                      Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                        new MaterialButton(
                          color: Colors.blue,
                          textColor: Colors.white,
                          child: new Text('查看'),
                          onPressed: () async {
                            if(this.hobby[i][j]["value"]["fLotList"] != null && this.hobby[i][j]["value"]["fLotList"].length>0){
                              await _showModalBottomSheet(
                                  context, this.hobby[i][j]["value"]["fLotList"],this.hobby[i][j]["value"]);
                            }else{
                              ToastUtil.showInfo('无相关批号信息');
                            }

                            setState(() {});
                          },
                        ),
                      ])),
                ),
                divider,
              ]),
            );
          }else*/ if ( j == 11) {
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
                                text: this.hobby[i][j]["value"]["label"].toString(),
                              );
                            }
                          },
                        ),
                      ])),
                ),
                divider,
              ]),
            );
          }else if (j == 10) {
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
          } else if (j == 4) {
            comList.add(
              _item('仓库:', stockList, this.hobby[i][j]['value']['label'],
                  this.hobby[i][j],stock:this.hobby[i]),
            );
          }  else if (j == 6) {
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
                            if(checkItem=="FLastQty"){
                              if(double.parse(_FNumber) <= double.parse(this.hobby[checkData][checkDataChild]["value"]['representativeQuantity'])){
                                if(double.parse(_FNumber) <= this.hobby[checkData][9]["value"]['value']){
                                  if (this.hobby[checkData][0]['value']['kingDeeCode'].length > 0) {
                                    var kingDeeCode = this.hobby[checkData][0]['value']['kingDeeCode'][this.hobby[checkData][0]['value']['kingDeeCode'].length - 1].split("-");
                                    print(kingDeeCode);
                                    var realQty = 0.0;
                                    this.hobby[checkData][0]['value']['kingDeeCode'].forEach((item) {
                                      var qty = item.split("-")[1];
                                      realQty += double.parse(qty);
                                    });
                                    print(realQty);
                                    print(this.hobby[checkData][10]["value"]["label"]);
                                    realQty = (realQty * 100 - double.parse(this.hobby[checkData][10]["value"]["label"]) * 100) / 100;
                                    realQty = (realQty * 100 + double.parse(_FNumber) * 100) / 100;
                                    print(realQty);
                                    this.hobby[checkData][10]["value"]["remainder"] = (Decimal.parse(this.hobby[checkData][10]["value"]["representativeQuantity"]) - Decimal.parse(_FNumber)).toString();
                                    this.hobby[checkData][3]["value"]["value"] = realQty.toString();
                                    this.hobby[checkData][3]["value"]["label"] = realQty.toString();
                                    if(this.fBillNo!=""){
                                      var entryIndex;
                                      if(this.hobby[checkData][0]['FEntryID'] == 0){
                                        entryIndex = this.hobbyItem[this.hobbyItem.indexWhere((v)=> v['number'] == (this.hobby[checkData][0]['value']['value']+'-'+this.hobby[checkData][0]['parseEntryID'].toString()))]['index'];
                                      }else{
                                        entryIndex = this.hobbyItem[this.hobbyItem.indexWhere((v)=> v['number'] == (this.hobby[checkData][0]['value']['value']+'-'+this.hobby[checkData][0]['FEntryID'].toString()))]['index'];
                                      }
                                      hobby[entryIndex][0]['value']['surplus'] = (hobby[entryIndex][9]['value']['value'] * 100 - double.parse(this.hobby[checkData][3]['value']['value']) * 100) / 100;
                                    }
                                    this.hobby[checkData][checkDataChild]["value"]["label"] = _FNumber;
                                    this.hobby[checkData][checkDataChild]['value']["value"] = _FNumber;
                                    this.hobby[checkData][0]['value']['kingDeeCode'][this.hobby[checkData][0]['value']['kingDeeCode'].length - 1] = kingDeeCode[0] + "-" + _FNumber + "-" + kingDeeCode[2];
                                  } else {
                                    ToastUtil.showInfo('无条码信息，输入失败');
                                  }
                                }else{
                                  ToastUtil.showInfo('输入数量大于可用数量');
                                }
                              }else{
                                ToastUtil.showInfo('输入数量大于条码可用数量');
                              }
                            }else if(checkItem=="bagNum"){
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
                            }else{
                              this.hobby[checkData][checkDataChild]["value"]
                              ["label"] = _FNumber.trim();
                              this.hobby[checkData][checkDataChild]['value']
                              ["value"] = _FNumber.trim();
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
  //保存
  saveOrder() async {
    if (this.hobby.length > 0) {
      setState(() {
        this.isSubmit = true;
      });
      if (this.departmentNumber  == null) {
        this.isSubmit = false;
        ToastUtil.showInfo('部门为空');
        return;
      }/*if (this.customerNumber  == null) {
        this.isSubmit = false;
        ToastUtil.showInfo('请选择客户');
        return;
      }*/
      Map<String, dynamic> dataMap = Map();
      dataMap['formid'] = 'STK_MisDelivery';
      Map<String, dynamic> orderMap = Map();
      orderMap['NeedUpDataFields'] = ['FEntity','FSerialSubEntity','FSerialNo'];
      orderMap['NeedReturnFields'] = ['FEntity','FSerialSubEntity','FSerialNo'];
      orderMap['IsDeleteEntry'] = true;
      Map<String, dynamic> Model = Map();
      Model['FID'] = 0;
      Model['F_UUAC_Combo_dvn'] = "1";
      Model['FBillTypeID'] = {"FNUMBER": "QTCKD01_SYS"};
      Model['FDate'] = FDate;
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      var tissue = sharedPreferences.getString('tissue');
      Model['FStockOrgId'] = {"FNumber": tissue};
      Model['FPickOrgId'] = {"FNumber": tissue};
      if (this.departmentNumber  != null) {
        Model['FDeptId'] = {"FNumber": this.departmentNumber};
      }
      if (this.customerNumber  != null) {
        Model['FCustId'] = {"FNumber": this.customerNumber};
      }
      Model['FOwnerTypeIdHead'] = "BD_OwnerOrg";
      Model['FStockDirect'] = "GENERAL";
      Model['FBizType'] = "0";
      /*Model['F_ora_Assistant'] = {"FNumber": this.typeNumber};*/
      Model['FOwnerIdHead'] = {"FNumber": tissue};
      Model['F_UUAC_Assistant'] = {"FNumber": this.outboundTypeNumber};
      Model['FNote'] = this._remarkContent.text;
      Model['F_UUAC_Text_83g'] = this._deptContent.text;
      Model['F_UUAC_CheckBox'] = _checked;
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
      for(var element in this.hobby){
        if (element[3]['value']['value'] != '0' && element[3]['value']['value'] != '' &&
            element[4]['value']['value'] != '') {
          var entryIndex;
          Map<String, dynamic> FEntityItem = Map();
          FEntityItem['FMaterialId'] = {
            "FNumber": element[0]['value']['value']
          };
          FEntityItem['FUnitID'] = {
            "FNumber": element[2]['value']['value']
          };
          FEntityItem['FBaseUnitId'] = {
            "FNumber": element[2]['value']['value']
          };
          FEntityItem['FStockId'] = {
            "FNumber": element[4]['value']['value']
          };
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
          FEntityItem['FAuxPropId'] = {
            "FAUXPROPID__FF100002": {"FNumber": element[1]['value']['value']}
          };
          /*FEntityItem['FReturnType'] = 1;*/
          FEntityItem['FQty'] = element[3]['value']['value'];
          FEntityItem['FOWNERTYPEID'] = "BD_OwnerOrg";
          FEntityItem['FSTOCKSTATUSID'] = {"FNumber": this.statusTypeNumber};
          FEntityItem['FOWNERID'] = {"FNumber": tissue};
          FEntityItem['FOwnerId'] = {"FNumber": tissue};
          FEntityItem['FKeeperTypeId'] = "BD_KeeperOrg";
          if(element[0]['FIsKFPeriod']){
            FEntityItem['FProduceDate'] = element[13]['value']['value'];
            FEntityItem['FExpiryDate'] = element[14]['value']['value'];
          }
          FEntityItem['FKeeperId'] = {"FNumber": tissue};
          FEntityItem['FLot'] = {"FNumber": element[5]['value']['value']};
          if(isScanWork){
            if(element[0]['FEntryID'] == 0){
              entryIndex = this.hobbyItem[this.hobbyItem.indexWhere((v)=> v['number'] == (element[0]['value']['value']+'-'+element[0]['parseEntryID'].toString()))]['index'];
              FEntityItem['FEntity_Link'] = [
                {
                  "FEntity_Link_FRuleId": "STK_OutStockApplyToSTK_MisDelivery",
                  "FEntity_Link_FSTableName": "T_STK_OUTSTOCKAPPLYENTRY",
                  "FEntity_Link_FSBillId": this.hobby[entryIndex][0]['FID'],
                  "FEntity_Link_FSId": this.hobby[entryIndex][0]['FEntryId'],
                  "FEntity_Link_FBaseUnitQty": element[3]['value']['value'],
                }
              ];
            }else{
              FEntityItem['FEntity_Link'] = [
                {
                  "FEntity_Link_FRuleId": "STK_OutStockApplyToSTK_MisDelivery",
                  "FEntity_Link_FSTableName": "T_STK_OUTSTOCKAPPLYENTRY",
                  "FEntity_Link_FSBillId": element[0]['FID'],
                  "FEntity_Link_FSId": element[0]['FEntryId'],
                  "FEntity_Link_FBaseUnitQty": element[3]['value']['value'],
                }
              ];
            }
          }
          var fSerialSub = [];
          var kingDeeCode = element[0]['value']['kingDeeCode'];
          for (int subj = 0; subj < kingDeeCode.length; subj++) {
            Map<String, dynamic> subObj = Map();
            var itemCode = kingDeeCode[subj].split("-");
            if(itemCode.length>2){
              if(itemCode.length > 3){
                subObj['FSerialNo'] = itemCode[2]+'-'+itemCode[3];
              }else{
                subObj['FSerialNo'] = itemCode[2];
              }
            }
            fSerialSub.add(subObj);
          }
          FEntityItem['FSerialSubEntity'] = fSerialSub;

          FEntity.add(FEntityItem);
        }
        hobbyIndex++;
      };
      if (FEntity.length == 0) {
        this.isSubmit = false;
        ToastUtil.showInfo('请输入数量,仓库,出库类别');
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
          "formid": "STK_MisDelivery",
          "data": {
            'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
          }
        };
        //提交
        HandlerOrder.orderHandler(
            context,
            submitMap,
            1,
            "STK_MisDelivery",
            SubmitEntity.submit(submitMap))
            .then((submitResult) async{
          if (submitResult) {
            if(_checked){
              //审核
              /*HandlerOrder.orderHandler(
                  context,
                  submitMap,
                  1,
                  "STK_MisDelivery",
                  SubmitEntity.audit(submitMap))
                  .then((auditResult) async{
                if (auditResult) {
                  print(auditResult);*/
                  var errorMsg = "";
                  if(fBarCodeList == 1){
                    for (int i = 0; i < this.hobby.length; i++) {
                      if (this.hobby[i][3]['value']['value'] != '0') {
                        var kingDeeCode = this.hobby[i][0]['value']['kingDeeCode'];
                        for(int j = 0;j<kingDeeCode.length;j++){
                          Map<String, dynamic> dataCodeMap = Map();
                          dataCodeMap['formid'] = 'QDEP_Cust_BarCodeList';
                          Map<String, dynamic> orderCodeMap = Map();
                          orderCodeMap['NeedReturnFields'] = [];
                          orderCodeMap['IsDeleteEntry'] = false;
                          Map<String, dynamic> codeModel = Map();
                          var itemCode = kingDeeCode[j].split("-");
                          codeModel['FID'] = itemCode[0];
                          /* codeModel['FOwnerID'] = {
                          "FNUMBER": deptData[1]
                        };
                        codeModel['FStockOrgID'] = {
                          "FNUMBER": deptData[1]
                        };
                        codeModel['FStockID'] = {
                          "FNUMBER": this.hobby[i][4]['value']['value']
                        };
                        codeModel['FLastCheckTime'] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);*/
                          Map<String, dynamic> codeFEntityItem = Map();
                          codeFEntityItem['FEntryStockID'] ={
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
                          codeFEntityItem['FEntryBillNo'] = res['Result']['ResponseStatus']['SuccessEntitys'][0]['Number'];

                          var codeFEntity = [codeFEntityItem];
                          codeModel['FEntity'] = codeFEntity;
                          orderCodeMap['Model'] = codeModel;
                          dataCodeMap['data'] = orderCodeMap;
                          print(dataCodeMap);
                          String codeRes = await SubmitEntity.save(dataCodeMap);
                          var barcodeRes = jsonDecode(codeRes);
                          if(!barcodeRes['Result']['ResponseStatus']['IsSuccess']){
                            errorMsg +="错误反馈："+itemCode[1]+":"+barcodeRes['Result']['ResponseStatus']['Errors'][0]['Message'];
                          }
                          print(codeRes);
                        }
                      }
                    }
                  }
                  if(errorMsg !=""){
                    ToastUtil.errorDialog(context,
                        errorMsg);
                    this.isSubmit = false;
                  }
                  //提交清空页面
                  setState(() {
                    this.hobby = [];
                    this.orderDate = [];
                    this.materialDate = [];
                    this.FBillNo = '';
                    ToastUtil.showInfo('提交成功');
                    Navigator.of(context).pop("refresh");
                  });
                /*} else {
                  //失败后反审
                  HandlerOrder.orderHandler(
                      context,
                      submitMap,
                      0,
                      "STK_MisDelivery",
                      SubmitEntity.unAudit(submitMap))
                      .then((unAuditResult) {
                    if (unAuditResult) {
                      this.isSubmit = false;
                    }else{
                      this.isSubmit = false;
                    }
                  });
                }
              });*/
            }else{
              var errorMsg = "";
              if(fBarCodeList == 1){
                for (int i = 0; i < this.hobby.length; i++) {
                  if (this.hobby[i][3]['value']['value'] != '0') {
                    var kingDeeCode = this.hobby[i][0]['value']['kingDeeCode'];
                    for(int j = 0;j<kingDeeCode.length;j++){
                      Map<String, dynamic> dataCodeMap = Map();
                      dataCodeMap['formid'] = 'QDEP_Cust_BarCodeList';
                      Map<String, dynamic> orderCodeMap = Map();
                      orderCodeMap['NeedReturnFields'] = [];
                      orderCodeMap['IsDeleteEntry'] = false;
                      Map<String, dynamic> codeModel = Map();
                      var itemCode = kingDeeCode[j].split("-");
                      codeModel['FID'] = itemCode[0];
                      /*codeModel['FOwnerID'] = {
                          "FNUMBER": deptData[1]
                        };
                        codeModel['FStockOrgID'] = {
                          "FNUMBER": deptData[1]
                        };
                        codeModel['FStockID'] = {
                          "FNUMBER": this.hobby[i][4]['value']['value']
                        };*/
                      /*codeModel['FLastCheckTime'] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);*/
                      Map<String, dynamic> codeFEntityItem = Map();
                      codeFEntityItem['FBillDate'] = FDate;
                      codeFEntityItem['FOutQty'] = itemCode[1];
                      codeFEntityItem['FEntryBillNo'] = res['Result']['ResponseStatus']['SuccessEntitys'][0]['Number'];
                      codeFEntityItem['FEntryStockID'] ={
                        "FNUMBER": this.hobby[i][4]['value']['value']
                      };
                      var codeFEntity = [codeFEntityItem];
                      codeModel['FEntity'] = codeFEntity;
                      orderCodeMap['Model'] = codeModel;
                      dataCodeMap['data'] = orderCodeMap;
                      print(dataCodeMap);
                      String codeRes = await SubmitEntity.save(dataCodeMap);
                      var barcodeRes = jsonDecode(codeRes);
                      if(!barcodeRes['Result']['ResponseStatus']['IsSuccess']){
                        errorMsg +="错误反馈："+itemCode[1]+":"+barcodeRes['Result']['ResponseStatus']['Errors'][0]['Message'];
                      }
                      print(codeRes);
                    }
                  }
                }
              }
              if(errorMsg !=""){
                ToastUtil.errorDialog(context,
                    errorMsg);
                this.isSubmit = false;
              }
              //提交清空页面
              setState(() {
                this.hobby = [];
                this.orderDate = [];
                this.materialDate = [];
                this.FBillNo = '';
                ToastUtil.showInfo('提交成功');
                Navigator.of(context).pop("refresh");
              });
            }
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
            title: Text("其他出库"),
            centerTitle: true,
            leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: (){
              Navigator.of(context).pop();
            }),
          ),
          body: Column(
            children: <Widget>[
              Expanded(
                child: ListView(children: <Widget>[
                  Visibility(
                    maintainSize: false,
                    maintainState: false,
                    maintainAnimation: false,
                    visible: isScanWork,
                    child: Column(
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
                  ),
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text("是否保密:"),
                          trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Checkbox(
                                  value: _checked, // 当前复选框的值，表示是否选中
                                  onChanged: (bool? newValue) {
                                    setState(() {
                                      _checked = newValue!;
                                    });
                                  },
                                ),
                              ]),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  _dateItem('日期：', DateMode.YMD),
                  /*_item('组织', this.organizationsList, this.organizationsName,
                      'organizations'),*/
                  Visibility(
                    maintainSize: false,
                    maintainState: false,
                    maintainAnimation: false,
                    visible: isScanWork,
                    child: Column(
                      children: [
                        Container(
                          color: Colors.white,
                          child: ListTile(
                            /* title: TextWidget(FBillNoKey, '生产订单：'),*/
                            title: Text("客户：$cusName"),
                          ),
                        ),
                        divider,
                      ],
                    ),
                  ),
                  /* _dateItem('日期：', DateMode.YMD),*/
                  Visibility(
                    maintainSize: false,
                    maintainState: false,
                    maintainAnimation: false,
                    visible: !isScanWork,
                    child: _item('客户:', this.customerList, this.customerName,
                        'customer'),
                  ),
                  _item('部门', this.departmentList, this.departmentName,
                      'department'),
                  _item('出库类型', this.outboundTypeList, this.outboundTypeName,
                      'outboundType'),
                  _item('库存状态', this.statusTypeList, this.statusTypeName,
                      'statusType'),
                  /*_item('类别', this.typeList, this.typeName,
                      'type'),*/
                 Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: TextField(
                            //最多输入行数
                            maxLines: 1,
                            decoration: InputDecoration(
                              hintText: "实际使用部门",
                              //给文本框加边框
                              border: OutlineInputBorder(),
                            ),
                            controller: this._deptContent,
                            //改变回调
                            onChanged: (value) {
                              setState(() {
                                _deptContent.value = TextEditingValue(
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
                  ),
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
