import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class PlatformUI {
  static final IconData LIBRARY_BOOKS = shouldUseCupertino() ? CupertinoIcons.book : Icons.book;
  static final IconData UPDATE = shouldUseCupertino() ? CupertinoIcons.refresh : Icons.update;
  static final IconData BOOK = shouldUseCupertino() ? CupertinoIcons.bookmark : Icons.bookmark;
  static final IconData PERSON = shouldUseCupertino() ? CupertinoIcons.profile_circled : Icons.person;
  static final IconData ERROR = shouldUseCupertino() ? CupertinoIcons.clear_circled : Icons.error;
  static final IconData ADD_CIRCLED = shouldUseCupertino() ? CupertinoIcons.plus_circled : Icons.add_circle;
  static final IconData REMOVE_CIRCLED = shouldUseCupertino() ? CupertinoIcons.minus_circled : Icons.remove_circle;
  static final IconData ARROW_LEFT = shouldUseCupertino() ? CupertinoIcons.left_chevron : Icons.keyboard_arrow_left;
  static final IconData ARROW_RIGHT = shouldUseCupertino() ? CupertinoIcons.right_chevron : Icons.keyboard_arrow_right;
  static final IconData SEARCH = shouldUseCupertino() ? CupertinoIcons.search : Icons.search;
  static final IconData SORT_BY = shouldUseCupertino() ? CupertinoIcons.shuffle_thick : Icons.sort;
  static final IconData SORT_ORDER = shouldUseCupertino() ? CupertinoIcons.down_arrow : Icons.arrow_downward;
  static final IconData CHECK = shouldUseCupertino() ? CupertinoIcons.check_mark : Icons.check;
  static final IconData IMPORT = shouldUseCupertino() ? CupertinoIcons.down_arrow : Icons.arrow_downward;
  static final IconData EXPORT = shouldUseCupertino() ? CupertinoIcons.up_arrow : Icons.arrow_upward;

  static final Color RED = shouldUseCupertino() ? CupertinoColors.destructiveRed : Colors.red;
  static final Color WHITE = shouldUseCupertino() ? CupertinoColors.white : Colors.white;

  static bool shouldUseCupertino() {
    // Disabled
    /*try {
      return Platform.isIOS;
    } catch(e) {
      return false;
    }*/
    return false;
  }

  static TextStyle getTextStyle(BuildContext context) {
    if(shouldUseCupertino()) {
      return CupertinoTheme.of(context).textTheme.textStyle;
    } else {
      return Theme.of(context).textTheme.bodyText1;
    }
  }

  static Color getDisabledColor(BuildContext context) {
    if(shouldUseCupertino()) {
      return Color(0xFF555555);
    } else {
      return Theme.of(context).disabledColor;
    }
  }

  static Widget createApp({
    @required String title,
    @required Widget home
  }) {
    Function builder;
    if(kIsWeb) {
      builder = (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        return MediaQuery(data: mediaQueryData.copyWith(
            padding: mediaQueryData.padding.copyWith(
                // On iPhone X and others, add padding for gesture bar.
                bottom: mediaQueryData.size.height >= 812 ? 34 : 0
            )
        ), child: child);
      };
    }

    if(shouldUseCupertino()) {
      return CupertinoApp(
          title: title,
          theme: CupertinoThemeData(brightness: Brightness.dark),
          home: home,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
            DefaultCupertinoLocalizations.delegate,
          ],
          builder: builder
      );
    } else {
      return MaterialApp(
          title: title,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: home,
          debugShowCheckedModeBanner: false,
          builder: builder
      );
    }
  }

  static Widget createPage({
    @required BuildContext context,
    @required String title,
    @required Widget body,
    List<NavBarAction> actions
  }) {
    if(shouldUseCupertino()) {
      return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
              middle: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions != null ? actions.map((action) {
                    return CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Icon(action.icon),
                        onPressed: action.onPressed != null ? () => action.onPressed(context) : null
                    );
                  }).toList() : []
              )
          ),
          child: SafeArea(
              child: body
          )
      );
    } else {
      return Scaffold(
          appBar: AppBar(
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: actions != null ? actions.map((action) {
              return IconButton(
                  icon: Icon(action.icon),
                  tooltip: action.tooltip,
                  onPressed: action.onPressed != null ? () => action.onPressed(context) : null
              );
            }).toList() : []
          ),
          body: body
      );
    }
  }

  static Widget createBottomNavPage({
    @required String title,
    @required List<BottomNavigationBarItem> navBarItems,
    @required List<BottomNavPage> pages
  }) {
    int currentIndex = 0;
    final tabController = new CupertinoTabController();
    bool hasListener = false;
    return StatefulBuilder(
      builder: (context, setState) {
        if(!hasListener) {
          tabController.addListener(() {
            setState(() {
              currentIndex = tabController.index;
            });
          });

          hasListener = true;
        }

        final actions = pages[currentIndex].buildActions();

        if(shouldUseCupertino()) {
          return CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(
                  middle: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions != null ? actions.map((action) {
                        return CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: Icon(action.icon),
                            onPressed: action.onPressed != null ? () => action.onPressed(context) : null
                        );
                      }).toList() : []
                  )
              ),
              child: SafeArea(
                  child: CupertinoTabScaffold(
                    tabBar: CupertinoTabBar(items: navBarItems),
                    tabBuilder: (context, index) {
                      return SafeArea(
                        child: pages[index]
                      );
                    },
                    controller: tabController,
                  )
              )
          );
        } else {
          return Scaffold(
            appBar: AppBar(
                title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                actions: actions != null ? actions.map((action) {
                  return IconButton(
                      icon: Icon(action.icon),
                      tooltip: action.tooltip,
                      onPressed: action.onPressed != null ? () => action.onPressed(context) : null
                  );
                }).toList() : []
            ),
            body: pages[currentIndex],
            bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                onTap: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                }, // new
                currentIndex: currentIndex,
                items: navBarItems
            ),
          );
        }
      },
    );
  }

  static Widget createRaisedButton({
    @required BuildContext context,
    @required String text,
    @required Function onPressed
  }) {
    if(shouldUseCupertino()) {
      return CupertinoButton(
          child: Text(text),
          onPressed: onPressed
      );
    } else {
      return RaisedButton(
          child: Text(text),
          onPressed: onPressed
      );
    }
  }

  static Widget createPressableWidget({
    @required Widget body,
    @required Function onPressed,
    EdgeInsetsGeometry padding
  }) {
    if(shouldUseCupertino()) {
      return CupertinoButton(
          child: body,
          onPressed: onPressed,
          padding: padding
      );
    } else {
      return FlatButton(
          child: body,
          onPressed: onPressed,
          padding: padding
      );
    }
  }

  static Widget createTextField({
    @required String label,
    @required TextEditingController controller,
    Function onChanged,
    bool autofocus = false,
    bool obscureText = false
  }) {
    if(shouldUseCupertino()) {
      return CupertinoTextField(
          placeholder: label,
          controller: controller,
          onChanged: onChanged,
          autofocus: autofocus,
          obscureText: obscureText
      );
    } else {
      return TextField(
          decoration: InputDecoration(labelText: label),
          controller: controller,
          onChanged: onChanged,
          autofocus: autofocus,
          obscureText: obscureText
      );
    }
  }

  static PageRoute createPageRoute({
    @required Function builder
  }) {
    if(shouldUseCupertino()) {
      return CupertinoPageRoute(builder: builder);
    } else {
      return MaterialPageRoute(builder: builder);
    }
  }

  static ImageProvider createNetworkImageProvider(String url) {
    if(kIsWeb) {
      return NetworkImage(url);
    } else {
      return CachedNetworkImageProvider(url);
    }
  }

  static Widget createProgressIndicator({
    double value
  }) {
    if(shouldUseCupertino()) {
      return CupertinoActivityIndicator();
    } else {
      return CircularProgressIndicator(value: value);
    }
  }

  static Widget createScrollbar({
    Widget child
  }) {
    if(shouldUseCupertino()) {
      return CupertinoScrollbar(
          child: child
      );
    } else {
      return Scrollbar(
          child: child
      );
    }
  }

  static Widget createDefaultNetworkImage(String url, {
    double aspectRatio
  }) {
    return Image(
      image: createNetworkImageProvider(url),
      loadingBuilder: (context, child, downloadProgress) {
        if(downloadProgress != null) {
          child = Center(child: PlatformUI.createProgressIndicator(
              value: downloadProgress.expectedTotalBytes != null
                  ? downloadProgress.cumulativeBytesLoaded / downloadProgress.expectedTotalBytes
                  : null
          ));
        } else {
          if(aspectRatio != null) {
            child = FittedBox(
                fit: BoxFit.fill,
                child: child
            );
          } else {
            return child;
          }
        }

        if(aspectRatio != null) {
          return AspectRatio(
              aspectRatio: aspectRatio,
              child: child
          );
        } else {
          return child;
        }
      },
      errorBuilder: (context, error, stackTrace) => Icon(PlatformUI.ERROR),
    );
  }

  static Future<AlertDialogResults> showAlertDialog({
    @required BuildContext context,
    @required String text,
    List<String> fields,
    @required List<String> actions
  }) {
    final fieldControllers = new Map<String, TextEditingController>();
    return showDialog<String>(
        context: context,
        builder: (BuildContext bc) {
          final actionWidgets = actions.map((actionName) {
            if(shouldUseCupertino()) {
              return CupertinoDialogAction(
                child: Text(actionName),
                onPressed: () {
                  Navigator.pop(context, actionName);
                },
              );
            } else {
              return FlatButton(
                child: Text(actionName.toUpperCase()),
                onPressed: () {
                  Navigator.pop(context, actionName);
                },
              );
            }
          }).toList();

          Widget content;
          if(fields != null) {
            final children = new List<Widget>();
            children.add(Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(text)
            ));

            fields.forEach((fieldName) {
              fieldControllers[fieldName] = new TextEditingController();
              children.add(createTextField(
                  label: fieldName,
                  controller: fieldControllers[fieldName],
                  autofocus: children.length == 1,
                  obscureText: fieldName == "Password"
              ));
            });

            content = Column(
              mainAxisSize: MainAxisSize.min,
              children: children
            );
          } else {
            content = Text(text);
          }

          if(shouldUseCupertino()) {
            return new CupertinoAlertDialog(
                content: content,
                actions: actionWidgets
            );
          } else {
            return new AlertDialog(
                content: content,
                actions: actionWidgets
            );
          }
        }
    ).then((value) {
      return new AlertDialogResults(
          action: value,
          fields: fieldControllers.map((key, value) =>
              MapEntry(key, value.value.text))
      );
    });
  }

  static Widget wrapWithContextMenu({
    @required BuildContext context,
    @required Widget target,
    @required String title,
    @required List<String> actionNames,
    @required List<Function> actionFuncs
  }) {
    return GestureDetector(
        onLongPress: () {
          Widget body;
          if(shouldUseCupertino()) {
            body = CupertinoActionSheet(
              title: Text(title),
              actions: List.generate(actionNames.length, (index) => CupertinoActionSheetAction(
                  child: Text(actionNames[index]),
                  onPressed: () {
                    actionFuncs[index]();
                    Navigator.pop(context);
                  }
              )),
              cancelButton: CupertinoActionSheetAction(
                  child: Text("Cancel"),
                  onPressed: () => Navigator.pop(context)
              ),
            );
          } else {
            body = ListView.separated(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                separatorBuilder: (context, index) => Divider(color: Colors.black, height: 1),
                itemCount: actionNames.length,
                itemBuilder: (context, index) =>
                    FlatButton(
                        child: Text(actionNames[index]),
                        onPressed: () {
                          actionFuncs[index]();
                          Navigator.pop(context);
                        }
                    )
            );
          }

          showModal(
              context: context,
              title: title,
              body: body
          );
        },
        child: target
    );
  }

  static void showModal({
    @required BuildContext context,
    @required String title,
    @required Widget body
  }) {
    if(shouldUseCupertino()) {
      showCupertinoModalPopup(
          context: context,
          builder: (context) {
            final children = new List<Widget>();
            if(body is CupertinoActionSheet) {
              children.add(body);
            } else {
              children.add(CupertinoNavigationBar(
                  middle: Text(title),
                  automaticallyImplyLeading: false
              ));

              children.add(Container(
                  color: CupertinoTheme.brightnessOf(context) == Brightness.light
                      ? CupertinoColors.white
                      : CupertinoColors.black,
                  child: body
              ));
            }

            return SafeArea(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: children
              )
            );
          }
      );
    } else {
      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AppBar(
                      title: Text(title),
                      automaticallyImplyLeading: false,
                      centerTitle: true
                  ),
                  body
                ]
            );
          }
      );
    }
  }
}

class NavBarAction {
  final IconData icon;
  final String tooltip;
  final Function onPressed;

  NavBarAction({
    this.icon,
    this.tooltip,
    this.onPressed
  });
}

abstract class BottomNavPage extends StatefulWidget {
  BottomNavPage({Key key}) : super(key: key);

  List<NavBarAction> buildActions();
}

class AlertDialogResults {
  final String action;
  final Map<String, String> fields;

  AlertDialogResults({
    @required this.action,
    @required this.fields
  });
}