import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/book_model.dart';

class BookRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final String _tableName = 'books';

  Future<int> insert(BookModel book) async {
    final db = await _databaseHelper.database;
    return await db.insert(_tableName, book.toMap());
  }

  Future<List<BookModel>> getAll() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return maps.map((map) => BookModel.fromMap(map)).toList();
  }

  Future<BookModel?> getById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return BookModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> update(BookModel book) async {
    final db = await _databaseHelper.database;
    return await db.update(
      _tableName,
      book.toMap(),
      where: 'id = ?',
      whereArgs: [book.id],
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
