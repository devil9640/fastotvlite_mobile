import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:persist_theme/persist_theme.dart';
import 'package:provider/provider.dart';

import 'package:fastotv_common/colors.dart';
import 'package:fastotv_common/tv/key_code.dart';

import 'package:fastotvlite/tv/settings/tv_settings_page.dart';
import 'package:fastotvlite/localization/app_localizations.dart';
import 'package:fastotvlite/localization/translations.dart';

class ThemePickerTV extends StatefulWidget {
  final ThemeModel model;
  final FocusNode focus;
  final void Function() callback;

  ThemePickerTV(this.focus, this.callback, this.model);

  @override
  _ThemePickerTVState createState() {
    return _ThemePickerTVState();
  }
}

class _ThemePickerTVState extends State<ThemePickerTV> {
  static const THEME_LIST = [TR_LIGHT, TR_DARK, TR_BLACK];

  int themeGroupValue = 0;

  @override
  void initState() {
    super.initState();
    themeGroupValue = _themeNumber(widget.model);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeModel>(builder: (context, model, child) {
      return Focus(
          canRequestFocus: false,
          child: Container(
              child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            _dialogItem(THEME_LIST[0], 0, model),
            _dialogItem(THEME_LIST[1], 1, model),
            _dialogItem(THEME_LIST[2], 2, model)
          ])));
    });
  }

  Widget _dialogItem(String text, int itemvalue, ThemeModel model) {
    return Focus(
        onKey: _listControl,
        focusNode: widget.focus,
        child: Container(
            decoration: BoxDecoration(
                border: Border.all(
                    color: borderColor(itemvalue == themeGroupValue && widget.focus.hasPrimaryFocus), width: 2)),
            child: RadioListTile(
                activeColor: CustomColor().tvSelectedColor(),
                title: Text(AppLocalizations.of(context).translate(text), style: TextStyle(fontSize: 20)),
                value: itemvalue,
                groupValue: themeGroupValue,
                onChanged: _changeTheme)));
  }

  void _changeTheme(int value) {
    if (value == 0) {
      widget.model.changeDarkMode(false);
      widget.model.changeCustomTheme(false);
      widget.model.changeTrueBlack(false);
    } else if (value == 1) {
      widget.model.changeDarkMode(true);
      widget.model.changeCustomTheme(false);
      widget.model.changeTrueBlack(false);
    } else {
      widget.model.changeDarkMode(true);
      widget.model.changeCustomTheme(false);
      widget.model.changeTrueBlack(true);
      widget.model.changePrimaryColor(Colors.black);
    }
  }

  int _themeNumber(ThemeModel model) {
    if (model.type == ThemeType.light) {
      return 0;
    } else if (model.type == ThemeType.dark) {
      return 1;
    }
    return 2;
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
          widget.callback();
          break;
        default:
      }
    }
    return widget.focus.hasPrimaryFocus;
  }

  void _nextCategory() {
    if (themeGroupValue == THEME_LIST.length - 1) {
      themeGroupValue = 0;
    } else {
      themeGroupValue++;
    }
    _changeTheme(themeGroupValue);
  }

  void _prevCategory() {
    if (themeGroupValue == 0) {
      themeGroupValue = THEME_LIST.length - 1;
    } else {
      themeGroupValue--;
    }
    _changeTheme(themeGroupValue);
  }
}
