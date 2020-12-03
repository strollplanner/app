import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:background_location/background_location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:strollplanner_tracker/services/auth.dart';
import 'package:strollplanner_tracker/services/gql.dart';

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

  Location _location;
  bool _running = false;
  bool _permGranted = false;
  bool postLocation = true;
  int count = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    Future.delayed(Duration.zero, () {
      updateGrantedPerm();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stopTracker();
    super.dispose();
  }

  Future stopTracker() async {
    await BackgroundLocation.stopLocationService();
    if (mounted) {
      setState(() {
        _running = false;
      });
    }
  }

  void toggleTracker() async {
    if (_running) {
      stopTracker();
      return;
    }

    startTracker();
  }

  void startTracker() async {
    await BackgroundLocation.startLocationService();

    setState(() {
      _running = true;
    });

    await BackgroundLocation.getLocationUpdates((location) {
      print(location);

      logPosition(location);

      setState(() {
        // This call to setState tells the Flutter framework that something has
        // changed in this State, which causes it to rerun the build method below
        // so that the display can reflect the updated values. If we changed
        // _counter without calling setState(), then the build method would not be
        // called again, and so nothing would appear to happen.
        _location = location;
      });
    });
  }

  void logPosition(Location location) async {
    setState(() {
      this.count++;
    });

    if (!postLocation) {
      return;
    }

    print("Posting to backend");

    await request(
        context,
        """
    mutation (\$orgId: ID!, \$id: ID!, \$lat: Float!, \$lng: Float!, \$acc: Float!) {
			  tracker(organizationId: \$orgId, id: \$id, input: {
					lat: \$lat,
					lng: \$lng,
					acc: \$acc,
				})
			}
    """,
        (_) => null,
        variables: {
          "orgId": this.orgId,
          "id": this.routeId,
          "lat": location.latitude,
          "lng": location.longitude,
          "acc": location.accuracy,
        });
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
                      Text('You may close the app, tracking will continue in the background.'),
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
                      await stopTracker();
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
        child:Scaffold(
      appBar: AppBar(
        title: Text("Tracker"),
      ),
      body: Center(
        child: _permGranted
            ? Column(
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
                    isAdmin
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
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
                          )
                        : null
                  ]),
                  RaisedButton(
                      onPressed: this.toggleTracker,
                      color: _running ? Colors.red : Colors.green,
                      child: Text(_running ? 'Stop' : 'Start')),
                  isAdmin ? Text("$count") : null
                ],
              )
            : GrantPermission(),
      ),
    ));
  }

  void updateGrantedPerm() async {
    var granted = await Permission.locationAlways.isGranted;
    setState(() {
      _permGranted = granted;
    });
  }
}
