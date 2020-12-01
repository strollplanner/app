import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:strollplanner_tracker/pages/root.dart';
import 'package:strollplanner_tracker/services/auth.dart';

void main() {
  runApp(ChangeNotifierProvider<AuthService>(
    child: RootPage(),
    create: (context) => AuthService(),
  ));
}
