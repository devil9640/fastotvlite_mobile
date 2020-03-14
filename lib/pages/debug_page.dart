import 'package:fastotv_device_info/devices.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:persist_theme/persist_theme.dart';
import 'package:provider/provider.dart';

import 'package:fastotv_common/colors.dart';
import 'package:fastotvlite/localization/app_localizations.dart';
import 'package:fastotv_common/package_manager.dart';
import 'package:fastotv_common/tv/key_code.dart';

import 'package:fastotvlite/service_locator.dart';
import 'package:fastotv_common/runtime_device.dart';

const DEVELOPER_SETTINGS_COUNTER = 7;

class DebugQueryInfo extends StatefulWidget {
  final bool isTv;

  DebugQueryInfo(this.isTv);

  @override
  _DebugQueryInfoState createState() => _DebugQueryInfoState();
}

class _DebugQueryInfoState extends State<DebugQueryInfo> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => FocusScope.of(context).requestFocus(_focusNode));
    super.initState();
  }

  List<Widget> get _device {
    final device = locator<RuntimeDevice>();
    final android = device.androidDetails;
    final green = TextStyle(color: Colors.green[400], fontWeight: FontWeight.bold);
    final red = TextStyle(color: Colors.red[400]);
    final estimatedColor = device.isRegisteredInOurDB() ? green : red;
    if (android != null) {
      return <Widget>[
        Text("Estimated Device: ${device.name}", style: estimatedColor),
        Text("os: ${device.os}"),
        Text("brand: ${android.brand}"),
        Text("device: ${android.device}"),
        Text("display: ${android.display}"),
        Text("manufacturer: ${android.manufacturer}", style: red),
        Text("model: ${android.model}", style: red),
        Text("fingerprint: ${android.fingerprint}"),
        Text("version: ${android.version}"),
        Text("has touch: ${device.hasTouch}", style: red)
      ];
    }

    final ios = device.iosDetails;
    if (ios != null) {
      return <Widget>[
        Text("Estimated Device: ${device.name}", style: estimatedColor),
        Text("os: ${device.os}"),
        Text("model: ${ios.utsname.machine}", style: red),
        Text("manufacturer: " + APPLE_BRAND, style: red),
        Text("name: ${ios.name}"),
        Text("systemName: ${ios.systemName}"),
        Text("systemVersion: ${ios.systemVersion}"),
        Text("localizedModel: ${ios.localizedModel}"),
        Text(
            "utsname: ${ios.utsname.sysname}\n${ios.utsname.nodename}\n${ios.utsname.release}\n${ios.utsname.version}\n${ios.utsname.machine}"),
        Text("has touch: ${device.hasTouch}", style: red),
      ];
    }

    return <Widget>[];
  }

  FocusNode _focusNode = FocusNode();

  void onBackButton(RawKeyEvent event, FocusNode node) {
    if (event is RawKeyDownEvent && event.data is RawKeyEventDataAndroid) {
      if (node.hasFocus || node.hasPrimaryFocus) {
        RawKeyDownEvent rawKeyDownEvent = event;
        RawKeyEventDataAndroid rawKeyEventDataAndroid = rawKeyDownEvent.data;
        switch (rawKeyEventDataAndroid.keyCode) {
          case KEY_CENTER:
            Navigator.of(context).pop();
            break;
          case ENTER:
            Navigator.of(context).pop();
            break;

          default:
            break;
        }
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    Color iconColor(ThemeModel model) {
      if (widget.isTv) {
        return CustomColor().primaryColorBrightness(model);
      } else if (_focusNode.hasFocus || _focusNode.hasPrimaryFocus) {
        return Colors.white;
      } else {
        return CustomColor().themeBrightnessColor(context);
      }
    }

    final red = TextStyle(color: Colors.red[400]);
    return Consumer<ThemeModel>(builder: (context, model, child) {
      return Scaffold(
          appBar: AppBar(
              leading: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Stack(children: <Widget>[
                    RawKeyboardListener(
                        focusNode: _focusNode,
                        onKey: (RawKeyEvent event) {
                          onBackButton(event, _focusNode);
                        },
                        child: SizedBox()),
                    IconButton(
                        focusNode: _focusNode,
                        focusColor: Colors.amber,
                        icon: Icon(Icons.arrow_back),
                        iconSize: 32,
                        color: iconColor(model),
                        onPressed: () {
                          Navigator.of(context).pop();
                        })
                  ])),
              title: Text(AppLocalizations.toUtf8('Device info'),
                  style: TextStyle(color: CustomColor().primaryColorBrightness(model)))),
          body: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView(
                  children: _device
                    ..addAll([
                      Text("devicePixelRatio: ${media.devicePixelRatio}", style: red),
                      Text("padding: ${media.padding}", style: red),
                      Text("size: ${media.size}", style: red),
                      Text("viewInsets: ${media.viewInsets}"),
                      Text("textScaleFactor: ${media.textScaleFactor}"),
                      Text("platformBrightness: ${media.platformBrightness}"),
                      Text("boldText: ${media.boldText}"),
                    ]))));
    });
  }
}

class VersionTile extends StatefulWidget {
  final int increment;

  final int type;

  const VersionTile.settings({this.increment}) : type = 0;

  const VersionTile.login({this.increment}) : type = 1;

  @override
  VersionTileState createState() => VersionTileState();
}

class VersionTileState extends State<VersionTile> {
  int counter = 0;

  void toInfo() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => DebugQueryInfo(false)));
    counter = 0;
  }

  Widget _login(String version) {
    return Opacity(
        opacity: 0.5,
        child: InkWell(
            child: Text(version),
            onTap: () {
              counter++;
              if (counter == DEVELOPER_SETTINGS_COUNTER) {
                toInfo();
              }
            }));
  }

  Widget _settings(String version) {
    return ListTile(
        leading: Icon(Icons.info, color: CustomColor().themeBrightnessColor(context)),
        title: Text('Version'),
        subtitle: Text(version),
        onTap: () {
          counter++;
          if (counter == DEVELOPER_SETTINGS_COUNTER) {
            toInfo();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final package = locator<PackageManager>();
    final version = package.version();
    if (widget.type == 0) {
      return _settings(version);
    }
    if (widget.type == 1) {
      return _login(version);
    }
    return SizedBox();
  }
}
