import 'package:flutter/material.dart';
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
            MaterialPageRoute(builder: (_) => SettingsPage()),
          );
          break;
        case 'Debug':
          navigatorKey.currentState!.push(
            MaterialPageRoute(builder: (_) => const DebugScreen()),
          );
          break;
        case 'Initial setup':
          navigatorKey.currentState!.push(
            MaterialPageRoute(builder: (_) => const SetupPage()),
          );
          break;
      }
    },
    itemBuilder: (context) {
      return [
        PopupMenuItemWithIcon("Paramètres", Icons.settings_outlined, context),
        PopupMenuItemWithIcon("Aide", Icons.help_outline, context),
        PopupMenuItemWithIcon("Se déconnecter", Icons.logout_outlined, context),
        PopupMenuItemWithIcon("Debug", Icons.bug_report_outlined, context),
        PopupMenuItemWithIcon("Initial setup", Icons.login, context),
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
}
