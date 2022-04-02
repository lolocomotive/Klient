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
import 'package:kosmos_client/global.dart';
import 'package:kosmos_client/kdecole-api/database_manager.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({Key? key}) : super(key: key);

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

  _updateGrades() {
    DatabaseManager.fetchGradesData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Debug")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
                onPressed: _updateMessages,
                child: const Text('Update messages')),
            ElevatedButton(
                onPressed: _updateNews, child: const Text('Update news')),
            ElevatedButton(
                onPressed: _updateTimetable,
                child: const Text('Update Timetable')),
            ElevatedButton(
                onPressed: _updateGrades, child: const Text('Update grades')),
            ElevatedButton(
                onPressed: _clearDatabase, child: const Text('Clear database')),
            ElevatedButton(
                onPressed: _closeDB, child: const Text('Close database')),
            ElevatedButton(
                onPressed: () {
                  Global.db!.execute('DROP TABLE GRADES');
                },
                child: const Text('drop grades')),
          ],
        ),
      ),
    );
  }
}
