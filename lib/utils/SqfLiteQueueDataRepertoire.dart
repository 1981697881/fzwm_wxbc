// ignore_for_file: camel_case_types

import 'dart:io';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fzwm_wxbc/utils/toast_util.dart';
import 'package:sqflite/sqflite.dart';

final _version = 1; //数据库版本号
final _databaseName = "landy.db"; //数据库名称
final _tableName = "barcode_list"; //表名称
final _tableId = "id"; //主键
final _tableFid = "fid"; //fid
final _tableFBillNo = "fBillNo"; //单据编号
final _tableFCreateOrgId = "fCreateOrgId"; //创建组织
final _tableFBarCode = "fBarCode"; //条码
final _tableFOwnerID = "fOwnerID"; //货主
final _tableFMATERIALID = "materialName"; //物料名称
final _tableFQDEPMName = "materialNumber"; //物料编码
final _tableFStockOrgID = "fStockOrgID"; //库存组织
final _tableFQDEPMSpec = "specification"; //规格型号
final _tableFStockID = "fStockID"; //仓库
final _tableFInQtyTotal = "fInQtyTotal"; //入库数量汇总
final _tableFOutQtyTotal = "fOutQtyTotal"; //出库数量汇总
final _tableFRemainQty = "fRemainQty"; //剩余数量
final _tableFMUnitName = "fMUnitName"; //单位
final _tableFOrder = "fOrder"; //流水号
final _tableFBatchNo = "fBatchNo"; //批号
final _tableFProduceDate = "fProduceDate"; //生产日期
final _tableFLastCheckTime = "fLastCheckTime"; //最后盘点日期

class SqfLiteQueueDataRepertoire {
  SqfLiteQueueDataRepertoire.internal();

  //数据库句柄
  late Database _database;

  Future<Database> get database async {
    String path = await getDatabasesPath() + "/$_databaseName";
    _database = await openDatabase(
      path,
      version: _version,
      onConfigure: (Database db) {
        print("数据库创建前、降级前、升级前调用");
      },
      onDowngrade: (Database db, int version, int x) {
        print("降级时调用");
      },
      onUpgrade: (Database db, int version, int x) {
        print("升级时调用");
      },
      onCreate: (Database db, int version) async {
        print("创建时调用");
      },
      onOpen: (Database db) async {
        if (await isTableExitss(db,"barcode_list") == false) {
          await _createTable(db,
              '''create table if not exists $_tableName ($_tableId integer primary key,$_tableFid INTEGER,$_tableFBillNo text,$_tableFCreateOrgId INTEGER,$_tableFBarCode text,$_tableFOwnerID INTEGER,$_tableFMATERIALID INTEGER,$_tableFQDEPMName text,$_tableFStockOrgID INTEGER,$_tableFQDEPMSpec text,$_tableFStockID text,$_tableFInQtyTotal REAL,$_tableFOutQtyTotal REAL,$_tableFRemainQty REAL,$_tableFMUnitName text,$_tableFOrder text,$_tableFBatchNo text,$_tableFProduceDate text,$_tableFLastCheckTime text)''');
        }
      },
    );
    return _database;
  }
//判断表是否存在
  isTableExitss(Database db,String tableName) async {
    //内建表sqlite_master
    var sql ="SELECT * FROM sqlite_master WHERE TYPE = 'table' AND NAME = '$tableName'";
    var res = await db.rawQuery(sql);
    var returnRes = res!=null && res.length > 0;
    return returnRes;
  }
  /// 添加数据
  static Future insertData(
      int fid,
      String fBillNo,
      int fCreateOrgId,
      String fBarCode,
      int fOwnerID,
      int materialName,
      String materialNumber,
      int fStockOrgID,
      String specification,
      String fStockID,
      double fInQtyTotal,
      double fOutQtyTotal,
      double fRemainQty,
      String fMUnitName,
      String fOrder,
      String fBatchNo,
      String fProduceDate,
      String fLastCheckTime,int length,int index) async {
    Database db = await SqfLiteQueueDataRepertoire.internal().open();
    //1、普通添加
    //await db.rawDelete("insert or replace into $_tableName ($_tableId,$_tableFid,$_tableRealQty) values (null,?,?)",[fid, realQty]);
    //2、事务添加
    db.transaction((txn) async {
      await txn.rawInsert(
          "insert or replace into $_tableName ($_tableId,$_tableFid,$_tableFBillNo,$_tableFCreateOrgId,$_tableFBarCode,$_tableFOwnerID,$_tableFMATERIALID,$_tableFQDEPMName,$_tableFStockOrgID,$_tableFQDEPMSpec,$_tableFStockID,$_tableFInQtyTotal,$_tableFOutQtyTotal,$_tableFRemainQty,$_tableFMUnitName,$_tableFOrder,$_tableFBatchNo,$_tableFProduceDate,$_tableFLastCheckTime) values (null,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
          [
            fid,
            fBillNo,
            fCreateOrgId,
            fBarCode,
            fOwnerID,
            materialName,
            materialNumber,
            fStockOrgID,
            specification,
            fStockID,
            fInQtyTotal,
            fOutQtyTotal,
            fRemainQty,
            fMUnitName,
            fOrder,
            fBatchNo,
            fProduceDate,
            fLastCheckTime,
          ]);
    });
    await db.batch().commit();
    if(index == length){
      ToastUtil.showInfo('下载完成');
      EasyLoading.dismiss();
      await SqfLiteQueueDataRepertoire.internal().close();
    }

  }

//判断表是否存在
  static Future isTableExits(String tableName) async {
    Database db = await SqfLiteQueueDataRepertoire.internal().open();
    //内建表sqlite_master
    var sql =
        "SELECT * FROM sqlite_master WHERE TYPE = 'table' AND NAME = '$tableName'";
    var res = await db.rawQuery(sql);
    var returnRes = res != null && res.length > 0;
    return returnRes;
  }

  /// 创建表
  Future<void> _createTable(Database db, String sql) async {
    var batch = db.batch();
    batch.execute(sql);
    await batch.commit();
  }

  /// 根据方案id删除该条记录
  static Future deleteData(String fid) async {
    Database db = await SqfLiteQueueDataRepertoire.internal().open();
    //1、普通删除
    //await db.rawDelete("delete from _tableName where _tableId = ?",[id]);
    //2、事务删除
    db.transaction((txn) async {
      txn.rawDelete("delete from $_tableName where $_tableFid = ?", [fid]);
    });
    await db.batch().commit();
    /*await SqfLiteQueueDataRepertoire.internal().close();*/
  }

  /// 清空数据表
  static Future deleteTableData() async {
    Database db = await SqfLiteQueueDataRepertoire.internal().open();
    //1、普通删除
    //await db.rawDelete("delete from _tableName where _tableId = ?",[id]);
    //2、事务删除truncate table
    db.transaction((txn) async {
      txn.rawDelete("delete from $_tableName");
    });
    await db.batch().commit();
    /*await SqfLiteQueueDataRepertoire.internal().close();*/
  }

  /// 根据id更新该条记录
  static Future updateData(
      int id,
      int fid,
      String fBillNo,
      int fCreateOrgId,
      String fBarCode,
      int fOwnerID,
      int materialName,
      String materialNumber,
      int fStockOrgID,
      String specification,
      String fStockID,
      double fInQtyTotal,
      double fOutQtyTotal,
      double fRemainQty,
      String fMUnitName,
      String fOrder,
      String fBatchNo,
      String fProduceDate,
      String fLastCheckTime) async {
    Database db = await SqfLiteQueueDataRepertoire.internal().open();
    //2、事务更新
    db.transaction((txn) async {
      txn.rawUpdate(
          "update $_tableName set $_tableFid =  ?,$_tableFBillNo =  ?,$_tableFCreateOrgId =  ?,$_tableFBarCode =  ?,$_tableFOwnerID =  ?,$_tableFMATERIALID =  ?,$_tableFQDEPMName =  ?,$_tableFStockOrgID =  ?,$_tableFQDEPMSpec =  ?,$_tableFStockID =  ?,$_tableFInQtyTotal =  ?,$_tableFOutQtyTotal =  ?,$_tableFRemainQty =  ?,$_tableFMUnitName =  ?,$_tableFOrder =  ?,$_tableFBatchNo =  ?,$_tableFProduceDate =  ?,$_tableFLastCheckTime =  ? where $_tableId = ?",
          [
            fid,
            fBillNo,
            fCreateOrgId,
            fBarCode,
            fOwnerID,
            materialName,
            materialNumber,
            fStockOrgID,
            specification,
            fStockID,
            fInQtyTotal,
            fOutQtyTotal,
            fRemainQty,
            fMUnitName,
            fOrder,
            fBatchNo,
            fProduceDate,
            fLastCheckTime,
            id
          ]);
    });
    await db.batch().commit();
    await SqfLiteQueueDataRepertoire.internal().close();
  }

  /// 查询所有数据
  static Future<List<Map<String, dynamic>>> searchDates(select) async {
    Database db = await SqfLiteQueueDataRepertoire.internal().open();
    List<Map<String, dynamic>> maps = await db.rawQuery(select);
    await SqfLiteQueueDataRepertoire.internal().close();
    return maps;
  }

  //打开
  Future<Database> open() async {
    return await database;
  }

  ///关闭
  Future<void> close() async {
    var db = await database;
    return db.close();
  }

  ///删除数据库表
  static Future<void> deleteDataTable() async {
    Database db = await SqfLiteQueueDataRepertoire.internal().open();
    //1、普通删除
    //await db.rawDelete("drop table $_tableName");
    //2、事务删除
    db.transaction((txn) async {
      txn.rawDelete("drop table $_tableName");
    });
    await db.batch().commit();
    await SqfLiteQueueDataRepertoire.internal().close();
  }

  ///删除数据库文件
  static Future<void> deleteDataBaseFile() async {
    await SqfLiteQueueDataRepertoire.internal().close();
    String path = await getDatabasesPath() + "/$_databaseName";
    File file = new File(path);
    if (await file.exists()) {
      file.delete();
    }
  }
}
