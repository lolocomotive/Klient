import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:kosmos_client/kdecole-api/background_tasks.dart';
import 'package:kosmos_client/screens/login.dart';

import 'global.dart';
import 'kdecole-api/client.dart';
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
  PopupMenuItemWithIcon(String label, IconData icon, BuildContext context,
      {Key? key})
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
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

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
          brightness: SchedulerBinding.instance.window.platformBrightness),
      useMaterial3: true,
    );
    return MaterialApp(
      scaffoldMessengerKey: _messengerKey,
      navigatorKey: Global.navigatorKey,
      title: title,
      theme: Global.theme!,
      darkTheme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: _mainWidget,
    );
  }
}
