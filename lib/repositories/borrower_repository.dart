import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/borrower_model.dart';

class BorrowerRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final String _tableName = 'borrowers';

  Future<int> insert(BorrowerModel borrower) async {
    final db = await _databaseHelper.database;
    return await db.insert(_tableName, borrower.toMap());
  }

  Future<List<BorrowerModel>> getAll() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return maps.map((map) => BorrowerModel.fromMap(map)).toList();
  }

  Future<BorrowerModel?> getByUserId(int userId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (maps.isNotEmpty) {
      return BorrowerModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> update(BorrowerModel borrower) async {
    final db = await _databaseHelper.database;
    return await db.update(
      _tableName,
      borrower.toMap(),
      where: 'id = ?',
      whereArgs: [borrower.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<BorrowerModel?> getById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return BorrowerModel.fromMap(maps.first);
    }
    return null;
  }
}
