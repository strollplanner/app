import 'package:flutter/material.dart';
import 'package:strollplanner_tracker/config.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 0),
        Image(image: AssetImage('assets/icon.png'), width: 100),
        ElevatedButton(
          onPressed: () async {
            var url = '${AppConfig.of(context).appBaseUrl}/magic-login';
            if (await canLaunch(url)) {
              await launch(
                url,
                forceSafariVC: false,
              );
            } else {
              throw 'Could not launch $url';
            }
          },
          style: ElevatedButton.styleFrom(padding: EdgeInsets.all(15)),
          child: Text(
            'LOGIN',
            style: new TextStyle(
              fontSize: 20.0,
            ),
          ),
        ),
      ],
    );
  }
}
