import 'dart:convert';
import 'package:date_format/date_format.dart';
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
import 'package:flutter_pickers/utils/check.dart';
import 'package:flutter/cupertino.dart';
import 'package:fzwm_wxbc/components/my_text.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubstepAllocationDetail extends StatefulWidget {
  var FBillNo;

  SubstepAllocationDetail({Key? key, @required this.FBillNo}) : super(key: key);

  @override
  _AllocationAffirmDetailState createState() => _AllocationAffirmDetailState(FBillNo);
}

class _AllocationAffirmDetailState extends State<SubstepAllocationDetail> {
  var _remarkContent = new TextEditingController();
  GlobalKey<TextWidgetState> textKey = GlobalKey();
  GlobalKey<PartRefreshWidgetState> globalKey = GlobalKey();

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
  var departmentList = [];
  List<dynamic> departmentListObj = [];
  var supplierList = [];
  List<dynamic> supplierListObj = [];
  var stockList = [];
  var typeList = [];
  List<dynamic> typeListObj = [];
  List<dynamic> stockListObj = [];
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
  var fBillNo;
  var fOrgID;
  var fBarCodeList;

  _AllocationAffirmDetailState(FBillNo) {
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
    EasyLoading.dismiss();
  }
  //获取部门
  getDepartmentList() async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    userMap['FormId'] = 'BD_Department';
    userMap['FieldKeys'] = 'FUseOrgId,FName,FNumber';
    userMap['FilterString'] = "FUseOrgId.FNumber ='"+deptData[1]+"'";
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
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BD_STOCK';
    userMap['FieldKeys'] = 'FStockID,FName,FNumber,FIsOpenLocation';
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    if(fOrgID == null){
      this.fOrgID = deptData[1];
    }
    userMap['FilterString'] = "FForbidStatus = 'A' and FUseOrgId.FNumber ="+fOrgID;
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
    Map<String, dynamic> userMap = Map();
    print(fBillNo);
    userMap['FilterString'] = "FBillNo='$fBillNo'";
    userMap['FormId'] = 'STK_TRANSFEROUT';
    userMap['OrderString'] = 'FMaterialId.FNumber ASC';
    userMap['FieldKeys'] =
    'FBillNo,FStockOrgId.FNumber,FStockOrgId.FName,FDate,FSTKTRSOUTENTRY_FEntryId,FMaterialId.FNumber,FMaterialId.FName,FMaterialId.FSpecification,FStockInOrgID.FNumber,FStockInOrgID.FName,FBaseUnitID.FNumber,FBaseUnitID.FName,FSrcStockId.FNumber,FSrcStockId.FName,FID,FMaterialId.FIsBatchManage,FDestStockId.FNumber,FDestStockId.FName,FUnitID.FNumber,FQty,FOwnerIdHead.FNumber';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    orderDate = [];
    orderDate = jsonDecode(order);
    FDate = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    selectData[DateMode.YMD] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    hobby = [];
    if (orderDate.length > 0) {
      this.fOrgID = orderDate[0][8];
      orderDate.forEach((value) {
        fNumber.add(value[5]);
        List arr = [];
        arr.add({
          "title": "物料名称",
          "name": "FMaterial",
          "isHide": false,
          "value": {"label": value[6] + "- (" + value[5] + ")", "value": value[5],"barcode": [],"kingDeeCode": []}
        });
        arr.add({
          "title": "规格型号",
          "isHide": true,
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
          "title": "实拨数量",
          "name": "FRealQty",
          "isHide": false,/*value[12]*/
          "value": {"label": "0", "value": "0"}
        });
        arr.add({
          "title": "调入仓库",
          "name": "FStockID",
          "isHide": false,
          "value": {"label": value[17], "value": value[16]}
        });
        arr.add({
          "title": "批号",
          "name": "FLot",
          "isHide": value[15] != true,
          "value": {"label": "", "value": ""}
        });
        arr.add({
          "title": "调出仓库",
          "name": "FStockLocID",
          "isHide": false,
          "value": {"label": value[13], "value": value[12]}
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
          "title": "调拨数量",
          "name": "",
          "isHide": false,
          "value": {"label": value[19], "value": value[19]}
        });
        arr.add({
          "title": "最后扫描数量",
          "name": "FLastQty",
          "isHide": false,
          "value": {
            "label": "0",
            "value": "0"
          }
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
    /* getStockList();*/
  }

  void _onEvent( event) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var deptData = sharedPreferences.getString('menuList');
    var menuList = new Map<dynamic, dynamic>.from(jsonDecode(deptData));
    fBarCodeList = menuList['FBarCodeList'];
    if(fBarCodeList == 1){
      Map<String, dynamic> barcodeMap = Map();
      barcodeMap['FilterString'] = "FBarCode='"+event+"'";
      barcodeMap['FormId'] = 'QDEP_BarCodeList';
      barcodeMap['FieldKeys'] =
      'FID,FInQtyTotal,FOutQtyTotal,FEntity_FEntryId,FRemainQty,FStockID.FName,FStockID.FNumber,F_QDEP_MName,FOwnerID.FNumber,FPackageSpec';
      Map<String, dynamic> dataMap = Map();
      dataMap['data'] = barcodeMap;
      String order = await CurrencyEntity.polling(dataMap);
      var barcodeData = jsonDecode(order);
      if (barcodeData.length>0) {
        if(barcodeData[0][4]>0){
          var msg = "";
          var orderIndex = 0;
          for (var value in orderDate) {
            if(value[5] == barcodeData[0][7]){
              /*if(value[20] == barcodeData[0][8]){
                if(value[16] == barcodeData[0][6]){

                }else{
                  msg = '条码仓库与单据仓库不一致';
                  if(fNumber.lastIndexOf(barcodeData[0][7])  == orderIndex){
                    break;
                  }
                }
              }else{
                msg = '条码货主与单据货主不一致';
                if(fNumber.lastIndexOf(barcodeData[0][7])  == orderIndex){
                  break;
                }
              }*/
              msg = "";
              if(fNumber.lastIndexOf(barcodeData[0][7])  == orderIndex){
                break;
              }
            }else{
              msg = '条码不在单据物料中';
            }
            orderIndex++;
          };
          if(msg ==  ""){
            _code = event;
            this.getMaterialList(barcodeData,_code);
            print("ChannelPage: $event");
          }else{
            ToastUtil.showInfo(msg);
          }

        }else{
          ToastUtil.showInfo('即时库存余额不足');
        }
      }else{
        ToastUtil.showInfo('条码不在条码清单中');
      }
    }else{
      _code = event;
      this.getMaterialList("",_code);
      print("ChannelPage: $event");
    }
  }
  getMaterialList(barcodeData,code) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    var scanCode = code.split(",");
    userMap['FilterString'] = "FNumber='"+scanCode[0]+"' and FForbidStatus = 'A' and FUseOrgId.FNumber = '"+deptData[1]+"'";
    userMap['FormId'] = 'BD_MATERIAL';
    userMap['FieldKeys'] =
    'FMATERIALID,F_UUAC_Text,FNumber,FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FIsBatchManage';/*,SubHeadEntity1.FStoreUnitID.FNumber*/
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    materialDate = [];
    materialDate = jsonDecode(order);
    FDate = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    selectData[DateMode.YMD] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    if (materialDate.length > 0) {
      var number = 0;
      var barCodeScan;
      if(fBarCodeList == 1){
        barCodeScan = barcodeData[0];
        barCodeScan.add(barCodeScan[4]);
        barCodeScan[4] = barCodeScan[4].toString();
      }else{
        barCodeScan = scanCode;
        barCodeScan.add(barCodeScan[4]);
      }
      var barcodeNum = scanCode[4];
      for (var element in hobby) {
        var residue = 0.0;
        //判断是否启用批号
        if(element[5]['isHide']){//不启用
          if(element[0]['value']['value'] == scanCode[0]){
            if(element[0]['value']['barcode'].indexOf(code) == -1){
              //判断是否可重复扫码
              if(scanCode.length>4){
                element[0]['value']['barcode'].add(code);
              }
              if(scanCode[5] == "N" ){
                  element[3]['value']['value']=(double.parse(element[3]['value']['value'])+double.parse(barcodeNum)).toString();
                    element[3]['value']['label']=element[3]['value']['value'];
                  var item = barCodeScan[0].toString()+"-"+barcodeNum;
                  element[0]['value']['kingDeeCode'].add(item);
                  element[10]['value']['label'] = barcodeNum.toString();
                  element[10]['value']['value'] = barcodeNum.toString();
                  barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                break;
              }

              //判断扫描数量是否大于单据数量
              if(double.parse(element[3]['value']['value']) >= element[9]['value']['label']) {
                  continue;
              }else {
                if((double.parse(element[3]['value']['value'])+double.parse(barCodeScan[4])) >= element[9]['value']['label']){
                  //判断条码是否重复
                  if(element[0]['value']['kingDeeCode'].indexOf(barCodeScan[0].toString()+"-"+element[3]['value']['value']) == -1){
                    var item = barCodeScan[0].toString()+"-"+(element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toStringAsFixed(2).toString();
                    element[10]['value']['label'] = (element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toString();
                    element[10]['value']['value'] = (element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toString();
                    element[3]['value']['value']=(double.parse(element[3]['value']['value'])+(element[9]['value']['label'] - double.parse(element[3]['value']['value']))).toString();
                      element[3]['value']['label']=element[3]['value']['value'];
                    residue = element[9]['value']['label'] - double.parse(element[3]['value']['value']);
                    element[0]['value']['kingDeeCode'].add(item);
                  }else{
                    //获取已存在下标
                    var index = element[0]['value']['kingDeeCode'].indexOf(barCodeScan[0].toString()+"-"+element[3]['value']['value']);
                    element[10]['value']['label'] = (element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toString();
                    element[10]['value']['value'] = (element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toString();
                    element[3]['value']['value']=(double.parse(element[3]['value']['value'])+(element[9]['value']['label'] - double.parse(element[3]['value']['value']))).toString();
                      element[3]['value']['label']=element[3]['value']['value'];
                    residue = element[9]['value']['label'] - double.parse(element[3]['value']['value']);
                    element[0]['value']['kingDeeCode'][index] = barCodeScan[0].toString()+"-"+element[3]['value']['value'];
                  }
                }else{//数量不超出
                  //判断条码是否重复
                  if(element[0]['value']['kingDeeCode'].indexOf(barCodeScan[0].toString()+"-"+element[3]['value']['value']) == -1){
                    element[10]['value']['label'] = barCodeScan[4];
                    element[10]['value']['value'] = barCodeScan[4];
                    element[3]['value']['label']=(double.parse(element[3]['value']['value'])+double.parse(barCodeScan[4])).toString();
                    element[3]['value']['value']=element[3]['value']['label'];
                    var item = barCodeScan[0].toString()+"-"+element[3]['value']['value'];
                    element[0]['value']['kingDeeCode'].add(item);
                  }else{
                    //获取已存在下标
                    element[10]['value']['label'] = barCodeScan[4];
                    element[10]['value']['value'] = barCodeScan[4];
                    var index = element[0]['value']['kingDeeCode'].indexOf(barCodeScan[0].toString()+"-"+element[3]['value']['value']);
                    element[3]['value']['label']=(double.parse(element[3]['value']['value'])+double.parse(barCodeScan[4])).toString();
                    element[3]['value']['value']=element[3]['value']['label'];
                    element[0]['value']['kingDeeCode'][index] = barCodeScan[0].toString()+"-"+element[3]['value']['value'];
                  }
                  break;
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
              //判断是否可重复扫码
              if(scanCode.length>4){
                element[0]['value']['barcode'].add(code);
              }
              if(scanCode[5] == "N" ){
                if(element[5]['value']['value'] == "") {
                  element[5]['value']['label'] = scanCode[1];
                  element[5]['value']['value'] = scanCode[1];
                }
                element[3]['value']['value']=(double.parse(element[3]['value']['value'])+double.parse(barcodeNum)).toString();
                    element[3]['value']['label']=element[3]['value']['value'];
                var item = barCodeScan[0].toString()+"-"+barcodeNum;
                element[0]['value']['kingDeeCode'].add(item);
                element[10]['value']['label'] = barcodeNum.toString();
                element[10]['value']['value'] = barcodeNum.toString();
                barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                break;
              }
              if(element[5]['value']['value'] == scanCode[1]){

                //判断扫描数量是否大于单据数量
                if(double.parse(element[3]['value']['value']) >= element[9]['value']['label']) {
                    continue;
                }else {
                  if((double.parse(element[3]['value']['value'])+double.parse(barCodeScan[4])) >= element[9]['value']['label']){
                    //判断条码是否重复
                    if(element[0]['value']['kingDeeCode'].indexOf(barCodeScan[0].toString()+"-"+element[3]['value']['value']) == -1){
                      var item = barCodeScan[0].toString()+"-"+(element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toStringAsFixed(2).toString();
                      element[10]['value']['label'] = (element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toString();
                      element[10]['value']['value'] = (element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toString();
                      element[3]['value']['value']=(double.parse(element[3]['value']['value'])+(element[9]['value']['label'] - double.parse(element[3]['value']['value']))).toString();
                      element[3]['value']['label']=element[3]['value']['value'];
                      residue = element[9]['value']['label'] - double.parse(element[3]['value']['value']);
                      element[0]['value']['kingDeeCode'].add(item);
                    }else{
                      //获取已存在下标
                      var index = element[0]['value']['kingDeeCode'].indexOf(barCodeScan[0].toString()+"-"+element[3]['value']['value']);
                      element[10]['value']['label'] = (element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toString();
                      element[10]['value']['value'] = (element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toString();
                      element[3]['value']['value']=(double.parse(element[3]['value']['value'])+(element[9]['value']['label'] - double.parse(element[3]['value']['value']))).toString();
                      element[3]['value']['label']=element[3]['value']['value'];
                      residue = element[9]['value']['label'] - double.parse(element[3]['value']['value']);
                      element[0]['value']['kingDeeCode'][index] = barCodeScan[0].toString()+"-"+element[3]['value']['value'];
                    }
                  }else{//数量不超出
                    //判断条码是否重复
                    if(element[0]['value']['kingDeeCode'].indexOf(barCodeScan[0].toString()+"-"+element[3]['value']['value']) == -1){
                      element[10]['value']['label'] = barCodeScan[4];
                      element[10]['value']['value'] = barCodeScan[4];
                      element[3]['value']['label']=(double.parse(element[3]['value']['value'])+double.parse(barCodeScan[4])).toString();
                      element[3]['value']['value']=element[3]['value']['label'];
                      var item = barCodeScan[0].toString()+"-"+element[3]['value']['value'];
                      element[0]['value']['kingDeeCode'].add(item);
                    }else{
                      //获取已存在下标
                      var index = element[0]['value']['kingDeeCode'].indexOf(barCodeScan[0].toString()+"-"+element[3]['value']['value']);
                      element[10]['value']['label'] = barCodeScan[4];
                      element[10]['value']['value'] = barCodeScan[4];
                      element[3]['value']['label']=(double.parse(element[3]['value']['value'])+double.parse(barCodeScan[4])).toString();
                      element[3]['value']['value']=element[3]['value']['label'];
                      element[0]['value']['kingDeeCode'][index] = barCodeScan[0].toString()+"-"+element[3]['value']['value'];
                    }
                    break;
                  }
                }
              }else{
                if(element[5]['value']['value'] == ""){
                  element[5]['value']['label'] = scanCode[1];
                  element[5]['value']['value'] = scanCode[1];
                  //判断扫描数量是否大于单据数量
                  if(double.parse(element[3]['value']['value']) >= element[9]['value']['label']) {
                      continue;
                  }else {
                    if((double.parse(element[3]['value']['value'])+double.parse(barCodeScan[4])) >= element[9]['value']['label']){
                      //判断条码是否重复
                      if(element[0]['value']['kingDeeCode'].indexOf(barCodeScan[0].toString()+"-"+element[3]['value']['value']) == -1){
                        var item = barCodeScan[0].toString()+"-"+(element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toStringAsFixed(2).toString();
                        element[10]['value']['label'] = (element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toString();
                        element[10]['value']['value'] = (element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toString();
                        element[3]['value']['value']=(double.parse(element[3]['value']['value'])+(element[9]['value']['label'] - double.parse(element[3]['value']['value']))).toString();
                      element[3]['value']['label']=element[3]['value']['value'];
                        residue = element[9]['value']['label'] - double.parse(element[3]['value']['value']);
                        element[0]['value']['kingDeeCode'].add(item);
                      }else{
                        //获取已存在下标
                        var index = element[0]['value']['kingDeeCode'].indexOf(barCodeScan[0].toString()+"-"+element[3]['value']['value']);
                        element[10]['value']['label'] = (element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toString();
                        element[10]['value']['value'] = (element[9]['value']['label'] - double.parse(element[3]['value']['value'])).toString();
                        element[3]['value']['value']=(double.parse(element[3]['value']['value'])+(element[9]['value']['label'] - double.parse(element[3]['value']['value']))).toString();
                      element[3]['value']['label']=element[3]['value']['value'];
                        residue = element[9]['value']['label'] - double.parse(element[3]['value']['value']);
                        element[0]['value']['kingDeeCode'][index] = barCodeScan[0].toString()+"-"+element[3]['value']['value'];
                      }
                    }else{//数量不超出
                      //判断条码是否重复
                      if(element[0]['value']['kingDeeCode'].indexOf(barCodeScan[0].toString()+"-"+element[3]['value']['value']) == -1){
                        element[10]['value']['label'] = barCodeScan[4];
                        element[10]['value']['value'] = barCodeScan[4];
                        element[3]['value']['label']=(double.parse(element[3]['value']['value'])+double.parse(barCodeScan[4])).toString();
                        element[3]['value']['value']=element[3]['value']['label'];
                        var item = barCodeScan[0].toString()+"-"+element[3]['value']['value'];
                        element[0]['value']['kingDeeCode'].add(item);
                      }else{
                        //获取已存在下标
                        element[10]['value']['label'] = barCodeScan[4];
                        element[10]['value']['value'] = barCodeScan[4];
                        var index = element[0]['value']['kingDeeCode'].indexOf(barCodeScan[0].toString()+"-"+element[3]['value']['value']);
                        element[3]['value']['label']=(double.parse(element[3]['value']['value'])+double.parse(barCodeScan[4])).toString();
                        element[3]['value']['value']=element[3]['value']['label'];
                        element[0]['value']['kingDeeCode'][index] = barCodeScan[0].toString()+"-"+element[3]['value']['value'];
                      }
                      break;
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
          if(hobby  == 'supplier'){
            supplierName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                supplierNumber = supplierListObj[elementIndex][2];
              }
              elementIndex++;
            });
          } else if(hobby  == 'department'){
            departmentName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                departmentNumber = departmentListObj[elementIndex][2];
              }
              elementIndex++;
            });
          }else{
            setState(() {
              hobby['value']['label'] = p;
            });
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
          /*if (j == 3 || j==5) {
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
          } else if(j == 6){
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
              ),

            );
          }else */if (j == 7) {
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
                              if(this.hobby[checkData][0]['value']['kingDeeCode'].length >0){
                                var kingDeeCode =this.hobby[checkData][0]['value']['kingDeeCode'][this.hobby[checkData][0]['value']['kingDeeCode'].length-1].split("-");
                                var realQty = 0.0;
                                this.hobby[checkData][0]['value']['kingDeeCode'].forEach((item) {
                                  var qty = item.split("-")[1];
                                  realQty += double.parse(qty);
                                });
                                realQty = realQty - double.parse(this.hobby[checkData][10]["value"]["label"]);
                                realQty = realQty + double.parse(_FNumber);
                                // if(realQty > this.hobby[checkData][9]["value"]["label"]){
                                //   ToastUtil.showInfo('总数量大于应发数量');
                                // }else{
                                  this.hobby[checkData][3]["value"]
                                  ["value"] = realQty.toString();
                                  this.hobby[checkData][3]["value"]
                                  ["label"] = realQty.toString();
                                  this.hobby[checkData][checkDataChild]["value"]
                                  ["label"] = _FNumber;
                                  this.hobby[checkData][checkDataChild]['value']
                                  ["value"] = _FNumber;
                                  this.hobby[checkData][0]['value']['kingDeeCode'][this.hobby[checkData][0]['value']['kingDeeCode'].length-1] = kingDeeCode[0]+"-"+_FNumber;
                                //}
                              }else{
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
  //下推
  pushDown() async {
    if (this.hobby.length > 0) {
      setState(() {
        this.isSubmit = true;
      });
     /* var val = [];
      var hobbyIndex = 0;
      this.hobby.forEach((element) {
        if (element[3]['value']['value'] != '0') {
          val.add(orderDate[hobbyIndex][4]);
        }
        hobbyIndex++;
      });*/
      //下推
      Map<String, dynamic> pushMap = Map();
      /*pushMap['EntryIds'] = val; */
      pushMap['Ids'] = orderDate[0][14];
      pushMap['RuleId'] = "STK_TRANSFEROUT-STK_TRANSFERIN";
      pushMap['TargetFormId'] = "STK_TRANSFERIN";
      pushMap['IsEnableDefaultRule'] = "false";
      pushMap['IsDraftWhenSaveFail'] = "false";
      print(pushMap);
      var downData =
      await SubmitEntity.pushDown({"formid": "STK_TRANSFEROUT", "data": pushMap});
      print(downData);
      var res = jsonDecode(downData);
      //判断成功
      if (res['Result']['ResponseStatus']['IsSuccess']) {
        //查询单据
        var entitysNumber =
        res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id'];
        Map<String, dynamic> OrderMap = Map();
        OrderMap['FormId'] = 'STK_TRANSFERIN';
        OrderMap['FilterString'] = "FID='$entitysNumber'";
        OrderMap['FieldKeys'] =
        'FID,FSTKTRSINENTRY_FEntryId,FStockId.FNumber,FMaterialId.FNumber,FBillNo';
        String order = await CurrencyEntity.polling({'data': OrderMap});
        var resData = jsonDecode(order);
        collarOrderDate = resData;
        /*saveOrder();*/
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
  //保存
  saveOrder() async {
    if (this.hobby.length > 0) {
      setState(() {
        this.isSubmit = true;
      });
      Map<String, dynamic> dataMap = Map();
      dataMap['formid'] = 'STK_TRANSFERIN';
      Map<String, dynamic> orderMap = Map();
      orderMap['NeedReturnFields'] = [];
      orderMap['IsDeleteEntry'] = false;
      Map<String, dynamic> Model = Map();
      Model['FID'] = collarOrderDate[0][0];
      var FEntity = [];
      var hobbyIndex = 0;
      this.hobby.forEach((element) {
        if (element[3]['value']['value'] != '0') {
          Map<String, dynamic> FEntityItem = Map();
          FEntityItem['FEntryID'] = collarOrderDate[hobbyIndex][1];
          /*FEntityItem['FSrcStockStatusId'] = {"FNumber": "KCZT01_SYS"};
          FEntityItem['FDestStockStatusId'] = {"FNumber": "KCZT01_SYS"};*/
          FEntityItem['FQty'] = element[3]['value']['value'];
          FEntity.add(FEntityItem);
        }
        hobbyIndex++;
      });
      if (FEntity.length == 0) {
        this.isSubmit = false;
        ToastUtil.showInfo('请输入数量');
        return;
      }
      Model['FSTKTRSINENTRY'] = FEntity;
      orderMap['Model'] = Model;
      dataMap['data'] = orderMap;
      print(jsonEncode(dataMap));
      String order = await SubmitEntity.save(dataMap);
      var res = jsonDecode(order);
      print(res);
      if (res['Result']['ResponseStatus']['IsSuccess']) {
        Map<String, dynamic> submitMap = Map();
        submitMap = {
          "formid": "STK_TRANSFERIN",
          "data": {
            'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
          }
        };
        //提交
        HandlerOrder.orderHandler(
            context,
            submitMap,
            1,
            "STK_TRANSFERIN",
            SubmitEntity.submit(submitMap))
            .then((submitResult) {
          if (submitResult) {
            //审核
            HandlerOrder.orderHandler(
                context,
                submitMap,
                1,
                "STK_TRANSFERIN",
                SubmitEntity.audit(submitMap))
                .then((auditResult) async {
              if (auditResult) {
                var errorMsg = "";
                if(fBarCodeList == 1){
                  for (int i = 0; i < this.hobby.length; i++) {
                    if (this.hobby[i][3]['value']['value'] != '0') {
                      var kingDeeCode = this.hobby[i][0]['value']['kingDeeCode'];
                      for(int j = 0;j<kingDeeCode.length;j++){
                        Map<String, dynamic> dataCodeMap = Map();
                        dataCodeMap['formid'] = 'QDEP_BarCodeList';
                        Map<String, dynamic> orderCodeMap = Map();
                        orderCodeMap['NeedReturnFields'] = [];
                        orderCodeMap['IsDeleteEntry'] = false;
                        Map<String, dynamic> codeModel = Map();
                        var itemCode = kingDeeCode[j].split("-");
                        codeModel['FID'] = itemCode[0];
                        for(var j =0;j<2;j++){
                          if(j==0){
                            /*codeModel['FLastCheckTime'] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);*/
                            Map<String, dynamic> codeFEntityItem = Map();
                            codeFEntityItem['FBillDate'] = FDate;
                            codeFEntityItem['FOutQty'] = itemCode[1];
                            codeFEntityItem['FEntryBillNo'] = orderDate[i][0];
                            codeFEntityItem['FEntryStockID'] ={
                              "FNUMBER": this.hobby[i][6]['value']['value']
                            };
                            var codeFEntity = [codeFEntityItem];
                            codeModel['FEntity'] = codeFEntity;
                            orderCodeMap['Model'] = codeModel;
                            dataCodeMap['data'] = orderCodeMap;
                            print(dataCodeMap);
                            String codeRes = await SubmitEntity.save(dataCodeMap);
                            print(codeRes);
                            var barcodeRes = jsonDecode(codeRes);
                            if(!barcodeRes['Result']['ResponseStatus']['IsSuccess']){
                              errorMsg +="错误反馈："+itemCode[1]+":"+barcodeRes['Result']['ResponseStatus']['Errors'][0]['Message'];
                            }
                          }else{
                            codeModel['FOwnerID'] = {
                              "FNUMBER": orderDate[i][20]
                            };
                            codeModel['FStockOrgID'] = {
                              "FNUMBER": orderDate[i][8]
                            };
                            codeModel['FStockID'] = {
                              "FNUMBER": this.hobby[i][4]['value']['value']
                            };
                            /*codeModel['FLastCheckTime'] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);*/
                            Map<String, dynamic> codeFEntityItem = Map();
                            codeFEntityItem['FBillDate'] = FDate;
                            codeFEntityItem['FInQty'] = itemCode[1];
                            codeFEntityItem['FEntryBillNo'] = collarOrderDate[i][4];
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
                    "STK_TRANSFERIN",
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
  @override
  Widget build(BuildContext context) {
    return FlutterEasyLoading(
      child: Scaffold(
          appBar: AppBar(
            title: Text("分步式调拨"),
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
                          /* title: TextWidget(FBillNoKey, '生产订单：'),*/
                          title: Text("单号：$fBillNo"),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  _dateItem('日期：', DateMode.YMD),
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
                    child:_item('部门',  this.departmentList, this.departmentName,
                        'department'),
                  ),
                  /*_item('部门', ['生产部'], '生产部'),*/
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
