import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastUtil{
  static void showInfo(String  str)async {
    Fluttertoast.showToast(
        msg: str,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIos: 3,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }
  //错误信息弹窗
  static void errorDialog(BuildContext context, String str) async {
    showDialog<Widget>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            //可滑动
            backgroundColor: Colors.black54,
            content: SingleChildScrollView(
              child: Text(str,
                  style: TextStyle(
                    fontSize: 15,
                    decoration: TextDecoration.none,
                    // 文字颜色
                    color: Colors.white,
                  )),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('关闭',
                    style: TextStyle(
                      fontSize: 18,
                    )),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        }
    ).then((val) {
      print(val);
    });
  }
}

