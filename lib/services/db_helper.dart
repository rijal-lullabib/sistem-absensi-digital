import 'dart:async';
import 'package:sqflite/sqflite.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';
import '../models/employee.dart';
import '../models/attendance.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _db;
  DBHelper._init();

  Future<Database> get database async {
    try {
      if (_db != null) return _db!;
      _db = await _initDB('absensi.db');
      return _db!;
    } catch (e) {
      throw Exception('Gagal membuka database: $e');
    }
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 3, // Increment version untuk migration
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Add department and contact columns if upgrading from version 2
      await db.execute('ALTER TABLE employees ADD COLUMN department TEXT DEFAULT ""');
      await db.execute('ALTER TABLE employees ADD COLUMN contact TEXT DEFAULT ""');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE employees(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      photoPath TEXT NOT NULL,
      faceHash TEXT NOT NULL,
      department TEXT DEFAULT '',
      contact TEXT DEFAULT ''
    )
    ''');

    await db.execute('''
    CREATE TABLE attendance(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      employeeId INTEGER NOT NULL,
      timestamp TEXT NOT NULL,
      photoPath TEXT DEFAULT '',
      type TEXT NOT NULL,
      status TEXT NOT NULL
    )
    ''');
  }

  Future<int> insertEmployee(Employee e) async {
    final db = await database;
    return await db.insert('employees', e.toMap());
  }

  Future<List<Employee>> getAllEmployees() async {
    final db = await database;
    final res = await db.query('employees');
    return res.map((m) => Employee.fromMap(m)).toList();
  }

  Future<int> insertAttendance(Attendance a) async {
    final db = await database;
    return await db.insert('attendance', a.toMap());
  }

  Future<List<Attendance>> getAllAttendance() async {
    final db = await database;
    final res = await db.query('attendance', orderBy: 'timestamp DESC');
    return res.map((m) => Attendance.fromMap(m)).toList();
  }

  Future<int> updateEmployee(Employee e) async {
    final db = await database;
    return await db.update(
      'employees',
      e.toMap(),
      where: 'id = ?',
      whereArgs: [e.id],
    );
  }

  Future<int> deleteEmployee(int id) async {
    final db = await database;
    return await db.delete(
      'employees',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
