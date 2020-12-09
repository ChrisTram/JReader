import 'package:flutter/widgets.dart';
import 'package:jreader/accountpage.dart';
import 'package:jreader/searchpage.dart';
import 'package:jreader/source/source.dart';
import 'package:jreader/support/platformui.dart';

import 'mylistpage.dart';
import 'serieslistpage.dart';
import 'updatespage.dart';

class SourcePage extends StatefulWidget {
  final Source _source;

  SourcePage(this._source, {Key key}) : super(key: key);

  @override
  _SourcePageState createState() => _SourcePageState(_source);
}

class _SourcePageState extends State<SourcePage> {
  final Source _source;

  _SourcePageState(this._source);

  @override
  Widget build(BuildContext context) {
    return PlatformUI.createBottomNavPage(
        title: _source.name,
        navBarItems: [
          BottomNavigationBarItem(
            icon: new Icon(PlatformUI.LIBRARY_BOOKS),
            label: 'Popular'
          ),
          BottomNavigationBarItem(
            icon: new Icon(PlatformUI.UPDATE),
            label: 'Updates'
          ),
          BottomNavigationBarItem(
            icon: new Icon(PlatformUI.SEARCH),
            label: 'Search'
          ),
          BottomNavigationBarItem(
            icon: new Icon(PlatformUI.BOOK),
            label: 'My List'
          ),
          BottomNavigationBarItem(
            icon: Icon(PlatformUI.PERSON),
            label: 'Account'
          )
        ],
        pages: [
          SeriesListPage(_source, (page) {
            return _source.listSeries(page: page);
          }),
          UpdatesPage(_source),
          SearchPage(_source),
          MyListPage(_source),
          AccountPage(_source)
        ]
    );
  }
}