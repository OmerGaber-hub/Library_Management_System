import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    // 1. Wait a bit, then fade in the logo
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _opacity = 1.0;
      });
    }

    // 2. Wait for 2 seconds to show the logo
    await Future.delayed(const Duration(seconds: 2));
    
    // 3. Navigate to Login Screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // خلفية داكنة بلون أزرق ليلي
    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      body: Center(
        // حركة ظهور بسيطة باستخدام AnimatedOpacity
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(seconds: 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // شعار كتاب بلون ذهبي مضيء كبديل مؤقت لصورة الشعار
              Icon(
                Icons.menu_book, 
                size: 100, 
                color: AppColors.accentGold,
              ),
              const SizedBox(height: 20),
              const Text(
                'نظام إدارة المكتبة',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
