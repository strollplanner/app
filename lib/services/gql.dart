import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:strollplanner_tracker/config.dart';
import 'package:strollplanner_tracker/services/auth.dart';

typedef DataFactory<D> = D Function(Map<String, dynamic>);

class Error {
  final String message;

  Error(this.message);

  factory Error.fromJson(Map<String, dynamic> json) {
    return Error(json["message"]);
  }
}

class Response<D> {
  final D data;
  final List<Error> errors;

  Response({this.data, this.errors});

  factory Response.fromJson(
      Map<String, dynamic> json, DataFactory dataFactory) {
    if (json['errors'] != null) {
      List<dynamic> errors = json['errors'];

      return Response(
        errors: errors.map((e) => Error.fromJson(e)).toList(),
      );
    }

    return Response(
      data: dataFactory(json['data']),
    );
  }
}

Future<Response<D>> request<D>(
    BuildContext context, String query, DataFactory<D> df,
    {Map<String, Object> variables, String token}) async {
  var headers = <String, String>{
    'Content-Type': 'application/json',
  };

  var reqToken =
      token != null ? token : AuthService.of(context, listen: false).token;
  if (reqToken != null) {
    headers['Authorization'] = 'Bearer $reqToken';
  }

  final res = await http.post(
    '${AppConfig.of(context).apiBaseApiUrl}/graphql',
    headers: headers,
    body: jsonEncode(<String, dynamic>{
      'query': query,
      'variables': variables,
    }),
  );

  if (res.statusCode == 200 || res.statusCode == 422) {
    return Response.fromJson(jsonDecode(utf8.decode(res.bodyBytes)), df);
  } else {
    throw Exception('Request failed: ${res.statusCode}');
  }
}
