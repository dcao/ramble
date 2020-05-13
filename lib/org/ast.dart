abstract class Node {
  void accept(NodeVisitor visitor);
}

abstract class InlineNode extends Node {}

class Root extends Node {
  List<Node> children;

  Root(this.children);

  void accept(NodeVisitor visitor) {
    visitor.visitRoot(this);
  }
}

class Heading extends Node {
  int level;
  List<InlineNode> title;
  List<Node> text;

  Heading(this.level, this.title, this.text);

  void accept(NodeVisitor visitor) {
    visitor.visitHeading(this);
  }
}

class InBufferSetting extends Node {
  String setting;
  String value;

  InBufferSetting(this.setting, this.value);

  void accept(NodeVisitor visitor) {
    visitor.visitIBS(this);
  }
}

class Link extends InlineNode {
  String href;
  List<InlineNode> text;

  Link(this.href, [this.text]);

  void accept(NodeVisitor visitor) {
    visitor.visitLink(this);
  }
}

class PlainText extends InlineNode {
  String text;

  PlainText(this.text);

  void append(String x) {
    this.text += x;
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