/*
 * This file is part of the Kosmos Client (https://github.com/lolocomotive/kosmos_client)
 *
 * Copyright (C) 2022 lolocomotive
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';
import 'package:kosmos_client/kdecole-api/client.dart';
import 'package:kosmos_client/screens/timetable.dart';
import 'package:kosmos_client/widgets/user_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../kdecole-api/database_manager.dart';
import '../main.dart';
import 'home.dart';
import 'messages.dart';

class Main extends StatefulWidget {
  const Main({Key? key}) : super(key: key);

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
    DatabaseManager.fetchMessageData();
  }

  _updateNews() {
    DatabaseManager.fetchNewsData();
  }

  _updateTimetable() {
    DatabaseManager.fetchTimetable();
  }

  _closeDB() {
    Global.db!.close();
  }

  _clearDatabase() {
    Global.db!.delete('NewsArticles');
    Global.db!.delete('NewsAttachments');
    Global.db!.delete('Conversations');
    Global.db!.delete('Messages');
    Global.db!.delete('MessageAttachments');
    Global.db!.delete('Grades');
    Global.db!.delete('Lessons');
    Global.db!.delete('Exercises');
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
