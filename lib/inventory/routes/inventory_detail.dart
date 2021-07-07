import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_deposit_request.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/inventory/widgets/inventory_deposit_request_item.dart';
import 'package:cwms_mobile/inventory/widgets/inventory_list_item.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';


class InventoryDetailPage extends StatefulWidget{

  InventoryDetailPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _InventoryDetailPageState();

}

class _InventoryDetailPageState extends State<InventoryDetailPage> {




  @override
  Widget build(BuildContext context) {

    List<Inventory> _inventories = ModalRoute.of(context).settings.arguments;
    printLongLogMessage(">>>> start to show inventory details with ${_inventories.length} records");

    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).inventory)),
      body:  _buildInventoryList(context, _inventories)
      //endDrawer: MyDrawer(),
      // endDrawer: MyDrawer(),
    );
  }



  Widget _buildInventoryList (BuildContext context, List<Inventory> _inventories){
    return
      ListView.separated(
            separatorBuilder: (context, index) => Divider(
              color: Colors.black,
            ),
            itemCount: _inventories.length,
            itemBuilder: (BuildContext context, int index) {

              // return Text( _inventories[index].lpn);

              return InventoryListItem(
                  index: index,
                  inventory: _inventories[index]
              );

            });
  }



}