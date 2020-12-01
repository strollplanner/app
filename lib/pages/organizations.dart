import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strollplanner_tracker/constants.dart' as Constants;
import 'package:strollplanner_tracker/pages/routes.dart';
import 'package:strollplanner_tracker/pages/track.dart';
import 'package:strollplanner_tracker/services/auth.dart';
import 'package:strollplanner_tracker/services/gql.dart';
import 'package:url_launcher/url_launcher.dart';

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
                Provider.of<AuthService>(context, listen: false).logout();
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

    var token = Provider.of<AuthService>(context, listen: false).token;

    var res = await request("""
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
    """, token, organizationsFromJson);

    setState(() {
      this.organizations = res.data;
    });
  }

  @override
  void initState() {
    super.initState();
    // Future.delayed(Duration.zero,() {
    fetchOrganizations();
    // });
  }
}
