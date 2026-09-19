import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/borrowing_model.dart';
import '../models/fine_model.dart';
import '../models/book_copy_model.dart';
import '../models/book_model.dart';
import '../models/user_model.dart';
import '../repositories/borrowing_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/fine_repository.dart';
import '../repositories/book_copy_repository.dart';
import '../repositories/book_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/borrower_repository.dart';

class BorrowingsScreen extends StatefulWidget {
  const BorrowingsScreen({Key? key}) : super(key: key);

  @override
  _BorrowingsScreenState createState() => _BorrowingsScreenState();
}

class _BorrowingsScreenState extends State<BorrowingsScreen> {
  final BorrowingRepository _repo = BorrowingRepository();
  final FineRepository _fineRepo = FineRepository();
  final BookCopyRepository _copyRepo = BookCopyRepository();

  List<BorrowingModel> _borrowings = [];
  Map<int, BookModel> _booksMap = {};
  Map<int, UserModel> _usersMap = {};
  
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadBorrowings();
  }

  Future<void> _loadBorrowings() async {
    setState(() => _isLoading = true);
    final user = AuthRepository.currentUser;
    if (user != null && user.id != null) {
      _isAdmin = user.isStaff;
      if (_isAdmin) {
        _borrowings = await _repo.getAll();
      } else {
        // Must resolve borrower_id from user_id first
        final borrower = await BorrowerRepository().getByUserId(user.id!);
        if (borrower != null) {
          _borrowings = await _repo.getBorrowingsForUser(borrower.id!);
        }
      }
      
      // Load related books and users
      final bookRepo = BookRepository();
      final borrowerRepo = BorrowerRepository();
      final userRepo = UserRepository();
      
      for (var b in _borrowings) {
        // Fetch book via copy
        final copy = await _copyRepo.getById(b.copyId);
        if (copy != null && !_booksMap.containsKey(b.id)) {
           final book = await bookRepo.getById(copy.bookId);
           if (book != null) _booksMap[b.id!] = book;
        }
        
        // Fetch user via borrower
        if (_isAdmin && !_usersMap.containsKey(b.borrowerId)) {
           final borrower = await borrowerRepo.getById(b.borrowerId);
           if (borrower != null) {
             final user = await userRepo.getById(borrower.userId);
             if (user != null) _usersMap[b.borrowerId] = user;
           }
        }
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _markReturned(BorrowingModel b) async {
    final fineAmountController = TextEditingController();
    final fineReasonController = TextEditingController(text: 'تأخير في الإرجاع');
    bool applyFine = false;

    // Check if late
    final expectedDate = DateTime.parse(b.expectedReturnDate);
    final now = DateTime.now();
    if (now.isAfter(expectedDate)) {
      applyFine = true;
      final diff = now.difference(expectedDate).inDays;
      // Default fine suggestion: 5 per day late
      fineAmountController.text = (diff > 0 ? diff * 5 : 5).toString();
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('تسجيل إرجاع الكتاب', style: TextStyle(color: AppColors.primaryNavy)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('هل تم إرجاع هذه النسخة فعلياً إلى المكتبة؟'),
                  const SizedBox(height: 20),
                  CheckboxListTile(
                    title: const Text('تسجيل غرامة مالية'),
                    value: applyFine,
                    onChanged: (val) {
                      setDialogState(() => applyFine = val ?? false);
                    },
                  ),
                  if (applyFine) ...[
                    TextField(
                      controller: fineAmountController,
                      decoration: const InputDecoration(labelText: 'مبلغ الغرامة', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: fineReasonController,
                      decoration: const InputDecoration(labelText: 'سبب الغرامة', border: OutlineInputBorder()),
                    ),
                  ]
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () async {
                    try {
                      // 1. Update Borrowing Record
                      b.actualReturnDate = DateTime.now().toIso8601String();
                      b.status = 'returned';
                      await _repo.update(b);

                      // 2. Free up the book copy
                      final copy = await _copyRepo.getById(b.copyId);
                      if (copy != null) {
                        copy.status = 'available';
                        await _copyRepo.update(copy);
                      }

                      // 3. Apply Fine if checked
                      if (applyFine) {
                        final fine = FineModel(
                          borrowingId: b.id!,
                          amount: double.tryParse(fineAmountController.text) ?? 0,
                          reason: fineReasonController.text,
                          createdAt: DateTime.now().toIso8601String(),
                        );
                        await _fineRepo.insert(fine);
                      }

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الإرجاع بنجاح'), backgroundColor: Colors.green));
                        _loadBorrowings();
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                    }
                  },
                  child: const Text('تأكيد الإرجاع', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _borrowings.isEmpty
              ? const Center(child: Text('لا توجد سجلات استعارة حالياً'))
              : ListView.builder(
                  itemCount: _borrowings.length,
                  itemBuilder: (context, index) {
                    final b = _borrowings[index];
                    final book = _booksMap[b.id];
                    final user = _isAdmin ? _usersMap[b.borrowerId] : null;
                    final isBorrowed = b.status == 'borrowed';
                    
                    final expectedDate = DateTime.parse(b.expectedReturnDate);
                    final isLate = isBorrowed && DateTime.now().isAfter(expectedDate);
                    
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon/Image
                            Container(
                              width: 60,
                              height: 80,
                              decoration: BoxDecoration(
                                color: isLate ? Colors.red.withOpacity(0.1) : AppColors.primaryNavy.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.menu_book, color: isLate ? Colors.red : AppColors.primaryNavy, size: 30),
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
                                      const Icon(Icons.file_upload, size: 14, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      Text('الاستعارة: ${b.borrowDate.split('T')[0]}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.download, size: 14, color: isLate ? Colors.red : Colors.green),
                                      const SizedBox(width: 4),
                                      Text(
                                        'الإرجاع: ${b.expectedReturnDate.split('T')[0]}', 
                                        style: TextStyle(color: isLate ? Colors.red : Colors.grey, fontSize: 12, fontWeight: isLate ? FontWeight.bold : FontWeight.normal),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Actions
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Chip(
                                  label: Text(isBorrowed ? (isLate ? 'متأخر' : 'مستعار') : 'مرتجع', style: const TextStyle(color: Colors.white, fontSize: 10)),
                                  backgroundColor: isBorrowed ? (isLate ? Colors.red : Colors.orange) : Colors.green,
                                  padding: EdgeInsets.zero,
                                ),
                                if (_isAdmin && isBorrowed)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                    onPressed: () => _markReturned(b),
                                    icon: const Icon(Icons.keyboard_return, size: 16, color: Colors.white),
                                    label: const Text('إرجاع', style: TextStyle(color: Colors.white, fontSize: 12)),
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
