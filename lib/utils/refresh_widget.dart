import 'package:flutter/material.dart';
/*
 * 封装的局部刷新Widget
 */
typedef BuildWidget = Widget Function();

// ignore: must_be_immutable
class PartRefreshWidget extends StatefulWidget {
  final Key key;
  BuildWidget child;

  // 接收一个Key
  PartRefreshWidget(this.key, this.child);

  @override
  State<StatefulWidget> createState() {
    print("createState");
    return PartRefreshWidgetState(child);
  }
}

class PartRefreshWidgetState extends State<PartRefreshWidget> {
  BuildWidget child;

  PartRefreshWidgetState(this.child);

  @override
  Widget build(BuildContext context) {
    return child.call();
  }

  void update() {
    setState(() {});
  }
}
