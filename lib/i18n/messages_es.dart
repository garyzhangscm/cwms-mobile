
import 'package:intl/message_lookup_by_library.dart';
import 'spanish_ui.dart';

final messages = SpanishMessageLookup();

class SpanishMessageLookup extends MessageLookupByLibrary {
  @override
  String get localeName => 'es';
  @override
  final Map<String, Function> messages = {

    "home": MessageLookupByLibrary.simpleMessage(spanishUi("Home")),
    "account": MessageLookupByLibrary.simpleMessage(spanishUi("Me")),
    "accountDisplay":
        MessageLookupByLibrary.simpleMessage(spanishUi("Account Display")),
    "login": MessageLookupByLibrary.simpleMessage(spanishUi("Login")),
    "personalInfo":
        MessageLookupByLibrary.simpleMessage(spanishUi("Personal Information")),
    "firstName": MessageLookupByLibrary.simpleMessage(spanishUi("First Name")),
    "lastName": MessageLookupByLibrary.simpleMessage(spanishUi("Last Name")),
    "firstNameRequired": MessageLookupByLibrary.simpleMessage(
        spanishUi("First Name is Required")),
    "lastNameRequired": MessageLookupByLibrary.simpleMessage(
        spanishUi("Last Name is Required")),
    "save": MessageLookupByLibrary.simpleMessage(spanishUi("Save")),
    "result": MessageLookupByLibrary.simpleMessage(spanishUi("result")),
    "dataSaved": MessageLookupByLibrary.simpleMessage(spanishUi("Data Saved")),
    "notification":
        MessageLookupByLibrary.simpleMessage(spanishUi("Notification")),
    "notificationHistory":
        MessageLookupByLibrary.simpleMessage(spanishUi("Notification History")),
    "password": MessageLookupByLibrary.simpleMessage(spanishUi("Password")),
    "nextStep": MessageLookupByLibrary.simpleMessage(spanishUi("Next Step")),
    "pickByOrder":
        MessageLookupByLibrary.simpleMessage(spanishUi("Pick By Order")),
    "pickByWorkOrder":
        MessageLookupByLibrary.simpleMessage(spanishUi("Pick By Work Order")),
    "orderNumber":
        MessageLookupByLibrary.simpleMessage(spanishUi("Order Number")),
    "inputOrderNumberHint": MessageLookupByLibrary.simpleMessage(
        spanishUi("Please input an order number")),
    "workOrderNumber":
        MessageLookupByLibrary.simpleMessage(spanishUi("Work Order Number")),
    "inputWorkOrderNumberHint": MessageLookupByLibrary.simpleMessage(
        spanishUi("Please input an work order number")),
    "addOrder": MessageLookupByLibrary.simpleMessage(spanishUi("Add Order")),
    "chooseOrder":
        MessageLookupByLibrary.simpleMessage(spanishUi("Choose Order")),
    "addWorkOrder": MessageLookupByLibrary.simpleMessage(spanishUi("Add WO")),
    "chooseWorkOrder":
        MessageLookupByLibrary.simpleMessage(spanishUi("Choose WO")),
    "start": MessageLookupByLibrary.simpleMessage(spanishUi("Start")),
    "confirm": MessageLookupByLibrary.simpleMessage(spanishUi("Confirm")),
    "lpn": MessageLookupByLibrary.simpleMessage(spanishUi("LPN")),
    "inputLPNHint":
        MessageLookupByLibrary.simpleMessage(spanishUi("Please input an LPN")),
    "chooseLPN":
        MessageLookupByLibrary.simpleMessage(spanishUi("Please choose an LPN")),
    "location": MessageLookupByLibrary.simpleMessage(spanishUi("location")),
    "inputLocationHint": MessageLookupByLibrary.simpleMessage(
        spanishUi("Please input a Location")),
    "depositInventory":
        MessageLookupByLibrary.simpleMessage(spanishUi("Deposit")),
    "chooseReceipt":
        MessageLookupByLibrary.simpleMessage(spanishUi("Choose Receipt")),
    "chooseItem":
        MessageLookupByLibrary.simpleMessage(spanishUi("Choose Item")),
    "addCountBatch":
        MessageLookupByLibrary.simpleMessage(spanishUi("Add Batch")),
    "chooseCountBatch":
        MessageLookupByLibrary.simpleMessage(spanishUi("Choose Batch")),
    "noMoreCycleCountInBatch": MessageLookupByLibrary.simpleMessage(
        spanishUi("No More Cycle Count in this Batch")),
    "noMoreAuditCountInBatch": MessageLookupByLibrary.simpleMessage(
        spanishUi("No More Audit Count in this Batch")),
    "confirmCycleCount":
        MessageLookupByLibrary.simpleMessage(spanishUi("Confirm")),
    "skipCycleCount": MessageLookupByLibrary.simpleMessage(spanishUi("Skip")),
    "cancelCycleCount":
        MessageLookupByLibrary.simpleMessage(spanishUi("Cancel")),
    "confirmAuditCount":
        MessageLookupByLibrary.simpleMessage(spanishUi("Confirm")),
    "skipAuditCount": MessageLookupByLibrary.simpleMessage(spanishUi("Skip")),
    "cancelAuditCount":
        MessageLookupByLibrary.simpleMessage(spanishUi("Cancel")),
    "addItem": MessageLookupByLibrary.simpleMessage(spanishUi("Add Item")),
    "item": MessageLookupByLibrary.simpleMessage(spanishUi("Item")),
    "itemPackageType":
        MessageLookupByLibrary.simpleMessage(spanishUi("Item Package Type")),
    "inventoryStatus":
        MessageLookupByLibrary.simpleMessage(spanishUi("Inventory Status")),
    "expectedQuantity":
        MessageLookupByLibrary.simpleMessage(spanishUi("Expected Quantity")),
    "receivedQuantity":
        MessageLookupByLibrary.simpleMessage(spanishUi("Received Quantity")),
    "countQuantity":
        MessageLookupByLibrary.simpleMessage(spanishUi("Count Quantity")),
    "quantity": MessageLookupByLibrary.simpleMessage(spanishUi("Quantity")),
    "cycleCount":
        MessageLookupByLibrary.simpleMessage(spanishUi("Cycle Count")),
    "auditCount":
        MessageLookupByLibrary.simpleMessage(spanishUi("Audit Count")),
    "workProfile":
        MessageLookupByLibrary.simpleMessage(spanishUi("Work Profile")),
    "currentLocation":
        MessageLookupByLibrary.simpleMessage(spanishUi("Current Location")),
    "menuMobileInbound":
        MessageLookupByLibrary.simpleMessage(spanishUi("Inbound")),
    "menuMobileOutbound":
        MessageLookupByLibrary.simpleMessage(spanishUi("Outbound")),
    "menuMobileInventory":
        MessageLookupByLibrary.simpleMessage(spanishUi("Inventory")),
    "menuMobileWorkOrder":
        MessageLookupByLibrary.simpleMessage(spanishUi("Work Order")),
    "menuMobileInboundReceive":
        MessageLookupByLibrary.simpleMessage(spanishUi("Receive")),
    "menuMobileOutboundPickByOrder":
        MessageLookupByLibrary.simpleMessage(spanishUi("Pick By Order")),
    "menuMobileOutboundPickByList":
        MessageLookupByLibrary.simpleMessage(spanishUi("Pick By List")),
    "menuMobileOutboundPickByWorkOrder":
        MessageLookupByLibrary.simpleMessage(spanishUi("Pick By WO")),
    "menuMobileOutboundPickByTote":
        MessageLookupByLibrary.simpleMessage(spanishUi("Pick By Tote")),
    "menuMobileInventoryInventory":
        MessageLookupByLibrary.simpleMessage(spanishUi("Inventory")),
    "menuMobileInventoryCount":
        MessageLookupByLibrary.simpleMessage(spanishUi("Cycle Count")),
    "menuMobileInventoryAuditCount":
        MessageLookupByLibrary.simpleMessage(spanishUi("Audit Count")),
    "menuMobileWorkOrderProduce":
        MessageLookupByLibrary.simpleMessage(spanishUi("Produce")),
    "chooseServer":
        MessageLookupByLibrary.simpleMessage(spanishUi("Choose Server")),
    "query": MessageLookupByLibrary.simpleMessage(spanishUi("Query")),
    "inputItemHint": MessageLookupByLibrary.simpleMessage(
        spanishUi("Please input an Item or Barcode")),
    "noInventoryFound": MessageLookupByLibrary.simpleMessage(
        spanishUi("Cannot find any inventory")),
    "inventory": MessageLookupByLibrary.simpleMessage(spanishUi("Inventory")),
    "highPriority":
        MessageLookupByLibrary.simpleMessage(spanishUi("High Priority")),
    "share": MessageLookupByLibrary.simpleMessage(spanishUi("Share")),
    "remove": MessageLookupByLibrary.simpleMessage(spanishUi("Remove")),
    "receiving": MessageLookupByLibrary.simpleMessage(spanishUi("Receiving")),
    "receiptNumber":
        MessageLookupByLibrary.simpleMessage(spanishUi("Receipt Number")),
    "receivingQuantity":
        MessageLookupByLibrary.simpleMessage(spanishUi("Receiving Quantity")),
    "add": MessageLookupByLibrary.simpleMessage(spanishUi("Add")),
    "actionComplete":
        MessageLookupByLibrary.simpleMessage(spanishUi("Action Complete")),
    "productionLine":
        MessageLookupByLibrary.simpleMessage(spanishUi("Production Line")),
    "inputProductionLineHint": MessageLookupByLibrary.simpleMessage(
        spanishUi("Please input a production line")),
    "workOrderProduce":
        MessageLookupByLibrary.simpleMessage(spanishUi("Produce")),
    "producedQuantity":
        MessageLookupByLibrary.simpleMessage(spanishUi("Produced Quantity")),
    "producingQuantity":
        MessageLookupByLibrary.simpleMessage(spanishUi("Producing Quantity")),
    "billOfMaterial": MessageLookupByLibrary.simpleMessage(spanishUi("BOM")),
    "workingTeamName":
        MessageLookupByLibrary.simpleMessage(spanishUi("Working Team")),
    "kpi": MessageLookupByLibrary.simpleMessage(spanishUi("KPI")),
    "kpiAmount": MessageLookupByLibrary.simpleMessage(spanishUi("Amount")),
    "kpiMeasurement":
        MessageLookupByLibrary.simpleMessage(spanishUi("Measurement")),
    "workingTeamMemberCount": MessageLookupByLibrary.simpleMessage(
        spanishUi("Work Team Member Count")),
    "productionLineCheckIn": MessageLookupByLibrary.simpleMessage(
        spanishUi("Production Line Check In")),
    "productionLineCheckOut": MessageLookupByLibrary.simpleMessage(
        spanishUi("Production Line Check Out")),
    "transactionTime":
        MessageLookupByLibrary.simpleMessage(spanishUi("Transaction Time")),
    "noWorkOrderFoundOnProductionLine": MessageLookupByLibrary.simpleMessage(
        spanishUi("No Work Order Found on This Production Line")),
    "pickWrongLPN": MessageLookupByLibrary.simpleMessage(
        spanishUi("lpn is not correct for picking")),
    "inventoryAdjust":
        MessageLookupByLibrary.simpleMessage(spanishUi("Inventory Adjust")),
    "error": MessageLookupByLibrary.simpleMessage(spanishUi("Error")),
    "warning": MessageLookupByLibrary.simpleMessage(spanishUi("Warning")),
    "skip": MessageLookupByLibrary.simpleMessage(spanishUi("Skip")),
    "inventoryNeedQC": MessageLookupByLibrary.simpleMessage(
        spanishUi("The Inventory Needs QC")),
    "workOrderQCNumber":
        MessageLookupByLibrary.simpleMessage(spanishUi("QC Number")),
    "workOrderQCSampleNumber":
        MessageLookupByLibrary.simpleMessage(spanishUi("QC Sample Number")),
    "workOrderQC":
        MessageLookupByLibrary.simpleMessage(spanishUi("Work Order QC")),
    "clear": MessageLookupByLibrary.simpleMessage(spanishUi("Clear")),
    "qcPass": MessageLookupByLibrary.simpleMessage(spanishUi("Pass")),
    "qcFail": MessageLookupByLibrary.simpleMessage(spanishUi("Fail")),
    "qcCompleted":
        MessageLookupByLibrary.simpleMessage(spanishUi("QC Completed")),
    "startQC": MessageLookupByLibrary.simpleMessage(spanishUi("Start QC")),
    "workOrderNoQCConfig": MessageLookupByLibrary.simpleMessage(spanishUi(
        "Cannot find any qc rule setup for this work order & production line")),
    "nextQCRule":
        MessageLookupByLibrary.simpleMessage(spanishUi("Next QC Rule")),
    "inventoryNotQCRequired": MessageLookupByLibrary.simpleMessage(
        spanishUi("The inventory does not need QC")),
    "pleaseSelect":
        MessageLookupByLibrary.simpleMessage(spanishUi("Please select")),
    "noCheckInProductionLineFoundForUser": MessageLookupByLibrary.simpleMessage(
        spanishUi("The user has not checked in any production line")),
    "noCheckInUsersFoundForProductionLine":
        MessageLookupByLibrary.simpleMessage(
            spanishUi("There's no user checked in this production line")),
    "productionLineCheckOutByUser":
        MessageLookupByLibrary.simpleMessage(spanishUi("By User")),
    "productionLineCheckOutByProductionLine":
        MessageLookupByLibrary.simpleMessage(spanishUi("By Production Line")),
    "pleaseSelectAUser":
        MessageLookupByLibrary.simpleMessage(spanishUi("Please Select A User")),
    "pleaseSelectAProductionLine": MessageLookupByLibrary.simpleMessage(
        spanishUi("Please Select A Production Line")),
    "appUpgrade":
        MessageLookupByLibrary.simpleMessage(spanishUi("App Upgrade")),
    "startDownloadingAppNewVersion": MessageLookupByLibrary.simpleMessage(
        spanishUi("Start Downloading new version")),
    "newReleaseFound":
        MessageLookupByLibrary.simpleMessage(spanishUi("New Release Found")),
    "qcQuantity":
        MessageLookupByLibrary.simpleMessage(spanishUi("QC Quantity")),
    "lpnUnitOfMeasure":
        MessageLookupByLibrary.simpleMessage(spanishUi("LPN UOM")),
    "enoughLPNCaptured": MessageLookupByLibrary.simpleMessage(
        spanishUi("We already captured enough LPN")),
    "requestedLPNQuantity": MessageLookupByLibrary.simpleMessage(
        spanishUi("Requested LPN Quantity")),
    "capturedLPNQuantity": MessageLookupByLibrary.simpleMessage(
        spanishUi("Captured LPN Quantity")),
    "captureLPN":
        MessageLookupByLibrary.simpleMessage(spanishUi("Captured LPN")),
    "receivingMultipleLpns": MessageLookupByLibrary.simpleMessage(
        spanishUi("Receive Multiple LPNs")),
    "receivingCurrentLpn": MessageLookupByLibrary.simpleMessage(
        spanishUi("Receiving Current LPN")),
    "addSample": MessageLookupByLibrary.simpleMessage(spanishUi("Add Sample")),
    "noAssignmentByProductionLine": MessageLookupByLibrary.simpleMessage(
        spanishUi("No Assignment Found by Production Line:")),
    "addImage": MessageLookupByLibrary.simpleMessage(spanishUi("Add Image")),
    "takePhoto": MessageLookupByLibrary.simpleMessage(spanishUi("Take Photo")),
    "qcSampleAdded":
        MessageLookupByLibrary.simpleMessage(spanishUi("QC Sample Added")),
    "qcSampleNumberAlreadyExists": MessageLookupByLibrary.simpleMessage(
        spanishUi("QC Sample With The Same Name Already Exists")),
    "noQCSampleExists": MessageLookupByLibrary.simpleMessage(
        spanishUi("Cannot find the qc samples")),
    "qcSampling":
        MessageLookupByLibrary.simpleMessage(spanishUi("QC Sampling")),
    "itemSamplingNumber":
        MessageLookupByLibrary.simpleMessage(spanishUi("Item Sampling Number")),
    "httpError400": MessageLookupByLibrary.simpleMessage(
        spanishUi("Request Has Syntax Error")),
    "httpError401":
        MessageLookupByLibrary.simpleMessage(spanishUi("User Not Authorized")),
    "httpError403":
        MessageLookupByLibrary.simpleMessage(spanishUi("Server Deny")),
    "httpError404":
        MessageLookupByLibrary.simpleMessage(spanishUi("Page Not Found")),
    "httpError405": MessageLookupByLibrary.simpleMessage(
        spanishUi("Request Method is Blocked")),
    "httpError500":
        MessageLookupByLibrary.simpleMessage(spanishUi("Server Error")),
    "httpError502":
        MessageLookupByLibrary.simpleMessage(spanishUi("Invalid Request")),
    "httpError503":
        MessageLookupByLibrary.simpleMessage(spanishUi("Server is Down")),
    "httpError505": MessageLookupByLibrary.simpleMessage(
        spanishUi("Request Method is not Support")),
    "lpnQuantityExceedWarningTitle": MessageLookupByLibrary.simpleMessage(
        spanishUi("Exceed LPN Standard Quantity")),
    "lpnQuantityExceedWarningMessage": MessageLookupByLibrary.simpleMessage(
        spanishUi(
            "The quantity of inventory you are receiving exceeds the LPN standard quantity. Press Yes to continue receiving")),
    "overPickNotAllowed": MessageLookupByLibrary.simpleMessage(
        spanishUi("Over pick is not allowed")),
    "pickToProductionLineInStage": MessageLookupByLibrary.simpleMessage(
        spanishUi("Pick To Production Line's Stage")),
    "itemNotReceivableNoPackageType": MessageLookupByLibrary.simpleMessage(
        spanishUi(
            "Item is not receivable as there's no item package setup yet")),
    "addOrModify":
        MessageLookupByLibrary.simpleMessage(spanishUi("Add or Modify")),
    "whetherAddNewSample": MessageLookupByLibrary.simpleMessage(spanishUi(
        "QC Sample exists for this production line, click Yes to modify the sample, No to add new sample")),
    "barcodeReceiving":
        MessageLookupByLibrary.simpleMessage(spanishUi("Barcode Receiving")),
    "startCamera":
        MessageLookupByLibrary.simpleMessage(spanishUi("Start Camera")),
    "incorrectBarcodeFormat": MessageLookupByLibrary.simpleMessage(
        spanishUi("Barcode is not in the right format")),
    "barcodeReceivingVerbiage": MessageLookupByLibrary.simpleMessage(spanishUi(
        "Scan in the barcode or click the button to start the camera")),
    "barcodeLastReceivingVerbiage": MessageLookupByLibrary.simpleMessage(
        spanishUi("Last received inventory")),
    "number": MessageLookupByLibrary.simpleMessage(spanishUi("Number")),
    "type": MessageLookupByLibrary.simpleMessage(spanishUi("Type")),
    "acknowledge":
        MessageLookupByLibrary.simpleMessage(spanishUi("Acknowledge")),
    "sourceLocation":
        MessageLookupByLibrary.simpleMessage(spanishUi("Source Location")),
    "partailBulkPickNotAllowed": MessageLookupByLibrary.simpleMessage(
        spanishUi("Partial Bulk Pick is Not Allowed")),
    "cannotFindWarehouse": MessageLookupByLibrary.simpleMessage(
        spanishUi("Cannot find warehouse")),
    "reverseProduction":
        MessageLookupByLibrary.simpleMessage(spanishUi("Reverse Production")),
    "reverseReceiving":
        MessageLookupByLibrary.simpleMessage(spanishUi("Reverse Received LPN")),
    "reverseErrorMixedWithClient": MessageLookupByLibrary.simpleMessage(
        spanishUi(
            "Can't reverse inventory when it is mixed with different Client")),
    "reverseErrorMixedWithItem": MessageLookupByLibrary.simpleMessage(spanishUi(
        "Can't reverse inventory when it is mixed with different Item")),
    "reverseErrorNoWorkOrder": MessageLookupByLibrary.simpleMessage(spanishUi(
        "Can't reverse inventory as it has inventory that is not from work order")),
    "reverseErrorMixedWorkOrder": MessageLookupByLibrary.simpleMessage(spanishUi(
        "Can't reverse inventory when it is mixed with different Work Order")),
    "reverseErrorNoReceipt": MessageLookupByLibrary.simpleMessage(spanishUi(
        "Can't reverse inventory as it has inventory that is not from Receipt")),
    "reverseErrorMixedReceipt": MessageLookupByLibrary.simpleMessage(spanishUi(
        "Can't reverse inventory when it is mixed with different Receipt")),
    "version": MessageLookupByLibrary.simpleMessage(spanishUi("Version")),
    "warehouse": MessageLookupByLibrary.simpleMessage(spanishUi("Warehouse")),
    "rfCode": MessageLookupByLibrary.simpleMessage(spanishUi("RF Code")),
    "bulkPick": MessageLookupByLibrary.simpleMessage(spanishUi("Bulk Pick")),
    "listPick": MessageLookupByLibrary.simpleMessage(spanishUi("List Pick")),
    "pickList": MessageLookupByLibrary.simpleMessage(spanishUi("Pick List")),
    "pick": MessageLookupByLibrary.simpleMessage(spanishUi("Pick")),
    "reason": MessageLookupByLibrary.simpleMessage(spanishUi("Reason")),
    "batchDepositInventory":
        MessageLookupByLibrary.simpleMessage(spanishUi("Batch Deposit")),
    "nextLocation":
        MessageLookupByLibrary.simpleMessage(spanishUi("Next Location")),
    "allocateLocation":
        MessageLookupByLibrary.simpleMessage(spanishUi("Allocate Location")),
    "sortBy": MessageLookupByLibrary.simpleMessage(spanishUi("Sort By")),
    "captureInventoryAttribute": MessageLookupByLibrary.simpleMessage(
        spanishUi("Capture Inventory Attribute")),
    "manualPick":
        MessageLookupByLibrary.simpleMessage(spanishUi("Manual Pick")),
    "pickToShipStage":
        MessageLookupByLibrary.simpleMessage(spanishUi("Pick To Ship Stage")),
    "waveNumber":
        MessageLookupByLibrary.simpleMessage(spanishUi("Wave Number")),
    "addWave": MessageLookupByLibrary.simpleMessage(spanishUi("Add Wave")),
    "color": MessageLookupByLibrary.simpleMessage(spanishUi("Color")),
    "style": MessageLookupByLibrary.simpleMessage(spanishUi("Style")),
    "productSize":
        MessageLookupByLibrary.simpleMessage(spanishUi("Product Size")),
    "inventoryAttribute1": MessageLookupByLibrary.simpleMessage(
        spanishUi("Inventory Attribute 1")),
    "inventoryAttribute2": MessageLookupByLibrary.simpleMessage(
        spanishUi("Inventory Attribute 2")),
    "inventoryAttribute3": MessageLookupByLibrary.simpleMessage(
        spanishUi("Inventory Attribute 3")),
    "inventoryAttribute4": MessageLookupByLibrary.simpleMessage(
        spanishUi("Inventory Attribute 4")),
    "inventoryAttribute5": MessageLookupByLibrary.simpleMessage(
        spanishUi("Inventory Attribute 5")),
    "cancelPickAndReallocate": MessageLookupByLibrary.simpleMessage(
        spanishUi("Cancel And Reallocate")),
    "chooseNextPick":
        MessageLookupByLibrary.simpleMessage(spanishUi("Choose Next Pick")),
    "pickByWave":
        MessageLookupByLibrary.simpleMessage(spanishUi("Pick By Wave")),
    "lastQCTime":
        MessageLookupByLibrary.simpleMessage(spanishUi("Last QC Time")),
    "changeQuantity":
        MessageLookupByLibrary.simpleMessage(spanishUi("Change Quantity")),
    "originalQuantity":
        MessageLookupByLibrary.simpleMessage(spanishUi("Original Quantity")),
    "newQuantity":
        MessageLookupByLibrary.simpleMessage(spanishUi("New Quantity")),
    "original": MessageLookupByLibrary.simpleMessage(spanishUi("Original")),
    "newValue": MessageLookupByLibrary.simpleMessage(spanishUi("New")),
    "select": MessageLookupByLibrary.simpleMessage(spanishUi("Select")),
    "downloading":
        MessageLookupByLibrary.simpleMessage(spanishUi("Downloading")),
    "auto": MessageLookupByLibrary.simpleMessage(spanishUi("Auto")),
    "cancel": MessageLookupByLibrary.simpleMessage(spanishUi("cancel")),
    "language": MessageLookupByLibrary.simpleMessage(spanishUi("Language")),
    "logout": MessageLookupByLibrary.simpleMessage(spanishUi("logout")),
    "logoutTip": MessageLookupByLibrary.simpleMessage(spanishUi("Are you sure you want to quit your current account?")),
    "noDescription": MessageLookupByLibrary.simpleMessage(spanishUi("No description yet !")),
    "passwordRequired": MessageLookupByLibrary.simpleMessage(spanishUi("Password required!")),
    "setting": MessageLookupByLibrary.simpleMessage(spanishUi("Setting")),
    "theme": MessageLookupByLibrary.simpleMessage(spanishUi("Theme")),
    "title": MessageLookupByLibrary.simpleMessage(spanishUi("Flutter APP")),
    "userName": MessageLookupByLibrary.simpleMessage(spanishUi("User Name")),
    "userNameOrPasswordWrong": MessageLookupByLibrary.simpleMessage(spanishUi("User name or password is not correct!")),
    "userNameRequired": MessageLookupByLibrary.simpleMessage(spanishUi("User name required!")),
    "yes": MessageLookupByLibrary.simpleMessage(spanishUi("Yes")),
    "no": MessageLookupByLibrary.simpleMessage(spanishUi("No")),
    'greetingMessage': (Object name) => 'Hola $name',
    'missingField': (Object name) => '${spanishUi('$name')} es obligatorio',
    'incorrectValue': (Object name) =>
        'Valor incorrecto: ${spanishUi('$name')}',
    'companyCode': MessageLookupByLibrary.simpleMessage('Código de empresa'),
    'username': MessageLookupByLibrary.simpleMessage('Usuario'),
    'rememberMe': MessageLookupByLibrary.simpleMessage('Recordarme'),
  };
}
