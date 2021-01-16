class Route {
  final String id;
  final String title;
  final String publishedAt;
  final String canceledAt;
  final double totalLength;

  get published => publishedAt != null;

  get canceled => canceledAt != null;

  Route(
      {this.id,
        this.title,
        this.publishedAt,
        this.totalLength,
        this.canceledAt});

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      id: json["id"],
      title: json["title"],
      publishedAt: json["publishedAt"],
      totalLength: double.parse(json["totalLength"].toString()),
      canceledAt: json["canceledAt"],
    );
  }
}
