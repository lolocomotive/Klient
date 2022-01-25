import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kosmos_client/screens/messages.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'kdecole-api/client.dart';
import 'screens/multiview.dart';

class Global {
  static FlutterSecureStorage? storage;
  static Database? db;
  static String? token;
  static Client? client;
  static int? currentConversation;
  static String? currentConversationSubject;
  static MessagesState? messagesState;
  static bool loadingMessages = false;
  static String? searchQuery;
  static MessageSearchResultsState? messageSearchSuggestionState;

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
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return date.hour.toString() +
          ':' +
          date.second.toString().padLeft(2, '0');
    } else if (date.year == now.year) {
      return date.day.toString() + ' ' + monthToString(date.month);
    } else {
      return date.day.toString() +
          '/' +
          date.month.toString() +
          '/' +
          date.year.toString();
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbDir = await getTemporaryDirectory();
  final dbPath = dbDir.path + '/kdecole.db';
  //await deleteDatabase(dbPath);
  stdout.writeln('Database URL: ' + dbPath);
  Global.storage = const FlutterSecureStorage();
  Global.token = await Global.storage!.read(key: 'token');
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
      Prof TEXT NOT NULL,
      Grade TEXT NOT NULL,
      Description TEXT NOT NULL
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
      ParentLesson INTEGER NOT NULL,
      LessonFor INTEGER,
      Type TEXT NOT NULL,
      DateFor INTEGER,
      ParentDate INTEGER NOT NULL,
      Title TEXT NOT NULL,
      HTMLContent TEXT NOT NULL,
      Done BOOLEAN NOT NULL,
      foreign KEY (ParentLesson) REFERENCES Lessons(ID),
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
  runApp(KosmosApp());
}

class KosmosApp extends StatefulWidget {
  const KosmosApp({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return KosmosState();
  }
}

class KosmosState extends State {
  final title = 'Kosmos client';
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  final _loginFormKey = GlobalKey<FormState>();
  final _unameController = TextEditingController();
  final _pwdController = TextEditingController();
  Widget? _mainWidget;

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
  Widget build(BuildContext context) {
    _mainWidget = const Main();
    if (Global.token == null || Global.token == '') {
      _mainWidget = loginScreen();
    } else {
      stdout.writeln("Token:" + Global.token!);
      Global.client = Client(Global.token!);
    }

    return MaterialApp(
      scaffoldMessengerKey: _messengerKey,
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: _mainWidget,
    );
  }

  Widget loginScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Container(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _loginFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _unameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom d\'utilisateur';
                  }
                  return null;
                },
                enableSuggestions: false,
                autocorrect: false,
                autofocus: true,
              ),
              TextFormField(
                controller: _pwdController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un mot de passe';
                  }
                  return null;
                },
                enableSuggestions: false,
                autocorrect: false,
                obscureText: true,
              ),
              ElevatedButton(
                  onPressed: _login, child: const Text('Se connecter'))
            ],
          ),
        ),
      ),
    );
  }
}
