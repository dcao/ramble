import 'package:flutter/material.dart';
import 'package:sup/note.dart';
import 'package:sup/settings.dart';
import 'package:sup/themes.dart';

import 'circle_tab_indicator.dart';

void main() {
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: myTabs.length,
      initialIndex: 1,
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
                            color: Theme.of(context).accentColor, radius: 3),
                        tabs: myTabs,
                        isScrollable: true,
                        labelPadding: EdgeInsets.only(left: 8, right: 8),
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
                          MaterialPageRoute(builder: (context) => SettingsPage()),
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
            NovelPage(),
            NovelPage(),
            NovelPage(),
          ],
        ),
      ),
    );
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

class NovelPage extends StatefulWidget {
  NovelPage({Key key}) : super(key: key);

  @override
  _NovelPageState createState() => _NovelPageState();
}

class _NovelPageState extends State<NovelPage> {
  NoteProvider _db = NoteProvider();
  Future<List<Note>> _notes;
  GlobalKey _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _db.open('notes.db');
    _notes = _db.sync("TODO");
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _notes,
      builder: (BuildContext context, AsyncSnapshot<List<Note>> snapshot) {
        return Container(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 16),
            child: Stack(
              children: <Widget>[
                Align(
                    alignment: Alignment.topLeft,
                    child: RefreshIndicator(
                        key: _refreshKey,
                        onRefresh: () { return _notes = _db.sync('TODO'); },
                        child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: 50,
                            itemBuilder: (context, index) {
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  "Title $index",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                subtitle: Text("Context $index"),
                              );
                            }))),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: FractionalOffset.bottomCenter,
                              end: FractionalOffset.topCenter,
                              stops: [
                            0.85,
                            1.0
                          ],
                              colors: [
                            Theme.of(context).scaffoldBackgroundColor,
                            Theme.of(context)
                                .scaffoldBackgroundColor
                                .withAlpha(0),
                          ])),
                      child: Container(
                        child: TextFormField(
                          decoration: InputDecoration.collapsed(
                            hintText: "sup?",
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 28,
                          ),
                          onFieldSubmitted: (String str) {
                            print("Submitted $str");
                          },
                          onChanged: (String str) {
                            if (str.isEmpty) {
                              print("Empty!");
                            }
                          },
                          autofocus: true,
                        ),
                        padding: EdgeInsets.only(top: 16),
                      )),
                ),
              ],
            ));
      },
    );
  }
}
