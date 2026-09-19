import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'utils/app_colors.dart';

// Global notifier for ThemeMode
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load saved theme preference
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkMode') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'نظام إدارة المكتبة',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          // Light Theme
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryNavy),
            scaffoldBackgroundColor: AppColors.backgroundLight,
            useMaterial3: false,
          ),
          // Dark Theme
          darkTheme: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryNavy,
              secondary: AppColors.accentGold,
            ),
            useMaterial3: false,
          ),
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            );
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
