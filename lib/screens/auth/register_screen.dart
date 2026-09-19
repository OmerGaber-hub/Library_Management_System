import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../repositories/auth_repository.dart';
import '../../models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String _selectedRole = 'borrower';
  
  final AuthRepository _authRepository = AuthRepository();
  bool _isLoading = false;

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final newUser = UserModel(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole,
          createdAt: DateTime.now().toIso8601String(),
        );

        await _authRepository.register(newUser);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إنشاء الحساب بنجاح! يمكنك الآن تسجيل الدخول.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Return to login screen
        }
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('خطأ في التسجيل', style: TextStyle(color: Colors.red)),
              content: Text(e.toString().replaceAll('Exception: ', '')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('حسناً', style: TextStyle(color: AppColors.primaryNavy)),
                ),
              ],
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
        centerTitle: true,
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            elevation: 8,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_add, size: 60, color: AppColors.primaryNavy),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'الاسم الكامل',
                        prefixIcon: const Icon(Icons.person, color: AppColors.primaryNavy),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => value!.isEmpty ? 'الرجاء إدخال الاسم' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: const Icon(Icons.email, color: AppColors.primaryNavy),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
                        if (!value.contains('@')) return 'صيغة البريد غير صحيحة';
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'رقم الهاتف',
                        prefixIcon: const Icon(Icons.phone, color: AppColors.primaryNavy),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock, color: AppColors.primaryNavy),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => value!.isEmpty ? 'الرجاء إدخال كلمة المرور' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'تأكيد كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryNavy),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'الرجاء تأكيد كلمة المرور';
                        if (value != _passwordController.text) return 'كلمات المرور غير متطابقة';
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'نوع الحساب',
                        prefixIcon: const Icon(Icons.badge, color: AppColors.primaryNavy),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      value: _selectedRole,
                      items: const [
                        DropdownMenuItem(value: 'borrower', child: Text('مستعير')),
                        DropdownMenuItem(value: 'librarian', child: Text('أمين مكتبة')),
                        DropdownMenuItem(value: 'admin', child: Text('مدير نظام')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedRole = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 25),
                    _isLoading 
                      ? const CircularProgressIndicator(color: AppColors.primaryNavy)
                      : SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _register,
                            icon: const Icon(Icons.app_registration, color: Colors.white),
                            label: const Text(
                              'تسجيل حساب جديد',
                              style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryNavy,
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
