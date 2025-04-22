


import 'package:cwms_mobile/inventory/models/item_unit_of_measure.dart';

import 'inventory.dart';



class InventoryQuantityForDisplay{
  InventoryQuantityForDisplay(this.inventory, this.displayItemUnitOfMeasure, this.quantity) ;

  Inventory inventory;

  ItemUnitOfMeasure displayItemUnitOfMeasure;

  // quantity in the display UOM
  int quantity;




}