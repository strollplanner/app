import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:background_locator/location_dto.dart';
import 'package:background_locator/settings/android_settings.dart';
import 'package:background_locator/settings/ios_settings.dart';
import 'package:background_locator/settings/locator_settings.dart';
import 'package:flutter/material.dart';
import 'package:background_locator/background_locator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strollplanner_tracker/config.dart';
import 'package:strollplanner_tracker/services/auth.dart';
import 'package:strollplanner_tracker/services/tracker.dart';

class TrackSessionRedirector extends StatelessWidget {
  final Widget child;

  TrackSessionRedirector(this.child);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: fetchSession(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [CircularProgressIndicator()]);
          }

          return child;
        });
  }

  Future fetchSession(BuildContext context) async {
    var s = await LocationCallbackHandler.getSession();
    print("Session: ${s?.toMap()}");

    if (s == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackPage(s.orgId, s.routeId),
      ),
    );
  }
}

class GrantPermission extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var helpText = Text(
        'You must grant permission for the app to have access to the location:');

    if (Platform.isAndroid) {
      return Column(
        children: [
          helpText,
          Text('Press Permissions > Location > Allow all the time'),
          RaisedButton(
            onPressed: openAppSettings,
            child: Text('Open Settings'),
          )
        ],
      );
    } else if (Platform.isIOS) {
      return FutureBuilder(
          future: Permission.locationWhenInUse.isGranted,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data) {
                return Column(
                  children: [
                    helpText,
                    Text('Press Location > Always'),
                    RaisedButton(
                      onPressed: () async {
                        openAppSettings();
                      },
                      child: Text('Grant always permission'),
                    )
                  ],
                );
              } else {
                return Column(
                  children: [
                    helpText,
                    Text('Select Allow While in use'),
                    RaisedButton(
                      onPressed: () async {
                        await Permission.locationWhenInUse.request();
                      },
                      child: Text('Grant permission'),
                    )
                  ],
                );
              }
            }

            return CircularProgressIndicator();
          });
    } else {
      return Column(
        children: [
          helpText,
        ],
      );
    }
  }
}

class TrackPage extends StatefulWidget {
  final String orgId;
  final String routeId;

  TrackPage(this.orgId, this.routeId);

  @override
  _TrackPageState createState() => _TrackPageState(this.orgId, this.routeId);
}

class _TrackPageState extends State<TrackPage> with WidgetsBindingObserver {
  final String orgId;
  final String routeId;

  _TrackPageState(this.orgId, this.routeId);

  int _count;
  LocationDto _location;
  bool _running = false;
  bool _permGranted = false;
  bool postLocation = true;
  ReceivePort port = ReceivePort();

  @override
  void initState() {
    super.initState();

    if (IsolateNameServer.lookupPortByName(
            LocationServiceRepository.isolateName) !=
        null) {
      IsolateNameServer.removePortNameMapping(
          LocationServiceRepository.isolateName);
    }

    IsolateNameServer.registerPortWithName(
        port.sendPort, LocationServiceRepository.isolateName);

    port.listen(
      (dynamic data) async {
        await updateUI(data);
      },
    );
    initPlatformState();
  }

  Future<void> updateUI(LocationUpdate data) async {
    updateRunning();
    if (data != null) {
      setState(() {
        _location = data.location;
        _count = data.count;
      });
    } else {
      setState(() {
        _location = null;
        _count = null;
      });
    }
  }

  void updateRunning() async {
    var running = await BackgroundLocator.isServiceRunning();
    setState(() {
      this._running = running;
    });
  }

  void initPlatformState() async {
    await BackgroundLocator.initialize();
    updateGrantedPerm();
    updateRunning();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    IsolateNameServer.removePortNameMapping(
        LocationServiceRepository.isolateName);
    super.dispose();
  }

  Future stopTracker() async {
    await BackgroundLocator.unRegisterLocationUpdate();
  }

  void toggleTracker() async {
    if (_running) {
      stopTracker();
      return;
    }

    startTracker();
  }

  void startTracker() async {
    const distanceFilter = 0.0;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        "session", jsonEncode(Session(this.orgId, this.routeId).toMap()));

    Map<String, dynamic> data = {
      'count': 1,
      'orgId': this.orgId,
      'routeId': this.routeId,
      'config': AppConfig.of(context).toMap(),
      'token': await AuthService.getToken(),
      'postBackend': postLocation,
    };
    await BackgroundLocator.registerLocationUpdate(
        LocationCallbackHandler.callback,
        initCallback: LocationCallbackHandler.initCallback,
        initDataCallback: data,
        disposeCallback: LocationCallbackHandler.disposeCallback,
        autoStop: false,
        iosSettings: IOSSettings(
            accuracy: LocationAccuracy.NAVIGATION,
            distanceFilter: distanceFilter,
            showsBackgroundLocationIndicator: true),
        androidSettings: AndroidSettings(
            accuracy: LocationAccuracy.NAVIGATION,
            interval: 5,
            distanceFilter: distanceFilter,
            wakeLockTime: 2147483647 /* max value */,
            androidNotificationSettings: AndroidNotificationSettings(
                notificationChannelName: 'Location tracking',
                notificationTitle: 'Location Tracking',
                notificationMsg: 'Location tracker running in the background',
                notificationBigMsg:
                    'Location tracker is running in the background',
                notificationIcon: 'assets/icon.png',
                notificationIconColor: Colors.grey,
                notificationTapCallback:
                    LocationCallbackHandler.notificationCallback)));
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      updateGrantedPerm();
    }
  }

  @override
  Widget build(BuildContext context) {
    var isAdmin = AuthService.of(context).currentUser.isAdmin;

    return WillPopScope(
        onWillPop: () async {
          if (!_running) {
            return true;
          }

          showDialog<void>(
            context: context,
            barrierDismissible: false, // user must tap button!
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Tracking in progress'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      Text('Leaving this page will stop the tracking'),
                      Text(
                          'You may close the app, tracking will continue in the background.'),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('Continue'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  TextButton(
                    child: Text('Leave'),
                    onPressed: () async {
                      stopTracker();
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          );

          return false;
        },
        child: Scaffold(
          appBar: AppBar(
              title: Text("Tracker"),
              actions: isAdmin
                  ? <Widget>[
                      FlatButton(
                        textColor: Colors.white,
                        onPressed: () async {
                          await showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return StatefulBuilder(builder:
                                    (BuildContext context,
                                        StateSetter setState) {
                                  return Column(children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Checkbox(
                                            value: postLocation,
                                            onChanged: (v) {
                                              setState(() {
                                                this.postLocation = v;
                                              });
                                            }),
                                        Text("Post to backend ?"),
                                      ],
                                    ),
                                    Text("Count: $_count")
                                  ]);
                                });
                              });
                        },
                        child: Text("Admin"),
                        shape: CircleBorder(
                            side: BorderSide(color: Colors.transparent)),
                      ),
                    ]
                  : []),
          body: Center(child: Builder(builder: (BuildContext context) {
            if (!_permGranted) {
              return GrantPermission();
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Column(children: [
                  Text(
                    'Last position:',
                  ),
                  Text(
                    _location == null
                        ? 'N/A'
                        : '${_location.latitude} ${_location.longitude}',
                    style: Theme.of(context).textTheme.headline4,
                  ),
                ]),
                RaisedButton(
                    onPressed: this.toggleTracker,
                    color: _running ? Colors.red : Colors.green,
                    child: Text(_running ? 'Stop' : 'Start')),
              ],
            );
          })),
        ));
  }

  void updateGrantedPerm() async {
    var granted = await Permission.locationAlways.isGranted;
    setState(() {
      _permGranted = granted;
    });
  }
}
