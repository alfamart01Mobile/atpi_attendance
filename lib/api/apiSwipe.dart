import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future insertSwipe(data) async {
  print('REQUEST API...');
  const subUrl = '/attendance/insert-swipe';
  var url = Uri.http(dotenv.env['API_URL']!, subUrl);
  var response = await http.post(url, body: data);
  try {
    return jsonDecode(response.body);
  } catch (e) {
    return {'RETURN': -2, 'MESSAGE': 'Problem found upon submission.'};
  }
}
