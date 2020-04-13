import 'package:flutter/material.dart';
import 'package:sup/components/shared_text.dart';
import 'package:sup/settings.dart';

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
  Future<String> nd;

  AnimationController _ac;
  Animation<Offset> _bottomBarAnim;
  Animation<double> _fabAnim;
  Animation<double> _tfOpacityAnim;

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

  Future<String> _noteData() async {
    await Future.delayed(Duration(milliseconds: 330));

    await pf.init();

    String res = await widget.note?.getContents(pf.getNotesFolder());

    _ac.forward(from: 0.0);

    return res;
  }

  Future<bool> _pop() async {
    _ac.reverse(from: 1.0);
    await Future.delayed(Duration(milliseconds: 50));
    return true;
  }

  void _save() async {
    // TODO
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _pop,
        child: FutureBuilder(
            future: nd,
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              _controller.text = snapshot.data;

              return Scaffold(
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.endDocked,
                floatingActionButton: ScaleTransition(
                  scale: _fabAnim,
                  child: FloatingActionButton(
                    child: const Icon(Icons.done),
                    onPressed: _save,
                  ),
                ),
                bottomNavigationBar: SlideTransition(
                  position: _bottomBarAnim,
                  child: BottomAppBar(
                    shape: CircularNotchedRectangle(),
                    notchMargin: 4.0,
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
                ),
                body: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                          tag: widget.titleTag,
                          child: SharedText(widget.title,
                              viewState: ViewState.enlarged)),
                      FadeTransition(
                        opacity: _tfOpacityAnim,
                        child: TextFormField(
                          controller: _controller,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                        ),
                      ),
                    ]),
              );
            }));
  }
}
