enum PrintingStrategy{
  SERVER_PRINTER ,
  LOCAL_PRINTER_SERVER_DATA,
  LOCAL_PRINTER_LOCAL_DATA
}

PrintingStrategy printingStrategyFromString(String value){
  return PrintingStrategy.values.firstWhere((e)=>
  e.toString().split('.')[1].toUpperCase()==value.toUpperCase());
}