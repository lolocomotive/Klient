import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kosmos_client/screens/debug.dart';
import 'package:kosmos_client/screens/login.dart';
import 'package:kosmos_client/screens/messages.dart';
import 'package:kosmos_client/screens/settings.dart';
import 'package:kosmos_client/screens/setup.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'global.dart';
import 'kdecole-api/client.dart';
import 'screens/multiview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbDir = await getTemporaryDirectory();
  final dbPath = dbDir.path + '/kdecole.db';
  //await deleteDatabase(dbPath);
  stdout.writeln('Database URL: ' + dbPath);
  Global.storage = const FlutterSecureStorage();
  try {
    Global.token = await Global.storage!.read(key: 'token');
  } on PlatformException catch (_) {
    // Workaround for https://github.com/mogol/flutter_secure_storage/issues/43
    await Global.storage!.deleteAll();
    Global.token = '';
  }
  Global.db = await openDatabase(dbPath);
  final queryResult = await Global.db!.query('sqlite_master');
  final tables = [
    'NewsArticles',
    'NewsAttachments',
    'Conversations',
    'Messages',
    'MessageAttachments',
    'Grades',
    'Lessons',
    'Exercises',
  ];
  for (final el in queryResult) {
    if (tables.contains(el['name'])) {
      tables.remove(el['name']);
    }
  }
  if (tables.isNotEmpty) {
    await deleteDatabase(dbPath);
    Global.db = await openDatabase(dbPath);

    stdout.writeln('Initializing database');
    await Global.db!.execute('''
    CREATE TABLE IF NOT EXISTS NewsArticles(
      ID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      UID TEXT UNIQUE NOT NULL,
      Type TEXT NOT NULL,
      Author TEXT NOT NULL,
      Title TEXT NOT NULL,
      PublishingDate INTEGER NOT NULL,
      HTMLContent TEXT NOT NULL,
      URL TEXT NOT NULL
    );''');

    await Global.db!.execute('''
    CREATE TABLE IF NOT EXISTS NewsAttachments(
      ID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      parentUID TEXT NOT NULL,
      Name TEXT NOT NULL,
      foreign KEY(parentUID) REFERENCES NewsArticles(UID)
    );''');
    await Global.db!.execute('''
    CREATE TABLE IF NOT EXISTS Conversations(
      ID INTEGER PRIMARY KEY NOT NULL,
      Subject TEXT NOT NULL,
      Preview TEXT NOT NULL,
      HasAttachment BOOLEAN NOT NULL,
      Read BOOLEAN NOT NULL,
      LastDate INTEGER NOT NULL,
      LastAuthor STRING NOT NULL,
      FirstAuthor STRING NOT NULL,
      FullMessageContents STRING NOT NULL
    );''');
    await Global.db!.execute('''
    CREATE TABLE IF NOT EXISTS Messages(
      ID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      ParentID INTEGER NOT NULL,
      HTMLContent TEXT NOT NULL,
      Author TEXT NOT NULL,
      DateSent INT NOT NULL,
      FOREIGN KEY (ParentID) REFERENCES Conversations(ID)
    );''');
    await Global.db!.execute('''
    CREATE TABLE IF NOT EXISTS MessageAttachments(
      ID INTEGER PRIMARY KEY NOT NULL,
      ParentID INTEGER NOT NULL,
      URL TEXT,
      Name TEXT NOT NULL,
      FOREIGN KEY (ParentID) references Messages(ID)
    );''');
    await Global.db!.execute('''
    CREATE TABLE IF NOT EXISTS Grades(
      ID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      Subject TEXT NOT NULL,
      Grade REAL NOT NULL,
      Of REAL NOT NULL,
      Date INT NOT NULL
    );''');
    await Global.db!.execute('''
    CREATE TABLE IF NOT EXISTS Lessons(
      ID INTEGER PRIMARY KEY NOT NULL,
      LessonDate INTEGER NOT NULL,
      StartTime TEXT NOT NULL,
      EndTime TEXT NOT NULL,
      Room TEXT NOT NULL,
      Subject TEXT NOT NULL,
      Title TEXT NOT NULL,
      IsModified BOOLEAN NOT NULL,
      ModificationMessage TEXT
    );''');
    await Global.db!.execute('''
    CREATE TABLE IF NOT EXISTS Exercises(
      ID INTEGER PRIMARY KEY NOT NULL,
      ParentLesson INTEGER,
      LessonFor INTEGER,
      Type TEXT NOT NULL,
      DateFor INTEGER,
      ParentDate INTEGER NOT NULL,
      Title TEXT NOT NULL,
      HTMLContent TEXT NOT NULL,
      Done BOOLEAN NOT NULL,
      FOREIGN KEY (ParentLesson) REFERENCES Lessons(ID),
      FOREIGN KEY (LessonFor) REFERENCES Lessons(ID)
    );''');
    await Global.db!.execute('''
    CREATE TABLE IF NOT EXISTS ExerciseAttachments(
      ID INTEGER PRIMARY KEY NOT NULL,
      ParentID INTEGER NOT NULL,
      URL TEXT,
      Name TEXT NOT NULL,
      FOREIGN KEY (ParentID) references Exercises(ID)
    );''');
    stdout.writeln('Done creating tables');
  }
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

class RestartWidget extends StatefulWidget {
  RestartWidget({required this.child});

  final Widget child;

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()!.restartApp();
  }

  @override
  _RestartWidgetState createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key key = UniqueKey();

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: key,
      child: widget.child,
    );
  }
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
  final _loginFormKey = GlobalKey<FormState>();
  final _unameController = TextEditingController();
  final _pwdController = TextEditingController();
  Widget? _mainWidget;

  KosmosState() {
    _mainWidget = const Main();
    if (Global.token == null || Global.token == '') {
      _mainWidget = const Login();
    } else {
      stdout.writeln("Token:" + Global.token!);
      Global.client = Client(Global.token!);
    }
  }

  _login() async {
    if (_loginFormKey.currentState!.validate()) {
      try {
        Global.client =
            await Client.login(_unameController.text, _pwdController.text);
        setState(() {
          _mainWidget = const Main();
        });
      } catch (e) {
        _messengerKey.currentState!.showSnackBar(
            const SnackBar(content: Text('Mauvais identifiant/mot de passe')));
      }
    }
  }

  @override
  void dispose() {
    _unameController.dispose();
    _pwdController.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {}
  }

  @override
  Widget build(BuildContext context) {
    Global.theme = ThemeData(
      colorScheme: const ColorScheme.light().copyWith(
        primary: Colors.teal.shade100,
        onPrimary: Colors.black,
        secondary: Colors.deepPurple,
        surface: Colors.white,
        background: const Color.fromARGB(255, 245, 245, 245),
        onTertiary: Colors.black45,
      ),
      /*  const ColorScheme.dark().copyWith(
          onTertiary: Colors.white54,
          primary: Colors.teal.shade900,
        ), */
      useMaterial3: true,
    );
    return RestartWidget(
      child: MaterialApp(
        scaffoldMessengerKey: _messengerKey,
        navigatorKey: Global.navigatorKey,
        title: title,
        theme: Global.theme!,
        home: _mainWidget,
      ),
    );
  }
}
