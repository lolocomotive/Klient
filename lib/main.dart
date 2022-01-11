import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'kdecole-api/client.dart';
import 'screens/multiview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final dbDir = await getTemporaryDirectory();
  final dbPath = dbDir.path + '/kdecole.db';
  await deleteDatabase(dbPath);
  stdout.writeln('Database URL: ' + dbPath);
  final db = await openDatabase(dbPath);
  final queryResult = await db.query('sqlite_master');
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
    await db.execute('''
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

    await db.execute('''
    CREATE TABLE IF NOT EXISTS NewsAttachments(
      ID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      parentUID TEXT NOT NULL,
      Name TEXT NOT NULL,
      foreign KEY(parentUID) REFERENCES NewsArticles(UID)
    );''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS Conversations(
      ID INTEGER PRIMARY KEY NOT NULL,
      Subject TEXT NOT NULL,
      Preview TEXT NOT NULL,
      HasAttachment BOOLEAN NOT NULL,
      LastDate INTEGER NOT NULL
    );''');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS Messages(
      ID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      ParentID INTEGER NOT NULL,
      HTMLContent TEXT NOT NULL,
      Author TEXT NOT NULL,
      FOREIGN KEY (ParentID) REFERENCES Conversations(ID)
    );''');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS MessageAttachments(
      ID INTEGER PRIMARY KEY NOT NULL,
      ParentID INTEGER NOT NULL,
      URL TEXT,
      Name TEXT NOT NULL,
      FOREIGN KEY (ParentID) references Messages(ID)
    );''');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS Grades(
      ID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      Subject TEXT NOT NULL,
      Prof TEXT NOT NULL,
      Grade TEXT NOT NULL,
      Description TEXT NOT NULL
    );''');
    await db.execute('''
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
    await db.execute('''
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
    await db.execute('''
    CREATE TABLE IF NOT EXISTS ExerciseAttachments(
      ID INTEGER PRIMARY KEY NOT NULL,
      ParentID INTEGER NOT NULL,
      URL TEXT,
      Name TEXT NOT NULL,
      FOREIGN KEY (ParentID) references Exercises(ID)
    );''');
    stdout.writeln('Done creating tables');
  }
  runApp(KosmosApp(prefs, db));
}

class KosmosApp extends StatefulWidget {
  final SharedPreferences _prefs;
  final Database _db;

  const KosmosApp(this._prefs, this._db, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return KosmosState(_prefs, _db);
  }
}

class KosmosState extends State {
  KosmosState(this._prefs, this._db);

  final title = 'Kosmos client';
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  final SharedPreferences _prefs;
  final Database _db;
  final _loginFormKey = GlobalKey<FormState>();
  final _unameController = TextEditingController();
  final _pwdController = TextEditingController();
  Widget? _mainWidget;

  _login() async {
    if (_loginFormKey.currentState!.validate()) {
      try {
        final client = await Client.login(_unameController.text,
            _pwdController.text, await SharedPreferences.getInstance());
        setState(() {
          _mainWidget = Main(_db, _prefs);
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
    _mainWidget = Main(_db, _prefs);
    final token = _prefs.getString('token');
    if (token == null || token == '') {
      _mainWidget = loginScreen();
    } else {
      stdout.writeln("Token:" + _prefs.getString('token')!);
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
