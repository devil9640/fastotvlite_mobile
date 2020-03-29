import 'package:fastotvlite/channels/live_stream.dart';
import 'package:fastotvlite/localization/app_localizations.dart';
import 'package:fastotvlite/localization/translations.dart';
import 'package:fastotvlite/mobile/add_streams/edit_channel_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fastotv_common/base/controls/preview_icon.dart';

abstract class _AbstractLiveEditPage extends StatefulWidget {
  final LiveStream stream;

  _AbstractLiveEditPage(this.stream);
}

abstract class _AbstractLiveEditPageState extends EditStreamPageState<_AbstractLiveEditPage> {
  TextEditingController descriptionController;
  TextEditingController nameController;
  TextEditingController iconController;
  TextEditingController videoLinkController;
  TextEditingController idController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: AppLocalizations.toUtf8(widget.stream.displayName()));
    iconController = TextEditingController(text: widget.stream.icon());
    videoLinkController = TextEditingController(text: widget.stream.primaryUrl());
    idController = TextEditingController(text: widget.stream.id());
    validator = videoLinkController.text.isNotEmpty;
  }

  String appBarTitle() => translate(TR_EDIT_STREAM);

  LiveStream stream() => widget.stream;

  void onSave() {
    widget.stream.setDisplayName(nameController.text);
    widget.stream.setPrimaryUrl(videoLinkController.text);
    widget.stream.setIcon(iconController.text);
    widget.stream.setIarc(int.tryParse(iarcController.text) ?? 21);
    widget.stream.setId(idController.text);
  }

  Widget editingPage() {
    return Column(children: <Widget>[
      Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.shortestSide, maxHeight: MediaQuery.of(context).size.shortestSide),
          child: PreviewIcon.live(iconController.text)),
      textField(translate(TR_EDIT_TITLE), nameController),
      textField(translate(TR_EDIT_GROUP), groupController),
      textField(translate(TR_EDIT_VIDEO_LINK), videoLinkController,
          onSubmitted: () => setState(() => validator = videoLinkController.text.isNotEmpty)),
      textField(translate(TR_EDIT_ICON), iconController, onSubmitted: () => setState(() {})),
      textField('IARC', iarcController),
      textField(translate(TR_EPG_PROVIDER), idController),
    ]);
  }

  String translate(String key) => AppLocalizations.of(context).translate(key);
}

class LiveAddPage extends _AbstractLiveEditPage {
  LiveAddPage(stream) : super(stream);

  @override
  _LiveAddPageState createState() => _LiveAddPageState();
}

class _LiveAddPageState extends _AbstractLiveEditPageState {
  @override
  String appBarTitle() => translate(TR_ADD_CHANNEL);

  @override
  Widget deleteButton() => SizedBox();
}

class LiveEditPage extends _AbstractLiveEditPage {
  LiveEditPage(stream) : super(stream);

  @override
  _LiveEditPageState createState() => _LiveEditPageState();
}

class _LiveEditPageState extends _AbstractLiveEditPageState {}
