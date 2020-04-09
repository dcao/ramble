import 'dart:convert';

import 'package:path/path.dart';

import 'note.dart';
import 'dart:io';

class Parser {
  static Future<List<Note>> parseDir(String path) {
    var notesDir = Directory(path);

    return notesDir
        .list()
        .asyncMap((FileSystemEntity entity) async {
          if (entity is File && extension(entity.path) == ".org") {
            Note note = await parseNote(entity);
            return note;
          } else {
            return null;
          }
        })
        .where((event) => event != null)
        .toList();
  }

  static Future<Note> parseNote(File file) async {
    // For now, we just read the entire file rather than trying to read
    // it line-by-line.

    try {
      Note note = Note(filename: basename(file.path), summary: null);

      bool summarized = false;

      file
          .openRead()
          .transform(utf8.decoder) // Decode bytes to UTF-8.
          .transform(new LineSplitter()) // Convert stream to individual lines.
          .listen((String line) {
        // Process results.
        String l = line.toLowerCase();
        if (l.startsWith("#+title")) {
          note.title ??= parseProp("title", line);
        } else if (l.startsWith("#+created")) {
          String createdS = parseProp("created", line);
          note.created ??= createdS == null ? null : int.parse(createdS);
        } else if (!line.startsWith("#") &&
            line.isNotEmpty && !summarized) {
          note.summary = line;
          summarized = true;
        }
      });

      // We return a note.
      note.summary ??= "Empty note";
      return note;
    } on FileSystemException {
      // Can't parse this, return null.
      return null;
    }
  }

  static String parseProp(String prop, String txt) {
    int matchIx = txt.toLowerCase().indexOf('#+$prop: ');

    if (matchIx != -1) {
      int endIx = txt.indexOf('\n', matchIx);
      return (endIx == -1)
          ? txt.substring(matchIx + prop.length + 4)
          : txt.substring(matchIx + prop.length + 4, endIx);
    } else {
      return null;
    }
  }
}
