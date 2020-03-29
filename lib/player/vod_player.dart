import 'package:fastotvlite/channels/vod_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fastotv_common/player/player.dart';
import 'package:video_player/video_player.dart';

class LiteVodPlayer<T extends StatefulWidget> extends LitePlayer<T> {
  VodStream channel;

  LiteVodPlayer(this.channel);

  String currentUrl() => channel.primaryUrl();

  @override
  void onPlaying(dynamic userData) {}

  @override
  void seekToInterrupt() {
    seekTo(Duration(milliseconds: channel.interruptTime()));
  }

  @override
  void initState() {
    super.initState();
  }

  void playChannel(VodStream chan) {
    channel = chan;
    playLink(currentUrl(), chan);
  }
}

class VodPlayerPage extends StatefulWidget {
  final LiteVodPlayer<VodPlayerPage> _player;

  VodPlayerPage({
    Key key,
    VodStream channel,
  })  : _player = LiteVodPlayer<VodPlayerPage>(channel),
        super(key: key);

  void playChannel(VodStream channel) {
    _player.playChannel(channel);
  }

  void play() {
    _player.play();
  }

  void pause() {
    _player.pause();
  }

  void seekTo(Duration duration) {
    _player.seekTo(duration);
  }

  void seekForward(Duration duration) {
    _player.seekForward(duration);
  }

  void seekBackward(Duration duration) {
    _player.seekBackward(duration);
  }

  VideoPlayerController controller() => _player.controller();

  Duration position() => _player.position();

  bool isPlaying() => _player.isPlaying();

  int interruptTime() => _player.position().inMilliseconds;

  @override
  LiteVodPlayer<VodPlayerPage> createState() => _player;
}

class LiteTrailerPlayer<T extends StatefulWidget> extends LitePlayer<T> {
  final String link;

  LiteTrailerPlayer(this.link);

  String currentUrl() => this.link;

  @override
  void onPlaying(dynamic userData) {}

  @override
  void initState() {
    super.initState();
  }
}

class TrailerPlayerPage extends StatefulWidget {
  final LiteTrailerPlayer<TrailerPlayerPage> _player;

  TrailerPlayerPage(String link) : _player = LiteTrailerPlayer<TrailerPlayerPage>(link);

  void play() {
    _player.play();
  }

  void pause() {
    _player.pause();
  }

  void seekTo(Duration duration) {
    _player.seekTo(duration);
  }

  void seekForward(Duration duration) {
    _player.seekForward(duration);
  }

  void seekBackward(Duration duration) {
    _player.seekBackward(duration);
  }

  VideoPlayerController controller() => _player.controller();

  Duration position() => _player.position();

  bool isPlaying() => _player.isPlaying();

  int interruptTime() => _player.position().inMilliseconds;

  @override
  LiteTrailerPlayer<TrailerPlayerPage> createState() => _player;
}
