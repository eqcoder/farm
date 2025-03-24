import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<void> initDatabase() async {
    if (_database != null) return;

    String path = join(await getDatabasesPath(), 'farm.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE farms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<String>> getFarmNames() async {
    final db = _database!;
    final List<Map<String, dynamic>> result = await db.query('farms');
    return result.map((row) => row['name'] as String).toList();
  }

  Future<void> addFarm(String name) async {
    final db = _database!;
    await db.insert('farms', {'name': name});
  }
}
