import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:strollplanner_tracker/config.dart';
import 'package:strollplanner_tracker/views/auth.dart';
import 'package:strollplanner_tracker/views/organizations/list.dart';
import 'package:strollplanner_tracker/views/track.dart';
import 'package:strollplanner_tracker/views/update.dart';
import 'package:strollplanner_tracker/services/auth.dart';
import 'package:flutter/material.dart';

Future runRoot({config: AppConfig}) async {
  var app = AppConfigWidget(
    config: config,
    child: ChangeNotifierProvider<AuthService>(
      child: RootPage(),
      create: (context) => AuthService(context),
    ),
  );

  if (kReleaseMode) {
    return SentryFlutter.init(
      (options) => options
        ..dsn =
            'https://efe61439a63446f78bcc661a4489dde3@o44685.ingest.sentry.io/5546076'
        ..environment = config.flavorName,
      appRunner: () => runApp(app),
    );
  }

  return runApp(app);
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
          backgroundColor: Colors.white),
      home: Material(
          child: UpdatePage.build(
              AuthWidget(TrackSessionRedirector(OrganizationsPage())))),
    );
  }
}
