import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tuple/tuple.dart';

import 'parse.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sql.dart';

final String tableNote = 'note';
final String columnId = '_id';
final String columnTitle = 'title';
final String columnFilename = 'filename';
final String columnSummary = 'summary';
final String columnModified = 'modified';

class Note {
  int id;
  String title;
  String filename;
  String summary;
  DateTime modified;

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnTitle: title,
      columnFilename: filename,
      columnSummary: summary,
      columnModified: modified.millisecondsSinceEpoch,
    };

    if (id != null) {
      map[columnId] = id;
    }

    return map;
  }

  String titleOrFilename() {
    return title ?? filename;
  }

  Note({this.id, this.title, this.filename, this.summary, this.modified});

  Note.fromMap(Map<String, dynamic> map) {
    id = map[columnId];
    title = map[columnTitle];
    filename = map[columnFilename];
    summary = map[columnSummary];
    modified = DateTime.fromMillisecondsSinceEpoch(map[columnModified]);
  }

  Future<Tuple2<Map<String, String>, String>> getContents(
      String basePath) async {
    String sss = "";
    Map<String, String> m = Map();
    final f = File(join(basePath, filename));

    var emptySkip = true;

    await f
        .openRead()
        .transform(utf8.decoder) // Decode bytes to UTF-8.
        .transform(new LineSplitter()) // Convert stream to individual lines.
        .listen((String line) {
      // Process results.
      String l = line.toLowerCase();
      if (l.startsWith("#+title")) {
        m["title"] = Parser.parseProp("title", line);
      } else if (line.isNotEmpty || !emptySkip) {
          sss = sss + "$line\n";
          emptySkip = false;
      }
    }).asFuture();

    return Tuple2(m, sss);
  }

  Future<Note> saveContents(
      String basePath, Map<String, String> noteProps, String txt) async {
    if (noteProps != null) {
      var s = "";

      noteProps.forEach((key, value) {
        s += "#+$key: $value\n";
      });

      s += txt;

      final f = File(join(basePath, filename));
      await f.writeAsString(s);

      Note newNote = Parser.parseNoteText(s);

      return newNote;
    } else {
      return null;
    }
  }

  void updateNote(Note newNote) {
    // Update this Note based on how we modified its text.
    title = newNote.title;
    summary = newNote.summary;
    modified = DateTime.now();
  }
}

class NoteProvider {
  Database db;

  Future<void> open(String name) async {
    db = await openDatabase(p.join(await getDatabasesPath(), name), version: 1,
        onCreate: (Database db, int version) async {
      await db.execute('''
create table $tableNote ( 
  $columnId integer primary key autoincrement, 
  $columnTitle text,
  $columnFilename text not null,
  $columnSummary text,
  $columnModified integer not null)
''');
    });
  }

  Future<List<Note>> sync(String path) async {
    // Our syncing algorithm is currently relatively rudimentary:
    // - We delete everything from the existing database
    // - We reinsert all the notes
    // - Once we have a backlink table, we generate this after inserting the
    //   notes

    if (db != null) {
      await deleteAll();
      List<Note> notes = await Parser.parseDir(path);

      for (Note note in notes) {
        insert(note);
      }

      return notes;
    } else {
      return null;
    }
  }

  Future<List<Note>> openAndSync(String path) async {
    await open(
        p.join((await getApplicationSupportDirectory()).path, "sqlite.db"));
    return sync(path);
  }

  Future<Note> insert(Note note) async {
    note?.id = await db.insert(tableNote, note?.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
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
        modified: maps[i]['modified'],
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
          columnModified
        ],
        where: '$columnId = ?',
        whereArgs: [id]);

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
