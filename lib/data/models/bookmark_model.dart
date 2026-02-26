// lib/data/models/bookmark_model.dart

class BookmarkModel {
  final int? id;
  final String? title;
  final String url;
  final String? notes;
  final String? image;
  final int isFavorite;
  final int? collectionId;
  final String createdAt;

  BookmarkModel({
    this.id,
    this.title,
    required this.url,
    this.notes,
    this.image,
    this.isFavorite = 0,
    this.collectionId,
    required this.createdAt,
  });

  factory BookmarkModel.fromMap(Map<String, dynamic> map) {
    return BookmarkModel(
      id: map['id'],
      title: map['title'],
      url: map['url'],
      notes: map['notes'],
      image: map['image'],
      isFavorite: map['is_favorite'] ?? 0,
      collectionId: map['collection_id'],
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'notes': notes,
      'image': image,
      'is_favorite': isFavorite,
      'collection_id': collectionId,
      'created_at': createdAt,
    };
  }

  BookmarkModel copyWith({
    int? id,
    Object? title = _sentinel,
    String? url,
    Object? notes = _sentinel,
    Object? image = _sentinel,
    int? isFavorite,
    Object? collectionId = _sentinel,
    String? createdAt,
  }) {
    return BookmarkModel(
      id: id ?? this.id,
      title: title == _sentinel ? this.title : title as String?,
      url: url ?? this.url,
      notes: notes == _sentinel ? this.notes : notes as String?,
      image: image == _sentinel ? this.image : image as String?,
      isFavorite: isFavorite ?? this.isFavorite,
      collectionId: collectionId == _sentinel
          ? this.collectionId
          : collectionId as int?,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static const _sentinel = Object();
}
