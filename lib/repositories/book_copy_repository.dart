import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/book_copy_model.dart';

class BookCopyRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final String _tableName = 'book_copies';

  Future<int> insert(BookCopyModel copy) async {
    final db = await _databaseHelper.database;
    return await db.insert(_tableName, copy.toMap());
  }

  Future<List<BookCopyModel>> getAll() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return maps.map((map) => BookCopyModel.fromMap(map)).toList();
  }

  Future<List<BookCopyModel>> getCopiesForBook(int bookId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'book_id = ?',
      whereArgs: [bookId],
    );
    return maps.map((map) => BookCopyModel.fromMap(map)).toList();
  }

  Future<List<BookCopyModel>> getAvailableCopiesForBook(int bookId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'book_id = ? AND status = ?',
      whereArgs: [bookId, 'available'],
    );
    return maps.map((map) => BookCopyModel.fromMap(map)).toList();
  }

  Future<BookCopyModel?> getById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return BookCopyModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> update(BookCopyModel copy) async {
    final db = await _databaseHelper.database;
    return await db.update(
      _tableName,
      copy.toMap(),
      where: 'id = ?',
      whereArgs: [copy.id],
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
