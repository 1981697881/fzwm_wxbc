import 'dart:async';
import 'dart:convert';
import 'package:date_format/date_format.dart';
import 'package:fzwm_wxbc/model/currency_entity.dart';
import 'package:fzwm_wxbc/model/submit_entity.dart';
import 'package:fzwm_wxbc/utils/toast_util.dart';
import 'package:gbk2utf8/gbk2utf8.dart';
import 'package:bluetooth_thermal_printer/bluetooth_thermal_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';

class PrintPage extends StatefulWidget {
  var data;

  PrintPage({Key? key, @required this.data}) : super(key: key);

  @override
  _PrintPageState createState() => _PrintPageState(data);
}

class _PrintPageState extends State<PrintPage> {
  var printData;

  _PrintPageState(data) {
    if (data != null) {
      this.printData = data;
      this.getConnectionStatus();
    }
  }

  @override
  void initState() {
    super.initState();
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
    final String? result = await BluetoothThermalPrinter.connect(mac);
    print("state conneected $result");
    if (result == "true") {
      setState(() {
        ToastUtil.showInfo('连接成功');
        connected = true;
      });
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

              println = 'SIZE 100.0 mm,73.0 mm\r\n' +
                  'GAP 2 mm\r\n' +
                  'CLS\r\n' +
                  'BOX 5, 5, 800, 550, 3\r\n' +
                  'BAR 140, 100, 460, 1\r\n' +
                  'BAR 140, 180, 460, 1\r\n' +
                  'BAR 140, 260, 460, 1\r\n' +
                  'BAR 220, 340, 380, 1\r\n' +
                  'BAR 190, 420, 410, 1\r\n' +
                  'BAR 140, 500, 460, 1\r\n' +
                  'TEXT 10,50,"TSS24.BF2",0,2,2,"品名:"\r\n' +
                  'TEXT 10,130,"TSS24.BF2",0,2,2,"批号:"\r\n' +
                  'TEXT 10,210,"TSS24.BF2",0,2,2,"净重:"\r\n' +
                  'TEXT 10,290,"TSS24.BF2",0,2,2,"到货日期:"\r\n' +
                  'TEXT 10,370,"TSS24.BF2",0,2,2,"有效期:"\r\n' +
                  'TEXT 10,450,"TSS24.BF2",0,2,2,"备注:"\r\n' +
                  'TEXT 150,50,"TSS24.BF2",0,2,2,"${value['FMaterialName']}"\r\n' +
                  'TEXT 150,130,"TSS24.BF2",0,2,2,"${value['FLot']['FNumber']}"\r\n' +
                  'TEXT 150,210,"TSS24.BF2",0,2,2,"${value['FAuxPropId']['FAUXPROPID__FF100002']['FNumber']}"\r\n' +
                  'TEXT 230,290,"TSS24.BF2",0,2,2,"${value['FProduceDate'].substring(0, 10)}"\r\n' +
                  'TEXT 200,370,"TSS24.BF2",0,2,2,"${value['FExpiryDate'].substring(0, 10)}"\r\n' +
                  'TEXT 150,450,"TSS24.BF2",0,2,2,"${value['FNote']}"\r\n' +
                  'QRCODE 610,180,M,5,A,0,"${codeCont}"\r\n' +
                  'PRINT 1,1\r\n';
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
              codeFEntityItem['FEntryStockID'] = {
                "FNUMBER": value['FStockId']['FNumber']
              };
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
      }else{
        var barcodeNum = 1.0;
        for(var ii=0;ii<printData['FInStockType'].length;ii++){
          var fRealQty;
          if(printData['FInStockType'][ii]['FInStockType'] == "1"){
            fRealQty = value['FFailQty'];
          }else{
            fRealQty = value['FQuaQty'];
          }
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
                remainingQuantity = remainingQuantity - int.parse(packing);
                //判断成品或原料
                var println;
                var codeCont = value['FMaterialId']['FNumber'] + ';' +value['FLot']['FNumber']+ ';' +value['FProduceDate'].substring(0, 10)+ ';' +(remainingQuantity >= int.parse(packing) ? packing : remainingQuantity).toString()+ ';' +printData['FBillNo']+ ';' +DateTime.now().millisecondsSinceEpoch.toString()+ ';' +barcodeNum.toString();
                println = 'SIZE 100.0 mm,73.0 mm\r\n' +
                    'GAP 2 mm\r\n' +
                    'CLS\r\n' +
                    'BOX 5, 5, 800, 550, 3\r\n' +
                    'BAR 140, 100, 460, 1\r\n' +
                    'BAR 140, 180, 460, 1\r\n' +
                    'BAR 140, 260, 460, 1\r\n' +
                    'BAR 220, 340, 380, 1\r\n' +
                    'BAR 190, 420, 410, 1\r\n' +
                    'BAR 140, 500, 460, 1\r\n' +
                    'TEXT 10,50,"TSS24.BF2",0,2,2,"品名:"\r\n' +
                    'TEXT 10,130,"TSS24.BF2",0,2,2,"批号:"\r\n' +
                    'TEXT 10,210,"TSS24.BF2",0,2,2,"净重:"\r\n' +
                    'TEXT 10,290,"TSS24.BF2",0,2,2,"入库日期:"\r\n' +
                    'TEXT 10,370,"TSS24.BF2",0,2,2,"有效期:"\r\n' +
                    'TEXT 10,450,"TSS24.BF2",0,2,2,"备注:"\r\n' +
                    'TEXT 150,50,"TSS24.BF2",0,2,2,"${value['FMaterialName']}"\r\n' +
                    'TEXT 150,130,"TSS24.BF2",0,2,2,"${value['FLot']['FNumber']}"\r\n' +
                    'TEXT 150,210,"TSS24.BF2",0,2,2,"${value['FAuxPropId']['FAUXPROPID__FF100002']['FNumber']}"\r\n' +
                    'TEXT 230,290,"TSS24.BF2",0,2,2,"${value['FProduceDate'].substring(0, 10)}"\r\n' +
                    'TEXT 200,370,"TSS24.BF2",0,2,2,"${value['FExpiryDate'].substring(0, 10)}"\r\n' +
                    'TEXT 150,450,"TSS24.BF2",0,2,2,"${value['FNote']}"\r\n' +
                    'QRCODE 610,180,M,8,A,0,"${codeCont}"\r\n' +
                    'PRINT 1,1\r\n';
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
                codeFEntityItem['FEntryStockID'] = {
                  "FNUMBER": value['FStockId']['FNumber']
                };
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
    }
    //println.codeUnits.toList();
    //return gbk.encode(println);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
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
                        onPressed: connected ? this.getGraphicsTicket : null,
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
