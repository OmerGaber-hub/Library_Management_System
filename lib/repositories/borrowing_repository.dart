import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/borrowing_model.dart';

class BorrowingRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final String _tableName = 'borrowings';

  Future<int> insert(BorrowingModel borrowing) async {
    final db = await _databaseHelper.database;
    return await db.insert(_tableName, borrowing.toMap());
  }

  Future<List<BorrowingModel>> getAll() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return maps.map((map) => BorrowingModel.fromMap(map)).toList();
  }

  Future<List<BorrowingModel>> getBorrowingsForUser(int borrowerId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'borrower_id = ?',
      whereArgs: [borrowerId],
    );
    return maps.map((map) => BorrowingModel.fromMap(map)).toList();
  }

  Future<int> update(BorrowingModel borrowing) async {
    final db = await _databaseHelper.database;
    return await db.update(
      _tableName,
      borrowing.toMap(),
      where: 'id = ?',
      whereArgs: [borrowing.id],
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

  Future<BorrowingModel?> getById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return BorrowingModel.fromMap(maps.first);
    }
    return null;
  }
}
