import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../main.dart'; // To access themeNotifier
import '../repositories/auth_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  final AuthRepository _authRepo = AuthRepository();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
    setState(() {
      _notificationsEnabled = value;
    });
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تغيير كلمة المرور', style: TextStyle(color: AppColors.primaryNavy)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'كلمة المرور الحالية'),
                  validator: (val) => val!.isEmpty ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'مطلوب';
                    if (val.length < 6) return 'كلمة المرور قصيرة جداً';
                    return null;
                  },
                ),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
                  validator: (val) {
                    if (val != newPasswordController.text) return 'غير متطابق';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final user = AuthRepository.currentUser;
                    if (user != null) {
                      await _authRepo.changePassword(
                        user.id!,
                        oldPasswordController.text,
                        newPasswordController.text,
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح'), backgroundColor: Colors.green),
                        );
                      }
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('تغيير', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: AppColors.primaryNavy,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('إعدادات الحساب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('تغيير كلمة المرور'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showChangePasswordDialog,
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('الإشعارات'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
              activeColor: AppColors.primaryNavy,
            ),
          ),
          const Divider(height: 30),
          
          const Text('إعدادات التطبيق', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('لغة التطبيق'),
            subtitle: const Text('العربية'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يدعم التطبيق اللغة العربية حالياً فقط')));
            },
          ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, child) {
              final isDark = currentMode == ThemeMode.dark;
              return ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('الوضع الليلي'),
                trailing: Switch(
                  value: isDark,
                  activeColor: AppColors.primaryNavy,
                  onChanged: (val) async {
                    themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isDarkMode', val);
                  },
                ),
              );
            },
          ),
          const Divider(height: 30),

          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('حول التطبيق'),
            subtitle: const Text('الإصدار 1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'مكتبتي',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.local_library, size: 50, color: AppColors.primaryNavy),
                children: [
                  const Text('نظام متكامل لإدارة المكتبات، تم تصميمه لتسهيل قراءة واستعارة الكتب وحجزها بكل سهولة.')
                ]
              );
            },
          ),
        ],
      ),
    );
  }
}
