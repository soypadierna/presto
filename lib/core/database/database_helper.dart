import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'presto.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE routes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE clients (
        id TEXT PRIMARY KEY,
        route_id TEXT NOT NULL,
        name TEXT NOT NULL,
        credit REAL NOT NULL,
        payment_type TEXT NOT NULL,
        payment_days TEXT NOT NULL,
        position INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (route_id) REFERENCES routes(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        client_id TEXT NOT NULL,
        route_id TEXT NOT NULL,
        amount REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        note TEXT,
        payment_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        payment_method TEXT NOT NULL DEFAULT 'cash',
        image_path TEXT,
        FOREIGN KEY (client_id) REFERENCES clients(id),
        FOREIGN KEY (route_id) REFERENCES routes(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        route_id TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        expense_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (route_id) REFERENCES routes(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_base (
        id TEXT PRIMARY KEY,
        route_id TEXT NOT NULL,
        amount REAL NOT NULL,
        base_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (route_id) REFERENCES routes(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE scheduled_payments (
        id TEXT PRIMARY KEY,
        client_id TEXT NOT NULL,
        route_id TEXT NOT NULL,
        scheduled_date TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (client_id) REFERENCES clients(id),
        FOREIGN KEY (route_id) REFERENCES routes(id)
      )
    ''');
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE payments
        ADD COLUMN payment_method TEXT NOT NULL DEFAULT 'cash'
      ''');
      await db.execute('''
        ALTER TABLE payments
        ADD COLUMN image_path TEXT
      ''');
      debugPrint('DB migrada de v$oldVersion a v2');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS scheduled_payments (
          id TEXT PRIMARY KEY,
          client_id TEXT NOT NULL,
          route_id TEXT NOT NULL,
          scheduled_date TEXT NOT NULL,
          note TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (client_id) REFERENCES clients(id),
          FOREIGN KEY (route_id) REFERENCES routes(id)
        )
      ''');
      debugPrint('DB migrada a v3 — tabla scheduled_payments creada');
    }
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'presto.db');
  }

  Future<void> reinitialize() async {
    await closeDatabase();
    _database = await _initDB();
  }
}
