import 'note.dart';
import 'notes_db.dart';


class NotesDao {
Future<int> insert(Note note) async {
final db = await NotesDatabase.instance.database;
return db.insert('notes', note.toMap());
}


Future<List<Note>> getAll({String? query}) async {
final db = await NotesDatabase.instance.database;
final where = (query == null || query.isEmpty) ? null : 'title LIKE ? OR content LIKE ?';
final whereArgs = (query == null || query.isEmpty) ? null : ['%$query%', '%$query%'];


final maps = await db.query('notes',
where: where,
whereArgs: whereArgs,
orderBy: 'createdAt DESC');
return maps.map((m) => Note.fromMap(m)).toList();
}


Future<int> update(Note note) async {
final db = await NotesDatabase.instance.database;
return db.update('notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]);
}


Future<int> delete(int id) async {
final db = await NotesDatabase.instance.database;
return db.delete('notes', where: 'id = ?', whereArgs: [id]);
}
}