import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UserRepository _repo = UserRepository();
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    _users = await _repo.getAll();
    setState(() => _isLoading = false);
  }

  Future<void> _changeRole(UserModel user, String newRole) async {
    if (user.role == newRole) return;
    try {
      await _repo.updateRole(user.id!, newRole);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير صلاحية المستخدم بنجاح'), backgroundColor: Colors.green));
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  Future<void> _deleteUser(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا المستخدم نهائياً؟ ستفقد جميع بياناته.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repo.delete(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المستخدم بنجاح')));
          _loadUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('لا يمكن حذف المستخدم لوجود ارتباطات: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        backgroundColor: AppColors.primaryNavy,
      ),
      backgroundColor: AppColors.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('لا يوجد مستخدمين'))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final u = _users[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: AppColors.primaryNavy, child: Icon(Icons.person, color: Colors.white)),
                        title: Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(u.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButton<String>(
                              value: u.role,
                              items: const [
                                DropdownMenuItem(value: 'borrower', child: Text('مستعير')),
                                DropdownMenuItem(value: 'librarian', child: Text('أمين مكتبة')),
                                DropdownMenuItem(value: 'admin', child: Text('مدير النظام')),
                              ],
                              onChanged: (val) {
                                if (val != null) _changeRole(u, val);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteUser(u.id!),
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
