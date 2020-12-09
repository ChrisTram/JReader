import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:jreader/support/persist.dart';
import 'package:jreader/sourcelistpage.dart';
import 'package:jreader/support/platformui.dart';

void main() {
  runApp(JNovelClubApp());
}

class JNovelClubApp extends StatefulWidget {
  @override
  _JNovelClubAppState createState() => _JNovelClubAppState();
}

class _JNovelClubAppState extends State<JNovelClubApp> {
  @override
  void initState() {
    super.initState();
    Persistence.load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      },
      child: PlatformUI.createApp(
          title: 'J-Reader',
          home: SourceListPage()
      ),
    );
  }
}
