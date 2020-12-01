import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:strollplanner_tracker/constants.dart';

typedef DataFactory<D> = D Function(Map<String, dynamic>);

class Response<D> {
  final D data;
  final List<String> errors;

  Response({this.data, this.errors});

  factory Response.fromJson(
      Map<String, dynamic> json, DataFactory dataFactory) {
    return Response(
      data: dataFactory(json['data']),
      errors: json['errors'],
    );
  }
}

Future<Response<D>> request<D>(String query, String token, DataFactory<D> df,
    {Map<String, Object> variables}) async {
  final res = await http.post(
    '$API_BASE_URL/graphql',
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(<String, dynamic>{
      'query': query,
      'variables': variables,
    }),
  );

  if (res.statusCode == 200) {
    return Response.fromJson(jsonDecode(utf8.decode(res.bodyBytes)), df);
  } else {
    throw Exception('Request failed: ${res.statusCode}');
  }
}
