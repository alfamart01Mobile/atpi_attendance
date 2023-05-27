import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future getEmployee(data) async {
  print('REQUEST API...');
  const subUrl = '/attendance/get-employee';
  var url = Uri.http(dotenv.env['API_URL']!, subUrl);
  var response = await http.post(url, body: data);

  return jsonDecode(response.body);
}
