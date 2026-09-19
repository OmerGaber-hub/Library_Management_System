import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

class UserRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final String _tableName = 'users';

  Future<List<UserModel>> getAll() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return maps.map((map) => UserModel.fromMap(map)).toList();
  }

  Future<int> updateRole(int userId, String newRole) async {
    final db = await _databaseHelper.database;
    final result = await db.update(
      _tableName,
      {'role': newRole},
      where: 'id = ?',
      whereArgs: [userId],
    );
    
    if (AuthRepository.currentUser?.id == userId) {
      AuthRepository.currentUser?.role = newRole;
    }
    
    return result;
  }

  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<UserModel?> getById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }
}
