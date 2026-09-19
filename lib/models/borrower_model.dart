class BorrowerModel {
  int? id;
  int userId;
  String? studentId;
  String? address;
  String membershipDate;
  String membershipStatus;
  double balance;

  BorrowerModel({
    this.id,
    required this.userId,
    this.studentId,
    this.address,
    required this.membershipDate,
    this.membershipStatus = 'active',
    this.balance = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'student_id': studentId,
      'address': address,
      'membership_date': membershipDate,
      'membership_status': membershipStatus,
      'balance': balance,
    };
  }

  factory BorrowerModel.fromMap(Map<String, dynamic> map) {
    return BorrowerModel(
      id: map['id'],
      userId: map['user_id'],
      studentId: map['student_id'],
      address: map['address'],
      membershipDate: map['membership_date'],
      membershipStatus: map['membership_status'],
      balance: map['balance'] != null ? (map['balance'] as num).toDouble() : 0.0,
    );
  }
}
