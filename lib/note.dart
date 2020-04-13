import 'package:flutter/material.dart';
import 'package:sup/components/shared_text.dart';

// TODO: https://uxdesign.cc/level-up-flutter-page-transition-choreographing-animations-across-screens-efb5ea105fca
class NotePage extends StatefulWidget {
  final Object titleTag;
  final String title;

  NotePage({Key key, @required this.title, @required this.titleTag})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _NotePageState();
  }
}

class _NotePageState extends State<NotePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.done),
        onPressed: () {},
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 4.0,
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {},
            ),
          ],
        ),
      ),
      body: Column(children: [
        Hero(
          tag: widget.titleTag,
          child: SharedText(widget.title, viewState: ViewState.enlarged)
        )
      ]),
    );
  }
}
