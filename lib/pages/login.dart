import 'package:flutter/material.dart';
import 'package:strollplanner_tracker/config.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () async {
            var url = '${AppConfig.of(context).appBaseApiUrl}/magic-login';
            if (await canLaunch(url)) {
              await launch(
                url,
                forceSafariVC: false,
              );
            } else {
              throw 'Could not launch $url';
            }
          },
          child: Text(
            'Login',
          ),
        )
      ],
    ));
  }
}
