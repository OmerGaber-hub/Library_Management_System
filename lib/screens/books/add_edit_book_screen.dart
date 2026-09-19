import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../utils/app_colors.dart';
import '../../models/book_model.dart';
import '../../models/category_model.dart';
import '../../models/author_model.dart';
import '../../models/publisher_model.dart';
import '../../repositories/book_repository.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/author_repository.dart';
import '../../repositories/publisher_repository.dart';

class AddEditBookScreen extends StatefulWidget {
  final BookModel? book;
  const AddEditBookScreen({Key? key, this.book}) : super(key: key);

  @override
  _AddEditBookScreenState createState() => _AddEditBookScreenState();
}

class _AddEditBookScreenState extends State<AddEditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final BookRepository _bookRepo = BookRepository();
  final CategoryRepository _catRepo = CategoryRepository();
  final AuthorRepository _authRepo = AuthorRepository();
  final PublisherRepository _pubRepo = PublisherRepository();

  List<CategoryModel> _categories = [];
  List<AuthorModel> _authors = [];
  List<PublisherModel> _publishers = [];

  final _titleController = TextEditingController();
  final _isbnController = TextEditingController();
  final _publishYearController = TextEditingController();
  final _pagesController = TextEditingController();
  final _descController = TextEditingController();
  
  int? _selectedCategory;
  int? _selectedAuthor;
  int? _selectedPublisher;
  
  String? _pdfPath;
  String? _coverImagePath;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.book != null) {
      _titleController.text = widget.book!.title;
      _isbnController.text = widget.book!.isbn ?? '';
      _publishYearController.text = widget.book!.publishYear?.toString() ?? '';
      _pagesController.text = widget.book!.pages?.toString() ?? '';
      _descController.text = widget.book!.description ?? '';
      _selectedCategory = widget.book!.categoryId;
      _selectedAuthor = widget.book!.authorId;
      _selectedPublisher = widget.book!.publisherId;
      _pdfPath = widget.book!.pdfPath;
      _coverImagePath = widget.book!.coverImagePath;
    }
  }

  Future<void> _loadData() async {
    final cats = await _catRepo.getAll();
    final auths = await _authRepo.getAll();
    final pubs = await _pubRepo.getAll();
    setState(() {
      _categories = cats;
      _authors = auths;
      _publishers = pubs;
      _isLoading = false;
    });
  }

  Future<void> _pickPDF() async {
    PlatformFile? result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.path != null) {
      File sourceFile = File(result.path!);
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'book_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final savedFile = await sourceFile.copy('${directory.path}/$fileName');
      
      setState(() {
        _pdfPath = savedFile.path;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرفاق الملف بنجاح')));
    }
  }

  Future<void> _pickCoverImage() async {
    PlatformFile? result = await FilePicker.pickFile(
      type: FileType.image,
    );

    if (result != null && result.path != null) {
      File sourceFile = File(result.path!);
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourceFile.path)}';
      final savedFile = await sourceFile.copy('${directory.path}/$fileName');
      
      setState(() {
        _coverImagePath = savedFile.path;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرفاق صورة الغلاف بنجاح')));
    }
  }

  void _saveBook() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null || _selectedAuthor == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب اختيار تصنيف ومؤلف')));
        return;
      }
      
      setState(() => _isSaving = true);
      final book = BookModel(
        id: widget.book?.id,
        title: _titleController.text.trim(),
        isbn: _isbnController.text.isEmpty ? null : _isbnController.text.trim(),
        publishYear: _publishYearController.text.isEmpty ? null : int.tryParse(_publishYearController.text),
        pages: _pagesController.text.isEmpty ? null : int.tryParse(_pagesController.text),
        categoryId: _selectedCategory!,
        authorId: _selectedAuthor!,
        publisherId: _selectedPublisher,
        description: _descController.text.isEmpty ? null : _descController.text.trim(),
        pdfPath: _pdfPath,
        coverImagePath: _coverImagePath,
      );

      if (widget.book == null) {
        await _bookRepo.insert(book);
      } else {
        await _bookRepo.update(book);
      }
      
      Navigator.pop(context, true); // true to indicate success
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(appBar: AppBar(title: const Text('جارِ التحميل...')), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book == null ? 'إضافة كتاب جديد' : 'تعديل بيانات الكتاب'),
        backgroundColor: AppColors.primaryNavy,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'عنوان الكتاب *', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _isbnController,
                decoration: const InputDecoration(labelText: 'رقم ISBN (اختياري)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'التصنيف *', border: OutlineInputBorder()),
                value: _selectedCategory,
                items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                validator: (val) => val == null ? 'مطلوب' : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'المؤلف *', border: OutlineInputBorder()),
                value: _selectedAuthor,
                items: _authors.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                onChanged: (val) => setState(() => _selectedAuthor = val),
                validator: (val) => val == null ? 'مطلوب' : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'دار النشر', border: OutlineInputBorder()),
                value: _selectedPublisher,
                items: _publishers.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                onChanged: (val) => setState(() => _selectedPublisher = val),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _publishYearController,
                      decoration: const InputDecoration(labelText: 'سنة النشر', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: _pagesController,
                      decoration: const InputDecoration(labelText: 'عدد الصفحات', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'الوصف', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 15),
              ListTile(
                tileColor: Colors.grey[200],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                leading: const Icon(Icons.image, color: Colors.blue),
                title: Text(_coverImagePath == null ? 'لم يتم إرفاق صورة غلاف' : 'تم إرفاق صورة غلاف', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: _coverImagePath != null ? const Text('هذه الصورة ستظهر كغلاف للكتاب') : const Text('اضغط هنا لرفع صورة الغلاف'),
                onTap: _pickCoverImage,
                trailing: _coverImagePath != null 
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _coverImagePath = null))
                    : null,
              ),
              const SizedBox(height: 15),
              ListTile(
                tileColor: Colors.grey[200],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(_pdfPath == null ? 'لم يتم إرفاق ملف PDF' : 'تم إرفاق ملف PDF', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: _pdfPath != null ? const Text('يمكن للقراء فتح هذا الملف من التطبيق') : const Text('اضغط هنا لرفع الكتاب'),
                onTap: _pickPDF,
                trailing: _pdfPath != null 
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _pdfPath = null))
                    : null,
              ),
              const SizedBox(height: 30),
              _isSaving 
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: _saveBook,
                      child: const Text('حفظ بيانات الكتاب', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
