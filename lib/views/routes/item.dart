import 'package:flutter/material.dart' hide Route;
import 'package:strollplanner_tracker/config.dart';
import 'package:strollplanner_tracker/views/routes/route_status.dart';
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

class RouteItemTile extends StatelessWidget {
  final String orgId;
  final Route route;

  const RouteItemTile({Key key, this.orgId, this.route}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            ShaderMask(
              blendMode: BlendMode.dstOut,
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: [0.4, 1.0],
                        colors: [Colors.transparent, Colors.white])
                    .createShader(bounds);
              },
              child: Image.network(
                "${AppConfig.of(context).apiBaseUrl}/orgs/$orgId/routes/${route.id}/static/simplified/300/300",
                width: 150,
                height: 150,
              ),
            ),
            Positioned.fill(
                left: 100,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(route.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20)),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RouteStatus(route: this.route),
                          SizedBox(width: 5),
                          Text(formatDistance(route.totalLength))
                        ],
                      )
                    ],
                  ),
                ))
          ],
        )
      ],
    );
  }
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
        RouteItemTile(orgId: orgId, route: route),
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
