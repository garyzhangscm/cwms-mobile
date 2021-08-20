enum MaterialConsumeTiming {
  WHEN_DELIVER,
  BY_TRANSACTION,
  WHEN_CLOSE,
}

MaterialConsumeTiming materialConsumeTimingFromString(String value){
  return MaterialConsumeTiming.values.firstWhere((e)=>
      e.toString().split('.')[1].toUpperCase()==value.toUpperCase());
}