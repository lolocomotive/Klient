/*
 * This file is part of the Klient (https://github.com/lolocomotive/klient)
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
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:klient/api/demo.dart';
import 'package:klient/api/downloader.dart';
import 'package:klient/database_provider.dart';
import 'package:klient/notifications_provider.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({Key? key}) : super(key: key);

  _updateMessages() {
    Downloader.fetchMessageData();
  }

  _updateNews() {
    Downloader.fetchNewsData();
  }

  _updateTimetable() {
    Downloader.fetchTimetable();
  }

  _closeDB() async {
    (await DatabaseProvider.getDB()).close();
  }

  _updateGrades() {
    Downloader.fetchGradesData();
  }

  _clearDatabase() async {
    final db = await DatabaseProvider.getDB();
    db.delete('NewsArticles');
    db.delete('NewsAttachments');
    db.delete('Conversations');
    db.delete('Messages');
    db.delete('MessageAttachments');
    db.delete('Grades');
    db.delete('Lessons');
    db.delete('Exercises');
  }

  _showNotification() async {
    const AndroidNotificationDetails lessonChannel = AndroidNotificationDetails(
      'channel-lessons',
      'channel-lessons',
      channelDescription: 'The channel for displaying lesson modifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const AndroidNotificationDetails msgChannel = AndroidNotificationDetails(
      'channel-msg',
      'channel-msg',
      channelDescription: 'The channel for displaying message modifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    final notifications = await NotificationsProvider.getNotifications();
    const NotificationDetails details = NotificationDetails(android: lessonChannel);
    notifications.show(0, 'Example lesson notification', 'This is an example notification', details,
        payload: 'lesson-4232582');
    const NotificationDetails details2 = NotificationDetails(android: msgChannel);

    notifications.show(
        1, 'Example Conversation notification', 'This is an example notification', details2,
        payload: 'conv-135794');
  }

  _sqliteMasterPrint() async {
    final db = await DatabaseProvider.getDB();
    final r = await db.query('sqlite_master');
    for (final table in r) {
      print((table['tbl_name'] as String) + (table['name'] as String));
    }
  }

  _forceMigrate1() async {
    final db = await DatabaseProvider.getDB();

    print('Upgrading to v1');
    await db.execute('''
          CREATE TABLE IF NOT EXISTS Students(
            ID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
            UID TEXT NOT NULL UNIQUE,
            Name TEXT NOT NULL,
            Permissions TEXT NOT NULL
          )''');
    await db.execute('''ALTER TABLE NewsArticles ADD StudentUID TEXT''');
    await db.execute('''ALTER TABLE NewsAttachments ADD StudentUID TEXT''');
    await db.execute('''ALTER TABLE Grades ADD StudentUID TEXT''');
    await db.execute('''ALTER TABLE Lessons ADD StudentUID TEXT''');
    await db.execute('''ALTER TABLE ExercisesADD StudentUID TEXT''');
    await db.execute('''ALTER TABLE ExerciseAttachmentsADD StudentUID TEXT''');
    print('Upgraded to v1');
  }

  _forceM2Step2() async {
    await Downloader.fetchUserInfo();
    final db = await DatabaseProvider.getDB();
    await db.update('NewsArticles', {'StudentUID': '0'});
    await db.update('Lessons', {'StudentUID': '0'});
    await db.update('Exercises', {'StudentUID': '0'});
    await db.update('Lessons', {'StudentUID': '0'});
    print('Upgraded to v2');
  }

  _dropGrades() async {
    (await DatabaseProvider.getDB()).execute('DROP TABLE GRADES');
  }

  _updateHomework() {
    Downloader.fetchHomework();
  }

  _fetchUserInfo() {
    Downloader.fetchUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            ElevatedButton(onPressed: _joinTest, child: const Text('SQL JOIN test')),
            ElevatedButton(onPressed: _updateMessages, child: const Text('Update messages')),
            ElevatedButton(onPressed: _updateNews, child: const Text('Update news')),
            ElevatedButton(onPressed: _updateTimetable, child: const Text('Update Timetable')),
            ElevatedButton(onPressed: _updateHomework, child: const Text('Update Homework')),
            ElevatedButton(onPressed: _updateGrades, child: const Text('Update grades')),
            ElevatedButton(onPressed: _clearDatabase, child: const Text('Clear database')),
            ElevatedButton(onPressed: _closeDB, child: const Text('Close database')),
            ElevatedButton(onPressed: _fetchUserInfo, child: const Text('Fetch user info')),
            ElevatedButton(onPressed: _dropGrades, child: const Text('drop grades')),
            ElevatedButton(onPressed: _showNotification, child: const Text('Force notification')),
            const ElevatedButton(onPressed: generate, child: Text('Force generate')),
            ElevatedButton(onPressed: _forceM2Step2, child: const Text('Force Migrate2 step2')),
            ElevatedButton(onPressed: _forceMigrate1, child: const Text('Force Migrate1')),
            ElevatedButton(onPressed: _sqliteMasterPrint, child: const Text('Sqlite master print')),
          ],
        ),
      ),
    );
  }

  _joinTest() {
    DatabaseProvider.getDB().then((db) => {
          db.rawQuery('''SELECT Lessons.ID as LessonID, Exercises.ID as ExerciseID, * 
          FROM Lessons INNER JOIN Exercises ON Lessons.ID = Exercises.ParentLesson OR Lessons.ID = Exercises.LessonFor
          ORDER BY Lessons.ID;''').then((result) {
            print(result[0]);
          })
        });
  }
}
