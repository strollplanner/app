import 'package:strollplanner_tracker/pages/organizations.dart';
import 'package:strollplanner_tracker/pages/routes.dart';
import 'package:strollplanner_tracker/services/auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:strollplanner_tracker/pages/login.dart';
import 'package:strollplanner_tracker/pages/track.dart';

class RootPage extends StatefulWidget {
  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StrollPlanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FutureBuilder(
        // get the Provider, and call the getUser method
        future: Provider.of<AuthService>(context).getUser(),
        // wait for the future to resolve and render the appropriate
        // widget for HomePage or LoginPage
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return snapshot.hasData ? OrganizationsPage() : LoginPage();
          } else {
            return Material(
                child: Column(
              children: [CircularProgressIndicator()],
            ));
          }
        },
      ),
    );
  }
}
