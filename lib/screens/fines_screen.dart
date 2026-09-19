import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/fine_model.dart';
import '../models/borrower_model.dart';
import '../repositories/fine_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/borrower_repository.dart';
import '../repositories/borrowing_repository.dart';
import '../repositories/book_copy_repository.dart';
import '../repositories/book_repository.dart';
import '../repositories/user_repository.dart';
import '../models/borrowing_model.dart';
import '../models/book_model.dart';
import '../models/user_model.dart';

class FinesScreen extends StatefulWidget {
  const FinesScreen({Key? key}) : super(key: key);

  @override
  _FinesScreenState createState() => _FinesScreenState();
}

class _FinesScreenState extends State<FinesScreen> {
  final FineRepository _repo = FineRepository();
  final BorrowerRepository _borrowerRepo = BorrowerRepository();

  List<FineModel> _fines = [];
  Map<int, BorrowingModel> _borrowingsMap = {};
  Map<int, BookModel> _booksMap = {};
  Map<int, UserModel> _usersMap = {};

  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadFines();
  }

  Future<void> _loadFines() async {
    setState(() => _isLoading = true);
    final user = AuthRepository.currentUser;
    if (user != null && user.id != null) {
      _isAdmin = user.isStaff;
      if (_isAdmin) {
        _fines = await _repo.getAll();
      } else {
        BorrowerModel? borrower = await _borrowerRepo.getByUserId(user.id!);
        if (borrower != null) {
          _fines = await _repo.getFinesForBorrower(borrower.id!);
        }
      }

      // Load related data
      final borrowingRepo = BorrowingRepository();
      final copyRepo = BookCopyRepository();
      final bookRepo = BookRepository();
      final userRepo = UserRepository();

      for (var f in _fines) {
        // Fetch Borrowing
        if (!_borrowingsMap.containsKey(f.borrowingId)) {
          final borrowing = await borrowingRepo.getById(f.borrowingId);
          if (borrowing != null) {
            _borrowingsMap[f.borrowingId] = borrowing;

            // Fetch Book
            final copy = await copyRepo.getById(borrowing.copyId);
            if (copy != null && !_booksMap.containsKey(borrowing.id)) {
              final book = await bookRepo.getById(copy.bookId);
              if (book != null) _booksMap[borrowing.id!] = book;
            }

            // Fetch User
            if (_isAdmin && !_usersMap.containsKey(borrowing.borrowerId)) {
              final borrower = await _borrowerRepo.getById(borrowing.borrowerId);
              if (borrower != null) {
                final u = await userRepo.getById(borrower.userId);
                if (u != null) _usersMap[borrowing.borrowerId] = u;
              }
            }
          }
        }
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _markAsPaid(FineModel fine) async {
    try {
      fine.paymentStatus = 'paid';
      await _repo.update(fine);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الغرامة كمدفوعة'), backgroundColor: Colors.green));
        _loadFines();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  Future<void> _payWithBalance(FineModel fine) async {
    final user = AuthRepository.currentUser;
    if (user == null) return;
    
    BorrowerModel? borrower = await _borrowerRepo.getByUserId(user.id!);
    if (borrower == null) return;

    if (borrower.balance >= fine.amount) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تأكيد الدفع', style: TextStyle(color: AppColors.primaryNavy)),
          content: Text('سيتم خصم مبلغ ${fine.amount} من رصيدك الحالي (${borrower.balance}). هل تريد المتابعة؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('دفع', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        try {
          borrower.balance -= fine.amount;
          await _borrowerRepo.update(borrower);
          fine.paymentStatus = 'paid';
          await _repo.update(fine);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم دفع الغرامة بنجاح خصماً من رصيدك'), backgroundColor: Colors.green));
            _loadFines();
          }
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء الدفع: $e')));
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رصيدك غير كافٍ، الرجاء شحن محفظتك أولاً.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isAdmin ? 'جميع الغرامات' : 'غراماتي'),
        backgroundColor: AppColors.primaryNavy,
      ),
      backgroundColor: AppColors.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _fines.isEmpty
              ? const Center(child: Text('لا توجد غرامات مسجلة'))
              : ListView.builder(
                  itemCount: _fines.length,
                  itemBuilder: (context, index) {
                    final f = _fines[index];
                    final borrowing = _borrowingsMap[f.borrowingId];
                    final book = borrowing != null ? _booksMap[borrowing.id] : null;
                    final user = _isAdmin && borrowing != null ? _usersMap[borrowing.borrowerId] : null;
                    
                    final isUnpaid = f.paymentStatus == 'unpaid';
                    
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
                                color: isUnpaid ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.receipt_long, color: isUnpaid ? Colors.red : Colors.green, size: 30),
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
                                      const Icon(Icons.warning, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(f.reason, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${f.amount} ر.ي', 
                                    style: TextStyle(color: isUnpaid ? Colors.red : Colors.green, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Actions
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Chip(
                                  label: Text(isUnpaid ? 'غير مدفوع' : 'مدفوع', style: const TextStyle(color: Colors.white, fontSize: 10)),
                                  backgroundColor: isUnpaid ? Colors.red : Colors.green,
                                  padding: EdgeInsets.zero,
                                ),
                                if (_isAdmin && isUnpaid)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                    onPressed: () => _markAsPaid(f),
                                    icon: const Icon(Icons.check_circle, size: 16, color: Colors.white),
                                    label: const Text('تسديد', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                if (!_isAdmin && isUnpaid)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accentGold,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                    onPressed: () => _payWithBalance(f),
                                    icon: const Icon(Icons.payment, size: 16, color: Colors.white),
                                    label: const Text('دفع الآن', style: TextStyle(color: Colors.white, fontSize: 12)),
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
