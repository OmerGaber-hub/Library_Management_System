import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../repositories/auth_repository.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'auth/login_screen.dart';
import 'manage/categories_screen.dart';
import 'manage/authors_screen.dart';
import 'manage/publishers_screen.dart';
import 'manage/book_copies_screen.dart';
import 'manage/users_screen.dart';
import 'borrowings_screen.dart';
import 'reservations_screen.dart';
import 'fines_screen.dart';
import 'settings_screen.dart';

import 'books/books_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final AuthRepository _authRepository = AuthRepository();
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() {
    _authRepository.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthRepository.currentUser;
    final isAdmin = user?.isAdmin ?? false;
    final isLibrarian = user?.isLibrarian ?? false;
    final isStaff = user?.isStaff ?? false;

    // Define pages dynamically based on role
    final List<Widget> pages = [];
    final List<BottomNavigationBarItem> navItems = [];

    if (isAdmin) {
      pages.add(const DashboardScreen());
      navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'اللوحة'));
    }

    pages.addAll([
      const BooksScreen(),
      const BorrowingsScreen(),
      const ProfileScreen(),
    ]);

    navItems.addAll(const [
      BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'الكتب'),
      BottomNavigationBarItem(icon: Icon(Icons.history), label: 'الاستعارات'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
    ]);

    // Ensure _selectedIndex doesn't go out of bounds if role changed somehow
    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام إدارة المكتبة'),
        backgroundColor: AppColors.primaryNavy,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primaryNavy),
              accountName: Text(user?.fullName ?? 'زائر'),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppColors.accentGold,
                backgroundImage: (user?.profileImagePath != null && user!.profileImagePath!.isNotEmpty)
                    ? FileImage(File(user.profileImagePath!))
                    : null,
                child: (user?.profileImagePath == null || user!.profileImagePath!.isEmpty)
                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
              ),
            ),
            
            // ADMIN ONLY
            if (isAdmin) ...[
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text('إدارة المستخدمين', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const UsersScreen()));
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('التصنيفات'),
                onTap: () {
                  Navigator.pop(context); 
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoriesScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('المؤلفون'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthorsScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.business),
                title: const Text('دور النشر'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PublishersScreen()));
                },
              ),
            ],

            // STAFF (Admin & Librarian)
            if (isStaff) ...[
              ListTile(
                leading: const Icon(Icons.book),
                title: const Text('نسخ الكتب'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const BookCopiesScreen()));
                },
              ),
            ],
            
            // ALL USERS
            const Divider(),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('الحجوزات'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ReservationsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.money_off),
              title: const Text('الغرامات'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const FinesScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('الإعدادات'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primaryNavy,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: navItems,
      ),
    );
  }
}
