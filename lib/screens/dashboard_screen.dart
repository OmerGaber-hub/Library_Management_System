import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../repositories/auth_repository.dart';
import '../repositories/book_repository.dart';
import '../repositories/borrowing_repository.dart';
import '../repositories/reservation_repository.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _booksCount = 0;
  int _copiesCount = 0;
  int _activeBorrowingsCount = 0;
  int _reservationsCount = 0;
  
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadStats();
  }
  
  Future<void> _loadStats() async {
    final user = AuthRepository.currentUser;
    if (user == null) return;
    
    try {
      if (user.isStaff) {
        // Admin Stats
        final books = await BookRepository().getAll();
        _booksCount = books.length;
        
        final db = await DatabaseHelper.instance.database;
        final copiesResult = await db.rawQuery('SELECT COUNT(*) as count FROM book_copies');
        _copiesCount = Sqflite.firstIntValue(copiesResult) ?? 0;
        
        final borrowings = await BorrowingRepository().getAll();
        _activeBorrowingsCount = borrowings.where((b) => b.status == 'borrowed').length;
        
        final reservations = await ReservationRepository().getAll();
        _reservationsCount = reservations.length;
        
      } else {
        // Borrower Stats
        final myBorrowings = await BorrowingRepository().getBorrowingsForUser(user.id!);
        _activeBorrowingsCount = myBorrowings.where((b) => b.status == 'borrowed').length;
        
        final myReservations = await ReservationRepository().getReservationsForUser(user.id!);
        _reservationsCount = myReservations.where((r) => r.status == 'pending').length;
      }
    } catch (e) {
      print('Error loading stats: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthRepository.currentUser;
    final isStaff = user?.isStaff ?? false;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مرحباً بك، ${user?.fullName ?? ""}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
          ),
          const SizedBox(height: 20),
          if (isStaff) ...[
            const Text('إحصائيات المكتبة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildStatCard('إجمالي الكتب', '$_booksCount', Icons.library_books, Colors.blue),
                _buildStatCard('النسخ المتاحة', '$_copiesCount', Icons.book, Colors.green),
                _buildStatCard('الاستعارات النشطة', '$_activeBorrowingsCount', Icons.history, Colors.orange),
                _buildStatCard('الحجوزات', '$_reservationsCount', Icons.bookmark, Colors.purple),
              ],
            ),
          ] else ...[
            const Text('نظرة عامة على حسابك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildStatCard('استعاراتي الحالية', '$_activeBorrowingsCount', Icons.menu_book, Colors.blue),
                _buildStatCard('حجوزاتي', '$_reservationsCount', Icons.bookmark, Colors.purple),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              count,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
