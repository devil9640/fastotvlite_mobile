import 'dart:async';

import 'package:fastotv_common/base/controls/favorite_button.dart';
import 'package:fastotv_common/base/controls/no_channels.dart';
import 'package:fastotv_common/colors.dart';
import 'package:fastotv_common/scroll_controller_manager.dart';
import 'package:fastotv_common/tv/key_code.dart';
import 'package:fastotv_dart/commands_info/programme_info.dart';
import 'package:fastotvlite/base/icon.dart';
import 'package:fastotvlite/base/stream_parser.dart';
import 'package:fastotvlite/base/streams/live_timeline.dart';
import 'package:fastotvlite/base/streams/program_bloc.dart';
import 'package:fastotvlite/base/streams/program_time.dart';
import 'package:fastotvlite/base/streams/programs_list.dart';
import 'package:fastotvlite/channels/live_stream.dart';
import 'package:fastotvlite/events/ascending.dart';
import 'package:fastotvlite/events/stream_list_events.dart';
import 'package:fastotvlite/localization/app_localizations.dart';
import 'package:fastotvlite/localization/translations.dart';
import 'package:fastotvlite/notification.dart';
import 'package:fastotvlite/player/stream_player.dart';
import 'package:fastotvlite/service_locator.dart';
import 'package:fastotvlite/shared_prefs.dart';
import 'package:fastotvlite/tv/streams/tv_live_edit_channel.dart';
import 'package:fastotvlite/tv/tv_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fastotv_common/base/controls/preview_icon.dart';

class ChannelsTabHomeTValt extends StatefulWidget {
  final List<LiveStream> channels;
  final StreamController<NotificationType> stream;

  ChannelsTabHomeTValt(this.channels, this.stream);

  @override
  _ChannelsTabHomeTValtState createState() {
    return _ChannelsTabHomeTValtState();
  }
}

class _ChannelsTabHomeTValtState extends State<ChannelsTabHomeTValt> {
  static const LIST_ITEM_SIZE = 64.0;
  static const LIST_HEADER_SIZE = 32.0;

  bool _isSnackbarActive = false;

  bool notFullScreen = true;

  double scale;

  StreamPlayerPage _playerPage;
  FocusNode playerFocus = FocusNode();

  List<String> _categories = [];
  int currentCategory = 1;

  Map<String, List<LiveStream>> channelsMap = {};
  CustomScrollController _channelsController = CustomScrollController(itemHeight: LIST_ITEM_SIZE);
  int currentChannel = 0;
  LiveStream currentPlaying;

  ProgramsBloc programsBloc;

  void _parseChannels() {
    channelsMap = StreamsParser<LiveStream>(widget.channels).parseChannels();
    _categories = channelsMap.keys.toList();
    if (channelsMap[TR_RECENT].isEmpty) {
      currentCategory++;
    }
  }

  LiveStream _getCurrentChannel() {
    final channels = _getCurrentChannels();
    return channels[currentChannel];
  }

  List<LiveStream> _getCurrentChannels() {
    final category = _categories[currentCategory];
    return channelsMap[category];
  }

  @override
  void initState() {
    super.initState();

    final settings = locator<LocalStorageService>();
    scale = settings.screenScale();

    _parseChannels();
    widget.stream.stream.asBroadcastStream().listen((command) => controlFromTabs(command));

    final channel = _getCurrentChannel();
    currentPlaying = channel;
    _playerPage = StreamPlayerPage(channel: channel);
    initProgramsBloc();
    WidgetsBinding.instance.addPostFrameCallback((_) => _lastViewed());
  }

  void _lastViewed() {
    final settings = locator<LocalStorageService>();

    final lastChannelID = settings.lastChannel();
    if (lastChannelID == null) {
      return;
    }

    final channels = channelsMap[TR_ALL];
    for (int i = 0; i < channels.length; i++) {
      if (channels[i].id() == lastChannelID) {
        currentChannel = i;
        _playChannel(i);
        _channelsController.moveToPosition(i);
        FocusScope.of(context).requestFocus(playerFocus);
        setFullscreenOff(false);
        return;
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    programsBloc.dispose();
    _channelsController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableSpace = MediaQuery.of(context).size * scale;

    Widget categoriesWidget() {
      return _Categories(
          onKey: _onCategory,
          category: _categories[currentCategory],
          size: Size(availableSpace.width / 5, LIST_HEADER_SIZE));
    }

    Widget channelsList() {
      final channels = _getCurrentChannels();
      final _size = Size(availableSpace.width / 5, availableSpace.height - LIST_HEADER_SIZE - TABBAR_HEIGHT);
      if (currentCategory == 0 && channelsMap[TR_FAVORITE].length == 0) {
        return _NoChannels.favorite(_size);
      } else if (currentCategory == 1 && channelsMap[TR_RECENT].length == 0) {
        return _NoChannels.recent(_size);
      }
      return _ChannelsList(
          onTap: (index) => _playChannel(index),
          channels: channels,
          scrollController: _channelsController.controller,
          itemHeight: LIST_ITEM_SIZE,
          size: _size);
    }

    Widget channelInfo() {
      return Padding(
          padding: EdgeInsets.all(16.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: <Widget>[
            _TimeLine(programsBloc, Size(availableSpace.width / 2, 36 * scale)),
            SizedBox(height: 16 * scale),
            Row(children: <Widget>[
              Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Text(AppLocalizations.of(context).translate(TR_CURRENT_CHANNEL)),
                Text(AppLocalizations.toUtf8(currentPlaying.displayName()),
                    style: TextStyle(fontSize: 24 * scale), overflow: TextOverflow.ellipsis)
              ]),
              Spacer(),
              FavoriteStarButton(currentPlaying.favorite(),
                  onFavoriteChanged: (bool value) => _handleFavorite(), selectedColor: CustomColor().tvSelectedColor()),
              CustomIcons(Icons.edit, () => _editChannel(currentPlaying)),
              CustomIcons(Icons.delete, () => _deleteChannel(currentPlaying))
            ]),
            SizedBox(height: 16 * scale),
            _ProgramTitle(programsBloc),
            _ProgramName(programsBloc, Size(availableSpace.width / 2, 24 * scale), 24 * scale)
          ]));
    }

    Widget programs() {
      return _Programs(
          LIST_ITEM_SIZE, Size(availableSpace.width * 0.3, availableSpace.height - TABBAR_HEIGHT), programsBloc);
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
      Visibility(
          visible: notFullScreen,
          child: Column(children: <Widget>[categoriesWidget(), Divider(height: 0.0), channelsList()])),
      Visibility(visible: notFullScreen, child: VerticalDivider(width: 0.0)),
      Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        _TvPlayerWrap(_playerPage, availableSpace, !notFullScreen, _onPlayer),
        Visibility(visible: notFullScreen, child: channelInfo())
      ])),
      Visibility(visible: notFullScreen, child: programs())
    ]);
  }

  Color selectedColor(FocusNode focus) => focus.hasPrimaryFocus ? CustomColor().tvSelectedColor() : Colors.grey;

  void controlFromTabs(NotificationType command) {
    if (context != null) {
      switch (command) {
        case NotificationType.TO_SETTINGS:
          _playerPage.pause();
          break;
        case NotificationType.EXIT_SETTINGS:
          final channel = _getCurrentChannel();
          _playerPage.playChannel(channel);
          break;
        default:
          break;
      }
      setState(() {});
    }
  }

  void sendRecent() {
    DateTime now = DateTime.now();
    final channel = _getCurrentChannel();
    channel.setRecentTime(now.millisecondsSinceEpoch);
  }

  void _prevCategory() {
    currentChannel = 0;
    if (currentCategory == 0) {
      currentCategory = _categories.length - 1;
    } else {
      currentCategory--;
    }
  }

  void _nextCategory() {
    currentChannel = 0;
    if (currentCategory == _categories.length - 1) {
      currentCategory = 0;
    } else {
      currentCategory++;
    }
  }

  void _playNext() {
    final channels = _getCurrentChannels();
    if (currentChannel == channels.length - 1) {
      if (notFullScreen) {
        _channelsController.moveToTop();
      }
      currentChannel = 0;
    } else {
      if (notFullScreen) {
        _channelsController.moveDown();
      }
      currentChannel++;
    }
    _playChannel(currentChannel);
  }

  void _playPrev() {
    if (currentChannel == 0) {
      final channels = _getCurrentChannels();
      if (notFullScreen) {
        _channelsController.moveToBottom();
      }
      currentChannel = channels.length - 1;
    } else {
      if (notFullScreen) {
        _channelsController.moveUp();
      }
      currentChannel--;
    }
    _playChannel(currentChannel);
  }

  void _playChannel(int index) {
    currentChannel = index;
    currentPlaying = _getCurrentChannel();
    initProgramsBloc();
    _playerPage.playChannel(currentPlaying);
    _addRecent(currentPlaying);
    setState(() {});
  }

  void _showSnackBar(bool show) {
    if (show == _isSnackbarActive) {
      return;
    }

    if (show) {
      _isSnackbarActive = true;
      final channel = _getCurrentChannel();
      final contentColor = CustomColor().themeBrightnessColor(context);
      final backColor = Theme.of(context).brightness == Brightness.dark ? Colors.black87 : Colors.white70;
      final snack = SnackBar(
          backgroundColor: backColor,
          content: Container(
              child: Row(children: <Widget>[
            SizedBox(width: 32),
            Text(AppLocalizations.toUtf8(channel.displayName()),
                style: TextStyle(fontSize: 36, color: contentColor),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false),
            Spacer(),
            Icon(_playerPage.isPlaying() ? Icons.pause : Icons.play_arrow, size: 48, color: contentColor)
          ])));
      Scaffold.of(context).showSnackBar(snack).closed.then((_) {
        _isSnackbarActive = false;
      });
    } else {
      Scaffold.of(context).hideCurrentSnackBar();
    }
  }

  void _addFavorite(LiveStream channel) {
    channelsMap[TR_FAVORITE].insert(0, channel);
  }

  void _deleteFavorite(LiveStream channel) {
    channelsMap[TR_FAVORITE].remove(channel);
  }

  void _handleFavorite() {
    currentPlaying.setFavorite(!currentPlaying.favorite());
    !currentPlaying.favorite() ? _deleteFavorite(currentPlaying) : _addFavorite(currentPlaying);
    setState(() {});
  }

  void _addRecent(LiveStream channel) {
    if (channelsMap[TR_RECENT].contains(channel)) {
      channelsMap[TR_RECENT].sort((b, a) => a.recentTime().compareTo(b.recentTime()));
    } else {
      channelsMap[TR_RECENT].insert(0, channel);
    }
    setState(() {});
  }

  void _deleteChannel(LiveStream channel) {
    final _category = channel.group();
    widget.channels.remove(channel);
    if (widget.channels.isNotEmpty) {
      channelsMap[TR_ALL].remove(channel);
      if (channelsMap[TR_RECENT].contains(channel)) {
        channelsMap[TR_RECENT].remove(channel);
      }
      if (channelsMap[TR_FAVORITE].contains(channel)) {
        channelsMap[TR_FAVORITE].remove(channel);
      }
      if (channelsMap.containsKey(_category)) {
        channelsMap[_category].remove(channel);
        if (channelsMap[_category].isEmpty) {
          channelsMap.remove(_category);
          _categories.remove(_category);
          currentCategory = 2;
        }
      }
      _playChannel(0);
    } else {
      channelsMap.clear();
      final listEvents = locator<StreamListEvent>();
      listEvents.publish(StreamsListEmptyEvent());
    }
    setState(() {});
  }

  void _editChannel(LiveStream channel) async {
    final epgUrl = channel.epgUrl();
    LiveStream response =
        await Navigator.of(context).push(MaterialPageRoute(builder: (context) => LiveEditPageTV(channel)));
    _parseChannels();
    if (response.epgUrl() != epgUrl) {
      channel.setRequested(false);
      programsBloc = ProgramsBloc(channel);
    }
    if (mounted) {
      setState(() {});
    }
  }

  bool _onCategory(FocusNode node, RawKeyEvent event) {
    if (event is RawKeyDownEvent && event.data is RawKeyEventDataAndroid) {
      if (node.hasFocus || node.hasPrimaryFocus) {
        RawKeyDownEvent rawKeyDownEvent = event;
        RawKeyEventDataAndroid rawKeyEventDataAndroid = rawKeyDownEvent.data;
        switch (rawKeyEventDataAndroid.keyCode) {
          case BACK:
          case BACKSPACE:
          case KEY_UP:
            FocusScope.of(context).focusInDirection(TraversalDirection.up);
            break;

          case ENTER:
          case KEY_CENTER:
          case KEY_DOWN:
            FocusScope.of(context).focusInDirection(TraversalDirection.down);
            break;

          case KEY_RIGHT:
            _nextCategory();
            break;
          case KEY_LEFT:
            _prevCategory();
            break;

          default:
            break;
        }
        setState(() {});
      }
    }
    return node.hasFocus;
  }

  bool _onPlayer(FocusNode node, RawKeyEvent event) {
    if (event is RawKeyDownEvent && event.data is RawKeyEventDataAndroid) {
      if (node.hasFocus || node.hasPrimaryFocus) {
        RawKeyDownEvent rawKeyDownEvent = event;
        RawKeyEventDataAndroid rawKeyEventDataAndroid = rawKeyDownEvent.data;
        switch (rawKeyEventDataAndroid.keyCode) {

          /// Opens fullscreen player
          case ENTER:
          case KEY_CENTER:
          case PAUSE:
            if (notFullScreen) {
              setFullscreenOff(false);
              _showSnackBar(true);
            } else {
              if (_playerPage.isPlaying()) {
                _playerPage.pause();
                _showSnackBar(!_isSnackbarActive);
              } else {
                _playerPage.play();
                _showSnackBar(!_isSnackbarActive);
              }
            }
            break;

          case BACK:
          case BACKSPACE:
            if (!notFullScreen) {
              setFullscreenOff(true);
              _showSnackBar(false);
            }
            break;

          case KEY_LEFT:
          case PREVIOUS:
            if (!notFullScreen) {
              _playPrev();
              sendRecent();
              final channel = _getCurrentChannel();
              _addRecent(channel);
            } else {
              FocusScope.of(context).focusInDirection(TraversalDirection.left);
            }
            break;

          case KEY_RIGHT:
          case NEXT:
            if (!notFullScreen) {
              _playNext();
              sendRecent();
              final channel = _getCurrentChannel();
              _addRecent(channel);
            } else {
              FocusScope.of(context).focusInDirection(TraversalDirection.right);
            }
            break;

          case MENU:
            if (!notFullScreen) {
              _showSnackBar(!_isSnackbarActive);
            }
            break;

          case KEY_DOWN:
            FocusScope.of(context).focusInDirection(TraversalDirection.down);
            break;

          case KEY_UP:
            if (notFullScreen) {
              FocusScope.of(context).focusInDirection(TraversalDirection.up);
            }
            break;

          default:
            break;
        }
        setState(() {});
      }
    }
    return node.hasFocus;
  }

  void setFullscreenOff(bool visibility) {
    notFullScreen = visibility;
    TvChannelNotification(title: NotificationType.FULLSCREEN, visibility: notFullScreen)..dispatch(context);
    final settings = locator<LocalStorageService>();
    if (notFullScreen) {
      settings.setLastChannel(null);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _channelsController.jumpToPosition(currentChannel);
      });
    } else {
      final channel = _getCurrentChannel();
      sendRecent();
      _addRecent(channel);
      settings.setLastChannel(channel.id());
    }
  }

  void initProgramsBloc() {
    final channel = _getCurrentChannel();
    programsBloc = ProgramsBloc(channel);
  }
}

class _ChannelsList extends StatelessWidget {
  final List<LiveStream> channels;
  final ScrollController scrollController;
  final Size size;
  final double itemHeight;
  final void Function(int index) onTap;

  _ChannelsList({this.channels, this.scrollController, this.itemHeight, this.size, this.onTap});

  Widget _channelAvatar(LiveStream channel) => PreviewIcon.live(channel.icon(), height: 40, width: 40);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: size.width,
        height: size.height,
        child: ListView.builder(
            controller: scrollController,
            itemCount: channels.length,
            itemExtent: itemHeight,
            itemBuilder: (context, index) {
              final channel = channels[index];
              return Center(
                  child: ListTile(
                      onTap: () => onTap(index),
                      leading: _channelAvatar(channel),
                      title: Text(AppLocalizations.toUtf8(channel.displayName()),
                          style: TextStyle(fontSize: itemHeight / 4), maxLines: 2, overflow: TextOverflow.ellipsis)));
            }));
  }
}

class _Categories extends StatefulWidget {
  final String category;
  final Size size;
  final bool Function(FocusNode node, RawKeyEvent event) onKey;

  _Categories({this.category, this.size, this.onKey});

  @override
  _CategoriesState createState() => _CategoriesState();
}

class _CategoriesState extends State<_Categories> {
  FocusNode _node = FocusNode();
  Color _color = CustomColor().tvUnselectedColor();

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    super.dispose();
    _node.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
        focusNode: _node,
        onKey: (event, node) => widget.onKey(event, node),
        child: Container(
            width: widget.size.width,
            height: widget.size.height,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
              Icon(Icons.keyboard_arrow_left, color: _color),
              Text(_title(widget.category)),
              Icon(Icons.keyboard_arrow_right, color: _color)
            ])));
  }

  void _onFocusChange() {
    setState(() {
      if (_node.hasFocus) {
        _color = CustomColor().tvSelectedColor();
      } else {
        _color = CustomColor().tvUnselectedColor();
      }
    });
  }

  String _title(String title) {
    if (title == TR_ALL || title == TR_RECENT || title == TR_FAVORITE) {
      return AppLocalizations.of(context).translate(title);
    }
    return AppLocalizations.toUtf8(title);
  }
}

class _TimeLine extends StatelessWidget {
  final ProgramsBloc programsBloc;
  final Size size;

  _TimeLine(this.programsBloc, this.size);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProgrammeInfo>(
        stream: programsBloc.currentProgram,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || snapshot.data == null) {
            return SizedBox();
          }
          return Container(
              width: size.width,
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                LiveTime.current(programmeInfo: snapshot.data),
                LiveTimeLine(
                    programmeInfo: snapshot.data,
                    width: size.width / 1.5,
                    height: 6,
                    color: CustomColor().tvSelectedColor()),
                LiveTime.end(programmeInfo: snapshot.data)
              ]));
        });
  }
}

class _ProgramName extends StatelessWidget {
  final ProgramsBloc programsBloc;
  final Size size;
  final double textSize;

  _ProgramName(this.programsBloc, this.size, this.textSize);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProgrammeInfo>(
        stream: programsBloc.currentProgram,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || snapshot.data == null) {
            return SizedBox();
          }
          return Container(
              height: size.height,
              width: size.width,
              child: Text(AppLocalizations.toUtf8(snapshot.data?.title ?? ''),
                  overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: textSize)));
        });
  }
}

class _ProgramTitle extends StatelessWidget {
  final ProgramsBloc programsBloc;

  _ProgramTitle(this.programsBloc);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProgrammeInfo>(
        stream: programsBloc.currentProgram,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || snapshot.data == null) {
            return SizedBox();
          }
          return Text(AppLocalizations.of(context).translate(TR_NOW_PLAYING));
        });
  }
}

class _Programs extends StatelessWidget {
  final ProgramsBloc programsBloc;
  final Size size;
  final double itemHeight;

  _Programs(this.itemHeight, this.size, this.programsBloc);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: size.width,
        height: size.height,
        child: ProgramsListView(
            itemHeight: itemHeight,
            programsBloc: programsBloc,
            textColor: CustomColor().themeBrightnessColor(context)));
  }
}

class _TvPlayerWrap extends StatefulWidget {
  final Widget child;
  final Size availableSpace;
  final bool fullscreen;
  final bool Function(FocusNode node, RawKeyEvent event) onKey;

  _TvPlayerWrap(this.child, this.availableSpace, this.fullscreen, this.onKey);

  @override
  _TvPlayerWrapState createState() => _TvPlayerWrapState();
}

class _TvPlayerWrapState extends State<_TvPlayerWrap> {
  FocusNode _node = FocusNode();
  Color _color = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    super.dispose();
    _node.dispose();
  }

  @override
  void didUpdateWidget(_TvPlayerWrap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setColor();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: !widget.fullscreen ? widget.availableSpace.height / 2 : widget.availableSpace.height,
        decoration: BoxDecoration(color: Colors.black, border: Border.all(color: _color, width: 2)),
        child: Focus(onKey: widget.onKey, focusNode: _node, child: widget.child));
  }

  void _onFocusChange() {
    _setColor();
  }

  void _setColor() {
    setState(() {
      if (widget.fullscreen || !_node.hasFocus) {
        _color = Colors.transparent;
      } else {
        _color = CustomColor().tvSelectedColor();
      }
    });
  }
}

class _NoChannels extends StatelessWidget {
  final int type;
  final Size size;

  _NoChannels.favorite(this.size) : type = 0;

  _NoChannels.recent(this.size) : type = 1;

  @override
  Widget build(BuildContext context) {
    return Container(
        height: size.height,
        width: size.width,
        child: Center(
            child: NonAvailableBuffer(
                iconSize: 48,
                icon: type == 0 ? Icons.favorite_border : Icons.replay,
                message: AppLocalizations.of(context).translate(_type()))));
  }

  String _type() {
    if (type == 0) {
      return TR_FAVORITE_LIVE;
    } else {
      return TR_RECENT_LIVE;
    }
  }
}
