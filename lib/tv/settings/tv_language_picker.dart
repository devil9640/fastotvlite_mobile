import 'package:fastotv_common/colors.dart';
import 'package:fastotv_common/tv/key_code.dart';
import 'package:fastotvlite/localization/app_localizations.dart';
import 'package:fastotvlite/service_locator.dart';
import 'package:fastotvlite/shared_prefs.dart';
import 'package:fastotvlite/tv/settings/tv_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LanguagePickerTV extends StatefulWidget {
  final FocusNode focus;
  final void Function() callback;

  LanguagePickerTV(this.focus, this.callback);

  @override
  _LanguagePickerTVState createState() {
    return _LanguagePickerTVState();
  }
}

class _LanguagePickerTVState extends State<LanguagePickerTV> {
  int _currentSelection = 0;

  @override
  Widget build(BuildContext context) {
    int currentLanguageIndex() {
      return SUPPORTED_LOCALES.indexOf(AppLocalizations.of(context).currentLocale()) ?? 0;
    }

    _currentSelection = currentLanguageIndex();
    return Focus(
        canRequestFocus: false,
        child: Container(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: new List<Widget>.generate(
                    SUPPORTED_LANGUAGES.length, (int index) => _dialogItem(SUPPORTED_LANGUAGES[index], index)))));
  }

  Widget _dialogItem(String text, int itemvalue) {
    return Focus(
        onKey: _listControl,
        focusNode: widget.focus,
        child: Container(
            decoration: BoxDecoration(
                border: Border.all(
                    color: borderColor(itemvalue == _currentSelection && widget.focus.hasPrimaryFocus), width: 2)),
            child: RadioListTile(
                activeColor: CustomColor().tvSelectedColor(),
                title: Text(text, style: TextStyle(fontSize: 20)),
                value: itemvalue,
                groupValue: _currentSelection,
                onChanged: _changeLanguage)));
  }

  void _changeLanguage(int value) async {
    _currentSelection = value;
    final selectedLocale = SUPPORTED_LOCALES[value];
    await AppLocalizations.of(context).load(selectedLocale);
    final settings = locator<LocalStorageService>();
    settings.setLangCode(selectedLocale.languageCode);
    settings.setCountryCode(selectedLocale.countryCode);
    widget.callback();
  }

  bool _listControl(FocusNode node, RawKeyEvent event) {
    if (event is RawKeyDownEvent && event.data is RawKeyEventDataAndroid) {
      RawKeyDownEvent rawKeyDownEvent = event;
      RawKeyEventDataAndroid rawKeyEventDataAndroid = rawKeyDownEvent.data;
      switch (rawKeyEventDataAndroid.keyCode) {
        case KEY_UP:
          _prevCategory();
          break;
        case KEY_DOWN:
          _nextCategory();
          break;
        case KEY_LEFT:
          FocusScope.of(context).focusInDirection(TraversalDirection.left);
          widget.callback();
          break;
        default:
      }
    }
    return widget.focus.hasPrimaryFocus;
  }

  void _nextCategory() {
    if (_currentSelection == SUPPORTED_LOCALES.length - 1) {
      _currentSelection = 0;
    } else {
      _currentSelection++;
    }
    _changeLanguage(_currentSelection);
  }

  void _prevCategory() {
    if (_currentSelection == 0) {
      _currentSelection = SUPPORTED_LOCALES.length - 1;
    } else {
      _currentSelection--;
    }
    _changeLanguage(_currentSelection);
  }
}
