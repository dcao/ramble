import 'package:tuple/tuple.dart';
import 'ast.dart';

// TODO: Diff name
class ParserRunner {
  List<Parser> parsers = [
    HeadingParser(),
    IBSParser(),
    LinkParser(),
    VerbatimParser(),
  ];

  // We have to handle Inline and BlockParsers differently when parsing, so we
  // follow the following rule: we are only allowed to parse a block element
  // at the start of the doc or after a newline. This prevents us from parsing
  // "[[lol][test]]* test" as a link followed by a heading (the correct parse
  // is link followed by text)
  List<Node> parse(String input, {bool inlineOnly = false, int startIx = 0}) {
    List<Node> res = [];
    bool blockDisabled = false;
    PlainText defNode;

    while (input.isNotEmpty) {
      for (Parser parser in parsers) {
        if (parser is InlineParser || (!inlineOnly && !blockDisabled)) {
          Node pres = parser.tryParse(this, input, startIx);
          if (pres != null) {
            // We first append our defNode if it exists
            if (defNode != null) {
              res.add(defNode);
              defNode = null;
            }

            if (parser is InlineParser) {
              blockDisabled = true;
            }

            // We then advance our parser and add the node.
            res.add(pres);
            input = input.substring(pres.end - pres.start);
            startIx += pres.end - pres.start;
            continue;
          }
        }
      }

      // None of our parsers worked, so we have to update blockDisabled and add
      // to our defNode before advancing the parser.
      // TODO: idk why we need this block
      if (input.isEmpty) {
        break;
      }

      if (defNode == null) {
        defNode = PlainText(input[0], startIx, startIx + 1);
      } else {
        defNode.append(input[0]);
      }

      blockDisabled = input[0] != "\n";
      input = input.substring(1);
      startIx++;
    }

    if (defNode != null) {
      res.add(defNode);
    }

    return res;
  }

  Root parseRoot(String input) {
    return Root(parse(input), 0, input.length);
  }

  List<InlineNode> inlineParse(String input, {int startIx = 0}) {
    return parse(input, inlineOnly: true, startIx: startIx)
        .map((e) => e as InlineNode)
        .toList();
  }
}

abstract class Parser {
  /// tryParse attempts to parse whatever is at the start of the text.
  /// If the input is unparsable, tryParse returns null. Otherwise, tryParse
  /// returns the Node parsed along with the number of characters to advance
  /// the parser state by.
  Node tryParse(ParserRunner pr, String input, int startIx);
}

abstract class InlineParser extends Parser {
  InlineNode tryParse(ParserRunner pr, String input, int startIx);
}

class HeadingParser extends Parser {
  Node tryParse(ParserRunner pr, String input, int startIx) {
    RegExp exp = RegExp(r"^(\*+) (.*)$", multiLine: true);
    RegExpMatch m = exp.matchAsPrefix(input);

    if (m != null) {
      // We match!
      int level = m.group(1).length;
      List<InlineNode> title =
          pr.inlineParse(m.group(2), startIx: startIx + level + 1);

      // We then find the next heading with at the same or less level:
      RegExpMatch nexm =
          RegExp(r"^\*{1," + level.toString() + r"} (.*)\$", multiLine: true)
              .firstMatch(input.substring(m.end));

      String body =
          input.substring(m.end, nexm == null ? null : m.end + nexm.start);
      List<Node> text = pr.parse(body, startIx: startIx + m.group(0).length);

      Heading node = Heading(level, title, text, startIx,
          startIx + m.group(0).length + body.length);

      return node;
    } else {
      return null;
    }
  }
}

class IBSParser extends Parser {
  Node tryParse(ParserRunner pr, String input, int startIx) {
    RegExp exp = RegExp(r"^#\+(.*): (.+)$", multiLine: true);
    RegExpMatch m = exp.matchAsPrefix(input);

    if (m != null) {
      // We match!
      String prop = m.group(1);
      String val = m.group(2);

      InBufferSetting node =
          InBufferSetting(prop, val, startIx, startIx + m.group(0).length);

      return node;
    } else {
      return null;
    }
  }
}

class LinkParser extends InlineParser {
  InlineNode tryParse(ParserRunner pr, String input, int startIx) {
    RegExp exp = RegExp(r"\[(?:\[(.*?)\])?\[(.*?)\]\]");
    RegExpMatch m = exp.matchAsPrefix(input);

    if (m != null) {
      // We match!
      String href = m.group(1) == null ? m.group(2) : m.group(1);
      List<InlineNode> text = m.group(1) == null
          ? null
          : pr.inlineParse(m.group(2), startIx: startIx + href.length + 4);

      Link node = Link(href, startIx, startIx + m.group(0).length, text: text);

      return node;
    } else {
      return null;
    }
  }
}

class VerbatimParser extends InlineParser {
  InlineNode tryParse(ParserRunner pr, String input, int startIx) {
    RegExp exp = RegExp(r"=(?=[^\s])(.*?)(?<=[^\s])=");
    RegExpMatch m = exp.matchAsPrefix(input);

    if (m != null) {
      // We match!
      Verbatim node =
          Verbatim(m.group(1), startIx, startIx + m.group(0).length);

      return node;
    } else {
      return null;
    }
  }
}
