import 'package:fastotv_common/colors.dart';
import 'package:fastotvlite/localization/app_localizations.dart';
import 'package:fastotvlite/localization/translations.dart';
import 'package:flutter/material.dart';

class LanguagePicker extends StatefulWidget {
  final Function onChanged;

  final int type;

  const LanguagePicker.settings(this.onChanged) : type = 0;

  const LanguagePicker.login(this.onChanged) : type = 1;

  @override
  _LanguagePickerState createState() => _LanguagePickerState();
}

class _LanguagePickerState extends State<LanguagePicker> {
  int _currentSelection = 0;

  @override
  Widget build(BuildContext context) {
    int currentLanguageIndex() {
      return SUPPORTED_LOCALES.indexOf(AppLocalizations.of(context).currentLocale()) ?? 0;
    }

    _currentSelection = currentLanguageIndex();
    if (widget.type == 0) {
      return _settings();
    } else if (widget.type == 1) {
      return _login();
    }
    return SizedBox();
  }

  // private:
  void _showAlertDialog() async {
    // show the dialog
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
              contentPadding: EdgeInsets.fromLTRB(0.0, 24.0, 0.0, 0.0),
              title: Text(AppLocalizations.of(context).translate(TR_LANGUAGE_CHOOSE) ?? "Choose language"),
              children: <Widget>[
                SingleChildScrollView(
                    child: new Column(
                        mainAxisSize: MainAxisSize.min,
                        children: new List<Widget>.generate(
                            SUPPORTED_LOCALES.length, (int index) => _dialogItem(SUPPORTED_LANGUAGES[index], index))))
              ]);
        });
    if (widget.onChanged != null) {
      widget.onChanged();
    }
  }

  Widget _dialogItem(String text, int itemvalue) {
    return RadioListTile(
      activeColor: Theme.of(context).accentColor,
      value: itemvalue,
      title: Text(text),
      groupValue: _currentSelection,
      onChanged: (int value) async {
        _currentSelection = itemvalue;
        final selectedLocale = SUPPORTED_LOCALES[itemvalue];
        AppLocalizations.of(context).load(selectedLocale);
        if (widget.onChanged != null) {
          widget.onChanged();
        }
        Navigator.of(context).pop();
      },
    );
  }

  Widget _settings() {
    return ListTile(
      leading: Icon(
        Icons.language,
        color: CustomColor().themeBrightnessColor(context),
      ),
      title: Text(AppLocalizations.of(context).translate(TR_LANGUAGE) ?? 'Language'),
      subtitle: Text(AppLocalizations.of(context).translate(TR_LANGUAGE_NAME) ?? "English"),
      onTap: () {
        _showAlertDialog();
      },
    );
  }

  Widget _login() {
    return FlatButton(
        onPressed: () {
          _showAlertDialog();
        },
        child: Opacity(
            opacity: 0.5,
            child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              Icon(Icons.language),
              SizedBox(width: 16),
              Text(AppLocalizations.of(context).translate(TR_LANGUAGE_NAME ?? "English"))
            ])));
  }
}
