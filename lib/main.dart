import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:morpheus/morpheus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sup/backend/note.dart';
import 'package:sup/components/sparse_note.dart';
import 'package:sup/settings.dart';
import 'package:sup/themes.dart';
import 'package:sup/components/circle_tab_indicator.dart';

import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:tuple/tuple.dart';

void main() {
  timeDilation = 1.0;

  runApp(Sup());
}

class Sup extends StatelessWidget {
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
  NoteProvider _db = NoteProvider();
  Future<List<Note>> _notes;
  Fuzzy<Note> fuse;
  List<Note> _searchNotes;
  GlobalKey _refreshKey = GlobalKey<RefreshIndicatorState>();
  final myController = TextEditingController();
  Timer _debounce;

  final _textFieldKey = GlobalKey();

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

  _onSparseNoteTap(SparseNote sp, Tuple2<Map<String, String>, String> res) {
    // If the whole res is null, we cancelled.
    // If the first element in the tuple is null, we backed out
    // before the future was finished.
    if (res != null && res.item1 != null) {
      setState(() {
        // sp.note.saveContents(widget.helper.getNotesFolder(), res.item1, res.item2);
        sp.note.title = "yeet";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _notes,
      builder: (BuildContext context, AsyncSnapshot<List<Note>> snapshot) {
        if (snapshot.hasData) {
          fuse = Fuzzy(
            snapshot.data,
            options: FuzzyOptions(
              keys: [
                WeightedKey(
                    name: "titleOrFilename",
                    getter: (x) => x.titleOrFilename(),
                    weight: 1.0),
                WeightedKey(
                    name: "summary", getter: (x) => x.summary, weight: 0.0),
              ],
            ),
          );
          if (_searchNotes == null) {
            _searchNotes = snapshot.data;
          }

          return Container(
              padding: EdgeInsets.only(top: 16),
              child: Stack(
                children: <Widget>[
                  Align(
                      alignment: Alignment.topLeft,
                      child: RefreshIndicator(
                          key: _refreshKey,
                          onRefresh: () {
                            // TODO: This doesn't work correctly since we're updating
                            // _notes but not _searchNotes
                            //
                            // We have to implement refreshing such that it updates
                            // _searchNotes, taking into account the current search term

                            setState(() {
                              _notes = _db.sync(widget.helper.getNotesFolder());
                            });

                            return _notes;
                          },
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
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.grey[50],
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 1,
                                  offset: Offset(0, -2))
                            ]),
                        child: TextFormField(
                          key: _textFieldKey,
                          controller: myController,
                          decoration: InputDecoration(
                            hintText: "sup?",
                            contentPadding: EdgeInsets.only(
                                bottom: 16, top: 16, left: 20, right: 20),
                            border: InputBorder.none,
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 28,
                          ),
                          onFieldSubmitted: (String str) {
                            print("Submitted $str");
                            Navigator.of(context).push(MorpheusPageRoute(
                                builder: (context) => Scaffold(),
                                parentKey: _textFieldKey));
                          },
                          autofocus: false,
                        ),
                      )),
                ],
              ));
        } else {
          return Container();
        }
      },
    );
  }
}
