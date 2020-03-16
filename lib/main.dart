import 'package:fastotvlite/main/main_common.dart';
import 'package:fastotvlite/app_config.dart';
import 'package:flutter/material.dart';

void main() async {
  var configuredApp = AppConfig(buildType: BuildType.DEV, child: MyApp());

  await mainCommon();

  runApp(configuredApp);
}
