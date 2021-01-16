class User {
  String id;
  String email;
  bool isAdmin;

  User({this.id, this.email, this.isAdmin});

  factory User.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      return null;
    }

    return User(id: json['id'], email: json['email'], isAdmin: json['isAdmin']);
  }
}
