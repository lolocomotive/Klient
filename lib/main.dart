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
import 'package:flutter/scheduler.dart';
import 'package:kosmos_client/api/background_tasks.dart';
import 'package:kosmos_client/api/client.dart';
import 'package:kosmos_client/screens/login.dart';

import 'global.dart';
import 'screens/multiview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Global.initNotifications();
  await Global.readPrefs();
  await Global.initDB();
  registerTasks();
  runApp(const KosmosApp());
}

class PopupMenuItemWithIcon extends PopupMenuItem {
  PopupMenuItemWithIcon(String label, IconData icon, BuildContext context, {Key? key})
      : super(
          key: key,
          value: label,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                child: Icon(
                  icon,
                  color: Global.theme!.colorScheme.brightness == Brightness.dark
                      ? Colors.white54
                      : Colors.black54,
                ),
              ),
              Text(label),
            ],
          ),
        );
}

class KosmosApp extends StatefulWidget {
  const KosmosApp({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return KosmosState();
  }
}

class KosmosState extends State with WidgetsBindingObserver {
  final title = 'Kosmos client';

  Widget? _mainWidget;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  KosmosState() {
    Global.onLogin = () {
      setState(() {
        _mainWidget = const Main();
      });
    };
    _mainWidget = const Main();
    if (Global.token == null || Global.token == '') {
      _mainWidget = Login(Global.onLogin!);
    } else {
      Global.client = Client(Global.token!);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {}
  }

  @override
  Widget build(BuildContext context) {
    Global.theme = ThemeData.from(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: SchedulerBinding.instance.window.platformBrightness,
      ),
      useMaterial3: true,
    ).copyWith(
      highlightColor: Colors.deepPurpleAccent.shade100.withAlpha(80),

      //FIXME
      // For now the splash appears green when using deepPurpleAccent as color, which is an error in the flutter SDK that will be fixed soon (https://github.com/flutter/flutter/pull/110552).
      // Using this custom color there is just a workaround while the fix isn't stable yet. Colors.deepPurpleAccent.shade100.withAlpha(80) should be used here

      splashColor: const HSVColor.fromAHSV(1, 80, .3, 1).toColor().withAlpha(80),
    );
    return MaterialApp(
      key: Global.mainKey,
      scaffoldMessengerKey: Global.messengerKey,
      navigatorKey: Global.navigatorKey,
      title: title,
      theme: Global.theme!,
      darkTheme: Global.theme!,
      home: _mainWidget,
    );
  }
}
