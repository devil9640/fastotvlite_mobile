import 'package:fastotv_common/colors.dart';
import 'package:fastotv_common/theming.dart';
import 'package:fastotvlite/localization/app_localizations.dart';
import 'package:fastotvlite/localization/translations.dart';
import 'package:fastotvlite/pages/debug_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persist_theme/persist_theme.dart';
import 'package:provider/provider.dart';

class AboutPage extends StatefulWidget {
  final String login;
  final DateTime expDate;
  final String deviceID;

  AboutPage(this.login, this.expDate, this.deviceID);

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  TextStyle mainTextStyle = TextStyle(fontSize: 16);
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool _snackBarShown = false;

  final divider = Divider(height: 0.0);

  void copyInfoSnackbar(String toCopy, String whatCopied) {
    if (_snackBarShown) {
      _snackBarShown = false;
      _scaffoldKey.currentState.hideCurrentSnackBar();
    }
    _snackBarShown = true;
    Clipboard.setData(new ClipboardData(text: toCopy));
    _scaffoldKey.currentState
        .showSnackBar(SnackBar(content: Text(whatCopied + ' ' + _translate(TR_COPIED))))
        .closed
        .then((_) {
      _snackBarShown = false;
    });
  }

  Widget login() {
    return ListTile(
        leading: Icon(Icons.account_box, color: CustomColor().themeBrightnessColor(context)),
        title: Text(_translate(TR_LOGIN_ABOUT)),
        subtitle: Text(widget.login),
        onTap: () {
          copyInfoSnackbar(widget.login, _translate(TR_LOGIN_ABOUT));
        });
  }

  Widget expDate() {
    return ListTile(
      leading: Icon(Icons.date_range, color: CustomColor().themeBrightnessColor(context)),
      title: Text(_translate(TR_EXPIRATION_DATE)),
      subtitle: Text(widget.expDate.toString()),
      onTap: () {},
    );
  }

  Widget deviceID() {
    return ListTile(
        leading: Icon(Icons.perm_device_information, color: CustomColor().themeBrightnessColor(context)),
        title: Text(_translate(TR_DEVICE_ID)),
        subtitle: Text(widget.deviceID),
        onTap: () {
          copyInfoSnackbar(widget.deviceID, 'ID');
        });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeModel>(
        builder: (context, model, child) => Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
                iconTheme: IconThemeData(color: CustomColor().primaryColorBrightness(model)),
                title:
                    Text(_translate(TR_ABOUT), style: TextStyle(color: CustomColor().primaryColorBrightness(model)))),
            body: Column(children: <Widget>[
              ListHeader(text: _translate(TR_ACCOUNT)),
              login(),
              expDate(),
              deviceID(),
              divider,
              ListHeader(text: _translate(TR_APP)),
              VersionTile.settings()
            ])));
  }

  String _translate(String key) => AppLocalizations.of(context).translate(key);
}
