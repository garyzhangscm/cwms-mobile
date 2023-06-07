enum ReportOrientation{
  LANDSCAPE,
  PORTRAIT,
}

ReportOrientation reportOrientationFromString(String value){
  return ReportOrientation.values.firstWhere((e)=>
  e.toString().split('.')[1].toUpperCase()==value.toUpperCase());
}