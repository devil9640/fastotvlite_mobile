import 'package:get_it/get_it.dart';

import 'package:fastotv_common/package_manager.dart';
import 'package:fastotv_common/runtime_device.dart';

import 'package:fastotvlite/shared_prefs.dart';
import 'package:fastotvlite/events/stream_list_events.dart';

// https://www.filledstacks.com/snippet/shared-preferences-service-in-flutter-for-code-maintainability/

GetIt locator = GetIt.instance;

Future setupLocator() async {
  var device = await RuntimeDevice.getInstance();
  locator.registerSingleton<RuntimeDevice>(device);
  
  var clientEvents = await StreamListEvent.getInstance();
  locator.registerSingleton<StreamListEvent>(clientEvents);

  var storage = await LocalStorageService.getInstance();
  locator.registerSingleton<LocalStorageService>(storage);

  var package = await PackageManager.getInstance();
  locator.registerSingleton<PackageManager>(package);
}
