import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html2md/html2md.dart' as html2md;
import 'package:jreader/support/persist.dart';
import 'package:jreader/source/source.dart';
import 'package:jreader/support/uicommon.dart';
import 'package:jreader/support/platformui.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';


// ignore: must_be_immutable
class ContentPage extends StatefulWidget {
  Content _content;
  Content _parent;

  Source _source;
  Metadata _metadata;

  ContentPage(this._content, this._parent, {Key key}) : super(key: key);

  ContentPage.fromComponents(this._source, this._metadata, {Key key}) : super(key: key);

  @override
  _ContentPageState createState() => _content != null ? _ContentPageState(this._content, this._parent)
                                                      : _ContentPageState.fromCached(this._source, this._metadata);
}

class _ContentPageState extends State<ContentPage> {
  Content _content;
  Content _parent;

  Source _source;
  Metadata _metadata;

  ScrollController _scrollCtrl;
  PageController _pageCtrl;

  PurchaseStatus _purchaseStatus;
  bool _purchasing;

  dynamic _error;

  _ContentPageState(this._content, this._parent);

  _ContentPageState.fromCached(this._source, this._metadata);

  @override
  void initState() {
    super.initState();

    if(_content != null) {
      _source = _content.source;
      _metadata = _content.meta;
    }

    if(_metadata.type == ContentType.NOVEL_PART
        || _metadata.type == ContentType.MANGA_PART
        || _metadata.type == ContentType.MANGA_PART_LONGSTRIP) {
      _initScrollingPart();
      _initPagedPart();
    }

    _purchaseStatus = null;
    _purchasing = false;

    _error = null;

    if(_content != null) {
      _content.fill().then((value) {
        _updateContent(_content);
      }).catchError(_onError);
    } else if(_source != null && _metadata != null) {
      _source.getSeries(_metadata.id).then((value) {
        value.fill().then((value2) {
          _updateContent(value);
        }).catchError(_onError);
      }).catchError(_onError);
    }
  }

  void _initScrollingPart() {
    final progress = Persistence.getProgress(_source.name);

    _scrollCtrl = ScrollController(
        initialScrollOffset: _metadata.type != ContentType.MANGA_PART_LONGSTRIP && progress.containsKey(_metadata.id) ? progress[_metadata.id].offset : 0
    );

    _scrollCtrl.addListener(() {
      progress[_metadata.id] = Progress(
          offset: _scrollCtrl.offset,
          read: _scrollCtrl.offset == _scrollCtrl.position.maxScrollExtent ||
              (progress.containsKey(_metadata.id) &&
                  progress[_metadata.id].read)
      );
    });
  }

  void _initPagedPart() {
    final progress = Persistence.getProgress(_source.name);
    final initialPage = progress.containsKey(_metadata.id) ? progress[_metadata.id].offset.toInt() : 1;

    _pageCtrl = new PageController(
        initialPage: initialPage - 1
    );

    _pageCtrl.addListener(() {
      int pageNum = _pageCtrl.page.toInt() + 1;
      progress[_metadata.id] = Progress(
          offset: pageNum.toDouble(),
          read: pageNum == _content.children.length ||
              (progress.containsKey(_metadata.id) &&
                  progress[_metadata.id].read)
      );

      // Update page number.
      setState(() {});
    });
  }

  void _onError(dynamic e, dynamic s) {
    setState(() {
      _error = e;

      debugPrint(e.toString());
      debugPrint(s.toString());
    });
  }

  void _updateContent(Content content) {
    if(mounted) {
      setState(() {
        _content = content;
        _metadata = content.meta;
      });

      _content.getPurchaseStatus().then((status) {
        if(mounted) {
          setState(() {
              _purchaseStatus = status;
          });
        }
      });

      final myList = Persistence.getMyList(_source.name);
      if(myList.containsKey(content.meta.id)) {
        // Update list metadata.
        myList[content.meta.id].meta = content.meta;
        Persistence.save();
      }

      if(content.meta.type == ContentType.MANGA_PART
          || content.meta.type == ContentType.MANGA_PART_LONGSTRIP) {
        // Update progress initially in case we're already on the last page (e.g. 1 page manga).
        final progress = Persistence.getProgress(_source.name);
        final initialPage = progress.containsKey(_metadata.id) ? progress[_metadata.id].offset.toInt() : 1;
        progress[_metadata.id] = Progress(
            offset: initialPage.toDouble(),
            read: initialPage == _content.children.length ||
                (progress.containsKey(_metadata.id) &&
                    progress[_metadata.id].read)
        );

        Future.microtask(() {
          Future<void> lastImage = Future.value();
          for(final pageUrl in _content.children) {
            lastImage = lastImage.then((_) {
              if(mounted) {
                return _precacheImage(pageUrl);
              } else {
                return null;
              }
            });
          }
        });
      }
    }
  }

  Future<void> _precacheImage(String pageUrl, {int retries = 5}) {
    return precacheImage(PlatformUI.createNetworkImageProvider(pageUrl), context, onError: (e, s) {
      if(mounted && retries > 0) {
        // Retry
        _precacheImage(pageUrl, retries: retries - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if(_metadata.type == ContentType.SERIES || _metadata.type == ContentType.VOLUME) {
      return _buildDetailPage(context);
    } else {
      return _buildPartPage(context);
    }
  }

  Widget _buildDetailPage(BuildContext context) {
    final body = new List<Widget>();

    body.add(Container(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 4),
      child: _buildDetailBox()
    ));

    final actionButtons = _buildActionButtons();
    if(actionButtons != null) {
      body.add(actionButtons);
    }

    if(_content != null && _content.isFilled()) {
      if(_content.children.isNotEmpty) {
        if(_content.children[0].meta.type == ContentType.VOLUME) {
          body.add(_buildVolumeList(context));
        } else {
          body.add(_buildPartList(context));
        }
      } else {
        body.add(Center(child: Text("No Content")));
      }
    } else if(_error != null) {
      body.add(Center(child: Text("Error: $_error")));
    } else {
      body.add(Expanded(child: Center(child: PlatformUI.createProgressIndicator())));
    }

    return PlatformUI.createPage(
        context: context,
        title: _metadata.title,
        body: Column(
          children: body
        )
    );
  }

  Widget _buildDetailBox() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(
              flex: 1,
              child: UICommon.buildCover(_metadata.coverUrl)
          ),
          Expanded(
              flex: 2,
              child: PlatformUI.createPressableWidget(
                  body: Container(
                    padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                            _metadata.title,
                            textAlign: TextAlign.left,
                            style: PlatformUI.getTextStyle(context).copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis
                        ),
                        Text(
                            _metadata.author,
                            textAlign: TextAlign.left,
                            style: PlatformUI.getTextStyle(context).copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis
                        ),
                        Padding(padding: EdgeInsets.all(4)),
                        Text(
                            _metadata.description,
                            textAlign: TextAlign.left,
                            style: PlatformUI.getTextStyle(context).copyWith(fontSize: 14),
                            maxLines: 8,
                            overflow: TextOverflow.ellipsis
                        )
                      ],
                    ),
                  ),
                  onPressed: () {
                    PlatformUI.showModal(
                        context: context,
                        title: _metadata.title,
                        body: SingleChildScrollView(
                            child: Text(
                                _metadata.description,
                                textAlign: TextAlign.left,
                                style: PlatformUI.getTextStyle(context).copyWith(fontSize: 14)
                            ),
                            padding: const EdgeInsets.all(8.0)
                        )
                    );
                  },
                  padding: EdgeInsets.zero
              )
          )
        ],
      )
    );
  }

  Widget _buildActionButtons() {
    final buttons = new List<Widget>();

    if(_metadata.type == ContentType.SERIES) {
      final myList = Persistence.getMyList(_source.name);
      final listEntry = myList[_metadata.id];
      buttons.add(_buildActionButton(
          listEntry != null ? 'Remove From List' : "Add To List",
              () {
            if(listEntry != null) {
              setState(() {
                myList.remove(_metadata.id);
              });
              Persistence.save();
            } else {
              setState(() {
                myList[_metadata.id] = new MyListEntry(
                    meta: _metadata
                );
              });
              Persistence.save();
            }
          }
      ));
    }

    if(_purchaseStatus != null && _purchaseStatus != PurchaseStatus.NOT_SUPPORTED) {
      buttons.add(_buildActionButton(
          PURCHASE_STATUS_TEXT[_purchaseStatus],
          !_purchasing && _purchaseStatus == PurchaseStatus.CAN_PURCHASE ? _confirmPurchaseContent : null
      ));
    }

    if(buttons.isNotEmpty) {
      return Column(
          children: buttons
      );
    } else {
      return null;
    }
  }

  Widget _buildActionButton(String text, Function onPressed) {
    return SizedBox(
        width: double.infinity,
        child: Container(
          padding: const EdgeInsets.all(4.0),
          child: PlatformUI.createRaisedButton(
              context: context,
              text: text,
              onPressed: onPressed
          ),
        )
    );
  }

  void _confirmPurchaseContent() {
    PlatformUI.showAlertDialog(
        context: context,
        text: "Purchase this content?",
        actions: ["Purchase", "Cancel"]
    ).then((result) {
      if(result.action == "Purchase") {
        _purchaseContent();
      }
    });
  }

  void _purchaseContent() {
    setState(() {
      _purchasing = true;
    });

    _content.purchase().then((_) {
      _content.getPurchaseStatus().then((status) {
        if(mounted) {
          setState(() {
            _purchasing = false;
            _purchaseStatus = status;
          });
        }
      });
    }).catchError((e) {
      PlatformUI.showAlertDialog(
          context: context,
          text: "Purchase failed: $e",
          actions: ["OK"]
      );
    });
  }

  Widget _buildVolumeList(BuildContext context) {
    return Expanded(
        child: UICommon.buildContentGrid(
            context,
            setState,
            _content.source,
            _content.children.map((e) => e.meta as Metadata).toList(),
            contents: _content.children,
            parent: _content,
            enableLongPress: true,
            showUnread: true
        )
    );
  }

  Widget _buildPartList(BuildContext context) {
    return Expanded(
        child: UICommon.buildContentList(
            context,
            setState,
            _source,
            _content.children.map((e) => e.meta as Metadata).toList(),
            contents: _content.children,
            parent: _content,
            enableLongPress: true,
            reverseSorted: true
        )
    );
  }

  Widget _buildPartPage(BuildContext context) {
    Widget bodyWidget = Center(child: PlatformUI.createProgressIndicator());
    if(_content != null && _content.isFilled()) {
      if(_metadata.type == ContentType.NOVEL_PART) {
        bodyWidget = _buildNovelPartPage();
      } else if(_metadata.type == ContentType.MANGA_PART) {
        bodyWidget = _buildMangaPartPage();
      } else if(_metadata.type == ContentType.MANGA_PART_LONGSTRIP) {
        bodyWidget = _buildMangaPartLongStripPage();
      }
    } else if(_error != null) {
      bodyWidget = Center(child: Text("Error: $_error"));
    }

    return PlatformUI.createPage(
        context: context,
        title: _metadata.title,
        body: bodyWidget,
        actions: _buildPartActions()
    );
  }

  List<NavBarAction> _buildPartActions() {
    Content prev;
    Content next;
    if(_parent != null && _parent.children != null) {
      final currIndex = _parent.children.indexOf(_content);
      if(currIndex != -1) {
        final prevIndex = currIndex + 1;
        if(prevIndex < _parent.children.length) {
          prev = _parent.children[prevIndex];
        }

        final nextIndex = currIndex - 1;
        if(nextIndex >= 0) {
          next = _parent.children[nextIndex];
        }
      }
    }

    return [
      NavBarAction(
        icon: PlatformUI.ARROW_LEFT,
        tooltip: "Previous Part",
        onPressed: prev != null ? (context) {
          Navigator.pop(context, prev);
        } : null,
      ),
      NavBarAction(
        icon: PlatformUI.ARROW_RIGHT,
        tooltip: "Next Part",
        onPressed: next != null ? (context) {
          Navigator.pop(context, next);
        } : null,
      )
    ];
  }

  Widget _buildNovelPartPage() {
    final font = GoogleFonts.crimsonText();
    return PlatformUI.createScrollbar(
      child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          controller: _scrollCtrl,
          padding: EdgeInsets.all(8.0),
          child: PlatformUI.createScrollbar(
              child: MarkdownBody(
                  data: html2md.convert(_content.children[0]),
                  styleSheetTheme: PlatformUI.shouldUseCupertino()
                      ? MarkdownStyleSheetBaseTheme.cupertino
                      : MarkdownStyleSheetBaseTheme.material,
                  styleSheet: MarkdownStyleSheet(
                      a: font,
                      p: font,
                      h1: font,
                      h2: font,
                      h3: font,
                      h4: font,
                      h5: font,
                      h6: font,
                      em: font,
                      strong: font,
                      del: font,
                      blockquote: font,
                      img: font,
                      checkbox: font,
                      listBullet: font,
                      tableHead: font,
                      tableBody: font,
                      textScaleFactor: 1.5
                  ),
                  imageBuilder: (uri, title, alt) => PlatformUI.createDefaultNetworkImage(uri.toString())
              )
          )
      ),
    );
  }

  Widget _buildMangaPartPage() {
    return Stack(
      children: <Widget>[
        PhotoViewGallery.builder(
            scrollDirection: Axis.horizontal,
            scrollPhysics: const BouncingScrollPhysics(),
            itemCount: _content.children.length,
            reverse: true,
            pageController: _pageCtrl,
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                  imageProvider: PlatformUI.createNetworkImageProvider(_content.children[index]),
                  minScale: PhotoViewComputedScale.contained
              );
            },
            loadingBuilder: (context, event) => Center(
              child: PlatformUI.createProgressIndicator(
                value: event == null
                    ? 0
                    : event.cumulativeBytesLoaded / event.expectedTotalBytes,
              ),
            )
        ),
        Positioned.fill(
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
                        "${_pageCtrl.hasClients ? _pageCtrl.page.round() + 1 : 1}/${_content.children.length}",
                        textAlign: TextAlign.center
                    )
                ),
              ),
            )
        ),
      ],
    );
  }

  Widget _buildMangaPartLongStripPage() {
    return PlatformUI.createScrollbar(
      child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          controller: _scrollCtrl,
          child: Column(
              children: _content.children.map((pageUrl) {
                return Image(
                    image: PlatformUI.createNetworkImageProvider(pageUrl),
                    loadingBuilder: (context, child, loadingProgress) {
                      if(loadingProgress != null) {
                        final totalHeight = MediaQuery.of(context).size.height;
                        return Container(
                            height: totalHeight,
                            child: Center(child: PlatformUI.createProgressIndicator(
                                value: loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes
                            ))
                        );
                      } else {
                        return child;
                      }
                    }
                );
              }).toList()
          )
      ),
    );
  }
}