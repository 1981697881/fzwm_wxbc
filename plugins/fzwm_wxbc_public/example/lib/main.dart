import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:fzwm_wxbc_public/fzwm_wxbc_public.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String arouseAbcResult = '无数据';
  @override
  void initState() {
    super.initState();
  }

  Future<void> testPlugin() async {
    String result = '';
    result = (await FzwmWxbcPublic.arouseAbc({"content": "POST\n%2Fgalaxyapi%2FKingdee.BOS.WebApi.ServicesStub.DynamicFormService.ExecuteBillQuery.common.kdsvc\n\nx-api-nonce:1710238510689\nx-api-timestamp:1710238510689\n","key": "38cbc7aa5fe9c9d3564c13b0a2e1acab"}));
    setState(() {
      arouseAbcResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: InkWell(
            child: Text('Running on: $arouseAbcResult'),
            onTap: (){
              testPlugin();
            },
          ),
        ),
      ),
    );
  }
}

