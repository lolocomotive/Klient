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

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kosmos_client/api/client.dart';
import 'package:kosmos_client/api/color_provider.dart';
import 'package:kosmos_client/api/conversation.dart';
import 'package:kosmos_client/api/lesson.dart';
import 'package:kosmos_client/main.dart';
import 'package:kosmos_client/screens/about.dart';
import 'package:kosmos_client/screens/conversation.dart';
import 'package:kosmos_client/screens/debug.dart';
import 'package:kosmos_client/screens/lesson.dart';
import 'package:kosmos_client/screens/message_search.dart';
import 'package:kosmos_client/screens/messages.dart';
import 'package:kosmos_client/screens/multiview.dart';
import 'package:kosmos_client/screens/settings.dart';
import 'package:kosmos_client/screens/setup.dart';
import 'package:restart_app/restart_app.dart';
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
  static MessagesPageState? messagesState;
  static bool loadingMessages = false;
  static String? searchQuery;
  static MessageSearchResultsState? messageSearchSuggestionState;
  static Widget? fab;
  static MainState? mainState;
  static ThemeData? theme;
  static GlobalKey mainKey = GlobalKey();
  static const timeWidth = 32.0;
  static const heightPerHour = 120.0;
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
  static String apiurl = '';
  static const apiUrls = {
    'Mon Bureau Numérique': 'https://mobilite.monbureaunumerique.fr/mobilite/',
    'Mon ENT Occitanie': 'https://mobilite.mon-ent-occitanie.fr/mobilite/',
    'Arsene 76': 'https://mobilite.arsene76.fr/mobilite/',
    'ENT27': 'https://mobilite.ent27.fr/mobilite/',
    'ENT Creuse': 'https://mobilite.entcreuse.fr/mobilite/',
    'ENT Auvergne-Rhône-Alpes': 'https://mobilite.ent.auvergnerhonealpes.fr/mobilite/',
    'Agora 06': 'https://mobilite.agora06.fr/mobilite/',
    'CyberCollèges 42': 'https://mobilite.cybercolleges42.fr/mobilite/',
    'eCollège 31 Haute-Garonne': 'https://mobilite.ecollege.haute-garonne.fr/mobilite/',
    "Mon collège en Val d'Oise": 'https://mobilite.moncollege.valdoise.fr/mobilite/',
    'Webcollège Seine-Saint-Denis  ': 'https://mobilite.webcollege.seinesaintdenis.fr/mobilite/',
    'Eclat-BFC': 'https://mobilite.eclat-bfc.fr/mobilite/',
    '@ucollège84': 'https://mobilite.aucollege84.vaucluse.fr/mobilite/',
    'Skolengo Demo': 'https://mobilite.demo.skolengo.com/mobilite/',
    'Kosmos Éducation (aefe, etc.)': 'https://mobilite.kosmoseducation.com/mobilite/',
    'Skolengo formation': 'https://mobilite.formation.skolengo.com/mobilite/',
    'Schulportal Ostbelgien': 'https://mobilite.schulen.be/mobilite/'
  };
  static List<DropdownMenuItem> dropdownItems = [];
  static GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();
  static AppLifecycleState? currentState;

  static initDB() async {
    final dbDir = await getDatabasesPath();
    final dbPath = '$dbDir/kdecole.db';
    if (kDebugMode) {
      //await deleteDatabase(dbPath);
    }
    print('Database URL: $dbPath');
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
      ParentUID TEXT NOT NULL,
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
      CanReply BOOLEAN NOT NULL,
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
      ShouldNotify BOOLEAN NOT NULL,
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
  static Widget defaultCard(
      {Widget? child,
      double? elevation,
      bool outlined = false,
      EdgeInsets padding = const EdgeInsets.all(16)}) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: elevation ?? 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: outlined ? BorderSide(color: Global.theme!.colorScheme.outline) : BorderSide.none,
      ),
      //clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }

  static Widget exceptionWidget(Exception e, StackTrace st) {
    String message = 'Erreur';
    String? hint;
    if (e is SocketException) {
      message = 'Erreur de réseau';
    } else if (e is DatabaseException) {
      message = 'Erreur de base de données';
      hint =
          'Essayez de redémarrer l\'application. Si l\'erreur persiste effacez les données de l\'application et reconnectez-vous';
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(message),
              if (hint != null)
                Text(
                  hint,
                  style: TextStyle(
                    color: Global.theme!.colorScheme.secondary,
                  ),
                ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            Global.messengerKey.currentState?.hideCurrentSnackBar();
            Global.navigatorKey.currentState!.push(
              MaterialPageRoute(builder: (context) {
                return Scaffold(
                  body: NestedScrollView(
                    floatHeaderSlivers: true,
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [
                        SliverAppBar(
                          title: Text(message),
                          floating: true,
                          forceElevated: innerBoxIsScrolled,
                        )
                      ];
                    },
                    body: Scrollbar(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              defaultCard(
                                child: Column(
                                  children: [
                                    Text(
                                      'Descriptif de l\'erreur',
                                      style: TextStyle(
                                          color: Global.theme!.colorScheme.primary,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(e.toString()),
                                  ],
                                ),
                              ),
                              defaultCard(
                                child: Column(
                                  children: [
                                    Text(
                                      'Stack trace',
                                      style: TextStyle(
                                          color: Global.theme!.colorScheme.primary,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(st.toString()),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
          child: const Text("Plus d'infos"),
        )
      ],
    );
  }

  static void onException(Exception e, StackTrace st) {
    print(e);
    if (Global.currentState == AppLifecycleState.resumed) {
      Global.messengerKey.currentState?.showSnackBar(
        SnackBar(
            content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            exceptionWidget(e, st),
          ],
        )),
      );
    }
  }

  static PopupMenuButton popupMenuButton = PopupMenuButton(
    onSelected: (choice) async {
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
        case 'Se déconnecter':
          navigatorKey.currentState!.push(MaterialPageRoute(builder: (_) {
            return WillPopScope(
              onWillPop: () async => false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [CircularProgressIndicator()],
              ),
            );
          }));
          Global.client!.clear();
          try {
            await Global.client!.request(Action.logout);
          } catch (_) {}
          await Global.db!.close();
          await deleteDatabase(Global.db!.path);
          print('Storage before erase:');
          var data = await Global.storage!.readAll();
          data.forEach((key, value) {
            print('$key:$value');
          });
          await Global.storage!.deleteAll();
          await Global.initDB();
          await Global.readPrefs();
          await Restart.restartApp();
          break;
        case 'Initial setup':
          navigatorKey.currentState!.push(
            MaterialPageRoute(builder: (_) => SetupPage(() {})),
          );
          break;
        case 'À propos':
          navigatorKey.currentState!.push(MaterialPageRoute(builder: (_) => const AboutPage()));
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

  static Future<void> readPrefs() async {
    apiUrls.forEach((key, value) {
      dropdownItems.add(DropdownMenuItem(
        value: value,
        child: Text(key),
      ));
    });
    Global.storage =
        const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
    if (kDebugMode) {
      //Global.storage!.deleteAll();
    }

    try {
      print('Reading prefernces');
      var data = await Global.storage!.readAll();
      data.forEach((key, value) {
        print('$key: $value');
        if (key.startsWith('color.')) {
          ColorProvider.addColor(key.substring(6), int.parse(value));
        }
      });
      Global.apiurl = await Global.storage!.read(key: 'apiurl') ??
          'https://mobilite.kosmoseducation.com/mobilite/';
      Global.token = await Global.storage!.read(key: 'token');
    } on PlatformException catch (_) {
      // Workaround for https://github.com/mogol/flutter_secure_storage/issues/43
      await Global.storage!.deleteAll();
      await Future.delayed(const Duration(seconds: 1));
      Global.token = '';
    }
  }

  static Future<void> initNotifications() async {
    Global.notifications = FlutterLocalNotificationsPlugin();
    await Global.notifications!.initialize(
        const InitializationSettings(android: AndroidInitializationSettings('ic_stat_name')),
        onSelectNotification: notificationCallback);
  }

  static void notificationCallback(String? payload) {
    if (payload == null) return;
    if (payload.startsWith('conv-')) {
      final id = payload.substring(5, payload.length);
      Conversation.byID(int.parse(id)).then((conv) {
        if (conv == null) return;
        currentConversation = conv.id;
        currentConversationSubject = conv.subject;
        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (context) {
            return const ConversationPage(
              onDelete: deleteConversation,
            );
          },
        ));
      });
    }
    if (payload.startsWith('lesson-')) {
      final id = payload.substring(7, payload.length);
      Lesson.byID(int.parse(id)).then((lesson) {
        if (lesson == null) return;
        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (context) {
            return LessonPage(lesson);
          },
        ));
      });
    }
  }
}
