import 'package:flutter/material.dart';
import 'package:strollplanner_tracker/services/auth.dart';
import 'package:strollplanner_tracker/views/login.dart';

class AuthWidget extends StatelessWidget {
  final Widget child;

  AuthWidget(this.child);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AuthService.of(context).fetchUser(),
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return snapshot.hasData ? child : LoginPage();
        } else {
          return Material(child: Center(child: CircularProgressIndicator()));
        }
      },
    );
  }
}
