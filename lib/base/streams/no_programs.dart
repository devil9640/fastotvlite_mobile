import 'package:fastotv_common/base/controls/no_channels.dart';
import 'package:fastotvlite/localization/app_localizations.dart';
import 'package:fastotvlite/localization/translations.dart';
import 'package:flutter/material.dart';

class NoPrograms extends StatelessWidget {
  final Color color;

  NoPrograms(this.color);

  @override
  Widget build(BuildContext context) {
    return NonAvailableBuffer(
        icon: Icons.error_outline,
        message: AppLocalizations.of(context).translate(TR_NO_PROGRAMS),
        iconSize: 16,
        textSize: 16,
        color: color);
  }
}
