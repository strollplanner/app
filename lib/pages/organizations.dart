import 'package:flutter/material.dart';
import 'package:strollplanner_tracker/pages/routes.dart';
import 'package:strollplanner_tracker/services/auth.dart';

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
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                child: ListView.separated(
                  itemCount: organizations.length,
                  itemBuilder: (context, index) {
                    var org = organizations[index];

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
                                  builder: (context) => RoutesPage(org.id),
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    ]);
                  },
                  separatorBuilder: (context, index) => SizedBox(height: 20),
                ),
                onRefresh: fetchOrganizations,
              ));
  }

  Future fetchOrganizations() async {
    setState(() {
      this.organizations = null;
    });

    var res = await AuthService.of(context, listen: false).request(
        context,
        """
    query {
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

  void initPlatformState() async {
    fetchOrganizations();
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      initPlatformState();
    });
  }
}
