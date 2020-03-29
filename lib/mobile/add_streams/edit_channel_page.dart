import 'package:fastotv_common/colors.dart';
import 'package:fastotvlite/channels/istream.dart';
import 'package:flutter/material.dart';

abstract class EditStreamPageState<T extends StatefulWidget> extends State<T> {
  TextEditingController groupController;
  TextEditingController iarcController;

  bool validator = true;

  void onSave();

  String appBarTitle();

  Widget editingPage();

  IStream stream();

  @override
  void initState() {
    super.initState();
    groupController = TextEditingController(text: stream().group());
    iarcController = TextEditingController(text: stream().iarc().toString());
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final appBarTextColor = CustomColor().backGroundColorBrightness(primaryColor);
    return WillPopScope(
      onWillPop: () async {
        exitAndResetChanges();
      },
      child: Scaffold(
          appBar: AppBar(
              iconTheme: IconThemeData(color: appBarTextColor),
              title: Text(appBarTitle(), style: TextStyle(color: appBarTextColor)),
              leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => exitAndResetChanges()),
              actions: <Widget>[deleteButton()]),
          floatingActionButton: _saveButton(),
          body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(16.0), child: editingPage()))),
    );
  }

  void exitAndResetChanges() => Navigator.of(context).pop(stream());

  Widget _saveButton() {
    final accentColor = Theme.of(context).accentColor;
    return !validator
        ? null
        : FloatingActionButton(
            onPressed: () {
              onSave();
              exitAndResetChanges();
            },
            backgroundColor: accentColor,
            child: Icon(Icons.save, color: CustomColor().backGroundColorBrightness(accentColor)));
  }

  Widget textField(String hintText, TextEditingController controller, {void Function() onSubmitted}) {
    return new TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: hintText),
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.none,
        onFieldSubmitted: (String text) {
          if (onSubmitted != null) {
            onSubmitted();
          }
        });
  }

  Widget deleteButton() {
    return IconButton(icon: Icon(Icons.delete), onPressed: () => Navigator.of(context).pop());
  }
}
