import 'package:fastotvlite/channels/live_stream.dart';
import 'package:fastotvlite/channels/vod_stream.dart';
import 'package:flutter/material.dart';

import 'package:fastotv_common/runtime_device.dart';

import 'package:fastotvlite/service_locator.dart';
import 'package:fastotvlite/mobile/mobile_home.dart';
import 'package:fastotvlite/shared_prefs.dart';
import 'package:fastotvlite/tv/tv_tabs.dart';
import 'package:fastotvlite/localization/app_localizations.dart';

class LoginPageBuffer extends StatefulWidget {
  @override
  _LoginPageBufferState createState() => _LoginPageBufferState();
}

class _LoginPageBufferState extends State<LoginPageBuffer> {
  List<LiveStream> channels = [];
  List<VodStream> vods = [];
  List<VodStream> series = [];
  List<LiveStream> privateChannels = [];
  bool _hasTouch;

  @override
  void initState() {
    super.initState();
    final settings = locator<LocalStorageService>();
    channels = settings.liveChannels();
    vods = settings.vods();

    final langCode = settings.langCode();
    final countryCode = settings.countryCode();
    if (langCode != null && countryCode != null) {
      final savedLocale = Locale(settings.langCode(), settings.countryCode());
      WidgetsBinding.instance.addPostFrameCallback((_) => AppLocalizations.of(context).load(savedLocale));
    }

    final device = locator<RuntimeDevice>();
    _hasTouch = device.hasTouch;
  }

  @override
  Widget build(BuildContext context) {
    return _hasTouch
        ? HomePage(channels, vods, series, privateChannels)
        : HomeTV(channels, vods, series, privateChannels);
  }
}
