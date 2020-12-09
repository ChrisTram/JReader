import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:jreader/contentpage.dart';
import 'package:jreader/source/source.dart';
import 'package:jreader/support/uicommon.dart';
import 'package:jreader/support/platformui.dart';

class UpdatesPage extends BottomNavPage {
  final Source _source;

  UpdatesPage(this._source, {Key key}) : super(key: key);

  @override
  _UpdatesPageState createState() => _UpdatesPageState(this._source);

  @override
  List<NavBarAction> buildActions() {
    return [];
  }
}

class _UpdatesPageState extends State<UpdatesPage> {
  final Source _source;

  Future<List<Event>> _futureEvents;

  _UpdatesPageState(this._source);

  @override
  void initState() {
    super.initState();
    this._futureEvents = _source.listEvents();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Event>>(
        future: _futureEvents,
        builder: (context, snapshot) {
          if(snapshot.hasData) {
            final now = DateTime.now();
            final beginningOfYesterday = new DateTime(now.year, now.month, now.day).subtract(new Duration(days: 1));

            final filtered = new List<Event>();
            for(final event in snapshot.data) {
              if(event.date.isAfter(beginningOfYesterday) && event.coverUrl != null) {
                filtered.add(event);
              }
            }

            filtered.sort((e1, e2) => e1.date == e2.date ? 0 : e1.date.isBefore(e2.date) ? -1 : 1);

            return ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount: filtered.length,
                itemBuilder: (context, index) => PlatformUI.createPressableWidget(
                    padding: EdgeInsets.zero,
                    body: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: UICommon.buildCover(filtered[index].coverUrl)
                        ),
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: <Widget>[
                              Text(
                                  filtered[index].name,
                                  style: PlatformUI.getTextStyle(context).copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis
                              ),
                              Padding(padding: EdgeInsets.all(4)),
                              Text(
                                  filtered[index].details,
                                  style: PlatformUI.getTextStyle(context).copyWith(fontSize: 14),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis
                              ),
                              Text(
                                  new DateFormat.yMMMMEEEEd().add_jm().format(filtered[index].date),
                                  style: PlatformUI.getTextStyle(context).copyWith(fontSize: 14),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                    onPressed: () {
                      final event = filtered[index];
                      if(event.date.isBefore(DateTime.now())) {
                        event.getContent().then((content) => Navigator.push(
                          context,
                          PlatformUI.createPageRoute(builder: (context) => ContentPage(content, null)),
                        ));
                      }
                    }
                )
            );
          } else if(snapshot.hasError) {
            return Center(child: Text("Error loading updates page: ${snapshot.error}"));
          } else {
            return Center(child: PlatformUI.createProgressIndicator());
          }
        }
    );
  }
}