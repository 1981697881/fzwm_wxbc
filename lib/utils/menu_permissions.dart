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
import 'package:fzwm_wxbc/views/stock/other_Inventory_detail.dart';
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
    print(list);
    list.removeAt(0);
    list.removeAt(0);
    list.removeAt(0);
    list.removeAt(0);
    print(list.length);
    var menu = [];
    menu.add({
      "icon": Icons.loupe,
      "text": "生产入库",
      "parentId": 1,
      "color": Colors.pink.withOpacity(0.7),
      "router": WarehousingPage(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "生产投料确认",
      "parentId": 1,
      "color": Colors.pink.withOpacity(0.7),
      "router": PickingStockPage(),
      "source": '',
    });
    menu.add({
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
      "router": OtherInventoryDetail(),
      "source": '',
    });
    return menu;
  }
}
