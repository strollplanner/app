import 'package:flutter/material.dart';
import 'package:strollplanner_tracker/models/org.dart';
import 'package:strollplanner_tracker/views/organizations/item.dart';
import 'package:strollplanner_tracker/services/auth.dart';

class OrganizationsPage extends StatefulWidget {
  @override
  State<OrganizationsPage> createState() => _OrganizationsPageState();
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
    print(organizations?.length);
    return SafeArea(
        child: Column(
      children: [
        Row(
          children: [
            Flexible(flex: 15, child: Container()),
            Flexible(
                flex: 70,
                child: Container(
                  child: Image.asset(
                    "assets/logo.png",
                    fit: BoxFit.cover,
                  ),
                  padding: EdgeInsets.all(30),
                )),
            Flexible(
                flex: 15,
                child: IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        // return object of type Dialog
                        return AlertDialog(
                          title: new Text("Are you sure you want to logout?"),
                          actions: <Widget>[
                            new FlatButton(
                              child: new Text("Cancel"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            new FlatButton(
                              child: new Text("Logout"),
                              onPressed: () {
                                AuthService.of(context, listen: false).logout();
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                )),
          ],
        ),
        Expanded(
            child: organizations == null
                ? Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    child: ListView.separated(
                      itemCount: organizations.length,
                      itemBuilder: (_, index) =>
                          OrganizationItem(organizations[index]),
                      separatorBuilder: (_, index) => SizedBox(height: 20),
                    ),
                    onRefresh: fetchOrganizations,
                  ))
      ],
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
