import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'kdecole-api/client.dart';
import 'screens/multiview.dart';
class Global{
  static FlutterSecureStorage? storage;
  static Database? db;
  static String? token;
  static Client? client;
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbDir = await getTemporaryDirectory();
  final dbPath = dbDir.path + '/kdecole.db';
  await deleteDatabase(dbPath);
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
    'Exercises'
  ];
  for (final el in queryResult) {
    if (tables.contains(el['name'])) {
      tables.remove(el['name']);
    }
  }
  if (tables.isNotEmpty) {
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
      LastDate INTEGER NOT NULL
    );''');
    await Global.db!.execute('''
    CREATE TABLE IF NOT EXISTS Messages(
      ID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      ParentID INTEGER NOT NULL,
      HTMLContent TEXT NOT NULL,
      Author TEXT NOT NULL,
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
        Global.client = await Client.login(_unameController.text,
            _pwdController.text);
        setState(() {
          _mainWidget = Main();
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
  Widget build(BuildContext context){
    _mainWidget = Main();
    if (Global.token == null || Global.token == '') {
      _mainWidget = loginScreen();
    } else {
      stdout.writeln("Token:" + Global.token!);
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
      appBar: AppBar(title: Text('Connexion')),
      body: Container(
        padding: EdgeInsets.all(20.0),
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
              ElevatedButton(onPressed: _login, child: Text('Se connecter'))
            ],
          ),
        ),
      ),
    );
  }
}
