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

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:klient/config_provider.dart';
import 'package:klient/main.dart';
import 'package:klient/widgets/exception_widget.dart';
import 'package:openid_client/openid_client.dart';
import 'package:scolengo_api/scolengo_api.dart';

class Util {
  static const standardShadow = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 8,
      offset: Offset(0, 4),
    )
  ];

  static void onException(Exception e, StackTrace st) {
    debugPrint(e.toString());
    debugPrintStack(stackTrace: st);
    debugPrint('Current app lifecycle state: ${KlientApp.currentLifecycleState}');
    if (KlientApp.currentLifecycleState == AppLifecycleState.resumed) {
      KlientApp.messengerKey.currentState?.showSnackBar(
        SnackBar(
            backgroundColor: KlientApp.theme!.colorScheme.surface,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExceptionWidget(e: e, st: st),
              ],
            )),
      );
    }
  }

  static String monthToString(int month) {
    switch (month) {
      case 1:
        return 'Jan.';
      case 2:
        return 'Fév.';
      case 3:
        return 'Mars';
      case 4:
        return 'Avril';
      case 5:
        return 'Mai';
      case 6:
        return 'Juin';
      case 7:
        return 'Juil.';
      case 8:
        return 'Août';
      case 9:
        return 'Sept.';
      case 10:
        return 'Oct.';
      case 11:
        return 'Nov.';
      case 12:
        return 'Déc.';
      default:
        throw Error();
    }
  }

  static String formatDate(String dateString) {
    DateTime date = DateTime.parse(dateString);
    final DateTime now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return '${date.hour}:${date.second.toString().padLeft(2, '0')}';
    } else if (date.year == now.year) {
      return '${date.day} ${monthToString(date.month)}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

extension Date on String {
  DateTime date() {
    return DateTime.parse(this).toLocal();
  }

  // Return a nicely formatted human readable date
  String format() {
    return Util.formatDate(this);
  }

  /// Return a string in the format HH:MM
  String hm() {
    final date = this.date();
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

extension NiceSize on num {
  String niceSize() {
    if (this < 1000) {
      return toString();
    } else if (this < 1000000) {
      return '${(this / 1000).toStringAsFixed(1)}k';
    } else if (this < 1000000000) {
      return '${(this / 1000000).toStringAsFixed(1)}M';
    } else {
      return '${(this / 1000000000).toStringAsFixed(1)}G';
    }
  }
}

extension HtmlUtils on String {
  String get innerText =>
      //First remove all html tags and line breaks
      replaceAll(RegExp(r'^\s+|\r?\n|\r|<.*?>'), '')
          //Then remove extra spaces
          .replaceAll(RegExp(r'\s+'), ' ')
          //Then remove leading space
          .replaceAll(RegExp(r'^\s+'), '');
}

Skolengo createClient() {
  final client = Skolengo.fromCredentials(
    ConfigProvider.credentials!,
    ConfigProvider.school!,
    cacheProvider: KlientApp.cache,
    debug: kDebugMode,
  );
  ConfigProvider.credentials!.onTokenChanged.listen((event) {
    ConfigProvider.getStorage()
        .write(key: 'credentials', value: jsonEncode(ConfigProvider.credentials!.toJson()));
    client.headers['Authorization'] =
        'Bearer ${TokenResponse.fromJson(ConfigProvider.credentials!.response!).accessToken}';
  });
  return client;
}
