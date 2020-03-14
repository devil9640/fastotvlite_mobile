import 'package:flutter/material.dart';

import 'package:fastotv_common/player/player.dart';

import 'package:fastotvlite/channels/live_stream.dart';

class LiteStreamPlayer<T extends StatefulWidget> extends LitePlayer<T> {
  LiveStream channel;

  LiteStreamPlayer(this.channel);

  String currentUrl() => channel.primaryUrl();

  @override
  void onPlaying(dynamic userData) {}

  @override
  void initState() {
    super.initState();
  }

  void playChannel(LiveStream chan) {
    channel = chan;
    playLink(currentUrl(), chan);
  }
}

class StreamPlayerPage extends StatefulWidget {
  final LiteStreamPlayer<StreamPlayerPage> _player;

  StreamPlayerPage({
    LiveStream channel,
  }) : _player = LiteStreamPlayer<StreamPlayerPage>(channel);

  void playChannel(LiveStream channel) {
    _player.playChannel(channel);
  }

  void play() {
    _player.play();
  }

  void pause() {
    _player.pause();
  }

  bool isPlaying() => _player.isPlaying();

  int interruptTime() => _player.position().inMilliseconds;

  @override
  LiteStreamPlayer<StreamPlayerPage> createState() => _player;
}
