class UserModel {
  int? id;
  String fullName;
  String email;
  String? phone;
  String password;
  String role;
  String? profileImagePath;
  String createdAt;

  UserModel({
    this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.password,
    this.role = 'borrower',
    this.profileImagePath,
    required this.createdAt,
  });

  // Convert a UserModel into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
      'profile_image_path': profileImagePath,
      'created_at': createdAt,
    };
  }

  // Extract a UserModel object from a Map.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      fullName: map['full_name'],
      email: map['email'],
      phone: map['phone'],
      password: map['password'],
      role: map['role'],
      profileImagePath: map['profile_image_path'],
      createdAt: map['created_at'],
    );
  }

  // Helper methods to check roles
  bool get isAdmin => role == 'admin';
  bool get isLibrarian => role == 'librarian';
  bool get isBorrower => role == 'borrower';
  
  // An admin or librarian has staff privileges
  bool get isStaff => isAdmin || isLibrarian;
}
