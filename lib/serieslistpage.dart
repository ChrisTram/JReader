import 'package:flutter/widgets.dart';
import 'package:jreader/source/source.dart';
import 'package:jreader/support/uicommon.dart';
import 'package:jreader/support/platformui.dart';

class SeriesListPage extends BottomNavPage {
  final Source _source;
  final Function _loadFunc;

  SeriesListPage(this._source, this._loadFunc, {Key key}) : super(key: key);

  @override
  _SeriesListPageState createState() => _SeriesListPageState(this._source, this._loadFunc);

  @override
  List<NavBarAction> buildActions() {
    return [];
  }
}

class _SeriesListPageState extends State<SeriesListPage> {
  final Source _source;
  final Function _loadFunc;

  ScrollController _scrollController;

  int _nextPage;
  bool _loading;
  bool _end;
  List<Content> _loaded;

  Future _future;

  _SeriesListPageState(this._source, this._loadFunc);

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent && !_scrollController.position.outOfRange) {
        advancePage();
      }
    });

    _nextPage = 0;
    _loading = false;
    _end = false;
    _loaded = new List();
    advancePage();
  }

  void advancePage() {
    if(!_loading && !_end) {
      setState(() {
        _loading = true;
      });

      final future = _loadFunc(_nextPage++).then((value) {
        setState(() {
          _loading = false;
          _end = value.isEmpty;
          _loaded.addAll(value);
        });

        return value;
      });

      if(_future == null) {
        _future = future;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if(snapshot.hasData) {
            return UICommon.buildContentGrid(
                context,
                setState,
                _source,
                _loaded.map((e) => e.meta).toList(),
                contents: _loaded,
                loading: _loading,
                scrollController: _scrollController);
          } else if(snapshot.hasError) {
            return Center(child: Text("Error loading series list: ${snapshot.error}"));
          } else {
            return Center(child: PlatformUI.createProgressIndicator());
          }
        }
    );
  }
}