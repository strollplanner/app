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
