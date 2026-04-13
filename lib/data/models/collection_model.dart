// lib/data/models/collection_model.dart

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

  CollectionModel copyWith({
    int? id,
    String? name,
    String? color,
    Object? coverImage = _sentinel,
    String? createdAt,
  }) {
    return CollectionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      coverImage: coverImage == _sentinel
          ? this.coverImage
          : coverImage as String?,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static const _sentinel = Object();
}

class CollectionWithCount extends CollectionModel {
  final int bookmarkCount;

  CollectionWithCount({
    required super.id,
    required super.name,
    super.color,
    super.coverImage,
    required super.createdAt,
    required this.bookmarkCount,
  });
}
