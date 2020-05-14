import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ramble/org/ast.dart';
import 'package:ramble/org/parser.dart' hide Parser;
import 'package:slugify/slugify.dart';
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

final String tableLink = 'link';
final String columnFrom = 'linkFrom';
final String columnTo = 'linkTo';
final String columnCtx = 'linkCtx';

class Note {
  int id;
  String title;
  String filename;
  String summary;
  DateTime modified;
  List<LinkWithCtx> hrefs;

  void genHrefsFromTxt(String txt) {
    ParserRunner pr = ParserRunner();
    LinkVisitor lv = LinkVisitor(txt);
    Root r = pr.parseRoot(txt);

    r.accept(lv);

    this.hrefs = lv.hrefs;
  }

  Future<void> genHrefs(String basePath) async {
    String txt = await File(join(basePath, filename)).readAsString();

    genHrefsFromTxt(txt);

    return null;
  }

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

  // TODO: Use AST Visitor?
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

  static String fileFromTitle(DateTime creation, String title) {
    return '${DateFormat("yyyyMMddHHmmss").format(creation)}_${Slugify(title, delimiter: '_')}.org';
  }

  static Future<Note> saveContents(Map<String, String> noteProps, String txt,
      {String filename, String basename}) async {
    if (noteProps != null && (filename != null || basename != null)) {
      var s = "";

      noteProps.forEach((key, value) {
        s += "#+$key: $value\n";
      });

      s += "\n" + txt;

      if (filename == null && basename != null) {
        filename =
            join(basename, fileFromTitle(DateTime.now(), noteProps["title"]));
      }
      final f = File(filename);
      await f.writeAsString(s);

      Note newNote = Parser.parseNoteText(s);

      newNote.filename = filename;
      newNote.genHrefsFromTxt(txt);

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
    hrefs = newNote.hrefs;
  }

  @override
  String toString() {
    return "Note(filename: $filename, title: $title, summary: $summary)";
  }
}

class NoteProvider {
  Database db;

  _onConfigure(Database db) async {
    await db.execute("PRAGMA foreign_keys = ON");
  }

  Future<void> open(String name) async {
    db = await openDatabase(p.join(await getDatabasesPath(), name),
        onConfigure: _onConfigure,
        version: 1, onCreate: (Database db, int version) async {
      await db.execute('''
create table $tableNote ( 
  $columnId integer primary key autoincrement, 
  $columnTitle text,
  $columnFilename text not null,
  $columnSummary text,
  $columnModified integer not null)
''');
      await db.execute('''
create table $tableLink ( 
  $columnId integer primary key autoincrement, 
  $columnFrom integer not null,
  $columnTo integer not null,
  $columnCtx text not null,
  foreign key ($columnFrom) references $tableNote ($columnId) on delete cascade,
  foreign key ($columnTo) references $tableNote ($columnId) on delete cascade)
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

      // When syncing, we have to go in two passes:
      // First, we add all the notes in.
      // Then, we can add the links by going thru the notes again.

      for (Note note in notes) {
        await insert(note);
      }

      for (Note note in notes) {
        await note.genHrefs(path);
        await insertHrefs(note);
      }

      return notes;
    } else {
      return null;
    }
  }

  Future<List<Note>> openAndSync(String path) async {
    await open(
        p.join((await getApplicationSupportDirectory()).path, "asdasddadad.db"));
    return sync(path);
  }

  Future<Note> insert(Note note) async {
    note?.id = await db.insert(tableNote, note?.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    if (note.hrefs != null) {
      insertHrefs(note);
    }
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

  Future<int> getNoteIdByFilename(String filename) async {
    List<Map> maps = await db.query(tableNote,
        columns: [
          columnId,
        ],
        where: '$columnFilename = ?',
        whereArgs: [filename]);

    if (maps.length > 0) {
      return maps.first[columnId];
    }

    return null;
  }

  Future<int> delete(int id) async {
    return await db.delete(tableNote, where: '$columnId = ?', whereArgs: [id]);
  }

  Future deleteAll() async {
    await db.delete(tableNote);
    await db.delete(tableLink);
  }

  Future<int> update(Note todo) async {
    int res = await db.update(tableNote, todo.toMap(),
        where: '$columnId = ?', whereArgs: [todo.id]);

    if (todo.hrefs != null) {
      await deleteFroms(todo);
      await insertHrefs(todo);
    }

    return res;
  }

  Future<int> updateByFilename(Note todo) async {
    return await db.update(tableNote, todo.toMap(),
        where: '$columnFilename = ?', whereArgs: [todo.filename]);
  }

  Future insertHrefs(Note n) async {
    for (LinkWithCtx l in n.hrefs) {
      // Get rid of the file: prefix
      String href = l.href.substring(5);

      // Then find the note id by filename
      int id = await getNoteIdByFilename(href);

      if (id != null) {
        await addLink(n.id, id, l.context);
      }
    }

    return null;
  }

  Future deleteFroms(Note n) async {
    await db.delete(tableLink, where: "$columnId = ?", whereArgs: [n.id]);
  }

  Future<int> addLink(int from, int to, String ctx) async {
    return await db
        .insert(tableLink, {columnFrom: from, columnTo: to, columnCtx: ctx});
  }

  Future<List<Note>> findBacklinks(int to) async {
    List<Map<String, dynamic>> ls = await db.rawQuery('''
select $tableNote.$columnId, $tableNote.$columnTitle, $tableNote.$columnFilename, $tableNote.$columnModified, $tableLink.$columnCtx as $columnSummary
from $tableLink inner join $tableNote on $tableNote.$columnId = $tableLink.$columnFrom where $tableLink.$columnTo = $to
''');
    return ls.map((e) => Note.fromMap(e)).toList();
  }

  Future close() async => db.close();
}
