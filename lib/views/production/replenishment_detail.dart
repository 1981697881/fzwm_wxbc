import 'dart:convert';
import 'package:date_format/date_format.dart';
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

class ReplenishmentDetail extends StatefulWidget {
  var FBillNo;
  var FSeq;

  ReplenishmentDetail({Key ?key, @required this.FBillNo, @required this.FSeq})
      : super(key: key);

  @override
  _ReplenishmentDetailState createState() =>
      _ReplenishmentDetailState(FBillNo, FSeq);
}

class _ReplenishmentDetailState extends State<ReplenishmentDetail> {

  GlobalKey<PartRefreshWidgetState> globalKey = GlobalKey();

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
  var isScanWork = false;
  var checkData;
  var checkDataChild;
  var departmentName;
  var departmentNumber;
  var selectData = {
    DateMode.YMD: "",
  };
  //包装规格
  var bagList = [];
  var hobbyItem = [];
  List<dynamic> bagListObj = [];
  var stockList = [];
  List<dynamic> stockListObj = [];
  var selectStock = "";
  Map<String, dynamic> selectStockMap = Map();
  List<dynamic> orderDate = [];
  List<dynamic> materialDate = [];
  final divider = Divider(height: 1, indent: 20);
  final rightIcon = Icon(Icons.keyboard_arrow_right);
  final scanIcon = Icon(Icons.filter_center_focus);
  static const scannerPlugin =
      const EventChannel('com.shinow.pda_scanner/plugin');
   StreamSubscription ?_subscription;
  var _code;
  var _FNumber;
  var FSeq;
  var fBillNo;
  var fOrgID;
  var fBarCodeList;
  final controller = TextEditingController();
  _ReplenishmentDetailState(fBillNo, FSeq) {
    this.fBillNo = fBillNo['value'];
    this.FSeq = FSeq['value'];
    this.getOrderList();
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
    getWorkShop();
    getStockList();
    getBagList();
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
    var tissue = sharedPreferences.getString('tissue');
    userMap['FilterString'] = "FForbidStatus = 'A' and FUseOrgId.FNumber ='"+tissue+"'";//
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
    userMap['FilterString'] = "FMOBillNO='$fBillNo' and FMOEntrySeq = '$FSeq'";
    userMap['FormId'] = 'PRD_PPBOM';
    userMap['OrderString'] = 'FMaterialId.FNumber ASC';
    userMap['FieldKeys'] =
        'FBillNo,FPrdOrgId.FNumber,FPrdOrgId.FName,FMOBillNO,FMOEntrySeq,FEntity_FEntryId,FEntity_FSeq,FMaterialID2.FNumber,FMaterialID2.F_UUAC_Text,FMaterialID2.FSpecification,FUnitID2.FNumber,FUnitID2.FName,FNeedQty2,FID,FAuxPropId.FF100002.FNumber,FMaterialId.FIsBatchManage,FBaseUnitID.FNumber,FBaseUnitID.FName,FMaterialId.FIsKFPeriod,FWorkshopID.FNUMBER,FMoEntryId,FMaterialID.FNumber';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    orderDate = [];
    orderDate = jsonDecode(order);
    DateTime dateTime = DateTime.now();
    FDate =
        "${dateTime.year}-${dateTime.month}-${dateTime.day} ${dateTime.hour}:${dateTime.minute}:${dateTime.second}";
    if (orderDate.length > 0) {
      FStockOrgId = orderDate[0][1].toString();
      FPrdOrgId = orderDate[0][1].toString();
      this.fOrgID = orderDate[0][1];
      departmentNumber = orderDate[0][19];
      hobby = [];
      orderDate.forEach((value) {
        fNumber.add(value[7]);
        List arr = [];
        arr.add({
          "title": "物料名称",
          "name": "FMaterial",
          "FEntryId": value[5],
          "FID": value[13],
          "FWorkShopId": value[19],
          "FIsKFPeriod": value[18],
          "FMoEntryId": value[20],
          "FPARENTMATERIALID": value[21],
          "parseEntryID": -1,
          "isHide": false,
          "value": {
            "label": value[8] + "- (" + value[7] + ")",
            "value": value[7],
            "barcode": [],
            "kingDeeCode": [],
            "surplus": value[12],
            "scanCode": []
          }
        });
        arr.add({
          "title": "包装规格",
          "name": "FMaterialIdFSpecification",
          "isHide": false,
          "value": {"label": "", "value": ""}
        });
        arr.add({
          "title": "单位",
          "name": "FStockOrgName",
          "isHide": false,
          "value": {"label": value[11], "value": value[10]}
        });
        arr.add({
          "title": "补料数量",
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
          "name": "FLot",
          "isHide": value[15] != true,/*value[20]*/
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
          "title": "基本单位",
          "name": "",
          "isHide": true,
          "value": {"label": value[17], "value": value[16]}
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
          "title": "生产日期",
          "name": "FProduceDate",
          "isHide": !value[18],
          "value": {
            "label": '',
            "value": ''
          }
        });
        arr.add({
          "title": "有效期至",
          "name": "FExpiryDate",
          "isHide": !value[18],
          "value": {
            "label": '',
            "value": ''
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

  }

  void _onEvent(event) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var deptData = sharedPreferences.getString('menuList');
    var menuList = new Map<dynamic, dynamic>.from(jsonDecode(deptData));
    fBarCodeList = menuList['FBarCodeList'];
    if(event == ""){
      return;
    }
    if (fBarCodeList == 1) {
      Map<String, dynamic> barcodeMap = Map();
      barcodeMap['FilterString'] = "FBarCodeEn='" + event + "'";
      barcodeMap['FormId'] = 'QDEP_Cust_BarCodeList';
      barcodeMap['FieldKeys'] =
      'FID,FInQtyTotal,FOutQtyTotal,FEntity_FEntryId,FRemainQty,FBarCodeQty,FStockID.FName,FStockID.FNumber,FMATERIALID.FNUMBER,FOwnerID.FNumber,FBarCode,FSN,FProduceDate,FExpiryDate,FPackageSpec';
      Map<String, dynamic> dataMap = Map();
      dataMap['data'] = barcodeMap;
      String order = await CurrencyEntity.polling(dataMap);
      var barcodeData = jsonDecode(order);
      if (barcodeData.length > 0) {
        _code = event;
        this.getMaterialList(barcodeData, barcodeData[0][10], barcodeData[0][11], barcodeData[0][12].substring(0, 10), barcodeData[0][13].substring(0, 10));
      } else {
        ToastUtil.showInfo('条码不在条码清单中');
      }
    } else {
      _code = event;
      this.getMaterialList("", _code,"","","");
      print("ChannelPage: $event");
    }
    print("ChannelPage: $event");
  }
  void _onError(Object error) {
    setState(() {
      _code = "扫描异常";
    });
  }
  getMaterialList(barcodeData, code, fsn, fProduceDate, fExpiryDate) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var tissue = sharedPreferences.getString('tissue');
    var scanCode = code.split(";");
    userMap['FilterString'] = "FNumber='"+scanCode[0]+"' and FForbidStatus = 'A' and FUseOrgId.FNumber = '"+tissue+"'";
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
      var barCodeScan = [];
      if (fBarCodeList == 1) {
        barCodeScan = barcodeData[0];
        barCodeScan[4] = barCodeScan[4].toString();
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
      for (var element in hobby) {
        var entryIndex;
        if(this.fBillNo == ''){
          entryIndex = hobbyIndex;
        }else{
          if(element[0]['FEntryID'] == 0){
            if(element[0]['parseEntryID'] != -1){
              entryIndex = this.hobbyItem[this.hobbyItem.indexWhere((v)=> v['number'] == (element[0]['value']['value']+'-'+element[0]['parseEntryID'].toString()))]['index'];
            }
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
                    element[1]['value']['label'] = barcodeData[0][14] == null? "":barcodeData[0][14];
                    element[1]['value']['value'] =barcodeData[0][14] == null? "":barcodeData[0][14];
                  }
                  if (element[11]['value']['value'] == "") {
                    element[11]['value']['label'] = fProduceDate == null? "":fProduceDate;
                    element[11]['value']['value'] =fProduceDate == null? "":fProduceDate;
                    element[12]['value']['label'] =fExpiryDate == null? "":fExpiryDate;
                    element[12]['value']['value'] =fExpiryDate == null? "":fExpiryDate;
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
                      element[1]['value']['label'] = barcodeData[0][14] == null? "":barcodeData[0][14];
                      element[1]['value']['value'] =barcodeData[0][14] == null? "":barcodeData[0][14];
                    }
                    if (element[11]['value']['value'] == "") {
                      element[11]['value']['label'] = fProduceDate == null? "":fProduceDate;
                      element[11]['value']['value'] =fProduceDate == null? "":fProduceDate;
                      element[12]['value']['label'] =fExpiryDate == null? "":fExpiryDate;
                      element[12]['value']['value'] =fExpiryDate == null? "":fExpiryDate;
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
                    element[1]['value']['label'] = barcodeData[0][14] == null? "":barcodeData[0][14];
                    element[1]['value']['value'] =barcodeData[0][14] == null? "":barcodeData[0][14];
                  }
                  if (element[11]['value']['value'] == "") {
                    element[11]['value']['label'] = fProduceDate == null? "":fProduceDate;
                    element[11]['value']['value'] =fProduceDate == null? "":fProduceDate;
                    element[12]['value']['label'] =fExpiryDate == null? "":fExpiryDate;
                    element[12]['value']['value'] =fExpiryDate == null? "":fExpiryDate;
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
                        element[1]['value']['label'] = barcodeData[0][14] == null? "":barcodeData[0][14];
                        element[1]['value']['value'] =barcodeData[0][14] == null? "":barcodeData[0][14];
                      }
                      if (element[11]['value']['value'] == "") {
                        element[11]['value']['label'] = fProduceDate == null? "":fProduceDate;
                        element[11]['value']['value'] =fProduceDate == null? "":fProduceDate;
                        element[12]['value']['label'] =fExpiryDate == null? "":fExpiryDate;
                        element[12]['value']['value'] =fExpiryDate == null? "":fExpiryDate;
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
                          element[1]['value']['label'] = barcodeData[0][14] == null? "":barcodeData[0][14];
                          element[1]['value']['value'] =barcodeData[0][14] == null? "":barcodeData[0][14];
                        }
                        if (element[11]['value']['value'] == "") {
                          element[11]['value']['label'] = fProduceDate == null? "":fProduceDate;
                          element[11]['value']['value'] =fProduceDate == null? "":fProduceDate;
                          element[12]['value']['label'] =fExpiryDate == null? "":fExpiryDate;
                          element[12]['value']['value'] =fExpiryDate == null? "":fExpiryDate;
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
      if(number ==0) {
        var inserNum = 0.0;
        print("剩余");
        print(surplus);
        print(parseEntryID);
        if(parseEntryID == -1){
          surplus = double.parse(barCodeScan[4]);
        }
        print(barCodeScan[4]);
        if(double.parse(barCodeScan[4]) >= surplus && this.fBillNo!=''){
          inserNum = surplus;
        }else{
          inserNum = double.parse(barCodeScan[4]);
        }
        if(inserNum == 0){
          ToastUtil.showInfo('该物料领料数量已达上限');
          return;
        }
        for (var value in materialDate) {
          var parentIndex = this.hobbyItem[this.hobbyItem.indexWhere((v)=> v['number'] == (value[2]+'-'+parseEntryID.toString()))]['index'];
          hobby[parentIndex][0]['value']['surplus'] = (surplus - inserNum >0?surplus - inserNum:0);
          List arr = [];
          arr.add({
            "title": "物料名称",
            "name": "FMaterial",
            "FEntryID": 0,
            "parseEntryID": parseEntryID,
            "FIsKFPeriod": fIsKFPeriod,
            "isHide": false,
            "value": {
              "FProduceDate": barcodeData[0][12],
              "FExpiryDate": barcodeData[0][13],
              "label": value[1] + "- (" + value[2] + ")",
              "value": value[2],
              "barcode": [code],
              "surplus": surplus,
              "kingDeeCode": [barCodeScan[0].toString()+"-"+scanCode[3]+"-"+fsn],
              "scanCode": [barCodeScan[0].toString()+"-"+scanCode[3]]
            }
          });
          arr.add({
            "title": "包装规格",
            "isHide": false,
            "name": "FMaterialIdFSpecification",
            "value": {"label": barcodeData[0][14], "value": barcodeData[0][14]}
          });
          arr.add({
            "title": "单位名称",
            "name": "FUnitId",
            "isHide": false,
            "value": {"label": value[4], "value": value[5]}
          });
          arr.add({
            "title": "补料数量",
            "name": "FBaseQty",
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
            "value": {
              "label": value[6]?(scanCode.length>1?scanCode[1]:''):'',
              "value": value[6]?(scanCode.length>1?scanCode[1]:''):''
            }
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
            "isHide": false,
            "value": {"label": "", "value": ""}
          });
          arr.add({
            "title": "基本单位",
            "name": "",
            "isHide": true,
            "value": {"label": value[4], "value": value[5]}
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
              "value": inserNum.toString(),"remainder": (double.parse(barCodeScan[4]) - inserNum).toString(),"representativeQuantity": barCodeScan[4]
            }
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
            setState(() {
              hobby['value']['label'] = p;
            });
            var elementIndex = 0;
            data.forEach((element) {
              print( element);
              if (element == p) {
                hobby['value']['value'] = stockListObj[elementIndex][2];
              }
              elementIndex++;
            });
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
      List<Widget> comList = [];
      for (int j = 0; j < this.hobby[i].length; j++) {
        if (!this.hobby[i][j]['isHide']) {
          /*if (j == 8 || j == 11) {
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
                                this._textNumber.text =
                                this.hobby[i][j]["value"]["label"];
                                this._FNumber =
                                this.hobby[i][j]["value"]["label"];
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
          } else */if (j == 4) {
            comList.add(
              _item('仓库:', stockList, this.hobby[i][j]['value']['label'],
                  this.hobby[i][j],stock:this.hobby[i]),
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
                            if (checkItem == "FLastQty") {
                              if(double.parse(_FNumber) <= double.parse(this.hobby[checkData][checkDataChild]["value"]['representativeQuantity'])){
                                if (this.hobby[checkData][0]['value']['kingDeeCode'].length > 0) {
                                  var kingDeeCode = this.hobby[checkData][0]['value']['kingDeeCode'][this.hobby[checkData][0]['value']['kingDeeCode'].length - 1].split("-");
                                  var realQty = 0.0;
                                  this.hobby[checkData][0]['value']['kingDeeCode'].forEach((item) {
                                    var qty = item.split("-")[1];
                                    realQty += double.parse(qty);
                                  });
                                  realQty = realQty - double.parse(this.hobby[checkData][10]
                                  ["value"]["label"]);
                                  realQty = realQty + double.parse(_FNumber);
                                  this.hobby[checkData][10]["value"]["remainder"] = (Decimal.parse(this.hobby[checkData][10]["value"]["representativeQuantity"]) - Decimal.parse(_FNumber)).toString();
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
                            }else{
                              this.hobby[checkData][checkDataChild]["value"]
                              ["label"] = _FNumber;
                              this.hobby[checkData][checkDataChild]['value']
                              ["value"] = _FNumber;
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
  //删除
  deleteOrder(Map<String, dynamic> map,title) async {
    var subData = await SubmitEntity.delete(map);
    print(subData);
    if (subData != null) {
      var res = jsonDecode(subData);
      if (res != null) {
        if (res['Result']['ResponseStatus']['IsSuccess']) {
         /* this.hobby = [];
          this.orderDate = [];
          this.FBillNo = '';
          this.FSaleOrderNo = '';
          ToastUtil.showInfo('提交成功');
          Navigator.of(context).pop("refresh");*/
          setState(() {
            this.isSubmit = false;
            ToastUtil.errorDialog(context,
                title);
          });
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
  unAuditOrder(Map<String, dynamic> map,title) async {
    var subData = await SubmitEntity.unAudit(map);
    print(subData);
    if (subData != null) {
      var res = jsonDecode(subData);
      if (res != null) {
        if (res['Result']['ResponseStatus']['IsSuccess']) {
          //提交清空页面
          Map<String, dynamic> deleteMap = Map();
          deleteMap = {
            "formid": "PRD_FeedMtrl",
            "data": {
              'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
            }
          };
          deleteOrder(deleteMap,title);
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
  auditOrder(Map<String, dynamic> auditMap,billNo) async {
    var subData = await SubmitEntity.audit(auditMap);
    //获取登录信息
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var tissue = sharedPreferences.getString('tissue');
    print(subData);
    if (subData != null) {
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
                  Map<String, dynamic> codeFEntityItem = Map();
                  codeFEntityItem['FBillDate'] = FDate;
                  codeFEntityItem['FInQty'] = itemCode[1];
                  codeFEntityItem['FEntryBillNo'] = billNo;
                  codeFEntityItem['FEntryStockID'] = {
                    "FNUMBER": this.hobby[i][4]['value']['value']
                  };
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
          //提交清空页面
          setState(() {
            this.hobby = [];
            this.orderDate = [];
            this.FBillNo = '';
            this.FSaleOrderNo = '';
            ToastUtil.showInfo('提交成功');
            Navigator.of(context).pop("refresh");
          });
        } else {
          unAuditOrder(auditMap,res['Result']['ResponseStatus']['Errors'][0]['Message']);
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
  submitOrder(Map<String, dynamic> submitMap, billNo) async {
    var subData = await SubmitEntity.submit(submitMap);
    print(subData);
    if (subData != null) {
      var res = jsonDecode(subData);
      if (res != null) {
        if (res['Result']['ResponseStatus']['IsSuccess']) {
          //提交清空页面
          Map<String, dynamic> auditMap = Map();
          auditMap = {
            "formid": "PRD_FeedMtrl",
            "data": {
              'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
            }
          };
          auditOrder(auditMap, billNo);
        } else {
          deleteOrder(submitMap,res['Result']['ResponseStatus']['Errors'][0]['Message']);
          /*setState(() {
            this.isSubmit = false;
            ToastUtil.errorDialog(context,
                res['Result']['ResponseStatus']['Errors'][0]['Message']);
          });*/
        }
      }
    }
  }

  //保存
  saveOrder() async {
    if (this.hobby.length > 0) {
      setState(() {
        this.isSubmit = true;
      });
      Map<String, dynamic> dataMap = Map();
      dataMap['formid'] = 'PRD_FeedMtrl';
      Map<String, dynamic> orderMap = Map();
      orderMap['NeedReturnFields'] = [];
      orderMap['IsDeleteEntry'] = false;
      Map<String, dynamic> Model = Map();
      Model['FID'] = 0;
      Model['FBillType'] = {"FNUMBER": "SCBLD01_SYS"};
      Model['FDate'] = FDate;
      Model['FStockOrgId'] = {"FNumber": FStockOrgId};
      Model['FPrdOrgId'] = {"FNumber": FPrdOrgId};
      Model['FCurrId'] = {"FNumber": 'PRE001'};
      Model['F_UUAC_Combo_tzk'] = "1";
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
      this.hobby.forEach((element) {
        if (element[3]['value']['value'] != '0' && element[3]['value']['value'] != '' &&
            element[4]['value']['value'] != '') {
          var entryIndex;
          Map<String, dynamic> FEntityItem = Map();
          FEntityItem['FMaterialId'] = {"FNumber": element[0]['value']['value']};
          FEntityItem['FUnitId'] = {"FNumber": element[2]['value']['value']};
          FEntityItem['FStockId'] = {"FNumber": element[4]['value']['value']};
          FEntityItem['FStockStatusId'] = {"FNumber": "KCZT01_SYS"};
          FEntityItem['FActualQty'] = element[3]['value']['value'];
          if(element[0]['FIsKFPeriod']){
            FEntityItem['FProduceDate'] = element[11]['value']['value'];
            FEntityItem['FExpiryDate'] = element[12]['value']['value'];
          }
          FEntityItem['FMoBillNo'] = fBillNo;
          FEntityItem['FEntrySrcBillType'] = "PRD_PPBOM";
          FEntityItem['FOwnerTypeId'] = "BD_OwnerOrg";
          FEntityItem['FParentOwnerTypeId'] = "BD_OwnerOrg";
          FEntityItem['FKeeperTypeId'] = "BD_KeeperOrg";
          FEntityItem['FEntrySrcBillNo'] = fBillNo;
          FEntityItem['FKeeperId'] = {"FNumber": FStockOrgId};
          FEntityItem['FOwnerId'] = {"FNumber": FStockOrgId};
          FEntityItem['FParentOwnerId'] = {"FNumber": FStockOrgId};
          FEntityItem['FAuxPropId'] = {
            "FAUXPROPID__FF100002": {"FNumber": element[1]['value']['value']}
          };
          FEntityItem['FLot'] = {"FNumber": element[5]['value']['value']};
          if(element[0]['FEntryID'] == 0){
            if(element[0]['parseEntryID'] == -1){
              FEntityItem['FParentMaterialId'] = {"FNumber": orderDate[0][21]};
              FEntityItem['FMoEntryId'] = orderDate[0][20];
              FEntityItem['FEntryWorkShopId'] = {"FNumber": this.departmentNumber};
            }else{
              entryIndex = this.hobbyItem[this.hobbyItem.indexWhere((v)=> v['number'] == (element[0]['value']['value']+'-'+element[0]['parseEntryID'].toString()))]['index'];
              FEntityItem['FEntryWorkShopId'] = {"FNumber": this.hobby[entryIndex][0]['FWorkShopId']};
              FEntityItem['FParentMaterialId'] = {"FNumber": this.hobby[entryIndex][0]['FPARENTMATERIALID']};
              FEntityItem['FMoEntryId'] = this.hobby[entryIndex][0]['FMoEntryId'];
              FEntityItem['FEntity_Link'] = [
                {
                  "FEntity_Link_FRuleId": "PRD_PPBOM2FEEDMTRL",
                  "FEntity_Link_FSTableName": "T_PRD_PPBOMENTRY",
                  "FEntity_Link_FSBillId": this.hobby[entryIndex][0]['FID'],
                  "FEntity_Link_FSId": this.hobby[entryIndex][0]['FEntryId'],
                  "FEntity_Link_FBaseActualQty": element[3]['value']['value']
                }
              ];
            }
          }else{
            FEntityItem['FParentMaterialId'] = {"FNumber": element[0]['FPARENTMATERIALID']};
            FEntityItem['FMoEntryId'] = element[0]['FMoEntryId'];
            FEntityItem['FEntryWorkShopId'] = {"FNumber": element[0]['FWorkShopId']};
            FEntityItem['FEntity_Link'] = [
              {
                "FEntity_Link_FRuleId": "PRD_PPBOM2FEEDMTRL",
                "FEntity_Link_FSTableName": "T_PRD_PPBOMENTRY",
                "FEntity_Link_FSBillId": element[0]['FID'],
                "FEntity_Link_FSId": element[0]['FEntryId'],
                "FEntity_Link_FBaseActualQty": element[3]['value']['value']
              }
            ];
          }
          FEntityItem['FKeeperTypeId'] = 'BD_KeeperOrg';
          FEntity.add(FEntityItem);
        }
        hobbyIndex++;
      });
      if(FEntity.length==0){
        this.isSubmit = false;
        ToastUtil.showInfo('请输入数量和录入仓库');
        return;
      }
      Model['FEntity'] = FEntity;
      orderMap['Model'] = Model;
      dataMap['data'] = orderMap;
      print(jsonEncode(dataMap));
      var datass = jsonEncode(dataMap);
      String order = await SubmitEntity.save(dataMap);
      var res = jsonDecode(order);
      print(res);
      if (res['Result']['ResponseStatus']['IsSuccess']) {
        Map<String, dynamic> submitMap = Map();
        submitMap = {
          "formid": "PRD_FeedMtrl",
          "data": {
            'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
          }
        };
        submitOrder(submitMap, res['Result']['ResponseStatus']['SuccessEntitys'][0]['Number']);
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
            title: Text("补料"),
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
                          title: Text("单据编号：$fBillNo"),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  /* Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text("日期：$FDate"),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  _item('仓库:', stockList, selectStock),*/
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
                       /* onPressed: () async {
                          if (this.hobby.length > 0) {
                            setState(() {
                              this.isSubmit = true;
                            });
                            saveOrder();
                          } else {
                            ToastUtil.showInfo('无提交数据');
                          }
                        },*/
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
