import 'dart:convert';
import 'package:date_format/date_format.dart';
import 'package:fzwm_wxbc/model/currency_entity.dart';
import 'package:fzwm_wxbc/model/submit_entity.dart';
import 'package:fzwm_wxbc/utils/SqfLiteQueueDataScheme.dart';
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

class SchemeInventoryDetail extends StatefulWidget {
  var FBillNo;

  SchemeInventoryDetail({Key? key, @required this.FBillNo}) : super(key: key);

  @override
  _SchemeInventoryDetailState createState() =>
      _SchemeInventoryDetailState(FBillNo);
}

class _SchemeInventoryDetailState extends State<SchemeInventoryDetail> {
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
  var isCumulative = "否";
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
  var fBarCodeList;
  var checkData;
  var checkDataChild;
  var selectData = {
    DateMode.YMD: "",
  };
  var stockList = [];
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

  _SchemeInventoryDetailState(FBillNo) {
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

  //获取缓存
  getInventorySessions() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var deptData = sharedPreferences.getString('menuList');
    var menuList = new Map<dynamic, dynamic>.from(jsonDecode(deptData));
    fBarCodeList = menuList['FBarCodeList'];
    if (this.schemeNumber != null) {
      Map<String, dynamic> userMap = Map();
      userMap['FilterString'] = "FSchemeNo ='$schemeNumber'";
      userMap['FormId'] = 'STK_StockCountInput';
      userMap['FieldKeys'] = 'FID';
      Map<String, dynamic> dataMap = Map();
      dataMap['data'] = userMap;
      String order = await CurrencyEntity.polling(dataMap);
      var resData = jsonDecode(order);
      if (resData.length > 0) {
        fID = resData[0][0];
        SqfLiteQueueDataScheme.searchDates(
                "select * from scheme_Inventory where schemeNumber='$schemeNumber'")
            .then((value) {
          var res = jsonEncode(value);
          if (jsonDecode(res).length > 0) {
            var resInventory = jsonDecode(res);
            _showInventoryDialog(resInventory);
          }
        });
      } else {
        ToastUtil.showInfo('该盘点作业无数据');
      }
    }
    /*SqfLiteQueueDataScheme.deleteDataTable();*/
    //SqfLiteQueueData.insertData(orderDate[0][15], orderDate[0][1], orderDate[0][1], orderDate[0][1], orderDate[0][1], orderDate[0][1], orderDate[0][1], 0, orderDate[0][1], orderDate[0][1], orderDate[0][1], orderDate[0][1], orderDate[0][1], orderDate[0][1], orderDate[0][1], orderDate[0][1]);
    /*SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var inventoryData = sharedPreferences.getString('inventory');
    if (inventoryData != null) {
      var inventory = jsonDecode(inventoryData);
      inventory.forEach((element) {
        if (this.organizationsNumber != null &&
            this.schemeNumber != null &&
            this.stockNumber != null) {
          if (this.organizationsNumber ==
              element["organizations"]["number"] &&
              this.schemeNumber == element["programme"]["number"] &&
              this.stockNumber == element["stock"]["number"]) {
            _showInventoryDialog(element);
          }
        }
      });
    }*/
  } //获取盘点方案

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
        "FForbidStatus = 'A' and FUseOrgId.FNumber =" + deptData[1];
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    stockListObj = jsonDecode(res);
    stockListObj.forEach((element) {
      stockList.add(element[1]);
    });
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
  getOrderList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FilterString'] = "FRemainStockINQty>0 and FBillNo='$fBillNo'";
    userMap['FormId'] = 'PUR_PurchaseOrder';
    userMap['FieldKeys'] =
        'FBillNo,FSupplierId.FNumber,FSupplierId.FName,FDate,FDetailEntity_FEntryId,FMaterialId.FNumber,FMaterialId.FName,FMaterialId.FSpecification,FPurOrgId.FNumber,FPurOrgId.FName,FUnitId.FNumber,FUnitId.FName,FInStockQty,FSrcBillNo,FID,FStockId.FNumber,FStockOrgId.FNumber,FStockStatusId.FNumber,FKeeperTypeId,FKeeperId.FNumber,FOwnerId.FNumber';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    orderDate = [];
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
    if (orderDate.length > 0) {
      hobby = [];
      fID = this.orderDate[0][15];
      orderDate.forEach((value) {
        List arr = [];
        arr.add({
          "title": "物料名称",
          "name": "FMaterial",
          "isHide": false,
          "value": {"label": value[6], "value": value[5]}
        });
        arr.add({
          "title": "规格型号",
          "isHide": false,
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
          "title": "帐存数量",
          "name": "FRealQty",
          "isHide": false,
          "value": {"label": value[12], "value": value[12]}
        });
        arr.add({
          "title": "盘点数量",
          "name": "FRealQty",
          "isHide": false,
          "value": {"label": "0", "value": "0"}
        });
        arr.add({
          "title": "仓库",
          "name": "FStockID",
          "isHide": false,
          "value": {"label": value[15], "value": value[15]}
        });
        arr.add({
          "title": "FStockOrgId",
          "name": "FStockOrgId",
          "isHide": true,
          "value": {"label": value[15], "value": value[15]}
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
        Map<String, dynamic> barcodeMap = Map();
        barcodeMap['FilterString'] = "FBarCode='" + event + "'";
        /*barcodeMap['FilterString'] = "FID=115853";*/
        barcodeMap['FormId'] = 'QDEP_BarCodeList';
        barcodeMap['FieldKeys'] =
            'FID,FInQtyTotal,FOutQtyTotal,FEntity_FEntryId,FRemainQty';
        Map<String, dynamic> dataMap = Map();
        dataMap['data'] = barcodeMap;
        String order = await CurrencyEntity.polling(dataMap);
        var barcodeData = jsonDecode(order);
        if (barcodeData.length > 0) {
          setState(() {
            _code = event;
          });
          this.getMaterialList(barcodeData, _code);
          print("ChannelPage: $event");
          ToastUtil.showInfo('查询标签成功');
        } else {
          ToastUtil.showInfo('条码不在条码清单中');
        }
      } else {
        setState(() {
          _code = event;
        });
        this.getMaterialList("", _code);
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

  getMaterialList(barcodeData, code) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    var scanCode = code.split(",");
    userMap['FilterString'] = "FMaterialId.FNumber='" +
        scanCode[0] +
        "' and FStockId.FNumber = '$stockNumber' and FSchemeNo = '$schemeNumber' and FOwnerId.FNumber = '$organizationsNumber'";
    if (scanCode.length > 1) {
      if (scanCode[1] == '') {
        userMap['FilterString'] = "FMaterialId.FNumber='" +
            scanCode[0] +
            "' and FStockId.FNumber = '$stockNumber' and FSchemeNo = '$schemeNumber' and FOwnerId.FNumber = '$organizationsNumber'";
      } else {
        userMap['FilterString'] = "FMaterialId.FNumber='" +
            scanCode[0] +
            "' and FLot.FNumber='" +
            scanCode[1] +
            "' and FStockId.FNumber = '$stockNumber' and FSchemeNo = '$schemeNumber' FOwnerId.FNumber = '$organizationsNumber'";
      }
    }
    userMap['FormId'] = 'STK_StockCountInput';
    userMap['FieldKeys'] =
        'FStockOrgId.FNumber,FMaterialId.FName,FMaterialId.FNumber,FMaterialId.FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FStockId.FNumber,FAcctQty,FStockName,FLot.FNumber,FStockStatusId.FNumber,FKeeperTypeId,FKeeperId.FNumber,FOwnerId.FNumber,FBillEntry_FEntryID,FID';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    orderDate = [];
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
    var barCodeScan = [];
    if (fBarCodeList == 1) {
      barCodeScan = barcodeData[0];
      barCodeScan.add(barCodeScan[4]);
      barCodeScan[4] = barCodeScan[4].toString();
    } else {
      barCodeScan = scanCode;
      barCodeScan.add(barCodeScan[4]);
    }
    if (orderDate.length > 0) {
      ToastUtil.showInfo('查询盘点作业成功');
      var number = 0;
      fID = this.orderDate[0][15];
      for (var element in hobby) {
        if (element[0]['value']['barcode']
                .indexOf(barCodeScan[0].toString() + "-" + code) !=
            -1) {
          number++;
          ToastUtil.showInfo('该标签已扫描');
          break;
        }
        if (element[0]['value']['value'] /*+ "-" + element[6]['value']['value'] */== scanCode[0] /*+ "-" + scanCode[1]*/) {
          element[4]['value']['label'] = (double.parse(element[4]['value']['label']) + double.parse(barCodeScan[4])).toString();
          element[4]['value']['value'] = element[4]['value']['label'];
          element[14]['value']['label'] = barCodeScan[4].toString();
          element[14]['value']['value'] = barCodeScan[4].toString();
          element[0]['value']['barcode']
              .add(barCodeScan[0].toString() + "-" + code);
          number++;
          break;
        }
      }
      if (number == 0) {
        orderDate.forEach((value) {
          List arr = [];
          arr.add({
            "title": "物料",
            "name": "FMaterial",
            "id": "",
            "isHide": false,
            "value": {
              "label": value[1] + "- (" + value[2] + ")",
              "value": value[2],
              "barcode": [barCodeScan[0].toString() + "-" + code]
            }
          });
          arr.add({
            "title": "规格型号",
            "isHide": false,
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
            "title": "账存数量",
            "name": "FRealQty",
            "isHide": false,
            "value": {"label": value[7], "value": value[7]}
          });
          /*arr.add({
          "title": "实存数量",
          "name": "FRealQty",
          "isHide": false,
          "value": {"label": value[6], "value": value[6]}
        });*/
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
            "value": {"label": value[8], "value": value[6]}
          });
          arr.add({
            "title": "批号",
            "name": "FLot",
            "isHide": false,
            "value": {
              "label": value[9] == null ? "" : value[9],
              "value": value[9] == null ? "" : value[9]
            }
          });
          arr.add({
            "title": "FStockOrgId",
            "name": "FStockOrgId",
            "isHide": true,
            "value": {"label": value[0], "value": value[0]}
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
            "value": {"label": value[13], "value": value[13]}
          });
          arr.add({
            "title": "FStockStatusId",
            "name": "FStockStatusId",
            "isHide": true,
            "value": {"label": value[10], "value": value[10]}
          });
          arr.add({
            "title": "FKeeperTypeId",
            "name": "FKeeperTypeId",
            "isHide": true,
            "value": {"label": value[11], "value": value[11]}
          });
          arr.add({
            "title": "FKeeperId",
            "name": "FKeeperId",
            "isHide": true,
            "value": {"label": value[12], "value": value[12]}
          });
          arr.add({
            "title": "FBillEntry_FEntryID",
            "name": "FBillEntry_FEntryID",
            "isHide": true,
            "value": {"label": value[14], "value": value[14]}
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
        });
      }
      setState(() {
        EasyLoading.dismiss();
        this._getHobby();
        _scrollController.jumpTo(globalListKey.currentContext!.size!.height);
      });
    } else {
      ToastUtil.showInfo('查询物料');
      /*var barCodeScan;
      if (fBarCodeList == 1) {
        barCodeScan = barcodeData[0];
      } else {
        barCodeScan = scanCode;
      }*/
      Map<String, dynamic> materialMap = Map();
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
      materialDate = jsonDecode(order);
      if (materialDate.length > 0) {
        ToastUtil.showInfo('查询物料成功');
        var number = 0;
        for (var element in hobby) {
          if (element[0]['value']['barcode']
                  .indexOf(barCodeScan[0].toString() + "-" + code) !=
              -1) {
            number++;
            ToastUtil.showInfo('该标签已扫描');
            break;
          }
          if (element[0]['value']['value'] /*+ "-" + element[6]['value']['value']*/ == scanCode[0] /*+ "-" + scanCode[1]*/) {
            element[4]['value']['label'] =
                (double.parse(element[4]['value']['label']) +
                        double.parse(barCodeScan[4]))
                    .toString();
            element[4]['value']['value'] = element[4]['value']['label'];
            element[14]['value']['label'] = barCodeScan[4].toString();
            element[14]['value']['value'] = barCodeScan[4].toString();
            element[0]['value']['barcode']
                .add(barCodeScan[0].toString() + "-" + code);
            number++;
            break;
          }
        }
        if (number == 0) {
          materialDate.forEach((value) {
            List arr = [];
            arr.add({
              "title": "物料",
              "name": "FMaterial",
              "isHide": false,
              "id": "",
              "value": {
                "label": value[1] + "- (" + value[2] + ")",
                "value": value[2],
                "barcode": [barCodeScan[0].toString() + "-" + code]
              }
            });
            arr.add({
              "title": "规格型号",
              "isHide": false,
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
          });
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
            getInventorySessions();
          } else if (hobby == 'organizations') {
            organizationsName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                organizationsNumber = organizationsListObj[elementIndex][2];
              }
              elementIndex++;
            });
            getInventorySessions();
          } else if (hobby == 'cumulative') {
            isCumulative = p;
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
          } else*/
          if (j == 8) {
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
                  SqfLiteQueueDataScheme.deleteData(this.schemeNumber);
                  /*SharedPreferences sharedPreferences =
                  await SharedPreferences.getInstance();
                  if (this.sessionDate != null) {
                    var inventoryData = sharedPreferences.getString('inventory');
                    if (inventoryData != null) {
                      var inventory = jsonDecode(inventoryData);
                      for (var element in inventory) {
                        if (this.sessionDate == element["time"]) {
                          inventory.remove(element);
                          break;
                        }
                      };
                      print(inventory);
                      sharedPreferences.setString('inventory', jsonEncode(inventory));
                    }
                  }*/
                  Navigator.of(context).pop();
                },
              ),
              new FlatButton(
                child: new Text('确定'),
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    print(inventoryData);
                    /*this.organizationsName =
                    inventoryData["organizations"]["name"];
                    this.organizationsNumber =
                    inventoryData["organizations"]["number"];
                    this.schemeName = inventoryData["programme"]["name"];
                    this.schemeNumber = inventoryData["programme"]["number"];
                    this.stockName = inventoryData["stock"]["name"];
                    this.stockNumber = inventoryData["stock"]["number"];
                    this.hobby = inventoryData["inventory"];
                    this.sessionDate = inventoryData["time"];*/
                    this.organizationsName =
                        inventoryData[0]['organizationsName'];
                    this.organizationsNumber =
                        inventoryData[0]["organizationsNumber"];
                    this.schemeName = inventoryData[0]["schemeName"];
                    this.schemeNumber = inventoryData[0]["schemeNumber"];
                    this.stockName = inventoryData[0]["stockIdName"];
                    this.stockNumber = inventoryData[0]["stockIdNumber"];
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
                        "isHide": false,
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
                        "value": {"label": "0", "value": "0"}
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
      /*Model['FStockOrgId'] = {"FNumber": this.orderDate[0][0]};
      Model['FOwnerIdHead'] = {"FNumber": this.orderDate[0][13]};*/
      /* Model['FDeptId'] = {"FNumber": this.departmentNumber};*/
      /* Model['FOwnerTypeIdHead'] = "BD_OwnerOrg";*/
      var FEntity = [];
      var hobbyIndex = 0;
      for (var element in this.hobby) {
        if (element[4]['value']['value'] != '') {
          if (!isError) {
            if (element[4]['value']['value'] == "0") {
              var materialDate = [];
              //查询盘点方案
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
            } else {
              Map<String, dynamic> schemeMap = Map();
              //if (element[6]['value']['value'] == "") {
                schemeMap['FilterString'] = "FMaterialId.FNumber='" +
                    element[0]['value']['value'] +
                    "' and FStockId.FNumber = '$stockNumber' and FSchemeNo = '$schemeNumber' and FOwnerId.FNumber = '$organizationsNumber'";
             /* } else {
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
              print(schemeDataMap.toString());
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
         // FEntityItem['FLOT'] = {"FNumber": element[6]['value']['value']};
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
      }
      ;
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
        SqfLiteQueueDataScheme.deleteData(this.schemeNumber);
        /*if (this.sessionDate != null) {
          var inventoryData = sharedPreferences.getString('inventory');
          if (inventoryData != null) {
            var inventory = jsonDecode(inventoryData);
            for (var element in inventory) {
              if (this.sessionDate == element["time"]) {
                inventory.remove(element);
                break;
              }
            }
            ;
            sharedPreferences.setString('inventory', jsonEncode(inventory));
          }
        }*/
        var errorMsg = "";
        if (fBarCodeList == 1) {
          for (int i = 0; i < this.hobby.length; i++) {
            var barcode = this.hobby[i][0]['value']['barcode'];
            print(barcode);
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
        if (errorMsg != "") {
          ToastUtil.errorDialog(context, errorMsg);
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
                  /*Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          */ /* title: TextWidget(FBillNoKey, '生产订单：'),*/ /*
                          title: Text("单号：$fBillNo"),
                        ),
                      ),
                      divider,
                    ],
                  ),*/
                  _dateItem('日期：', DateMode.YMD),
                  _item('盘点方案', this.schemeList, this.schemeName, 'scheme'),
                  _item('货主', this.organizationsList, this.organizationsName,
                      'organizations'),
                  _item('仓库', this.stockList, this.stockName, 'stock'),
                  _item('累计盘点', ['否', '是'], isCumulative, "cumulative"),
                  /*Column(
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
                  ),*/
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
                          SqfLiteQueueDataScheme.deleteData(this.schemeNumber);
                          for (var element in this.hobby) {
                            SqfLiteQueueDataScheme.insertData(
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
                          /* await SqfLiteQueueDataScheme.internal().close();*/
                          /*SharedPreferences sharedPreferences =
                          await SharedPreferences.getInstance();
                          var menuData =
                          sharedPreferences.getString('MenuPermissions');
                          Map<String, dynamic> sessionMap = Map();
                          sessionMap['programme'] = {
                            'name': this.schemeName,
                            'number': this.schemeNumber,
                          };
                          sessionMap['organizations'] = {
                            'name': this.organizationsName,
                            'number': this.organizationsNumber,
                          };
                          sessionMap['stock'] = {
                            'name': this.stockName,
                            'number': this.stockNumber,
                          };
                          DateTime dateTime = DateTime.now();
                          sessionMap['time'] = dateTime.toString();
                          sessionMap['inventory'] = this.hobby;
                          if (sharedPreferences.getString('inventory') == null) {
                            List invetoryList = [];
                            invetoryList.add(sessionMap);
                            sharedPreferences.setString('inventory', jsonEncode(invetoryList));
                          } else {
                            var pesNumber = 0;
                            var inventoryPes = jsonDecode(
                                sharedPreferences.getString('inventory'));
                            for (var element in inventoryPes) {
                              if (this.organizationsNumber ==
                                  element["organizations"]["number"] &&
                                  this.schemeNumber ==
                                      element["programme"]["number"] &&
                                  this.stockNumber ==
                                      element["stock"]["number"]) {
                                inventoryPes[pesNumber] = sessionMap;
                                pesNumber++;
                                break;
                              }
                            };
                            print(inventoryPes);
                            if (pesNumber == 0) {
                              inventoryPes.add(sessionMap);
                            }
                            sharedPreferences.setString(
                                'inventory', jsonEncode(inventoryPes));
                          }*/
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
