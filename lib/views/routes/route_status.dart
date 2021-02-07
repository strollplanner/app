import 'package:flutter/material.dart' hide Route;
import 'package:strollplanner_tracker/models/route.dart';

class RouteStatus extends StatelessWidget {
  final Route route;

  const RouteStatus({Key key, this.route}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (route.published) {
      if (route.canceled) {
        return Icon(Icons.close_rounded, color: Colors.red);
      }

      return Container();
    }

    return Icon(Icons.hourglass_bottom_outlined, color: Colors.grey[500]);
  }
}
