enum ReceiptStatus {
  OPEN,
  CHECK_IN,
  RECEIVING,
  CLOSED
}

ReceiptStatus receiptStatusFromString(String value){
  return ReceiptStatus.values.firstWhere((e)=>
      e.toString().split('.')[1].toUpperCase()==value.toUpperCase());
}