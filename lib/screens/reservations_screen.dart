import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/reservation_model.dart';
import '../models/book_copy_model.dart';
import '../models/borrowing_model.dart';
import '../models/book_model.dart';
import '../models/user_model.dart';
import '../repositories/reservation_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/book_copy_repository.dart';
import '../repositories/borrowing_repository.dart';
import '../repositories/book_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/borrower_repository.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({Key? key}) : super(key: key);

  @override
  _ReservationsScreenState createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final ReservationRepository _repo = ReservationRepository();
  final BookCopyRepository _copyRepo = BookCopyRepository();
  final BorrowingRepository _borrowingRepo = BorrowingRepository();
  
  List<ReservationModel> _reservations = [];
  Map<int, BookModel> _booksMap = {};
  Map<int, UserModel> _usersMap = {};
  
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkRoleAndLoad();
  }

  Future<void> _checkRoleAndLoad() async {
    setState(() => _isLoading = true);
    final user = AuthRepository.currentUser;
    if (user != null) {
      _isAdmin = user.isStaff;
      if (_isAdmin) {
        _reservations = await _repo.getAll();
      } else {
        // Must resolve borrower_id from user_id first
        final borrower = await BorrowerRepository().getByUserId(user.id!);
        if (borrower != null) {
          _reservations = await _repo.getReservationsForUser(borrower.id!);
        }
      }
      
      // Load related books and users
      final bookRepo = BookRepository();
      final borrowerRepo = BorrowerRepository();
      final userRepo = UserRepository();
      
      for (var r in _reservations) {
        if (!_booksMap.containsKey(r.bookId)) {
           final book = await bookRepo.getById(r.bookId);
           if (book != null) _booksMap[r.bookId] = book;
        }
        
        if (_isAdmin && !_usersMap.containsKey(r.borrowerId)) {
           final borrower = await borrowerRepo.getById(r.borrowerId);
           if (borrower != null) {
             final user = await userRepo.getById(borrower.userId);
             if (user != null) _usersMap[r.borrowerId] = user;
           }
        }
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _approveReservation(ReservationModel r) async {
    // Get available copies for this book
    final copies = await _copyRepo.getAvailableCopiesForBook(r.bookId);
    if (copies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد نسخ متاحة لهذا الكتاب حالياً'), backgroundColor: Colors.red));
      return;
    }

    BookCopyModel? selectedCopy;
    DateTime? expectedReturnDate;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('الموافقة على الحجز', style: TextStyle(color: AppColors.primaryNavy)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('اختر النسخة المراد تسليمها:'),
                  DropdownButton<BookCopyModel>(
                    isExpanded: true,
                    value: selectedCopy,
                    hint: const Text('النسخ المتاحة'),
                    items: copies.map((c) => DropdownMenuItem(value: c, child: Text(c.copyNumber))).toList(),
                    onChanged: (val) => setDialogState(() => selectedCopy = val),
                  ),
                  const SizedBox(height: 20),
                  const Text('تاريخ الاستحقاق (موعد الإرجاع):'),
                  ListTile(
                    tileColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    title: Text(expectedReturnDate == null ? 'اختر التاريخ' : expectedReturnDate.toString().split(' ')[0]),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 14)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => expectedReturnDate = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () async {
                    if (selectedCopy == null || expectedReturnDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تعبئة جميع الحقول')));
                      return;
                    }
                    
                    try {
                      // 1. Create Borrowing
                      final borrowing = BorrowingModel(
                        borrowerId: r.borrowerId,
                        copyId: selectedCopy!.id!,
                        employeeUserId: AuthRepository.currentUser!.id,
                        borrowDate: DateTime.now().toIso8601String(),
                        expectedReturnDate: expectedReturnDate!.toIso8601String(),
                      );
                      await _borrowingRepo.insert(borrowing);

                      // 2. Update Book Copy Status
                      selectedCopy!.status = 'borrowed';
                      await _copyRepo.update(selectedCopy!);

                      // 3. Update Reservation Status
                      r.status = 'approved';
                      await _repo.update(r);

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحويل الحجز لاستعارة بنجاح'), backgroundColor: Colors.green));
                        _checkRoleAndLoad();
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                    }
                  },
                  child: const Text('تأكيد وتسليم', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _rejectReservation(ReservationModel r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رفض الحجز', style: TextStyle(color: Colors.red)),
        content: const Text('هل أنت متأكد أنك تريد رفض هذا الحجز وإلغاءه؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('رفض الحجز', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        r.status = 'rejected';
        await _repo.update(r);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفض الحجز وإلغاؤه'), backgroundColor: Colors.orange));
          _checkRoleAndLoad();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isAdmin ? 'جميع الحجوزات' : 'حجوزاتي'),
        backgroundColor: AppColors.primaryNavy,
      ),
      backgroundColor: AppColors.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reservations.isEmpty
              ? const Center(child: Text('لا توجد حجوزات حالياً'))
              : ListView.builder(
                  itemCount: _reservations.length,
                  itemBuilder: (context, index) {
                    final r = _reservations[index];
                    final book = _booksMap[r.bookId];
                    final user = _isAdmin ? _usersMap[r.borrowerId] : null;
                    final isPending = r.status == 'pending';
                    
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Book Cover Icon
                            Container(
                              width: 60,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.primaryNavy.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.book, color: AppColors.primaryNavy, size: 30),
                            ),
                            const SizedBox(width: 15),
                            
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    book?.title ?? 'كتاب غير معروف', 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryNavy),
                                    maxLines: 2, overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),
                                  if (_isAdmin) ...[
                                    Row(
                                      children: [
                                        const Icon(Icons.person, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(user?.fullName ?? 'مستعير غير معروف', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                  ],
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(r.reservationDate.split('T')[0], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Actions & Status
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Chip(
                                  label: Text(
                                    isPending ? 'قيد الانتظار' : (r.status == 'rejected' ? 'مرفوض' : 'تم الاستلام'), 
                                    style: const TextStyle(color: Colors.white, fontSize: 10)
                                  ),
                                  backgroundColor: isPending ? Colors.orange : (r.status == 'rejected' ? Colors.red : Colors.green),
                                  padding: EdgeInsets.zero,
                                ),
                                if (_isAdmin && isPending)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                        onPressed: () => _approveReservation(r),
                                        icon: const Icon(Icons.check, size: 16, color: Colors.white),
                                        label: const Text('موافقة', style: TextStyle(color: Colors.white, fontSize: 12)),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                        onPressed: () => _rejectReservation(r),
                                        icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                        label: const Text('رفض', style: TextStyle(color: Colors.white, fontSize: 12)),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
