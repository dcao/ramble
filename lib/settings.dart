import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:sup/components/circle_tab_indicator.dart';

class SettingsPage extends StatelessWidget {
  final List<Tab> myTabs = [
    Tab(text: "general"),
    Tab(text: "about"),
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
              initialIndex: 0,
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
                          padding: EdgeInsets.only(left: 0.0),
                          child: Row(
                            children: [
                              IconButton(
                                iconSize: 20.0,
                                padding: EdgeInsets.only(bottom: 4.0),
                                icon: Icon(Icons.clear, color: Colors.black54),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  body: Stack(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.only(top: 16),
                        child: TabBarView(
                          children: <Widget>[
                            GeneralSettings(helper: snapshot.data),
                            AboutSettings(),
                          ],
                        ),
                      ),
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
                                width: double.infinity,
                                padding: EdgeInsets.only(
                                    left: 20, right: 20, bottom: 20, top: 36),
                                child: Text(
                                  "settings",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 28,
                                  ),
                                ),
                              ))),
                    ],
                  )),
            );
          } else {
            return Container();
          }
        });
  }
}

class GeneralSettings extends StatefulWidget {
  GeneralSettings({Key key, @required this.helper}) : super(key: key);

  final PrefsHelper helper;

  @override
  _GeneralSettingsState createState() => _GeneralSettingsState();
}

class _GeneralSettingsState extends State<GeneralSettings> {
  String _screen;
  String _format;
  String _notesFolder;

  @override
  Widget build(BuildContext context) {
    _screen = widget.helper.getDefaultScreen();
    _format = widget.helper.getFileFormat();
    _notesFolder = widget.helper.getNotesFolder();

    return ListView(
      children: <Widget>[
        ListTile(
          contentPadding: EdgeInsets.only(left: 57.0),
          title: Text(
            "Default screen",
          ),
          onTap: () {
            _screenChoice(context);
          },
          subtitle: Text(_screen),
        ),
        ListTile(
          contentPadding: EdgeInsets.only(left: 57.0),
          title: Text(
            "Note file format",
          ),
          subtitle: Text(_format),
          onTap: () {
            _fileFormat(context);
          },
        ),
        ListTile(
          enabled: Platform.isAndroid,
          contentPadding: EdgeInsets.only(left: 57.0),
          title: Text(
            "Notes folder",
          ),
          onTap: _chooseDir,
          subtitle:
              Platform.isAndroid ? Text(_notesFolder) : Text("Disabled on iOS"),
        ),
      ],
    );
  }

  Future<void> _screenChoice(BuildContext context) async {
    Screen s = await showDialog<Screen>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text('Default screen'),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, Screen.Remember);
                },
                child: const Text('Remember'),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, Screen.Note);
                },
                child: const Text('Note'),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, Screen.Capture);
                },
                child: const Text('Capture'),
              ),
            ],
          );
        });

    await widget.helper.setDefaultScreen(s);
    setState(() {
      _screen = describeEnum(s);
    });
  }

  Future<void> _chooseDir() async {
    File file = await FilePicker.getFile();
    if (file != null) {
      String path = dirname(file.path);
      await widget.helper.setNotesFolder(path);
      setState(() {
        _notesFolder = path;
      });
    } else {
      return null;
    }
  }

  Future<void> _fileFormat(BuildContext context) async {
    String format = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      // dialog is dismissible with a tap on the barrier
      builder: (BuildContext context) {
        String f = widget.helper.getFileFormat();
        return AlertDialog(
          title: Text('Note file format'),
          content: new Row(
            children: <Widget>[
              new Expanded(
                  child: new TextFormField(
                autofocus: true,
                initialValue: f,
                onChanged: (value) {
                  f = value;
                },
                decoration:
                    InputDecoration(hintText: PrefsHelper.DefaultFileFormat),
              ))
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(f);
              },
            ),
          ],
        );
      },
    );

    await widget.helper.setFileFormat(format);
    setState(() {
      _format = format;
    });
  }
}

enum Screen { Remember, Note, Capture }

class AboutSettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        ListTile(
          contentPadding: EdgeInsets.only(left: 57.0),
          title: Text(
            "sup 0.1.0",
          ),
          subtitle: Text("(C) 2020 David Cao <david@cao.sh>"),
        ),
        ListTile(
          contentPadding: EdgeInsets.only(left: 57.0),
          title: Text(
            "Rebuild database",
          ),
          subtitle: Text("Rebuilds sup's internal notes database"),
        ),
      ],
    );
  }
}

class PrefsHelper {
  SharedPreferences prefs;

  PrefsHelper();

  static const String DefaultDefaultScreen = 'Note';
  static const String DefaultFileFormat = 'yyyyMMddhhmmss_%s.org';

  static String defaultNotesFolder;

  Future<PrefsHelper> init() async {
    prefs = await SharedPreferences.getInstance();
    defaultNotesFolder = (await getApplicationDocumentsDirectory()).path;
    return this;
  }

  String getDefaultScreen() {
    return prefs.getString("default_screen") ?? DefaultDefaultScreen;
  }

  int getDefaultScreenAsInt() {
    switch (getDefaultScreen()) {
      case "Remember":
        return 0;
      case "Note":
        return 1;
      default:
        return 0;
    }
  }

  Future<bool> setDefaultScreen(Screen value) async {
    return prefs.setString("default_screen", describeEnum(value));
  }

  String getFileFormat() {
    return prefs.getString("notes_file_format") ?? DefaultFileFormat;
  }

  Future<bool> setFileFormat(String value) async {
    return prefs.setString("notes_file_format", value);
  }

  String getNotesFolder() {
    return prefs.getString("notes_folder") ?? defaultNotesFolder;
  }

  Future<bool> setNotesFolder(String value) async {
    return prefs.setString("notes_folder", value);
  }
}
