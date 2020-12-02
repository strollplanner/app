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
    super.dispose();
  }

  void toggleTracker() async {
    if (_running) {
      BackgroundLocation.stopLocationService();
      setState(() {
        _running = false;
      });
      return;
    }

    startTracker();
  }

  void startTracker() {
    BackgroundLocation.startLocationService();

    setState(() {
      _running = true;
    });

    BackgroundLocation.getLocationUpdates((location) {
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
    return;
    var token = Provider
        .of<AuthService>(context, listen: false)
        .token;

    await request(
        """
    mutation (\$orgId: ID!, \$id: ID!, \$lat: Float!, \$lng: Float!, \$acc: Float!) {
			  tracker(organizationId: \$orgId, id: \$id, input: {
					lat: \$lat,
					lng: \$lng,
					acc: \$acc,
				})
			}
    """,
        token,
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Tracker"),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: _permGranted
            ? Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
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
                style: Theme
                    .of(context)
                    .textTheme
                    .headline4,
              ),
            ]),
            RaisedButton(
                onPressed: this.toggleTracker,
                color: _running ? Colors.red : Colors.green,
                child: Text(_running ? 'Stop' : 'Start'))
          ],
        )
            : GrantPermission(),
      ),
    );
  }

  void updateGrantedPerm() async {
    var granted = await Permission.locationAlways.isGranted;
    setState(() {
      _permGranted = granted;
    });
  }
}
