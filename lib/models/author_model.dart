class AuthorModel {
  int? id;
  String name;
  String? nationality;
  String? birthDate;
  String? biography;

  AuthorModel({this.id, required this.name, this.nationality, this.birthDate, this.biography});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'nationality': nationality, 'birth_date': birthDate, 'biography': biography};
  }

  factory AuthorModel.fromMap(Map<String, dynamic> map) {
    return AuthorModel(
      id: map['id'],
      name: map['name'],
      nationality: map['nationality'],
      birthDate: map['birth_date'],
      biography: map['biography'],
    );
  }
}
