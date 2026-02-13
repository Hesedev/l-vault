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
      isFavorite: map['is_favorite'],
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
}
