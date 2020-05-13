import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ramble/components/constantly_notched_rectangle.dart';
import 'package:ramble/components/docked_fab_position.dart';
import 'package:ramble/components/org_text_controller.dart';
import 'package:ramble/settings.dart';
import 'package:tuple/tuple.dart';

import 'backend/note.dart';
import 'org/ast.dart';

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
  Future<void> nd;

  AnimationController _ac;
  Animation<Offset> _bottomBarAnim;
  Animation<Offset> _appBarAnim;
  Animation<double> _fabAnim;
  Animation<double> _tfOpacityAnim;

  final _bodyTC = OrgTextController();
  final _titleTC = TextEditingController();

  Map<String, String> noteProps;

  static final Duration xlen = Duration(milliseconds: 250);

  final g = CorrectEndDockedFABLoc();

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

    _titleTC.text = widget.title;

    nd = _noteData();
  }

  Future<void> _noteData() async {
    await Future.delayed(Duration(milliseconds: 330));

    await pf.init();

    Tuple2<Map<String, String>, String> res =
        await widget.note?.getContents(pf.getNotesFolder());

    if (widget.note != null) {
      noteProps = res.item1;
      _bodyTC.text = res.item2;
    } else {
      noteProps = Map();
      noteProps["title"] = widget.title;
    }

    _ac.forward(from: 0.0);

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
    _bodyTC.dispose();
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
        onPressed: () async {
          await _pop();
          Navigator.pop(context);
        },
      ),
    );

    return WillPopScope(
        onWillPop: _pop,
        child: Scaffold(
          floatingActionButtonLocation: g,
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
              onPressed: () async {
                noteProps["title"] = _titleTC.text;
                await _pop();
                Navigator.of(context).pop(Tuple2(noteProps, _bodyTC.text));
              },
            ),
          ),
          bottomNavigationBar: Transform.translate(
              offset:
                  Offset(0.0, -1 * MediaQuery.of(context).viewInsets.bottom),
              child: SlideTransition(
                position: _bottomBarAnim,
                child: BottomAppBar(
                  shape: ConstantlyNotchedRectangle(),
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
                          child: TextFormField(
                            controller: _titleTC,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            style: TextStyle(
                              fontSize: 28.0,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              hintText: "Title",
                            ),
                          )),
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
                          controller: _bodyTC,
                          keyboardType: TextInputType.multiline,
                          style: TextStyle(
                            color: Colors.grey[800],
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Write something",
                          ),
                          maxLines: null,
                        ),
                      ),
                    ])),
          ),
        ));
  }
}
