import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:jreader/contentpage.dart';
import 'package:jreader/support/persist.dart';
import 'package:jreader/source/source.dart';
import 'package:jreader/support/platformui.dart';

class UICommon {
  static const double _COVER_ASPECT_RATIO = 0.7025;

  static Widget buildCover(String coverUrl) {
    return PlatformUI.createDefaultNetworkImage(coverUrl, aspectRatio: _COVER_ASPECT_RATIO);
  }

  static Widget buildContentGrid(BuildContext context, Function setState, Source source, List<Metadata> metas, {
    List<Content> contents,
    Content parent,
    bool enableLongPress = false,
    bool reverseSorted = false,
    bool loading = false,
    bool showUnread = false,
    ScrollController scrollController
  }) {
    final children = List<Widget>.generate(metas.length, (index) {
      final content = contents != null ? contents[index] : null;
      final entry = UICommon._buildContentGridEntry(context, setState, source, metas[index], content, parent, showUnread);
      if(enableLongPress) {
        return _wrapContentForLongPress(context, setState, entry, source, metas, index, parent, reverseSorted);
      } else {
        return entry;
      }
    });

    if(loading) {
      children.add(PlatformUI.createPressableWidget(
          body: Center(child: PlatformUI.createProgressIndicator()),
          onPressed: () {},
          padding: EdgeInsets.zero
      ));
    }

    return GridView.count(
        controller: scrollController,
        crossAxisCount: 3,
        childAspectRatio: _COVER_ASPECT_RATIO,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        padding: EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 4.0),
        shrinkWrap: true,
        children: children
    );
  }

  static Widget _buildContentGridEntry(BuildContext context, Function setState, Source source, Metadata meta, Content content, Content parent, bool showUnread) {
    final body = new List<Widget>();
    body.add(buildCover(meta.coverUrl));
    body.add(_buildTitle(context, meta, parent));
    if(showUnread) {
      Widget readStatus = _buildUnreadIcon(context, source, meta);
      if(readStatus != null) {
        body.add(readStatus);
      }
    }

    return PlatformUI.createPressableWidget(
        body: Stack(
          children: body,
        ),
        onPressed: () {
          _openContent(context, setState, source, meta, content, parent);
        },
        padding: EdgeInsets.zero
    );
  }

  static Widget _buildTitle(BuildContext context, Metadata meta, Content parent) {
    return Positioned.fill(
        child: Container(
          padding: EdgeInsets.all(2.0),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
                decoration: BoxDecoration(
                    color: Color.fromARGB(200, 0, 0, 0),
                    borderRadius: const BorderRadius.all(Radius.circular(8.0))
                ),
                padding: EdgeInsets.all(5.0),
                child: Text(
                    _getChildContentTitle(meta, parent != null ? parent.meta.title : ""),
                    style: PlatformUI.getTextStyle(context).copyWith(
                        fontSize: 10
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis
                )
            ),
          ),
        )
    );
  }

  static Widget _buildUnreadIcon(BuildContext context, Source source, Metadata meta) {
    int unread = Persistence.getUnreadParts(source.name, meta);

    if(unread > 0) {
      return Positioned.fill(
          child: Container(
            padding: EdgeInsets.all(2.0),
            child: Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: PlatformUI.RED,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  '$unread',
                  style: PlatformUI.getTextStyle(context).copyWith(
                      fontSize: 12,
                      color: PlatformUI.WHITE
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
      );
    }

    return null;
  }

  static Widget buildContentList(BuildContext context, Function setState, Source source, List<Metadata> metas, {
    List<Content> contents,
    Content parent,
    bool enableLongPress = false,
    bool reverseSorted = false,
    ScrollController scrollController
  }) {
    return ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: metas.length,
        itemBuilder: (context, index) {
          final content = contents != null ? contents[index] : null;
          final entry = UICommon._buildContentListEntry(context, setState, source, metas[index], content, parent);
          if(enableLongPress) {
            return _wrapContentForLongPress(context, setState, entry, source, metas, index, parent, reverseSorted);
          } else {
            return entry;
          }
        }
    );
  }

  static Widget _buildContentListEntry(BuildContext context, Function setState, Source source, Metadata meta, Content content, Content parent) {
    TextStyle baseStyle = PlatformUI.getTextStyle(context);
    if(_isPartRead(source, meta.id)) {
      baseStyle = baseStyle.copyWith(color: PlatformUI.getDisabledColor(context));
    }

    return PlatformUI.createPressableWidget(
        padding: EdgeInsets.all(12),
        body: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                      _getChildContentTitle(meta, parent != null ? parent.meta.title : ""),
                      style: baseStyle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      )
                  ),
                  Padding(padding: EdgeInsets.all(4.0)),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                            meta.author,
                            style: baseStyle.copyWith(fontSize: 10)
                        ),
                        Text(
                            DateFormat.yMMMMd().add_jm().format(meta.date),
                            style: baseStyle.copyWith(fontSize: 10)
                        )
                      ],
                  )
                ],
              ),
            )
          ],
        ),
        onPressed: () {
          _openContent(context, setState, source, meta, content, parent);
        }
    );
  }

  static void _openContent(BuildContext context, Function setState, Source source, Metadata meta, Content content, Content parent) {
    Navigator.push(
      context,
      PlatformUI.createPageRoute(builder: (context) => content != null ? ContentPage(content, parent) : ContentPage.fromComponents(source, meta)),
    ).then((value) {
      // Save data on content exit. Uses set state to also update the UI (e.g. read progress, series removed from list).
      setState(() {});
      Persistence.save();

      if(value != null) {
        _openContent(context, setState, value.source, value.meta, value, parent);
      }
    });
  }

  static Widget _wrapContentForLongPress(BuildContext context, Function setState, Widget widget, Source source, List<Metadata> metas, int index, Content parent, bool reverseSorted) {
    final prevDirection = reverseSorted ? 1 : -1;
    final read = _isContentRead(source, metas[index]);

    return PlatformUI.wrapWithContextMenu(
        context: context,
        target: widget,
        title: metas[index].title,
        actionNames: [
          read ? "Mark as unread" : "Mark as read",
          "Mark previous as read",
          "Mark previous as unread"
        ],
        actionFuncs: [
              () {
            setState(() {
              _setContentRead(source, metas[index], !read);
            });
            Persistence.save();
          },
              () {
            setState(() {
              for(int i = index + prevDirection; i >= 0 && i < metas.length; i += prevDirection) {
                _setContentRead(source, metas[i], true);
              }
            });
            Persistence.save();
          },
              () {
            setState(() {
              for(int i = index + prevDirection; i >= 0 && i < metas.length; i += prevDirection) {
                _setContentRead(source, metas[i], false);
              }
            });
            Persistence.save();
          }
        ]
    );
  }

  static bool _isContentRead(Source source, Metadata meta) {
    bool read = true;
    for(String leafId in meta.leafs.keys) {
      if(!_isPartRead(source, leafId)) {
        read = false;
        break;
      }
    }

    return read;
  }

  static void _setContentRead(Source source, Metadata meta, bool read) {
    for(String leafId in meta.leafs.keys) {
      _setPartRead(source, leafId, read);
    }
  }

  static bool _isPartRead(Source source, String id) {
    final progress = Persistence.getProgress(source.name);
    return progress.containsKey(id) && progress[id].read;
  }

  static void _setPartRead(Source source, String id, bool read) {
    final progress = Persistence.getProgress(source.name);

    if(read) {
      if(progress.containsKey(id)) {
        progress[id].read = true;
      } else {
        progress[id] = Progress(offset: 0, read: true);
      }
    } else if(progress.containsKey(id)) {
      progress[id].read = false;
    }
  }

  static String _getChildContentTitle(Metadata meta, String parentTitle) {
    String title = meta.title;
    if(title.contains(" Vol ")) {
      title = title.replaceAll(" Vol ", " Volume ");
      title = title.replaceAll(" Ch ", " Chapter ");
    }

    if(parentTitle != null && parentTitle.isNotEmpty) {
      title = title.replaceAll(parentTitle, "");
    }

    if(title.startsWith(":")) {
      title = title.substring(1);
    }

    if(title.isEmpty) {
      title = meta.title;
    }

    return title.trim();
  }

  static void showChoiceModal({
    @required BuildContext context,
    @required String title,
    @required List<String> options,
    @required Function getState,
    @required Function setState,
    bool multiChoice = false
  }) {
    PlatformUI.showModal(
        context: context,
        title: title,
        body: StatefulBuilder(
            builder: (context, setUiState) {
              return ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.all(4),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final children = new List<Widget>();
                    children.add(Container(
                        height: 25,
                        child: Text(option)
                    ));
                    if(getState(option)) {
                      children.add(Icon(PlatformUI.CHECK));
                    }

                    return PlatformUI.createPressableWidget(
                        body: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: children
                        ),
                        onPressed: () {
                          final state = getState(option);
                          if(multiChoice || !state) {
                            setUiState(() {
                              setState(option, !state);
                              if(!multiChoice) {
                                options.forEach((opt) {
                                  if(opt != option) {
                                    setState(opt, false);
                                  }
                                });
                              }
                            });
                          }
                        }
                    );
                  }
              );
            }
        )
    );
  }
}