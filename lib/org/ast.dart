abstract class Node {
  int start; // Inclusive
  int end; // Exclusive

  Node(this.start, this.end);

  void accept(NodeVisitor visitor);
}

abstract class InlineNode extends Node {
  InlineNode(int start, int end) : super(start, end);
}

class Root extends Node {
  List<Node> children;

  Root(this.children, int start, int end) : super(start, end);

  void accept(NodeVisitor visitor) {
    visitor.visitRoot(this);
  }
}

class Heading extends Node {
  int level;
  List<InlineNode> title;
  List<Node> text;

  Heading(this.level, this.title, this.text, int start, int end) : super(start, end);

  void accept(NodeVisitor visitor) {
    visitor.visitHeading(this);
  }
}

class InBufferSetting extends Node {
  String setting;
  String value;

  InBufferSetting(this.setting, this.value, int start, int end) : super(start, end);

  void accept(NodeVisitor visitor) {
    visitor.visitIBS(this);
  }
}

class Link extends InlineNode {
  String href;
  List<InlineNode> text;

  Link(this.href, int start, int end, {this.text}) : super(start, end);

  void accept(NodeVisitor visitor) {
    visitor.visitLink(this);
  }
}

class Verbatim extends InlineNode {
  String text;

  Verbatim(this.text, int start, int end) : super(start, end);

  void accept(NodeVisitor visitor) {
    visitor.visitVerbatim(this);
  }
}

class PlainText extends InlineNode {
  String text;

  PlainText(this.text, int start, int end) : super(start, end);

  void append(String x) {
    this.text += x;
    this.end++;
  }

  void accept(NodeVisitor visitor) {
    visitor.visitText(this);
  }
}

/// Visitor pattern for the AST.
///
/// Renderers or other AST transformers should implement this.
abstract class NodeVisitor {
  void visitRoot(Root text);
  void visitText(PlainText text);
  void visitVerbatim(Verbatim text);
  void visitLink(Link link);
  void visitHeading(Heading heading);
  void visitIBS(InBufferSetting ibs);
}

class DebugPrinter extends NodeVisitor {
  void visitRoot(Root r) {
    for (Node n in r.children) {
      n.accept(this);
    }
  }

  void visitText(PlainText text) {
    print("PlainText: ${text.text}");
  }

  void visitVerbatim(Verbatim text) {
    print("Verbatim: ${text.text}");
  }

  void visitLink(Link link) {
    print("Link: ${link.href}");
    if (link.text != null) {
      for (InlineNode node in link.text) {
        node.accept(this);
      }
    }
    print("end Link");
  }

  void visitHeading(Heading heading) {
    print("Heading ${heading.level}");
    for (InlineNode node in heading.title) {
      node.accept(this);
    }
    if (heading.text != null) {
      for (Node node in heading.text) {
        node.accept(this);
      }
    }
    print("end Heading");
  }

  void visitIBS(InBufferSetting ibs) {
    print("InBufferSetting: ${ibs.setting} -> ${ibs.value}");
  }
}