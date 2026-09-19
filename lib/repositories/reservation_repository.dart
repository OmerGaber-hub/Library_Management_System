import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/reservation_model.dart';

class ReservationRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final String _tableName = 'reservations';

  Future<int> insert(ReservationModel reservation) async {
    final db = await _databaseHelper.database;
    return await db.insert(_tableName, reservation.toMap());
  }

  Future<List<ReservationModel>> getReservationsForUser(int borrowerId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'borrower_id = ?',
      whereArgs: [borrowerId],
    );
    return maps.map((map) => ReservationModel.fromMap(map)).toList();
  }

  Future<List<ReservationModel>> getAll() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return maps.map((map) => ReservationModel.fromMap(map)).toList();
  }

  Future<int> update(ReservationModel reservation) async {
    final db = await _databaseHelper.database;
    return await db.update(
      _tableName,
      reservation.toMap(),
      where: 'id = ?',
      whereArgs: [reservation.id],
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
