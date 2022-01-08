import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login.dart';
import 'screens/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(KosmosApp(prefs));
}

class KosmosApp extends StatelessWidget {
  KosmosApp(this._prefs, {Key? key}) : super(key: key);
  final title = 'Kosmos client';
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  final SharedPreferences _prefs;
  @override
  Widget build(BuildContext context) {
    Widget mainWidget = Home();
    final token = _prefs.getString('token');
    if(token== null || token == ''){
      mainWidget = Login(_messengerKey);
    }else{
      stdout.writeln("Token:" + _prefs.getString('token')!);
    }

    return MaterialApp(
      scaffoldMessengerKey: _messengerKey,
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: mainWidget,
    );
  }
}
