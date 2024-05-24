import 'package:event_note_taker/model/event.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('events.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const boolType =
        'INTEGER NOT NULL'; // SQLite does not have a BOOLEAN type, so we use INTEGER
    const dateType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE events ( 
  id $idType, 
  name $textType,
  amount $intType,
  status $boolType,
  remark $textType,
  date $dateType
  )
''');
  }

  Future<int> createEvent(Event event) async {
    final db = await instance.database;
    return await db.insert('events', event.toJson());
  }

  Future<List<Event>> readAllEvents() async {
    final db = await instance.database;
    final orderBy = 'date ASC';
    final result = await db.query('events', orderBy: orderBy);
    return result.map((json) => Event.fromJson(json)).toList();
  }

  Future<List<Event>> readEventsByDate(DateTime date) async {
    final db = await instance.database;
    final result = await db.query(
      'events',
      where: 'date = ?',
      whereArgs: [date.millisecondsSinceEpoch],
    );
    return result.map((json) => Event.fromJson(json)).toList();
  }

  Future<int> updateEvent(Event event) async {
    final db = await instance.database;
    return await db.update(
      'events',
      event.toJson(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(int id) async {
    final db = await instance.database;
    return await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
