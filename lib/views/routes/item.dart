import 'package:flutter/material.dart' hide Route;
import 'package:strollplanner_tracker/config.dart';
import 'package:strollplanner_tracker/views/track.dart';
import 'package:strollplanner_tracker/models/route.dart';

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

class RouteItem extends StatelessWidget {
  final String orgId;
  final Route route;

  const RouteItem({Key key, this.orgId, this.route}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
        color: Colors.white,
      ),
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
                    "${AppConfig.of(context).apiBaseUrl}/orgs/$orgId/routes/${route.id}/static/simplified/300/300",
                    width: 150,
                  ),
                  Container(
                      child: Column(
                        children: [
                          Text(formatDistance(route.totalLength)),
                          SizedBox(height: 20),
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
            ], crossAxisAlignment: CrossAxisAlignment.stretch)),
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
    );
  }
}
