import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';

final options = BaseOptions(
  baseUrl: 'http://${dotenv.env['API_URL']}',
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 30),
);

final dio = Dio(options);

Future apiRequest(url, data) async {
  try {
    var response = await dio.post(url, data: FormData.fromMap(data));
    return response.data;
  } catch (e) {
    if (kDebugMode) {
      print('HTTP ERROR: $e');
    }
    return {'RETURN': -200, 'MESSAGE': 'Server connection failed!.'};
  }
}

Future getDeviceInfo(data) async {
  return await apiRequest('/attendance/get-location', data);
}

Future getEmployee(data) async {
  return await apiRequest('/attendance/get-employee', data);
}

Future insertEmployeeRegister(data) async {
  return await apiRequest('/attendance/insert-employee-register', data);
}

Future insertSwipe(data) async {
  return await apiRequest('/attendance/insert-swipe', data);
}
