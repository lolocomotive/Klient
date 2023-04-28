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

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsProvider {
  static FlutterLocalNotificationsPlugin? _notifications;
  static Future<void> initNotifications() async {
    _notifications = FlutterLocalNotificationsPlugin();
    await _notifications!.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_name'),
        linux: LinuxInitializationSettings(defaultActionName: 'Klient'),
      ),
      onDidReceiveNotificationResponse: notificationCallback,
    );
  }

  static void notificationCallback(NotificationResponse? response) {
    final payload = response?.payload;
    if (payload == null) return;
    if (payload.startsWith('conv-')) {
      /* TODO rewrite this 
      final id = payload.substring(5, payload.length);
      Conversation.byID(int.parse(id)).then((conv) {
        if (conv == null) return;

        KlientApp.navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (context) {
            return CommunicationPage(
              onDelete: deleteConversation,
              id: int.parse(id),
              subject: conv.subject,
            );
          },
        ));
      }); */
    }
  }

  static Future<FlutterLocalNotificationsPlugin> getNotifications() async {
    if (_notifications != null) return _notifications!;
    await initNotifications();
    return _notifications!;
  }
}
