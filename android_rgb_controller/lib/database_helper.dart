import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'colors.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE colors(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            color INTEGER
          )
        ''');
      },
    );
  }

  Future<int> insertColorProfile(String name, int color) async {
    final db = await database;
    return await db.insert('colors', {'name': name, 'color': color});
  }

  Future<List<Map<String, dynamic>>> getColorProfiles() async {
    final db = await database;
    return await db.query('colors');
  }

  Future<int> deleteColorProfile(int id) async {
    final db = await database;
    return await db.delete('colors', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateColorProfile(int id, int color) async {
    final db = await database;
    return await db.update('colors', {'color': color}, where: 'id = ?', whereArgs: [id]);
  }
}
