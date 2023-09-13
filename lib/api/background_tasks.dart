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
import 'dart:io';
import 'dart:math';

import 'package:background_fetch/background_fetch.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:klient/api/custom_requests.dart';
import 'package:klient/config_provider.dart';
import 'package:klient/main.dart';
import 'package:klient/notifications_provider.dart';
import 'package:klient/util.dart';
import 'package:scolengo_api/scolengo_api.dart';

void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  print('[Background Task $taskId] Start');
  if (isTimeout) {
    print('[Background Task $taskId] Headless task timed-out: $taskId');
    BackgroundFetch.finish(taskId);
    return;
  }
  process(taskId);
}

process(String taskId) async {
  try {
    if (ConfigProvider.client == null) {
      await ConfigProvider.load();
    }
    if (ConfigProvider.credentials == null) {
      print('[Background Task $taskId] Not logged in, exiting');
      BackgroundFetch.finish(taskId);
      return;
    }
    print('[Background Task $taskId] Checking connectivity...');
    if (await Connectivity().checkConnectivity() == ConnectivityResult.none) {
      print('[Background Task $taskId] No connectivity, exiting');
      BackgroundFetch.finish(taskId);
      return;
    }
    print('[Background Task $taskId] Logging in...');
    KlientApp.cache.forceNetwork = true;
    ConfigProvider.client = createClient();
    await ConfigProvider.client!.getAppCurrentConfig().last;
    print('[Background Task $taskId] Fetching data...');
    await showNotifications();
  } catch (_, st) {
    print(_.toString());
    print(st.toString());
  } finally {
    KlientApp.cache.forceNetwork = false;
    BackgroundFetch.finish(taskId);
  }
}

registerTasks() {
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) return;
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

Future<void> initPlatformState() async {
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) return;
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
    process(taskId);
    BackgroundFetch.finish(taskId);
  }, (String taskId) async {
    print('[Background Task $taskId] TASK TIMEOUT');
    BackgroundFetch.finish(taskId);
  });
  print('[Background Tasks] configure success: $status');
}

Future<void> showNotificationsCategory<T extends BaseResponse>(
    String id, String description, Stream<List<T>> data, NotificationBuilder<T> build) async {
  final channel = AndroidNotificationDetails(
    id,
    id,
    channelDescription: description,
    importance: Importance.max,
    priority: Priority.high,
  );
  final details = NotificationDetails(android: channel);
  print('[Background@showNotifications:$id] Getting cache...');
  final cached = await data.first;
  print('[Background@showNotifications:$id] Getting network...');
  final real = await data.last;
  print('[Background@showNotifications:$id] Comparing cache with network data...');

  for (var i = 0; i < real.length; i++) {
    if (cached.where((element) => element.id == real[i].id).isEmpty) {
      final notification = build(real[i]);
      await (await NotificationsProvider.getNotifications()).show(
        notification.id,
        notification.title,
        notification.body,
        details,
        payload: notification.payload,
      );
    }
  }
}

class Notification {
  final int id;
  final String title;
  final String body;
  final String payload;

  Notification(this.id, this.title, this.body, this.payload);
}

typedef NotificationBuilder<T> = Notification Function(T data);

Future<void> showNotifications() async {
  if (ConfigProvider.notificationSettings![NotificationType.messages] ?? false) {
    print('[Background@showNotifications:messages] Getting settings...');
    final folderId = (await ConfigProvider.client!
            .getUsersMailSettings(ConfigProvider.credentials!.idToken.claims.subject)
            .first)
        .data
        .folders
        .firstWhere((folder) => folder.folderType == FolderType.INBOX)
        .id;

    await showNotificationsCategory<Communication>(
      'messages',
      'The channel for displaying new messages',
      getUnread(folderId).asBroadcastStream(),
      (comm) => Notification(
        int.parse(comm.id),
        '${comm.lastParticipation?.sender?.label ?? comm.lastParticipation?.sender?.person?.fullName ?? 'Auteur inconnu'} - ${comm.subject}',
        comm.lastParticipation?.content.innerText ?? 'Aucun contenu',
        'comm-${comm.id}',
      ),
    );
  } else {
    print('[Background@showNotifications:messages] Message notifications disabled');
  }
  if (ConfigProvider.notificationSettings![NotificationType.evaluations] ?? false) {
    await showNotificationsCategory<Evaluation>(
      'eval',
      'The channel for displaying new evaluations',
      getEvaluations().asBroadcastStream(),
      (eval) => Notification(
        Random().nextInt(1000000),
        'Nouvelle note - ${eval.subject.label}',
        '${eval.result.mark ?? eval.result.nonEvaluationReason}/${eval.scale ?? 20}',
        'eval-${eval.id}',
      ),
    );
  } else {
    print('[Background@showNotifications:eval] Evaluation notifications disabled');
  }
  if (ConfigProvider.notificationSettings![NotificationType.info] ?? false) {
    await showNotificationsCategory<SchoolInfo>(
      'info',
      'The channel for displaying new school infos',
      getSchoolInfos().asBroadcastStream(),
      (info) => Notification(
        Random().nextInt(100000),
        info.title,
        info.content.innerText,
        'eval-${info.id}',
      ),
    );
  } else {
    print('[Background@showNotifications:schoolinfo] Evaluation notifications disabled');
  }
  if (ConfigProvider.notificationSettings![NotificationType.homework] ?? false) {
    await showNotificationsCategory<HomeworkAssignment>(
      'homework',
      'The channel for displaying new homework assignments',
      getHomework().asBroadcastStream(),
      (homework) => Notification(
        Random().nextInt(100000),
        homework.title ?? 'Nouveau travail à faire',
        homework.html.innerText,
        'eval-${homework.id}',
      ),
    );
  } else {
    print('[Background@showNotifications:homework] Evaluation notifications disabled');
  }
}
