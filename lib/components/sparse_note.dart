import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:morpheus/page_routes/morpheus_page_route.dart';
import 'package:ramble/backend/note.dart';
import 'package:ramble/components/shared_text.dart';
import 'package:ramble/note.dart';

class SparseNote extends StatelessWidget {
  final Object titleKey;
  final Note note;
  final Function onTap;

  SparseNote({Key key, @required this.note, @required this.titleKey, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    GlobalKey _parentKey = GlobalKey();

    return Card(
      key: _parentKey,
      elevation: 0,
      margin: EdgeInsets.only(left: 4.0, right: 4.0, bottom: 2.0, top: 2.0),
      child: InkWell(
        onTap: () async {
          final res = await Navigator.of(context).push(MorpheusPageRoute(
            transitionToChild: false,
            transitionDuration: Duration(milliseconds: 500),
            builder: (context) => NotePage(
              title: note.titleOrFilename(),
              titleTag: titleKey,
              note: note,
            ),
            parentKey: _parentKey,
          ));

          onTap(this, res);
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.ideographic,
                children: [
                  Expanded(
                    child: Stack(
                      // What the hell is this Stack business?
                      // When we do our Hero transition, the SharedText is no
                      // longer in the row. Thus, the height of the row becomes
                      // equal to the height of the "timeago" string, which is
                      // always less than the height of the title. This row
                      // shrinkage causes the summary text to unceremoniously
                      // jump up when the transition on push (since the Row
                      // is now smaller) and jump down on pop (since the Row
                      // has suddenly become larger).

                      // To combat this, we place an invisible copy of the
                      // title behind the actual title such that the Row will
                      // always keep the same size.
                      children: [
                        Opacity(
                          opacity: 0,
                          child: SharedText(
                          note.titleOrFilename(),
                          smallFontSize: 16.0,
                          viewState: ViewState.shrunk,
                        )),
                        Hero(
                          tag: titleKey,
                          child: SharedText(
                            note.titleOrFilename(),
                            smallFontSize: 16.0,
                            viewState: ViewState.shrunk,
                          ),
                          flightShuttleBuilder: (
                            BuildContext flightContext,
                            Animation<double> animation,
                            HeroFlightDirection flightDirection,
                            BuildContext fromHeroContext,
                            BuildContext toHeroContext,
                          ) {
                            return SharedText(
                              note.titleOrFilename(),
                              isOverflow: true,
                              viewState:
                                  flightDirection == HeroFlightDirection.push
                                      ? ViewState.enlarge
                                      : ViewState.shrink,
                              smallFontSize: 16.0,
                              largeFontSize: 28.0,
                            );
                          },
                        )
                      ],
                    ),
                  ),
                  Text(
                    timeago.format(note.modified, locale: 'en_short'),
                    style: TextStyle(
                      fontSize: 13.0,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.0),
              Text(note.summary, maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
