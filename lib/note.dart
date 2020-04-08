import 'parse.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sql.dart';

final String tableNote = 'note';
final String columnId = '_id';
final String columnTitle = 'title';
final String columnFilename = 'filename';
final String columnSummary = 'summary';
final String columnCreated = 'created';

class Note {
  int id;
  String title;
  String filename;
  String summary;
  int created;

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnTitle: title,
      columnFilename: filename,
      columnSummary: summary,
      columnCreated: created,
    };

    if (id != null) {
      map[columnId] = id;
    }

    return map;
  }

  Note({this.id, this.title, this.filename, this.summary, this.created});

  Note.fromMap(Map<String, dynamic> map) {
    id = map[columnId];
    title = map[columnTitle];
    filename = map[columnFilename];
    summary = map[columnSummary];
    created = map[columnCreated];
  }
}

class NoteProvider {
  Database db;

  Future open(String name) async {
    db = await openDatabase(
        join(await getDatabasesPath(), name),
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
create table $tableNote ( 
  $columnId integer primary key autoincrement, 
  $columnTitle text,
  $columnFilename text not null,
  $columnSummary text,
  $columnCreated integer)
''');
        });
  }

  Future<List<Note>> sync(String path) async {
    // Our syncing algorithm is currently relatively rudimentary:
    // - We delete everything from the existing database
    // - We reinsert all the notes
    // - Once we have a backlink table, we generate this after inserting the
    //   notes

    await deleteAll();
    List<Note> notes = await Parser.parseDir(path);

    for (Note note in notes) {
      insert(note);
    }

    return notes;
  }

  Future<Note> insert(Note note) async {
    note.id = await db.insert(
      tableNote,
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace
    );
    return note;
  }

  Future<List<Note>> notes() async {
    // Query the table for all The Dogs.
    final List<Map<String, dynamic>> maps = await db.query('$tableNote');

    // Convert the List<Map<String, dynamic> into a List<Note>.
    return List.generate(maps.length, (i) {
      return Note(
        id: maps[i]['id'],
        filename: maps[i]['filename'],
        title: maps[i]['title'],
        summary: maps[i]['summary'],
        created: maps[i]['created'],
      );
    });
  }

  Future<Note> getNote(int id) async {
    List<Map> maps = await db.query(tableNote,
      columns: [
        columnId,
        columnFilename,
        columnTitle,
        columnSummary,
        columnCreated
      ],
      where: '$columnId = ?',
      whereArgs: [id]
    );

    if (maps.length > 0) {
      return Note.fromMap(maps.first);
    }

    return null;
  }

  Future<int> delete(int id) async {
    return await db.delete(tableNote, where: '$columnId = ?', whereArgs: [id]);
  }

  Future deleteAll() async {
    await db.delete(tableNote);
  }

  Future<int> update(Note todo) async {
    return await db.update(tableNote, todo.toMap(),
        where: '$columnId = ?', whereArgs: [todo.id]);
  }

  Future<int> updateByFilename(Note todo) async {
    return await db.update(tableNote, todo.toMap(),
        where: '$columnFilename = ?', whereArgs: [todo.filename]);
  }

  Future close() async => db.close();
}

