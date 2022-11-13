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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:kosmos_client/api/client.dart';
import 'package:kosmos_client/config_provider.dart';
import 'package:kosmos_client/database_provider.dart';
import 'package:kosmos_client/main.dart';
import 'package:kosmos_client/screens/about.dart';
import 'package:kosmos_client/screens/debug.dart';
import 'package:kosmos_client/screens/settings.dart';
import 'package:kosmos_client/screens/setup.dart';
import 'package:kosmos_client/widgets/exception_widget.dart';
import 'package:restart_app/restart_app.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class Util {
  static const standardShadow = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 8,
      offset: Offset(0, 4),
    )
  ];

  static void onException(Exception e, StackTrace st) {
    print(e);
    print(st);
    print('Current state: ${KosmosApp.currentState}');
    if (KosmosApp.currentState == AppLifecycleState.resumed) {
      KosmosApp.messengerKey.currentState?.showSnackBar(
        SnackBar(
            content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExceptionWidget(e: e, st: st),
          ],
        )),
      );
    }
  }

  static PopupMenuButton popupMenuButton = PopupMenuButton(
    onSelected: (choice) async {
      switch (choice) {
        case 'Paramètres':
          KosmosApp.navigatorKey.currentState!.push(
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          );
          break;
        case 'Debug':
          KosmosApp.navigatorKey.currentState!.push(
            MaterialPageRoute(builder: (_) => const DebugScreen()),
          );
          break;
        case 'Se déconnecter':
          KosmosApp.navigatorKey.currentState!.push(MaterialPageRoute(builder: (_) {
            return WillPopScope(
              onWillPop: () async => false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [CircularProgressIndicator()],
              ),
            );
          }));
          Client.getClient().clear();
          try {
            await Client.getClient().request(Action.logout);
          } catch (_) {}
          await (await DatabaseProvider.getDB()).close();
          await deleteDatabase((await DatabaseProvider.getDB()).path);
          await ConfigProvider.getStorage().deleteAll();
          await ConfigProvider.load();
          await DatabaseProvider.initDB();
          await Restart.restartApp();
          break;
        case 'Initial setup':
          KosmosApp.navigatorKey.currentState!.push(
            MaterialPageRoute(builder: (_) => SetupPage(() {})),
          );
          break;
        case 'À propos':
          KosmosApp.navigatorKey.currentState!
              .push(MaterialPageRoute(builder: (_) => const AboutPage()));
          break;
      }
    },
    itemBuilder: (context) {
      return [
        PopupMenuItemWithIcon('Paramètres', Icons.settings_outlined, context),
        //PopupMenuItemWithIcon("Aide", Icons.help_outline, context),
        PopupMenuItemWithIcon('À propos', Icons.info_outline, context),
        PopupMenuItemWithIcon('Se déconnecter', Icons.logout_outlined, context),
        if (kDebugMode) PopupMenuItemWithIcon('Debug', Icons.bug_report_outlined, context),
        if (kDebugMode) PopupMenuItemWithIcon('Initial setup', Icons.bug_report_outlined, context),
      ];
    },
  );
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

  static String dateToString(DateTime date) {
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
