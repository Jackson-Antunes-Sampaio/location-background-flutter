import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:background_locator_2/location_dto.dart';
import 'package:dio/dio.dart';

import 'file_manager.dart';

class LocationServiceRepository {
  static final LocationServiceRepository _instance =
      LocationServiceRepository._();

  LocationServiceRepository._();

  factory LocationServiceRepository() {
    return _instance;
  }

  static const String isolateName = 'LocatorIsolate';

  int _count = -1;

  Future<void> init(Map<dynamic, dynamic> params) async {
    //TODO change logs
    print("***********Init callback handler");
    if (params.containsKey('countInit')) {
      dynamic tmpCount = params['countInit'];
      if (tmpCount is double) {
        _count = tmpCount.toInt();
      } else if (tmpCount is String) {
        _count = int.parse(tmpCount);
      } else if (tmpCount is int) {
        _count = tmpCount;
      } else {
        _count = -2;
      }
    } else {
      _count = 0;
    }
    print("$_count");
    await setLogLabel("start");
    final SendPort? send = IsolateNameServer.lookupPortByName(isolateName);
    send?.send(null);
  }

  Future<void> dispose() async {
    print("***********Dispose callback handler");
    print("$_count");
    await setLogLabel("end");
    final SendPort? send = IsolateNameServer.lookupPortByName(isolateName);
    send?.send(null);
  }

  Future<void> callback(LocationDto locationDto) async {
    print('$_count location in dart: ${locationDto.toString()}');
    await setLogPosition(_count, locationDto);
    final SendPort? send = IsolateNameServer.lookupPortByName(isolateName);
    send?.send(locationDto.toJson());
    _count++;
  }

  Future<void> getSend() async {}

  static Future<void> setLogLabel(String label) async {
    final date = DateTime.now().toUtc();
    await FileManager.writeToLogFile(
        '------------\n$label: $date\n------------\n');
  }

  static Future<void> getFilmes(LocationDto location) async {
    try{
      final dio = Dio();
      final response = await dio.post(
        'https://sandbox.pointservice.com.br/v1/ApiGis/set-location',
        data: {
          "userCode": 1118,
          "imei": "string",
          "latitude": location.latitude,
          "longitude": location.longitude,
          "version": "string"
        },
      );
      print('----------------------------------------------');
      print(response.requestOptions.data);
      print("status: ${response.statusCode}");
      print('----------------------------------------------');
    }catch(e){
      print('----------------------------------------------');
      print("status: $e");
      await FileManager.writeToLogFile(
          '------------\n$e\n------------\n');
      print('----------------------------------------------');
    }

  }

  static Future<void> setLogPosition(int count, LocationDto data) async {
    final date = DateTime.now().toUtc();
    getFilmes(data);

    await FileManager.writeToLogFile('$count;$date;${formatLog(data)}\n');
  }

  static double dp(double val, int places) {
    num mod = pow(10.0, places);
    return ((val * mod).round().toDouble() / mod);
  }

  static String formatDateLog(DateTime date) {
    return date.hour.toString() +
        ":" +
        date.minute.toString() +
        ":" +
        date.second.toString();
  }

  static String formatLog(LocationDto locationDto) {
    return dp(locationDto.latitude, 4).toString() +
        " " +
        dp(locationDto.longitude, 4).toString();
  }
}
