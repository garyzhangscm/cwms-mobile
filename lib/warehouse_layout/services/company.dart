
import 'dart:convert';


import 'package:cwms_mobile/inventory/models/cycle_count_request.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_result.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/warehouse_layout/models/company.dart';
import 'package:dio/dio.dart';

class CompanyService {
  // Get all cycle count requests by batch id
  static Future<Company> getCompanyById(int id) async {
    Dio httpClient = CWMSHttpClient.getDio();


    Response response = await httpClient.get(
        "/layout/companies/{id}"
    );

    print("reponse from company: $response");

    Company company =
        Company.fromJson(json.decode(response.toString()));

    return company;
  }
  static Future<int> validateCompanyByCode(String code) async {

    Response response = await Dio().get(
        Global.currentServer.url + "layout/companies/validate",
        queryParameters:{"code": code});
    print("get response: $response");

    Map<String, dynamic> responseJson = json.decode(response.toString());


    if (responseJson["result"] == 0) {
      // ok, we can connect to the server. Add it to the history
      //
      return responseJson["data"];
    }
    else {
      return null;
    }

  }
  static Future<Company> getCompanyByCode(String code) async {
    Dio httpClient = CWMSHttpClient.getDio();


    Response response = await httpClient.get(
        "/layout/companies",
        queryParameters:{"code": code}
    );

    print("reponse from company: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());
    List<dynamic> responseData = responseString["data"];

    List<Company> _companies
    = (responseString["data"] as List)?.map((e) =>
    e == null ? null : Company.fromJson(e as Map<String, dynamic>))
        ?.toList();

    // company code is supposed to be unique.
    if (_companies.isEmpty) {
      return null;
    }
    else {
      return _companies[0];
    }


  }

}