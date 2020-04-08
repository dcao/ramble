import 'package:path/path.dart';

import 'note.dart';
import 'dart:io';

class Parser {
  static Future<List<Note>> parseDir(String path) {
    var notesDir = Directory(path);

    return notesDir.list()
      .asyncMap((FileSystemEntity entity) async {
        if (entity is File) {
          Note note = await parseNote(entity);
          return note;
        } else {
          return null;
        }
      }).toList();
  }

  static Future<Note> parseNote(File file) async {
    // For now, we just read the entire file rather than trying to read
    // it line-by-line.

    String contents = (await file.readAsString()).toLowerCase();

    String filename = basename(file.path);
    String title = parseProp("title", contents);
    int id = int.parse(parseProp("id", contents));
    int created = int.parse(parseProp("created", contents));
    // TODO: Also for now, our summaries will be lorem ipsum text.
    String summary = "Lorem ipsum dolor amet.";

    // We return a note.
    return Note(
      id: id,
      filename: filename,
      title: title,
      summary: summary,
      created: created,
    );
  }

  static String parseProp(String prop, String txt) {
    int matchIx = txt.indexOf('#+$prop: ');

    if (matchIx != -1) {
      int endIx = txt.indexOf('\n', matchIx);
      return (endIx == -1)
        ? txt.substring(matchIx + prop.length + 5)
        : txt.substring(matchIx + prop.length + 5, endIx);
    } else {
      return null;
    }
  }
}