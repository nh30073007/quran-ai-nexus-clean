class News {
  final int? id;
  final String title;
  final String description;
  final String? image;
  final String? url;
  final String source;
  final String addedAt;

  News({
    this.id,
    required this.title,
    required this.description,
    this.image,
    this.url,
    required this.source,
    required this.addedAt,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      image: json['image'],
      url: json['url'],
      source: json['source'] ?? '',
      addedAt: json['added_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image': image,
      'url': url,
      'source': source,
      'added_at': addedAt,
    };
  }
}