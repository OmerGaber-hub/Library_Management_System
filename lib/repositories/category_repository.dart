import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final String _tableName = 'categories';

  Future<int> insert(CategoryModel category) async {
    final db = await _databaseHelper.database;
    return await db.insert(_tableName, category.toMap());
  }

  Future<List<CategoryModel>> getAll() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return maps.map((map) => CategoryModel.fromMap(map)).toList();
  }

  Future<CategoryModel?> getById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return CategoryModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> update(CategoryModel category) async {
    final db = await _databaseHelper.database;
    return await db.update(
      _tableName,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
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
