import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/author_model.dart';
import '../../repositories/author_repository.dart';

class AuthorsScreen extends StatefulWidget {
  const AuthorsScreen({Key? key}) : super(key: key);

  @override
  _AuthorsScreenState createState() => _AuthorsScreenState();
}

class _AuthorsScreenState extends State<AuthorsScreen> {
  final AuthorRepository _repository = AuthorRepository();
  List<AuthorModel> _authors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuthors();
  }

  Future<void> _loadAuthors() async {
    setState(() => _isLoading = true);
    final data = await _repository.getAll();
    setState(() {
      _authors = data;
      _isLoading = false;
    });
  }

  void _showFormDialog([AuthorModel? author]) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: author?.name ?? '');
    final _nationalityController = TextEditingController(text: author?.nationality ?? '');
    final _birthController = TextEditingController(text: author?.birthDate ?? '');
    final _bioController = TextEditingController(text: author?.biography ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(author == null ? 'إضافة مؤلف جديد' : 'تعديل المؤلف'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'اسم المؤلف'),
                  validator: (value) => value!.isEmpty ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: _nationalityController,
                  decoration: const InputDecoration(labelText: 'الجنسية'),
                ),
                TextFormField(
                  controller: _birthController,
                  decoration: const InputDecoration(labelText: 'تاريخ الميلاد'),
                ),
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(labelText: 'نبذة (اختياري)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                if (author == null) {
                  await _repository.insert(AuthorModel(
                    name: _nameController.text.trim(),
                    nationality: _nationalityController.text.trim(),
                    birthDate: _birthController.text.trim(),
                    biography: _bioController.text.trim(),
                  ));
                } else {
                  author.name = _nameController.text.trim();
                  author.nationality = _nationalityController.text.trim();
                  author.birthDate = _birthController.text.trim();
                  author.biography = _bioController.text.trim();
                  await _repository.update(author);
                }
                Navigator.pop(context);
                _loadAuthors();
              }
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAuthor(int id) async {
    await _repository.delete(id);
    _loadAuthors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المؤلفين'),
        backgroundColor: AppColors.primaryNavy,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _authors.isEmpty
              ? const Center(child: Text('لا يوجد مؤلفين حالياً'))
              : ListView.builder(
                  itemCount: _authors.length,
                  itemBuilder: (context, index) {
                    final author = _authors[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.accentGold,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(author.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(author.nationality ?? 'غير محدد'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showFormDialog(author),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteAuthor(author.id!),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentGold,
        onPressed: () => _showFormDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
