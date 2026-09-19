import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/book_copy_model.dart';
import '../../models/book_model.dart';
import '../../repositories/book_copy_repository.dart';
import '../../repositories/book_repository.dart';

class BookCopiesScreen extends StatefulWidget {
  const BookCopiesScreen({Key? key}) : super(key: key);

  @override
  _BookCopiesScreenState createState() => _BookCopiesScreenState();
}

class _BookCopiesScreenState extends State<BookCopiesScreen> {
  final BookCopyRepository _repository = BookCopyRepository();
  final BookRepository _bookRepo = BookRepository();
  
  List<BookCopyModel> _copies = [];
  Map<int, BookModel> _booksMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCopies();
  }

  Future<void> _loadCopies() async {
    setState(() => _isLoading = true);
    
    final copies = await _repository.getAll();
    for (var copy in copies) {
      if (!_booksMap.containsKey(copy.bookId)) {
        final book = await _bookRepo.getById(copy.bookId);
        if (book != null) {
          _booksMap[copy.bookId] = book;
        }
      }
    }
    
    if (mounted) {
      setState(() {
        _copies = copies;
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddDialog() async {
    final _formKey = GlobalKey<FormState>();
    final _copyNumController = TextEditingController();
    final _shelfController = TextEditingController();
    BookModel? selectedBook;

    // Load books for dropdown
    final allBooks = await _bookRepo.getAll();
    if (allBooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إضافة كتب أولاً')));
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('إضافة نسخة كتاب', style: TextStyle(color: AppColors.primaryNavy)),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<BookModel>(
                      isExpanded: true,
                      value: selectedBook,
                      decoration: const InputDecoration(labelText: 'اختر الكتاب'),
                      items: allBooks.map((b) => DropdownMenuItem(value: b, child: Text(b.title, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) => setDialogState(() => selectedBook = val),
                      validator: (val) => val == null ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _copyNumController,
                      decoration: const InputDecoration(labelText: 'رقم النسخة/الباركود (مثال: C-001)'),
                      validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _shelfController,
                      decoration: const InputDecoration(labelText: 'رقم الرف (اختياري)'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      await _repository.insert(BookCopyModel(
                        bookId: selectedBook!.id!,
                        copyNumber: _copyNumController.text,
                        shelfNumber: _shelfController.text,
                        status: 'available'
                      ));
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة النسخة بنجاح'), backgroundColor: Colors.green));
                        _loadCopies();
                      }
                    } catch(e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: قد يكون رقم النسخة مكرراً'), backgroundColor: Colors.red));
                    }
                  }
                },
                child: const Text('حفظ', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _deleteCopy(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف النسخة', style: TextStyle(color: Colors.red)),
        content: const Text('هل أنت متأكد من حذف هذه النسخة نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repository.delete(id);
      _loadCopies();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة نسخ الكتب'),
        backgroundColor: AppColors.primaryNavy,
      ),
      backgroundColor: AppColors.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _copies.isEmpty
              ? const Center(child: Text('لا توجد نسخ مسجلة حالياً'))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _copies.length,
                  itemBuilder: (context, index) {
                    final copy = _copies[index];
                    final book = _booksMap[copy.bookId];
                    final isAvail = copy.status == 'available';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isAvail ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          child: Icon(Icons.inventory_2, color: isAvail ? Colors.green : Colors.orange),
                        ),
                        title: Text(book?.title ?? 'كتاب مجهول', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text('النسخة: ${copy.copyNumber} | الرف: ${copy.shelfNumber ?? "-"}'),
                            Text(
                              isAvail ? 'متوفرة للاستعارة' : 'مستعارة حالياً',
                              style: TextStyle(color: isAvail ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                            )
                          ],
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteCopy(copy.id!),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accentGold,
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة نسخة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
