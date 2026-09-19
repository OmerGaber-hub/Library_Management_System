class CategoryModel {
  int? id;
  String name;
  String? description;

  CategoryModel({this.id, required this.name, this.description});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'description': description};
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      description: map['description'],
    );
  }
}
