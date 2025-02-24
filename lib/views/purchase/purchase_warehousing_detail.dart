import 'dart:convert';
import 'package:date_format/date_format.dart';
import 'package:fzwm_wxbc/model/currency_entity.dart';
import 'package:fzwm_wxbc/model/submit_entity.dart';
import 'package:fzwm_wxbc/utils/handler_order.dart';
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
import 'package:fzwm_wxbc/components/my_text.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qrscan/qrscan.dart' as scanner;

class PurchaseWarehousingDetail extends StatefulWidget {
  var FBillNo;

  PurchaseWarehousingDetail({Key? key, @required this.FBillNo})
      : super(key: key);

  @override
  _PurchaseWarehousingDetailState createState() =>
      _PurchaseWarehousingDetailState(FBillNo);
}

class _PurchaseWarehousingDetailState extends State<PurchaseWarehousingDetail> {
  var _remarkContent = new TextEditingController();
  GlobalKey<TextWidgetState> textKey = GlobalKey();


  GlobalKey<PartRefreshWidgetState> globalTKey = GlobalKey();

  final _textNumber = TextEditingController();
  var checkItem;
  String FBillNo = '';
  String FSaleOrderNo = '';
  String FName = '';
  String FNumber = '';
  String FDate = '';
  var supplierName;
  var supplierNumber;
  var departmentName;
  var departmentNumber;
  var storehouseName;
  var storehouseNumber;
  var showPosition = false;
  var storingLocationName;
  var storingLocationNumber;
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
  var bagModalList = [];
  List<dynamic> bagListObj = [];
  var departmentList = [];
  List<dynamic> departmentListObj = [];
  var supplierList = [];
  List<dynamic> supplierListObj = [];
  var stockList = [];
  var typeList = [];
  List<dynamic> typeListObj = [];
  List<dynamic> stockListObj = [];
  List<dynamic> orderDate = [];
  Map<String, dynamic> printData = {};
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
  var fOrgID;
  var fBarCodeList;
  final controller = TextEditingController();
  _PurchaseWarehousingDetailState(FBillNo) {
    if (FBillNo != null) {
      this.fBillNo = FBillNo['value'];
      this.getOrderList();
      isScanWork = true;
    } else {
      isScanWork = false;
      getSupplierList();
      getDepartmentList();
      this.fBillNo = '';
      getStockList();
    }
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
    /*getWorkShop();*/
    getBagList();
    EasyLoading.dismiss();
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
  //获取部门
  getDepartmentList() async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var tissue = sharedPreferences.getString('tissue');
    userMap['FormId'] = 'BD_Department';
    userMap['FieldKeys'] = 'FUseOrgId,FName,FNumber';
    userMap['FilterString'] = "FUseOrgId.FNumber ='" + tissue + "'";
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    departmentListObj = jsonDecode(res);
    departmentListObj.forEach((element) {
      departmentList.add(element[1]);
    });
  }

  //获取线路名称
  getTypeList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BOS_ASSISTANTDATA_DETAIL';
    userMap['FieldKeys'] = 'FId,FDataValue,FNumber';
    userMap['FilterString'] = "FId ='5fd715f4883532' and FForbidStatus='A'";
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    typeListObj = jsonDecode(res);
    typeListObj.forEach((element) {
      typeList.add(element[1]);
    });
  }

  //获取供应商
  getSupplierList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BD_Supplier';
    userMap['FieldKeys'] = 'FSupplierId,FName,FNumber';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    supplierListObj = jsonDecode(res);
    supplierListObj.forEach((element) {
      supplierList.add(element[1]);
    });
  }

  //获取仓库
  getStockList() async {
    this.stockList = [];
    this.stockListObj = [];
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BD_STOCK';
    userMap['FieldKeys'] = 'FStockId,FName,FNumber,FIsOpenLocation';
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var tissue = sharedPreferences.getString('tissue');
    if (fOrgID == null) {
      this.fOrgID = tissue;
    }
    userMap['FilterString'] =
        "FForbidStatus = 'A' and FDocumentStatus = 'C' and FUseOrgId.FNumber='" + this.fOrgID + "'"; //
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
    userMap['FilterString'] = "FBillNo='$fBillNo' and FENTRYSTATUS = 'A'";
    userMap['FormId'] = 'PUR_ReceiveBill';
    userMap['OrderString'] = 'FMaterialId.FNumber ASC';
    userMap['FieldKeys'] =
    'FBillNo,FSupplierId.FNumber,FSupplierId.FName,FDate,FDetailEntity_FEntryId,FMaterialId.FNumber,F_UUAC_BaseProperty1,FMaterialId.FSpecification,FPurOrgId.FNumber,FPurOrgId.FName,FUnitId.FNumber,FUnitId.FName,FActlandQty,FSrcBillNo,FID,FMaterialId.FIsBatchManage,FStockOrgId.FNumber,FStockUnitID.FNumber,FTaxPrice,FEntryTaxRate,FPrice,FPurDeptId.FNumber,FPurchaserId.FNumber,FDescription,FBillTypeID.FNUMBER,FAuxPropId.FF100002.FNumber,FProduceDate,FExpiryDate,FInStockJoinQty,FGiveAway,FOrderBillNo,FSrcEntryId,FPayConditionId.FNumber,FDetailEntity_FSeq';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    orderDate = [];
    printData = {};
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
    hobby = [];
    if (orderDate.length > 0) {
      this.fOrgID = orderDate[0][16];
      orderDate.forEach((value) {
        fNumber.add(value[5]);
        List arr = [];
        arr.add({
          "title": "物料名称",
          "name": "FMaterial",
          "FBaseUnitID": value[17],
          "FSRCBILLTYPEID": value[24],
          "FSRCBillNo": value[0],
          "FPOQTY": value[12],
          "FPOOrderNo": value[0],
          "FTaxPrice": value[18],
          "FEntryTaxRate": value[19],
          "FNote": value[23],
          "FID": value[14],
          "FEntryId": value[4],
          "FGiveAway": value[29],
          "FOrderBillNo": value[30],
          "FSrcEntryId": value[31],
          "FPayConditionId": value[32],
          "FSeq": value[33],
          "isHide": false,
          "value": {
            "label": value[6] + "- (" + value[5] + ")",
            "value": value[5],
            "barcode": [],
            "kingDeeCode": [],
            "scanCode": []
          }
        });
        arr.add({
          "title": "包装规格",
          "isHide": false,
          "name": "FMaterialIdFSpecification",
          "value": {"label": "", "value": ""}
          //"value": {"label": value[25]==null?"":value[25], "value": value[25]==null?"":value[25]}
        });
        arr.add({
          "title": "单位名称",
          "name": "FUnitId",
          "isHide": false,
          "value": {"label": value[11], "value": value[10]}
        });
        arr.add({
          "title": "实收数量",
          "name": "FRealQty",
          "isHide": false,
          /*value[12]*/
          "value": {"label": "", "value": "0"}
        });
        arr.add({
          "title": "仓库",
          "name": "FStockID",
          "isHide": false,
          "value": {"label": "", "value": "", "dimension": ""}
        });
        arr.add({
          "title": "批号",
          "name": "FLot",
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
          "value": {"label": value[33], "value": value[33]}
        });
        arr.add({
          "title": "库存单位",
          "name": "",
          "isHide": true,
          "value": {"label": value[18], "value": value[18]}
        });
        arr.add({
          "title": "实到数量",
          "name": "",
          "isHide": false,
          "value": {
            "label": (value[12] - value[28])>0?value[12] - value[28]: 0,
            "value": (value[12] - value[28])>0?value[12] - value[28]: 0,
            "rateValue": (value[12] - value[28])>0?value[12] - value[28]: 0
          } /*+value[12]*0.1*/
        });
        arr.add({
          "title": "最后扫描数量",
          "name": "FLastQty",
          "isHide": false,
          "value": {"label": "0", "value": "0"}
        });
        arr.add({
          "title": "生产日期",
          "name": "FProduceDate",
          "isHide": false,
          "value": {"label": value[26]!=null && value[26] != ''?value[26].substring(0,10):'', "value": value[26]!=null && value[26] != ''?value[26].substring(0,10):''}
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
    /*_onEvent("11052;20240709穗昌隆   品牌：益海;2024-07-09;10637;,1127086795;2");
    _onEvent("13111;G20240108科曼斯/长舟;2024-01-08;3361;,1453248587;2");*/
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
        if(this._FNumber != ""){
          this._FNumber = this._FNumber+","+event;
          this._textNumber.text = this._FNumber;
        }else{
          this._FNumber = event;
          this._textNumber.text = event;
        }
      });
    }else if(checkItem == 'HPoc'){
      setState(() {
          this._FNumber = event;
          this._textNumber.text = event;
      });
    }/*else{
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
            this.getMaterialList(
                barcodeData, barcodeData[0][10], barcodeData[0][11]);
          } else {
            ToastUtil.showInfo(msg);
          }
        } else {
          ToastUtil.showInfo('条码不在条码清单中');
        }
      } else {
        _code = event;
        this.getMaterialList("", _code, "");
        print("ChannelPage: $event");
      }
    }*/

    print("ChannelPage: $event");
  }

  getMaterialList(barcodeData, code, fsn) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
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
                  if (element[4]['value']['value'] == "") {
                    element[4]['value']['label'] = barcodeData[0][6] == null? "":barcodeData[0][6];
                    element[4]['value']['value'] = barcodeData[0][7] == null? "":barcodeData[0][7];
                  }
                  if (element[1]['value']['value'] == "") {
                    element[1]['value']['label'] = barcodeData[0][12] == null? "":barcodeData[0][12];
                    element[1]['value']['value'] =barcodeData[0][12] == null? "":barcodeData[0][12];
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
                break;
              }
              //判断扫描数量是否大于单据数量
              if (double.parse(element[3]['value']['value']) >=
                  element[9]['value']['rateValue']) {
                continue;
              } else {
                //判断条码数量
                if ((double.parse(element[3]['value']['value']) +
                    double.parse(barcodeNum)) >
                    0 &&
                    double.parse(barcodeNum) > 0) {
                  if (element[4]['value']['value'] == "") {
                    element[4]['value']['label'] = barcodeData[0][6] == null? "":barcodeData[0][6];
                    element[4]['value']['value'] = barcodeData[0][7] == null? "":barcodeData[0][7];
                  }
                  if (element[1]['value']['value'] == "") {
                    element[1]['value']['label'] = barcodeData[0][12] == null? "":barcodeData[0][12];
                    element[1]['value']['value'] =barcodeData[0][12] == null? "":barcodeData[0][12];
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
                  if ((double.parse(element[3]['value']['value']) +
                      double.parse(barcodeNum)) >=
                      element[9]['value']['rateValue']) {
                    //判断条码是否重复
                    if (element[0]['value']['scanCode'].indexOf(code) == -1) {

                      var item = barCodeScan[0].toString() +
                          "-" +
                          (element[9]['value']['rateValue'] -
                              double.parse(element[3]['value']['value']))
                              .toStringAsFixed(2)
                              .toString() +
                          "-" +
                          fsn;
                      element[10]['value']['label'] = (element[9]['value']
                      ['label'] -
                          double.parse(element[3]['value']['value']))
                          .toString();
                      element[10]['value']['value'] = (element[9]['value']
                      ['label'] -
                          double.parse(element[3]['value']['value']))
                          .toString();
                      barcodeNum = (double.parse(barcodeNum) -
                          (element[9]['value']['rateValue'] -
                              double.parse(element[3]['value']['value'])))
                          .toString();
                      element[3]['value']['value'] = (double.parse(
                          element[3]['value']['value']) +
                          (element[9]['value']['rateValue'] -
                              double.parse(element[3]['value']['value'])))
                          .toString();
                      element[3]['value']['label'] = element[3]['value']['value'];
                      residue = element[9]['value']['rateValue'] -
                          double.parse(element[3]['value']['value']);
                      element[0]['value']['kingDeeCode'].add(item);
                      element[0]['value']['scanCode'].add(code);
                    }
                    break;
                  } else {
                    //数量不超出
                    //判断条码是否重复
                    if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                      element[3]['value']['value'] =
                          (double.parse(element[3]['value']['value']) +
                              double.parse(barcodeNum))
                              .toString();
                      element[3]['value']['label'] =
                      element[3]['value']['value'];
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
                  if (element[4]['value']['value'] == "") {
                    element[4]['value']['label'] = barcodeData[0][6] == null? "":barcodeData[0][6];
                    element[4]['value']['value'] = barcodeData[0][7] == null? "":barcodeData[0][7];
                  }
                  if (element[1]['value']['value'] == "") {
                    element[1]['value']['label'] = barcodeData[0][12] == null? "":barcodeData[0][12];
                    element[1]['value']['value'] =barcodeData[0][12] == null? "":barcodeData[0][12];
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
                  if (element[5]['value']['value'] == "") {
                    element[5]['value']['label'] = scanCode[1];
                    element[5]['value']['value'] = scanCode[1];
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
                break;
              }
              if (element[5]['value']['value'] == scanCode[1]) {
                //判断扫描数量是否大于单据数量
                if (double.parse(element[3]['value']['value']) >=
                    element[9]['value']['rateValue']) {
                  continue;
                } else {
                  //判断条码数量
                  if ((double.parse(element[3]['value']['value']) +
                      double.parse(barcodeNum)) >
                      0 &&
                      double.parse(barcodeNum) > 0) {
                    if (element[4]['value']['value'] == "") {
                      element[4]['value']['label'] = barcodeData[0][6] == null? "":barcodeData[0][6];
                      element[4]['value']['value'] = barcodeData[0][7] == null? "":barcodeData[0][7];
                    }
                    if (element[1]['value']['value'] == "") {
                      element[1]['value']['label'] = barcodeData[0][12] == null? "":barcodeData[0][12];
                      element[1]['value']['value'] =barcodeData[0][12] == null? "":barcodeData[0][12];
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
                    if ((double.parse(element[3]['value']['value']) +
                        double.parse(barcodeNum)) >=
                        element[9]['value']['rateValue']) {
                      //判断条码是否重复
                      if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                        var item = barCodeScan[0].toString() +
                            "-" +
                            (element[9]['value']['rateValue'] -
                                double.parse(element[3]['value']['value']))
                                .toStringAsFixed(2)
                                .toString() +
                            "-" +
                            fsn;
                        element[10]['value']['label'] = (element[9]['value']
                        ['label'] -
                            double.parse(element[3]['value']['value']))
                            .toString();
                        element[10]['value']['value'] = (element[9]['value']
                        ['label'] -
                            double.parse(element[3]['value']['value']))
                            .toString();
                        barcodeNum = (double.parse(barcodeNum) -
                            (element[9]['value']['rateValue'] -
                                double.parse(element[3]['value']['value'])))
                            .toString();
                        element[3]['value']['value'] = (double.parse(
                            element[3]['value']['value']) +
                            (element[9]['value']['rateValue'] -
                                double.parse(element[3]['value']['value'])))
                            .toString();
                        element[3]['value']['label'] =
                        element[3]['value']['value'];
                        residue = element[9]['value']['rateValue'] -
                            double.parse(element[3]['value']['value']);
                        element[0]['value']['kingDeeCode'].add(item);
                        element[0]['value']['scanCode'].add(code);
                      }
                      break;
                    } else {
                      //数量不超出
                      //判断条码是否重复
                      if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                        element[3]['value']['value'] =
                            (double.parse(element[3]['value']['value']) +
                                double.parse(barcodeNum))
                                .toString();
                        element[3]['value']['label'] =
                        element[3]['value']['value'];
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

                  //判断扫描数量是否大于单据数量
                  if (double.parse(element[3]['value']['value']) >=
                      element[9]['value']['rateValue']) {
                    continue;
                  } else {
                    //判断条码数量
                    if ((double.parse(element[3]['value']['value']) +
                        double.parse(barcodeNum)) >
                        0 &&
                        double.parse(barcodeNum) > 0) {
                      if (element[4]['value']['value'] == "") {
                        element[4]['value']['label'] = barcodeData[0][6] == null? "":barcodeData[0][6];
                        element[4]['value']['value'] = barcodeData[0][7] == null? "":barcodeData[0][7];
                      }
                      if (element[1]['value']['value'] == "") {
                        element[1]['value']['label'] = barcodeData[0][12] == null? "":barcodeData[0][12];
                        element[1]['value']['value'] =barcodeData[0][12] == null? "":barcodeData[0][12];
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
                      element[5]['value']['label'] = scanCode[1];
                      element[5]['value']['value'] = scanCode[1];
                      if ((double.parse(element[3]['value']['value']) +
                          double.parse(barcodeNum)) >=
                          element[9]['value']['rateValue']) {
                        //判断条码是否重复
                        if (element[0]['value']['scanCode'].indexOf(code) ==
                            -1) {
                          var item = barCodeScan[0].toString() +
                              "-" +
                              (element[9]['value']['rateValue'] -
                                  double.parse(
                                      element[3]['value']['value']))
                                  .toStringAsFixed(2)
                                  .toString() +
                              "-" +
                              fsn;
                          element[10]['value']['label'] = (element[9]['value']
                          ['label'] -
                              double.parse(element[3]['value']['value']))
                              .toString();
                          element[10]['value']['value'] = (element[9]['value']
                          ['label'] -
                              double.parse(element[3]['value']['value']))
                              .toString();
                          barcodeNum = (double.parse(barcodeNum) -
                              (element[9]['value']['rateValue'] -
                                  double.parse(
                                      element[3]['value']['value'])))
                              .toString();
                          element[3]['value']['value'] =
                              (double.parse(element[3]['value']['value']) +
                                  (element[9]['value']['rateValue'] -
                                      double.parse(
                                          element[3]['value']['value'])))
                                  .toString();
                          element[3]['value']['label'] =
                          element[3]['value']['value'];
                          residue = element[9]['value']['rateValue'] -
                              double.parse(element[3]['value']['value']);
                          element[0]['value']['kingDeeCode'].add(item);
                          element[0]['value']['scanCode'].add(code);
                        }
                        break;
                      } else {
                        //数量不超出
                        //判断条码是否重复
                        if (element[0]['value']['scanCode'].indexOf(code) ==
                            -1) {
                          element[3]['value']['value'] =
                              (double.parse(element[3]['value']['value']) +
                                  double.parse(barcodeNum))
                                  .toString();
                          element[3]['value']['label'] =
                          element[3]['value']['value'];
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
            "title": "实收数量",
            "name": "FRealQty",
            "isHide": false,
            /*value[12]*/
            "value": {"label": "", "value": "0"}
          });
          arr.add({
            "title": "仓库",
            "name": "FStockID",
            "isHide": false,
            "value": {"label": this.storehouseName == null? "":this.storehouseName, "value": this.storehouseNumber == null? "":this.storehouseNumber,}
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
            "value": {"label": this.storingLocationName == null? "":this.storingLocationName, "value": this.storingLocationNumber == null? "":this.storingLocationNumber, "hide": showPosition}
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
            "title": "实到数量",
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
            "isHide": true,
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

  Widget _dateItem(title, model, hobby) {
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
              PartRefreshWidget(globalTKey, () {
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
                    (hobby == ""
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

  void _onDateClickItem(model,hobby) {
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
  void _onDateChildClickItem(model,hobby) {
    Pickers.showDatePicker(
      context,
      mode: model,
      suffix: Suffix.normal(),
      // selectDate: PDuration(month: 2),
      minDate: PDuration(year: 2020, month: 2, day: 10),
      maxDate: PDuration(second: 22),
      selectDate: (hobby['value']['label'] == '' || hobby['value']['label'] == null
          ? PDuration(year: 2021, month: 2, day: 10)
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
          if (hobby == 'supplier') {
            supplierName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                supplierNumber = supplierListObj[elementIndex][2];
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
          } else if(hobby['title']  == '包装规格'){
            setState(() {
              hobby['value']['label'] = p;
            });
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                hobby['value']['value'] = bagListObj[elementIndex][0];
              }
              elementIndex++;
            });
          }else {
            setState(() {
              hobby['value']['label'] = p;
            });
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                hobby['value']['value'] = stockListObj[elementIndex][2];
                stock[6]['value']['value'] = "";
                stock[6]['value']['label'] = "";
                stock[6]['value']['hide'] = stockListObj[elementIndex][3];
                //hobby['value']['dimension'] = stockListObj[elementIndex][4];
              }
              elementIndex++;
            });
          }
        });
      },
    );
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
      List<Widget> comList = [];
      for (int j = 0; j < this.hobby[i].length; j++) {
        if (!this.hobby[i][j]['isHide']) {
          if (j == 3 || j==5) {
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
              _item('仓库:', stockList, this.hobby[i][j]['value']['label'],
                  this.hobby[i][j],
                  stock: this.hobby[i]),
            );
          }else if (j == 11) {
            comList.add(
              _dateChildItem('生产日期：', DateMode.YMD, this.hobby[i][j]),
            );
          }else if (j == 1) {
            /*comList.add(
              _item('包装规格:', bagList, this.hobby[i][j]['value']['label'],
                  this.hobby[i][j],
                  stock: this.hobby[i]),
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
                          '：源单行号' +
                          this.hobby[i][j]["value"]["label"].toString(),style: TextStyle(
                        color: Colors.red, // 改变文本颜色为蓝色
                      ),),
                      trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                          Visibility(
                          visible: this.hobby[i][9]["value"]['value'] != double.parse(this.hobby[i][3]["value"]["value"]),//
                          child: FlatButton(
                              color: Colors.blue,
                              textColor: Colors.white,
                              child: new Text('复制行'),
                              onPressed: () {
                                setState(() {
                                  if(this.hobby[i][3]["value"]["value"] != "0"){
                                    if(double.parse(this.hobby[i][3]["value"]["value"]) < this.hobby[i][9]["value"]['rateValue']){
                                      var orderDataItem = List.from(this.orderDate);
                                      this.orderDate.insert(i, orderDataItem[i]);
                                      this.fNumber = [];
                                      var childItemNumber = 0;
                                      for(var value in orderDate){
                                        fNumber.add(value[5]);
                                        print(childItemNumber);
                                        print(i);
                                        if(childItemNumber == i){
                                          List arr = [];
                                          arr.add({
                                            "title": "物料名称",
                                            "name": "FMaterial",
                                            "FBaseUnitID": value[17],
                                            "FSRCBILLTYPEID": value[24],
                                            "FSRCBillNo": value[0],
                                            "FPOQTY": value[12],
                                            "FPOOrderNo": value[0],
                                            "FTaxPrice": value[18],
                                            "FEntryTaxRate": value[19],
                                            "FNote": value[23],
                                            "FID": value[14],
                                            "FEntryId": value[4],
                                            "FGiveAway": value[29],
                                            "FOrderBillNo": value[30],
                                            "FSrcEntryId": value[31],
                                            "FPayConditionId": value[32],
                                            "FSeq": value[33],
                                            "isHide": false,
                                            "value": {
                                              "label": value[6] + "- (" + value[5] + ")",
                                              "value": value[5],
                                              "barcode": [],
                                              "kingDeeCode": [],
                                              "scanCode": []
                                            }
                                          });
                                          arr.add({
                                            "title": "包装规格",
                                            "isHide": false,
                                            "name": "FMaterialIdFSpecification",
                                            "value": {"label": "", "value": ""}
                                            //"value": {"label": value[25]==null?"":value[25], "value": value[25]==null?"":value[25]}
                                          });
                                          arr.add({
                                            "title": "单位名称",
                                            "name": "FUnitId",
                                            "isHide": false,
                                            "value": {"label": value[11], "value": value[10]}
                                          });
                                          arr.add({
                                            "title": "实收数量",
                                            "name": "FRealQty",
                                            "isHide": false,
                                            /*value[12]*/
                                            "value": {"label": "", "value": "0"}
                                          });
                                          arr.add({
                                            "title": "仓库",
                                            "name": "FStockID",
                                            "isHide": false,
                                            "value": {"label": this.storehouseName == null? "":this.storehouseName, "value": this.storehouseNumber == null? "":this.storehouseNumber,}
                                          });
                                          arr.add({
                                            "title": "批号",
                                            "name": "FLot",
                                            "isHide": value[15] != true,
                                            "value": {"label": "", "value": ""}
                                          });
                                          arr.add({
                                            "title": "仓位",
                                            "name": "FStockLocID",
                                            "isHide": false,
                                            "value": {"label": this.storingLocationName == null? "":this.storingLocationName, "value": this.storingLocationNumber == null? "":this.storingLocationNumber, "hide": showPosition}
                                          });
                                          arr.add({
                                            "title": "操作",
                                            "name": "",
                                            "isHide": false,
                                            "value": {"label": value[33], "value": value[33]}
                                          });
                                          arr.add({
                                            "title": "库存单位",
                                            "name": "",
                                            "isHide": true,
                                            "value": {"label": value[18], "value": value[18]}
                                          });
                                          arr.add({
                                            "title": "实到数量",
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
                                            "isHide": true,
                                            "value": {"label": "0", "value": "0"}
                                          });
                                          arr.add({
                                            "title": "生产日期",
                                            "name": "FProduceDate",
                                            "isHide": false,
                                            "value": {"label": value[26].substring(0,10), "value": value[26].substring(0,10)}
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
                                      print(this.orderDate);
                                      print(this.hobby);
                                    }else{
                                      ToastUtil.showInfo('当前分录数量已达上限，不可增加行');
                                    }
                                  }else{
                                    ToastUtil.showInfo('为了避免总入库数量统计错误，请先录入当前分录数量再增加行');
                                  }
                                });
                              },
                            ),
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
                              keyboardType: checkItem == "HPoc"?TextInputType.text:(this.hobby[checkData][checkDataChild]["title"]=="批号"? TextInputType.text: TextInputType.number),
                              /*inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                          ],*/
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
                            if(checkItem == "HPoc"){
                              this.storingLocationName = _FNumber;
                              this.storingLocationNumber = _FNumber;
                              for(var hItem in this.hobby){
                                if(hItem[6]['value']['hide'] &&  hItem[6]['value']['value'] == ""){
                                  hItem[6]['value']['label'] = storingLocationName;
                                  hItem[6]['value']['value'] = storingLocationNumber;
                                }
                              }
                              Navigator.pop(context);
                            }else{
                              if(this.hobby[checkData][checkDataChild]["title"]=="实收数量"){
                                if(double.parse(_FNumber) <= this.hobby[checkData][9]["value"]['rateValue']){
                                  this.hobby[checkData][checkDataChild]["value"]
                                  ["label"] = _FNumber;
                                  this.hobby[checkData][checkDataChild]['value']
                                  ["value"] = _FNumber;
                                  Navigator.pop(context);
                                }else{
                                  ToastUtil.showInfo('输入数量大于可用数量');
                                }
                              }else if(checkItem == 'position'){
                                //录入仓位个数
                                var positionList = _FNumber.split(",");
                                if(positionList.length>1){
                                  positionList = positionList.toSet().toList();
                                  //输入数量除于包装规格，等于基础分录个数
                                  var lineSplit = (double.parse(this.hobby[checkData][3]["value"]["label"]) / double.parse(this.hobby[checkData][1]["value"]["label"].toString().replaceAll('kg', ''))).ceil();
                                  if(this.hobby[checkData][1]["value"]["label"] != "" && this.hobby[checkData][3]["value"]["label"] != ""){
                                    if(double.parse(this.hobby[checkData][3]["value"]["label"])>double.parse(this.hobby[checkData][1]["value"]["label"].toString().replaceAll('kg', '')) && double.parse(this.hobby[checkData][3]["value"]["label"]) > positionList.length){
                                      //判断以那个条件做拆分
                                      var splitNum = 0;
                                      if(positionList.length>lineSplit){
                                        splitNum = lineSplit;
                                      }else{
                                        splitNum = positionList.length;
                                      }
                                      //包装规格转换为数值，以便计算
                                      var packaging = double.parse(this.hobby[checkData][1]["value"]["label"].toString().replaceAll('kg', ''));
                                      //计算每个分录分配数量 默认为包装规格数量(前置条件为：入库数量必须大于包装规格)
                                      var itemNum = double.parse(this.hobby[checkData][1]["value"]["label"].toString().replaceAll('kg', ''));
                                      //输入的入库数量
                                      var inventoryQuantity = double.parse(this.hobby[checkData][3]["value"]["label"]);

                                      this.hobby[checkData][3]["value"]["label"] = packaging.toString();
                                      this.hobby[checkData][3]["value"]["value"] = packaging.toString();
                                      this.hobby[checkData][9]["value"]['label']=double.parse(this.hobby[checkData][3]["value"]["value"]);
                                      this.hobby[checkData][9]["value"]['value']=double.parse(this.hobby[checkData][3]["value"]["value"]);
                                      this.hobby[checkData][9]["value"]['rateValue']=double.parse(this.hobby[checkData][3]["value"]["value"]);
                                      this.hobby[checkData][checkDataChild]["value"]["label"] = positionList[0];
                                      this.hobby[checkData][checkDataChild]['value']["value"] = positionList[0];
                                      for(var i=1;i<splitNum;i++){
                                        var orderDataItem = List.from(this.orderDate);
                                        this.orderDate.insert(checkData, orderDataItem[checkData]);
                                        this.fNumber = [];
                                        var childItemNumber = 0;
                                        for(var value in orderDate){
                                          fNumber.add(value[5]);
                                          print(childItemNumber);
                                          print(i);
                                          if(childItemNumber == checkData){
                                            List arr = [];
                                            arr.add({
                                              "title": "物料名称",
                                              "name": "FMaterial",
                                              "FBaseUnitID": value[17],
                                              "FSRCBILLTYPEID": value[24],
                                              "FSRCBillNo": value[0],
                                              "FPOQTY": value[12],
                                              "FPOOrderNo": value[0],
                                              "FTaxPrice": value[18],
                                              "FEntryTaxRate": value[19],
                                              "FNote": value[23],
                                              "FID": value[14],
                                              "FEntryId": value[4],
                                              "FGiveAway": value[29],
                                              "FOrderBillNo": value[30],
                                              "FSrcEntryId": value[31],
                                              "isHide": false,
                                              "value": {
                                                "label": value[6] + "- (" + value[5] + ")",
                                                "value": value[5],
                                                "barcode": [],
                                                "kingDeeCode": [],
                                                "scanCode": []
                                              }
                                            });
                                            arr.add({
                                              "title": "包装规格",
                                              "isHide": false,
                                              "name": "FMaterialIdFSpecification",
                                              "value": {"label": this.hobby[checkData][1]["value"]["label"], "value": this.hobby[checkData][1]["value"]["value"]}
                                              //"value": {"label": value[25]==null?"":value[25], "value": value[25]==null?"":value[25]}
                                            });
                                            arr.add({
                                              "title": "单位名称",
                                              "name": "FUnitId",
                                              "isHide": false,
                                              "value": {"label": value[11], "value": value[10]}
                                            });
                                            arr.add({
                                              "title": "实收数量",
                                              "name": "FRealQty",
                                              "isHide": false,
                                              /*value[12]*/
                                              "value": {"label": (inventoryQuantity - itemNum > packaging ? packaging: inventoryQuantity - itemNum).toString(), "value": (inventoryQuantity - itemNum > packaging ? packaging: inventoryQuantity - itemNum).toString()}
                                            });
                                            arr.add({
                                              "title": "仓库",
                                              "name": "FStockID",
                                              "isHide": false,
                                              "value": {"label": this.hobby[checkData][4]["value"]["label"], "value": this.hobby[checkData][4]["value"]["value"]}
                                            });
                                            arr.add({
                                              "title": "批号",
                                              "name": "FLot",
                                              "isHide": value[15] != true,
                                              "value": {"label": this.hobby[checkData][5]["value"]["label"], "value": this.hobby[checkData][5]["value"]["label"]}
                                            });
                                            arr.add({
                                              "title": "仓位",
                                              "name": "FStockLocID",
                                              "isHide": false,
                                              "value": {"label": positionList[i], "value": positionList[i], "hide": true}
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
                                              "title": "实到数量",
                                              "name": "",
                                              "isHide": false,
                                              "value": {
                                                "label": double.parse(arr[3]["value"]["value"]),
                                                "value": double.parse(arr[3]["value"]["value"]),
                                                "rateValue": double.parse(arr[3]["value"]["value"])
                                              } /*+value[12]*0.1*/
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
                                              "isHide": false,
                                              "value": {"label": value[26].substring(0,10), "value": value[26].substring(0,10)}
                                            });
                                            if(inventoryQuantity - itemNum > packaging){
                                              itemNum = (itemNum* 100 + packaging* 100)/100;
                                            }else{
                                              itemNum = (itemNum* 100 + inventoryQuantity* 100 - itemNum* 100)/100;
                                            }
                                            hobby.insert(i, arr);
                                            break;
                                          }
                                          childItemNumber++;
                                        }
                                      }
                                      this._getHobby();
                                      //数量超出分录行数，需再循环累加数量至分录
                                      this.insertItemNum(checkData,itemNum,splitNum,packaging,inventoryQuantity);
                                      Navigator.pop(context);
                                    }else{
                                      ToastUtil.showInfo('输入数量必须大于库位个数和包装规格，否则不允许拆分');
                                    }
                                  }else{
                                    ToastUtil.showInfo('入库数量和包装规格需提前录入,否则无法拆分行');
                                    Navigator.pop(context);
                                  }
                                }else{
                                  Navigator.pop(context);
                                  this.hobby[checkData][checkDataChild]["value"]
                                  ["label"] = _FNumber;
                                  this.hobby[checkData][checkDataChild]['value']
                                  ["value"] = _FNumber;
                                }
                              }else{
                                Navigator.pop(context);
                                print(this.orderDate);
                                print(this.hobby);
                                this.hobby[checkData][checkDataChild]["value"]
                                ["label"] = _FNumber;
                                this.hobby[checkData][checkDataChild]['value']
                                ["value"] = _FNumber;
                              }
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
  //递归 数量轮询
  insertItemNum(checkData,itemNum,splitNum,packaging,inventoryQuantity) async{
    for(var i=checkData+splitNum-1;i>=checkData;i--){
      if(inventoryQuantity - itemNum >0){
        this.hobby[i][3]["value"]["label"] = ((double.parse(this.hobby[i][3]["value"]["value"])*100 + (inventoryQuantity - itemNum > packaging ? packaging: inventoryQuantity - itemNum)*100)/100).toString();
        this.hobby[i][3]["value"]["value"] = this.hobby[i][3]["value"]["label"];
        this.hobby[i][9]["value"]['label']=double.parse(this.hobby[i][3]["value"]["value"]);
        this.hobby[i][9]["value"]['value']=double.parse(this.hobby[i][3]["value"]["value"]);
        this.hobby[i][9]["value"]['rateValue']=double.parse(this.hobby[i][3]["value"]["value"]);
      }
      if(inventoryQuantity - itemNum > packaging){
        itemNum = (itemNum* 100 + packaging* 100)/100;
      }else{
        itemNum = (itemNum* 100 + inventoryQuantity* 100 - itemNum* 100)/100;
      }
    }
    if(inventoryQuantity - itemNum > 0){
      this.insertItemNum(checkData,itemNum,splitNum,packaging,inventoryQuantity);
    }
  }
  pushDown(val, type) async {
    //下推
    Map<String, dynamic> pushMap = Map();
    pushMap['EntryIds'] = val;
    pushMap['RuleId'] = "PUR_ReceiveBill-STK_InStock";
    pushMap['TargetFormId'] = "STK_InStock";
    pushMap['IsEnableDefaultRule'] = "false";
    pushMap['IsDraftWhenSaveFail'] = "false";
    var downData = await SubmitEntity.pushDown(
        {"formid": "PUR_ReceiveBill", "data": pushMap});
    var res = jsonDecode(downData);
    print(res);
    //判断成功
    if (res['Result']['ResponseStatus']['IsSuccess']) {
      //查询入库单
      var entitysNumber =
      res['Result']['ResponseStatus']['SuccessEntitys'][0]['Number'];
      Map<String, dynamic> inOrderMap = Map();
      inOrderMap['FormId'] = 'STK_InStock';
      inOrderMap['FilterString'] = "FBillNo='$entitysNumber'";
      inOrderMap['FieldKeys'] =
      'FInStockEntry_FEntryId,FMaterialId.FNumber,FMaterialId.FName,FUnitId.FNumber';
      String order = await CurrencyEntity.polling({'data': inOrderMap});
      print(order);
      var resData = jsonDecode(order);
      //组装数据
      Map<String, dynamic> dataMap = Map();
      dataMap['data'] = inOrderMap;
      Map<String, dynamic> orderMap = Map();
      orderMap['NeedUpDataFields'] = [
        'FInStockEntry',
      ];
      orderMap['IsDeleteEntry'] = false;
      Map<String, dynamic> Model = Map();
      Model['FID'] = res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id'];
      var FEntity = [];
      for (int entity = 0; entity < resData.length; entity++) {
        for (int element = 0; element < this.hobby.length; element++) {
          if (resData[entity][1].toString() ==
              this.hobby[element][0]['value']['value'].toString()) {
            Map<String, dynamic> FEntityItem = Map();
            FEntityItem['FEntryID'] = resData[entity][0];
            FEntityItem['FStockStatusId'] = {"FNumber": "KCZT01_SYS"};
            FEntityItem['FRealQty'] =
            this.hobby[element][3]['value']['value'];
            /*  FEntityItem['FStockId'] = {
              "FNumber": this.hobby[element][4]['value']['value']
            };
            var fSerialSub = [];
            var kingDeeCode = this.hobby[element][0]['value']['kingDeeCode'];
            for (int subj = 0; subj < kingDeeCode.length; subj++) {
              Map<String, dynamic> subObj = Map();
              var itemCode = kingDeeCode[subj].split("-");
              if (itemCode.length > 2) {
                if (itemCode.length > 3) {
                  subObj['FSerialNo'] = itemCode[2] + '-' + itemCode[3];
                } else {
                  subObj['FSerialNo'] = itemCode[2];
                }
              }
              fSerialSub.add(subObj);
            }
            FEntityItem['FSerialSubEntity'] = fSerialSub;*/
            FEntity.add(FEntityItem);
          }
        }
      }
      Model['FInStockEntry'] = FEntity;
      orderMap['Model'] = Model;
      dataMap = {"formid": "STK_InStock", "data": orderMap, "isBool": true};
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
  saveOrder(type) async {

    //获取登录信息
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    if (this.hobby.length > 0) {
      setState(() {
        this.isSubmit = true;
      });
      if (type) {
        var hobbyIndex = 0;
        var EntryIds = '';
        this.hobby.forEach((element) {
          if (double.parse(element[3]['value']['value']) > 0) {
            if (EntryIds == '') {
              EntryIds = orderDate[hobbyIndex][4].toString();
            } else {
              EntryIds = EntryIds + ',' + orderDate[hobbyIndex][4].toString();
            }
          }
          hobbyIndex++;
        });
        var resCheck = await this.pushDown(EntryIds, 'defective');
        print(resCheck);
        if (resCheck['isBool'] != false) {
          String order = await SubmitEntity.save(resCheck);
          var res = jsonDecode(order);
          print(res);
          if (res['Result']['ResponseStatus']['IsSuccess']) {
            print(resCheck);
            Map<String, dynamic> submitMap = Map();
            submitMap = {
              "formid": "STK_InStock",
              "data": {'Ids': resCheck['data']['Model']['FID']}
            };
            //提交
            HandlerOrder.orderHandler(context, submitMap, 1, "STK_InStock",
                SubmitEntity.submit(submitMap))
                .then((submitResult) {
              if (submitResult) {
                //审核
                HandlerOrder.orderHandler(context, submitMap, 1,
                    "STK_InStock", SubmitEntity.audit(submitMap))
                    .then((auditResult) async {
                  if (auditResult) {
                    //提交清空页面
                    setState(() {
                      this.hobby = [];
                      this.orderDate = [];
                      this.printData = {};
                      this.FBillNo = '';
                      ToastUtil.showInfo('提交成功');
                      Navigator.of(context).pop("refresh");
                    });
                  } else {
                    //失败后反审
                    HandlerOrder.orderHandler(context, submitMap, 0,
                        "STK_InStock", SubmitEntity.unAudit(submitMap))
                        .then((unAuditResult) {
                      if (unAuditResult) {
                        this.isSubmit = false;
                      } else {
                        this.isSubmit = false;
                      }
                    });
                  }
                });
              } else {
                this.isSubmit = false;
              }
            });
          };
        } else {
          setState(() {
            this.isSubmit = false;
            ToastUtil.errorDialog(context, resCheck['msg']);
          });
        }
      } else {
        Map<String, dynamic> dataMap = Map();
        dataMap['formid'] = 'STK_InStock';
        Map<String, dynamic> orderMap = Map();
        orderMap['NeedUpDataFields'] = [
          'FInStockEntry',
          'FSerialSubEntity',
          'FSerialNo'
        ];
        orderMap['NeedReturnFields'] = [
          'FInStockEntry',
          'FSerialSubEntity',
          'FSerialNo',
          'FBillNo',
          'FExpiryDate',
          'FMaterialName',
          'FProduceDate'
        ];
        orderMap['IsDeleteEntry'] = true;
        Map<String, dynamic> Model = Map();
        Model['FID'] = 0;
        Model['F_UUAC_Combo_re5'] = "1";
        Model['FBillTypeID'] = {"FNUMBER": "RKD01_SYS"};
        Model['FBusinessType'] = "CG";
        Model['F_UUAC_CheckBox'] = _checked;
        Model['FDate'] = FDate;
        //判断有源单 无源单
        if (this.isScanWork) {
          Model['FPurchaseOrgId'] = {"FNumber": this.fOrgID};
          Model['FStockOrgId'] = {"FNumber": this.fOrgID};
          Model['FSupplierId'] = {"FNumber": orderDate[0][1].toString()};
          Model['FOwnerTypeIdHead'] = {"FNumber": orderDate[0][1].toString()};
          Model['FOwnerIdHead'] = {"FNumber": orderDate[0][1].toString()};
        } else {
          if (this.departmentNumber == null) {
            this.isSubmit = false;
            ToastUtil.showInfo('请选择部门');
            return;
          }
          if (this.supplierNumber == null) {
            this.isSubmit = false;
            ToastUtil.showInfo('请选择供应商');
            return;
          }
          Model['FPurchaseOrgId'] = {"FNumber": this.fOrgID};
          Model['FStockOrgId'] = {"FNumber": this.fOrgID};
          Model['FStockDeptId'] = {"FNumber": this.departmentNumber};
          Model['FSupplierId'] = {"FNumber": this.supplierNumber};
          Model['FOwnerTypeIdHead'] = {"FNumber": orderDate[0][1].toString()};
          Model['FOwnerIdHead'] = {"FNumber": orderDate[0][1].toString()};
        }
        if (orderDate[0][21] != null) {
          Model['FPurchaseDeptId'] = {"FNumber": orderDate[0][21]};
        }
        if (orderDate[0][22] != null) {
          Model['FPurchaserId'] = {"FNumber": orderDate[0][22]};
        }
        var FEntity = [];
        var hobbyIndex = 0;
        for(var element in this.hobby){
          if (element[3]['value']['value'] != '0' && element[3]['value']['value'] != '' &&
              element[4]['value']['value'] != '') {
            Map<String, dynamic> FEntityItem = Map();
            FEntityItem['FMaterialId'] = {
              "FNumber": element[0]['value']['value']
            };
            FEntityItem['FUnitId'] = {"FNumber": element[2]['value']['value']};
            FEntityItem['FRemainInStockUnitId'] = {"FNumber": element[2]['value']['value']};
            FEntityItem['FBaseUnitID'] = {
              "FNumber": element[0]['FBaseUnitID']
            };
            FEntityItem['FPriceUnitId'] = {
              "FNumber": element[2]['value']['value']
            };
            FEntityItem['FSettleOrgId'] = {"FNumber": this.fOrgID};
            FEntityItem['FStockId'] = {"FNumber": element[4]['value']['value']};
            FEntityItem['FLot'] = {"FNumber": element[5]['value']['value']};
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
            var fSerialSub = [];
            var kingDeeCode = element[0]['value']['kingDeeCode'];
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
            FEntityItem['FOwnerId'] = {"FNumber": this.fOrgID};
            FEntityItem['FWWInType'] = "QLI";
            FEntityItem['FSRCBILLTYPEID'] = "PUR_ReceiveBill";
            FEntityItem['FSRCBillNo'] = element[0]['FSRCBillNo'];
            //FEntityItem['FPOQTY'] = orderDate[hobbyIndex][12];
            FEntityItem['FPOORDERENTRYID'] = element[0]['FSrcEntryId'];
            FEntityItem['FPOOrderNo'] = element[0]['FOrderBillNo'];
            FEntityItem['FRealQty'] = element[3]['value']['value'];
            FEntityItem['FBaseJoinQty'] = element[3]['value']['value'];
            FEntityItem['FSerialSubEntity'] = fSerialSub;
            /*FEntityItem['FOwnerTypeId'] = "BD_OwnerOrg";*/
            FEntityItem['FTaxPrice'] = element[0]['FTaxPrice'];
            FEntityItem['FEntryTaxRate'] = element[0]['FEntryTaxRate'];
            FEntityItem['FNote'] = element[0]['FNote'];
            FEntityItem['FGiveAway'] = element[0]['FGiveAway'];
            FEntityItem['FProduceDate'] = element[11]['value']['value'];
            //FEntityItem['FExpiryDate'] = orderDate[hobbyIndex][27];
            /*FEntityItem['FPrice'] = orderDate[hobbyIndex][20];*/
            FEntityItem['FInStockEntry_Link'] = [
              {
                "FInStockEntry_Link_FRuleId": "PUR_ReceiveBill-STK_InStock",
                "FInStockEntry_Link_FSTableName": "T_PUR_ReceiveEntry",
                "FInStockEntry_Link_FSBillId": element[0]['FID'],
                "FInStockEntry_Link_FSId": element[0]['FEntryId'],
                "FInStockEntry_Link_FBaseUnitQty": element[3]['value']['value'],
                "FInStockEntry_Link_FRemainInStockBaseQty": element[3]['value']['value']
              }
            ];
            FEntity.add(FEntityItem);
          }
          hobbyIndex++;
        };
        if (FEntity.length == 0) {
          this.isSubmit = false;
          ToastUtil.showInfo('请输入数量和仓库');
          return;
        }
        Model['FOwnerTypeIdHead'] = "BD_OwnerOrg";
        Model['FOwnerIdHead'] = {"FNumber": this.fOrgID};
        Map<String, dynamic> FinanceEntity = Map();
        FinanceEntity['FSettleOrgId'] = {"FNumber": this.fOrgID};
        FinanceEntity['FPayConditionId'] = {"FNumber": this.hobby[0][0]['FPayConditionId']};
        Model['FInStockFin'] = FinanceEntity;
        Model['FInStockEntry'] = FEntity;
        /*Model['FDescription'] = this._remarkContent.text;*/
        orderMap['Model'] = Model;
        dataMap['data'] = orderMap;
        print(jsonEncode(dataMap));
        var saveData = jsonEncode(dataMap);
        printData = dataMap;
        ToastUtil.showInfo('保存');
        String order = await SubmitEntity.save(dataMap);
        var res = jsonDecode(order);
        print(res);
        if (res['Result']['ResponseStatus']['IsSuccess']) {
          Map<String, dynamic> submitMap = Map();
          var returnData = res['Result']['NeedReturnData'];
          for(var p=0;p<printData['data']['Model']['FInStockEntry'].length;p++){
            printData['data']['Model']['FInStockEntry'][p]['FExpiryDate'] = returnData[0]['FInStockEntry'][p]['FExpiryDate'];
            printData['data']['Model']['FInStockEntry'][p]['FProduceDate'] = returnData[0]['FInStockEntry'][p]['FProduceDate'];
            printData['data']['Model']['FInStockEntry'][p]['FMaterialName'] = returnData[0]['FInStockEntry'][p]['FMaterialName'];
          }
          printData['FBillNo'] = returnData[0]['FBillNo'];
          printData['type'] = "STK_InStock";
          submitMap = {
            "formid": "STK_InStock",
            "data": {
              'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
            }
          };
          if(_checked){
            //提交
            HandlerOrder.orderHandler(context, submitMap, 1, "STK_InStock",
                SubmitEntity.submit(submitMap))
                .then((submitResult) async{
              if (submitResult) {
                //审核
                /*HandlerOrder.orderHandler(context, submitMap, 1,
                    "STK_InStock", SubmitEntity.audit(submitMap))
                    .then((auditResult) async {
                  if (auditResult) {*/
                    //打印确认
                    _showPrintDialog(context);
                    /*var errorMsg = "";
                  if (fBarCodeList == 1) {
                    for (int i = 0; i < this.hobby.length; i++) {
                      if (this.hobby[i][3]['value']['value'] != '0' &&
                          this.hobby[i][4]['value']['value'] != '') {
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
                          if (itemCode.length > 1) {
                            codeModel['FID'] = itemCode[0];
                            codeModel['FOwnerID'] = {"FNUMBER": deptData[1]};
                            codeModel['FStockOrgID'] = {"FNUMBER": deptData[1]};
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
                          }
                        }
                      }
                    }
                  }
                  if (errorMsg != "") {
                    ToastUtil.errorDialog(context, errorMsg);
                    this.isSubmit = false;
                  }*/
                  /*} else {
                    //失败后反审
                    HandlerOrder.orderHandler(context, submitMap, 0,
                        "STK_InStock", SubmitEntity.unAudit(submitMap))
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
          }else{
            //打印确认
            _showPrintDialog(context);
          }
        } else {
          setState(() {
            this.isSubmit = false;
            ToastUtil.errorDialog(context,
                res['Result']['ResponseStatus']['Errors'][0]['Message']);
          });
        }
      }
    } else {
      ToastUtil.showInfo('无提交数据');
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
                        return PrintPage(
                            data: printData
                          // 路由参数
                        );
                      },
                    ),
                  ).then((data) {

                  });
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
                  var number = 0;
                  for (int i = 0; i < this.hobby.length; i++) {
                    var kingDeeCode = this.hobby[i][0]['value']['kingDeeCode'];
                    if (kingDeeCode.length > 0) {
                      number++;
                    }
                  }
                  saveOrder(false);
                  /*if (number==0) {
                    saveOrder(false);
                  } else {
                    saveOrder(true);
                  }*/
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
          /*floatingActionButton: FloatingActionButton(
            onPressed: scan,
            tooltip: 'Increment',
            child: Icon(Icons.filter_center_focus),
          ),*/
          appBar: AppBar(
            title: Text("采购入库"),
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
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          /* title: TextWidget(FBillNoKey, '生产订单：'),*/
                          title: Text("单号：$fBillNo"),
                        ),
                      ),
                      divider,
                    ],
                  ), Column(
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
                  _dateItem('日期：', DateMode.YMD, ""),
                  Visibility(
                    maintainSize: false,
                    maintainState: false,
                    maintainAnimation: false,
                    visible: !isScanWork,
                    child: _item('供应商:', this.supplierList, this.supplierName,
                        'supplier'),
                  ),
                  Visibility(
                    maintainSize: false,
                    maintainState: false,
                    maintainAnimation: false,
                    visible: !isScanWork,
                    child: _item('部门', this.departmentList, this.departmentName,
                        'department'),
                  ),
                  /*_item('部门', ['生产部'], '生产部'),*/
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
