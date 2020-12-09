import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:jreader/source/source.dart';
import 'package:jreader/sourcepage.dart';
import 'package:jreader/support/persist.dart';
import 'package:jreader/support/platformui.dart';

class SourceListPage extends StatefulWidget {
  SourceListPage({Key key}) : super(key: key);

  @override
  _SourceListPageState createState() => _SourceListPageState();
}

class _SourceListPageState extends State<SourceListPage> {
  @override
  Widget build(BuildContext context) {
    final sources = Sources.all();
    return PlatformUI.createPage(
        context: context,
        title: "Sources",
        actions: [
          NavBarAction(
            icon: PlatformUI.IMPORT,
            tooltip: "Import Data",
            onPressed: (context) {
              PlatformUI.showAlertDialog(
                  context: context,
                  text: "Import data from clipboard?",
                  actions: ["Import", "Cancel"]
              ).then((result) {
                if(result.action == "Import") {
                  Clipboard.getData(Clipboard.kTextPlain)
                      .then((value) {
                        Persistence.loadData(value.text);
                        Persistence.save();
                      });
                }
              });
            },
          ),
          NavBarAction(
            icon: PlatformUI.EXPORT,
            tooltip: "Export Data",
            onPressed: (context) {
              PlatformUI.showAlertDialog(
                  context: context,
                  text: "Export data to clipboard?",
                  actions: ["Export", "Cancel"]
              ).then((result) {
                if(result.action == "Export") {
                  Clipboard.setData(ClipboardData(text: Persistence.saveData()));
                }
              });
            },
          )
        ],
        body: ListView.builder(
          scrollDirection: Axis.vertical,
          itemCount: sources.length,
          padding: EdgeInsets.all(8.0),
          itemBuilder: (context, index) {
            return Container(
                padding: EdgeInsets.fromLTRB(0, 0, 8, 8),
                child: PlatformUI.createRaisedButton(
                    context: context,
                    text: sources[index].name,
                    onPressed: () {
                      Navigator.push(
                        context,
                        PlatformUI.createPageRoute(builder: (context) => SourcePage(sources[index])),
                      );
                    }
                )
            );
          }
        )
    );
  }
}