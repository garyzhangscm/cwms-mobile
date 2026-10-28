import '../../shared/scanning/scan_result_feedback.dart';

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
  bool? _reverseInProgress;
  bool? get reverseInProgress => _reverseInProgress;
  set reverseInProgress(bool? value) { _reverseInProgress = value; _updateScanFeedback(); }
  bool? _reverseResult;
  bool? get reverseResult => _reverseResult;
  set reverseResult(bool? value) { _reverseResult = value; _updateScanFeedback(); }
  String? _result;
  String? get result => _result;
  set result(String? value) { _result = value; _updateScanFeedback(); }



  final _scanFeedback = ScanResultFeedback();
  bool get pendingConfirmation => _scanFeedback.pending;
  void _updateScanFeedback() => _scanFeedback.update(
      _reverseInProgress == true, _reverseResult == true, _result);
}