import 'package:flutter/material.dart';

class TextWidget extends StatefulWidget {
  TextWidget(Key key, this.text) : super(key: key);
  String text;
  @override
  TextWidgetState createState() => TextWidgetState();


}

class TextWidgetState extends State<TextWidget> {
  String _text = '';
  @override
  Widget build(BuildContext context) {
    if(_text == ''){
      _text = widget.text;
    }
    return Container(
      child: Text(_text),
    );
  }

  void onPressed(String count) {
    setState(() {
      _text = widget.text+''+count.toString();
      print(_text);
    });
  }
}
