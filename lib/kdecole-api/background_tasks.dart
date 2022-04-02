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

import 'package:background_fetch/background_fetch.dart';
import 'package:kosmos_client/global.dart';
import 'package:kosmos_client/kdecole-api/client.dart';
import 'package:kosmos_client/kdecole-api/database_manager.dart';

void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    // This task has exceeded its allowed running-time.
    // You must stop what you're doing and immediately .finish(taskId)
    print('[BackgroundFetch] Headless task timed-out: $taskId');

    BackgroundFetch.finish(taskId);
    return;
  }
  try {
    print('Setting up shared preferences');
    await Global.readPrefs();
    print('Setting up database');
    await Global.initDB();
    String? token = await Global.storage!.read(key: 'token');
    if (token != null) {
      print('Logging in');
      Global.client = Client(token);
      print('Fetching data');
      await DatabaseManager.downloadAll();
    }
  } catch (_) {
    print(_.toString());
  } finally {
    BackgroundFetch.finish(taskId);
  }
}

registerTasks() {
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

Future<void> initPlatformState() async {
  // Configure BackgroundFetch.
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
        requiredNetworkType: NetworkType.NONE,
      ), (String taskId) async {
    // <-- Event handler
    // This is the fetch-event callback.
    print('[BackgroundFetch feur] Event received $taskId');

    // IMPORTANT:  You must signal completion of your task or the OS can^ punish your app
    // for taking too long in the background.
    await DatabaseManager.downloadAll();
    BackgroundFetch.finish(taskId);
  }, (String taskId) async {
    // <-- Task timeout handler.
    // This task has exceeded its allowed running-time.  You must stop what you're doing and immediately .finish(taskId)
    print('[BackgroundFetch] TASK TIMEOUT taskId: $taskId');
    BackgroundFetch.finish(taskId);
  });
  print('[BackgroundFetch] configure success: $status');

  // If the widget was removed from the tree while the asynchronous platform
  // message was in flight, we want to discard the reply rather than calling
  // setState to update our non-existent appearance.
}
