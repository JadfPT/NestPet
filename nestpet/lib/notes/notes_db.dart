import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';


class NotesDatabase {
static final NotesDatabase instance = NotesDatabase._();
NotesDatabase._();


Database? _db;


Future<Database> get database async {
if (_db != null) return _db!;
_db = await _initDB();
return _db!;
}


Future<Database> _initDB() async {
final dir = await getApplicationDocumentsDirectory();
final path = p.join(dir.path, 'notes.db');


return openDatabase(
path,
version: 1,
onCreate: (db, version) async {
await db.execute('''
CREATE TABLE notes (
id INTEGER PRIMARY KEY AUTOINCREMENT,
title TEXT NOT NULL,
content TEXT NOT NULL,
createdAt INTEGER NOT NULL
)
''');
await db.execute('CREATE INDEX idx_notes_createdAt ON notes(createdAt)');
},
onUpgrade: (db, oldV, newV) async {
// Exemplo de migrações futuras
// if (oldV < 2) { await db.execute('ALTER TABLE notes ADD COLUMN isArchived INTEGER NOT NULL DEFAULT 0'); }
},
);
}
}