import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/publisher_model.dart';

class PublisherRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final String _tableName = 'publishers';

  Future<int> insert(PublisherModel publisher) async {
    final db = await _databaseHelper.database;
    return await db.insert(_tableName, publisher.toMap());
  }

  Future<List<PublisherModel>> getAll() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return maps.map((map) => PublisherModel.fromMap(map)).toList();
  }

  Future<PublisherModel?> getById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return PublisherModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> update(PublisherModel publisher) async {
    final db = await _databaseHelper.database;
    return await db.update(
      _tableName,
      publisher.toMap(),
      where: 'id = ?',
      whereArgs: [publisher.id],
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
