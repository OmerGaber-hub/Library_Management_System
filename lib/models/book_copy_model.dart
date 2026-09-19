class BookCopyModel {
  int? id;
  int bookId;
  String copyNumber;
  String? shelfNumber;
  String status;

  BookCopyModel({
    this.id,
    required this.bookId,
    required this.copyNumber,
    this.shelfNumber,
    this.status = 'available',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'copy_number': copyNumber,
      'shelf_number': shelfNumber,
      'status': status,
    };
  }

  factory BookCopyModel.fromMap(Map<String, dynamic> map) {
    return BookCopyModel(
      id: map['id'],
      bookId: map['book_id'],
      copyNumber: map['copy_number'],
      shelfNumber: map['shelf_number'],
      status: map['status'],
    );
  }
}
