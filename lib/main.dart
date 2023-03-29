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

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:klient/api/background_tasks.dart';
import 'package:klient/api/client.dart';
import 'package:klient/config_provider.dart';
import 'package:klient/notifications_provider.dart';
import 'package:klient/screens/login.dart';

import 'screens/multiview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('FR_fr');
  await ConfigProvider.load();
  await Client.getCurrentlySelected();

  //Background fetch
  await initPlatformState();
  registerTasks();

  runApp(const KlientApp());
}

_checkNotifications() async {
  var details =
      await (await NotificationsProvider.getNotifications()).getNotificationAppLaunchDetails();
  if (details == null) return;
  if (!details.didNotificationLaunchApp) return;
  if (details.notificationResponse!.payload == null) return;
  NotificationsProvider.notificationCallback(details.notificationResponse);
}

class KlientApp extends StatefulWidget {
  static ThemeData? theme;
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();
  static List<DropdownMenuItem> dropdownItems = [];
  static AppLifecycleState? currentLifecycleState;
  static void Function()? onLogin;

  const KlientApp({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return KlientState();
  }
}

class KlientState extends State with WidgetsBindingObserver {
  final title = 'Klient';

  Widget? _mainWidget;
  static KlientState? currentState;

  @override
  void initState() {
    super.initState();
    _checkNotifications();
    NotificationsProvider.getNotifications().then((notifications) => notifications.cancelAll());

    WidgetsBinding.instance.addObserver(this);
    KlientApp.currentLifecycleState = AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  KlientState() {
    KlientApp.onLogin = () {
      setState(() {
        _mainWidget = const Main();
        KlientApp.currentLifecycleState = AppLifecycleState.resumed;
      });
    };
    _mainWidget = const Main();
    if (ConfigProvider.demo) {
      Client.demo();
      return;
    }
    if (ConfigProvider.token == null || ConfigProvider.token == '') {
      _mainWidget = Login(KlientApp.onLogin!);
    } else {
      Client(ConfigProvider.token!);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {}
    KlientApp.currentLifecycleState = state;
  }

  @override
  void didChangePlatformBrightness() {
    ConfigProvider.setTheme();
    currentState!.setState(() {});
    super.didChangePlatformBrightness();
  }

  @override
  Widget build(BuildContext context) {
    currentState = this;
    return DynamicColorBuilder(builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
      ConfigProvider.lightDynamic = lightDynamic;
      ConfigProvider.darkDynamic = darkDynamic;
      ConfigProvider.setTheme();
      return MaterialApp(
        scaffoldMessengerKey: KlientApp.messengerKey,
        navigatorKey: KlientApp.navigatorKey,
        title: title,
        theme: KlientApp.theme!,
        darkTheme: KlientApp.theme!,
        home: _mainWidget,
      );
    });
  }
}
