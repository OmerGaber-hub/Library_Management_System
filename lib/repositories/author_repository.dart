import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/author_model.dart';

class AuthorRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final String _tableName = 'authors';

  Future<int> insert(AuthorModel author) async {
    final db = await _databaseHelper.database;
    return await db.insert(_tableName, author.toMap());
  }

  Future<List<AuthorModel>> getAll() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return maps.map((map) => AuthorModel.fromMap(map)).toList();
  }

  Future<AuthorModel?> getById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return AuthorModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> update(AuthorModel author) async {
    final db = await _databaseHelper.database;
    return await db.update(
      _tableName,
      author.toMap(),
      where: 'id = ?',
      whereArgs: [author.id],
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
