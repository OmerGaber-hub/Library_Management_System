import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/publisher_model.dart';
import '../../repositories/publisher_repository.dart';

class PublishersScreen extends StatefulWidget {
  const PublishersScreen({Key? key}) : super(key: key);

  @override
  _PublishersScreenState createState() => _PublishersScreenState();
}

class _PublishersScreenState extends State<PublishersScreen> {
  final PublisherRepository _repository = PublisherRepository();
  List<PublisherModel> _publishers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPublishers();
  }

  Future<void> _loadPublishers() async {
    setState(() => _isLoading = true);
    final data = await _repository.getAll();
    setState(() {
      _publishers = data;
      _isLoading = false;
    });
  }

  void _showFormDialog([PublisherModel? publisher]) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: publisher?.name ?? '');
    final _addressController = TextEditingController(text: publisher?.address ?? '');
    final _phoneController = TextEditingController(text: publisher?.phone ?? '');
    final _emailController = TextEditingController(text: publisher?.email ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(publisher == null ? 'إضافة دار نشر جديدة' : 'تعديل دار النشر'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'اسم دار النشر'),
                  validator: (value) => value!.isEmpty ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'العنوان'),
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                  keyboardType: TextInputType.emailAddress,
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
                if (publisher == null) {
                  await _repository.insert(PublisherModel(
                    name: _nameController.text.trim(),
                    address: _addressController.text.trim(),
                    phone: _phoneController.text.trim(),
                    email: _emailController.text.trim(),
                  ));
                } else {
                  publisher.name = _nameController.text.trim();
                  publisher.address = _addressController.text.trim();
                  publisher.phone = _phoneController.text.trim();
                  publisher.email = _emailController.text.trim();
                  await _repository.update(publisher);
                }
                Navigator.pop(context);
                _loadPublishers();
              }
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePublisher(int id) async {
    await _repository.delete(id);
    _loadPublishers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة دور النشر'),
        backgroundColor: AppColors.primaryNavy,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _publishers.isEmpty
              ? const Center(child: Text('لا يوجد دور نشر حالياً'))
              : ListView.builder(
                  itemCount: _publishers.length,
                  itemBuilder: (context, index) {
                    final publisher = _publishers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.accentGold,
                          child: Icon(Icons.business, color: Colors.white),
                        ),
                        title: Text(publisher.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(publisher.address ?? 'غير محدد'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showFormDialog(publisher),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deletePublisher(publisher.id!),
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
