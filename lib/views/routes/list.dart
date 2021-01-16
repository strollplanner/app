import 'dart:async';
import 'package:flutter/material.dart' hide Route;
import 'package:strollplanner_tracker/models/org.dart';
import 'package:strollplanner_tracker/models/route.dart';
import 'package:strollplanner_tracker/services/auth.dart';
import 'package:strollplanner_tracker/views/routes/item.dart';

class RoutesPage extends StatefulWidget {
  final Organization org;

  RoutesPage(this.org);

  @override
  State<RoutesPage> createState() => _RoutesPageState(this.org);
}

List<Route> routesFromJson(Map<String, dynamic> json) {
  List<dynamic> edges = json["organization"]["routes"]["edges"];

  return edges.map((e) => Route.fromJson(e["node"])).toList();
}

class _RoutesPageState extends State<RoutesPage> {
  final Organization org;

  List<Route> routes;

  _RoutesPageState(this.org);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Image.network(
              this.org.logoUrl,
              fit: BoxFit.cover,
              height: 35.0,
            ),
            SizedBox(width: 20),
            Text(this.org.name)
          ],
        )),
        body: routes == null
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                child: ListView.separated(
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    var route = routes[index];
                    return RouteItem(
                        key: ValueKey(route.id),
                        orgId: this.org.id,
                        route: route);
                  },
                  separatorBuilder: (context, index) => SizedBox(height: 20),
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
        variables: {"orgId": this.org.id});

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
