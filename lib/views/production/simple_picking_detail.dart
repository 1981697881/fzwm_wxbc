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
class SimplePickingDetail extends StatefulWidget {
  var FBillNo;

  SimplePickingDetail({Key ?key, @required this.FBillNo}) : super(key: key);

  @override
  _SimplePickingDetailState createState() => _SimplePickingDetailState(FBillNo);
}

class _SimplePickingDetailState extends State<SimplePickingDetail> {
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
  var customerName;
  var customerNumber;
  var departmentName;
  var departmentNumber;
  var outboundTypeName;
  var outboundTypeNumber;
  var organizationsName;
  var organizationsNumber;
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
  //包装规格
  var bagList = [];
  List<dynamic> bagListObj = [];
  var commodityList = [];
  List<dynamic> commodityListObj = [];
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
  var outboundTypeList = ['合格品入库','不合格品入库','报废品入库','返工品入库'];
  List<dynamic> outboundTypeListObj = [['1','合格品入库'],['2','不合格品入库'],['3','报废品入库'],['4','返工品入库']];
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
  var fBarCodeList;
  final controller = TextEditingController();
  List<TextEditingController> _textNumber2 = [];
  List<TextEditingController> _textNumber3 = [];
  List<TextEditingController> _textNumber4 = [];
  List<FocusNode> focusNodes = [];
  _SimplePickingDetailState(FBillNo) {
    if (FBillNo != null) {
      this.fBillNo = FBillNo['value'];
      this.getOrderList();
    }else{
      this.fBillNo = '';
      //_onEvent("31001;AQ40711305N1;2024-07-11;200;MO001684,1511255198;2");
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
    getCustomer();
    getDepartmentList();
    getOrganizationsList();
    getStockList();
    getBagList();
    getCommodity();
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
  //获取部门-
  getDepartmentList() async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var tissue = sharedPreferences.getString('tissue');
    userMap['FormId'] = 'BD_Department';
    userMap['FilterString'] = "FUseOrgId.FNumber ='"+tissue+"' and FIsStock = 1";
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
    userMap['FilterString'] = "FForbidStatus = 'A' and FDocumentStatus = 'C' and FUseOrgId.FNumber ='"+tissue+"'";// and FUseOrgId.FNumber ='"+deptData[1]+"'
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
  }//获取物料信息-成品
  getCommodity() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var tissue = sharedPreferences.getString('tissue');
    Map<String, dynamic> userMap = Map();
    userMap['FilterString'] = "FForbidStatus = 'A' and FUseOrgId.FNumber = '"+tissue+"' and FCategoryID in (241, 239)";
    userMap['FormId'] = 'BD_MATERIAL';
    userMap['FieldKeys'] =
    'FNumber,FName';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    commodityListObj = jsonDecode(res);
    commodityListObj.forEach((element) {
      commodityList.add(element[0]+"-"+element[1]);
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
    // 释放所有 Controller 和 FocusNode
    for (var controller in _textNumber2) {
      controller.dispose();
    }
    for (var controller in _textNumber3) {
      controller.dispose();
    }
    for (var controller in _textNumber4) {
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

  // 查询数据集合
  List hobby = [];
  List fNumber = [];
  getOrderList() async {
    Map<String, dynamic> userMap = Map();
    print(fBillNo);
    userMap['FilterString'] = "FBillNo='$fBillNo'";
    userMap['FormId'] = 'PUR_ReceiveBill';
    userMap['OrderString'] = 'FMaterialId.FNumber ASC';
    userMap['FieldKeys'] =
    'FBillNo,FSupplierId.FNumber,FSupplierId.FName,FDate,FDetailEntity_FEntryId,FMaterialId.FNumber,FMaterialId.FName,FMaterialId.FSpecification,FPurOrgId.FNumber,FPurOrgId.FName,FUnitId.FNumber,FUnitId.FName,FInStockQty,FSrcBillNo,FID';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    orderDate = [];
    orderDate = jsonDecode(order);
    FDate = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    selectData[DateMode.YMD] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    if (orderDate.length > 0) {
      hobby = [];
      orderDate.forEach((value) {
        List arr = [];
        fNumber.add(value[5]);
        arr.add({
          "title": "物料名称",
          "name": "FMaterial",
          "isHide": false,
          "value": {"label": value[6] + "- (" + value[5] + ")", "value": value[5],"barcode": []}
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
          "title": "出库数量",
          "name": "FRealQty",
          "isHide": false,
          "value": {"label": value[12], "value": value[12]}
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
          "isHide": false,
          "value": {"label": "", "value": ""}
        });
        arr.add({
          "title": "仓位",
          "name": "FStockLocID",
          "isHide": false,
          "value": {"label": "", "value": "","hide": false}
        });arr.add({
          "title": "加工费",
          "name": "",
          "isHide": true,
          "value": {"label": "0", "value": "0"}
        });arr.add({
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
          barcodeMap['FilterString'] = "FBarCodeEn='"+item[0]+"'";
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
              this.getMaterialList(barcodeData,barcodeData[0][10], barcodeData[0][11], barcodeData[0][13].substring(0, 10), barcodeData[0][14].substring(0, 10), barcodeData[0][15].trim(), barcodeData[0][16]);
              print("ChannelPage: $event");
            }else{
              ToastUtil.showInfo('该条码已出库或没入库，数量为零');
            }
          }else{
            ToastUtil.showInfo('条码不在条码清单中');
          }
        }

      }else{
        _code = event;
        this.getMaterialList("",_code,"","","", "", false);
        print("ChannelPage: $event");
      }
    }
  }

  void _onError(Object error) {
    setState(() {
      _code = "扫描异常";
    });
  }
  getMaterialList(barcodeData,code, fsn, fProduceDate, fExpiryDate, fLoc,fIsOpenLocation) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var tissue = sharedPreferences.getString('tissue');
    var scanCode = code.split(";");
    userMap['FilterString'] = "FNumber='" + scanCode[0] + "' and FForbidStatus = 'A' and FUseOrgId.FNumber = '"+tissue+"'";
    userMap['FormId'] = 'BD_MATERIAL';
    userMap['FieldKeys'] =
    'FMATERIALID,F_UUAC_Text,FNumber,FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FIsBatchManage,FIsKFPeriod';
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
        barCodeScan[4] = barCodeScan[4].toString();
      }else{
        barCodeScan = scanCode;
      }
      var fIsKFPeriod = materialDate[0][7];
      var barcodeNum = barCodeScan[4];
      for (var element in hobby) {
        var residue = 0.0;
        //判断是否启用批号
        if(element[5]['isHide']){//不启用
          if(element[0]['value']['value'] == scanCode[0]){ // && element[4]['value']['value'] == barCodeScan[7]
            if(element[0]['value']['barcode'].indexOf(code) == -1){
              //判断是否可重复扫码
              if(scanCode.length>4){
                element[0]['value']['barcode'].add(code);
              }
              if (element[4]['value']['value'] == "") {
                element[4]['value']['label'] = barcodeData[0][6] == null? "":barcodeData[0][6];
                element[4]['value']['value'] = barcodeData[0][7] == null? "":barcodeData[0][7];
              }
              if (element[1]['value']['value'] == "") {
                element[1]['value']['label'] = barcodeData[0][12] == null? "":barcodeData[0][12];
                element[1]['value']['value'] =barcodeData[0][12] == null? "":barcodeData[0][12];
              }
              if (element[11]['value']['value'] == "") {
                element[11]['value']['label'] = fProduceDate == null? "":fProduceDate;
                element[11]['value']['value'] =fProduceDate == null? "":fProduceDate;
                element[12]['value']['label'] =fExpiryDate == null? "":fExpiryDate;
                element[12]['value']['value'] =fExpiryDate == null? "":fExpiryDate;
              }
              if(fIsOpenLocation){
                element[6]['value']['hide'] = fIsOpenLocation;
                if (element[6]['value']['value'] == "") {
                  element[6]['value']['label'] = fLoc == null? "":fLoc;
                  element[6]['value']['value'] =fLoc == null? "":fLoc;
                }
              }
              //判断条码数量
              if((double.parse(element[3]['value']['value'])+double.parse(barcodeNum)) > 0 && double.parse(barcodeNum)>0){
                //判断条码是否重复
                if(element[0]['value']['scanCode'].indexOf(code) == -1){
                  element[3]['value']['value']=(double.parse(element[3]['value']['value'])+double.parse(barcodeNum)).toString();
                    element[3]['value']['label']=element[3]['value']['value'];
                  var item = barCodeScan[0].toString() + "-" + barcodeNum + "-" + fsn;
                  element[8]['value']['label'] =barcodeNum.toString();
                  element[8]['value']['value'] = barcodeNum.toString();
                  element[0]['value']['kingDeeCode'].add(item);
                  element[0]['value']['scanCode'].add(code);
                  barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                }
                number++;
                break;
              }
            }else{
              ToastUtil.showInfo('该标签已扫描');
              number++;
              break;
            }
          }
        }else{//启用批号
          print(element[0]['value']['value'] );
          print(scanCode[0]);
          print(element[4]['value']['value']);
          print(barCodeScan[6]);
          if(element[0]['value']['value'] == scanCode[0]){  //&& element[4]['value']['value'] == barCodeScan[7]
            if(element[0]['value']['barcode'].indexOf(code) == -1){
              if(element[5]['value']['value'] == scanCode[1]){
                //判断是否可重复扫码
                if(scanCode.length>4){
                  element[0]['value']['barcode'].add(code);
                }
                if (element[4]['value']['value'] == "") {
                  element[4]['value']['label'] = barcodeData[0][6] == null? "":barcodeData[0][6];
                  element[4]['value']['value'] = barcodeData[0][7] == null? "":barcodeData[0][7];
                }
                if (element[1]['value']['value'] == "") {
                  element[1]['value']['label'] = barcodeData[0][12] == null? "":barcodeData[0][12];
                  element[1]['value']['value'] =barcodeData[0][12] == null? "":barcodeData[0][12];
                }
                if (element[11]['value']['value'] == "") {
                  element[11]['value']['label'] = fProduceDate == null? "":fProduceDate;
                  element[11]['value']['value'] =fProduceDate == null? "":fProduceDate;
                  element[12]['value']['label'] =fExpiryDate == null? "":fExpiryDate;
                  element[12]['value']['value'] =fExpiryDate == null? "":fExpiryDate;
                }
                if(fIsOpenLocation){
                  element[6]['value']['hide'] = fIsOpenLocation;
                  if (element[6]['value']['value'] == "") {
                    element[6]['value']['label'] = fLoc == null? "":fLoc;
                    element[6]['value']['value'] =fLoc == null? "":fLoc;
                  }
                }
                //判断条码数量
                if((double.parse(element[3]['value']['value'])+double.parse(barcodeNum)) > 0 && double.parse(barcodeNum)>0){
                  //判断条码是否重复
                  if(element[0]['value']['scanCode'].indexOf(code) == -1){
                    element[3]['value']['value']=(double.parse(element[3]['value']['value'])+double.parse(barcodeNum)).toString();
                    element[3]['value']['label']=element[3]['value']['value'];
                    var item = barCodeScan[0].toString() + "-" + barcodeNum + "-" + fsn;
                    element[8]['value']['label'] =barcodeNum.toString();
                    element[8]['value']['value'] = barcodeNum.toString();
                    element[0]['value']['kingDeeCode'].add(item);
                    element[0]['value']['scanCode'].add(code);
                    barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                  }
                }
                number++;
                break;
              }else{
                if(element[5]['value']['value'] == ""){
                  //判断是否可重复扫码
                  if(scanCode.length>4){
                    element[0]['value']['barcode'].add(code);
                  }
                  element[5]['value']['label'] = scanCode[1];
                  element[5]['value']['value'] = scanCode[1];
                  //判断条码数量
                  if((double.parse(element[3]['value']['value'])+double.parse(barcodeNum)) > 0 && double.parse(barcodeNum)>0){
                    //判断条码是否重复
                    if(element[0]['value']['scanCode'].indexOf(code) == -1){
                      element[3]['value']['value']=(double.parse(element[3]['value']['value'])+double.parse(barcodeNum)).toString();
                    element[3]['value']['label']=element[3]['value']['value'];
                      var item = barCodeScan[0].toString() + "-" + barcodeNum + "-" + fsn;
                      element[8]['value']['label'] =barcodeNum.toString();
                      element[8]['value']['value'] = barcodeNum.toString();
                      element[0]['value']['kingDeeCode'].add(item);
                      element[0]['value']['scanCode'].add(code);
                      barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                    }
                  }
                  number++;
                  break;
                }
              }
            }else{
              ToastUtil.showInfo('该标签已扫描');
              number++;
              break;
            }
          }
        }
      }
      if(number == 0 && this.fBillNo ==""){
        for (var value in materialDate) {
        //materialDate.forEach((value) {
          List arr = [];
          arr.add({
            "title": "物料名称",
            "name": "FMaterial",
            "FIsKFPeriod": fIsKFPeriod,
            "isHide": false,
            "value": {"label": value[1] + "- (" + value[2] + ")", "value": value[2],"barcode": [code],"kingDeeCode": [barCodeScan[0].toString()+"-"+barCodeScan[4]+"-"+fsn],"scanCode": [barCodeScan[0].toString()+"-"+barCodeScan[4]]}
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
            "title": "出库数量",
            "name": "FRealQty",
            "isHide": false,
            "value": {"label": barCodeScan[4].toString(), "value": barCodeScan[4].toString()}
          });
          arr.add({
            "title": "仓库",
            "name": "FStockID",
            "isHide": false,
            "value": {"label": barcodeData[0][6], "value": barcodeData[0][7]}
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
              "isHide": value[6] != true,
              "value": {"label": value[6]?(scanCode.length>1?scanCode[1]:''):'', "value": value[6]?(scanCode.length>1?scanCode[1]:''):'',"fLotList": stocks}
            });
          }else{
            arr.add({
              "title": "批号",
              "name": "FLot",
              "isHide": value[6] != true,
              "value": {"label": value[6]?(scanCode.length>1?scanCode[1]:''):'', "value": value[6]?(scanCode.length>1?scanCode[1]:''):'',"fLotList": []}
            });
          }*/
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
            "title": "最后扫描数量",
            "name": "FLastQty",
            "isHide": false,
            "value": {
              "label": barCodeScan[4].toString(),
              "value": barCodeScan[4].toString(),"remainder": "0","representativeQuantity": barCodeScan[4].toString()
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
            "name": "",
            "isHide": !fIsKFPeriod,
            "value": {"label": barcodeData[0][13], "value": barcodeData[0][13]}
          }); arr.add({
            "title": "有效期",
            "name": "",
            "isHide": !fIsKFPeriod,
            "value": {"label": barcodeData[0][14], "value": barcodeData[0][14]}
          }); arr.add({
            "title": "生产编号",
            "name": "",
            "isHide": false,
            "value": {"label": "", "value": ""}
          }); arr.add({
            "title": "生产对象",
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
          } else if(hobby  == 'department'){
            departmentName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                departmentNumber = departmentListObj[elementIndex][2];
              }
              elementIndex++;
            });
          }else if (hobby == 'organizations') {
            organizationsName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                organizationsNumber = organizationsListObj[elementIndex][2];
              }
              elementIndex++;
            });
            getStockList();
          }else if(hobby  == 'outboundType'){
            outboundTypeName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                outboundTypeNumber = outboundTypeListObj[elementIndex][0];
              }
              elementIndex++;
            });
          }else if(hobby  == 'type'){
            typeName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                typeNumber = typeListObj[elementIndex][2];
              }
              elementIndex++;
            });
          }else{
            setState(() {
              setState(() {
                hobby['value']['label'] = p;
              });;
            });
            print(hobby['value']['label']);
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
  Future<List<int>?> _showMultiChoiceProduceBottomSheet(
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
                          for(var element in this.commodityListObj){
                            options.add(element[0]+"-"+element[1]);
                          }
                          setState(() {
                            options = options.where((item) => item.contains(value)).toList();
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
  void _moveCursorToEnd(controller) {
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
  }
  List<Widget> _getHobby() {
    List<Widget> tempList = [];
    for (int i = 0; i < this.hobby.length; i++) {
      List<Widget> comList = [];
      _textNumber2.add(TextEditingController());
      _textNumber3.add(TextEditingController());
      _textNumber4.add(TextEditingController());
      focusNodes.add(FocusNode());
      // 可选：添加监听（需注意内存管理）
      _setupListener(i);
      for (int j = 0; j < this.hobby[i].length; j++) {
        if (!this.hobby[i][j]['isHide']) {
          if (j == 13 ) {
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
                                  controller: _textNumber4[i], // 文本控制器
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
          } /*else  if (j == 5) {
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
                            await _showModalBottomSheet(
                                context, this.hobby[i][j]["value"]["fLotList"],this.hobby[i][j]["value"]);
                            setState(() {});
                          },
                        ),
                      ])),
                ),
                divider,
              ]),
            );
          }*/else if ( j == 9) {
            comList.add(
              Column(children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                      title: Text(this.hobby[i][j]["title"] +
                          '：' +
                          this.hobby[i][j]["value"]["label"].toString()),
                      trailing:Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                        /*IconButton(
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
                        ),*/
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
                                  this.hobby[i][10]["value"]["value"] = (realQty.ceil()).toString();
                                  this.hobby[i][10]["value"]["label"] = (realQty.ceil()).toString();
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
          }else if (j == 14) {
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
                                this.commodityList = [];
                                for(var element in this.commodityListObj){

                                  this.commodityList.add(element[0]+"-"+element[1]);
                                }
                                _showMultiChoiceProduceBottomSheet(context, this.commodityList,  this.hobby[i][j]);
                              },
                            ),
                          ])),
                ),
                divider,
              ]),
            );
          }else if (j == 4) {
            comList.add(
              _item('仓库:', stockList, this.hobby[i][j]['value']['label'],
                  this.hobby[i][j],stock:this.hobby[i]),
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
          } else if (j == 8) {
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
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')), // 允许小数和数字
                                ],
                                onChanged: (value) {
                                  if(value[0]=="0" && value.length>1){
                                    if(!value.contains('.')){
                                      value = value.substring(1);
                                      this._textNumber3[i].text = value;
                                      // 移动光标到末尾
                                      _moveCursorToEnd(this._textNumber3[i]);
                                    }
                                  }
                                  // 提交前检查并处理
                                  if (value.endsWith('.')) {
                                    value = value.substring(0, value.length - 1);
                                  }

                                    if(double.parse(value) <= double.parse(this.hobby[i][j]["value"]['representativeQuantity'])){
                                        if (this.hobby[i][0]['value']['kingDeeCode'].length > 0) {
                                          var kingDeeCode = this.hobby[i][0]['value']['kingDeeCode'][this.hobby[i][0]['value']['kingDeeCode'].length - 1].split("-");
                                          var realQty = 0.0;
                                          this.hobby[i][0]['value']['kingDeeCode'].forEach((item) {
                                            var qty = item.split("-")[1];
                                            realQty += double.parse(qty);
                                          });
                                          realQty = (realQty * 100 - double.parse(this.hobby[i][8]["value"]["label"]) * 100) / 100;
                                          realQty = (realQty * 100 + double.parse(value) * 100) / 100;
                                          this.hobby[i][8]["value"]["remainder"] = (Decimal.parse(this.hobby[i][8]["value"]["representativeQuantity"]) - Decimal.parse(value)).toString();
                                          this.hobby[i][3]["value"]["value"] = realQty.toString();
                                          this.hobby[i][3]["value"]["label"] = realQty.toString();
                                          this.hobby[i][j]["value"]["label"] = value;
                                          this.hobby[i][j]['value']["value"] = value;
                                          this.hobby[i][0]['value']['kingDeeCode'][this.hobby[i][0]['value']['kingDeeCode'].length - 1] = kingDeeCode[0] + "-" + value + "-" + kingDeeCode[2];
                                        } else {
                                          this._textNumber3[i].text = this.hobby[i][j]["value"]["value"];
                                          // 移动光标到末尾
                                          _moveCursorToEnd(this._textNumber3[i]);
                                          ToastUtil.showInfo('无条码信息，输入失败');
                                        }
                                    }else{
                                      this._textNumber3[i].text = this.hobby[i][j]["value"]["value"];
                                      // 移动光标到末尾
                                      _moveCursorToEnd(this._textNumber3[i]);
                                      ToastUtil.showInfo('输入数量大于条码可用数量');
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

          }else if(j == 6){
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
                              checkItem = 'position';
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
                              print(this.hobby[checkData][checkDataChild]["value"]['representativeQuantity']);
                                if(double.parse(_FNumber) <= double.parse(this.hobby[checkData][checkDataChild]["value"]['representativeQuantity'])){
                                  if (this.hobby[checkData][0]['value']['kingDeeCode'].length > 0) {
                                    var kingDeeCode = this.hobby[checkData][0]['value']['kingDeeCode'][this.hobby[checkData][0]['value']['kingDeeCode'].length - 1].split("-");
                                    var realQty = 0.0;
                                    this.hobby[checkData][0]['value']['kingDeeCode'].forEach((item) {
                                      var qty = item.split("-")[1];
                                      realQty += double.parse(qty);
                                    });
                                    realQty = (realQty * 100 - double.parse(this.hobby[checkData][8]["value"]["label"]) * 100) / 100;
                                    realQty = (realQty * 100 + double.parse(_FNumber) * 100) / 100;
                                    this.hobby[checkData][8]["value"]["remainder"] = (Decimal.parse(this.hobby[checkData][8]["value"]["representativeQuantity"]) - Decimal.parse(_FNumber)).toString();
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
                            }else if(checkItem=="bagNum"){
                              if(this.hobby[checkData][3]['value'] != '0'){
                                var realQty = 0.0;
                                realQty = double.parse(this.hobby[checkData][3]["value"]["label"]) / double.parse(_FNumber);
                                this.hobby[checkData][10]["value"]["value"] = (realQty.ceil()).toString();
                                this.hobby[checkData][10]["value"]["label"] = (realQty.ceil()).toString();
                                this.hobby[checkData][checkDataChild]["value"]
                                ["label"] = _FNumber;
                                this.hobby[checkData][checkDataChild]['value']
                                ["value"] = _FNumber;
                              }else{
                                ToastUtil.showInfo('请输入出库数量');
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
  //保存
  saveOrder() async {
    if (this.hobby.length > 0) {
      setState(() {
        this.isSubmit = true;
      });
      Map<String, dynamic> dataMap = Map();
      dataMap['formid'] = 'SP_PickMtrl';
      Map<String, dynamic> orderMap = Map();
      orderMap['NeedUpDataFields'] = ['FEntity','FSerialSubEntity','FSerialNo'];
      orderMap['NeedReturnFields'] = ['FBillNo'];
      orderMap['IsDeleteEntry'] = true;
      Map<String, dynamic> Model = Map();
      Model['FID'] = 0;
      Model['FBillType'] = {"FNUMBER": "JDSCLL01_SYS"};
      Model['FDate'] = FDate;
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      var tissue = sharedPreferences.getString('tissue');
      Model['FStockOrgId'] = {"FNumber": tissue};
      Model['FPrdOrgId'] = {"FNumber": tissue};
      Model['FOwnerId0'] = {"FNumber": tissue};
      Model['FWorkShopId'] = {"FNumber": this.departmentNumber};
      Model['FOwnerTypeId0'] = "BD_OwnerOrg";
      Model['FDescription'] = this._remarkContent.text;
      Model['F_UUAC_Combo_apv'] = "1";
      var FEntity = [];
      var hobbyIndex = 0;
      for(var element in this.hobby){
        if (element[3]['value']['value'] != '0' && element[3]['value']['value'] != '' &&
            element[4]['value']['value'] != '') {
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
          FEntityItem['FStockUnitId'] = {
            "FNumber": element[2]['value']['value']
          };
          //FEntityItem['FInStockType'] = this.outboundTypeNumber;
          FEntityItem['FOwnerTypeId'] = "BD_OwnerOrg";
          //FEntityItem['FProductNo'] = DateTime.now().millisecondsSinceEpoch.toString();
          FEntityItem['FStockId'] = {
            "FNumber": element[4]['value']['value']
          };
          FEntityItem['FProductNo'] = element[13]['value']['value'];
          FEntityItem['FProductId'] = {
            "FNumber": element[14]['value']['value'].split("-")[0]
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
          FEntityItem['FActualQty'] = element[3]['value']['value'];
          FEntityItem['FStockStatusId'] = {"FNumber": "KCZT01_SYS"};
          FEntityItem['FOwnerId'] = {"FNumber": tissue};
          FEntityItem['FKeeperTypeId'] = "BD_KeeperOrg";
          FEntityItem['FKeeperId'] = {"FNumber": tissue};
          FEntityItem['FLot'] = {"FNumber": element[5]['value']['value']};
          if(element[0]['FIsKFPeriod']){
            FEntityItem['FProduceDate'] = element[11]['value']['value'];
            FEntityItem['FExpiryDate'] = element[12]['value']['value'];
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
        ToastUtil.showInfo('请输入数量,仓库');
        return;
      }
      Model['FEntity'] = FEntity;
      orderMap['Model'] = Model;
      dataMap['data'] = orderMap;
      print(jsonEncode(dataMap));
      String order = await SubmitEntity.save(dataMap);
      var res = jsonDecode(order);
      print(res);
      var saveData = jsonEncode(dataMap);
      if (res['Result']['ResponseStatus']['IsSuccess']) {
        Map<String, dynamic> submitMap = Map();
        submitMap = {
          "formid": "SP_PickMtrl",
          "data": {
            'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
          }
        };
        //提交
        HandlerOrder.orderHandler(
            context,
            submitMap,
            1,
            "SP_PickMtrl",
            SubmitEntity.submit(submitMap))
            .then((submitResult) async{
          if (submitResult) {
            //审核
           /* HandlerOrder.orderHandler(
                context,
                submitMap,
                1,
                "SP_PickMtrl",
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
                    "SP_PickMtrl",
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
            title: Text("简单领料"),
            centerTitle: true,
            leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: (){
              Navigator.of(context).pop();
            }),
          ),
          body: Column(
            children: <Widget>[
              Expanded(
                child: ListView(children: <Widget>[
                  _dateItem('日期：', DateMode.YMD),
                  /*_item('组织', this.organizationsList, this.organizationsName,
                      'organizations'),*/
                  /*_item('客户:', this.customerList, this.customerName,
                      'customer'),

                 */
                  /*_item('类别', this.typeList, this.typeName,
                      'type'),

                  _item('入库类型', this.outboundTypeList, this.outboundTypeName,
                      'outboundType'),*/
                  _item('生产车间', this.departmentList, this.departmentName,
                      'department'),
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
