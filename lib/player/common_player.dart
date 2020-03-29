import 'package:fastotvlite/base/streams/live_bottom_controls.dart';
import 'package:fastotvlite/service_locator.dart';
import 'package:fastotvlite/shared_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fastotv_common/player/appbar_player.dart';

abstract class AppBarPlayerCommon<T extends StatefulWidget> extends AppBarPlayer<T> {
  bool brightnessChange() {
    final settings = locator<LocalStorageService>();
    return settings.brightnessChange();
  }

  bool soundChange() {
    final settings = locator<LocalStorageService>();
    return settings.soundChange();
  }

  double interfaceOpacity() => INTERFACE_OPACITY;
}
