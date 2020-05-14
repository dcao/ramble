import 'package:path/path.dart';
import 'package:ramble/org/ast.dart';

import 'note.dart';
import 'dart:io';

class Parser {
  static Future<List<Note>> parseDir(String path) {
    var notesDir = Directory(path);

    return notesDir
        .list()
        .asyncMap((FileSystemEntity entity) async {
          if (entity is File && extension(entity.path) == ".org") {
            Note note = await parseNote(entity, notesDir.path);
            return note;
          } else {
            return null;
          }
        })
        .where((event) => event != null)
        .toList();
  }

  static Future<Note> parseNote(File file, String base) async {
    // For now, we just read the entire file rather than trying to read
    // it line-by-line.

    try {
      String str = await file.readAsString();
      return parseNoteText(str,
          filename: relative(file.path, from: base),
          modified: await file.lastModified());
    } on FileSystemException {
      // Can't parse this, return null.
      return null;
    }
  }

  static Note parseNoteText(String txt, {String filename, DateTime modified}) {
    Note note = Note(
      summary: null,
      modified: modified,
      filename: filename,
    );
    bool summarized = false;

    // TODO: Use AST Visitor?
    txt.split("\n").forEach((line) {
      String l = line.toLowerCase();
      if (l.startsWith("#+title")) {
        note.title ??= parseProp("title", line);
      } else if (!line.startsWith("#") && line.isNotEmpty && !summarized) {
        note.summary = line;
        summarized = true;
      }
    });

    // We return a note.
    note.summary ??= "Empty note";
    note.modified ??= DateTime.now();
    return note;
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

class LinkWithCtx {
  String href;
  String context;

  LinkWithCtx(this.href, this.context);
}


class LinkVisitor extends NodeVisitor {
  List<LinkWithCtx> hrefs = [];
  String rootTxt;

  LinkVisitor(this.rootTxt);

  void visitRoot(Root r) {
    for (Node n in r.children) {
      n.accept(this);
    }
  }

  void visitText(PlainText text) {}

  void visitVerbatim(Verbatim text) {}

  void visitLink(Link link) {
    if (link.href.startsWith("file:")) {
      // Our context is the containing line of the link.
      int startIx = rootTxt.lastIndexOf('\n', link.start);
      int endIx = rootTxt.indexOf('\n', link.end);

      startIx = startIx == -1 ? 0 : startIx + 1;
      endIx = endIx == -1 ? rootTxt.length : endIx;

      hrefs.add(LinkWithCtx(link.href, rootTxt.substring(startIx, endIx)));
    }
  }

  void visitHeading(Heading heading) {
    for (InlineNode node in heading.title) {
      node.accept(this);
    }
    if (heading.text != null) {
      for (Node node in heading.text) {
        node.accept(this);
      }
    }
  }

  void visitIBS(InBufferSetting ibs) {}
}
