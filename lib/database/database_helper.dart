import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database_schema.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static const _databaseName = "LibraryDatabase.db";
  static const _databaseVersion = 3;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE books ADD COLUMN cover_image_path TEXT;');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE borrowers ADD COLUMN balance REAL NOT NULL DEFAULT 0.0;');
      await db.execute('ALTER TABLE borrowings ADD COLUMN return_requested INTEGER NOT NULL DEFAULT 0;');
    }
  }

  Future _onCreate(Database db, int version) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');

    // Create tables in correct dependency order
    await db.execute(DatabaseSchema.createUsersTable);
    await db.execute(DatabaseSchema.createCategoriesTable);
    await db.execute(DatabaseSchema.createAuthorsTable);
    await db.execute(DatabaseSchema.createPublishersTable);
    await db.execute(DatabaseSchema.createBooksTable);
    await db.execute(DatabaseSchema.createBookCopiesTable);
    await db.execute(DatabaseSchema.createBorrowersTable);
    await db.execute(DatabaseSchema.createBorrowingsTable);
    await db.execute(DatabaseSchema.createFinesTable);
    await db.execute(DatabaseSchema.createReservationsTable);
    
    // Insert a default admin user for testing
    await db.insert('users', {
      'full_name': 'Admin User',
      'email': 'admin@library.com',
      'password': 'password123', // In a real app, this should be hashed
      'role': 'admin',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
