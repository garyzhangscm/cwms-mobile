enum WorkTaskStatus {
  PENDING,
  RELEASED,
  WORKING,
  COMPLETE
}

WorkTaskStatus workTaskStatusFromString(String value){
  return WorkTaskStatus.values.firstWhere((e)=>
      e.toString().split('.')[1].toUpperCase()==value.toUpperCase());
}