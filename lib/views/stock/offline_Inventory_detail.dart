import 'dart:convert';
import 'package:date_format/date_format.dart';
import 'package:fzwm_wxbc/model/currency_entity.dart';
import 'package:fzwm_wxbc/model/submit_entity.dart';
import 'package:fzwm_wxbc/utils/SqfLiteQueueDataOffline.dart';
import 'package:fzwm_wxbc/utils/SqfLiteQueueDataRepertoire.dart';
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

class OfflineInventoryDetail extends StatefulWidget {
  var FBillNo;

  OfflineInventoryDetail({Key? key, @required this.FBillNo}) : super(key: key);

  @override
  _OfflineInventoryDetailState createState() =>
      _OfflineInventoryDetailState(FBillNo);
}

class _OfflineInventoryDetailState extends State<OfflineInventoryDetail> {
  var _remarkContent = new TextEditingController();
  GlobalKey<TextWidgetState> textKey = GlobalKey();
  GlobalKey<PartRefreshWidgetState> globalKey = GlobalKey();
  final GlobalKey globalListKey = GlobalKey();
  late ScrollController _scrollController;
  final _textNumber = TextEditingController();
  var checkItem;
  String FBillNo = '';
  String FSaleOrderNo = '';
  String FName = '';
  String FNumber = '';
  String FDate = '';
  var fBarCodeList;
  var sessionDate;
  var customerName;
  var customerNumber;
  var departmentName;
  var departmentNumber;
  var organizationsName;
  var organizationsNumber;
  var stockName;
  var stockNumber;
  var schemeName;
  var schemeNumber;
  var show = false;
  var isError = false;
  var isSubmit = false;
  var isScanWork = false;
  var isCumulative = "否";
  var checkData;
  var checkDataChild;
  var selectData = {
    DateMode.YMD: "",
  };
  var stockList = [];
  List<dynamic> barCodeList = [];
  List<dynamic> stockListObj = [];
  var organizationsList = [];
  List<dynamic> organizationsListObj = [];
  var schemeList = [];
  List<dynamic> schemeListObj = [];
  var departmentList = [];
  List<dynamic> departmentListObj = [];
  var customerList = [];
  List<dynamic> customerListObj = [];
  List<dynamic> orderDate = [];
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
  var fID;

  _OfflineInventoryDetailState(FBillNo) {
    if (FBillNo != null) {
      this.fBillNo = FBillNo['value'];
      this.getOrderList();
    } else {
      this.fBillNo = '';
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    DateTime dateTime = DateTime.now();
    var nowDate = "${dateTime.year}-${dateTime.month}-${dateTime.day}";
    selectData[DateMode.YMD] = nowDate;
    EasyLoading.dismiss();
    /// 开启监听
    if (_subscription == null && this.fBillNo == '') {
      _subscription = scannerPlugin
          .receiveBroadcastStream()
          .listen(_onEvent, onError: _onError);
    }
    getOrganizationsList();
    getSchemeList();
    getStockList();
  }
  //选择条码清单保存本地
  getBarcodeList({int startRow = 0,int page = 1}) async {
    if (this.schemeNumber != null) {
      EasyLoading.show(status: 'loading...');
      Map<String, dynamic> barcodeMap = Map();
      barcodeMap['FormId'] = 'QDEP_BarCodeList';
      barcodeMap['StartRow'] = startRow;
      barcodeMap['FilterString'] = "FStockID.FNumber = '$stockNumber'";
      barcodeMap['FieldKeys'] =
      'FID,FBillNo,FCreateOrgId,FBarCode,FOwnerID,FMATERIALID,F_QDEP_MName,FStockOrgID,F_QDEP_MSpec,FStockID.FNumber,FInQtyTotal,FOutQtyTotal,FRemainQty,FMUnitName,FOrder,FBatchNo,FProduceDate,FLastCheckTime';
      Map<String, dynamic> dataMap = Map();
      dataMap['data'] = barcodeMap;
      String order = await CurrencyEntity.polling(dataMap);
      if(jsonDecode(order).length == 2000){
        getBarcodeList(startRow:page*2000,page:page+1);
        barCodeList..addAll(jsonDecode(order));
      }else{
        if(jsonDecode(order).length>0){
          barCodeList..addAll(jsonDecode(order));
        }
        if (barCodeList.length > 0) {
          /*if(barcodeData.length == 2000){
          startRow++;
          dataMap["barcodeMap"] = startRow*2000;
          String limitData = await CurrencyEntity.polling(dataMap);
          List<dynamic> barcodeLimitData = jsonDecode(limitData);
        }*/
          SqfLiteQueueDataRepertoire.deleteTableData();
          var barcodeDataIndex = 0;
          for (var value in barCodeList) {
            barcodeDataIndex++;
            SqfLiteQueueDataRepertoire.insertData(
                value[0],
                value[1],
                value[2],
                value[3],
                value[4],
                value[5],
                value[6],
                value[7],
                value[8],
                value[9],
                value[10],
                value[11],
                value[12],
                value[13],
                value[14].toString(),
                value[15],
                value[16],
                value[17],barCodeList.length,barcodeDataIndex);
          }
        } else {
          EasyLoading.dismiss();
          ToastUtil.showInfo('无条码清单数据');
        }
      }
    }
  }
  //选择盘点方案保存本地
  getInventorySessions() async {
    EasyLoading.show(status: 'loading...');
    SharedPreferences sharedPreferences =
    await SharedPreferences.getInstance();
    var deptData = sharedPreferences.getString('menuList');
    var menuList = new Map<dynamic, dynamic>.from(jsonDecode(deptData));
    fBarCodeList = menuList['FBarCodeList'];
    if (this.schemeNumber != null) {
      Map<String, dynamic> userMap = Map();
      userMap['FilterString'] = "FSchemeNo = '$schemeNumber'";
      userMap['FormId'] = 'STK_StockCountInput';
      userMap['FieldKeys'] =
          'FStockOrgId.FNumber,FMaterialId.FName,FMaterialId.FNumber,FMaterialId.FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FStockId.FNumber,FAcctQty,FStockName,FLot.FNumber,FStockStatusId.FNumber,FKeeperTypeId,FKeeperId.FNumber,FOwnerId.FNumber,FBillEntry_FEntryID,FID';
      Map<String, dynamic> dataMap = Map();
      dataMap['data'] = userMap;
      String order = await CurrencyEntity.polling(dataMap);
      var resData = jsonDecode(order);
      if (resData.length > 0) {
        fID = resData[0][15];
        SqfLiteQueueDataOffline.searchDates(
            "select * from offline_Inventory_cache where schemeNumber='$schemeNumber'")
            .then((value) {
          var res = jsonEncode(value);
          if (jsonDecode(res).length > 0) {
            var resInventory = jsonDecode(res);
            _showInventoryDialog(resInventory);
          }
        });
        SqfLiteQueueDataOffline.deleteTableData();
        var resDataIndex = 0;
        for (var value in resData) {
          resDataIndex++;
          SqfLiteQueueDataOffline.insertData(
              this.fID,
              this.schemeName,
              this.schemeNumber,
              this.organizationsName == null ? "" : this.organizationsName,
              this.organizationsNumber == null ? "" : this.organizationsNumber,
              this.stockName == null ? "" : this.stockName,
              this.stockNumber == null ? "" : this.stockNumber,
              value[1] + "- (" + value[2] + ")",
              value[2],
              value[3],
              value[4],
              value[5],
              value[7],
              "0",
              value[8],
              value[6],
              value[9] == null ? "" : value[9],
              value[0],
              value[13],
              value[10],
              value[11],
              value[12],
              value[14],
              "",resData.length,resDataIndex);
        }
      } else {
        EasyLoading.dismiss();
        ToastUtil.showInfo('该盘点作业无数据');
      }
    }
  }
  //获取盘点方案
  getSchemeList() async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    userMap['FormId'] = 'STK_StockCountScheme';
    userMap['FieldKeys'] = 'FStockOrgId,FName,FBillNo';
    userMap['FilterString'] =
        "FDocumentStatus = 'C' and FCloseStatus ='0' and FStockOrgId.FNumber ='" +
            deptData[1] +
            "'";
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    schemeListObj = jsonDecode(res);
    schemeListObj.forEach((element) {
      schemeList.add(element[1]);
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

  //获取部门
  getDepartmentList() async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    userMap['FormId'] = 'BD_Department';
    userMap['FieldKeys'] = 'FUseOrgId,FName,FNumber';
    userMap['FilterString'] = "FUseOrgId.FNumber ='" + deptData[1] + "'";
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
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    userMap['FilterString'] =
        "FForbidStatus = 'A' and FDocumentStatus = 'C' and FUseOrgId.FNumber =" + deptData[1];
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
  @override
  void dispose() {
    this._textNumber.dispose();
    this._scrollController.dispose();
    super.dispose();

    /// 取消监听
    if (_subscription != null) {
      _subscription!.cancel();
    }
  }
  // 查询数据集合
  List hobby = [];
  List fNumber = [];
  getOrderList() async {}
  void _onEvent(event) async {
    /*  setState(() {*/
    if ((stockNumber == null || stockNumber == "") ||
        (schemeNumber == null || schemeNumber == "") ||
        (organizationsNumber == null || organizationsNumber == "")) {
      ToastUtil.showInfo('请选择盘点方案、货主和仓库');
    } else {
      SharedPreferences sharedPreferences =
      await SharedPreferences.getInstance();
      var deptData = sharedPreferences.getString('menuList');
      var menuList = new Map<dynamic, dynamic>.from(jsonDecode(deptData));
      fBarCodeList = menuList['FBarCodeList'];
      if (fBarCodeList == 1) {
        await SqfLiteQueueDataOffline.searchDates(
            "select * from barcode_list where fBarCode='" +
                event +
                "'")
            .then((value) {
          var res = jsonEncode(value);
          if (jsonDecode(res).length > 0) {
            var resBarcode = jsonDecode(res);
            _code = event;
            var barCode = [];
            barCode.add(resBarcode[0]["fid"]);
            barCode.add(resBarcode[0]["fInQtyTotal"]);
            barCode.add(resBarcode[0]["fOutQtyTotal"]);
            barCode.add(resBarcode[0]["id"]);
            barCode.add(resBarcode[0]["fRemainQty"].toString());
            this.getMaterialList(barCode,_code);
            print("ChannelPage: $event");
          } else {
            ToastUtil.showInfo('条码不在条码清单中');
          }
        });
      } else {
        _code = event;
        this.getMaterialList("",_code);
        EasyLoading.show(status: 'loading...');
        print("ChannelPage: $event");
      }
    }
    /*});*/
  }

  void _onError(Object error) {
    setState(() {
      _code = "扫描异常";
    });
  }

  getMaterialList(barcodeData,code) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    var scanCode = code.split(",");
    var resInventory = [];
    if (scanCode.length > 1) {
      if (scanCode[1] == '') {
        await SqfLiteQueueDataOffline.searchDates(
                "select * from offline_Inventory where materialNumber='" +
                    scanCode[0] +
                    "' and schemeNumber = '$schemeNumber' and ownerId ='$organizationsNumber' and stockNumber = '$stockNumber'")
            .then((value) {
          var res = jsonEncode(value);
          if (jsonDecode(res).length > 0) {
            resInventory = jsonDecode(res);
          }
        });
      } else {
        await SqfLiteQueueDataOffline.searchDates(
                "select * from offline_Inventory where materialNumber='" +
                    scanCode[0] +
                    "' and lot='" +
                    scanCode[1] +
                    "' and schemeNumber = '$schemeNumber' and ownerId ='$organizationsNumber' and stockNumber = '$stockNumber'")
            .then((value) {
          var res = jsonEncode(value);
          if (jsonDecode(res).length > 0) {
            resInventory = jsonDecode(res);
          }
        });
      }
    } else {
      await SqfLiteQueueDataOffline.searchDates(
              "select * from offline_Inventory where materialNumber='" +
                  scanCode[0] +
                  "' and schemeNumber = '$schemeNumber' and ownerId ='$organizationsNumber' and stockNumber = '$stockNumber'")
          .then((value) {
        var res = jsonEncode(value);
        if (jsonDecode(res).length > 0) {
          resInventory = jsonDecode(res);
        }
      });
    }
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
    var barCodeScan;
    if(fBarCodeList == 1){
      barCodeScan = barcodeData;
      barCodeScan[4] = barCodeScan[4].toString();
    }else{
      barCodeScan = scanCode;
    }
    if (resInventory.length > 0) {
      var number = 0;
      for (var element in hobby) {
        if (element[0]['value']['barcode'].indexOf(barCodeScan[0].toString() + "-" + code) != -1) {
          number++;
          ToastUtil.showInfo('该标签已扫描');
          break;
        }
        if (element[0]['value']['value'] /*+ "-" + element[6]['value']['value']*/ == scanCode[0] /*+ "-" + scanCode[1]*/) {
          element[4]['value']['label'] = (double.parse(element[4]['value']['label']) + double.parse(barCodeScan[4])).toString();
          element[4]['value']['value'] = element[4]['value']['label'];
          element[14]['value']['label'] = barCodeScan[4].toString();
          element[14]['value']['value'] = barCodeScan[4].toString();
          element[0]['value']['barcode'].add(barCodeScan[0].toString() + "-" + code);
          number++;
          break;
        }
      }
      if (number == 0) {
        List arr = [];
        arr.add({
          "title": "物料",
          "name": "FMaterial",
          "id": "",
          "isHide": false,
          "value": {
            "label": resInventory[0]['materialName'],
            "value": resInventory[0]['materialNumber'],
            "barcode": [barCodeScan[0].toString() + "-" + code]
          }
        });
        arr.add({
          "title": "规格型号",
          "isHide": true,
          "name": "FMaterialIdFSpecification",
          "value": {
            "label": resInventory[0]['specification'],
            "value": resInventory[0]['specification']
          }
        });
        arr.add({
          "title": "单位名称",
          "name": "FUnitId",
          "isHide": false,
          "value": {
            "label": resInventory[0]['unitName'],
            "value": resInventory[0]['unitNumber']
          }
        });
        arr.add({
          "title": "账存数量",
          "name": "FRealQty",
          "isHide": false,
          "value": {
            "label": resInventory[0]['realQty'],
            "value": resInventory[0]['realQty']
          }
        });
        arr.add({
          "title": "盘点数量",
          "name": "FCountQty",
          "isHide": false,
          "value": {
            "label": barCodeScan[4].toString(),
            "value": barCodeScan[4].toString()
          }
        });

        arr.add({
          "title": "仓库",
          "name": "FStockID",
          "isHide": false,
          "value": {
            "label": resInventory[0]['stockName'],
            "value": resInventory[0]['stockNumber']
          }
        });
        arr.add({
          "title": "批号",
          "name": "FLot",
          "isHide": false,
          "value": {
            "label": resInventory[0]['lot'],
            "value": resInventory[0]['lot']
          }
        });
        arr.add({
          "title": "FStockOrgId",
          "name": "FStockOrgId",
          "isHide": true,
          "value": {
            "label": resInventory[0]['stockOrgId'],
            "value": resInventory[0]['stockOrgId']
          }
        });
        arr.add({
          "title": "操作",
          "name": "",
          "isHide": false,
          "value": {"label": "", "value": ""}
        });
        arr.add({
          "title": "FOwnerid",
          "name": "FOwnerid",
          "isHide": true,
          "value": {
            "label": resInventory[0]['ownerId'],
            "value": resInventory[0]['ownerId']
          }
        });
        arr.add({
          "title": "FStockStatusId",
          "name": "FStockStatusId",
          "isHide": true,
          "value": {
            "label": resInventory[0]['stockStatusId'],
            "value": resInventory[0]['stockStatusId']
          }
        });
        arr.add({
          "title": "FKeeperTypeId",
          "name": "FKeeperTypeId",
          "isHide": true,
          "value": {
            "label": resInventory[0]['keeperTypeId'],
            "value": resInventory[0]['keeperTypeId']
          }
        });
        arr.add({
          "title": "FKeeperId",
          "name": "FKeeperId",
          "isHide": true,
          "value": {
            "label": resInventory[0]['keeperId'],
            "value": resInventory[0]['keeperId']
          }
        });
        arr.add({
          "title": "FBillEntry_FEntryID",
          "name": "FBillEntry_FEntryID",
          "isHide": true,
          "value": {
            "label": resInventory[0]['entryID'],
            "value": resInventory[0]['entryID']
          }
        });
        arr.add({
          "title": "最后扫描数量",
          "name": "FLastQty",
          "isHide": false,
          "value": {
            "label": barCodeScan[4].toString(),
            "value": barCodeScan[4].toString()
          }
        });
        hobby.add(arr);
      }
      setState(() {
        EasyLoading.dismiss();
        this._getHobby();
        _scrollController.jumpTo(globalListKey.currentContext!.size!.height);
      });
    } else {
      /*Map<String, dynamic> materialMap = Map();
      materialMap['FilterString'] = "FNumber='" +
          scanCode[0] +
          "' and FForbidStatus = 'A' and FUseOrgId.FNumber = '" +
          deptData[1] +
          "'";
      materialMap['FormId'] = 'BD_MATERIAL';
      materialMap['FieldKeys'] =
      'FMATERIALID,FName,FNumber,FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FIsBatchManage';
      Map<String, dynamic> materialDataMap = Map();
      materialDataMap['data'] = materialMap;
      String order = await CurrencyEntity.polling(materialDataMap);
      var materialDate = [];
      materialDate = jsonDecode(order);*/
      if (scanCode.length > 2) {
        var number = 0;
        for (var element in hobby) {
          if (element[0]['value']['barcode'].indexOf(barCodeScan[0].toString() + "-" + code) != -1) {
            number++;
            ToastUtil.showInfo('该标签已扫描');
            break;
          }
          if (element[0]['value']['value'] /*+ "-" + element[6]['value']['value']*/ == scanCode[0] /*+ "-" + scanCode[1]*/) {
            element[4]['value']['label'] = (double.parse(element[4]['value']['label']) + double.parse(barCodeScan[4])).toString();
            element[4]['value']['value'] = element[4]['value']['label'];
            element[14]['value']['label'] = barCodeScan[4].toString();
            element[14]['value']['value'] = barCodeScan[4].toString();
            element[0]['value']['barcode'].add(barCodeScan[0].toString() + "-" + code);
            number++;
            break;
          }
        }
        if (number == 0) {
          List arr = [];
          arr.add({
            "title": "物料",
            "name": "FMaterial",
            "isHide": false,
            "id": "",
            "value": {
              "label": scanCode[0],
              "value": scanCode[0],
              "barcode": [barCodeScan[0].toString() + "-" + code]
            }
          });
          arr.add({
            "title": "规格型号",
            "isHide": true,
            "name": "FMaterialIdFSpecification",
            "value": {"label": "", "value": ""}
          });
          arr.add({
            "title": "单位名称",
            "name": "FUnitId",
            "isHide": false,
            "value": {"label": "", "value": ""}
          });
          arr.add({
            "title": "账存数量",
            "name": "FRealQty",
            "isHide": false,
            "value": {"label": 0, "value": 0}
          });
          arr.add({
            "title": "盘点数量",
            "name": "FCountQty",
            "isHide": false,
            "value": {
              "label": barCodeScan[4].toString(),
              "value": barCodeScan[4].toString()
            }
          });

          arr.add({
            "title": "仓库",
            "name": "FStockID",
            "isHide": false,
            "value": {"label": this.stockName, "value": this.stockNumber}
          });
          arr.add({
            "title": "批号",
            "name": "FLot",
            "isHide": false,
            "value": {"label": scanCode[1], "value": scanCode[1]}
          });
          arr.add({
            "title": "FStockOrgId",
            "name": "FStockOrgId",
            "isHide": true,
            "value": {"label": deptData[1], "value": deptData[1]}
          });
          arr.add({
            "title": "操作",
            "name": "",
            "isHide": false,
            "value": {"label": "", "value": ""}
          });
          arr.add({
            "title": "FOwnerid",
            "name": "FOwnerid",
            "isHide": true,
            "value": {
              "label": this.organizationsNumber,
              "value": this.organizationsNumber
            }
          });
          arr.add({
            "title": "FStockStatusId",
            "name": "FStockStatusId",
            "isHide": true,
            "value": {"label": "KCZT01_SYS", "value": "KCZT01_SYS"}
          });
          arr.add({
            "title": "FKeeperTypeId",
            "name": "FKeeperTypeId",
            "isHide": true,
            "value": {"label": "BD_KeeperOrg", "value": "BD_KeeperOrg"}
          });
          arr.add({
            "title": "FKeeperId",
            "name": "FKeeperId",
            "isHide": true,
            "value": {"label": deptData[1], "value": deptData[1]}
          });
          arr.add({
            "title": "FBillEntry_FEntryID",
            "name": "FBillEntry_FEntryID",
            "isHide": true,
            "value": {"label": "0", "value": "0"}
          });
          arr.add({
            "title": "最后扫描数量",
            "name": "FLastQty",
            "isHide": false,
            "value": {
              "label": barCodeScan[4].toString(),
              "value": barCodeScan[4].toString()
            }
          });
          hobby.add(arr);
        }
        setState(() {
          EasyLoading.dismiss();
          this._getHobby();
          _scrollController.jumpTo(globalListKey.currentContext!.size!.height);
        });
      } else {
        setState(() {
          EasyLoading.dismiss();
        });
        ToastUtil.showInfo('无数据');
      }
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
          if (hobby == 'customer') {
            customerName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                customerNumber = customerListObj[elementIndex][2];
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
          } else if (hobby == 'stock') {
            stockName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                stockNumber = stockListObj[elementIndex][2];
              }
              elementIndex++;
            });
            if (fBarCodeList == 1) {
              this.getBarcodeList();
            }
          } else if (hobby == 'organizations') {
            organizationsName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                organizationsNumber = organizationsListObj[elementIndex][2];
              }
              elementIndex++;
            });
          } else if (hobby == 'scheme') {
            schemeName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                schemeNumber = schemeListObj[elementIndex][2];
              }
              elementIndex++;
            });
            getInventorySessions();
          } else if (hobby == 'cumulative') {
            isCumulative = p;
          } else {
            setState(() {
              hobby['value']['label'] = p;
            });
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                hobby['value']['value'] = stockListObj[elementIndex][2];
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
          /*if (j == 4) {
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
          } else*/ if (j == 8) {
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
  /// 缓存数据确认弹窗
  Future<void> _showInventoryDialog(inventoryData) async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("检测到缓存数据，是否提取", style: TextStyle(fontSize: 14.0)),
            actions: <Widget>[
              new FlatButton(
                child: new Text('不了'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              new FlatButton(
                child: new Text('清空缓存'),
                onPressed: () async {
                  SqfLiteQueueDataOffline.deleteTData(this.schemeNumber);
                  Navigator.of(context).pop();
                },
              ),
              new FlatButton(
                child: new Text('确定'),
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    this.organizationsName =
                    inventoryData[0]['organizationsName'];
                    this.organizationsNumber =
                    inventoryData[0]["organizationsNumber"];
                    this.schemeName = inventoryData[0]["schemeName"];
                    this.schemeNumber = inventoryData[0]["schemeNumber"];
                    this.stockName = inventoryData[0]["stockIdName"];
                    this.stockNumber = inventoryData[0]["stockIdNumber"];
                    if (fBarCodeList == 1) {
                      this.getBarcodeList();
                    }
                    hobby = [];
                    for (var element in inventoryData) {
                      List arr = [];
                      arr.add({
                        "title": "物料",
                        "name": "FMaterial",
                        "isHide": false,
                        "value": {
                          "label": element["materialName"] +
                              "- (" +
                              element["materialNumber"] +
                              ")",
                          "value": element["materialNumber"],
                          "barcode": jsonDecode(element["barcode"])
                        }
                      });
                      arr.add({
                        "title": "规格型号",
                        "isHide": true,
                        "name": "FMaterialIdFSpecification",
                        "value": {
                          "label": element["specification"],
                          "value": element["specification"]
                        }
                      });
                      arr.add({
                        "title": "单位名称",
                        "name": "FUnitId",
                        "isHide": false,
                        "value": {
                          "label": element["unitName"],
                          "value": element["unitNumber"]
                        }
                      });
                      arr.add({
                        "title": "账存数量",
                        "name": "FRealQty",
                        "isHide": false,
                        "value": {
                          "label": element["realQty"],
                          "value": element["realQty"]
                        }
                      });
                      arr.add({
                        "title": "盘点数量",
                        "name": "FCountQty",
                        "isHide": false,
                        "value": {
                          "label": element["countQty"],
                          "value": element["countQty"]
                        }
                      });
                      arr.add({
                        "title": "仓库",
                        "name": "FStockID",
                        "isHide": false,
                        "value": {
                          "label": element["stockName"],
                          "value": element["stockNumber"]
                        }
                      });
                      arr.add({
                        "title": "批号",
                        "name": "FLot",
                        "isHide": false,
                        "value": {
                          "label": element["lot"],
                          "value": element["lot"]
                        }
                      });
                      arr.add({
                        "title": "FStockOrgId",
                        "name": "FStockOrgId",
                        "isHide": true,
                        "value": {
                          "label": element["stockOrgId"],
                          "value": element["stockOrgId"]
                        }
                      });
                      arr.add({
                        "title": "操作",
                        "name": "",
                        "isHide": false,
                        "value": {"label": "", "value": ""}
                      });
                      arr.add({
                        "title": "FOwnerid",
                        "name": "FOwnerid",
                        "isHide": true,
                        "value": {
                          "label": element["ownerId"],
                          "value": element["ownerId"]
                        }
                      });
                      arr.add({
                        "title": "FStockStatusId",
                        "name": "FStockStatusId",
                        "isHide": true,
                        "value": {
                          "label": element["stockStatusId"],
                          "value": element["stockStatusId"]
                        }
                      });
                      arr.add({
                        "title": "FKeeperTypeId",
                        "name": "FKeeperTypeId",
                        "isHide": true,
                        "value": {
                          "label": element["keeperTypeId"],
                          "value": element["keeperTypeId"]
                        }
                      });
                      arr.add({
                        "title": "FKeeperId",
                        "name": "FKeeperId",
                        "isHide": true,
                        "value": {
                          "label": element["keeperId"],
                          "value": element["keeperId"]
                        }
                      });
                      arr.add({
                        "title": "FBillEntry_FEntryID",
                        "name": "FBillEntry_FEntryID",
                        "isHide": true,
                        "value": {
                          "label": element["entryID"],
                          "value": element["entryID"]
                        }
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
                    }
                    this._getHobby();
                    _scrollController
                        .jumpTo(globalListKey.currentContext!.size!.height);
                  });
                },
              )
            ],
          );
        });
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

  //保存
  saveOrder() async {
    if (this.hobby.length > 0) {
      setState(() {
        this.isSubmit = true;
      });
      EasyLoading.show(status: 'loading...');
      /* if (this.departmentNumber == null) {
        this.isSubmit = false;
        ToastUtil.showInfo('请选择部门');
        return;
      }*/
      Map<String, dynamic> dataMap = Map();
      Map<String, dynamic> orderMap = Map();
      orderMap['NeedReturnFields'] = [];
      orderMap['IsDeleteEntry'] = false;
      Map<String, dynamic> Model = Map();
      Model['FID'] = fID;
      /*Model['FDate'] = FDate;*/
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      var menuData = sharedPreferences.getString('MenuPermissions');
      var deptData = jsonDecode(menuData)[0];
      var FEntity = [];
      var hobbyIndex = 0;
      for (var element in this.hobby) {
        if (element[4]['value']['value'] != '') {
          //判断是否提交失败
          if(!isError){
            if (element[2]['value']['value'] == "") {
              //查询盘点方案
              var orderData = [];
              Map<String, dynamic> schemeMap = Map();
              /*if (element[6]['value']['value'] == "") {*/
                schemeMap['FilterString'] = "FMaterialId.FNumber='" +
                    element[0]['value']['value'] +
                    "' and FStockId.FNumber = '$stockNumber' and FSchemeNo = '$schemeNumber' and FOwnerId.FNumber = '$organizationsNumber'";
              /*} else {
                schemeMap['FilterString'] = "FMaterialId.FNumber='" +
                    element[0]['value']['value'] +
                    "' and FLot.FNumber='" +
                    element[6]['value']['value'] +
                        "' and FStockId.FNumber = '$stockNumber' and FSchemeNo = '$schemeNumber' and FOwnerId.FNumber = '$organizationsNumber'";
              }*/
              schemeMap['FormId'] = 'STK_StockCountInput';
              schemeMap['FieldKeys'] =
              'FMaterialId.FName,FMaterialId.FNumber,FStockId.FNumber,FAcctQty,FStockName,FLot.FNumber,FBillEntry_FEntryID,FCountQty,FMaterialId.FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber';
              Map<String, dynamic> schemeDataMap = Map();
              schemeDataMap['data'] = schemeMap;
              String order = await CurrencyEntity.polling(schemeDataMap);
              orderData = jsonDecode(order);
              //盘点方案不存在则查询物料信息
              if (orderData.length == 0) {
                Map<String, dynamic> materialMap = Map();
                materialMap['FilterString'] = "FNumber='" +
                    element[0]['value']['value'] +
                    "' and FForbidStatus = 'A' and FUseOrgId.FNumber = '" +
                    deptData[1] +
                    "'";
                materialMap['FormId'] = 'BD_MATERIAL';
                materialMap['FieldKeys'] =
                'FMATERIALID,FName,FNumber,FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FIsBatchManage';
                Map<String, dynamic> materialDataMap = Map();
                materialDataMap['data'] = materialMap;
                String order = await CurrencyEntity.polling(materialDataMap);
                orderData = jsonDecode(order);
                element[0]['value']['label'] =
                    orderData[0][1] + "- (" + orderData[0][2] + ")";
                element[1]['value']['label'] = orderData[0][3];
                element[1]['value']['value'] = orderData[0][3];
                element[2]['value']['label'] = orderData[0][4];
                element[2]['value']['value'] = orderData[0][5];
              } else {
                if (element[13]['value']['value'] == "0") {
                  element[13]['value']['label'] = orderData[0][6].toString();
                  element[13]['value']['value'] = orderData[0][6].toString();
                }
                if (this.isCumulative == "是") {
                  element[4]['value']['label'] =
                      (double.parse(element[4]['value']['label']) +
                          orderData[0][7])
                          .toString();
                  element[4]['value']['value'] = element[4]['value']['label'];
                }
                element[0]['value']['label'] =
                    orderData[0][0] + "- (" + orderData[0][1] + ")";
                element[1]['value']['label'] = orderData[0][8];
                element[1]['value']['value'] = orderData[0][8];
                element[2]['value']['label'] = orderData[0][9];
                element[2]['value']['value'] = orderData[0][10];
              }
            } else {
              Map<String, dynamic> schemeMap = Map();
              /*if (element[6]['value']['value'] == "") {*/
                schemeMap['FilterString'] = "FMaterialId.FNumber='" +
                    element[0]['value']['value'] +
                    "' and FStockId.FNumber = '$stockNumber' and FSchemeNo = '$schemeNumber' and FOwnerId.FNumber = '$organizationsNumber'";
              /*} else {
                schemeMap['FilterString'] = "FMaterialId.FNumber='" +
                    element[0]['value']['value'] +
                    "' and FLot.FNumber='" +
                    element[6]['value']['value'] +
                        "' and FStockId.FNumber = '$stockNumber' and FSchemeNo = '$schemeNumber' and FOwnerId.FNumber = '$organizationsNumber'";
              }*/
              schemeMap['FormId'] = 'STK_StockCountInput';
              schemeMap['FieldKeys'] =
              'FMaterialId.FName,FMaterialId.FNumber,FStockId.FNumber,FAcctQty,FStockName,FLot.FNumber,FBillEntry_FEntryID,FCountQty';
              Map<String, dynamic> schemeDataMap = Map();
              schemeDataMap['data'] = schemeMap;
              String order = await CurrencyEntity.polling(schemeDataMap);
              var orderData = [];
              orderData = jsonDecode(order);
              if (orderData.length > 0) {
                if (element[13]['value']['value'] == "0") {
                  element[13]['value']['label'] = orderData[0][6].toString();
                  element[13]['value']['value'] = orderData[0][6].toString();
                }
                if (this.isCumulative == "是") {
                  element[4]['value']['label'] =
                      (double.parse(element[4]['value']['label']) +
                          orderData[0][7])
                          .toString();
                  element[4]['value']['value'] = element[4]['value']['label'];
                }
              }
            }
          }
          Map<String, dynamic> FEntityItem = Map();
          FEntityItem['FEntryID'] = element[13]['value']['value'];
          FEntityItem['FMaterialId'] = {
            "FNumber": element[0]['value']['value']
          };
          FEntityItem['FUnitID'] = {"FNumber": element[2]['value']['value']};
          FEntityItem['FStockId'] = {"FNumber": element[5]['value']['value']};
          FEntityItem['FOwnerId'] = {"FNumber": element[9]['value']['value']};
          //FEntityItem['FLOT'] = {"FNumber": element[6]['value']['value']};
          FEntityItem['FStockStatusId'] = {
            "FNumber": element[10]['value']['value']
          };
          FEntityItem['FKeeperTypeId'] = element[11]['value']['value'];
          FEntityItem['FKeeperId'] = {"FNumber": element[12]['value']['value']};
          /*FEntityItem['FReturnType'] = 1;*/
          FEntityItem['FCountQty'] = element[4]['value']['value'];
          FEntityItem['FOwnerTypeId'] = "BD_OwnerOrg";
          FEntity.add(FEntityItem);
        }
        hobbyIndex++;
      };
      if (FEntity.length == 0) {
        this.isSubmit = false;
        ToastUtil.showInfo('盘点数量未录入');
        EasyLoading.dismiss();
        return;
      }
      dataMap['formid'] = 'STK_StockCountInput';
      Model['FBillEntry'] = FEntity;
      orderMap['Model'] = Model;
      dataMap['data'] = orderMap;
      print(jsonEncode(dataMap));
      String order = await SubmitEntity.save(dataMap);
      var res = jsonDecode(order);
      if (res['Result']['ResponseStatus']['IsSuccess']) {
        Map<String, dynamic> submitMap = Map();
        FEntity = [];
        submitMap = {
          "formid": "STK_StockCountInput",
          "data": {
            'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
          }
        };
        SqfLiteQueueDataOffline.deleteTData(this.schemeNumber);
        SqfLiteQueueDataOffline.deleteData(this.schemeNumber);
        SqfLiteQueueDataRepertoire.deleteTableData();
        var errorMsg = "";
        if (fBarCodeList == 1) {
          for (int i = 0; i < this.hobby.length; i++) {
            var barcode = this.hobby[i][0]['value']['barcode'];
            for (int j = 0; j < barcode.length; j++) {
              Map<String, dynamic> dataCodeMap = Map();
              dataCodeMap['formid'] = 'QDEP_BarCodeList';
              Map<String, dynamic> orderCodeMap = Map();
              orderCodeMap['NeedReturnFields'] = [];
              orderCodeMap['IsDeleteEntry'] = false;
              Map<String, dynamic> codeModel = Map();
              var itemCode = barcode[j].split("-");
              codeModel['FID'] = itemCode[0];
              codeModel['FLastCheckTime'] = formatDate(DateTime.now(),
                  [yyyy, "-", mm, "-", dd, " ", HH, ":", nn, ":", ss]);
              orderCodeMap['Model'] = codeModel;
              dataCodeMap['data'] = orderCodeMap;
              print(dataCodeMap);
              String codeRes = await SubmitEntity.save(dataCodeMap);
              print(codeRes);
              var barcodeRes = jsonDecode(codeRes);
              if(!barcodeRes['Result']['ResponseStatus']['IsSuccess']){
                errorMsg +="错误反馈："+itemCode[1]+":"+barcodeRes['Result']['ResponseStatus']['Errors'][0]['Message'];
              }
            }
          }
        }
        if(errorMsg !=""){
          ToastUtil.errorDialog(context,
              errorMsg);
          this.isSubmit = false;
        }
        //提交
        setState(() {
          this.hobby = [];
          this.orderDate = [];
          this.FBillNo = '';
          this.isSubmit = false;
          this.isError = false;
          EasyLoading.dismiss();
          ToastUtil.showInfo('提交成功');
          /* Navigator.of(context).pop();*/
        });
      } else {
        setState(() {
          this.isSubmit = false;
          this.isError = true;
          EasyLoading.dismiss();
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
            title: Text("盘点"),
            centerTitle: true,
          ),
          body: Column(
            children: <Widget>[
              Expanded(
                child:
                    ListView(controller: _scrollController, children: <Widget>[
                  _dateItem('日期：', DateMode.YMD),
                  _item('盘点方案', this.schemeList, this.schemeName, 'scheme'),
                  _item('货主', this.organizationsList, this.organizationsName,
                      'organizations'),
                  _item('仓库', this.stockList, this.stockName, 'stock'),
                  _item('累计盘点', ['否', '是'], isCumulative, "cumulative"),
                  Column(
                    key: globalListKey,
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
                        child: Text("暂存"),
                        color: Colors.orange,
                        textColor: Colors.white,
                        onPressed: () async {
                          SqfLiteQueueDataOffline.deleteTData(this.schemeNumber);
                          for (var element in this.hobby) {
                            SqfLiteQueueDataOffline.insertTData(
                                this.fID,
                                this.schemeName,
                                this.schemeNumber,
                                this.organizationsName,
                                this.organizationsNumber,
                                this.stockName,
                                this.stockNumber,
                                element[0]['value']['label'],
                                element[0]['value']['value'],
                                element[1]['value']['value'],
                                element[2]['value']['label'],
                                element[2]['value']['value'],
                                element[3]['value']['value'],
                                element[4]['value']['value'],
                                element[5]['value']['label'],
                                element[5]['value']['value'],
                                element[6]['value']['value'],
                                element[7]['value']['value'],
                                element[9]['value']['value'],
                                element[10]['value']['value'],
                                element[11]['value']['value'],
                                element[12]['value']['value'],
                                element[13]['value']['value'],
                                jsonEncode(element[0]['value']['barcode']));
                          }
                          ToastUtil.showInfo('暂存成功');
                        },
                      ),
                    ),
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
