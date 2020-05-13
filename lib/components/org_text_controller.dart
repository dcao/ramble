import 'package:flutter/material.dart';
import 'package:ramble/org/ast.dart';
import 'package:ramble/org/parser.dart';

class OrgRenderer extends NodeVisitor {
  List<InlineSpan> spans = [];
  TextStyle style;

  OrgRenderer(this.style);

  void visitRoot(Root r) {
    for (Node n in r.children) {
      n.accept(this);
    }
  }

  void visitText(PlainText text) {
    spans.add(TextSpan(style: style, text: text.text));
  }

  void visitVerbatim(Verbatim text) {
    spans.add(TextSpan(
        style: style.copyWith(fontFamily: "monospace"),
        text: "=${text.text}="));
  }

  void visitLink(Link link) {
    spans.add(TextSpan(
        style: style.copyWith(color: Colors.black26), text: "[["));
    if (link.text == null) {
      spans.add(TextSpan(
          style: style.copyWith(
              fontWeight: FontWeight.w600, color: Colors.blueGrey[500]),
          text: link.href));
    } else {
      spans.add(TextSpan(
          style: style.merge(TextStyle(color: Colors.black26)),
          text: "${link.href}]["));
      TextStyle old = style;
      style = style.copyWith(
        fontWeight: FontWeight.w600,
        color: Colors.blueGrey[500],
      );
      for (InlineNode n in link.text) {
        n.accept(this);
      }
      style = old;
    }
    spans.add(TextSpan(
        style: style.copyWith(color: Colors.black26), text: "]]"));
  }

  void visitHeading(Heading heading) {
    TextStyle old = style;
    style = style.copyWith(
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    );
    spans.add(TextSpan(
      style: style.copyWith(color: Colors.black26),
      text: "*" * heading.level + " ",
    ));

    for (InlineNode n in heading.title) {
      n.accept(this);
    }

    style = old;

    for (Node n in heading.text) {
      n.accept(this);
    }
  }

  // No-op
  void visitIBS(InBufferSetting ibs) {
    spans.add(TextSpan(
        style: style.copyWith(color: Colors.black26),
        text: "#+${ibs.setting}: ${ibs.value}"));
  }
}

class OrgTextController extends TextEditingController {
  TextSpan buildTextSpan({TextStyle style, bool withComposing}) {
    ParserRunner pr = ParserRunner();
    OrgRenderer r = OrgRenderer(style);
    Root parsed = pr.parseRoot(value.text);

    parsed.accept(r);

    return TextSpan(style: style, children: r.spans);
  }
}
