class FineModel {
  int? id;
  int borrowingId;
  double amount;
  String reason;
  String paymentStatus;
  String createdAt;

  FineModel({
    this.id,
    required this.borrowingId,
    required this.amount,
    required this.reason,
    this.paymentStatus = 'unpaid',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'borrowing_id': borrowingId,
      'amount': amount,
      'reason': reason,
      'payment_status': paymentStatus,
      'created_at': createdAt,
    };
  }

  factory FineModel.fromMap(Map<String, dynamic> map) {
    return FineModel(
      id: map['id'],
      borrowingId: map['borrowing_id'],
      amount: map['amount'],
      reason: map['reason'],
      paymentStatus: map['payment_status'],
      createdAt: map['created_at'],
    );
  }
}
