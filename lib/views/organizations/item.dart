import 'package:flutter/material.dart';
import 'package:strollplanner_tracker/models/org.dart';
import 'package:strollplanner_tracker/views/routes/list.dart';

class OrganizationItem extends StatelessWidget {
  final Organization org;

  OrganizationItem(this.org);

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 5,
              blurRadius: 7,
              offset:
              Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: ListTile(
          leading: Image.network(org.logoUrl),
          title: Text(org.name),
          contentPadding: EdgeInsets.all(10),
          tileColor: Colors.white,
          trailing: Icon(Icons.keyboard_arrow_right_outlined, size: 40, color: Colors.black87),
        ),
      ),
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