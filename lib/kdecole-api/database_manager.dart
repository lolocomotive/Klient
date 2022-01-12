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

import 'package:kosmos_client/kdecole-api/client.dart';
import 'package:kosmos_client/kdecole-api/exercise.dart';

import '../main.dart';

/// Utility class that fetches data from the API and stores it inside the database
class DatabaseManager {
  /// Download the 20 first Conversations, the associated messages and their attachments
  static fetchMessageData() async {
    final result = await Global.client!.request(Action.getConversations);
    for (final conversation in result['communications']) {
      Global.db!.insert('Conversations', {
        'ID': conversation['id'],
        'Subject': conversation['objet'],
        'Preview': conversation['premieresLignes'],
        'HasAttachment': (conversation['pieceJointe'] as bool) ? 1 : 0,
        'LastDate': (conversation['dateDernierMessage'])
      });
      final messages = await Global.client!.request(
          Action.getConversationDetail,
          params: [(conversation['id'] as int).toString()]);
      for (final message in messages['participations']) {
        Global.db!.insert('Messages', {
          'ParentID': conversation['id'],
          'HTMLContent': message['corpsMessage'],
          'Author': message['redacteur']['libelle']
        });
        for (final attachment in message['pjs'] ?? []) {
          Global.db!.insert('MessageAttachments', {
            'ID': attachment['idRessource'],
            'ParentID': message['id'],
            'URL': attachment['url'],
            'Name': attachment['name']
          });
        }
      }
    }
  }

  /// Download all the available NewsArticles, and their associated attachments
  static fetchNewsData() async {
    final result = await Global.client!.request(
        Action.getNewsArticlesEtablissement,
        params: [Global.client!.idEtablissement ?? '0']);
    for (final newsArticle in result['articles']) {
      final articleDetails = await Global.client!
          .request(Action.getArticleDetails, params: [newsArticle['uid']]);
      await Global.db!.insert('NewsArticles', {
        'UID': newsArticle['uid'],
        'Type': articleDetails['type'],
        'Author': articleDetails['auteur'],
        'Title': articleDetails['titre'],
        'PublishingDate': articleDetails['date'],
        'HTMLContent': articleDetails['codeHTML'],
        'URL': articleDetails['url'],
      });
    }
  }

  /// Returns the ID of the lesson that occurs at the timestamp, returns null if nothing is found
  static int? _lessonIdByTimestamp(
      int timestamp, Iterable<dynamic> listeJourCdt) {
    for (final day in listeJourCdt) {
      for (final lesson in day['listeSeances']) {
        if (lesson['hdeb'] == timestamp) {
          return lesson['idSeance'];
        }
      }
    }
    return null;
  }

  /// Download the timetable from D-7 to D+7 with the associated [Exercise]s and their attachments
  static fetchTimetable() async {
    final result = await Global.client!.request(Action.getTimeTableEleve,
        params: [(Global.client!.idEleve ?? 0).toString()]);
    for (final day in result['listeJourCdt']) {
      for (final lesson in day['listeSeances']) {
        Global.db!.insert('Lessons', {
          'ID': lesson['idSeance'],
          'LessonDate': lesson['hdeb'],
          'StartTime': lesson['heureDebut'],
          'EndTime': lesson['heureFin'],
          'Room': lesson['salle'],
          'Title': lesson['titre'],
          'Subject': lesson['matiere'],
          'IsModified': lesson['flagModif'] ? 1 : 0,
          'ModificationMessage': lesson['motifModif'],
        });

        for (final exercise in lesson['aFaire'] ?? []) {
          final exerciseDetails =
              await Global.client!.request(Action.getExerciseDetails, params: [
            (Global.client!.idEleve ?? 0).toString(),
            (lesson['idSeance']).toString(),
            (exercise['uid']).toString()
          ]);
          Global.db!.insert('Exercises', {
            'Type': exercise['type'],
            'Title': exerciseDetails['titre'],
            'ID': exercise['uid'],
            'LessonFor':
                _lessonIdByTimestamp(exercise['date'], result['listeJourCdt']),
            'DateFor': exercise['date'],
            'ParentDate': lesson['hdeb'],
            'ParentLesson': lesson['idSeance'],
            'HTMLContent': exerciseDetails['codeHTML'],
            'Done': exerciseDetails['flagRealise'] ? 1 : 0,
          });
          for (final attachment in exerciseDetails['pjs'] ?? []) {
            Global.db!.insert('MessageAttachments', {
              'ID': attachment['idRessource'],
              'ParentID': exerciseDetails['uid'],
              'URL': attachment['url'],
              'Name': attachment['name']
            });
          }
        }
        for (final exercise in lesson['enSeance'] ?? []) {
          final exerciseDetails =
              await Global.client!.request(Action.getExerciseDetails, params: [
            (Global.client!.idEleve ?? 0).toString(),
            (lesson['idSeance']).toString(),
            (exercise['uid']).toString()
          ]);
          Global.db!.insert('Exercises', {
            'Type': 'Cours',
            'Title': exerciseDetails['titre'],
            'ID': exercise['uid'],
            'ParentDate': exercise['date'],
            'ParentLesson': lesson['idSeance'],
            'HTMLContent': exerciseDetails['codeHTML'],
            'Done': exerciseDetails['flagRealise'] ? 1 : 0,
          });
          for (final attachment in exerciseDetails['pjs'] ?? []) {
            Global.db!.insert('MessageAttachments', {
              'ID': attachment['idRessource'],
              'ParentID': exerciseDetails['uid'],
              'URL': attachment['url'],
              'Name': attachment['name']
            });
          }
        }
        for (final exercise in lesson['aRendre'] ?? []) {
          if ((await Global.db!.query('Exercises',
                  where: 'ID = ?', whereArgs: exercise['id']))
              .isEmpty) {
            continue;
          }
          final exerciseDetails =
              await Global.client!.request(Action.getExerciseDetails, params: [
            (Global.client!.idEleve ?? 0).toString(),
            (lesson['idSeance']).toString(),
            (exercise['uid']).toString()
          ]);
          stdout.writeln('exercise[date]: ' +
              exercise['date'].toString() +
              ' exerciseDetails[date]: ' +
              exerciseDetails['date'].toString());
          Global.db!.insert('Exercises', {
            'Type': exercise['type'],
            'Title': exerciseDetails['titre'],
            'ID': exercise['uid'],
            'LessonFor': lesson['idSeance'],
            'DateFor': exerciseDetails['date'],
            'ParentDate': exercise['date'],
            'ParentLesson':
                _lessonIdByTimestamp(exercise['date'], result['listeJourCdt']),
            'HTMLContent': exerciseDetails['codeHTML'],
            'Done': exerciseDetails['flagRealise'] ? 1 : 0,
          });
          for (final attachment in exerciseDetails['pjs'] ?? []) {
            Global.db!.insert('MessageAttachments', {
              'ID': attachment['idRessource'],
              'ParentID': exerciseDetails['uid'],
              'URL': attachment['url'],
              'Name': attachment['name']
            });
          }
        }
      }
    }
  }
}
