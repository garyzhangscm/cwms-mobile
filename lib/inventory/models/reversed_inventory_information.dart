
class ReversedInventoryInformation{
  ReversedInventoryInformation(
      this.lpn, this.clientName, this.itemName,
      this.itemPackageTypeName, this.quantity,
      this.locationName, this.workOrderNumber, this.receiptNumber) {
    this.reverseInProgress = false;
    this.reverseResult = false;
    this.result = "";
  }

  ReversedInventoryInformation.fromProducedInventory(
      this.lpn, this.clientName, this.itemName,
      this.itemPackageTypeName, this.quantity,
      this.locationName, this.workOrderNumber) {
    this.reverseInProgress = false;
    this.reverseResult = false;
    this.result = "";
  }

  ReversedInventoryInformation.fromReceivedInventory(
      this.lpn, this.clientName, this.itemName,
      this.itemPackageTypeName, this.quantity,
      this.locationName, this.receiptNumber) {
    this.reverseInProgress = false;
    this.reverseResult = false;
    this.result = "";
  }

  String? lpn;
  String? clientName;
  String? itemName;
  String? itemPackageTypeName;
  int? quantity;
  String? locationName;
  String? workOrderNumber;
  String? receiptNumber;
  bool? reverseInProgress;
  bool? reverseResult;
  String? result;



}