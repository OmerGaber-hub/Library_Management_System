import 'dart:io';
import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../utils/app_colors.dart';
import '../../models/book_model.dart';
import '../../models/category_model.dart';
import '../../models/author_model.dart';
import '../../models/publisher_model.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/author_repository.dart';
import '../../repositories/publisher_repository.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/borrower_repository.dart';
import '../../repositories/reservation_repository.dart';
import '../../repositories/book_copy_repository.dart';
import '../../repositories/book_repository.dart';
import '../../models/borrower_model.dart';
import '../../models/reservation_model.dart';
import 'book_reader_screen.dart';
import 'add_edit_book_screen.dart';
import 'package:share_plus/share_plus.dart';

class BookDetailsScreen extends StatefulWidget {
  final BookModel book;

  const BookDetailsScreen({Key? key, required this.book}) : super(key: key);

  @override
  _BookDetailsScreenState createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  final CategoryRepository _catRepo = CategoryRepository();
  final AuthorRepository _authRepo = AuthorRepository();
  final PublisherRepository _pubRepo = PublisherRepository();

  CategoryModel? _category;
  AuthorModel? _author;
  PublisherModel? _publisher;
  int _availableCopiesCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    final cat = await _catRepo.getById(widget.book.categoryId);
    final auth = await _authRepo.getById(widget.book.authorId);
    PublisherModel? pub;
    if (widget.book.publisherId != null) {
      pub = await _pubRepo.getById(widget.book.publisherId!);
    }
    
    // Fetch available copies
    final copyRepo = BookCopyRepository();
    final copies = await copyRepo.getAvailableCopiesForBook(widget.book.id!);

    if (mounted) {
      setState(() {
        _category = cat;
        _author = auth;
        _publisher = pub;
        _availableCopiesCount = copies.length;
        _isLoading = false;
      });
    }
  }

  Color _getCoverColor(String title) {
    final colors = [
      Colors.teal,
      Colors.indigo,
      Colors.deepPurple,
      Colors.blueGrey,
      Colors.brown,
      Colors.red[800]!,
      Colors.green[800]!,
    ];
    return colors[title.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final hasPdf = book.pdfPath != null && book.pdfPath!.isNotEmpty;
    final hasCustomCover = book.coverImagePath != null && book.coverImagePath!.isNotEmpty;
    final coverColor = _getCoverColor(book.title);

    final isStaff = AuthRepository.currentUser?.isStaff ?? false;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(book.title),
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        actions: isStaff ? [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: 'تعديل الكتاب',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddEditBookScreen(book: book)),
              );
              // if it returns true, we pop this screen to refresh the books list
              if (result == true) {
                Navigator.pop(context); 
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            tooltip: 'حذف الكتاب',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.red)),
                  content: const Text('هل أنت متأكد أنك تريد حذف هذا الكتاب نهائياً؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        try {
                          await BookRepository().delete(book.id!);
                          if (mounted) {
                            Navigator.pop(context); // close dialog
                            Navigator.pop(context); // go back to books list
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم حذف الكتاب بنجاح'), backgroundColor: Colors.green),
                            );
                          }
                        } catch (e) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('خطأ أثناء الحذف: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      child: const Text('حذف', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ] : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Header for Book Cover
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 160,
                        height: 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 10))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: hasCustomCover
                              ? Image.file(
                                  File(book.coverImagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildFallbackCover(book.title, coverColor),
                                )
                              : _buildFallbackCover(book.title, coverColor),
                        ),
                      ),
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Author
                        Text(
                          book.title,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _author?.name ?? 'مؤلف غير معروف',
                          style: const TextStyle(fontSize: 18, color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 25),

                        // Metadata Grid
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 3,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          children: [
                            _buildInfoChip(Icons.category, 'التصنيف', _category?.name ?? 'غير محدد'),
                            _buildInfoChip(Icons.business, 'دار النشر', _publisher?.name ?? 'غير محدد'),
                            _buildInfoChip(Icons.date_range, 'سنة النشر', book.publishYear?.toString() ?? 'غير محدد'),
                            _buildInfoChip(Icons.pages, 'الصفحات', book.pages?.toString() ?? 'غير محدد'),
                            _buildInfoChip(Icons.inventory_2, 'نسخ متاحة', _availableCopiesCount.toString()),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Description
                        const Text('نبذة عن الكتاب', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                          ),
                          child: Text(
                            book.description ?? 'لا يوجد وصف متاح لهذا الكتاب.',
                            style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // ISBN Barcode (If available)
                        if (book.isbn != null && book.isbn!.isNotEmpty) ...[
                          const Text('رقم ISBN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                          const SizedBox(height: 15),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                              ),
                              child: BarcodeWidget(
                                barcode: Barcode.code128(), // Or Barcode.isbn() if it fits standard strictly
                                data: book.isbn!,
                                width: 250,
                                height: 80,
                                drawText: true,
                                errorBuilder: (context, error) => const Center(
                                  child: Text('صيغة ISBN غير صالحة للباركود', style: TextStyle(color: Colors.red)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _isLoading ? null : Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _availableCopiesCount == 0 ? null : () async {
                  final user = AuthRepository.currentUser;
                  if (user == null) return;
                  
                  try {
                    final borrowerRepo = BorrowerRepository();
                    BorrowerModel? borrower = await borrowerRepo.getByUserId(user.id!);
                    
                    if (borrower == null) {
                      // Create borrower profile if it doesn't exist
                      final newBorrower = BorrowerModel(
                        userId: user.id!,
                        membershipDate: DateTime.now().toIso8601String(),
                      );
                      final borrowerId = await borrowerRepo.insert(newBorrower);
                      borrower = BorrowerModel(id: borrowerId, userId: user.id!, membershipDate: newBorrower.membershipDate);
                    }
                    
                    final reservation = ReservationModel(
                      borrowerId: borrower.id!,
                      bookId: book.id!,
                      reservationDate: DateTime.now().toIso8601String(),
                    );
                    
                    await ReservationRepository().insert(reservation);
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم إرسال طلب الحجز بنجاح!'),
                          backgroundColor: Colors.green,
                        )
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('حدث خطأ أثناء الحجز: $e'), backgroundColor: Colors.red)
                      );
                    }
                  }
                },
                icon: Icon(Icons.bookmark_add, color: _availableCopiesCount == 0 ? Colors.grey : Colors.white),
                label: Text(
                  _availableCopiesCount == 0 ? 'غير متوفر حالياً' : 'استعارة / حجز', 
                  style: TextStyle(color: _availableCopiesCount == 0 ? Colors.grey : Colors.white, fontSize: 14, fontWeight: FontWeight.bold)
                ),
              ),
            ),
            if (hasPdf) ...[
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGold,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BookReaderScreen(book: book)),
                    );
                  },
                  icon: const Icon(Icons.menu_book, color: Colors.white, size: 20),
                  label: const Text('قراءة', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () async {
                    try {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('جاري تجهيز الملف...')),
                        );
                      }
                      
                      final file = XFile(book.pdfPath!);
                      final result = await Share.shareXFiles(
                        [file],
                        text: 'كتاب: ${book.title}',
                        subject: book.title,
                      );
                      
                      if (result.status == ShareResultStatus.success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تمت العملية بنجاح!'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('حدث خطأ أثناء المشاركة/الحفظ: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.share, color: Colors.white, size: 20),
                  label: const Text('مشاركة / حفظ', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackCover(String title, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.7), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(2, 2))],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryNavy),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                Text(
                  value,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
