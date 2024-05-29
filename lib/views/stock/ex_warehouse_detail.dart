import 'dart:convert';
import 'package:date_format/date_format.dart';
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

  _ExWarehouseDetailState(FBillNo) {
    if (FBillNo != null) {
      this.fBillNo = FBillNo['value'];
      this.getOrderList();
    }else{
      this.fBillNo = '';
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
    getCustomer();
    getStockList();
    getDepartmentList();


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
    userMap['FilterString'] = "FForbidStatus = 'A' and FUseOrgId.FNumber ='"+tissue+"'";
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
        });
        arr.add({
          "title": "加工费",
          "name": "",
          "isHide": false,
          "value": {"label": "0", "value": "0"}
        });
        arr.add({
          "title": "操作",
          "name": "",
          "isHide": false,
          "value": {"label": "", "value": ""}
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
    if(fBarCodeList == 1){
      Map<String, dynamic> barcodeMap = Map();
      barcodeMap['FilterString'] = "FBarCodeEn='"+event+"'";
      barcodeMap['FormId'] = 'QDEP_Cust_BarCodeList';
      barcodeMap['FieldKeys'] =
      'FID,FInQtyTotal,FOutQtyTotal,FEntity_FEntryId,FRemainQty,FBarCodeQty,FStockID.FName,FStockID.FNumber,FMATERIALID.FNUMBER,FOwnerID.FNumber,FBarCode,FSN,FPackageSpec';
      Map<String, dynamic> dataMap = Map();
      dataMap['data'] = barcodeMap;
      String order = await CurrencyEntity.polling(dataMap);
      var barcodeData = jsonDecode(order);
      if (barcodeData.length>0) {
        print(barcodeData);
        if(barcodeData[0][4]>0){
          _code = event;
          this.getMaterialList(barcodeData,barcodeData[0][10], barcodeData[0][11], barcodeData[0][12]);
          print("ChannelPage: $event");
        }else{
          ToastUtil.showInfo('该条码已出库或没入库，数量为零');
        }
      }else{
        ToastUtil.showInfo('条码不在条码清单中');
      }
    }else{
      _code = event;
      this.getMaterialList("",_code,"","");
      print("ChannelPage: $event");
    }
  }

  void _onError(Object error) {
    setState(() {
      _code = "扫描异常";
    });
  }
  getMaterialList(barcodeData,code, fsn,fAuxPropId) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var tissue = sharedPreferences.getString('tissue');
    var scanCode = code.split(";");
    userMap['FilterString'] = "FNumber='" + scanCode[0] + "' and FForbidStatus = 'A' and FUseOrgId.FNumber = '"+tissue+"'";
    userMap['FormId'] = 'BD_MATERIAL';
    userMap['FieldKeys'] =
    'FMATERIALID,F_UUAC_Text,FNumber,FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FIsBatchManage,FStockId.FName,FStockId.FNumber';
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
      var barcodeNum = scanCode[3];
      for (var element in hobby) {
        var residue = 0.0;
        //判断是否启用批号
        if(element[5]['isHide']){//不启用
          if(element[0]['value']['value'] == scanCode[0] && element[4]['value']['value'] == barCodeScan[7]){
            if(element[0]['value']['barcode'].indexOf(code) == -1){
              //判断是否可重复扫码
              if(scanCode.length>4){
                element[0]['value']['barcode'].add(code);
              }
              //判断条码数量
              if((double.parse(element[3]['value']['label'])+double.parse(barcodeNum)) > 0 && double.parse(barcodeNum)>0){
                //判断条码是否重复
                if(element[0]['value']['scanCode'].indexOf(code) == -1){
                  element[3]['value']['label']=(double.parse(element[3]['value']['label'])+double.parse(barcodeNum)).toString();
                  element[3]['value']['value']=element[3]['value']['label'];
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
          if(element[0]['value']['value'] == scanCode[0] && element[4]['value']['value'] == barCodeScan[7]){
            if(element[0]['value']['barcode'].indexOf(code) == -1){
              if(element[5]['value']['value'] == scanCode[1]){
                //判断是否可重复扫码
                if(scanCode.length>4){
                  element[0]['value']['barcode'].add(code);
                }
                //判断条码数量
                if((double.parse(element[3]['value']['label'])+double.parse(barcodeNum)) > 0 && double.parse(barcodeNum)>0){
                  //判断条码是否重复
                  if(element[0]['value']['scanCode'].indexOf(code) == -1){
                    element[3]['value']['label']=(double.parse(element[3]['value']['label'])+double.parse(barcodeNum)).toString();
                    element[3]['value']['value']=element[3]['value']['label'];
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
                  if((double.parse(element[3]['value']['label'])+double.parse(barcodeNum)) > 0 && double.parse(barcodeNum)>0){
                    //判断条码是否重复
                    if(element[0]['value']['scanCode'].indexOf(code) == -1){
                      element[3]['value']['label']=(double.parse(element[3]['value']['label'])+double.parse(barcodeNum)).toString();
                      element[3]['value']['value']=element[3]['value']['label'];
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
          List arr = [];
          arr.add({
            "title": "物料名称",
            "name": "FMaterial",
            "isHide": false,
            "value": {"label": value[1] + "- (" + value[2] + ")", "value": value[2],"barcode": [code],"kingDeeCode": [barCodeScan[0].toString()+"-"+scanCode[3]+"-"+fsn],"scanCode": [barCodeScan[0].toString()+"-"+scanCode[3]]}
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
            "value": {"label": scanCode[3].toString(), "value": scanCode[3].toString()}
          });
          arr.add({
            "title": "仓库",
            "name": "FStockID",
            "isHide": false,
            "value": {"label": '', "value": ''}
          });
          Map<String, dynamic> inventoryMap = Map();
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
          }
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
            "title": "最后扫描数量",
            "name": "FLastQty",
            "isHide": false,
            "value": {
              "label": scanCode[3].toString(),
              "value": scanCode[3].toString()
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
            _onEvent("13095;20190618考科;2019-06-18;1;,1006124995;2");
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
  List<Widget> _getHobby() {
    List<Widget> tempList = [];
    for (int i = 0; i < this.hobby.length; i++) {
      List<Widget> comList = [];
      for (int j = 0; j < this.hobby[i].length; j++) {
        if (!this.hobby[i][j]['isHide']) {
          if (j == 5) {
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
          }else if ( j == 9) {
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
          } else if (j == 4) {
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
                                realQty = realQty - double.parse(this.hobby[checkData][8]["value"]["label"]);
                                realQty = realQty + double.parse(_FNumber);
                                this.hobby[checkData][3]["value"]
                                ["value"] = realQty.toString();
                                this.hobby[checkData][3]["value"]
                                ["label"] = realQty.toString();
                                this.hobby[checkData][checkDataChild]["value"]
                                ["label"] = _FNumber;
                                this.hobby[checkData][checkDataChild]['value']
                                ["value"] = _FNumber;
                                this.hobby[checkData][0]['value']['kingDeeCode'][this.hobby[checkData][0]['value']['kingDeeCode'].length-1] = kingDeeCode[0]+"-"+_FNumber;

                              }else{
                                ToastUtil.showInfo('无条码信息，输入失败');
                              }
                            }else if(checkItem=="bagNum"){
                              if(this.hobby[checkData][3]['value'] != '0'){
                                var realQty = 0.0;
                                realQty = double.parse(this.hobby[checkData][3]["value"]["label"]) / double.parse(_FNumber);
                                this.hobby[checkData][8]["value"]["value"] = realQty.toString();
                                this.hobby[checkData][8]["value"]["label"] = realQty.toString();
                                this.hobby[checkData][checkDataChild]["value"]
                                ["label"] = _FNumber;
                                this.hobby[checkData][checkDataChild]['value']
                                ["value"] = _FNumber;
                              }else{
                                ToastUtil.showInfo('请输入出库数量');
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
  //保存
  saveOrder() async {
    if (this.hobby.length > 0) {
      setState(() {
        this.isSubmit = true;
      });
      if (this.departmentNumber  == null && this.customerNumber  == null) {
        this.isSubmit = false;
        ToastUtil.showInfo('部门和客户不能全为空');
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
      Model['FBillTypeID'] = {"FNUMBER": "QTCKD01_SYS"};
      Model['FDate'] = FDate;
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      var tissue = sharedPreferences.getString('tissue');
      Model['FStockOrgId'] = {"FNumber": tissue};
      Model['FPickOrgId'] = {"FNumber": tissue};
      if (this.departmentNumber  != null) {
        Model['FDeptId'] = {"FNumber": this.departmentNumber};
        Model['F_UUAC_Text_83g'] = this.departmentName;
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
      var FEntity = [];
      var hobbyIndex = 0;
      this.hobby.forEach((element) {
        if (element[3]['value']['value'] != '0' &&
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
          FEntityItem['FStockId'] = {
            "FNumber": element[4]['value']['value']
          };
          FEntityItem['FStockLocId'] = {
            "FSTOCKLOCID__FF100011": {
              "FNumber": element[6]['value']['value']
            }
          };
          FEntityItem['FAuxPropId'] = {
            "FAUXPROPID__FF100002": {"FNumber": element[1]['value']['value']}
          };
          /*FEntityItem['FReturnType'] = 1;*/
          FEntityItem['FQty'] = element[3]['value']['value'];
          FEntityItem['FOWNERTYPEID'] = "BD_OwnerOrg";
          FEntityItem['FSTOCKSTATUSID'] = {"FNumber": "KCZT01_SYS"};
          FEntityItem['FOWNERID'] = {"FNumber": tissue};
          FEntityItem['FOwnerId'] = {"FNumber": tissue};
          FEntityItem['FKeeperTypeId'] = "BD_KeeperOrg";
          FEntityItem['FKeeperId'] = {"FNumber": tissue};
          FEntityItem['FLot'] = {"FNumber": element[5]['value']['value']};
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
      });
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
            //审核
           /* HandlerOrder.orderHandler(
                context,
                submitMap,
                1,
                "STK_MisDelivery",
                SubmitEntity.audit(submitMap))
                .then((auditResult) async{
              if (auditResult) {
                print(auditResult);
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
                        *//*codeModel['FOwnerID'] = {
                          "FNUMBER": deptData[1]
                        };
                        codeModel['FStockOrgID'] = {
                          "FNUMBER": deptData[1]
                        };
                        codeModel['FStockID'] = {
                          "FNUMBER": this.hobby[i][4]['value']['value']
                        };*//*
                        *//*codeModel['FLastCheckTime'] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);*//*
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
              } else {
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
                  /*Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          *//* title: TextWidget(FBillNoKey, '生产订单：'),*//*
                          title: Text("单号：$fBillNo"),
                        ),
                      ),
                      divider,
                    ],
                  ),*/
                  _dateItem('日期：', DateMode.YMD),
                  /*_item('组织', this.organizationsList, this.organizationsName,
                      'organizations'),*/
                  _item('客户:', this.customerList, this.customerName,
                      'customer'),
                  _item('部门', this.departmentList, this.departmentName,
                      'department'),
                  _item('出库类型', this.outboundTypeList, this.outboundTypeName,
                      'outboundType'),
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
