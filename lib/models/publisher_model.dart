class PublisherModel {
  int? id;
  String name;
  String? address;
  String? phone;
  String? email;

  PublisherModel({this.id, required this.name, this.address, this.phone, this.email});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'address': address, 'phone': phone, 'email': email};
  }

  factory PublisherModel.fromMap(Map<String, dynamic> map) {
    return PublisherModel(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      phone: map['phone'],
      email: map['email'],
    );
  }
}
