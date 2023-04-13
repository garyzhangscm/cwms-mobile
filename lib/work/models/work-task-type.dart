enum WorkTaskType {
  INVENTORY_MOVEMENT,
  INVENTORY_MOVEMENT_CROSS_WAREHOUSE_OUT,
  INVENTORY_MOVEMENT_CROSS_WAREHOUSE_IN,
  PICK,
  PUT_AWAY,
  BULK_PICK,
  LIST_PICK
}

WorkTaskType workTaskTypeFromString(String value){
  return WorkTaskType.values.firstWhere((e)=>
      e.toString().split('.')[1].toUpperCase()==value.toUpperCase());
}

extension ParseToString on WorkTaskType {
  String toShortString() {
    return this.toString().split('.').last;
  }
}