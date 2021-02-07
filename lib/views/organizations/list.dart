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
        Container(
          width: MediaQuery.of(context).size.width * 0.70,
          child: Image.asset(
            "assets/logo.png",
            fit: BoxFit.cover,
          ),
          padding: EdgeInsets.all(30),
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
