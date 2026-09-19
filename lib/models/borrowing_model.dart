class BorrowingModel {
  int? id;
  int borrowerId;
  int copyId;
  int? employeeUserId;
  String borrowDate;
  String expectedReturnDate;
  String? actualReturnDate;
  String status;
  bool returnRequested;

  BorrowingModel({
    this.id,
    required this.borrowerId,
    required this.copyId,
    this.employeeUserId,
    required this.borrowDate,
    required this.expectedReturnDate,
    this.actualReturnDate,
    this.status = 'borrowed',
    this.returnRequested = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'borrower_id': borrowerId,
      'copy_id': copyId,
      'employee_user_id': employeeUserId,
      'borrow_date': borrowDate,
      'expected_return_date': expectedReturnDate,
      'actual_return_date': actualReturnDate,
      'status': status,
      'return_requested': returnRequested ? 1 : 0,
    };
  }

  factory BorrowingModel.fromMap(Map<String, dynamic> map) {
    return BorrowingModel(
      id: map['id'],
      borrowerId: map['borrower_id'],
      copyId: map['copy_id'],
      employeeUserId: map['employee_user_id'],
      borrowDate: map['borrow_date'],
      expectedReturnDate: map['expected_return_date'],
      actualReturnDate: map['actual_return_date'],
      status: map['status'],
      returnRequested: map['return_requested'] == 1,
    );
  }
}
