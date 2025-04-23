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

class OtherInventoryDetail extends StatefulWidget {
  var FBillNo;

  OtherInventoryDetail({Key ?key, @required this.FBillNo}) : super(key: key);

  @override
  _OtherInventoryDetailState createState() => _OtherInventoryDetailState(FBillNo);
}

class _OtherInventoryDetailState extends State<OtherInventoryDetail> {
  var _remarkContent = new TextEditingController();
  GlobalKey<TextWidgetState> textKey = GlobalKey();
  GlobalKey<PartRefreshWidgetState> globalKey = GlobalKey();

  final _textNumber = TextEditingController();
  var checkItem;
  var fBarCodeList;
  String FBillNo = '';
  String FSaleOrderNo = '';
  String FName = '';
  String FNumber = '';
  String FDate = '';
  var customerName;
  var customerNumber;
  var departmentName;
  var departmentNumber;
  var stockName;
  var stockNumber;
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
   StreamSubscription ?_subscription;
  var _code;
  var _FNumber;
  var fBillNo;

  _OtherInventoryDetailState(FBillNo) {
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
    /// 开启监听
    if (_subscription == null && this.fBillNo == '') {
      _subscription = scannerPlugin
          .receiveBroadcastStream()
          .listen(_onEvent, onError: _onError);
    }
    getStockList();
    EasyLoading.dismiss();
  }
  //获取部门
  getDepartmentList() async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var tissue = sharedPreferences.getString('tissue');
    userMap['FormId'] = 'BD_Department';
    userMap['FieldKeys'] = 'FUseOrgId,FName,FNumber';
    userMap['FilterString'] = "FUseOrgId.FNumber ='"+tissue+"'";
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
    userMap['FilterString'] = "FForbidStatus = 'A' and FDocumentStatus = 'C' and FUseOrgId.FNumber ="+tissue;
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
    userMap['FilterString'] = "FRemainStockINQty>0 and FBillNo='$fBillNo'";
    userMap['FormId'] = 'PUR_PurchaseOrder';
    userMap['OrderString'] = 'FMaterialId.FNumber ASC';
    userMap['FieldKeys'] =
    'FBillNo,FSupplierId.FNumber,FSupplierId.FName,FDate,FDetailEntity_FEntryId,FMaterialId.FNumber,FMaterialId.FName,FMaterialId.FSpecification,FPurOrgId.FNumber,FPurOrgId.FName,FUnitId.FNumber,FUnitId.FName,FInStockQty,FSrcBillNo,FID,FStockId.FNumber,FStockOrgId.FNumber,FStockStatusId.FNumber,FKeeperTypeId,FKeeperId.FNumber,FOwnerId.FNumber';
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
        arr.add({
          "title": "物料名称",
          "name": "FMaterial",
          "isHide": false,
          "value": {"label": value[6] + "- (" + value[5] + ")", "value": value[5]}
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
          "title": "帐存数量",
          "name": "FRealQty",
          "isHide": false,
          "value": {"label": value[12], "value": value[12]}
        });
        arr.add({
          "title": "盘点数量",
          "name": "FRealQty",
          "isHide": false,
          "value": {"label": "", "value": "0"}
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
    if(stockNumber == null || stockNumber == ""){
      ToastUtil.showInfo('请选择仓库');
    }else{
      _code = event;
      SharedPreferences sharedPreferences =
      await SharedPreferences.getInstance();
      var deptData = sharedPreferences.getString('menuList');
      var menuList = new Map<dynamic, dynamic>.from(jsonDecode(deptData));
      fBarCodeList = menuList['FBarCodeList'];
      if (fBarCodeList == 1) {
        Map<String, dynamic> barcodeMap = Map();
        barcodeMap['FilterString'] = "FBarCodeEn='"+event+"' and FStockID.FNumber= '"+stockNumber+"'";
        barcodeMap['FormId'] = 'QDEP_Cust_BarCodeList';
        barcodeMap['FieldKeys'] =
        'FID,FInQtyTotal,FOutQtyTotal,FEntity_FEntryId,FRemainQty,FBarCodeQty,FStockID.FName,FStockID.FNumber,FMATERIALID.FNUMBER,FOwnerID.FNumber,FBarCode,FSN,FPackageSpec,FProduceDate,FExpiryDate,FStockLocNumberH,FStockID.FIsOpenLocation,FBatchNo';
        Map<String, dynamic> dataMap = Map();
        dataMap['data'] = barcodeMap;
        String order = await CurrencyEntity.polling(dataMap);
        var barcodeData = jsonDecode(order);
        if (barcodeData.length>0) {
          this.getMaterialList(barcodeData[0],event,barcodeData[0][15].trim(), barcodeData[0][16], barcodeData[0][12], barcodeData[0][13].substring(0, 10), barcodeData[0][14].substring(0, 10));
        }else{
          ToastUtil.showInfo('条码不在条码清单中或与盘点仓库不一致');
        }
      }else{
        EasyLoading.show(status: 'loading...');
        this.getMaterialList("0",_code,"",false,"","","");
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
  getMaterialList(barcodeData,code, fLoc,fIsOpenLocation,fAuxPropId,fProduceDate,fExpiryDate) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    var scanCode = code.split(";");
    var postionList = fLoc.split(".");
    if(scanCode.length > 1){
      if(fIsOpenLocation && fLoc!=''){
        if(scanCode[1] == ''){
          userMap['FilterString'] = "FProduceDate='"+fProduceDate+"' and fExpiryDate='"+fExpiryDate+"' and FAuxPropId.FF100002.FNumber='"+fAuxPropId+"' and FMaterialId.FNumber='"+scanCode[0]+"' and FStockId.FNumber = '$stockNumber' and FStockLocId.FF100018.FNumber = '" + postionList[0] + "' and FStockLocId.FF100019.FNumber = '" + postionList[1] + "' and FStockLocId.FF100020.FNumber = '" + postionList[2] + "' and FStockLocId.FF100021.FNumber = '" + postionList[3] + "'";
        }else{
          userMap['FilterString'] = "FProduceDate='"+fProduceDate+"' and fExpiryDate='"+fExpiryDate+"' and FAuxPropId.FF100002.FNumber='"+fAuxPropId+"' and FMaterialId.FNumber='"+scanCode[0]+"' and FLot.FNumber='"+scanCode[1]+"' and FStockId.FNumber = '$stockNumber' and FStockLocId.FF100018.FNumber = '" + postionList[0] + "' and FStockLocId.FF100019.FNumber = '" + postionList[1] + "' and FStockLocId.FF100020.FNumber = '" + postionList[2] + "' and FStockLocId.FF100021.FNumber = '" + postionList[3] + "'";
        }
      }else{
        if(scanCode[1] == ''){
          userMap['FilterString'] = "FProduceDate='"+fProduceDate+"' and fExpiryDate='"+fExpiryDate+"' and FAuxPropId.FF100002.FNumber='"+fAuxPropId+"' and FMaterialId.FNumber='"+scanCode[0]+"' and FStockId.FNumber = '$stockNumber'";
        }else{
          userMap['FilterString'] = "FProduceDate='"+fProduceDate+"' and fExpiryDate='"+fExpiryDate+"' and FAuxPropId.FF100002.FNumber='"+fAuxPropId+"' and FMaterialId.FNumber='"+scanCode[0]+"' and FLot.FNumber='"+scanCode[1]+"' and FStockId.FNumber = '$stockNumber'";
        }
      }
    }
    userMap['FormId'] = 'STK_Inventory';
    userMap['FieldKeys'] =
    'FStockOrgId.FNumber,FMaterialId.FName,FMaterialId.FNumber,FMaterialId.FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FStockId.FNumber,FBaseQty,FStockName,FLot.FNumber,FStockStatusId.FNumber,FKeeperTypeId,FKeeperId.FNumber,FOwnerId.FNumber,FStockLocId.FF100018.FNumber,FStockLocId.FF100019.FNumber,FStockLocId.FF100020.FNumber,FStockLocId.FF100021.FNumber,FStockID.FIsOpenLocation,FAuxPropId.FF100002.FNumber,FMaterialId.FIsKFPeriod,FStockID.FIsOpenLocation,FMaterialId.FIsBatchManage,FProduceDate,FExpiryDate';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    orderDate = [];
    orderDate = jsonDecode(order);
    FDate = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    selectData[DateMode.YMD] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    if (orderDate.length > 0) {
      var number = 0;
      for (var element in hobby) {
        if(element[0]['value']['barcode'].indexOf(code) != -1){
          number++;
          ToastUtil.showInfo('该标签已扫描');
          break;
        }
        //判断是否启用保质期
        if (!element[14]['isHide']) {
          if (element[14]['value']['value'].substring(0, 10) != fProduceDate ||
              element[15]['value']['value'].substring(0, 10) != fExpiryDate) {
            continue;
          }
        }
        //判断是否启用仓位
        if (element[13]['isHide']) {
          if (element[13]['value']['label'] != fLoc) {
            continue;
          }
        }
        //判断包装规格
        if (element[1]['value']['label'] != fAuxPropId) {
          continue;
        }
        if(element[0]['value']['value']+"-"+element[6]['value']['value']+"-"+element[5]['value']['value'] == barcodeData[8]+"-"+barcodeData[17]+"-"+barcodeData[7]){
          element[4]['value']['label'] =  (double.parse(element[4]['value']['label']) + double.parse(barcodeData[4].toString())).toString();
          element[4]['value']['value'] =  element[4]['value']['label'];
          element[0]['value']['barcode'].add(code);
          number++;
          break;
        }
      }
      if(number == 0){
        for(var value in orderDate){
          List arr = [];
          arr.add({
            "title": "物料名称",
            "name": "FMaterial",
            "isHide": false,
            "value": {"label": value[1] + "- (" + value[2] + ")", "value": value[2],"barcode": [code]}
          });
          arr.add({
            "title": "包装规格",
            "isHide": false,
            "name": "FMaterialIdFSpecification",
            "value": {"label": value[19], "value": value[19]}
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
            "value": {"label": barcodeData[4].toString(), "value": barcodeData[4].toString()}
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
            "isHide": !value[22],
            "value": {"label": value[9]==null?"":value[9], "value": value[9]==null?"":value[9]}
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
            "title": "仓位",
            "name": "FStockID",
            "isHide": !value[21],
            "value": {"label": value[14] == null?"":value[14]+"."+value[15]+"."+value[16]+"."+value[17], "value": value[14] == null?"":value[14]+"."+value[15]+"."+value[16]+"."+value[17]}
          });
          arr.add({
            "title": "生产日期",
            "name": "FProduceDate",
            "isHide": !value[20],
            "value": {
              "label": value[23].substring(0, 10),
              "value": value[23].substring(0, 10)
            }
          });
          arr.add({
            "title": "有效期至",
            "name": "FExpiryDate",
            "isHide": !value[20],
            "value": {
              "label": value[24].substring(0, 10),
              "value": value[24].substring(0, 10)
            }
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
          }else if(hobby  == 'stock'){
            stockName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                stockNumber = stockListObj[elementIndex][2];
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
  //保存
  saveOrder() async {
    if (this.hobby.length > 0) {
      setState(() {
        /*this.isSubmit = true;*/
      });
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
      Model['FID'] = 0;
      Model['FDate'] = FDate;
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      var menuData = sharedPreferences.getString('MenuPermissions');
      var deptData = jsonDecode(menuData)[0];
      Model['FStockOrgId'] = {"FNumber": this.orderDate[0][0]};
      Model['FOwnerIdHead'] = {"FNumber": this.orderDate[0][13]};
      /* Model['FDeptId'] = {"FNumber": this.departmentNumber};*/
      Model['FOwnerTypeIdHead'] = "BD_OwnerOrg";
      var FEntity1 = [];
      var FEntity = [];
      var FEntity2 = [];
      var hobbyIndex = 0;
      print(this.orderDate);
      for(var element in this.hobby){
        if (element[4]['value']['value'] != '0' &&
            element[4]['value']['value'] != '' && double.parse(element[4]['value']['value']) != element[3]['value']['value']) {
          Map<String, dynamic> FEntityItem = Map();
          FEntityItem['FMaterialId'] = {
            "FNumber": element[0]['value']['value']
          };
          FEntityItem['FAuxPropId'] = {
            "FAUXPROPID__FF100002": {"FNumber": element[1]['value']['value']}
          };
          FEntityItem['FUnitID'] = {
            "FNumber": element[2]['value']['value']
          };
          FEntityItem['FStockId'] = {
            "FNumber": element[5]['value']['value']
          };
          FEntityItem['FOwnerid'] = {
            "FNumber": element[9]['value']['value']
          };
          FEntityItem['FLOT'] = {
            "FNumber": element[6]['value']['value']
          };
          FEntityItem['FStockStatusId'] = {
            "FNumber": element[10]['value']['value']
          };
          FEntityItem['FKeeperTypeId'] = element[11]['value']['value'];
          FEntityItem['FKeeperId'] = {
            "FNumber": element[12]['value']['value']
          };
          if (!element[13]['isHide']) {
            Map<String, dynamic> stockMap = Map();
            stockMap['FormId'] = 'BD_STOCK';
            stockMap['FieldKeys'] =
            'FFlexNumber';
            stockMap['FilterString'] = "FNumber = '" +
                element[5]['value']['value'] +
                "'";
            Map<String, dynamic> stockDataMap = Map();
            stockDataMap['data'] = stockMap;
            String res = await CurrencyEntity.polling(stockDataMap);
            var stockRes = jsonDecode(res);
            if (stockRes.length > 0) {
              var postionList = element[13]['value']['value'].split(".");
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
          /*FEntityItem['FReturnType'] = 1;*/
          FEntityItem['FCountQty'] = element[4]['value']['value'];
          FEntityItem['FOwnerTypeId'] = "BD_OwnerOrg";
          if(double.parse(element[4]['value']['value']) > element[3]['value']['value']){
            FEntity1.add(FEntityItem);
          }else{
            FEntity2.add(FEntityItem);
          }
          FEntity.add(FEntityItem);
        }
        hobbyIndex++;
      }
      if (FEntity.length == 0 ) {
        this.isSubmit = false;
        ToastUtil.showInfo('盘点数量未录入或盘点数量无差异，无须保存');
        return;
      }
      for(var i=0;i<2;i++){
        //盘盈
        if(FEntity1.length>0){
          dataMap['formid'] = 'STK_StockCountGain';
          Model['FBillTypeID'] = {"FNUMBER": "PY01_SYS"};
          Model['FBillEntry'] = FEntity1;
          orderMap['Model'] = Model;
          dataMap['data'] = orderMap;
          print(jsonEncode(dataMap));
          String order = await SubmitEntity.save(dataMap);
          var res = jsonDecode(order);
          print(res);
          if (res['Result']['ResponseStatus']['IsSuccess']) {
            Map<String, dynamic> submitMap = Map();
            FEntity1 =  [];
            submitMap = {
              "formid": "STK_StockCountGain",
              "data": {
                'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
              }
            };
            //提交
            HandlerOrder.orderHandler(
                context,
                submitMap,
                1,
                "STK_StockCountGain",
                SubmitEntity.submit(submitMap))
                .then((submitResult) {
              if (submitResult) {
                //审核
                HandlerOrder.orderHandler(
                    context,
                    submitMap,
                    1,
                    "STK_StockCountGain",
                    SubmitEntity.audit(submitMap))
                    .then((auditResult) {
                  if (auditResult) {
                    //提交清空页面
                    setState(() {
                      if(FEntity1.length == 0 && FEntity2.length == 0){
                        this.hobby = [];
                        this.orderDate = [];
                        this.FBillNo = '';
                        this.isSubmit = false;
                        ToastUtil.showInfo('提交成功');
                        /* Navigator.of(context).pop();*/
                      }
                    });
                  } else {
                    //失败后反审
                    HandlerOrder.orderHandler(
                        context,
                        submitMap,
                        0,
                        "STK_StockCountGain",
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
        }else if(FEntity2.length>0){
          //盘亏
          dataMap['formid'] = 'STK_StockCountLoss';
          Model['FBillTypeID'] = {"FNUMBER": "PK01_SYS"};
          Model['FBillEntry'] = FEntity2;
          orderMap['Model'] = Model;
          dataMap['data'] = orderMap;
          print(jsonEncode(dataMap));
          String order = await SubmitEntity.save(dataMap);
          var res = jsonDecode(order);
          print(res);
          if (res['Result']['ResponseStatus']['IsSuccess']) {
            Map<String, dynamic> submitMap = Map();
            FEntity2 =  [];
            submitMap = {
              "formid": "STK_StockCountLoss",
              "data": {
                'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
              }
            };
            //提交
            HandlerOrder.orderHandler(
                context,
                submitMap,
                1,
                "STK_StockCountLoss",
                SubmitEntity.submit(submitMap))
                .then((submitResult) {
              if (submitResult) {
                //审核
                HandlerOrder.orderHandler(
                    context,
                    submitMap,
                    1,
                    "STK_StockCountLoss",
                    SubmitEntity.audit(submitMap))
                    .then((auditResult) {
                  if (auditResult) {
                    //提交清空页面
                    setState(() {
                      if(FEntity1.length == 0 && FEntity2.length == 0){
                        this.hobby = [];
                        this.orderDate = [];
                        this.FBillNo = '';
                        this.isSubmit = false;
                        ToastUtil.showInfo('提交成功');
                        /*Navigator.of(context).pop();*/
                      }
                    });
                  } else {
                    //失败后反审
                    HandlerOrder.orderHandler(
                        context,
                        submitMap,
                        0,
                        "STK_StockCountLoss",
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
        }
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
                  _item('仓库',  this.stockList, this.stockName,
                      'stock'),
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
