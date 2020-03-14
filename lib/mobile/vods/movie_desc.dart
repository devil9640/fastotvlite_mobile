import 'package:flutter/material.dart';
import 'package:persist_theme/persist_theme.dart';
import 'package:provider/provider.dart';

import 'package:fastotv_common/base/controls/preview_icon.dart';
import 'package:fastotv_common/base/controls/favorite_button.dart';
import 'package:fastotv_common/base/vods/vod_description.dart';
import 'package:fastotvlite/localization/app_localizations.dart';
import 'package:fastotv_common/colors.dart';

import 'package:fastotvlite/channels/vod_stream.dart';
import 'package:fastotvlite/base/vods/vod_description.dart';

class VodDescription extends StatefulWidget {
  final VodStream vod;

  VodDescription({Key key, this.vod});

  VodStream currentVod() {
    return vod;
  }

  @override
  _VodDescriptionState createState() => _VodDescriptionState();
}

class _VodDescriptionState extends State<VodDescription> {
  static const String INVALID_TRAILER_URL = "https://fastocloud.com/static/video/invalid_trailer.m3u8";

  @override
  Widget build(BuildContext context) {
    final currentVod = widget.currentVod();

    Widget portrait(ThemeModel model) {
      return Column(children: <Widget>[
        Container(
            height: 216,
            child: Row(children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
                child: Container(width: 180, child: PreviewIcon.vod(currentVod.previewIcon())),
              ),
              VerticalDivider(),
              Expanded(
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Column(children: <Widget>[
                        userScore(currentVod),
                        Spacer(),
                        trailerButton(currentVod),
                        playButton(currentVod)
                      ])))
            ])),
        Divider(),
        sideInfo(currentVod),
        Divider(),
        description(currentVod)
      ]);
    }

    Widget landscape(ThemeModel model) {
      return Row(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.max, children: <Widget>[
        Container(
            width: 196,
            child: Column(children: <Widget>[
              Expanded(
                  flex: 8,
                  child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(child: PreviewIcon.vod(currentVod.previewIcon())))),
              trailerButton(currentVod, padding: 8),
              playButton(currentVod, padding: 8)
            ])),
        VerticalDivider(),
        Expanded(
            child: Column(children: <Widget>[
          Padding(
              padding: EdgeInsets.fromLTRB(16.0, 8.0, 8, 0),
              child: Row(children: <Widget>[userScore(currentVod), VerticalDivider(), sideInfo(currentVod)])),
          Divider(),
          description(currentVod)
        ]))
      ]);
    }

    return Consumer<ThemeModel>(
        builder: (context, model, child) => Scaffold(
            appBar: AppBar(
                iconTheme: IconThemeData(color: CustomColor().primaryColorBrightness(model)),
                title: Text(AppLocalizations.toUtf8(currentVod.displayName()),
                    style: TextStyle(color: CustomColor().primaryColorBrightness(model))),
                actions: <Widget>[
                  FavoriteStarButton(
                    widget.currentVod().favorite(),
                    onFavoriteChanged: (bool value) => callback(value),
                  )
                ]),
            body: OrientationBuilder(builder: (context, orientation) {
              return orientation == Orientation.portrait ? portrait(model) : landscape(model);
            })));
  }

  Widget userScore(VodStream currentVod) => UserScore(currentVod.userScore());

  Widget trailerButton(VodStream currentVod, {double padding}) {
    return currentVod.trailerUrl() == INVALID_TRAILER_URL
        ? Spacer(flex: 1)
        : Padding(
            padding: EdgeInsets.symmetric(horizontal: padding ?? 8), child: VodTrailerButton(currentVod, context));
  }

  Widget playButton(VodStream currentVod, {double padding}) {
    return Padding(padding: EdgeInsets.symmetric(horizontal: padding ?? 8), child: VodPlayButton(currentVod, context));
  }

  Widget description(VodStream currentVod) {
    return Flexible(child: VodDescriptionText(AppLocalizations.toUtf8(currentVod.description())));
  }

  Widget sideInfo(VodStream currentVod) {
    return SideInfo(
        country: AppLocalizations.toUtf8(currentVod.country()),
        duration: currentVod.duration(),
        primeDate: currentVod.primeDate());
  }

  void callback(bool value) {
    final current = widget.currentVod();
    current.setFavorite(value);
  }
}
