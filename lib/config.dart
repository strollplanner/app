import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

class AppConfig {
  AppConfig({
    @required this.flavorName,
    @required this.apiBaseUrl,
    @required this.appBaseUrl,
  });

  final String flavorName;
  final String apiBaseUrl;
  final String appBaseUrl;

  static const _releaseTag =
      String.fromEnvironment('RELEASE_TAG', defaultValue: '');

  get releaseTag => _releaseTag;

  factory AppConfig.init({
    @required flavorName,
    @required basePlatformUrl,
  }) {
    var app = Uri.parse(basePlatformUrl);
    app = app.replace(host: "app.${app.host}");

    var api = Uri.parse(basePlatformUrl);
    api = api.replace(host: "api.${api.host}");

    return AppConfig(
        flavorName: flavorName,
        apiBaseUrl: api.toString(),
        appBaseUrl: app.toString());
  }

  factory AppConfig.of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppConfigWidget>().config;
  }

  Map<String, dynamic> toMap() {
    return {
      'flavorName': flavorName,
      'apiBaseUrl': apiBaseUrl,
      'appBaseUrl': appBaseUrl,
    };
  }

  factory AppConfig.fromMap(dynamic m) {
    return AppConfig(
        flavorName: m['flavorName'],
        apiBaseUrl: m['apiBaseUrl'],
        appBaseUrl: m['appBaseUrl']);
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
