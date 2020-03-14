import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// https://resocoder.com/2019/06/01/flutter-localization-the-easy-way-internationalization-with-json/

const SUPPORTED_LOCALES = [const Locale('en', 'US'), const Locale('ru', 'RU'), const Locale('fr', 'CA')];
const SUPPORTED_LANGUAGES = ['English', 'Русский', 'Français'];

class AppLocalizations {
  Locale _locale = defaultLocale();

  AppLocalizations();

  // Helper method to keep the code in the widgets concise
  // Localizations are accessed using an InheritedWidget "of" syntax
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static String toUtf8(String data) {
    String _output;
    try {
      _output = utf8.decode(data.codeUnits);
    } on FormatException catch (e) {
      print('error caught: $e');
      _output = data;
    }
    return _output;
  }

  Map<String, String> _localizedStrings;

  Locale currentLocale() {
    return _locale;
  }

  Future<bool> load(Locale locale) async {
    // Load the language JSON file from the "lang" folder
    String jsonString = await rootBundle.loadString('install/lang/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    _locale = locale;
    return true;
  }

  // This method will be called from every widget which needs a localized text
  String translate(String key) {
    return _localizedStrings[key];
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static Locale defaultLocale() {
    return SUPPORTED_LOCALES[0];
  }
}

// LocalizationsDelegate is a factory for a set of localized resources
// In this case, the localized strings will be gotten in an AppLocalizations object
class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  // This delegate instance will never change (it doesn't even have fields!)
  // It can provide a constant constructor.
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Include all of your supported language codes here
    for (var sup in SUPPORTED_LOCALES) {
      if (sup.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // AppLocalizations class is where the JSON loading actually runs
    AppLocalizations localizations = new AppLocalizations();
    await localizations.load(locale);
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
