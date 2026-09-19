import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/fine_model.dart';

class FineRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final String _tableName = 'fines';

  Future<int> insert(FineModel fine) async {
    final db = await _databaseHelper.database;
    return await db.insert(_tableName, fine.toMap());
  }

  Future<List<FineModel>> getAll() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return maps.map((map) => FineModel.fromMap(map)).toList();
  }

  Future<List<FineModel>> getFinesForBorrower(int borrowerId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT fines.* FROM fines
      INNER JOIN borrowings ON fines.borrowing_id = borrowings.id
      WHERE borrowings.borrower_id = ?
    ''', [borrowerId]);
    return maps.map((map) => FineModel.fromMap(map)).toList();
  }

  Future<int> update(FineModel fine) async {
    final db = await _databaseHelper.database;
    return await db.update(
      _tableName,
      fine.toMap(),
      where: 'id = ?',
      whereArgs: [fine.id],
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
}
