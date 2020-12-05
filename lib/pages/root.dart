import 'package:provider/provider.dart';
import 'package:strollplanner_tracker/pages/organizations.dart';
import 'package:strollplanner_tracker/pages/track.dart';
import 'package:strollplanner_tracker/pages/update.dart';
import 'package:strollplanner_tracker/services/auth.dart';
import 'package:flutter/material.dart';

Widget root() {
  return ChangeNotifierProvider<AuthService>(
    child: RootPage(),
    create: (context) => AuthService(context),
  );
}

class RootPage extends StatelessWidget {
  MaterialColor createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    strengths.forEach((strength) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    });
    return MaterialColor(color.value, swatch);
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StrollPlanner',
      theme: ThemeData(
        primarySwatch: createMaterialColor(Color(0xFF005DCC)),
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Material(
          child: UpdatePage.build(
              AuthWidget(TrackSessionRedirector(OrganizationsPage())))),
    );
  }
}
