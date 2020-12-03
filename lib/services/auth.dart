import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strollplanner_tracker/pages/login.dart';
import 'package:strollplanner_tracker/services/gql.dart';
import 'package:uni_links/uni_links.dart';

class User {
  String id;
  String email;
  bool isAdmin;

  User({this.id, this.email, this.isAdmin});

  factory User.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      return null;
    }

    return User(id: json['id'], email: json['email'], isAdmin: json['isAdmin']);
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

class AuthWidget extends StatelessWidget {
  final Widget child;

  AuthWidget(this.child);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // get the Provider, and call the getUser method
      future: AuthService.of(context).getUser(),
      // wait for the future to resolve and render the appropriate
      // widget for HomePage or LoginPage
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return snapshot.hasData ? child : LoginPage();
        } else {
          return Material(
              child: Column(
            children: [CircularProgressIndicator()],
          ));
        }
      },
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
  var token;

  static AuthService of(BuildContext context, {bool listen = true}) {
    return Provider.of<AuthService>(context, listen: listen);
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

  Future login(String token, User user) async {
    this.token = token;
    this.currentUser = user;
    notifyListeners();
    return Future.value(currentUser);
  }

  void loginRequest(String token) async {
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
        (m) => ViewerData.fromJson(m),
        token: token);

    var viewer = res.data.viewer;

    if (viewer == null) {
      print("viewer is null");

      return logout();
    }

    login(token, viewer);
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

        loginRequest(token);
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
