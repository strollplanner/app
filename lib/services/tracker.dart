import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:background_locator/background_locator.dart';
import 'package:background_locator/location_dto.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strollplanner_tracker/config.dart';
import 'package:strollplanner_tracker/services/gql.dart';

class LocationUpdate {
  final LocationDto location;
  final int count;

  LocationUpdate(this.location, this.count);
}

class Session {
  final String orgId;
  final String routeId;

  Session(this.orgId, this.routeId);

  Map<String, dynamic> toMap() {
    return {
      'orgId': orgId,
      'routeId': routeId,
    };
  }

  factory Session.fromMap(dynamic m) {
    return Session(m['orgId'], m['routeId']);
  }
}

class LocationServiceRepository {
  static LocationServiceRepository _instance = LocationServiceRepository._();

  LocationServiceRepository._();

  factory LocationServiceRepository() {
    return _instance;
  }

  static const String isolateName = 'LocatorIsolate';

  int _count = -1;
  AppConfig _config;
  String _token;
  String _orgId;
  String _routeId;
  bool _postBackend = false;

  Future<void> init(Map<dynamic, dynamic> params) async {
    print("start");
    dynamic tmpCount = params['count'];
    if (tmpCount is double) {
      _count = tmpCount.toInt();
    } else if (tmpCount is String) {
      _count = int.parse(tmpCount);
    } else if (tmpCount is int) {
      _count = tmpCount;
    } else {
      _count = -2;
    }

    _config = AppConfig.fromMap(params['config']);
    _token = params['token'] as String;
    _orgId = params['orgId'] as String;
    _routeId = params['routeId'] as String;
    _postBackend = params['postBackend'] as bool;

    print("$_count");
    final SendPort send = IsolateNameServer.lookupPortByName(isolateName);
    send?.send(null);
  }

  Future<void> dispose() async {
    print("end");
    final SendPort send = IsolateNameServer.lookupPortByName(isolateName);
    send?.send(null);
  }

  Future<void> callback(LocationDto location) async {
    print('$_count location: ${location.toString()}');
    final SendPort send = IsolateNameServer.lookupPortByName(isolateName);
    send?.send(LocationUpdate(location, _count));

    _count++;

    if (_postBackend) {
      print("Posting to backend");

      var variables = {
        "orgId": _orgId,
        "id": _routeId,
        "lat": location.latitude,
        "lng": location.longitude,
        "acc": location.accuracy,
        "time": DateTime.fromMillisecondsSinceEpoch(location.time.round())
            .toUtc()
            .toIso8601String(),
      };

      try {
        await request(
            _config,
            """
    mutation (\$orgId: ID!, \$id: ID!, \$lat: Float!, \$lng: Float!, \$acc: Float!, \$time: Time) {
			  tracker(organizationId: \$orgId, id: \$id, input: {
					lat: \$lat,
					lng: \$lng,
					acc: \$acc,
					time: \$time,
				})
			}
    """,
            (_) => null,
            variables: variables,
            token: _token);
      } catch (exception, stacktrace) {
        await Sentry.captureException(
          exception,
          stackTrace: stacktrace,
        );
      }
    }
  }
}

class LocationCallbackHandler {
  static Future<Session> getSession() async {
    if (!await BackgroundLocator.isServiceRunning()) {
      return null;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    var s = prefs.getString("session");

    if (s == null) {
      return null;
    }

    return Session.fromMap(jsonDecode(s));
  }

  static Future<void> initCallback(Map<dynamic, dynamic> params) async {
    LocationServiceRepository myLocationCallbackRepository =
        LocationServiceRepository();
    await myLocationCallbackRepository.init(params);
  }

  static Future<void> disposeCallback() async {
    LocationServiceRepository myLocationCallbackRepository =
        LocationServiceRepository();
    await myLocationCallbackRepository.dispose();
  }

  static Future<void> callback(LocationDto locationDto) async {
    LocationServiceRepository myLocationCallbackRepository =
        LocationServiceRepository();
    await myLocationCallbackRepository.callback(locationDto);
  }

  static Future<void> notificationCallback() async {
    print('***notificationCallback');
  }
}
