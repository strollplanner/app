import 'dart:async';

import 'package:flutter/material.dart';
import 'package:strollplanner_tracker/pages/track.dart';
import 'package:strollplanner_tracker/services/auth.dart';
import 'package:strollplanner_tracker/services/gql.dart';

class RoutesPage extends StatefulWidget {
  final String orgId;

  RoutesPage(this.orgId);

  @override
  State<RoutesPage> createState() => _RoutesPageState(this.orgId);
}

class Route {
  String id;
  String title;

  Route({this.id, this.title});

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      id: json["id"],
      title: json["title"],
    );
  }
}

List<Route> routesFromJson(Map<String, dynamic> json) {
  List<dynamic> edges = json["organization"]["routes"]["edges"];

  return edges.map((e) => Route.fromJson(e["node"])).toList();
}

class _RoutesPageState extends State<RoutesPage> {
  final String orgId;

  List<Route> routes;

  _RoutesPageState(this.orgId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Routes"),
        ),
        body: routes == null
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                child: ListView.builder(
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    var route = routes[index];
                    return ListTile(
                      title: Text(route.title),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TrackPage(this.orgId, route.id),
                          ),
                        );
                      },
                    );
                  },
                ),
                onRefresh: fetchRoutes,
              ));
  }

  Future fetchRoutes() async {
    setState(() {
      this.routes = null;
    });

    var res = await AuthService.of(context, listen: false).request(
        context,
        """
    query Organizations(\$orgId: ID!) {
      organization(id: \$orgId) {
        routes(first: 10, after: "") {
          edges {
            node {
              id
              title
            }
          }
        }
      }
    }
    """,
        routesFromJson,
        variables: {"orgId": this.orgId});

    setState(() {
      this.routes = res.data;
    });
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      fetchRoutes();
    });
  }
}
