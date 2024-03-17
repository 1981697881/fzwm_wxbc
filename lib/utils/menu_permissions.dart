import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fzwm_wxbc/views/production/bind_SN_page.dart';
import 'package:fzwm_wxbc/views/production/picking_detail.dart';
import 'package:fzwm_wxbc/views/production/picking_out_sourcing_page.dart';
import 'package:fzwm_wxbc/views/production/picking_page.dart';
import 'package:fzwm_wxbc/views/production/picking_stock_page.dart';
import 'package:fzwm_wxbc/views/production/return_detail.dart';
import 'package:fzwm_wxbc/views/production/return_page.dart';
import 'package:fzwm_wxbc/views/production/simple_picking_detail.dart';
import 'package:fzwm_wxbc/views/production/simple_warehousing_detail.dart';
import 'package:fzwm_wxbc/views/production/warehousing_detail.dart';
import 'package:fzwm_wxbc/views/production/warehousing_page.dart';
import 'package:fzwm_wxbc/views/purchase/purchase_out_sourcing_page.dart';
import 'package:fzwm_wxbc/views/purchase/purchase_return_detail.dart';
import 'package:fzwm_wxbc/views/purchase/purchase_return_page.dart';
import 'package:fzwm_wxbc/views/purchase/purchase_warehousing_detail.dart';
import 'package:fzwm_wxbc/views/purchase/purchase_warehousing_page.dart';
import 'package:fzwm_wxbc/views/sale/retrieval_detail.dart';
import 'package:fzwm_wxbc/views/sale/retrieval_page.dart';
import 'package:fzwm_wxbc/views/sale/return_goods_detail.dart';
import 'package:fzwm_wxbc/views/sale/return_goods_page.dart';
import 'package:fzwm_wxbc/views/stock/Inventory_detail.dart';
import 'package:fzwm_wxbc/views/stock/Inventory_page.dart';
import 'package:fzwm_wxbc/views/stock/allocation_detail.dart';
import 'package:fzwm_wxbc/views/stock/allocation_page.dart';
import 'package:fzwm_wxbc/views/stock/ex_warehouse_detail.dart';
import 'package:fzwm_wxbc/views/stock/ex_warehouse_page.dart';
import 'package:fzwm_wxbc/views/stock/grounding_page.dart';
import 'package:fzwm_wxbc/views/stock/other_warehousing_detail.dart';
import 'package:fzwm_wxbc/views/stock/other_warehousing_page.dart';
import 'package:fzwm_wxbc/views/stock/scheme_Inventory_detail.dart';
import 'package:fzwm_wxbc/views/stock/stock_page.dart';
import 'package:fzwm_wxbc/views/stock/undercarriage_page.dart';
import 'package:fzwm_wxbc/views/workshop/dispatch_detail.dart';
import 'package:fzwm_wxbc/views/workshop/dispatch_page.dart';
import 'package:fzwm_wxbc/views/workshop/report_detail.dart';
import 'package:fzwm_wxbc/views/workshop/report_page.dart';

class MenuPermissions {
  static void getMenu() async {}

  static getMenuChild(item) {
    var list = jsonDecode(item)[0];
    /*[
      "201801004",
      "手机事业部",
      "A",
      true,
      "SCDD",
      false,
      "",
      true,
      "FHTZD",
      true,
      "THTZD",
      true,
      "SLTZD",
      true,
      "DTPD",
      true,
      "",
      true,
      "",
      false,
      "",
      false,
      "",
      false,
      false,
      false
    ];*/
    print(list);
    list.removeAt(0);
    list.removeAt(0);
    list.removeAt(0);
    list.removeAt(0);
    print(list.length);
    var menu = [];
    /*for (var i = 0; i < list.length; i++) {
      switch (i) {
        case 0:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "生产入库",
              "parentId": 1,
              "color": Colors.pink.withOpacity(0.7),
              "router": list[i + 1].length > 1
                  ? WarehousingPage()
                  : WarehousingDetail(FBillNo: null),
              "source": list[i + 1],
            };
            menu.add(obj);
          }
          break;
        case 2:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "生产领料",
              "parentId": 1,
              "color": Colors.pink.withOpacity(0.7),
              "router": list[i + 1].length > 1
                  ? PickingPage()
                  : PickingDetail(FBillNo: null),
              "source": list[i + 1],
            };
            menu.add(obj);
          }
          break;
        case 4:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "销售出库",
              "parentId": 2,
              "color": Colors.pink.withOpacity(0.7),
              "router": list[i + 1].length > 1
                  ? RetrievalPage()
                  : RetrievalDetail(FBillNo: null),
              "source": list[i + 1],
            };
            menu.add(obj);
          }
          break;
        case 6:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "销售退货",
              "parentId": 2,
              "color": Colors.pink.withOpacity(0.7),
              "router": list[i + 1].length > 1
                  ? ReturnGoodsPage()
                  : ReturnGoodsDetail(FBillNo: null),
              "source": list[i + 1],
            };
            menu.add(obj);
          }
          break;
        case 8:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "采购入库",
              "parentId": 5,
              "color": Colors.pink.withOpacity(0.7),
              "router": list[i + 1].length > 1
                  ? PurchaseWarehousingPage()
                  : PurchaseWarehousingDetail(FBillNo: null),
              "source": list[i + 1],
            };
            menu.add(obj);
          }
          break;
        case 10:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "动态盘点",
              "parentId": 3,
              "color": Colors.pink.withOpacity(0.7),
              "router": list[i + 1].length > 1
                  ? InventoryPage()
                  : InventoryDetail(FBillNo: null),
              "source": list[i + 1],
            };
            menu.add(obj);
          }
          break;
        case 12:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "其他入库",
              "parentId": 3,
              "color": Colors.pink.withOpacity(0.7),
              "router": list[i + 1].length > 1
                  ? OtherWarehousingPage()
                  : OtherWarehousingDetail(FBillNo: null),
              "source": list[i + 1],
            };
            menu.add(obj);
          }
          break;
        case 14:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "其他出库",
              "parentId": 3,
              "color": Colors.pink.withOpacity(0.7),
              "router": list[i + 1].length > 1
                  ? ExWarehousePage()
                  : ExWarehouseDetail(FBillNo: null),
              "source": list[i + 1],
            };
            menu.add(obj);
          }
          break;
        case 16:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "工序派工",
              "parentId": 4,
              "color": Colors.pink.withOpacity(0.7),
              "router": list[i + 1].length > 1
                  ? DispatchPage()
                  : DispatchDetail(FBillNo: null),
              "source": list[i + 1],
            };
            menu.add(obj);
          }
          break;
        case 18:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "工序汇报",
              "parentId": 4,
              "color": Colors.pink.withOpacity(0.7),
              "router": list[i + 1].length > 1
                  ? ReportPage()
                  : ReportDetail(FBillNo: null),
              "source": list[i + 1],
            };
            menu.add(obj);
          }
          break;
        case 20:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "上架",
              "parentId": 3,
              "color": Colors.pink.withOpacity(0.7),
              "router": "",
              "source": GroundingPage(),
            };
            menu.add(obj);
          }
          break;
        case 21:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "下架",
              "parentId": 3,
              "color": Colors.pink.withOpacity(0.7),
              "router": UndercarriagePage(),
              "source": '',
            };
            menu.add(obj);
          }
          break;
        case 22:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "库存查询",
              "parentId": 3,
              "color": Colors.pink.withOpacity(0.7),
              "router": StockPage(),
              "source": '',
            };
            menu.add(obj);
          }
          break;
      }
    }*/
    /*menu.add({
      "icon": Icons.loupe,
      "text": "SN绑定",
      "parentId": 1,
      "color": Colors.pink.withOpacity(0.7),
      "router": BindSNPage(),
      "source": '',
    });*/
    menu.add({
      "icon": Icons.loupe,
      "text": "生产入库",
      "parentId": 1,
      "color": Colors.pink.withOpacity(0.7),
      "router": WarehousingPage(),
      "source": '',
    }); menu.add({
      "icon": Icons.loupe,
      "text": "生产领料",
      "parentId": 1,
      "color": Colors.pink.withOpacity(0.7),
      "router": PickingPage(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "简单生产入库",
      "parentId": 1,
      "color": Colors.pink.withOpacity(0.7),
      "router": SimpleWarehousingDetail(),
      "source": '',
    }); menu.add({
      "icon": Icons.loupe,
      "text": "简单生产领料",
      "parentId": 1,
      "color": Colors.pink.withOpacity(0.7),
      "router": SimplePickingDetail(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "生产领料确认",
      "parentId": 1,
      "color": Colors.pink.withOpacity(0.7),
      "router": PickingStockPage(),
      "source": '',
    });menu.add({
      "icon": Icons.loupe,
      "text": "委外领料",
      "parentId": 6,
      "color": Colors.pink.withOpacity(0.7),
      "router": PickingOutSourcingPage(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "生产退料(有源单)",
      "parentId": 1,
      "color": Colors.pink.withOpacity(0.7),
      "router": ReturnPage(),
      "source": '',
    });menu.add({
      "icon": Icons.loupe,
      "text": "生产退料(无源单)",
      "parentId": 1,
      "color": Colors.pink.withOpacity(0.7),
      "router": ReturnDetail(),
      "source": '',
    });menu.add({
      "icon": Icons.loupe,
      "text": "销售出库",
      "parentId": 2,
      "color": Colors.pink.withOpacity(0.7),
      "router": RetrievalPage(),
      "source": '',
    }); menu.add({
      "icon": Icons.loupe,
      "text": "销售退货(有源单)",
      "parentId": 2,
      "color": Colors.pink.withOpacity(0.7),
      "router": ReturnGoodsPage(),
      "source": '',
    });menu.add({
      "icon": Icons.loupe,
      "text": "销售退货(无源单)",
      "parentId": 2,
      "color": Colors.pink.withOpacity(0.7),
      "router": ReturnGoodsDetail(),
      "source": '',
    }); menu.add({
      "icon": Icons.loupe,
      "text": "采购入库",
      "parentId": 5,
      "color": Colors.pink.withOpacity(0.7),
      "router": PurchaseWarehousingPage(),
      "source": '',
    });menu.add({
      "icon": Icons.loupe,
      "text": "委外入库",
      "parentId": 6,
      "color": Colors.pink.withOpacity(0.7),
      "router": PurchaseOutSourcingPage(),
      "source": '',
    });menu.add({
      "icon": Icons.loupe,
      "text": "采购退货(有源单)",
      "parentId": 5,
      "color": Colors.pink.withOpacity(0.7),
      "router": PurchaseReturnPage(),
      "source": '',
    });menu.add({
      "icon": Icons.loupe,
      "text": "采购退货(无源单)",
      "parentId": 5,
      "color": Colors.pink.withOpacity(0.7),
      "router": PurchaseReturnDetail(),
      "source": '',
    }); menu.add({
      "icon": Icons.loupe,
      "text": "其他入库",
      "parentId": 3,
      "color": Colors.pink.withOpacity(0.7),
      "router": OtherWarehousingDetail(),
      "source": '',
    }); menu.add({
      "icon": Icons.loupe,
      "text": "其他出库",
      "parentId": 3,
      "color": Colors.pink.withOpacity(0.7),
      "router": ExWarehouseDetail(),
      "source": '',
    }); menu.add({
      "icon": Icons.loupe,
      "text": "库存查询",
      "parentId": 3,
      "color": Colors.pink.withOpacity(0.7),
      "router": StockPage(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "移库",
      "parentId": 3,
      "color": Colors.pink.withOpacity(0.7),
      "router": AllocationDetail(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "方案盘点",
      "parentId": 3,
      "color": Colors.pink.withOpacity(0.7),
      "router": SchemeInventoryDetail(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "现场盘点",
      "parentId": 3,
      "color": Colors.pink.withOpacity(0.7),
      "router": InventoryPage(),
      "source": '',
    });
    /* menu.add({
      "icon": Icons.loupe,
      "text": "生产入库确认",
      "parentId": 1,
      "color": Colors.pink.withOpacity(0.7),
      "router": WarehousingAffirmPage(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "生产领料确认",
      "parentId": 1,
      "color": Colors.pink.withOpacity(0.7),
      "router": PickingStockPage(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "采购入库确认",
      "parentId": 5,
      "color": Colors.pink.withOpacity(0.7),
      "router": PurchaseAffirmPage(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "销售出库确认",
      "parentId": 2,
      "color": Colors.pink.withOpacity(0.7),
      "router": RetrievalAffirmPage(),
      "source": '',
    });menu.add({
      "icon": Icons.loupe,
      "text": "销售退货确认",
      "parentId": 2,
      "color": Colors.pink.withOpacity(0.7),
      "router": SalesReturnAffirmPage(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "调拨确认",
      "parentId": 3,
      "color": Colors.pink.withOpacity(0.7),
      "router": AllocationAffirmPage(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "调拨",
      "parentId": 3,
      "color": Colors.pink.withOpacity(0.7),
      "router": AllocationPage(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "分步式调拨",
      "parentId": 3,
      "color": Colors.pink.withOpacity(0.7),
      "router": SubstepAllocationPage(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "其他盘点",
      "parentId": 3,
      "color": Colors.pink.withOpacity(0.7),
      "router": OtherInventoryDetail(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "方案盘点",
      "parentId": 3,
      "color": Colors.pink.withOpacity(0.7),
      "router": SchemeInventoryDetail(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "离线盘点",
      "parentId": 3,
      "color": Colors.pink.withOpacity(0.7),
      "router": OfflineInventoryDetail(),
      "source": '',
    }); menu.add({
      "icon": Icons.loupe,
      "text": "其他出库确认",
      "parentId": 3,
      "color": Colors.pink.withOpacity(0.7),
      "router": ExWarehouseAffirmPage(),
      "source": '',
    });menu.add({
      "icon": Icons.loupe,
      "text": "其他入库确认",
      "parentId": 3,
      "color": Colors.pink.withOpacity(0.7),
      "router": OtherWarehousingAffirmPage(),
      "source": '',
    });menu.add({
      "icon": Icons.loupe,
      "text": "分步调出单确认",
      "parentId": 3,
      "color": Colors.pink.withOpacity(0.7),
      "router": CallOutAffirmPage(),
      "source": '',
    });menu.add({
      "icon": Icons.loupe,
      "text": "分步调入单确认",
      "parentId": 3,
      "color": Colors.pink.withOpacity(0.7),
      "router": CallInAffirmPage(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "生产补料",
      "parentId": 1,
      "color": Colors.pink.withOpacity(0.7),
      "router": ReplenishmentPage(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "生产退料",
      "parentId": 1,
      "color": Colors.pink.withOpacity(0.7),
      "router": ReturnPage(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "生产补料确认",
      "parentId": 1,
      "color": Colors.pink.withOpacity(0.7),
      "router": ReplenishmentAffirmPage(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "生产退料确认",
      "parentId": 1,
      "color": Colors.pink.withOpacity(0.7),
      "router": ReturnAffirmPage(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "采购退料",
      "parentId": 5,
      "color": Colors.pink.withOpacity(0.7),
      "router": PurchaseReturnPage(),
      "source": '',
    });menu.add({
      "icon": Icons.loupe,
      "text": "采购退料确认",
      "parentId": 5,
      "color": Colors.pink.withOpacity(0.7),
      "router": PurchaseReturnAffirmPage(),
      "source": '',
    });*/
    return menu;
  }
}
