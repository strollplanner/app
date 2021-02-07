import 'package:flutter/material.dart';
import 'package:strollplanner_tracker/models/org.dart';
import 'package:strollplanner_tracker/views/routes/list.dart';

class OrganizationItemTile extends StatelessWidget {
  final Organization org;

  OrganizationItemTile(this.org);

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 5,
              blurRadius: 10,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Row(
          children: [
            Image.network(org.logoUrl, height: 100, width: 100),
            Expanded(
                child: Container(
                    padding: EdgeInsets.all(10),
                    child: Text(org.name,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)))),
            Icon(Icons.keyboard_arrow_right_outlined,
                size: 40, color: Colors.black87),
          ],
        ));
  }
}

class OrganizationItem extends StatelessWidget {
  final Organization org;

  OrganizationItem(this.org);

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      OrganizationItemTile(org),
      Positioned.fill(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RoutesPage(org),
                ),
              );
            },
          ),
        ),
      )
    ]);
  }
}
