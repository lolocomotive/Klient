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
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kosmos_client/api/database_manager.dart';
import 'package:kosmos_client/api/demo.dart';
import 'package:kosmos_client/database_provider.dart';
import 'package:kosmos_client/notifications_provider.dart';

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

  _closeDB() async {
    (await DatabaseProvider.getDB()).close();
  }

  _updateGrades() {
    DatabaseManager.fetchGradesData();
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

  void _showNotification() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            ElevatedButton(onPressed: _updateMessages, child: const Text('Update messages')),
            ElevatedButton(onPressed: _updateNews, child: const Text('Update news')),
            ElevatedButton(onPressed: _updateTimetable, child: const Text('Update Timetable')),
            ElevatedButton(onPressed: _updateGrades, child: const Text('Update grades')),
            ElevatedButton(onPressed: _clearDatabase, child: const Text('Clear database')),
            ElevatedButton(onPressed: _closeDB, child: const Text('Close database')),
            ElevatedButton(
                onPressed: () async {
                  (await DatabaseProvider.getDB()).execute('DROP TABLE GRADES');
                },
                child: const Text('drop grades')),
            ElevatedButton(onPressed: _showNotification, child: const Text('Force notification')),
            const ElevatedButton(onPressed: generate, child: Text('Force generate')),
          ],
        ),
      ),
    );
  }
}
