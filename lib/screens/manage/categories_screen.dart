import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/category_model.dart';
import '../../repositories/category_repository.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CategoryRepository _repository = CategoryRepository();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final data = await _repository.getAll();
    setState(() {
      _categories = data;
      _isLoading = false;
    });
  }

  void _showFormDialog([CategoryModel? category]) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: category?.name ?? '');
    final _descController = TextEditingController(text: category?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'إضافة تصنيف جديد' : 'تعديل التصنيف'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم التصنيف'),
                validator: (value) => value!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'الوصف (اختياري)'),
              ),
            ],
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
                if (category == null) {
                  await _repository.insert(CategoryModel(
                    name: _nameController.text.trim(),
                    description: _descController.text.trim(),
                  ));
                } else {
                  category.name = _nameController.text.trim();
                  category.description = _descController.text.trim();
                  await _repository.update(category);
                }
                Navigator.pop(context);
                _loadCategories();
              }
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(int id) async {
    await _repository.delete(id);
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة التصنيفات'),
        backgroundColor: AppColors.primaryNavy,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? const Center(child: Text('لا توجد تصنيفات حالياً'))
              : ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.accentGold,
                          child: Icon(Icons.category, color: Colors.white),
                        ),
                        title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(cat.description ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showFormDialog(cat),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCategory(cat.id!),
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
