import 'package:flutter/widgets.dart';
import 'package:jreader/source/source.dart';
import 'package:jreader/support/platformui.dart';

class AccountPage extends BottomNavPage {
  final Source _source;

  AccountPage(this._source, {Key key}) : super(key: key);

  @override
  _AccountPageState createState() => _AccountPageState(_source);

  @override
  List<NavBarAction> buildActions() {
    return [];
  }
}

class _AccountPageState extends State<AccountPage> {
  final Source _source;

  Future<List<String>> _futureUserInfo;

  _AccountPageState(this._source);

  @override
  void initState() {
    super.initState();

    if(_source.isLoggedIn()) {
      _futureUserInfo = _source.getUserInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children;
    if(_source.isLoggedIn()) {
      children = [
        Center(
            child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Logged in as: ${_source.getUsername()}")
            )
        ),
        FutureBuilder<List<String>>(
          future: _futureUserInfo,
          builder: (context, snapshot) {
            if(snapshot.hasData) {
              final lines = new List<Widget>();
              for(final line in snapshot.data) {
                lines.add(Center(
                    child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(line)
                    )
                ));
              }

              return Column(
                children: lines
              );
            } else if(snapshot.hasError) {
              return Center(child: Text("Error loading user info: ${snapshot.error}"));
            } else {
              return Center(child: PlatformUI.createProgressIndicator());
            }
          },
        ),
        PlatformUI.createRaisedButton(
            context: context,
            text: "Log out",
            onPressed: () {
              _logout();
            }
        ),
      ];
    } else {
      children = [
        PlatformUI.createRaisedButton(
            context: context,
            text: "Log in",
            onPressed: () {
              _login();
            }
        )
      ];
    }

    return ListView(
        scrollDirection: Axis.vertical,
        padding: EdgeInsets.all(8.0),
        children: children
    );
  }

  void _login() {
    PlatformUI.showAlertDialog(
        context: context,
        text: "Enter account details.",
        fields: ["Username", "Password"],
        actions: ["Log In", "Cancel"]
    ).then((result) {
      if(result.action == "Log In") {
        _performLogin(result.fields["Username"], result.fields["Password"]);
      }
    });
  }

  void _performLogin(String username, String password) {
    _source.login(username, password).then((value) {
      setState(() {
        _futureUserInfo = _source.getUserInfo();
      });
    }).catchError((error) {
      PlatformUI.showAlertDialog(
          context: context,
          text: "Login failed: $error",
          actions: ["OK"]
      );
    });
  }

  void _logout() {
    _source.logout().then((value) {
      this.setState(() {
        // Update account page state.
      });
    });
  }
}