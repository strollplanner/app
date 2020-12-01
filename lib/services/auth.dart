import 'dart:async';
import 'package:flutter/material.dart';
import 'package:strollplanner_tracker/services/gql.dart';
import 'package:uni_links/uni_links.dart';

class User {
  String id;
  String email;

  User({this.id, this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      return null;
    }

    return User(
      id: json['id'],
      email: json['email'],
    );
  }
}

class ViewerData {
  User viewer;

  ViewerData({this.viewer});

  factory ViewerData.fromJson(Map<String, dynamic> json) {
    return ViewerData(
      viewer: User.fromJson(json['viewer']),
    );
  }
}

class AuthService with ChangeNotifier {
  StreamSubscription _sub;
  User currentUser;
  var token;

  AuthService() {
    initUriUniLinks();
  }

  Future getUser() {
    return Future.value(currentUser);
  }

  Future logout() {
    this.currentUser = null;
    this.token = null;
    notifyListeners();
    return Future.value(null);
  }

  Future login({String token}) async {
    var res = await request<ViewerData>("""
    query {
      viewer {
        id
        email
      }
    }
""", token, (m) => ViewerData.fromJson(m));

    if (res.data.viewer == null) {
      print("viewer is null");

      return logout();
    }

    this.token = token;
    this.currentUser = res.data.viewer;
    notifyListeners();
    return Future.value(currentUser);
  }

  @override
  dispose() {
    if (_sub != null) _sub.cancel();
    super.dispose();
  }

  handleUri(Uri uri) {
    switch (uri.pathSegments[0]) {
      case "login":
        var token = uri.queryParameters["token"];

        login(token: token);
        break;
      default:
        print("Unhandled uri: $uri");
    }
  }

  initUriUniLinks() async {
    // var uri = await getInitialUri();
    // if (uri != null) {
    //   handleUri(uri);
    // }

    getUriLinksStream().listen((Uri uri) {
      handleUri(uri);
    }, onError: (err) {
      print('uri err: $err');
    });
  }
}
