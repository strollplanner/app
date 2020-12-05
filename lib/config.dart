import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

class AppConfig {
  AppConfig({
    @required this.flavorName,
    @required this.apiBaseApiUrl,
    @required this.appBaseApiUrl,
  });

  final String flavorName;
  final String apiBaseApiUrl;
  final String appBaseApiUrl;

  static const _releaseTag =
      String.fromEnvironment('RELEASE_TAG', defaultValue: '');

  get releaseTag => _releaseTag;

  static AppConfig of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppConfigWidget>().config;
  }

  Map<String, dynamic> toMap() {
    return {
      'flavorName': flavorName,
      'apiBaseApiUrl': apiBaseApiUrl,
      'appBaseApiUrl': appBaseApiUrl,
    };
  }

  factory AppConfig.fromMap(dynamic m) {
    return AppConfig(
        flavorName: m['flavorName'],
        apiBaseApiUrl: m['apiBaseApiUrl'],
        appBaseApiUrl: m['appBaseApiUrl']);
  }
}

class AppConfigWidget extends InheritedWidget {
  AppConfigWidget({
    @required this.config,
    @required Widget child,
  }) : super(child: child);

  final AppConfig config;

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;
}
