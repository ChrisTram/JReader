import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:jreader/serieslistpage.dart';
import 'package:jreader/source/source.dart';
import 'package:jreader/support/platformui.dart';
import 'package:jreader/support/uicommon.dart';

class SearchPage extends BottomNavPage {
  final Source _source;

  SearchPage(this._source, {Key key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState(_source);

  @override
  List<NavBarAction> buildActions() {
    return [];
  }
}

class _SearchPageState extends State<SearchPage> {
  final Source _source;

  Map<String, String> _fieldValues;
  Map<String, Map<String, bool>> _filterValues;

  _SearchPageState(this._source);

  @override
  void initState() {
    super.initState();
    _fieldValues = new Map<String, String>();
    for(final field in _source.searchDefinition.fields) {
      _fieldValues[field] = "";
    }

    _filterValues = new Map<String, Map<String, bool>>();
    for(final filter in _source.searchDefinition.filters) {
      _filterValues[filter.name] = new Map<String, bool>();
      for(final option in filter.choices) {
        _filterValues[filter.name][option] = filter.defaultOn.contains(option);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = new List<Widget>();

    items.add(PlatformUI.createRaisedButton(
      context: context,
      text: "Search",
      onPressed: () {
        Navigator.push(
          context,
          PlatformUI.createPageRoute(builder: (context) => PlatformUI.createPage(
              context: context,
              title: "Search Results",
              body: SeriesListPage(_source, (page) {
                return _source.searchSeries(_fieldValues, _filterValues, page: page);
              })
          )),
        );
      },
    ));

    for(final field in _source.searchDefinition.fields) {
      items.add(PlatformUI.createTextField(
        label: field,
        controller: TextEditingController(text: _fieldValues[field]),
        onChanged: (text) {
          _fieldValues[field] = text;
        },
      ));
    }

    final filtersRows = new List<Widget>();
    for(int i = 0; i < _source.searchDefinition.filters.length; i += 2) {
      final filterRow = new List<Widget>();
      filterRow.add(_buildFilterButton(_source.searchDefinition.filters[i]));
      if(i + 1 < _source.searchDefinition.filters.length) {
        filterRow.add(_buildFilterButton(_source.searchDefinition.filters[i + 1]));
      }

      filtersRows.add(Flex(
          direction: Axis.horizontal,
          children: filterRow
      ));
    }

    items.add(Column(
      children: filtersRows
    ));

    return ListView.builder(
        scrollDirection: Axis.vertical,
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            padding: EdgeInsets.all(8.0),
            child: items[index]
          );
        }
    );
  }

  Widget _buildFilterButton(SearchFilter filter) {
    final options = _filterValues[filter.name].keys.toList();
    options.sort((a, b) => a.compareTo(b));

    return Expanded(
          flex: 1,
          child: Container(
            padding: EdgeInsets.all(4),
            child: PlatformUI.createRaisedButton(
                context: context,
                text: filter.name,
                onPressed: () {
                  UICommon.showChoiceModal(
                      context: context,
                      title: filter.name,
                      options: options,
                      getState: (option) => _filterValues[filter.name][option],
                      setState: (option, value) {
                        _filterValues[filter.name][option] = value;
                      },
                      multiChoice: filter.multiChoice
                  );
                }
            )
          )
      );
  }
}