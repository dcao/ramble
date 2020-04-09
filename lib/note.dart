import 'package:flutter/material.dart';

// TODO: https://uxdesign.cc/level-up-flutter-page-transition-choreographing-animations-across-screens-efb5ea105fca
class NotePage extends StatefulWidget {
  final String titleTag;

  NotePage({Key key, @required this.titleTag}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _NotePageState();
  }
}

class _NotePageState extends State<NotePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Hero(
            child: Text(
              "Title ${widget.titleTag}",
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            tag: widget.titleTag)
      ]),
    );
  }
}
