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

import 'dart:io';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:kosmos_client/api/client.dart';
import 'package:kosmos_client/api/conversation.dart';
import 'package:kosmos_client/api/downloader.dart';
import 'package:kosmos_client/config_provider.dart';
import 'package:kosmos_client/database_provider.dart';
import 'package:kosmos_client/notifications_provider.dart';

void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  print('Starting headless Task $taskId');
  if (isTimeout) {
    print('[BackgroundFetch] Headless task timed-out: $taskId');
    BackgroundFetch.finish(taskId);
    return;
  }
  try {
    String? token = await ConfigProvider.getStorage().read(key: 'token');
    if (token != null && token != '') {
      print('Logging in');
      Client(token);
      print('Fetching data');
      await Downloader.downloadAll();
      print('Showing notifications');
      await showNotifications();
    }
  } catch (_, st) {
    print(_.toString());
    print(st.toString());
  } finally {
    BackgroundFetch.finish(taskId);
  }
}

registerTasks() {
  if (Platform.isLinux) return;
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

Future<void> initPlatformState() async {
  if (Platform.isLinux) return;
  int status = await BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        enableHeadless: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        forceAlarmManager: false,
        requiredNetworkType: NetworkType.ANY,
      ), (String taskId) async {
    print('[BackgroundFetch] Event #received $taskId');
    await Downloader.downloadAll();
    await showNotifications();
    BackgroundFetch.finish(taskId);
  }, (String taskId) async {
    print('[BackgroundFetch] TASK TIMEOUT taskId: $taskId');
    BackgroundFetch.finish(taskId);
  });
  print('[BackgroundFetch] configure success: $status');
}

Future<void> showNotifications() async {
  if (ConfigProvider.notifMsgEnabled!) {
    const AndroidNotificationDetails msgChannel = AndroidNotificationDetails(
      'channel-msg',
      'channel-msg',
      channelDescription: 'The channel for displaying messages',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails msgDetails = NotificationDetails(android: msgChannel);
    List<Conversation> convs = (await Conversation.fetchAll());

    convs = convs.where((conv) => !conv.read).where((conv) => !conv.notificationShown).toList();
    if (convs.isEmpty) {
      print('Showing no message notifications');
    } else {
      print('Message notifications to show:');
      print(convs.map((e) => e.subject).toList());
    }
    for (var i = 0; i < convs.length; i++) {
      Conversation conv = convs[i];
      (await DatabaseProvider.getDB()).update('Conversations', {'NotificationShown': 1},
          where: 'ID = ?', whereArgs: [conv.id.toString()]);
      await (await NotificationsProvider.getNotifications()).show(
        conv.id,
        '${conv.lastAuthor} - ${conv.subject}',
        HtmlUnescape().convert(conv.preview),
        msgDetails,
        payload: 'conv-${conv.id}',
      );
    }
  } else {
    print('Message notifications disabled');
  }
}
