// ignore_for_file: camel_case_types

import 'dart:io';

import 'package:sqflite/sqflite.dart';

final _version = 1; //数据库版本号
final _databaseName = "landy.db"; //数据库名称
final _tableName = "scheme_Inventory"; //表名称
final _tableId = "id"; //主键
final _tableFid = "fid"; //fid
final _tableSchemeName = "schemeName"; //盘点方案
final _tableSchemeNumber = "schemeNumber"; //盘点方案
final _tableOrganizationsName = "organizationsName"; //货主
final _tableOrganizationsNumber = "organizationsNumber"; //货主
final _tableStockIdName = "stockIdName"; //仓库
final _tableStockIdNumber = "stockIdNumber"; //仓库
final _tableMaterialName = "materialName";
final _tableMaterialNumber = "materialNumber";
final _tableSpecification = "specification";
final _tableUnitName = "unitName";
final _tableUnitNumber = "unitNumber";
final _tableRealQty = "realQty";
final _tableCountQty = "countQty";
final _tableStockName = "stockName";
final _tableStockNumber = "stockNumber";
final _tableLot = "lot";
final _tableStockOrgId = "stockOrgId";
final _tableOwnerId = "ownerId";
final _tableStockStatusId = "stockStatusId";
final _tableKeeperTypeId = "keeperTypeId";
final _tableKeeperId = "keeperId";
final _tableEntryID = "entryID";
final _tableBarcode = "barcode";

class SqfLiteQueueDataScheme {
  SqfLiteQueueDataScheme.internal();

  //数据库句柄
  late Database _database;

  /// 添加数据
  static Future insertData(
      int fid,
      String schemeName,
      String schemeNumber,
      String organizationsName,
      String organizationsNumber,
      String stockIdName,
      String stockIdNumber,
      String materialName,
      String materialNumber,
      String specification,
      String unitName,
      String unitNumber,
      double realQty,
      String countQty,
      String stockName,
      String stockNumber,
      String lot,
      String stockOrgId,
      String ownerId,
      String stockStatusId,
      String keeperTypeId,
      String keeperId,
      int entryID,
      String barcode) async {
    Database db = await SqfLiteQueueDataScheme.internal().open();
    //1、普通添加
    //await db.rawDelete("insert or replace into $_tableName ($_tableId,$_tableFid,$_tableRealQty) values (null,?,?)",[fid, realQty]);
    //2、事务添加
    db.transaction((txn) async {
      await txn.rawInsert(
          "insert or replace into $_tableName ($_tableId,$_tableFid,$_tableSchemeName,$_tableSchemeNumber,$_tableOrganizationsName,$_tableOrganizationsNumber,$_tableStockIdName,$_tableStockIdNumber,$_tableMaterialName,$_tableMaterialNumber,$_tableSpecification,$_tableUnitName,$_tableUnitNumber,$_tableRealQty,$_tableCountQty,$_tableStockName,$_tableStockNumber,$_tableLot,$_tableStockOrgId,$_tableOwnerId,$_tableStockStatusId,$_tableKeeperTypeId,$_tableKeeperId,$_tableEntryID,$_tableBarcode) values (null,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
          [
            fid,
            schemeName,
            schemeNumber,
            organizationsName,
            organizationsNumber,
            stockIdName,
            stockIdNumber,
            materialName,
            materialNumber,
            specification,
            unitName,
            unitNumber,
            realQty,
            countQty,
            stockName,
            stockNumber,
            lot,
            stockOrgId,
            ownerId,
            stockStatusId,
            keeperTypeId,
            keeperId,
            entryID,
            barcode
          ]);
    });
    await db.batch().commit();

    /*await SqfLiteQueueDataScheme.internal().close();*/
  }

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
        print("重新打开时调用");
        if (await isTableExitss(db,"scheme_Inventory") == false) {
          await _createTable(db,
              '''create table if not exists $_tableName ($_tableId integer primary key,$_tableFid INTEGER,$_tableSchemeName text,$_tableSchemeNumber text,$_tableOrganizationsName text,$_tableOrganizationsNumber text,$_tableStockIdName text,$_tableStockIdNumber text,$_tableMaterialName text,$_tableMaterialNumber text,$_tableSpecification text,$_tableUnitName text,$_tableUnitNumber text,$_tableRealQty REAL,$_tableCountQty text,$_tableStockName text,$_tableStockNumber text,$_tableLot text,$_tableStockOrgId text,$_tableOwnerId text,$_tableStockStatusId text,$_tableKeeperTypeId text,$_tableKeeperId text,$_tableEntryID INTEGER,$_tableBarcode text)''');
        }
        if (await isTableExitss(db,"offline_Inventory") == false) {
          await _createTable(db,
              '''create table if not exists offline_Inventory ($_tableId integer primary key,$_tableFid INTEGER,$_tableSchemeName text,$_tableSchemeNumber text,$_tableOrganizationsName text,$_tableOrganizationsNumber text,$_tableStockIdName text,$_tableStockIdNumber text,$_tableMaterialName text,$_tableMaterialNumber text,$_tableSpecification text,$_tableUnitName text,$_tableUnitNumber text,$_tableRealQty REAL,$_tableCountQty text,$_tableStockName text,$_tableStockNumber text,$_tableLot text,$_tableStockOrgId text,$_tableOwnerId text,$_tableStockStatusId text,$_tableKeeperTypeId text,$_tableKeeperId text,$_tableEntryID INTEGER,$_tableBarcode text)''');
        }
        if (await isTableExitss(db,"offline_Inventory_cache") == false) {
          await _createTable(db,
              '''create table if not exists offline_Inventory_cache ($_tableId integer primary key,$_tableFid INTEGER,$_tableSchemeName text,$_tableSchemeNumber text,$_tableOrganizationsName text,$_tableOrganizationsNumber text,$_tableStockIdName text,$_tableStockIdNumber text,$_tableMaterialName text,$_tableMaterialNumber text,$_tableSpecification text,$_tableUnitName text,$_tableUnitNumber text,$_tableRealQty REAL,$_tableCountQty text,$_tableStockName text,$_tableStockNumber text,$_tableLot text,$_tableStockOrgId text,$_tableOwnerId text,$_tableStockStatusId text,$_tableKeeperTypeId text,$_tableKeeperId text,$_tableEntryID INTEGER,$_tableBarcode text)''');
        }
        if (await isTableExitss(db,"barcode_list") == false) {
          await _createTable(db,
              '''create table if not exists barcode_list (id integer primary key,fid INTEGER,fBillNo text,fCreateOrgId INTEGER,fBarCode text,fOwnerID INTEGER,materialName INTEGER,materialNumber text,fStockOrgID INTEGER,specification text,fStockID INTEGER,fInQtyTotal REAL,fOutQtyTotal REAL,fRemainQty REAL,fMUnitName text,fOrder text,fBatchNo text,fProduceDate text,fLastCheckTime text)''');
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
  /// 创建表
  Future<void> _createTable(Database db, String sql) async {
    var batch = db.batch();
    batch.execute(sql);
    await batch.commit();
  }
  //判断表是否存在
  static Future isTableExits(String tableName) async {
    Database db = await SqfLiteQueueDataScheme.internal().open();
    //内建表sqlite_master
    var sql =
        "SELECT * FROM sqlite_master WHERE TYPE = 'table' AND NAME = '$tableName'";
    var res = await db.rawQuery(sql);
    var returnRes = res != null && res.length > 0;
    return returnRes;
  }

  /// 根据方案id删除该条记录
  static Future deleteData(String schemeNumber) async {
    Database db = await SqfLiteQueueDataScheme.internal().open();
    //1、普通删除
    //await db.rawDelete("delete from _tableName where _tableId = ?",[id]);
    //2、事务删除
    db.transaction((txn) async {
      txn.rawDelete("delete from $_tableName where $_tableSchemeNumber = ?",
          [schemeNumber]);
    });
    await db.batch().commit();
    /*await SqfLiteQueueDataScheme.internal().close();*/
  }

  /// 根据id更新该条记录
  static Future updateData(
      int id,
      int fid,
      String schemeName,
      String schemeNumber,
      String organizationsName,
      String organizationsNumber,
      String stockIdName,
      String stockIdNumber,
      String materialName,
      String materialNumber,
      String specification,
      String unitName,
      String unitNumber,
      double realQty,
      String countQty,
      String stockName,
      String stockNumber,
      String lot,
      String stockOrgId,
      String ownerId,
      String stockStatusId,
      String keeperTypeId,
      String keeperId,
      int entryID,
      String barcode) async {
    Database db = await SqfLiteQueueDataScheme.internal().open();
    //1、普通更新
    // await db.rawUpdate("update $_tableName set $_tableFid =  ?,$_tableRealQty =  ? where $_tableId = ?",[fid,realQty,id]);
    //2、事务更新 scheme,materialName,materialNumber,specification,unitName,unitNumber,realQty,countQty,stockName,stockNumber,ownerId,stockStatusId,keeperTypeId,keeperId,entryID
    //_tableScheme _tableMaterialName _tableMaterialNumber _tableSpecification _tableUnitName _tableUnitNumber _tableRealQty _tableCountQty _tableStockName _tableStockNumber _tableOwnerId _tableStockStatusId _tableKeeperTypeId _tableKeeperId _tableEntryID
    db.transaction((txn) async {
      txn.rawUpdate(
          "update $_tableName set $_tableFid =  ?,$_tableSchemeName =  ?,$_tableSchemeNumber =  ?,$_tableOrganizationsName =  ?,$_tableOrganizationsNumber =  ?,$_tableStockIdName =  ?,$_tableStockIdNumber =  ?,$_tableMaterialName =  ?,$_tableMaterialNumber =  ?,$_tableSpecification =  ?,$_tableUnitName =  ?,$_tableUnitNumber =  ?,$_tableRealQty =  ?,$_tableCountQty =  ?,$_tableStockName =  ?,$_tableStockNumber =  ?,$_tableLot =  ?,$_tableStockOrgId =  ?,$_tableOwnerId =  ?,$_tableStockStatusId =  ?,$_tableKeeperTypeId =  ?,$_tableKeeperId =  ?,$_tableEntryID =  ?,$_tableBarcode =  ? where $_tableId = ?",
          [
            fid,
            schemeName,
            schemeNumber,
            organizationsName,
            organizationsNumber,
            stockIdName,
            stockIdNumber,
            materialName,
            materialNumber,
            specification,
            unitName,
            unitNumber,
            realQty,
            countQty,
            stockName,
            stockNumber,
            lot,
            stockOrgId,
            ownerId,
            stockStatusId,
            keeperTypeId,
            keeperId,
            entryID,
            barcode,
            id
          ]);
    });
    await db.batch().commit();

    await SqfLiteQueueDataScheme.internal().close();
  }

  /// 查询所有数据
  static Future<List<Map<String, dynamic>>> searchDates(select) async {
    Database db = await SqfLiteQueueDataScheme.internal().open();
    List<Map<String, dynamic>> maps = await db.rawQuery(select);
    /*await SqfLiteQueueDataScheme.internal().close();*/
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
    Database db = await SqfLiteQueueDataScheme.internal().open();
    //1、普通删除
    //await db.rawDelete("drop table $_tableName");
    //2、事务删除
    db.transaction((txn) async {
      txn.rawDelete("drop table $_tableName");
    });
    await db.batch().commit();
     await SqfLiteQueueDataScheme.internal().close();
  }

  ///删除数据库文件
  static Future<void> deleteDataBaseFile() async {
    await SqfLiteQueueDataScheme.internal().close();
    String path = await getDatabasesPath() + "/$_databaseName";
    File file = new File(path);
    if (await file.exists()) {
      file.delete();
    }
  }
}
