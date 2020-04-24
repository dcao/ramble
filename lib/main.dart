import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:morpheus/morpheus.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ramble/backend/note.dart';
import 'package:ramble/components/sparse_note.dart';
import 'package:ramble/settings.dart';
import 'package:ramble/themes.dart';
import 'package:ramble/components/circle_tab_indicator.dart';
import 'package:ramble/note.dart';

import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:tuple/tuple.dart';

void main() {
  timeDilation = 1.0;

  runApp(Ramble());
}

class Ramble extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: Themes.light,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Tab> myTabs = [
    Tab(text: "remember"),
    Tab(text: "note"),
    Tab(text: "capture"),
  ];

  final Future<PrefsHelper> helper = PrefsHelper().init();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: helper,
        builder: (BuildContext context, AsyncSnapshot<PrefsHelper> snapshot) {
          if (snapshot.hasData) {
            return DefaultTabController(
              length: myTabs.length,
              initialIndex: snapshot.data.getDefaultScreenAsInt(),
              child: Scaffold(
                appBar: AppBar(
                  // backgroundColor: Colors.white,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(8.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TabBar(
                                indicator: CircleTabIndicator(
                                    color: Theme.of(context).accentColor,
                                    radius: 3),
                                tabs: myTabs,
                                isScrollable: true,
                                labelPadding:
                                    EdgeInsets.only(left: 8, right: 8),
                                labelColor: Colors.black54,
                                labelStyle: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontFamily: "Axiforma"),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.settings, color: Colors.black54),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SettingsPage()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                body: TabBarView(
                  children: [
                    Container(),
                    NovelPage(helper: snapshot.data),
                    Container(),
                  ],
                ),
              ),
            );
          } else {
            return Container();
          }
        });
  }
}

class CapturePage extends StatefulWidget {
  CapturePage({Key key}) : super(key: key);

  @override
  _CapturePageState createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> {
  @override
  Widget build(BuildContext context) {
    return null;
  }
}

// TODO: Implement swipe actions on notes
// https://stackoverflow.com/questions/46651974/swipe-list-item-for-more-options-flutter
// https://flutter.dev/docs/cookbook/gestures/dismissible
class NovelPage extends StatefulWidget {
  NovelPage({Key key, @required this.helper}) : super(key: key);

  final PrefsHelper helper;

  @override
  _NovelPageState createState() => _NovelPageState();
}

class _NovelPageState extends State<NovelPage> {
  static const TextFieldHero = "tfhero";

  NoteProvider _db = NoteProvider();
  Future<List<Note>> _notes;
  Fuzzy<Note> fuse;
  List<Note> _searchNotes;
  GlobalKey _refreshKey = GlobalKey<RefreshIndicatorState>();
  final myController = TextEditingController();
  Timer _debounce;

  final _textFieldKey = GlobalKey();

  bool snInvalid = true;

  @override
  void initState() {
    super.initState();
    _notes = _db.openAndSync(widget.helper.getNotesFolder());
    myController.addListener(_search);
    _handlePerms();
  }

  _handlePerms() async {
    print(await Permission.storage.request().isGranted);
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    myController.removeListener(_search);
    myController.dispose();
    super.dispose();
  }

  _search() {
    if (_debounce?.isActive ?? false) _debounce.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      final res = fuse.search(myController.text);
      setState(() {
        _searchNotes = res.map((r) => r.item).toList();
      });
    });
  }

  Future<void> _refresh() {
    snInvalid = false;
    setState(() {
      _notes = _db.sync(widget.helper.getNotesFolder());
    });

    return _notes;
  }

  _onSparseNoteTap(
      SparseNote sp, Tuple2<Map<String, String>, String> res) async {
    // If the whole res is null, we cancelled.
    // If the first element in the tuple is null, we backed out
    // before the future was finished.
    if (res != null && res.item1 != null) {
      // await Future.delayed(Duration(milliseconds: 500));
      Note newNote = await Note.saveContents(
        res.item1,
        res.item2,
        filename: join(widget.helper.getNotesFolder(), sp.note.filename),
      );
      setState(() {
        sp.note.updateNote(newNote);
      });
      _db.update(sp.note);
    }
  }

  _onNewNote(BuildContext context, String str) async {
    Tuple2<Map<String, String>, String> res =
        await Navigator.of(context).push(MorpheusPageRoute(
            builder: (context) => NotePage(
                  title: myController.text,
                  titleTag: TextFieldHero,
                ),
            parentKey: _textFieldKey));

    if (res != null && res.item1 != null) {
      Note newNote = await Note.saveContents(
        res.item1,
        res.item2,
        basename: widget.helper.getNotesFolder(),
      );

      _db.insert(newNote);

      snInvalid = true;
      _buildFuse(fuse.list..insert(0, newNote));

      setState(() {
        _searchNotes.insert(0, newNote);
      });
    }
  }

  _buildFuse(List<Note> data) {
    fuse = Fuzzy(
      data,
      options: FuzzyOptions(
        keys: [
          WeightedKey(
              name: "titleOrFilename",
              getter: (x) => x.titleOrFilename(),
              weight: 1.0),
          WeightedKey(name: "summary", getter: (x) => x.summary, weight: 0.0),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _notes,
      builder: (BuildContext context, AsyncSnapshot<List<Note>> snapshot) {
        if (snapshot.hasData) {
          if (snInvalid) {
            _buildFuse(snapshot.data);

            final res = fuse.search(myController.text);
            _searchNotes = res.map((r) => r.item).toList();
            snInvalid = false;
          }

          return Container(
              padding: EdgeInsets.only(top: 16),
              child: Stack(
                children: <Widget>[
                  Align(
                      alignment: Alignment.topLeft,
                      child: RefreshIndicator(
                          key: _refreshKey,
                          onRefresh: _refresh,
                          child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _searchNotes.length,
                              itemBuilder: (note, index) {
                                final note = _searchNotes[index];

                                return SparseNote(
                                    note: note,
                                    titleKey: index,
                                    onTap: _onSparseNoteTap);
                              }))),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Material(
                      key: _textFieldKey,
                      child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 1,
                                    offset: Offset(0, -2))
                              ]),
                          child: Hero(
                            tag: TextFieldHero,
                            child: TextFormField(
                              controller: myController,
                              decoration: InputDecoration(
                                hintText: "ramble",
                                contentPadding: EdgeInsets.only(
                                    bottom: 16, top: 16, left: 20, right: 20),
                                border: InputBorder.none,
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 28,
                              ),
                              onFieldSubmitted: (String str) {
                                _onNewNote(context, str);
                              },
                              autofocus: false,
                            ),
                          )),
                    ),
                  ),
                ],
              ));
        } else {
          return Container();
        }
      },
    );
  }
}
