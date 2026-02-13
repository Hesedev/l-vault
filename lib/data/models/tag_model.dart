class TagModel {
  final int? id;
  final String name;

  TagModel({this.id, required this.name});

  factory TagModel.fromMap(Map<String, dynamic> map) {
    return TagModel(id: map['id'], name: map['name']);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }
}
