class ReservationModel {
  int? id;
  int borrowerId;
  int bookId;
  String reservationDate;
  String status;

  ReservationModel({
    this.id,
    required this.borrowerId,
    required this.bookId,
    required this.reservationDate,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'borrower_id': borrowerId,
      'book_id': bookId,
      'reservation_date': reservationDate,
      'status': status,
    };
  }

  factory ReservationModel.fromMap(Map<String, dynamic> map) {
    return ReservationModel(
      id: map['id'],
      borrowerId: map['borrower_id'],
      bookId: map['book_id'],
      reservationDate: map['reservation_date'],
      status: map['status'],
    );
  }
}
