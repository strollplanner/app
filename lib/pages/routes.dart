import 'dart:async';

import 'package:flutter/material.dart';
import 'package:strollplanner_tracker/config.dart';
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
  final String id;
  final String title;
  final String publishedAt;
  final String canceledAt;
  final double totalLength;

  get published => publishedAt != null;

  get canceled => canceledAt != null;

  Route(
      {this.id,
      this.title,
      this.publishedAt,
      this.totalLength,
      this.canceledAt});

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      id: json["id"],
      title: json["title"],
      publishedAt: json["publishedAt"],
      totalLength: double.parse(json["totalLength"].toString()),
      canceledAt: json["canceledAt"],
    );
  }
}

String formatDistance(double d) {
  if (d == null) {
    return '??';
  }

  const precision = 1;

  if (d > 1000) {
    return "${(d / 1000).toStringAsFixed(precision)} km";
  }

  return "${d.toStringAsFixed(precision)} m";
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
                    return RouteItem(
                        key: ValueKey(route.id),
                        orgId: this.orgId,
                        route: route);
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
    query (\$orgId: ID!) {
      organization(id: \$orgId) {
        routes(first: 10, after: "") {
          edges {
            node {
              id
              title
              publishedAt
              canceledAt
              totalLength
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

class RouteItem extends StatelessWidget {
  final String orgId;
  final Route route;

  const RouteItem({Key key, this.orgId, this.route}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Stack(children: [
          Container(
              child: Column(children: [
                Container(
                    child: Text(route.title,
                        style: Theme.of(context).textTheme.headline6),
                    padding: EdgeInsets.all(10)),
                Row(
                  children: [
                    Image.network(
                        "${AppConfig.of(context).apiBaseApiUrl}/orgs/$orgId/routes/${route.id}/static/simplified/150/150"),
                    Container(
                        child: Column(
                          children: [
                            Text(formatDistance(route.totalLength)),
                            route.published
                                ? route.canceled
                                    ? Chip(
                                        label: Text(
                                          "Canceled",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText1
                                              .copyWith(color: Colors.white),
                                        ),
                                        backgroundColor: Colors.red,
                                      )
                                    : Chip(
                                        label: Text(
                                          "Published",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText1
                                              .copyWith(color: Colors.white),
                                        ),
                                        backgroundColor: Colors.green,
                                      )
                                : Chip(
                                    label: Text(
                                      "Not Published",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyText1
                                          .copyWith(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.grey[500],
                                  ),
                          ],
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        ),
                        padding: EdgeInsets.all(10))
                  ],
                )
              ], crossAxisAlignment: CrossAxisAlignment.stretch),
              color: Colors.white),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrackPage(this.orgId, route.id),
                    ),
                  );
                },
              ),
            ),
          )
        ]),
        margin: EdgeInsets.only(bottom: 20));
  }
}
