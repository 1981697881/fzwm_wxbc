import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'package:date_format/date_format.dart';
import 'package:fzwm_wxbc/model/currency_entity.dart';
import 'package:fzwm_wxbc/model/submit_entity.dart';
import 'package:fzwm_wxbc/utils/toast_util.dart';
import 'package:gbk2utf8/gbk2utf8.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:bluetooth_thermal_printer/bluetooth_thermal_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
class PrintPage extends StatefulWidget {
  var data;

  PrintPage({Key? key, @required this.data}) : super(key: key);

  @override
  _PrintPageState createState() => _PrintPageState(data);
}

class _PrintPageState extends State<PrintPage> {
  var printData;
  var sheetNum = '1';
  final _textNumber = TextEditingController();
  _PrintPageState(data) {
    if (data != null) {
      this._textNumber.text = this.sheetNum;
      this.printData = data;
      this.getConnectionStatus();
    }
  }

  @override
  void initState() {
    super.initState();
  }
  @override
  void dispose() {
    this._textNumber.dispose();
    super.dispose();
  }
  bool connected = false;
  List availableBluetoothDevices = [];

  //获取连接状态
  getConnectionStatus() async {
    String? isConnected = await BluetoothThermalPrinter.connectionStatus;
    if (isConnected == 'true') {
      setState(() {
        ToastUtil.showInfo('已连接');
        connected = true;
      });
    } else {
      setState(() {
        ToastUtil.showInfo('连接失败');
        connected = false;
      });
    }
  }

  Future<void> getBluetooth() async {
    final List? bluetooths = await BluetoothThermalPrinter.getBluetooths;
    print("Print $bluetooths");
    setState(() {
      availableBluetoothDevices = bluetooths!;
    });
  }

  Future<void> setConnect(String mac) async {
    try {
      EasyLoading.show(status: '连接中...');
      final String? result = await BluetoothThermalPrinter.connect(mac)
          .timeout(Duration(seconds: 15)); // 设置超时

      if (result?.toLowerCase() == 'success' || result == 'true') {
        setState(() => connected = true);
        ToastUtil.showInfo('连接成功');
      } else {
        ToastUtil.showInfo('连接失败: $result');
      }
    } on TimeoutException {
      ToastUtil.showInfo('连接超时');
    } catch (e) {
      ToastUtil.showInfo('连接异常: $e');
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> printGraphics(bytes) async {
    String? isConnected = await BluetoothThermalPrinter.connectionStatus;
    if (isConnected == "true") {
      // List<int> bytes = await getGraphicsTicket();
      final result = await BluetoothThermalPrinter.writeBytes(bytes);
      print("Print $result");
    } else {
      //Hadnle Not Connected Senario
    }
  }

  bool cnIsNumber(val) {
    final reg = RegExp(r'^-?[0-9.]+$');
    return reg.hasMatch(val);

  }

  Future<void> getGraphicsTicket() async {
    var data;
    if(printData['type'] == "STK_InStock"){
      data = printData['data']['Model']['FInStockEntry'];
    }else{
      data = printData['data']['Model']['FEntity'];
    }
    for (var value in data) {
      if(printData['type'] == "STK_InStock"){
        var barcodeNum = 1.0;
        var fRealQty = value['FRealQty'];
        var packing = value['FAuxPropId']['FAUXPROPID__FF100002']['FNumber'];
        //获取条码流水号
        Map<String, dynamic> barcodeMap = Map();
        barcodeMap['FilterString'] =
            "FMATERIALID.FNUMBER='" + value['FMaterialId']['FNumber'] + "'";
        barcodeMap['FormId'] = 'QDEP_Cust_BarCodeList';
        barcodeMap['OrderString'] = 'FOrder DESC';
        barcodeMap['FieldKeys'] = 'FID,FOrder';
        Map<String, dynamic> dataMap = Map();
        dataMap['data'] = barcodeMap;
        String order = await CurrencyEntity.polling(dataMap);
        var barcodeData = jsonDecode(order);
        if (barcodeData.length > 0) {
          barcodeNum = barcodeData[0][1] + 1.0;
        } else {
          barcodeNum = 1.0;
        }
        //判断规格重量
        if (cnIsNumber(packing) == true) {
          print(fRealQty);
          print(packing.toUpperCase());
        } else {
          packing = packing.toUpperCase();
          packing = packing.replaceAll("KG", '');
          //处理后判断规格重量是否数字
          if (cnIsNumber(packing) == true) {
            var printNum = (int.parse(fRealQty) / int.parse(packing)).ceil();
            var remainingQuantity = int.parse(fRealQty);
            for (var i = 0; i < printNum; i++) {
              //判断成品或原料
              var println;
              var codeCont = value['FMaterialId']['FNumber'] + ';' +value['FLot']['FNumber']+ ';' +value['FProduceDate'].substring(0, 10)+ ';' +(remainingQuantity >= int.parse(packing) ? packing : remainingQuantity).toString()+ ';' +printData['FBillNo']+ ';' +DateTime.now().millisecondsSinceEpoch.toString()+ ';' +barcodeNum.toString();
              print(codeCont);
              println = 'SIZE 100.0 mm,73.0 mm\r\n' +
                  'GAP 2 mm\r\n' +
                  'CLS\r\n' +
                  /*'BOX 5, 5, 800, 550, 3\r\n' +*/

                  'BAR 90, 80, 425, 1\r\n' +
                  'BAR 90, 140, 425, 1\r\n' +
                  'BAR 90, 200, 425, 1\r\n' +
                  'BAR 150, 260, 365, 1\r\n' +
                  'BAR 150, 320, 365, 1\r\n' +
                  'BAR 120, 380, 375, 1\r\n' +
                  'BAR 90, 440, 425, 1\r\n' +
                  'BAR 120, 500, 375, 1\r\n' +
                  'TEXT 5,40,"TSS24.BF2",0,1,1,"品名:"\r\n' +
                  'TEXT 5,100,"TSS24.BF2",0,1,1,"批号:"\r\n' +
                  'TEXT 5,160,"TSS24.BF2",0,1,1,"净重:"\r\n' +
                  'TEXT 5,220,"TSS24.BF2",0,1,1,"检验状态:"\r\n' +
                  'TEXT 5,280,"TSS24.BF2",0,1,1,"到货日期:"\r\n' +
                  'TEXT 5,340,"TSS24.BF2",0,1,1,"有效期:"\r\n' +
                  'TEXT 5,400,"TSS24.BF2",0,1,1,"备注:"\r\n' +
                  'TEXT 5,460,"TSS24.BF2",0,1,1,"流水号:"\r\n' +
                  'TEXT 100,40,"TSS24.BF2",0,1,1,"${value['FMaterialName']}"\r\n' +
                  'TEXT 100,100,"TSS24.BF2",0,1,1,"${value['FLot']['FNumber']}"\r\n' +
                  'TEXT 100,160,"TSS24.BF2",0,1,1,"${value['FAuxPropId']['FAUXPROPID__FF100002']['FNumber']}"\r\n' +
                  'TEXT 180,220,"TSS24.BF2",0,1,1,"合格"\r\n' +
                  'TEXT 180,280,"TSS24.BF2",0,1,1,"${value['FProduceDate'].substring(0, 10)}"\r\n' +
                  'TEXT 150,340,"TSS24.BF2",0,1,1,"${value['FExpiryDate'].substring(0, 10)}"\r\n' +
                  'TEXT 100,400,"TSS24.BF2",0,1,1,"${value['FNote']==null?'':value['FNote']}"\r\n' +
                  'TEXT 150,460,"TSS24.BF2",0,1,1,"${barcodeNum}"\r\n' +
                  'QRCODE 550,140,M,5,A,0,"${codeCont}"\r\n' +
                  'PRINT 1,${sheetNum}\r\n';
             /* println = "! 0 200 200 580 1\n" +
                    "PAGE-WIDTH 750\n" +
                    "LEFT\n" +
                    "BOX 5 5 748 540 3\n" +
                    "L 140 100 500 100 3\n" +
                    "L 140 160 500 160 3\n" +
                    "L 140 220 500 220 3\n" +
                    "L 140 280 500 280 3\n" +
                    "L 140 340 500 340 3\n" +
                    "L 140 400 500 400 3\n" +
                    "LEFT\n" +
                    "T 0 24 20 60 品名:\n" +
                    "T 0 24 20 120 批号:\n" +
                    "T 0 24 20 180 净重:\n" +
                    "T 0 24 20 240 到货日期:\n" +
                    "T 0 24 20 300 有效期:\n" +
                    "T 0 24 20 360 备注:\n" +
                    "LEFT\n" +
                    "T 0 24 150 60 ${value['FMaterialName']}\n" +
                    "T 0 24 150 120 ${value['FLot']['FNumber']}\n" +
                    "T 0 24 150 180 ${value['FAuxPropId']['FAUXPROPID__FF100002']['FNumber']}\n" +
                    "T 0 24 150 240 ${value['FProduceDate']}\n" +
                    "T 0 24 150 300 ${value['FExpiryDate']}\n" +
                    "T 0 24 150 360 ${value['FNote']}\n" +
                    "CENTER\n" +
                    "B QR 450 170 M 3 U 6\n MA,${codeCont}\nENDQR\n" +
                    "FORM\n" +
                    "PRINT\n";*/
              Map<String, dynamic> dataCodeMap = Map();
              dataCodeMap['formid'] = 'QDEP_Cust_BarCodeList';
              Map<String, dynamic> orderCodeMap = Map();
              orderCodeMap['NeedReturnFields'] = [];
              orderCodeMap['IsDeleteEntry'] = false;
              Map<String, dynamic> codeModel = Map();
              codeModel['FID'] = 0;
              codeModel['FMATERIALID'] = {
                "FNUMBER": value['FMaterialId']['FNumber']
              };
              codeModel['FBatchNo'] = value['FLot']['FNumber'];
              codeModel['FSrcBillNo'] = printData['type'];
              codeModel['FBarCode'] = codeCont;
              codeModel['FBarCodeEn'] = codeCont;
              codeModel['FSourceBill'] = printData['FBillNo'];
              codeModel['FOrder'] = barcodeNum;
              codeModel['FProduceDate'] = value['FProduceDate'];
              codeModel['FExpiryDate'] = value['FExpiryDate'];
              codeModel['FPackageSpec'] = value['FAuxPropId']['FAUXPROPID__FF100002']['FNumber'];
              codeModel['FBarCodeQty'] = remainingQuantity >= int.parse(packing)
                  ? packing
                  : remainingQuantity;
              codeModel['FRemainQty '] = remainingQuantity >= int.parse(packing)
                  ? packing
                  : remainingQuantity;
              codeModel['FOwnerID'] = {"FNUMBER": value['FOwnerId']['FNumber']};
              codeModel['FStockOrgID'] = {
                "FNUMBER": value['FOwnerId']['FNumber']
              };
              codeModel['FStockID'] = {"FNUMBER": value['FStockId']['FNumber']};
              Map<String, dynamic> codeFEntityItem = Map();
              codeFEntityItem['FEntryStockID'] = {
                "FNUMBER": value['FStockId']['FNumber']
              };
              if (value['FStockLocId'] !=null && !value['FStockLocId'].isEmpty) {
                Map<String, dynamic> stockMap = Map();

                stockMap['FormId'] = 'BD_STOCK';
                stockMap['FieldKeys'] =
                'FFlexNumber';
                stockMap['FilterString'] = "FNumber = '" +
                    value['FStockId']['FNumber'] +
                    "'";
                Map<String, dynamic> stockDataMap = Map();
                stockDataMap['data'] = stockMap;
                String res = await CurrencyEntity.polling(stockDataMap);
                var stockRes = jsonDecode(res);
                if (stockRes.length > 0) {
                  codeModel['FStockLocIDH'] = {};
                  codeFEntityItem['FStockLocID'] = {};
                  var positionNumber = [];
                  for(var dimension in stockRes){
                    codeModel['FStockLocIDH']["FSTOCKLOCIDH__" + dimension[0]] = {
                      "FNumber": value['FStockLocId']["FSTOCKLOCID__" + dimension[0]]["FNumber"]
                    };
                    positionNumber.add(value['FStockLocId']["FSTOCKLOCID__" + dimension[0]]["FNumber"]);
                    codeFEntityItem['FStockLocID']["FSTOCKLOCID__" + dimension[0]] = {
                      "FNumber": value['FStockLocId']["FSTOCKLOCID__" + dimension[0]]["FNumber"]
                    };
                  }
                  codeFEntityItem['FStockLocNumber'] = positionNumber.join(".");
                  codeModel['FStockLocNumberH'] = positionNumber.join(".");
                }
              }
              codeFEntityItem['FBillDate'] = formatDate(DateTime.now(), [
                yyyy,
                "-",
                mm,
                "-",
                dd,
              ]);
              codeFEntityItem['FInQty'] = remainingQuantity >= int.parse(packing)
                  ? packing
                  : remainingQuantity;
              codeFEntityItem['FEntryBillNo'] = printData['FBillNo'];

              var codeFEntity = [codeFEntityItem];
              codeModel['FEntity'] = codeFEntity;
              orderCodeMap['Model'] = codeModel;
              dataCodeMap['data'] = orderCodeMap;
              print(dataCodeMap);
              var paramsData= jsonEncode(dataCodeMap);
              String codeRes = await SubmitEntity.save(dataCodeMap);
              var res = jsonDecode(codeRes);
              if (res['Result']['ResponseStatus']['IsSuccess']) {
                barcodeNum++;
                remainingQuantity = remainingQuantity - int.parse(packing);
                await this.printGraphics(gbk.encode(println));
              } else {
                setState(() {
                  ToastUtil.errorDialog(context,
                      res['Result']['ResponseStatus']['Errors'][0]['Message']);
                });
              }
            }
          } else {
            ToastUtil.showInfo('包装规格有误,无法换算,请检查！');
          }
        }
      }else{
        var barcodeNum = 1.0;
        var fRealQty = value['FQty'].toString();
        var packing = value['FAuxPropID']['FAUXPROPID__FF100002']['FNumber'];
        //获取条码流水号
        Map<String, dynamic> barcodeMap = Map();
        barcodeMap['FilterString'] =
            "FMATERIALID.FNUMBER='" + value['FMaterialId']['FNumber'] + "'";
        barcodeMap['FormId'] = 'QDEP_Cust_BarCodeList';
        barcodeMap['OrderString'] = 'FOrder DESC';
        barcodeMap['FieldKeys'] = 'FID,FOrder';
        Map<String, dynamic> dataMap = Map();
        dataMap['data'] = barcodeMap;
        String order = await CurrencyEntity.polling(dataMap);
        var barcodeData = jsonDecode(order);
        if (barcodeData.length > 0) {
          barcodeNum = barcodeData[0][1] + 1.0;
        } else {
          barcodeNum = 1.0;
        }
        //判断规格重量
        if (cnIsNumber(packing) == true) {
          print(fRealQty);
          print(packing.toUpperCase());
        } else {
          packing = packing.toUpperCase();
          packing = packing.replaceAll("KG", '');
          //处理后判断规格重量是否数字
          if (cnIsNumber(packing) == true) {
            var printNum = (double.parse(fRealQty) / int.parse(packing)).ceil();
            var remainingQuantity = double.parse(fRealQty);
            for (var i = 0; i < printNum; i++) {
              //判断成品或原料
              var println;
              var codeCont = value['FMaterialId']['FNumber'] + ';' +value['FLot']['FNumber']+ ';' +value['FProduceDate'].substring(0, 10)+ ';' +(remainingQuantity >= int.parse(packing) ? packing : remainingQuantity).toString()+ ';' +printData["data"]["Model"]['FBillNo']+ ';' +DateTime.now().millisecondsSinceEpoch.toString()+ ';' +barcodeNum.toString();
              print(codeCont);
              println = 'SIZE 100.0 mm,73.0 mm\r\n' +
                  'GAP 2 mm\r\n' +
                  'CLS\r\n' +
                  /*'BOX 5, 5, 800, 550, 3\r\n' +*/
                  'BAR 90, 80, 425, 1\r\n' +
                  'BAR 90, 140, 425, 1\r\n' +
                  'BAR 90, 200, 425, 1\r\n' +
                  'BAR 150, 260, 365, 1\r\n' +
                  'BAR 150, 320, 365, 1\r\n' +
                  'BAR 120, 380, 375, 1\r\n' +
                  'BAR 90, 440, 425, 1\r\n' +
                  'BAR 120, 500, 375, 1\r\n' +
                  'TEXT 5,40,"TSS24.BF2",0,1,1,"品名:"\r\n' +
                  'TEXT 5,100,"TSS24.BF2",0,1,1,"批号:"\r\n' +
                  'TEXT 5,160,"TSS24.BF2",0,1,1,"净重:"\r\n' +
                  'TEXT 5,220,"TSS24.BF2",0,1,1,"检验状态:"\r\n' +
                  'TEXT 5,280,"TSS24.BF2",0,1,1,"生产日期:"\r\n' +
                  'TEXT 5,340,"TSS24.BF2",0,1,1,"有效期:"\r\n' +
                  'TEXT 5,400,"TSS24.BF2",0,1,1,"备注:"\r\n' +
                  'TEXT 5,460,"TSS24.BF2",0,1,1,"流水号:"\r\n' +
                  'TEXT 100,40,"TSS24.BF2",0,1,1,"${value['FMaterialName']}"\r\n' +
                  'TEXT 100,100,"TSS24.BF2",0,1,1,"${value['FLot']['FNumber']}"\r\n' +
                  'TEXT 100,160,"TSS24.BF2",0,1,1,"${value['FAuxPropID']['FAUXPROPID__FF100002']['FNumber']}"\r\n' +
                  'TEXT 180,220,"TSS24.BF2",0,1,1,"合格"\r\n' +
                  'TEXT 180,280,"TSS24.BF2",0,1,1,"${value['FProduceDate'].substring(0, 10)}"\r\n' +
                  'TEXT 150,340,"TSS24.BF2",0,1,1,"${value['FExpiryDate'].substring(0, 10)}"\r\n' +
                  'TEXT 100,400,"TSS24.BF2",0,1,1,"${value['FNote']==null?'':value['FNote']}"\r\n' +
                  'TEXT 150,460,"TSS24.BF2",0,1,1,"${barcodeNum}"\r\n' +
                  'QRCODE 550,140,M,5,A,0,"${codeCont}"\r\n' +
                  'PRINT 1,${sheetNum}\r\n';
                /*println = "! 0 200 200 580 1\n" +
                    "PAGE-WIDTH 750\n" +
                    "LEFT\n" +
                    "BOX 5 5 748 540 3\n" +
                    "L 140 100 500 100 3\n" +
                    "L 140 160 500 160 3\n" +
                    "L 140 220 500 220 3\n" +
                    "L 140 280 500 280 3\n" +
                    "L 140 340 500 340 3\n" +
                    "L 140 400 500 400 3\n" +
                    "LEFT\n" +
                    "T 0 24 20 60 品名:\n" +
                    "T 0 24 20 120 批号:\n" +
                    "T 0 24 20 180 净重:\n" +
                    "T 0 24 20 240 入库日期:\n" +
                    "T 0 24 20 300 有效期:\n" +
                    "T 0 24 20 360 备注:\n" +
                    "LEFT\n" +
                    "T 0 24 150 60 ${value['FMaterialName']}\n" +
                    "T 0 24 150 120 ${value['FLot']['FNumber']}\n" +
                    "T 0 24 150 180 ${value['FAuxPropId']['FAUXPROPID__FF100002']['FNumber']}\n" +
                    "T 0 24 150 240 ${value['FProduceDate']}\n" +
                    "T 0 24 150 300 ${value['FExpiryDate']}\n" +
                    "T 0 24 150 360 ${value['FNote']}\n" +
                    "CENTER\n" +
                    "B QR 450 170 M 3 U 6\n MA,${codeCont}\nENDQR\n" +
                    "FORM\n" +
                    "PRINT\n";*/
              Map<String, dynamic> dataCodeMap = Map();
              dataCodeMap['formid'] = 'QDEP_Cust_BarCodeList';
              Map<String, dynamic> orderCodeMap = Map();
              orderCodeMap['NeedReturnFields'] = [];
              orderCodeMap['IsDeleteEntry'] = false;
              Map<String, dynamic> codeModel = Map();
              codeModel['FID'] = 0;
              codeModel['FMATERIALID'] = {
                "FNUMBER": value['FMaterialId']['FNumber']
              };
              codeModel['FBatchNo'] = value['FLot']['FNumber'];
              codeModel['FSrcBillNo'] = printData['type'];
              codeModel['FBarCode'] = codeCont;
              codeModel['FBarCodeEn'] = codeCont;
              codeModel['FSourceBill'] = printData['FBillNo'];
              codeModel['FOrder'] = barcodeNum;
              codeModel['FProduceDate'] = value['FProduceDate'];
              codeModel['FExpiryDate'] = value['FExpiryDate'];
              codeModel['FPackageSpec'] = value['FAuxPropID']['FAUXPROPID__FF100002']['FNumber'];
              codeModel['FBarCodeQty'] = remainingQuantity >= int.parse(packing)
                  ? packing
                  : remainingQuantity;
              codeModel['FRemainQty '] = remainingQuantity >= int.parse(packing)
                  ? packing
                  : remainingQuantity;
              codeModel['FOwnerID'] = {"FNUMBER": value['FOwnerId']['FNumber']};
              codeModel['FStockOrgID'] = {
                "FNUMBER": value['FOwnerId']['FNumber']
              };
              codeModel['FStockID'] = {"FNUMBER": value['FStockId']['FNumber']};
              Map<String, dynamic> codeFEntityItem = Map();
              codeFEntityItem['FEntryStockID'] = {
                "FNUMBER": value['FStockId']['FNumber']
              };
              print(value['FStockLocId']);
              if (value['FStockLocId'] !=null && !value['FStockLocId'].isEmpty) {
                Map<String, dynamic> stockMap = Map();
                stockMap['FormId'] = 'BD_STOCK';
                stockMap['FieldKeys'] =
                'FFlexNumber';
                stockMap['FilterString'] = "FNumber = '" +
                    value['FStockId']['FNumber'] +
                    "'";
                Map<String, dynamic> stockDataMap = Map();
                stockDataMap['data'] = stockMap;
                String res = await CurrencyEntity.polling(stockDataMap);
                var stockRes = jsonDecode(res);
                if (stockRes.length > 0) {
                  codeModel['FStockLocIDH'] = {};
                  codeFEntityItem['FStockLocID'] = {};
                  var positionNumber = [];
                  for(var dimension in stockRes){
                    codeModel['FStockLocIDH']["FSTOCKLOCIDH__" + dimension[0]] = {
                      "FNumber": value['FStockLocId']["FSTOCKLOCID__" + dimension[0]]["FNumber"]
                    };
                    positionNumber.add(value['FStockLocId']["FSTOCKLOCID__" + dimension[0]]["FNumber"]);
                    codeFEntityItem['FStockLocID']["FSTOCKLOCID__" + dimension[0]] = {
                      "FNumber": value['FStockLocId']["FSTOCKLOCID__" + dimension[0]]["FNumber"]
                    };
                  }
                  codeFEntityItem['FStockLocNumber'] = positionNumber.join(".");
                  codeModel['FStockLocNumberH'] = positionNumber.join(".");
                }
              }
              codeFEntityItem['FBillDate'] = formatDate(DateTime.now(), [
                yyyy,
                "-",
                mm,
                "-",
                dd,
              ]);
              codeFEntityItem['FInQty'] = remainingQuantity >= int.parse(packing)
                  ? packing
                  : remainingQuantity;
              codeFEntityItem['FEntryBillNo'] = printData['FBillNo'];

              var codeFEntity = [codeFEntityItem];
              codeModel['FEntity'] = codeFEntity;
              orderCodeMap['Model'] = codeModel;
              dataCodeMap['data'] = orderCodeMap;
              print(dataCodeMap);
              String codeRes = await SubmitEntity.save(dataCodeMap);
              var res = jsonDecode(codeRes);
              if (res['Result']['ResponseStatus']['IsSuccess']) {
                barcodeNum++;
                remainingQuantity = remainingQuantity - int.parse(packing);
                await this.printGraphics(gbk.encode(println));
              } else {
                setState(() {
                  ToastUtil.errorDialog(context,
                      res['Result']['ResponseStatus']['Errors'][0]['Message']);
                });
              }
            }
          } else {
              ToastUtil.showInfo('包装规格有误,无法换算,请检查！');
            }
          }
        }
    }
    //println.codeUnits.toList();
    //return gbk.encode(println);
  }

  @override
  Widget build(BuildContext context) {
    return FlutterEasyLoading(
      child: Scaffold(
        appBar: AppBar(
          title: Text("打印标签"),
          centerTitle: true,
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              }),
        ),
        body: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("搜索打印机"),
              TextButton(
                onPressed: () {
                  this.getBluetooth();
                },
                child: Text("点击搜索"),
              ),
              Container(
                height: 150,
                child: ListView.builder(
                  itemCount: availableBluetoothDevices.length > 0
                      ? availableBluetoothDevices.length
                      : 0,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () {
                        String select = availableBluetoothDevices[index];
                        List list = select.split("#");
                        // String name = list[0];
                        String mac = list[1];
                        this.setConnect(mac);
                      },
                      title: Text('${availableBluetoothDevices[index]}'),
                      subtitle: Text("点击链接"),
                    );
                  },
                ),
              ),
              Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Card(
                      child: Column(children: <Widget>[
                        TextField(
                          style: TextStyle(color: Colors.black87),
                          keyboardType: TextInputType.number,
                          controller: this._textNumber,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^[1-9]\d*|^$')),
                          ],
                          decoration: InputDecoration(hintText: "请输入份数"),
                          onChanged: (value) {
                            setState(() {
                              this.sheetNum = value;
                            });
                          },
                        ),
                      ]))),
              SizedBox(
                height: 30,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: RaisedButton(
                        padding: EdgeInsets.all(15.0),
                        child: Text("打印"),
                        textColor: Colors.white,
                        color: this.connected
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                        onPressed: connected ?getGraphicsTicket: null,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
