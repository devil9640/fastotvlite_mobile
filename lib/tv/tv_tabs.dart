import 'dart:async';

import 'package:flutter/material.dart';

import 'package:fastotv_common/screen_orientation.dart' as orientation;
import 'package:fastotv_common/base/controls/logo.dart';
import 'package:fastotv_common/colors.dart';
import 'package:fastotv_common/clock.dart';

import 'package:fastotvlite/notification.dart';
import 'package:fastotvlite/shared_prefs.dart';
import 'package:fastotvlite/service_locator.dart';
import 'package:fastotvlite/base/add_streams/m3u_to_channels.dart';
import 'package:fastotvlite/base/add_streams/add_stream_dialog.dart';
import 'package:fastotvlite/channels/live_stream.dart';
import 'package:fastotvlite/channels/vod_stream.dart';
import 'package:fastotvlite/channels/istream.dart';
import 'package:fastotvlite/tv/vods/tv_vod_tab.dart';
import 'package:fastotvlite/tv/exit_dialog.dart';
import 'package:fastotvlite/tv/add_streams/tv_stream_quantity.dart';
import 'package:fastotvlite/tv/add_streams/tv_add_stream_dialog.dart';
import 'package:fastotvlite/tv/settings/tv_settings_page.dart';
import 'package:fastotvlite/tv/streams/tv_live_tab_alt.dart';
import 'package:fastotvlite/constants.dart';
import 'package:fastotvlite/events/stream_list_events.dart';
import 'package:fastotvlite/events/ascending.dart';
import 'package:fastotvlite/base/icon.dart';
import 'package:fastotvlite/localization/app_localizations.dart';
import 'package:fastotvlite/localization/translations.dart';

class HomeTV extends StatefulWidget {
  final List<LiveStream> channels;
  final List<VodStream> vods;
  final List<VodStream> series;
  final List<LiveStream> privateChannels;

  HomeTV(this.channels, this.vods, this.series, this.privateChannels);

  @override
  _HomeTVState createState() => _HomeTVState();
}

const TABBAR_HEIGHT = 72;

class _HomeTVState extends State<HomeTV> with TickerProviderStateMixin, WidgetsBindingObserver {
  StreamController<NotificationType> channelsStreamController = StreamController<NotificationType>.broadcast();
  StreamController<NotificationType> vodsStreamController = StreamController<NotificationType>.broadcast();
  StreamController<NotificationType> seriesStreamController = StreamController<NotificationType>.broadcast();
  StreamController<NotificationType> privateChannelsStreamController = StreamController<NotificationType>.broadcast();

  final List<String> _tabNodes = [];
  List<Widget> _typesTabView = [];

  List<LiveStream> _channels = [];
  List<VodStream> _vods = [];

  TabController _tabController;
  int _currentType = 0;
  bool isVisible = true;

  double _scale;

  int _initTypes() {
    if (widget.channels.isEmpty && widget.vods.isEmpty && widget.series.isEmpty && widget.privateChannels.isEmpty) {
      return 0;
    }

    final settings = locator<LocalStorageService>();
    bool isSaved = settings.saveLastViewed();
    String lastChannel = settings.lastChannel();
    int lastType;

    if (_channels.isNotEmpty) {
      final live = TR_LIVE_TV;
      _tabNodes.add(live);

      _typesTabView.add(ChannelsTabHomeTValt(_channels, privateChannelsStreamController));

      if (isSaved) {
        for (int i = 0; i < _channels.length; i++) {
          if (_channels[i].id() == lastChannel) {
            lastType = 0;
          }
        }
      }
    }
    if (_vods.isNotEmpty) {
      final vods = TR_VODS;
      _tabNodes.add(vods);
      _typesTabView.add(TVVodPage(_vods));
      if (isSaved && lastType == null) {
        for (int i = 0; i < _vods.length; i++) {
          if (_vods[i].id() == lastChannel) {
            lastType = 1;
          }
        }
      }
    }
    if (widget.series.isNotEmpty) {
      final series = TR_SERIES;
      _tabNodes.add(series);
      _typesTabView.add(TVVodPage(widget.series));
      if (isSaved && lastType == null) {
        for (int i = 0; i < widget.series.length; i++) {
          if (widget.series[i].id() == lastChannel) {
            lastType = 2;
          }
        }
      }
    }
    if (widget.privateChannels.isNotEmpty) {
      final priv = TR_PRIVATE_TV;
      _tabNodes.add(priv);
      _typesTabView.add(ChannelsTabHomeTValt(_channels, privateChannelsStreamController));
      if (isSaved && lastType == null) {
        for (int i = 0; i < widget.privateChannels.length; i++) {
          if (widget.privateChannels[i].id() == lastChannel) {
            lastType = 3;
          }
        }
      }
    }

    if (lastType != null) {
      return lastType;
    }
    return 0;
  }

  void _initTabController() {
    _tabController = TabController(vsync: this, length: _tabNodes.length, initialIndex: _currentType);
  }

  @override
  void initState() {
    orientation.onlyLandscape();
    super.initState();

    final events = locator<StreamListEvent>();
    events.subscribe<StreamsListEmptyEvent>().listen((_) => _onTypeDelete());

    final settings = locator<LocalStorageService>();
    _scale = settings.screenScale();

    _channels = widget.channels;
    _vods = widget.vods;
    _currentType = _initTypes();

    _initTabController();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveStreams();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool onTitlePush(TvChannelNotification notification) {
      switch (notification.title) {
        case NotificationType.FULLSCREEN:
          setState(() {
            isVisible = notification.visibility;
          });
          break;
        default:
      }

      return true;
    }

    Widget _home() {
      return _tabController.length > 0
          ? TabBarView(key: UniqueKey(), controller: _tabController, children: _typesTabView)
          : Center(child: Text(AppLocalizations.of(context).translate(TR_NO_STREAMS), style: TextStyle(fontSize: 24)));
    }

    return WillPopScope(
        onWillPop: () async => false,
        child: NotificationListener<TvChannelNotification>(
            onNotification: onTitlePush,
            child: FractionallySizedBox(
                widthFactor: _scale,
                heightFactor: _scale,
                child: new Scaffold(
                    resizeToAvoidBottomPadding: false,
                    backgroundColor: Theme.of(context).primaryColor,
                    body: Column(children: <Widget>[
                      Visibility(
                          visible: isVisible,
                          child: AppBar(
                              leading: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 0, 8), child: Logo(LOGO_PATH)),
                              backgroundColor: Colors.transparent,
                              iconTheme: IconThemeData(color: CustomColor().themeBrightnessColor(context)),
                              actionsIconTheme: IconThemeData(color: CustomColor().themeBrightnessColor(context)),
                              elevation: 0,
                              title: Row(children: <Widget>[
                                SizedBox(width: 16),
                                TabBar(
                                    indicatorColor: CustomColor().tvSelectedColor(),
                                    controller: _tabController,
                                    isScrollable: true,
                                    tabs: List<_Tab>.generate(_tabNodes.length, (int index) => _Tab(_tabNodes[index])))
                              ]),
                              actions: <Widget>[
                                CustomIcons(Icons.add_circle, () => _onAdd()),
                                CustomIcons(Icons.settings, () => _toSettings()),
                                CustomIcons(Icons.power_settings_new, () => _showExitDialog()),
                                Clock.full(textColor: CustomColor().themeBrightnessColor(context))
                              ])),
                      Expanded(child: _home())
                    ])))));
  }

  void _toSettings() async {
    channelsStreamController.add(NotificationType.TO_SETTINGS);
    double padding = await Navigator.push(context, MaterialPageRoute(builder: (context) => SettingPageTV()));
    channelsStreamController.add(NotificationType.EXIT_SETTINGS);
    setState(() {
      _scale = padding;
    });
  }

  void _onAdd() async {
    PickStreamFrom _source =
        await showDialog(context: context, builder: (BuildContext context) => StreamTypePickerTV());
    if (_source != null) {
      AddStreamResponse result =
          await showDialog(context: context, builder: (BuildContext context) => FilePickerDialogTV(_source));
      if (result != null) {
        if (result.type == StreamType.Live) {
          _addLiveStreams(result.channels);
          _saveStreams(type: StreamType.Live);
        } else {
          _addVodStreams(result.vods);
          _saveStreams(type: StreamType.Vod);
        }
      }
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _addLiveStreams(List<LiveStream> streams) {
    if (!_tabNodes.contains(TR_LIVE_TV)) {
      _tabNodes.insert(0, TR_LIVE_TV);
      _typesTabView.insert(0, ChannelsTabHomeTValt(_channels, privateChannelsStreamController));
      _initTabController();
      _currentType = _tabNodes.length;
    }

    streams.forEach((channel) {
      bool contains = _containsStream(_channels, channel);
      if (!contains) {
        _channels.add(channel);
      }
    });
  }

  void _addVodStreams(List<VodStream> streams) {
    if (!_tabNodes.contains(TR_VODS)) {
      _tabNodes.insert(0, TR_VODS);
      _typesTabView.insert(0, TVVodPage(_vods));
      _initTabController();
    }

    streams.forEach((stream) {
      bool contains = _containsStream(_vods, stream);
      if (!contains) {
        _vods.add(stream);
      }
    });
  }

  bool _containsStream<U extends IStream>(List<U> list, U add) {
    for (int i = 0; i < list.length; i++) {
      if (list[i].primaryUrl() == add?.primaryUrl()) {
        return true;
      }
    }
    return false;
  }

  void _showExitDialog() async {
    await showDialog(context: context, builder: (BuildContext context) => ExitDialog());
  }

  void _saveStreams({StreamType type}) {
    final settings = locator<LocalStorageService>();
    if (type == null) {
      settings.saveLiveChannels(_channels);
      settings.saveVods(_vods);
    } else {
      if (type == StreamType.Live) {
        settings.saveLiveChannels(_channels);
      }
      if (type == StreamType.Vod) {
        settings.saveVods(_vods);
      }
    }
  }

  void _onTypeDelete() {
    _currentType = 0;
    if (_channels.isEmpty && widget.vods.isEmpty && widget.series.isEmpty) {
      _typesTabView.clear();
      _tabNodes.clear();
    } else {
      _typesTabView.removeAt(_currentType);
      _tabNodes.removeAt(_currentType);
    }
    _initTabController();
    setState(() {});
  }
}

class _Tab extends StatelessWidget {
  final String title;

  _Tab(this.title);

  @override
  Widget build(BuildContext context) {
    return Focus(
        focusNode: FocusNode(),
        autofocus: true,
        child: Tab(
            child: Text(AppLocalizations.of(context).translate(title),
                style: TextStyle(fontSize: 20, color: CustomColor().themeBrightnessColor(context)))));
  }
}
