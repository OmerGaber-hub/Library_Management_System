import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../repositories/auth_repository.dart';
import 'register_screen.dart';
import '../main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthRepository _authRepository = AuthRepository();
  bool _isLoading = false;

  void _login() async {
    // التحقق من المدخلات باستخدام Validator الخاص بـ TextFormField
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _authRepository.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
        
        if (mounted) {
          // رسالة نجاح
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تسجيل الدخول بنجاح!'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          // استخدام AlertDialog لعرض رسالة خطأ واضحة
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('خطأ في الدخول', style: TextStyle(color: Colors.red)),
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
    // خلفية فاتحة مائلة للرمادي
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
        centerTitle: true,
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          // الحاوية المرئية Card مع تأثير الظل elevation والزوايا الدائرية shape
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
                    Icon(Icons.account_circle, size: 80, color: AppColors.primaryNavy),
                    const SizedBox(height: 30),
                    // حقل الإدخال الأول
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next, // للانتقال للحقل التالي
                      decoration: InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: const Icon(Icons.email, color: AppColors.primaryNavy),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال البريد الإلكتروني';
                        }
                        if (!value.contains('@')) {
                          return 'صيغة البريد غير صحيحة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // حقل الإدخال الثاني
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true, // إخفاء النص
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock, color: AppColors.primaryNavy),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال كلمة المرور';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    // زر الدخول مع التحميل
                    _isLoading 
                      ? const CircularProgressIndicator(color: AppColors.primaryNavy)
                      : SizedBox(
                          width: double.infinity,
                          height: 50,
                          // زر التفاعل والإدخال ElevatedButton
                          child: ElevatedButton.icon(
                            onPressed: _login,
                            icon: const Icon(Icons.login, color: Colors.white),
                            label: const Text(
                              'دخول',
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
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        'ليس لديك حساب؟ إنشاء حساب جديد',
                        style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold),
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
