// Spanish interface messages. Untranslated messages retain their English fallback.
import 'package:intl/message_lookup_by_library.dart';
import 'messages_messages.dart' as english;

final messages = SpanishMessageLookup();

class SpanishMessageLookup extends MessageLookupByLibrary {
  @override
  String get localeName => 'es';
  @override
  final Map<String, Function> messages = {
    ...Map<String, Function>.from(english.messages.messages),
    "home": MessageLookupByLibrary.simpleMessage("Inicio"),
    "language": MessageLookupByLibrary.simpleMessage("Idioma"),
    "login": MessageLookupByLibrary.simpleMessage("Iniciar sesión"),
    "account": MessageLookupByLibrary.simpleMessage("Cuenta"),
    "save": MessageLookupByLibrary.simpleMessage("Guardar"),
    "result": MessageLookupByLibrary.simpleMessage("Resultado"),
    "password": MessageLookupByLibrary.simpleMessage("Contraseña"),
    "username": MessageLookupByLibrary.simpleMessage("Usuario"),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirmar"),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancelar"),
    "clear": MessageLookupByLibrary.simpleMessage("Limpiar"),
    "next": MessageLookupByLibrary.simpleMessage("Siguiente"),
    "auto": MessageLookupByLibrary.simpleMessage("Usar idioma del dispositivo"),
    "yes": MessageLookupByLibrary.simpleMessage("Sí"),
    "no": MessageLookupByLibrary.simpleMessage("No"),
    "warning": MessageLookupByLibrary.simpleMessage("Aviso"),
    "error": MessageLookupByLibrary.simpleMessage("Error"),
    "startQC": MessageLookupByLibrary.simpleMessage("Iniciar inspección"),
    "qcQuantity":
        MessageLookupByLibrary.simpleMessage("Cantidad a inspeccionar"),
    "qcCompleted":
        MessageLookupByLibrary.simpleMessage("Inspección completada"),
    "nextQCRule": MessageLookupByLibrary.simpleMessage("Siguiente regla"),
    "lpn": MessageLookupByLibrary.simpleMessage("LPN"),
    "quantity": MessageLookupByLibrary.simpleMessage("Cantidad"),
    "item": MessageLookupByLibrary.simpleMessage("Producto"),
    "description": MessageLookupByLibrary.simpleMessage("Descripción"),
    "inventoryNotQCRequired": MessageLookupByLibrary.simpleMessage(
        "No hay una inspección pendiente para este inventario."),
    "companyCode": MessageLookupByLibrary.simpleMessage("Código de empresa"),
    "rfCode": MessageLookupByLibrary.simpleMessage("Código RF"),
    "currentLocation": MessageLookupByLibrary.simpleMessage("Ubicación actual"),
    "warehouse": MessageLookupByLibrary.simpleMessage("Almacén"),
    "rememberMe": MessageLookupByLibrary.simpleMessage("Recordarme"),
  };
}
