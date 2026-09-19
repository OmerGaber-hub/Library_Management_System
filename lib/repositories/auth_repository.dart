import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';

class AuthRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // In-memory current user (for simple state access, though State Management like Provider is better)
  static UserModel? currentUser;

  /// Registers a new user in the database.
  /// Checks if the email is already in use.
  Future<UserModel?> register(UserModel user) async {
    final db = await _databaseHelper.database;
    
    // Check if email already exists
    final List<Map<String, dynamic>> existingUser = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [user.email],
    );

    if (existingUser.isNotEmpty) {
      throw Exception('البريد الإلكتروني مسجل مسبقاً');
    }

    // Insert user
    final int id = await db.insert('users', user.toMap());
    user.id = id;
    
    // If it's a borrower, we should ideally create a record in 'borrowers' table too,
    // but that can be handled during registration flow or profile completion.

    return user;
  }

  /// Authenticates a user by email and password.
  /// Returns the UserModel if successful, throws Exception otherwise.
  Future<UserModel> login(String email, String password) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) {
      UserModel user = UserModel.fromMap(maps.first);
      currentUser = user; // Set as logged in
      return user;
    } else {
      throw Exception('البريد الإلكتروني أو كلمة المرور غير صحيحة');
    }
  }

  /// Logs out the current user
  void logout() {
    currentUser = null;
  }

  /// Check if a user is currently logged in
  bool isLoggedIn() {
    return currentUser != null;
  }

  /// Changes the user's password
  Future<void> changePassword(int userId, String currentPassword, String newPassword) async {
    final db = await _databaseHelper.database;
    
    // Verify current password
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ? AND password = ?',
      whereArgs: [userId, currentPassword],
    );

    if (maps.isEmpty) {
      throw Exception('كلمة المرور الحالية غير صحيحة');
    }

    // Update to new password
    await db.update(
      'users',
      {'password': newPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );
    
    if (currentUser?.id == userId) {
      currentUser?.password = newPassword;
    }
  }
}
