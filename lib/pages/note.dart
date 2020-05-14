import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:ramble/components/constantly_notched_rectangle.dart';
import 'package:ramble/components/docked_fab_position.dart';
import 'package:ramble/components/org_text_controller.dart';
import 'package:ramble/components/sparse_note.dart';
import 'package:ramble/pages/settings.dart';
import 'package:tuple/tuple.dart';

import '../backend/note.dart';

class BacklinksChip extends StatelessWidget {
  final List<Note> backlinks;
  final NoteProvider db;

  BacklinksChip(this.backlinks, this.db) : super();

  _onSparseNoteTap(
      SparseNote sp, Tuple2<Map<String, String>, String> res) async {
    // If the whole res is null, we cancelled.
    // If the first element in the tuple is null, we backed out
    // before the future was finished.
    if (res != null && res.item1 != null) {
      // await Future.delayed(Duration(milliseconds: 500));
      PrefsHelper helper = await PrefsHelper().init();
      await Note.saveContents(
        res.item1,
        res.item2,
        filename: join(helper.getNotesFolder(), sp.note.filename),
      );

      // TODO: More stuff?
    }
  }

  @override
  Widget build(BuildContext context) {
    if (backlinks.length > 0) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        color: Colors.blueGrey[500],
        margin: EdgeInsets.only(bottom: 12.0),
        elevation: 10,
        clipBehavior: Clip.antiAlias,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ExpandablePanel(
            theme: const ExpandableThemeData(
              headerAlignment: ExpandablePanelHeaderAlignment.center,
              tapBodyToExpand: true,
              tapBodyToCollapse: true,
              hasIcon: true,
            ),
            expanded: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: backlinks
                  .asMap()
                  .entries
                  .map((e) => SparseNote(
                      note: e.value,
                      titleKey: e.key,
                      color: Colors.blueGrey[50],
                      onTap: _onSparseNoteTap,
                      db: db,
                      maxLines: 2) as Widget)
                  .toList()
                    ..add(SizedBox(height: 4)),
            ),
            header: Container(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        backlinks.length == 1
                            ? "1 backlink"
                            : "${backlinks.length} backlinks",
                        style: Theme.of(context).textTheme.bodyText2.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      );
    } else {
      return Container();
    }
  }
}

class NotePage extends StatefulWidget {
  final Object titleTag;
  final String title;
  final Note note;

  final NoteProvider db;

  NotePage(
      {Key key,
      @required this.title,
      @required this.titleTag,
      @required this.db,
      this.note})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _NotePageState();
  }
}

class _NotePageState extends State<NotePage>
    with SingleTickerProviderStateMixin {
  final pf = PrefsHelper();
  Future<List<Note>> nd;

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

  Future<List<Note>> _noteData() async {
    await Future.delayed(Duration(milliseconds: 330));

    await pf.init();

    Tuple2<Map<String, String>, String> res =
        await widget.note?.getContents(pf.getNotesFolder());

    List<Note> backlinks = await widget.db.findBacklinks(widget.note.id);

    if (widget.note != null) {
      noteProps = res.item1;
      _bodyTC.text = res.item2;
    } else {
      noteProps = Map();
      noteProps["title"] = widget.title;
    }

    _ac.forward(from: 0.0);

    return backlinks;
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

    return FutureBuilder(
        future: nd,
        builder: (context, snapshot) {
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
                      Navigator.of(context)
                          .pop(Tuple2(noteProps, _bodyTC.text));
                    },
                  ),
                ),
                bottomNavigationBar: Transform.translate(
                    offset: Offset(
                        0.0, -1 * MediaQuery.of(context).viewInsets.bottom),
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            SizedBox(height: 20.0),
                            FadeTransition(
                                opacity: _tfOpacityAnim,
                                child: snapshot.hasData
                                    ? BacklinksChip(snapshot.data, widget.db)
                                    : Container()),
                            SizedBox(height: 12.0),
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
        });
  }
}
