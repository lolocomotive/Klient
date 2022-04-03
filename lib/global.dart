import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kosmos_client/kdecole-api/client.dart';
import 'package:kosmos_client/main.dart';
import 'package:kosmos_client/screens/debug.dart';
import 'package:kosmos_client/screens/messages.dart';
import 'package:kosmos_client/screens/multiview.dart';
import 'package:kosmos_client/screens/settings.dart';
import 'package:kosmos_client/screens/setup.dart';
import 'package:sqflite/sqflite.dart';

class Global {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static FlutterSecureStorage? storage;
  static FlutterLocalNotificationsPlugin? notifications;
  static Database? db;
  static String? token;
  static Client? client;
  static int? currentConversation;
  static String? currentConversationSubject;
  static MessagesState? messagesState;
  static bool loadingMessages = false;
  static String? searchQuery;
  static MessageSearchResultsState? messageSearchSuggestionState;
  static Widget? fab;
  static MainState? mainState;
  static ThemeData? theme;
  static const timeWidth = 32.0;
  static const heightPerHour = 110.0;
  static const lessonLength = 55.0 / 55.0;
  static const maxLessonsPerDay = 11;
  static const startTime = 8;
  static bool step1 = false;
  static bool step2 = false;
  static bool step3 = false;
  static bool step4 = false;
  static bool step5 = false;
  static int progress = 0;
  static int progressOf = 0;
  static void Function()? onLogin;

  static initDB() async {
    final dbDir = await getDatabasesPath();
    final dbPath = dbDir + '/kdecole.db';
    if (kDebugMode) {
      //await deleteDatabase(dbPath);
    }
    print('Database URL: ' + dbPath);
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

      print('Initializing database');
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
      NotificationShown BOOLEAN NOT NULL,
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
      Date INT NOT NULL,
      UniqueID TEXT NOT NULL UNIQUE
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
      print('Done creating tables');
    }
  }

  static const standardShadow = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 8,
      offset: Offset(0, 4),
    )
  ];

  static PopupMenuButton popupMenuButton = PopupMenuButton(
    onSelected: (choice) {
      switch (choice) {
        case 'Paramètres':
          navigatorKey.currentState!.push(
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          );
          break;
        case 'Debug':
          navigatorKey.currentState!.push(
            MaterialPageRoute(builder: (_) => const DebugScreen()),
          );
          break;
        case 'Initial setup':
          navigatorKey.currentState!.push(
            MaterialPageRoute(builder: (_) => SetupPage(() {})),
          );
          break;
      }
    },
    itemBuilder: (context) {
      return [
        PopupMenuItemWithIcon('Paramètres', Icons.settings_outlined, context),
        //PopupMenuItemWithIcon("Aide", Icons.help_outline, context),
        //PopupMenuItemWithIcon("Se déconnecter", Icons.logout_outlined, context),
        if (kDebugMode)
          PopupMenuItemWithIcon('Debug', Icons.bug_report_outlined, context),
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

  static Future<void> readPrefs() async {
    Global.storage = const FlutterSecureStorage();
    if (kDebugMode) {
      //Global.storage!.deleteAll();
    }
    try {
      Global.token = await Global.storage!.read(key: 'token');
    } on PlatformException catch (_) {
      // Workaround for https://github.com/mogol/flutter_secure_storage/issues/43
      await Global.storage!.deleteAll();
      Global.token = '';
    }
  }

  static Future<void> initNotifications() async {
    Global.notifications = FlutterLocalNotificationsPlugin();
    await Global.notifications!.initialize(
        const InitializationSettings(
            android: AndroidInitializationSettings('ic_stat_name')),
        onSelectNotification: (_) {
      print(_);
    });
  }
}
