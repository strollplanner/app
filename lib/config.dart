import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

class AppConfig extends InheritedWidget {
  AppConfig({
    @required this.flavorName,
    @required this.apiBaseApiUrl,
    @required this.appBaseApiUrl,
    @required Widget child,
  }) : super(child: child);

  final String flavorName;
  final String apiBaseApiUrl;
  final String appBaseApiUrl;

  static AppConfig of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppConfig>();
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;
}
