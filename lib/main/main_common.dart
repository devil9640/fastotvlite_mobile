import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:persist_theme/persist_theme.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:fastotvlite/localization/app_localizations.dart';

import 'package:fastotvlite/service_locator.dart';
import 'package:fastotvlite/pages/login_page.dart';

Future<void> mainCommon() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
}

class MyApp extends StatelessWidget {
  final _model = ThemeModel();

  @override
  Widget build(BuildContext context) {
    final app = Consumer<ThemeModel>(builder: (context, model, child) {
      return Shortcuts(
          shortcuts: {LogicalKeySet(LogicalKeyboardKey.select): const Intent(ActivateAction.key)},
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: model.theme,
            supportedLocales: SUPPORTED_LOCALES,
            // These delegates make sure that the localization data for the proper language is loaded
            localizationsDelegates: [
              // THIS CLASS WILL BE ADDED LATER
              // A class which loads the translations from JSON files
              AppLocalizations.delegate,
              // Built-in localization of basic text for Material widgets
              GlobalMaterialLocalizations.delegate,
              // Built-in localization for text direction LTR/RTL
              GlobalWidgetsLocalizations.delegate
            ],
            // Returns a locale which will be used by the app
            localeResolutionCallback: (locale, supportedLocales) {
              // Check if the current device locale is supported
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale != null && locale != null) {
                  if (supportedLocale.languageCode == locale.languageCode &&
                      supportedLocale.countryCode == locale.countryCode) {
                    return supportedLocale;
                  }
                }
              }
              // If the locale of the device is not supported, use the first one
              // from the list (English, in this case).
              return supportedLocales.first;
            },
            home: LoginPageBuffer(),
          ));
    });

    return ListenableProvider<ThemeModel>(builder: (_) => _model..init(), child: app);
  }
}
