import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ramble/components/shared_text.dart';
import 'package:ramble/settings.dart';
import 'package:tuple/tuple.dart';

import 'backend/note.dart';

class NotePage extends StatefulWidget {
  final Object titleTag;
  final String title;
  final Note note;

  NotePage({Key key, @required this.title, @required this.titleTag, this.note})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _NotePageState();
  }
}

class _NotePageState extends State<NotePage>
    with SingleTickerProviderStateMixin {
  final pf = PrefsHelper();
  final _controller = TextEditingController();
  Future<void> nd;

  AnimationController _ac;
  Animation<Offset> _bottomBarAnim;
  Animation<Offset> _appBarAnim;
  Animation<double> _fabAnim;
  Animation<double> _tfOpacityAnim;

  Map<String, String> noteProps;

  static final Duration xlen = Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();

    _ac = AnimationController(
      duration: xlen,
      vsync: this,
    );

    _bottomBarAnim = Tween<Offset>(
      begin: Offset(0, 2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ac,
      curve: Interval(0.0, 1.0, curve: Curves.easeOutQuint),
    ));

    _appBarAnim = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ac,
      curve: Interval(0.3, 1.0, curve: Curves.easeOutQuint),
    ));

    _fabAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _ac,
      curve: Interval(0.0, 1.0, curve: Curves.easeOutQuint),
    ));

    _tfOpacityAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _ac,
      curve: Interval(0.65, 1.0, curve: Curves.easeOut),
    ));

    nd = _noteData();
  }

  Future<void> _noteData() async {
    await Future.delayed(Duration(milliseconds: 330));

    await pf.init();

    Tuple2<Map<String, String>, String> res =
        await widget.note?.getContents(pf.getNotesFolder());

    noteProps = res.item1;

    _ac.forward(from: 0.0);

    _controller.text = res.item2;

    return null;
  }

  Future<bool> _pop() async {
    _ac.reverse(from: 1.0);
    await Future.delayed(Duration(milliseconds: 50));
    return true;
  }

  @override
  void dispose() {
    _ac.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppBar ab = AppBar(
      elevation: 1.0,
      backgroundColor: Colors.grey[50],
      leading: IconButton(
        iconSize: 20.0,
        padding: EdgeInsets.only(bottom: 4.0),
        icon: Icon(Icons.clear, color: Colors.black54),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );

    return WillPopScope(
        onWillPop: _pop,
        child: Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
          backgroundColor: Colors.grey[50],
          appBar: PreferredSize(
            preferredSize: ab.preferredSize,
            child: SlideTransition(
              position: _appBarAnim,
              child: ab,
            ),
          ),
          floatingActionButton: ScaleTransition(
            scale: _fabAnim,
            child: FloatingActionButton(
              child: const Icon(Icons.done),
              onPressed: () {
                var contents = _controller.text;
                Navigator.of(context).pop(Tuple2(noteProps, contents));
              },
            ),
          ),
          bottomNavigationBar: SlideTransition(
              position: _bottomBarAnim,
              child: Transform.translate(
                offset:
                    Offset(0.0, -1 * MediaQuery.of(context).viewInsets.bottom),
                child: BottomAppBar(
                  shape: CircularNotchedRectangle(),
                  notchMargin: 8.0,
                  child: new Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.link),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              )),
          body: SingleChildScrollView(
            child: Container(
                padding: EdgeInsets.only(
                    left: 20.0, right: 20.0, bottom: 16.0, top: 36.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                          tag: widget.titleTag,
                          child: SharedText(widget.title,
                              smallFontSize: 16.0,
                              largeFontSize: 28.0,
                              viewState: ViewState.enlarged)),
                      SizedBox(height: 4.0),
                      FadeTransition(
                          opacity: _tfOpacityAnim,
                          child: Text(
                            "Last edited: " +
                                (widget.note != null
                                    ? DateFormat.yMMMd()
                                        .add_jm()
                                        .format(widget.note.modified)
                                    : "right now"),
                            style: TextStyle(color: Colors.grey[500]),
                          )),
                      SizedBox(height: 32.0),
                      FadeTransition(
                        opacity: _tfOpacityAnim,
                        child: TextFormField(
                          controller: _controller,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Write something...",
                          ),
                          maxLines: null,
                        ),
                      ),
                    ])),
          ),
        ));
  }
}
