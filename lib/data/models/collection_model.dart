class CollectionModel {
  final int? id;
  final String name;
  final String? color;
  final String? coverImage;
  final String createdAt;

  CollectionModel({
    this.id,
    required this.name,
    this.color,
    this.coverImage,
    required this.createdAt,
  });

  factory CollectionModel.fromMap(Map<String, dynamic> map) {
    return CollectionModel(
      id: map['id'],
      name: map['name'],
      color: map['color'],
      coverImage: map['cover_image'],
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'cover_image': coverImage,
      'created_at': createdAt,
    };
  }
}
