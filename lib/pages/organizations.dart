import 'package:flutter/material.dart';
import 'package:strollplanner_tracker/pages/routes.dart';
import 'package:strollplanner_tracker/pages/track.dart';
import 'package:strollplanner_tracker/services/auth.dart';
import 'package:strollplanner_tracker/services/gql.dart';
import 'package:strollplanner_tracker/services/tracker.dart';

class OrganizationsPage extends StatefulWidget {
  @override
  State<OrganizationsPage> createState() => _OrganizationsPageState();
}

class Organization {
  String id;
  String name;
  String logoUrl;

  Organization({this.id, this.name, this.logoUrl});

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json["id"],
      name: json["name"],
      logoUrl: json["logoUrl"],
    );
  }
}

List<Organization> organizationsFromJson(Map<String, dynamic> json) {
  List<dynamic> memberships = json["viewer"]["memberships"];

  return memberships
      .map((e) => Organization.fromJson(e["organization"]))
      .toList();
}

class _OrganizationsPageState extends State<OrganizationsPage> {
  List<Organization> organizations;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Organizations"),
          actions: <Widget>[
            FlatButton(
              textColor: Colors.white,
              onPressed: () {
                AuthService.of(context, listen: false).logout();
              },
              child: Text("Logout"),
              shape: CircleBorder(side: BorderSide(color: Colors.transparent)),
            ),
          ],
        ),
        body: organizations == null
            ? CircularProgressIndicator()
            : ListView.builder(
                itemCount: organizations.length,
                itemBuilder: (context, index) {
                  var org = organizations[index];
                  return ListTile(
                    leading: Image.network(org.logoUrl),
                    title: Text(org.name),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoutesPage(org.id),
                        ),
                      );
                    },
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: fetchOrganizations,
          tooltip: 'Refresh',
          child: Icon(Icons.refresh),
        ));
  }

  void fetchOrganizations() async {
    setState(() {
      this.organizations = null;
    });

    var res = await AuthService.of(context, listen: false).request(
        context,
        """
    query  {
      viewer {
        memberships {
          organization {
            id
            name
            logoUrl
          }
        }
      }
    }
    """,
        organizationsFromJson);

    setState(() {
      this.organizations = res.data;
    });
  }

  void redirectToSession() async {
    var s = await LocationCallbackHandler.getSession();
    print("Session: ${s?.toMap()}");

    if (s == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackPage(s.orgId, s.routeId),
      ),
    );
  }

  void initPlatformState() async {
    fetchOrganizations();
    redirectToSession();
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      initPlatformState();
    });
  }
}
