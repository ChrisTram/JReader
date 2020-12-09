import 'package:flutter/widgets.dart';
import 'package:jreader/support/persist.dart';
import 'package:jreader/source/source.dart';
import 'package:jreader/support/platformui.dart';
import 'package:jreader/support/uicommon.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class MyListPage extends BottomNavPage {
  final Source _source;

  Function refreshSort;

  MyListPage(this._source, {Key key}) : super(key: key);

  @override
  _MyListPageState createState() => _MyListPageState(_source, this);

  @override
  List<NavBarAction> buildActions() {
    return [
      NavBarAction(
          icon: PlatformUI.SORT_ORDER,
          tooltip: "Sort Order",
          onPressed: (context) {
            final options = [
              "Ascending",
              "Descending"
            ];

            UICommon.showChoiceModal(
                context: context,
                title: "Sort Order",
                options: options,
                getState: (option) {
                  return (Persistence.getSortingDirs(_source.name)["myList"] ?? 0) == options.indexOf(option);
                },
                setState: (option, value) {
                  if(value) {
                    Persistence.getSortingDirs(_source.name)["myList"] = options.indexOf(option);
                    Persistence.save();
                    refreshSort();
                  }
                }
            );
          }
      ),
      NavBarAction(
          icon: PlatformUI.SORT_BY,
          tooltip: "Sort By",
          onPressed: (context) {
            final options = [
              "Title",
              "Recently Updated",
              "Most Updates"
            ];

            UICommon.showChoiceModal(
                context: context,
                title: "Sort By",
                options: options,
                getState: (option) {
                  return (Persistence.getSortingModes(_source.name)["myList"] ?? 0) == options.indexOf(option);
                },
                setState: (option, value) {
                  if(value) {
                    Persistence.getSortingModes(_source.name)["myList"] = options.indexOf(option);
                    Persistence.save();
                    refreshSort();
                  }
                }
            );
          }
      )
    ];
  }
}

class _MyListPageState extends State<MyListPage> {
  final Source _source;

  RefreshController _refreshCtrl;
  String _refreshing;

  _MyListPageState(this._source, MyListPage myListPage) {
    myListPage.refreshSort = () {
      setState(() {});
    };
  }

  @override
  void initState() {
    super.initState();
    _refreshCtrl = new RefreshController(initialRefresh: false);
  }

  @override
  Widget build(BuildContext context) {
    final sorted = Persistence.getMyList(_source.name).values.toList();
    Persistence.sortMeta(_source.name, "myList", sorted, (e) => e.meta);

    return SmartRefresher(
      enablePullUp: true,
      header: WaterDropHeader(refresh: Text(
        "Refreshing $_refreshing...",
        style: TextStyle(
            fontWeight: FontWeight.bold
        ),
        textAlign: TextAlign.center
      )),
      footer: CustomFooter(
        builder: (BuildContext context, LoadStatus mode) {
          return Container();
        },
      ),
      controller: _refreshCtrl,
      onRefresh: _performRefresh,
      child: UICommon.buildContentGrid(
          context,
          setState,
          _source,
          sorted.map((e) => e.meta).toList(),
          showUnread: true
      ),
    );
  }

  void _onError(dynamic e, dynamic s) {
    debugPrint(e.toString());
    debugPrint(s.toString());
  }

  void _performRefresh() {
    final myList = Persistence.getMyList(_source.name);

    Future<void> lastRefresh = Future.value();
    for(final entry in myList.entries) {
      lastRefresh = lastRefresh.then((_) {
        if(mounted) {
          setState(() {
            _refreshing = entry.value.meta.title;
          });

          return _source.getSeries(entry.key).then((series) {
            return series.fill().then((value) {
              entry.value.meta = series.meta;
            }).catchError(_onError);
          }).catchError(_onError);
        } else {
          return null;
        }
      });
    }

    lastRefresh.then((_) {
      if(mounted) {
        setState(() {
          _refreshing = "";
          _refreshCtrl.refreshCompleted();
        });
      }

      Persistence.save();
    });
  }
}