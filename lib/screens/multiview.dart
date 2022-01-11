import 'package:flutter/material.dart';
import 'package:kosmos_client/kdecole-api/client.dart';
import 'package:kosmos_client/screens/timetable.dart';
import 'package:kosmos_client/widgets/user_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../kdecole-api/database_manager.dart';
import 'home.dart';
import 'messages.dart';

class Main extends StatefulWidget {
  final Database _db;
  final SharedPreferences _prefs;
  late Client _client;

  Main(this._db, this._prefs, {Key? key}) : super(key: key) {
    _client = Client(_prefs.getString('token') as String, _prefs);
  }

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  static const _homeLabel = 'Accueuil';
  static const _messagesLabel = 'Messagerie';
  static const _timetableLabel = 'Emploi du temps';
  static const _debugLabel = 'Debug';

  String? _currentLabel;
  Widget? _currentWidget;

  _updateMessages() {
    DatabaseManager.fetchMessageData(widget._client, widget._db);
  }

  _updateNews() {
    DatabaseManager.fetchNewsData(widget._client, widget._db);
  }

  _updateTimetable() {
    DatabaseManager.fetchTimetable(widget._client, widget._db);
  }

  _closeDB() {
    widget._db.close();
  }

  _clearDatabase() {
    widget._db.delete('NewsArticles');
    widget._db.delete('NewsAttachments');
    widget._db.delete('Conversations');
    widget._db.delete('Messages');
    widget._db.delete('MessageAttachments');
    widget._db.delete('Grades');
    widget._db.delete('Lessons');
    widget._db.delete('Exercises');
  }

  _changeScreen(String label, BuildContext context) {
    Navigator.pop(context);
    _currentLabel = label;
    switch (label) {
      case _homeLabel:
        setState(() {
          _currentWidget = Home();
        });
        break;
      case _messagesLabel:
        setState(() {
          _currentWidget = Messages();
        });
        break;
      case _timetableLabel:
        setState(() {
          _currentWidget = Timetable();
        });
        break;
      case _debugLabel:
        setState(() {
          _currentWidget = Debug();
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            Container(child: UserInfo()),
            drawerLink(_homeLabel),
            drawerLink(_messagesLabel),
            drawerLink(_timetableLabel),
            drawerLink(_debugLabel),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(_currentLabel ?? 'Accueuil'),
      ),
      body: Container(
          padding: EdgeInsets.all(10.0), child: _currentWidget ?? Home()),
    );
  }

  Widget drawerLink(String label) {
    return ListTile(
      title: Text(label),
      onTap: () => {_changeScreen(label, context)},
    );
  }

  Widget Debug() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
            onPressed: _updateMessages, child: Text('Update messages')),
        ElevatedButton(onPressed: _updateNews, child: Text('Update news')),
        ElevatedButton(
            onPressed: _updateTimetable, child: Text('Update Timetable')),
        ElevatedButton(
            onPressed: _clearDatabase, child: Text('Clear database')),
        ElevatedButton(onPressed: _closeDB, child: Text('Close database')),
      ],
    );
  }
}
