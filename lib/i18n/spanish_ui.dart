import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String uiText(BuildContext context, String english) =>
    Localizations.localeOf(context).languageCode == 'es'
        ? spanishUi(english)
        : english;

String uiTemplate(BuildContext context, String english, List<Object?> values) {
  final template = uiText(context, english);
  return template.replaceAllMapped(RegExp(r'\{(\d+)\}'), (match) {
    final index = int.parse(match[1]!);
    return index < values.length ? '${values[index] ?? ''}' : match[0]!;
  });
}

String localizedUi(String english) =>
    Intl.getCurrentLocale().startsWith('es') ? spanishUi(english) : english;

String? uiOptionalText(BuildContext context, String? english) =>
    english == null ? null : uiText(context, english);

String uiErrorText(BuildContext context, String message) {
  final translated = uiText(context, message);
  if (Localizations.localeOf(context).languageCode != 'es' ||
      translated != message) return translated;
  return 'No se pudo completar la operación. Detalles del servidor:\n$message';
}

String _normalize(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
final _spanishByText = <String, String>{
  for (final entry in spanishUiTranslations.entries)
    _normalize(entry.key): entry.value,
};
final _templates = <_UiTemplate>[
  for (final entry in spanishUiTranslations.entries)
    if (entry.key.contains(RegExp(r'\{\d+\}')) &&
        entry.key.replaceAll(RegExp(r'[^A-Za-z]'), '').length >= 10)
      _UiTemplate(entry.key, entry.value),
];

String spanishUi(String english) {
  final exact = _spanishByText[_normalize(english)];
  if (exact != null) return exact;
  for (final template in _templates) {
    final translated = template.translate(english);
    if (translated != null) return translated;
  }
  return english;
}

class _UiTemplate {
  _UiTemplate(String english, this.spanish) {
    final out = StringBuffer('^');
    var offset = 0;
    for (final match in RegExp(r'\{(\d+)\}').allMatches(english.trim())) {
      out.write(RegExp.escape(english.trim().substring(offset, match.start))
          .replaceAll(RegExp(r'\s+'), r'\s+'));
      out.write(r'([\s\S]*?)');
      fields.add(int.parse(match[1]!));
      offset = match.end;
    }
    out.write(RegExp.escape(english.trim().substring(offset))
        .replaceAll(RegExp(r'\s+'), r'\s+'));
    out.write(r'$');
    pattern = RegExp(out.toString(), caseSensitive: false);
  }
  final String spanish;
  final fields = <int>[];
  late final RegExp pattern;
  String? translate(String value) {
    final match = pattern.firstMatch(value.trim());
    if (match == null) return null;
    return spanish.replaceAllMapped(RegExp(r'\{(\d+)\}'), (m) {
      final slot = fields.indexOf(int.parse(m[1]!));
      return slot < 0 ? m[0]! : match[slot + 1]!;
    });
  }
}

// Text only. Route names, status codes, quantities and business data are not translated.
const spanishUiTranslations = <String, String>{
  "1. Capture LPNs": "1. Capturar LPN",
  "2. Select LPNs ({0}/{1})": "2. Seleccionar LPN ({0}/{1})",
  "3. Choose Operation": "3. Elegir operación",
  "About Claytech One": "Acerca de Claytech One",
  "Account Display": "Información de la cuenta",
  "Acknowledge": "Aceptar asignación",
  "Action Complete": "Operación completada",
  "Add": "Añadir",
  "Add Batch": "Añadir lote",
  "Add Image": "Añadir imagen",
  "Add Item": "Añadir producto",
  "Add LPN": "Añadir LPN",
  "Add LPN manually": "Añadir LPN manualmente",
  "Add Order": "Añadir pedido",
  "Add Sample": "Añadir muestra",
  "Add WO": "Añadir orden",
  "Add Wave": "Añadir ola",
  "Add or Modify": "Añadir o modificar",
  "All": "Todos",
  "All applications": "Todas las aplicaciones",
  "Allocate Location": "Asignar ubicación",
  "Amount": "Importe",
  "App Upgrade": "Actualización de la aplicación",
  "App is up to date": "La aplicación está actualizada",
  "App update ready": "Actualización lista",
  "Apply downloaded update": "Aplicar actualización descargada",
  "Are you sure you want to quit your current account?":
      "¿Desea cerrar la sesión actual?",
  "Audit Count": "Conteo de auditoría",
  "Auto": "Usar idioma del dispositivo",
  "BOM": "Lista de materiales",
  "Barcode Receiving": "Recepción por código",
  "Barcode Type: {0}   Data: {1}": "Tipo de código: {0}   Datos: {1}",
  "Barcode is not in the right format":
      "El código de barras tiene un formato incorrecto",
  "Batch Deposit": "Depósito por lote",
  "Batch Pick Quantity:": "Cantidad del grupo:",
  "Bulk Pick": "Preparación por grupo",
  "By Production Line": "Por línea de producción",
  "By User": "Por usuario",
  "CLAYTECH ONE / WORKSPACE": "CLAYTECH ONE / ÁREA DE TRABAJO",
  "Camera facing {0}": "Cámara: {0}",
  "Can't find receipt by number {0}": "No se encontró la recepción {0}",
  "Can't parse the barcode {0}": "No se pudo interpretar el código {0}",
  "Can't reverse inventory as it has inventory that is not from Receipt":
      "No se puede revertir porque incluye inventario que no procede de una recepción",
  "Can't reverse inventory as it has inventory that is not from work order":
      "No se puede revertir porque incluye inventario que no procede de una orden de trabajo",
  "Can't reverse inventory when it is mixed with different Client":
      "No se puede revertir inventario que mezcla distintos clientes",
  "Can't reverse inventory when it is mixed with different Item":
      "No se puede revertir inventario que mezcla distintos productos",
  "Can't reverse inventory when it is mixed with different Receipt":
      "No se puede revertir inventario que mezcla distintas recepciones",
  "Can't reverse inventory when it is mixed with different Work Order":
      "No se puede revertir inventario que mezcla distintas órdenes de trabajo",
  "Cancel": "Cancelar",
  "Cancel And Reallocate": "Cancelar y reasignar",
  "Cancel if not started": "Cancelar si no se ha iniciado",
  "Cannot find any inventory": "No se encontró inventario",
  "Cannot find any qc rule setup for this work order & production line":
      "No hay reglas de calidad configuradas para esta orden y línea",
  "Cannot find the qc samples": "No se encontraron muestras de calidad",
  "Cannot find warehouse": "No se encontró el almacén",
  "Capture Inventory Attribute": "Capturar atributo de inventario",
  "Captured LPN": "LPN capturado",
  "Captured LPN Quantity": "Cantidad de LPN capturada",
  "Change Quantity": "Cambiar cantidad",
  "Change Status": "Cambiar estado",
  "Check In": "Registrar entrada",
  "Check Out": "Registrar salida",
  "Check for updates": "Buscar actualizaciones",
  "Check that your last operation completed successfully. Unsaved entries will be lost. After closing, tap the app icon to reopen it.":
      "Verifique que su última operación se haya completado. Se perderán los datos sin guardar. Después de cerrar, toque el icono para volver a abrir la aplicación.",
  "Checking for updates...": "Buscando actualizaciones…",
  "Choose Batch": "Seleccionar lote",
  "Choose Item": "Seleccionar producto",
  "Choose Next Pick": "Seleccionar siguiente preparación",
  "Choose Order": "Seleccionar pedido",
  "Choose Photo": "Seleccionar foto",
  "Choose Receipt": "Seleccionar recepción",
  "Choose Server": "Seleccionar servidor",
  "Choose WO": "Seleccionar orden",
  "Choose a Pick": "Seleccionar preparación",
  "Choose a machine": "Seleccionar máquina",
  "Choose an operation to get started.":
      "Seleccione una operación para comenzar.",
  "Choose defective reason": "Seleccionar motivo del defecto",
  "Choose your factory": "Seleccione su planta",
  "Claytech One - Cycle Count": "Claytech One - Conteo cíclico",
  "Claytech One - Cycle Count - {0}": "Claytech One - Conteo cíclico - {0}",
  "Claytech One - Deposit": "Claytech One - Depósito",
  "Claytech One - Inventory": "Claytech One - Inventario",
  "Claytech One - Inventory Putaway": "Claytech One - Ubicación de inventario",
  "Claytech One - Inventory QC": "Claytech One - Calidad de inventario",
  "Claytech One - Item Sampling": "Claytech One - Muestreo de producto",
  "Claytech One - Partial Inventory Move": "Claytech One - Movimiento parcial",
  "Claytech One - Pick": "Claytech One - Preparación",
  "Claytech One - QC": "Claytech One - Calidad",
  "Claytech One - System Driven Work": "Claytech One - Trabajo dirigido",
  "Clear": "Limpiar",
  "Close": "Cerrar",
  "Close and reopen": "Cerrar y volver a abrir",
  "Close and reopen the app to apply the update.":
      "Cierre y vuelva a abrir la aplicación para aplicar la actualización.",
  "Close app": "Cerrar aplicación",
  "Close app to apply update?": "¿Cerrar la aplicación para actualizar?",
  "Color": "Color",
  "Confirm": "Confirmar",
  "Confirm Defective": "Confirmar defectuosos",
  "Confirm Operation": "Confirmar operación",
  "Confirm pallet pick": "Confirmar preparación del pallet",
  "Confirm pick": "Confirmar preparación",
  "Confirmation is not yet known. Keep both labels and retry the same pick; do not split again.":
      "Aún no se conoce el resultado. Conserve ambas etiquetas y reintente la misma preparación; no vuelva a dividir el pallet.",
  "Contact": "Contacto",
  "Could not load picking quantities. Please try again.":
      "No se pudieron cargar las cantidades de preparación. Reintente.",
  "Could not load this page. Check your connection and retry.":
      "No se pudo cargar esta página. Revise la conexión y reintente.",
  "Could not verify cancellation. Keep both labels and retry later.":
      "No se pudo verificar la cancelación. Conserve ambas etiquetas y reintente más tarde.",
  "Count Quantity": "Cantidad contada",
  "Current Location": "Ubicación actual",
  "Cycle Count": "Conteo cíclico",
  "DMG / Damaged": "DMG / Dañado",
  "Damaged": "Dañado",
  "Data Saved": "Datos guardados",
  "Defective": "Producción defectuosa",
  "Defective quantity": "Cantidad defectuosa",
  "Delete": "Eliminar",
  "Delete LPN": "Eliminar LPN",
  "Delete LPN?": "¿Eliminar LPN?",
  "Deposit": "Depositar",
  "Deposit All": "Depositar todos",
  "Deposit Selected LPN": "Depositar LPN seleccionado",
  "Destination LPN:": "LPN de destino:",
  "Destination Location": "Ubicación de destino",
  "Downloading": "Descargando",
  "Edit LPN": "Editar LPN",
  "Enter LPN": "Ingresar LPN",
  "Enter company code and username":
      "Ingrese el código de empresa y el usuario",
  "Enter location name": "Ingrese la ubicación",
  "Enter username to load warehouses":
      "Ingrese el usuario para cargar los almacenes",
  "Error": "Error",
  "Exceed LPN Standard Quantity": "Se supera la cantidad estándar del LPN",
  "Execute": "Ejecutar",
  "Execute Selected LPNs": "Ejecutar LPN seleccionados",
  "Executing Operation": "Ejecutando operación",
  "Executing operation...": "Ejecutando operación…",
  "Expected Quantity": "Cantidad esperada",
  "Fail": "No conforme",
  "Find": "Buscar",
  "Finish your current task and check its result. Open the app switcher, swipe Claytech One up to close it, then reopen the app to apply the update.":
      "Termine la tarea y verifique el resultado. Abra el selector de aplicaciones, deslice Claytech One hacia arriba para cerrarla y vuelva a abrirla para aplicar la actualización.",
  "First Name": "Nombre",
  "First Name is Required": "El nombre es obligatorio",
  "Flash: {0}": "Flash: {0}",
  "Flutter APP": "Claytech One",
  "From LPN:": "Desde el LPN:",
  "High Priority": "Prioridad alta",
  "Home": "Inicio",
  "How to apply update": "Cómo aplicar la actualización",
  "Inbound": "Entradas",
  "Inbound QC": "Calidad de recepción",
  "Inbound quality check": "Inspección de recepción",
  "Invalid Request": "Solicitud no válida",
  "Inventory": "Inventario",
  "Inventory Adjust": "Ajuste de inventario",
  "Inventory Attribute 1": "Atributo de inventario 1",
  "Inventory Attribute 2": "Atributo de inventario 2",
  "Inventory Attribute 3": "Atributo de inventario 3",
  "Inventory Attribute 4": "Atributo de inventario 4",
  "Inventory Attribute 5": "Atributo de inventario 5",
  "Inventory Lost And Found": "Objetos encontrados",
  "Inventory Putaway": "Ubicar inventario",
  "Inventory QC": "Calidad de inventario",
  "Inventory Quantity:": "Cantidad de inventario:",
  "Inventory Status": "Estado del inventario",
  "Inventory quality check": "Inspección de inventario",
  "Item": "Producto",
  "Item Number:": "Número de producto:",
  "Item Package Type": "Tipo de empaque",
  "Item Sampling": "Muestreo de producto",
  "Item Sampling Number": "Número de muestra del producto",
  "Item is not receivable as there's no item package setup yet":
      "No se puede recibir el producto porque no tiene un empaque configurado",
  "Item or package details are missing. Refresh or check configuration.":
      "Faltan datos del producto o empaque. Actualice o revise la configuración.",
  "Item unavailable": "Producto no disponible",
  "Item: {0}": "Producto: {0}",
  "KPI": "KPI",
  "LPN": "LPN",
  "LPN UOM": "Unidad del LPN",
  "LPN is required": "El LPN es obligatorio",
  "LPN must start with L or R and contain at least 6 characters.":
      "El LPN debe comenzar con L o R y tener al menos 6 caracteres.",
  "Language": "Idioma",
  "Last Name": "Apellido",
  "Last Name is Required": "El apellido es obligatorio",
  "Last QC Time": "Última inspección",
  "Last received inventory": "Último inventario recibido",
  "Last selected": "Última selección",
  "Later": "Más tarde",
  "Line {0}": "Línea {0}",
  "List Number:": "Número de lista:",
  "List Pick": "Preparación por lista",
  "Load more": "Cargar más",
  "Loading statuses...": "Cargando estados…",
  "Loading warehouses…": "Cargando almacenes…",
  "Loading...": "Cargando…",
  "Location {0} is not the right location for pick":
      "La ubicación {0} no es correcta para esta preparación",
  "Location:": "Ubicación:",
  "Location: {0}": "Ubicación: {0}",
  "Login": "Iniciar sesión",
  "Lost & Found": "Objetos encontrados",
  "Lost and Found": "Objetos encontrados",
  "Manual Pick": "Preparación manual",
  "Me": "Mi cuenta",
  "Measurement": "Medición",
  "Move": "Mover",
  "Move {0} LPN(s) to {1}?": "¿Mover {0} LPN a {1}?",
  "Multiple LPN Capture": "Captura de varios LPN",
  "New": "Nuevo",
  "New LPN": "LPN nuevo",
  "New LPN for picked units": "LPN nuevo para unidades preparadas",
  "New LPN for remaining stock": "LPN nuevo para inventario restante",
  "New Quantity": "Nueva cantidad",
  "New Release Found": "Nueva versión disponible",
  "Next Location": "Siguiente ubicación",
  "Next QC Rule": "Siguiente regla",
  "Next Step": "Siguiente",
  "No": "No",
  "No Assignment Found by Production Line:":
      "No se encontró una asignación para la línea:",
  "No LPNs yet. Capture a photo or add one manually.":
      "No hay LPN. Tome una foto o añada uno manualmente.",
  "No More Audit Count in this Batch":
      "No quedan conteos de auditoría en este lote",
  "No More Cycle Count in this Batch":
      "No quedan conteos cíclicos en este lote",
  "No Work Order Found on This Production Line":
      "No hay una orden de trabajo en esta línea",
  "No applications available": "No hay aplicaciones disponibles",
  "No description yet !": "Sin descripción",
  "No enabled inspection checks are available for this rule. Ask an administrator to review the QC configuration.":
      "Esta regla no tiene puntos de inspección habilitados. Solicite al administrador revisar la configuración.",
  "No inspection checks are available. Review the QC configuration.":
      "No hay puntos de inspección disponibles. Revise la configuración.",
  "No machines with active assigned work orders":
      "No hay máquinas con órdenes activas asignadas",
  "No more inventory on the RF": "No queda inventario en RF",
  "No operations available": "No hay operaciones disponibles",
  "No reasons available. Please retry.":
      "No hay motivos disponibles. Reintente.",
  "No. {0} image": "Imagen n.º {0}",
  "Not Auth": "Sin autorización",
  "Not configured": "Sin configurar",
  "Notification": "Notificación",
  "Notification History": "Historial de notificaciones",
  "Number": "Número",
  "OK": "Aceptar",
  "Open-source Licenses": "Licencias de código abierto",
  "Operation Complete": "Operación completada",
  "Operations": "Operaciones",
  "Order Number": "Número de pedido",
  "Order picking complete": "Preparación del pedido completada",
  "Order {0}\nLPN {1}\nQuantity {2}\nRetry this same pick to check and finish it safely.":
      "Pedido {0}\nLPN {1}\nCantidad {2}\nReintente esta misma preparación para verificarla y completarla de forma segura.",
  "Order {0} has no remaining quantity to pick.":
      "El pedido {0} no tiene cantidad pendiente de preparación.",
  "Original": "Original",
  "Original LPN goes with this order": "El LPN original acompaña a este pedido",
  "Original LPN stays with remaining stock":
      "El LPN original queda con el inventario restante",
  "Original Quantity": "Cantidad original",
  "Outbound": "Salidas",
  "Over pick is not allowed":
      "No se permite preparar más de la cantidad solicitada",
  "Page Not Found": "Página no encontrada",
  "Partial Bulk Pick is Not Allowed":
      "No se permite la preparación parcial de un grupo",
  "Partial Inventory Move": "Movimiento parcial",
  "Partial Move": "Movimiento parcial",
  "Pass": "Conforme",
  "Password": "Contraseña",
  "Password required!": "La contraseña es obligatoria",
  "Personal Information": "Información personal",
  "Pick": "Preparar",
  "Pick By List": "Preparar por lista",
  "Pick By Order": "Preparar por pedido",
  "Pick By Tote": "Preparar por contenedor",
  "Pick By WO": "Preparar por orden",
  "Pick By Wave": "Preparar por ola",
  "Pick By Work Order": "Preparar por OT",
  "Pick By Workorder": "Preparar por orden",
  "Pick Error": "Error de preparación",
  "Pick List": "Lista de preparación",
  "Pick Number:": "Número de preparación:",
  "Pick Quantity:": "Cantidad a preparar:",
  "Pick To Production Line's Stage": "Preparar para el área de la línea",
  "Pick To Ship Stage": "Preparar para el área de envío",
  "Pick awaiting confirmation": "Preparación pendiente de confirmación",
  "Pick awaiting confirmation. Press Confirm to resume. Keep both labels; do not split again.":
      "Preparación pendiente de confirmación. Pulse Confirmar para continuar. Conserve ambas etiquetas; no vuelva a dividir el pallet.",
  "Pick confirmed, but the order could not be refreshed. Please reload the order.":
      "Preparación confirmada, pero no se pudo actualizar el pedido. Vuelva a cargarlo.",
  "Pick the full pallet using its original LPN.":
      "Prepare el pallet completo con su LPN original.",
  "Picked Quantity:": "Cantidad preparada:",
  "Please Select A Production Line": "Seleccione una línea de producción",
  "Please Select A User": "Seleccione un usuario",
  "Please choose an LPN": "Seleccione un LPN",
  "Please input a Location": "Ingrese una ubicación",
  "Please input a production line": "Ingrese la línea de producción",
  "Please input a valid RF": "Ingrese un código RF válido",
  "Please input a valid location": "Ingrese una ubicación válida",
  "Please input an Item or Barcode": "Ingrese el producto o código de barras",
  "Please input an LPN": "Escanee o ingrese un LPN",
  "Please input an order number": "Ingrese el número de pedido",
  "Please input an work order number": "Ingrese la orden de trabajo",
  "Please relabel the following inventory into a new LPN":
      "Reetiquete el siguiente inventario con un LPN nuevo",
  "Please select": "Seleccione",
  "Privacy Policy": "Política de privacidad",
  "Processed {0} / {1}": "Procesados {0} / {1}",
  "Produce": "Registrar producción",
  "Produced Quantity": "Cantidad producida",
  "Producing Quantity": "Cantidad a producir",
  "Product Size": "Tamaño del producto",
  "Production Line": "Línea de producción",
  "Production Line Check In": "Entrada a línea",
  "Production Line Check Out": "Salida de línea",
  "Putaway": "Ubicar inventario",
  "QC": "Calidad",
  "QC Completed": "Inspección completada",
  "QC Number": "Número de inspección",
  "QC Quantity": "Cantidad a inspeccionar",
  "QC Sample Added": "Muestra añadida",
  "QC Sample Number": "Número de muestra",
  "QC Sample With The Same Name Already Exists":
      "Ya existe una muestra con ese nombre",
  "QC Sample exists for this production line, click Yes to modify the sample, No to add new sample":
      "Ya existe una muestra para esta línea. Pulse Sí para modificarla o No para añadir otra.",
  "QC Sampling": "Muestreo de calidad",
  "QUALITY CHECK": "INSPECCIÓN DE CALIDAD",
  "Qty: {0},": "Cant.: {0},",
  "Qty: {0}, Remaining Qty: {1}": "Cant.: {0}, pendiente: {1}",
  "Quantity": "Cantidad",
  "Quantity to pick": "Cantidad a preparar",
  "Quantity: {0}": "Cantidad: {0}",
  "Query": "Consultar",
  "RECEIVING": "RECEPCIÓN",
  "RF Code": "Código RF",
  "Reading LPNs from photo...": "Leyendo LPN de la foto…",
  "Ready for the work ahead.": "Todo listo para empezar.",
  "Reason": "Motivo",
  "Receipt Number": "Número de recepción",
  "Receive": "Recibir",
  "Receive Multiple LPNs": "Recibir varios LPN",
  "Received Quantity": "Cantidad recibida",
  "Received {0}  ·  Expected {1}": "Recibido {0}  ·  Esperado {1}",
  "Receiving": "Recepción",
  "Receiving Current LPN": "LPN en recepción",
  "Receiving Quantity": "Cantidad a recibir",
  "Refresh": "Actualizar",
  "Relabel": "Reetiquetar",
  "Remaining Qty: {0}": "Cantidad restante: {0}",
  "Remaining Quantity:": "Cantidad restante:",
  "Remaining stock stays at its original location.":
      "El inventario restante permanece en su ubicación original.",
  "Remember Me": "Recordarme",
  "Remove": "Quitar",
  "Remove LPN": "Quitar LPN",
  "Request Has Syntax Error": "La solicitud tiene un formato incorrecto",
  "Request Method is Blocked": "El método de solicitud está bloqueado",
  "Request Method is not Support": "El método de solicitud no es compatible",
  "Requested LPN Quantity": "Cantidad de LPN solicitada",
  "Required update ready": "Actualización obligatoria lista",
  "Retain LPN for LPN Pick": "Conservar LPN al preparar el pallet",
  "Retry": "Reintentar",
  "Retry this LPN": "Reintentar este LPN",
  "Reverse Production": "Revertir producción",
  "Reverse Received LPN": "Revertir recepción",
  "Save": "Guardar",
  "Scan / enter machine number": "Escanee o ingrese la máquina",
  "Scan a code": "Escanear código",
  "Scan an LPN to begin inspection":
      "Escanee un LPN para iniciar la inspección",
  "Scan an LPN to review QC status":
      "Escanee un LPN para revisar su estado de calidad",
  "Scan in the barcode or click the button to start the camera":
      "Escanee el código o pulse el botón para iniciar la cámara",
  "Scan label": "Escanear etiqueta",
  "Scan or choose a receipt": "Escanee o seleccione una recepción",
  "Scan or enter LPN": "Escanee o ingrese un LPN",
  "Scroll for more": "Deslice para ver más",
  "Secure access to your operations": "Acceso seguro a sus operaciones",
  "Select": "Seleccionar",
  "Select a receipt to get started": "Seleccione una recepción para comenzar",
  "Select a work order and production line":
      "Seleccione la orden de trabajo y la línea de producción",
  "Select inventory for QC": "Seleccionar inventario para inspección",
  "Select status": "Seleccionar estado",
  "Select your assigned machine to report defective output.":
      "Seleccione su máquina asignada para registrar producción defectuosa.",
  "Select your workplace to sign in.":
      "Seleccione su lugar de trabajo para iniciar sesión.",
  "Server Deny": "Acceso denegado por el servidor",
  "Server Error": "Error del servidor",
  "Server is Down": "El servidor no está disponible",
  "Setting": "Configuración",
  "Share": "Compartir",
  "Sign in": "Iniciar sesión",
  "Skip": "Omitir",
  "Sort By": "Ordenar por",
  "Source Location": "Ubicación de origen",
  "Start": "Iniciar",
  "Start Camera": "Iniciar cámara",
  "Start Downloading new version": "Descargando la nueva versión",
  "Start QC": "Iniciar inspección",
  "Starting...": "Iniciando…",
  "Style": "Estilo",
  "Switch factory": "Cambiar planta",
  "Sync": "Sincronizar",
  "Take Photo": "Tomar foto",
  "Take {0} units and attach the new label. Leave {1} units with {2}.":
      "Retire {0} unidades y coloque la etiqueta nueva. Deje {1} unidades con {2}.",
  "Take {0} units using {1}. Attach the new label to the remaining {2} units.":
      "Retire {0} unidades con {1}. Coloque la etiqueta nueva en las {2} unidades restantes.",
  "Technical Support": "Soporte técnico",
  "The Inventory Needs QC": "El inventario requiere inspección de calidad",
  "The inventory does not need QC":
      "El inventario no requiere inspección de calidad",
  "The quantity of inventory you are receiving exceeds the LPN standard quantity. Press Yes to continue receiving":
      "La cantidad a recibir supera la cantidad estándar del LPN. Pulse Sí para continuar.",
  "The user has not checked in any production line":
      "El usuario no ha registrado su entrada a ninguna línea",
  "Theme": "Tema",
  "There's no user checked in this production line":
      "No hay usuarios registrados en esta línea",
  "This legacy task has a PASS summary, but all checkpoints are pending and no inspection time is recorded. Complete the inspection before submitting.":
      "Esta tarea anterior figura como conforme, pero todos sus puntos están pendientes y no tiene hora de inspección. Complete la inspección antes de enviarla.",
  "This pick has already been reserved or processed. Retry it or ask a supervisor; do not split again.":
      "Esta preparación ya está reservada o procesada. Reinténtela o consulte al supervisor; no vuelva a dividir el pallet.",
  "Transaction Time": "Fecha y hora de operación",
  "Try again": "Reintentar",
  "Type": "Tipo",
  "Unable to check for updates. We will retry when connected.":
      "No se pudieron buscar actualizaciones. Se reintentará al recuperar la conexión.",
  "Unable to load applications": "No se pudieron cargar las aplicaciones",
  "Unable to load material consumption details.":
      "No se pudieron cargar los datos de consumo de materiales.",
  "Unable to load reporting details. Please retry.":
      "No se pudieron cargar los datos de producción. Reintente.",
  "Unfinished QC task": "Inspección pendiente",
  "Update Status": "Actualizar estado",
  "Update before starting another operation.":
      "Actualice antes de iniciar otra operación.",
  "Update {0} LPN(s) to {1}?": "¿Actualizar {0} LPN a {1}?",
  "Updating machines…": "Actualizando máquinas…",
  "User Name": "Usuario",
  "User Not Authorized": "Usuario no autorizado",
  "User name or password is not correct!":
      "El usuario o la contraseña no son correctos",
  "User name required!": "El usuario es obligatorio",
  "Version": "Versión",
  "Warehouse": "Almacén",
  "Warning": "Aviso",
  "Wave Number": "Número de ola",
  "We already captured enough LPN": "Ya se capturaron suficientes LPN",
  "Welcome back. Sign in to continue.":
      "Bienvenido. Inicie sesión para continuar.",
  "Work Number:": "Número de trabajo:",
  "Work Order": "Orden de trabajo",
  "Work Order Manual Pick": "Preparación manual",
  "Work Order Number": "Orden de trabajo",
  "Work Order Produce": "Registrar producción",
  "Work Order QC": "Calidad de producción",
  "Work Profile": "Perfil de trabajo",
  "Work Team Member Count": "Número de integrantes del equipo",
  "Working Team": "Equipo de trabajo",
  "Workspace": "Área de trabajo",
  "Yes": "Sí",
  "Your last selected factory will be remembered.":
      "Se recordará la última planta seleccionada.",
  "Your operations, connected. Choose a module to get started.":
      "Sus operaciones, conectadas. Seleccione un módulo para comenzar.",
  "all picks are done!": "Todas las preparaciones están completas",
  "batch ID": "ID del lote",
  "batch ID is required": "El ID del lote es obligatorio",
  "cancel": "Cancelar",
  "click to see the item to be picked": "Ver el producto a preparar",
  "company code": "Código de empresa",
  "company code is required": "El código de empresa es obligatorio",
  "current list {0} is done": "La lista {0} está completa",
  "invalid barcode format": "Formato de código de barras incorrecto",
  "invalid barcode. Can't find the receipt and line":
      "Código no válido. No se encontró la recepción y su línea.",
  "item list": "Lista de productos",
  "loading": "Cargando",
  "location": "Ubicación",
  "logout": "Cerrar sesión",
  "lpn is not correct for picking": "El LPN no es válido para esta preparación",
  "lpn {0} is not pickable": "El LPN {0} no se puede preparar",
  "message": "Mensaje",
  "no Permission": "Permiso denegado",
  "order {0} is marked as not for manual pick":
      "El pedido {0} no permite preparación manual",
  "over receive is not allowed": "No se permite superar la cantidad solicitada",
  "password is required": "La contraseña es obligatoria",
  "pause": "Pausar",
  "please input LPN": "Ingrese un LPN",
  "please input a new lpn": "Ingrese un LPN nuevo",
  "please input batch id": "Ingrese el ID del lote",
  "please input bulk pick number": "Ingrese el número de preparación por grupo",
  "please input order number": "Ingrese el número de pedido",
  "please input password": "Ingrese la contraseña",
  "please input pick list": "Ingrese la lista de preparación",
  "please input pick number": "Ingrese el número de preparación",
  "please input username": "Ingrese el usuario",
  "please input wave number": "Ingrese el número de ola",
  "please input your company code": "Ingrese el código de empresa",
  "please make sure the LPN is in the right place":
      "Verifique que el LPN esté en la ubicación correcta",
  "please scan in item": "Escanee el producto",
  "please scan in receipt": "Escanee la recepción",
  "please type in a valid quantity": "Ingrese una cantidad válida",
  "please type in quantity": "Ingrese la cantidad",
  "please type in the quantity": "Ingrese la cantidad",
  "quantity:": "Cantidad:",
  "quantity: {0}, LPN: {1}": "Cantidad: {0}, LPN: {1}",
  "result": "Resultado",
  "resume": "Reanudar",
  "there's no more open quantity left for manual pick of order {0}":
      "El pedido {0} no tiene cantidad pendiente de preparación manual",
  "there's no more open quantity left for manual pick of work order {0}":
      "La orden de trabajo {0} no tiene cantidad pendiente de preparación manual",
  "there's no open quantity left for manual pick of order {0}":
      "El pedido {0} no tiene cantidad pendiente de preparación manual",
  "username": "Usuario",
  "username is required": "El usuario es obligatorio",
  "{0} LPN(s) captured for the next operation.":
      "Se capturaron {0} LPN para la siguiente operación.",
  "{0} failed, {1} succeeded.": "{0} fallidos, {1} completados.",
  "{0} of {1} checks completed": "{0} de {1} puntos completados",
  "{0} on RF": "{0} en RF",
  "{0} · Qty {1}": "{0} · Cant. {1}",
  "{0} · {1} Fail": "{0} · {1} no conformes",
  "{0} · {1} pending": "{0} · {1} pendientes",
  "{0}: Failed - {1}": "{0}: Falló - {1}",
  "{0}: Success": "{0}: Completado",
  "{0}: Success ({1} record(s))": "{0}: Completado ({1} registros)",
  "Server connected": "Servidor conectado",
  "Waiting for server — scans saved":
      "Esperando al servidor; escaneos guardados",
  "Sign in again to resume saved scans":
      "Inicie sesión de nuevo para continuar con los escaneos guardados",
  "Unable to synchronize — scans retained":
      "No se pudo sincronizar; se conservaron los escaneos",
  "Checking server connection…": "Comprobando la conexión con el servidor…",
  "Saved — waiting for synchronization":
      "Guardado; pendiente de sincronización",
  "Synchronized": "Sincronizado",
  "Please wait for saved scans to load.":
      "Espere a que se carguen los escaneos guardados.",
  "LPN saved for synchronization": "LPN guardado para sincronización",
  "Could not save this scan. Please try again.":
      "No se pudo guardar el escaneo. Reintente.",
  "Could not save retry. Please try again.":
      "No se pudo guardar el reintento. Reintente.",
  "Unable to open saved scans. {0}":
      "No se pudieron abrir los escaneos guardados. {0}",
  "DMG · Damaged": "DMG · Dañado",
  "No warehouses available for this account. Contact your administrator.":
      "Esta cuenta no tiene almacenes disponibles. Contacte al administrador.",
  "Could not load warehouses. Check your connection and retry.":
      "No se pudieron cargar los almacenes. Revise la conexión y reintente.",
  "A unique DMG / Damaged status is required. Check warehouse configuration.":
      "Debe existir un único estado DMG / Dañado. Revise la configuración del almacén.",
  "Unable to load inventory statuses. Retry.":
      "No se pudieron cargar los estados del inventario. Reintente.",
  "No reasons available. Configure them in Master Data.":
      "No hay motivos disponibles. Configúrelos en Datos maestros.",
  "Unable to load reasons. Retry.":
      "No se pudieron cargar los motivos. Reintente.",
  "Select a valid machine and work order.":
      "Seleccione una máquina y una orden de trabajo válidas.",
  "Unable to verify machine assignment. Please retry.":
      "No se pudo verificar la asignación de la máquina. Reintente.",
  "The work order has ended or is no longer assigned to this machine. Return and select again.":
      "La orden terminó o ya no está asignada a esta máquina. Regrese y seleccione otra vez.",
  "Unable to confirm production. Check the LPN result before retrying.":
      "No se pudo confirmar la producción. Verifique el resultado del LPN antes de reintentar.",
  "No pending inspection was found for this LPN. Check its QC history or ask an administrator to review the task.":
      "No hay una inspección pendiente para este LPN. Revise su historial de calidad o consulte al administrador.",
  "This QC task has no enabled inspection checks. Ask an administrator to check the QC rule configuration.":
      "Esta tarea no tiene puntos de inspección habilitados. Solicite al administrador revisar la regla de calidad.",
  "No inventory found for LPN {0}.":
      "No se encontró inventario para el LPN {0}.",
  "Could not load this LPN. Check your connection and try again.":
      "No se pudo cargar este LPN. Revise la conexión y reintente.",
  "This LPN is not awaiting inbound QC. Review its QC history if an inspection was already completed.":
      "Este LPN no tiene una inspección de recepción pendiente. Revise su historial si la inspección ya se completó.",
  "The factory changed. Reopen this inspection.":
      "Cambió la planta seleccionada. Vuelva a abrir esta inspección.",
  "Can't find any work order that assigned to the production line {0}":
      "No hay una orden de trabajo asignada a la línea {0}",
  "multiple work orders found. please specify the work order number as well":
      "Hay varias órdenes asignadas. Ingrese también el número de orden.",
  "can't find inventory by LPN {0}":
      "No se encontró inventario para el LPN {0}",
  "No inventory record found": "No se encontró ningún registro de inventario",
  "Move failed": "No se pudo mover el inventario",
  "A required update is ready. Finish reviewing your last operation, then close and reopen the app.":
      "Hay una actualización obligatoria lista. Termine de revisar su última operación y cierre y vuelva a abrir la aplicación.",
};
