import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:strollplanner_tracker/config.dart';
import 'package:strollplanner_tracker/services/gql.dart' as gql;
import 'package:uni_links/uni_links.dart';
import 'package:strollplanner_tracker/models/user.dart';

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
  BuildContext context;

  AuthService(this.context) {
    initUriUniLinks();
  }

  StreamSubscription _sub;

  User currentUser;

  static AuthService of(BuildContext context, {bool listen = true}) {
    return Provider.of<AuthService>(context, listen: listen);
  }

  Future logout() async {
    this.currentUser = null;
    final _storage = FlutterSecureStorage();
    await _storage.delete(key: "token");
    notifyListeners();
    return;
  }

  static Future<String> getToken() async {
    final _storage = FlutterSecureStorage();
    return await _storage.read(key: "token");
  }

  Future<gql.Response<D>> request<D>(
      BuildContext context, String query, gql.DataFactory<D> df,
      {Map<String, Object> variables}) async {
    var config = AppConfig.of(context);

    return gql.request(config, query, df,
        variables: variables, token: await getToken());
  }

  Future storeToken(String token) async {
    this.currentUser = null;
    final _storage = FlutterSecureStorage();
    await _storage.write(key: "token", value: token);
    notifyListeners();
  }

  Future<User> fetchUser() async {
    print("fetch user");
    final _storage = FlutterSecureStorage();

    if (!await _storage.containsKey(key: "token")) {
      print("token doesnt exist");
      return null;
    }

    var res = await request<ViewerData>(
        context,
        """
    query {
      viewer {
        id
        email
        isAdmin
      }
    } 
""",
        (m) => ViewerData.fromJson(m));

    var viewer = res?.data?.viewer;

    if (viewer == null) {
      print("viewer is null");

      return logout();
    }

    this.currentUser = viewer;

    return viewer;
  }

  @override
  dispose() {
    if (_sub != null) _sub.cancel();
    super.dispose();
  }

  handleUri(Uri uri) async {
    switch (uri.pathSegments[0]) {
      case "login":
        var token = uri.queryParameters["token"];

        await storeToken(token);
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

    _sub = getUriLinksStream().listen((Uri uri) {
      handleUri(uri);
    }, onError: (err) {
      print('uri err: $err');
    });
  }
}
