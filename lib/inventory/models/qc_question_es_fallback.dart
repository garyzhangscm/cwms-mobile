// Test-client compatibility for DTOs that omit the existing Spanish field.
// Source: read-only audit of assigned production QC rules, 2026-10-19.
// Always match both ID and English; never rewrite standards or API payloads.
const qcQuestionEsFallback = <int, Map<String, String>>{
  12: {
    'english': "Does the appearance match sample?",
    'spanish': "¿Coincide la apariencia con la muestra?"
  },
  13: {
    'english': "Does the weight match the sample?",
    'spanish': "¿Coincide el peso con el de la muestra?"
  },
  14: {
    'english': "Does the color match the sample?",
    'spanish': "¿Coincide el color con el de la muestra?"
  },
  15: {
    'english': "Are all the functions right?",
    'spanish': "¿Funcionan correctamente todas las funciones?"
  },
  16: {
    'english': "Does the product have any flashing? ",
    'spanish': "¿Tiene el producto alguna rebaba?"
  },
  17: {
    'english': "Is the product deformed in any way? ",
    'spanish': "¿Presenta el producto alguna deformación?"
  },
  18: {
    'english':
        "If the product has multiple parts, is the product able to be assembled?",
    'spanish':
        "Si el producto tiene varias piezas, ¿se pueden ensamblar correctamente?"
  },
  19: {
    'english': "Are there any broken parts?",
    'spanish': "¿Hay piezas rotas?"
  },
  20: {
    'english': "Is the label correct? ",
    'spanish': "¿Es correcta la etiqueta?"
  },
  21: {
    'english': "Is the packaging (carton/ wrap) ok?",
    'spanish':
        "¿Está en buenas condiciones el embalaje (caja de cartón o envoltura)?"
  },
  22: {
    'english': "Are there any missing parts?",
    'spanish': "¿Falta alguna pieza?"
  },
  44: {'english': "What is the Weight? ", 'spanish': "¿Cuál es el peso?"},
  45: {'english': "Test", 'spanish': "Prueba"},
  48: {
    'english': "have you verify the machines settings",
    'spanish': "¿Ha verificado los ajustes de la máquina?"
  },
  60: {'english': "Inspection qty", 'spanish': "Cantidad inspeccionada"},
  91: {
    'english': "Does the appearance of the product match the Approval Sample? ",
    'spanish':
        "¿Coincide la apariencia del producto con la de la muestra aprobada?"
  },
  92: {
    'english': "Does the color of the product match the Approval Sample?",
    'spanish': "¿Coincide el color del producto con el de la muestra aprobada?"
  },
  93: {
    'english': "Does the weight of the product match the Approval Sample?",
    'spanish': "¿Coincide el peso del producto con el de la muestra aprobada?"
  },
  94: {
    'english': "Do the labels match the labels of the Approval Sample?",
    'spanish': "¿Coinciden las etiquetas con las de la muestra aprobada?"
  },
  95: {
    'english': "Do the functions of the product match the Approval Ssmple?",
    'spanish':
        "¿Coinciden las funciones del producto con las de la muestra aprobada?"
  },
  96: {
    'english': "Does the product match the Specification Sheet?",
    'spanish': "¿Cumple el producto con la hoja de especificaciones?"
  },
  61: {
    'english':
        "Is there any issue with the overall appearance of the suitcase?",
    'spanish': "¿Hay algún problema con la apariencia general de la maleta?"
  },
  62: {
    'english': "Is there any issue with the suitcase's handle and pull rod?",
    'spanish':
        "¿Hay algún problema con el asa y el mango telescópico de la maleta?"
  },
  63: {
    'english': "Is there any issue with the suitcase's wheels?",
    'spanish': "¿Hay algún problema con las ruedas de la maleta?"
  },
  64: {
    'english': "Is there any issue with the inside of the suitcase",
    'spanish': "¿Hay algún problema con el interior de la maleta?"
  },
  65: {
    'english': "Is there any issue with the suitcase's packaging?",
    'spanish': "¿Hay algún problema con el embalaje de la maleta?"
  },
  66: {
    'english': "Is there any other issue with the suitcase?",
    'spanish': "¿Hay algún otro problema con la maleta?"
  },
  67: {
    'english': "Does the weight of this board meet the standard?",
    'spanish': "¿Cumple el peso de esta lámina con el estándar?"
  },
  68: {
    'english': "Does the thickness of this board meet the standard?",
    'spanish': "¿Cumple el espesor de esta lámina con el estándar?"
  },
  69: {
    'english': "Does this board material meet the standard dimensions?",
    'spanish': "¿Cumple esta lámina con las dimensiones estándar?"
  },
  70: {
    'english': "Is there a color difference between this board and the sample?",
    'spanish': "¿Hay alguna diferencia de color entre esta lámina y la muestra?"
  },
  71: {
    'english': "Is there any bubbling on this piece of board?",
    'spanish': "¿Tiene burbujas esta lámina?"
  },
  72: {
    'english': "Does this piece of board contain impurities?",
    'spanish': "¿Contiene impurezas esta lámina?"
  },
  73: {
    'english':
        "Does the film on this board have any color discrepancies or wrinkles?",
    'spanish':
        "¿La película de esta lámina presenta diferencias de color o arrugas?"
  },
  74: {
    'english': "Does the weight of this shell meet the standard?",
    'spanish': "¿Cumple el peso de esta carcasa con el estándar?"
  },
  75: {
    'english': "Does the thickness of this shell meet the standard?",
    'spanish': "¿Cumple el espesor de esta carcasa con el estándar?"
  },
  76: {
    'english': "Does this shell material meet the standard dimensions?",
    'spanish': "¿Cumple esta carcasa con las dimensiones estándar?"
  },
  77: {
    'english': "Is there a color difference between this shell and the sample?",
    'spanish':
        "¿Hay alguna diferencia de color entre esta carcasa y la muestra?"
  },
  78: {
    'english': "Is there any bubbling on this piece of shell?",
    'spanish': "¿Tiene burbujas esta carcasa?"
  },
  79: {
    'english': "Does this shell have any functional defects?",
    'spanish': "¿Tiene esta carcasa algún defecto funcional?"
  },
};
